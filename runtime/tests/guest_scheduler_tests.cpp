#include "kartpad/scheduler/guest_scheduler.h"
#include "kartpad/translation/scheduled_execution.h"
#include "ppc_runtime.h"

#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
using kartpad::scheduler::GuestCpuContext;
using kartpad::scheduler::GuestScheduler;
using kartpad::scheduler::StepAction;
using kartpad::scheduler::ThreadState;

void Require(const bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

void TestPriorityYieldSleepAlarmAndQueue() {
  GuestScheduler scheduler;
  int resumed_steps = 0;
  const auto suspended = scheduler.Create(
      0, "suspended", {}, [&](GuestCpuContext&) {
        ++resumed_steps;
        return StepAction::Exit();
      });
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Idle,
          "suspended thread ran before resume");
  Require(scheduler.Resume(suspended), "resume failed");
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed && resumed_steps == 1,
          "resumed thread did not start");

  std::vector<std::string> order;
  const auto low = scheduler.Create(
      10, "low", {}, [&](GuestCpuContext&) {
        order.emplace_back("low");
        return StepAction::Exit();
      }, false);
  const auto high = scheduler.Create(
      1, "high", {}, [&](GuestCpuContext&) {
        order.emplace_back("high");
        return StepAction::Exit();
      }, false);
  Require(scheduler.Run(2) == 2, "priority fixture operation count mismatch");
  Require(order == std::vector<std::string>({"high", "low"}), "priority order mismatch");
  Require(scheduler.Snapshot(high)->state == ThreadState::Terminated, "high did not exit");
  Require(scheduler.Snapshot(low)->state == ThreadState::Terminated, "low did not exit");

  int sleep_steps = 0;
  const auto sleeper = scheduler.Create(
      4, "sleeper", {}, [&](GuestCpuContext&) {
        return ++sleep_steps == 1 ? StepAction::SleepUntil(50) : StepAction::Exit(9);
      }, false);
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed, "sleep step did not execute");
  Require(scheduler.RunOne() == GuestScheduler::RunResult::AdvancedToAlarm,
          "idle scheduler did not advance to alarm");
  Require(scheduler.LogicalTick() == 50, "logical alarm tick mismatch");
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed, "woken sleeper did not run");
  Require(scheduler.Snapshot(sleeper)->exit_code == 9, "sleep exit code mismatch");

  std::vector<int> simultaneous_order;
  int wake_a_steps = 0;
  int wake_b_steps = 0;
  (void)scheduler.Create(
      6, "wake-a", {}, [&](GuestCpuContext&) {
        if (++wake_a_steps == 1) {
          return StepAction::SleepUntil(80);
        }
        simultaneous_order.push_back(6);
        return StepAction::Exit();
      }, false);
  (void)scheduler.Create(
      5, "wake-b", {}, [&](GuestCpuContext&) {
        if (++wake_b_steps == 1) {
          return StepAction::SleepUntil(80);
        }
        simultaneous_order.push_back(5);
        return StepAction::Exit();
      }, false);
  Require(scheduler.Run(2) == 2, "simultaneous sleepers did not enter wait");
  Require(scheduler.RunOne() == GuestScheduler::RunResult::AdvancedToAlarm,
          "simultaneous alarm did not advance once");
  Require(scheduler.Run(2) == 2, "simultaneous alarm threads did not resume");
  Require(simultaneous_order == std::vector<int>({5, 6}),
          "simultaneous wake priority order mismatch");

  int queue_steps = 0;
  const auto queued = scheduler.Create(
      3, "queue", {}, [&](GuestCpuContext&) {
        return ++queue_steps == 1 ? StepAction::WaitQueue(0xCAFE) : StepAction::Exit();
      }, false);
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed, "queue wait did not run");
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Idle, "queue wait busy-spun");
  Require(scheduler.Send(0xCAFE), "queue send did not wake a waiter");
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed, "queue waiter did not resume");
  Require(scheduler.Snapshot(queued)->state == ThreadState::Terminated, "queue waiter did not exit");
}

