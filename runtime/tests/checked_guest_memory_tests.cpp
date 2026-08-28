#include "kartpad/memory/checked_guest_memory.h"

#include <atomic>
#include <cstdlib>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

namespace {
using kartpad::memory::CheckedGuestMemory;
using kartpad::memory::FaultKind;
using kartpad::memory::FaultContext;
using kartpad::memory::GuestMemoryFault;

void Require(const bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

template <typename Action>
void RequireFault(const FaultKind expected, Action action, const std::string& message) {
  try {
    action();
  } catch (const GuestMemoryFault& fault) {
    Require(fault.Kind() == expected, message + ": wrong fault kind");
    return;
  }
  throw std::runtime_error(message + ": no fault");
}

void MapDefault(CheckedGuestMemory& memory) {
  memory.Map({.guest_base = 0x80000000, .size = 0x8000, .backing = 1});
  memory.Map({.guest_base = 0xC0000000, .size = 0x8000, .backing = 1});
  memory.Map({.guest_base = 0x90000000, .size = 0x8000, .backing = 2});
}

void TestScalarEndianAlignmentAndAliases() {
  CheckedGuestMemory memory;
  MapDefault(memory);
  constexpr std::uint64_t value = 0xFEDCBA9876543210ULL;
  for (const std::size_t width : {1U, 2U, 4U, 8U}) {
    for (std::size_t alignment = 0; alignment < width; ++alignment) {
      const std::uint32_t address = 0x80000100 + static_cast<std::uint32_t>(alignment);
      memory.Store(address, width, value);
      const std::uint64_t mask = width == 8 ? ~std::uint64_t{0}
                                            : (std::uint64_t{1} << (width * 8U)) - 1U;
      Require(memory.LoadUnsigned(address, width) == (value & mask),
              "unaligned scalar round-trip mismatch");
    }
  }

  memory.Store(0x80000200, 4, 0x12345678);
  Require(memory.LoadUnsigned(0x80000200, 1) == 0x12, "big-endian byte 0 mismatch");
  Require(memory.LoadUnsigned(0x80000201, 1) == 0x34, "big-endian byte 1 mismatch");
  Require(memory.LoadUnsigned(0xC0000200, 4) == 0x12345678, "MEM1 alias read mismatch");
  memory.Store(0xC0000202, 2, 0xABCD);
  Require(memory.LoadUnsigned(0x80000200, 4) == 0x1234ABCD, "MEM1 alias write mismatch");

  memory.Store(0x80000300, 1, 0x80);
  memory.Store(0x80000308, 2, 0x8000);
  memory.Store(0x80000310, 4, 0x80000000);
  Require(memory.LoadSigned(0x80000300, 1) == -128, "signed byte extension mismatch");
  Require(memory.LoadSigned(0x80000308, 2) == -32768, "signed half extension mismatch");
  Require(memory.LoadSigned(0x80000310, 4) == -2147483648LL, "signed word extension mismatch");

  memory.Store(0x80000FFD, 8, 0x0102030405060708ULL);
  Require(memory.LoadUnsigned(0x80000FFD, 8) == 0x0102030405060708ULL,
          "cross-page scalar mismatch");
}

void TestFaultsMmioAndExecutableGuard() {
  CheckedGuestMemory memory;
  MapDefault(memory);
  memory.SetFaultContextProvider([] {
    return FaultContext{.guest_pc = 0x80001234,
                        .guest_lr = 0x80005678,
                        .translated_function = "fixture_load",
                        .register_dump = "r3=00000001 r4=CC000010"};
  });
  try {
    (void)memory.LoadUnsigned(0x7FFFFFFF, 1);
    throw std::runtime_error("diagnostic fault did not fire");
  } catch (const GuestMemoryFault& fault) {
    Require(fault.Context().has_value(), "fault context missing");
    Require(fault.Context()->guest_pc == 0x80001234, "fault PC mismatch");
    Require(fault.Context()->guest_lr == 0x80005678, "fault LR mismatch");
    Require(std::string{fault.what()}.find("fixture_load") != std::string::npos,
            "fault function missing from diagnosis");
    Require(std::string{fault.what()}.find("r3=00000001") != std::string::npos,
            "fault register dump missing from diagnosis");
  }
  RequireFault(FaultKind::Unmapped, [&] { (void)memory.LoadUnsigned(0x7FFFFFFF, 1); },
               "unmapped read");
  RequireFault(FaultKind::Unmapped, [&] { (void)memory.LoadUnsigned(0xFFFFFFFF, 2); },
               "domain-end read");
  RequireFault(FaultKind::Unmapped, [&] { memory.Store(0x80007FFF, 2, 0); },
               "region-end write");
  RequireFault(FaultKind::InvalidMapping,
               [&] { memory.Map({.guest_base = 0x80000100, .size = 0x100, .backing = 3}); },
               "overlapping mapping");

  std::uint64_t mmio_written = 0;
  memory.RegisterMmio(
      0xCC000000, 0xCC001000,
      [](const std::uint32_t address, const std::size_t width) {
        return static_cast<std::uint64_t>(address ^ static_cast<std::uint32_t>(width));
      },
      [&](const std::uint32_t, const std::size_t, const std::uint64_t value) {
        mmio_written = value;
      });
  Require(memory.LoadUnsigned(0xCC000010, 4) == 0xCC000014, "MMIO read dispatch mismatch");
  memory.Store(0xCC000020, 4, 0xCAFEBABE);
  Require(mmio_written == 0xCAFEBABE, "MMIO write dispatch mismatch");

  memory.RegisterExecutable(0x80001000, 0x80002000);
  RequireFault(FaultKind::ExecutableWrite, [&] { memory.Store(0x80001000, 4, 0); },
               "executable write");
  RequireFault(FaultKind::ExecutableWrite, [&] { memory.Store(0x80000FFF, 2, 0); },
               "straddled executable write");
}

void TestLifecycleConcurrencyAndStress() {
  CheckedGuestMemory memory;
  for (int launch = 0; launch < 2; ++launch) {
    memory.Map({.guest_base = 0x10000000, .size = 0x20000, .backing = 7});
    Require(memory.LoadUnsigned(0x10000000, 8) == 0, "mapping was not zero-filled");

    std::vector<std::thread> workers;
    for (std::uint32_t thread = 0; thread < 4; ++thread) {
      workers.emplace_back([&, thread] {
        const std::uint32_t base = 0x10001000 + thread * 0x1000;
        for (std::uint32_t iteration = 0; iteration < 10'000; ++iteration) {
          const std::uint32_t address = base + (iteration % 256U) * 4U;
          memory.Store(address, 4, (static_cast<std::uint64_t>(thread) << 24U) | iteration);
          (void)memory.LoadUnsigned(address, 4);
        }
      });
    }
    for (auto& worker : workers) {
      worker.join();
    }

    std::mt19937_64 random{0x4B415254504144ULL};
    std::vector<std::uint64_t> oracle(4096, 0);
    for (std::size_t iteration = 0; iteration < 100'000; ++iteration) {
      const std::size_t index = random() % oracle.size();
      const std::uint64_t value = random();
      const std::uint32_t address = 0x10010000 + static_cast<std::uint32_t>(index * 8U);
      memory.Store(address, 8, value);
      oracle[index] = value;
      Require(memory.LoadUnsigned(address, 8) == oracle[index], "randomized stress mismatch");
    }
    for (std::size_t index = 0; index < oracle.size(); ++index) {
      const std::uint32_t address = 0x10010000 + static_cast<std::uint32_t>(index * 8U);
      Require(memory.LoadUnsigned(address, 8) == oracle[index],
              "randomized stress retained-state mismatch");
    }
    memory.Reset();
    Require(memory.RegionCount() == 0, "reset retained a region");
    Require(memory.BackingSize(7) == 0, "reset retained a backing");
  }
}

void TestGuestMicroprogramHostCall() {
  CheckedGuestMemory memory;
  MapDefault(memory);
  // Bytecode: STORE32 [address] value; BRANCH +2; invalid opcode (skipped);
  // HOSTCALL id,arg; HALT. It exercises guest fetch, write, branch and ABI-like host dispatch.
  const std::vector<std::uint8_t> program = {
      0x01, 0x80, 0x00, 0x40, 0x00, 0x12, 0x34, 0x56, 0x78,
      0x02, 0x00, 0x02, 0xFF, 0x00,
      0x03, 0x00, 0x00, 0x00, 0x07, 0x80, 0x00, 0x40, 0x00,
      0x00,
  };
  for (std::size_t index = 0; index < program.size(); ++index) {
    memory.Store(0x80003000 + static_cast<std::uint32_t>(index), 1, program[index]);
  }

  std::uint32_t pc = 0x80003000;
  std::uint64_t host_result = 0;
  bool running = true;
  while (running) {
    switch (memory.LoadUnsigned(pc++, 1)) {
    case 0x00:
      running = false;
      break;
    case 0x01: {
      const std::uint32_t address = static_cast<std::uint32_t>(memory.LoadUnsigned(pc, 4));
      pc += 4;
      const std::uint32_t value = static_cast<std::uint32_t>(memory.LoadUnsigned(pc, 4));
      pc += 4;
      memory.Store(address, 4, value);
      break;
    }
    case 0x02: {
      const auto displacement = static_cast<std::int16_t>(memory.LoadUnsigned(pc, 2));
      pc += 2;
      pc += displacement;
      break;
    }
    case 0x03: {
      const std::uint32_t identifier = static_cast<std::uint32_t>(memory.LoadUnsigned(pc, 4));
      pc += 4;
      const std::uint32_t argument_address =
          static_cast<std::uint32_t>(memory.LoadUnsigned(pc, 4));
      pc += 4;
      host_result = identifier + memory.LoadUnsigned(argument_address, 4);
      break;
    }
    default:
      throw std::runtime_error("microprogram executed an invalid opcode");
    }
  }
  Require(memory.LoadUnsigned(0x80004000, 4) == 0x12345678, "microprogram store mismatch");
  Require(host_result == 0x1234567F, "microprogram host-call result mismatch");
}

}  // namespace

int main() {
  try {
    TestScalarEndianAlignmentAndAliases();
    TestFaultsMmioAndExecutableGuard();
    TestLifecycleConcurrencyAndStress();
    TestGuestMicroprogramHostCall();
    std::cout << "KartPad checked guest-memory tests passed\n";
    return EXIT_SUCCESS;
  } catch (const std::exception& error) {
    std::cerr << "KartPad checked guest-memory test failure: " << error.what() << '\n';
    return EXIT_FAILURE;
  }
}
