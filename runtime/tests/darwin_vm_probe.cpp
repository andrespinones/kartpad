#include <mach/mach.h>
#include <mach/mach_vm.h>

#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <stdexcept>

namespace {

constexpr mach_vm_address_t kPreferredBase = 0x0000100000000000ULL;
constexpr mach_vm_size_t kGuestReservationSize = 0x1'0000'0000ULL + 0x4000ULL;

void Require(const bool condition, const char* message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

bool ProbeFixedReservation() {
  mach_vm_address_t address = kPreferredBase;
  const kern_return_t result = ::mach_vm_allocate(mach_task_self(), &address,
                                                   kGuestReservationSize, VM_FLAGS_FIXED);
  if (result == KERN_NO_SPACE) {
    return false;
  }
  Require(result == KERN_SUCCESS, "fixed mach_vm_allocate returned an unexpected error");
  Require(address == kPreferredBase, "fixed mach_vm_allocate returned the wrong address");
  Require(::mach_vm_protect(mach_task_self(), address, kGuestReservationSize, FALSE,
                            VM_PROT_NONE) == KERN_SUCCESS,
          "mach_vm_protect(PROT_NONE) failed");
  Require(::mach_vm_deallocate(mach_task_self(), address, kGuestReservationSize) == KERN_SUCCESS,
          "fixed mach_vm_deallocate failed");
  return true;
}

void ProbeAnywhereLifecycle() {
  for (int launch = 0; launch < 2; ++launch) {
    mach_vm_address_t address = 0;
    Require(::mach_vm_allocate(mach_task_self(), &address, kGuestReservationSize,
                               VM_FLAGS_ANYWHERE) == KERN_SUCCESS,
            "base-relative mach_vm_allocate failed");
    Require(address != 0, "base-relative reservation returned null");
    Require(::mach_vm_protect(mach_task_self(), address, kGuestReservationSize, FALSE,
                              VM_PROT_NONE) == KERN_SUCCESS,
            "base-relative mach_vm_protect failed");
    Require(::mach_vm_deallocate(mach_task_self(), address, kGuestReservationSize) == KERN_SUCCESS,
            "base-relative mach_vm_deallocate failed");
  }
}

}  // namespace

int main() {
  try {
    // VM_FLAGS_FIXED without VM_FLAGS_OVERWRITE is non-destructive: an occupied
    // preferred range returns KERN_NO_SPACE instead of replacing another mapping.
    const bool fixed_available = ProbeFixedReservation();
    ProbeAnywhereLifecycle();
    std::cout << "preferredBase=0x" << std::hex << kPreferredBase << std::dec
              << " fixedAvailable=" << (fixed_available ? "true" : "false")
              << " anywhereLifecycle=pass\n";
    return EXIT_SUCCESS;
  } catch (const std::exception& error) {
    std::cerr << "Darwin VM probe failure: " << error.what() << '\n';
    return EXIT_FAILURE;
  }
}