void TestJoinCancelNestedCallbackAndLifecycle() {
  GuestScheduler scheduler;
  std::uint64_t target = 0;
  int join_steps = 0;
  const auto joiner = scheduler.Create(
      1, "joiner", {}, [&](GuestCpuContext&) {
        return ++join_steps == 1 ? StepAction::WaitJoin(target) : StepAction::Exit();
      }, false);
  target = scheduler.Create(2, "target", {}, [](GuestCpuContext&) { return StepAction::Exit(42); },
                            false);
  Require(scheduler.Run(3) == 3, "join fixture operation count mismatch");
  Require(scheduler.Snapshot(target)->exit_code == 42, "target exit code mismatch");
  Require(scheduler.Snapshot(joiner)->state == ThreadState::Terminated, "joiner did not wake");

  const auto cancelled = scheduler.Create(3, "cancel", {}, [](GuestCpuContext&) {
    return StepAction::Yield();
  });
  Require(scheduler.Cancel(cancelled), "cancel failed");
  Require(scheduler.Snapshot(cancelled)->state == ThreadState::Cancelled, "cancel state mismatch");

  bool nested_callback_ran = false;
  const auto nested = scheduler.Create(
      1, "nested", {}, [&](GuestCpuContext& context) {
        const auto snapshots = scheduler.SnapshotAll();
        Require(!snapshots.empty(), "nested host callback could not inspect scheduler");
        context.gpr[3] = 0x12345678;
        nested_callback_ran = true;
        return StepAction::Exit();
      }, false);
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed, "nested callback did not run");
  Require(nested_callback_ran && scheduler.Snapshot(nested)->context.gpr[3] == 0x12345678,
          "nested callback context mismatch");

  scheduler.ReapTerminated();
  for (int cycle = 0; cycle < 10'000; ++cycle) {
    (void)scheduler.Create(5, "cycle", {}, [](GuestCpuContext&) { return StepAction::Exit(); }, false);
    Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed,
            "create/delete cycle did not execute");
    scheduler.ReapTerminated();
  }
  Require(scheduler.ThreadCount() == 0, "terminated thread records leaked");
}

std::uint64_t HashState(const std::vector<GuestScheduler::ThreadSnapshot>& snapshots,
                        const std::uint64_t operations, const std::uint64_t retraces) {
  std::uint64_t hash = 1469598103934665603ULL;
  const auto mix = [&](const std::uint64_t value) {
    hash ^= value;
    hash *= 1099511628211ULL;
  };
  mix(operations);
  mix(retraces);
  for (const auto& snapshot : snapshots) {
    mix(snapshot.id);
    mix(snapshot.context.gpr[0]);
    mix(snapshot.context.gpr[31]);
    mix(snapshot.context.fpr_bits[0]);
    mix(snapshot.context.fpr_bits[31]);
    for (const std::uint8_t byte : snapshot.context.simd_state) {
      mix(byte);
    }
    mix(snapshot.context.fpscr);
  }
  return hash;
}

std::uint64_t RunMillionOperationFixture() {
  GuestScheduler scheduler;
  std::uint64_t retraces = 0;
  scheduler.ConfigureViRetrace(100, [&](const std::uint64_t index) {
    Require(index == retraces + 1, "VI retrace index mismatch");
    ++retraces;
  });

  for (std::uint32_t thread_index = 0; thread_index < 4; ++thread_index) {
    GuestCpuContext initial{};
    initial.gpr[31] = 0xA0000000U | thread_index;
    initial.fpr_bits[0] = 0x3FF0000000000000ULL + thread_index;
    initial.fpr_bits[31] = 0x7FF8000000000000ULL + thread_index;
    initial.fpscr = 0xF0000000U | thread_index;
    initial.simd_state.fill(static_cast<std::uint8_t>(0x20 + thread_index));
    (void)scheduler.Create(
        5, "stress-" + std::to_string(thread_index), initial,
        [thread_index](GuestCpuContext& context) {
          ++context.gpr[0];
          context.pc += 4;
          context.lr = 0x80000000U | thread_index;
          return StepAction::Yield();
        },
        false);
  }
  Require(scheduler.Run(1'000'000) == 1'000'000, "million-operation fixture ended early");
  Require(scheduler.OperationCount() == 1'000'000, "million-operation count mismatch");
  Require(retraces == 10'000, "VI retrace cadence mismatch");
  const auto snapshots = scheduler.SnapshotAll();
  Require(snapshots.size() == 4, "stress thread count mismatch");
  for (const auto& snapshot : snapshots) {
    Require(snapshot.context.gpr[0] == 250'000, "round-robin operation distribution mismatch");
    const std::uint32_t index = static_cast<std::uint32_t>(snapshot.id - 1);
    Require(snapshot.context.gpr[31] == (0xA0000000U | index), "GPR preservation mismatch");
    Require(snapshot.context.fpr_bits[0] == 0x3FF0000000000000ULL + index,
            "FP register preservation mismatch");
    Require(snapshot.context.fpr_bits[31] == 0x7FF8000000000000ULL + index,
            "NaN FP register preservation mismatch");
    Require(snapshot.context.fpscr == (0xF0000000U | index), "FPSCR preservation mismatch");
    for (const std::uint8_t byte : snapshot.context.simd_state) {
      Require(byte == static_cast<std::uint8_t>(0x20 + index), "SIMD preservation mismatch");
    }
  }
  return HashState(snapshots, scheduler.OperationCount(), retraces);
}

void TestMillionOperationsDeterminismAndLifecycleStates() {
  const std::uint64_t first_hash = RunMillionOperationFixture();
  const std::uint64_t second_hash = RunMillionOperationFixture();
  Require(first_hash == second_hash, "million-operation state hash diverged");
  std::cout << "millionStateHash=0x" << std::hex << first_hash << std::dec << '\n';

  GuestScheduler scheduler;
  const auto waiting = scheduler.Create(1, "waiting", {}, [](GuestCpuContext&) {
    return StepAction::WaitQueue(7);
  }, false);
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Executed, "waiting setup failed");
  scheduler.SetBackgrounded(true);
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Suspended,
          "background suspension did not stop execution");
  scheduler.SetBackgrounded(false);
  scheduler.Shutdown();
  Require(scheduler.RunOne() == GuestScheduler::RunResult::Shutdown,
          "shutdown did not stop scheduler");
  Require(scheduler.Snapshot(waiting)->state == ThreadState::Cancelled,
          "shutdown did not cancel waiting thread");
  const auto all_after_shutdown = scheduler.SnapshotAll();
  for (const auto& snapshot : all_after_shutdown) {
    Require(snapshot.state == ThreadState::Terminated || snapshot.state == ThreadState::Cancelled,
            "shutdown left a live thread state");
  }

  GuestScheduler running_shutdown;
  (void)running_shutdown.Create(
      1, "shutdown-running", {}, [&](GuestCpuContext&) {
        running_shutdown.Shutdown();
        return StepAction::Yield();
      }, false);
  Require(running_shutdown.RunOne() == GuestScheduler::RunResult::Shutdown,
          "shutdown during running step was not safe");
}

void TestTranslatedContextAcrossYieldsAndCallbacks() {
  GuestScheduler scheduler;
  GuestCpuContext initial{};
  initial.fpscr = kartpad::semantics::fpscr::NI;
  initial.fpr_bits[1] = 0x4045000000000000ULL;
  initial.fpr_bits[2] = 0x7ff0000000000000ULL;
  initial.fpr_bits[3] = 0xfff0000000000000ULL;
  int steps = 0;
  bool host_callback_saw_context = false;
  const auto id = scheduler.Create(
      1, "translated-persistence", initial,
      [&](GuestCpuContext& scheduled) {
        kartpad::translation::RunScheduledTranslatedStep(
            scheduled, [&](CpuContext& active) {
              host_callback_saw_context = g_currentCpuContext == &active;
              if (steps == 0) {
                PPC_Mtfsb1(24);
                PpcFaddsStateInline(active.fpr[1].d, active.fpr[2].d,
                                    active.fpr[3].d);
              } else {
                Require((active.fpscr & kartpad::semantics::fpscr::NI) != 0,
                        "NI did not survive scheduler yield");
                Require((active.fpscr & kartpad::semantics::fpscr::VXISI) != 0,
                        "FPSCR cause did not survive scheduler yield");
                PPC_Mtfsb1(27);
                PpcFresValueStateInline(active.fpr[1].d, 0.0);
              }
            });
        Require(g_currentCpuContext == nullptr,
                "translated scope leaked past scheduler callback");
        return ++steps == 1 ? StepAction::Yield() : StepAction::Exit();
      }, false);
  Require(scheduler.Run(2) == 2, "translated scheduler fixture did not complete");
  const auto snapshot = scheduler.Snapshot(id);
  Require(snapshot.has_value(), "translated scheduler snapshot missing");
  Require(host_callback_saw_context, "host callback did not inherit active CPU context");
  Require(snapshot->context.fpr_bits[1] == 0x4045000000000000ULL,
          "enabled exception destination changed across scheduler callbacks");
  constexpr std::uint32_t expected = kartpad::semantics::fpscr::NI |
      kartpad::semantics::fpscr::VE | kartpad::semantics::fpscr::ZE |
      kartpad::semantics::fpscr::VXISI | kartpad::semantics::fpscr::ZX;
  Require((snapshot->context.fpscr & expected) == expected,
          "translated FPSCR state did not persist through scheduler callbacks");
}

}  // namespace

int main() {
  try {
    TestPriorityYieldSleepAlarmAndQueue();
    TestJoinCancelNestedCallbackAndLifecycle();
    TestMillionOperationsDeterminismAndLifecycleStates();
    TestTranslatedContextAcrossYieldsAndCallbacks();
    std::cout << "KartPad portable guest-scheduler tests passed\n";
    return EXIT_SUCCESS;
  } catch (const std::exception& error) {
    std::cerr << "KartPad guest-scheduler test failure: " << error.what() << '\n';
    return EXIT_FAILURE;
  }
}
