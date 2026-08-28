#pragma once

#include <array>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace kartpad::scheduler {

struct GuestCpuContext {
  std::array<std::uint32_t, 32> gpr{};
  std::array<std::uint64_t, 32> fpr_bits{};
  std::array<std::uint8_t, 16 * 8> simd_state{};
  std::uint32_t pc = 0;
  std::uint32_t lr = 0;
  std::uint32_t ctr = 0;
  std::uint32_t xer = 0;
  std::uint32_t cr = 0;
  std::uint32_t fpscr = 0;
  std::array<std::uint32_t, 8> gqr{};
  std::uint32_t srr0 = 0;
  std::uint32_t srr1 = 0;
  std::uint32_t hid0 = 0;
  std::uint32_t hid1 = 0;
  std::uint32_t hid2 = 0;
  std::uint32_t msr = 0;
  std::uint64_t time_base = 0;
};

enum class ThreadState {
  Suspended,
  Ready,
  Running,
  Sleeping,
  WaitingQueue,
  WaitingJoin,
  Terminated,
  Cancelled,
};

struct StepAction {
  enum class Kind { Yield, SleepUntil, WaitQueue, WaitJoin, Exit };
  Kind kind = Kind::Yield;
  std::uint64_t value = 0;

  [[nodiscard]] static StepAction Yield() { return {}; }
  [[nodiscard]] static StepAction SleepUntil(std::uint64_t tick) {
    return {.kind = Kind::SleepUntil, .value = tick};
  }
  [[nodiscard]] static StepAction WaitQueue(std::uint64_t queue) {
    return {.kind = Kind::WaitQueue, .value = queue};
  }
  [[nodiscard]] static StepAction WaitJoin(std::uint64_t thread) {
    return {.kind = Kind::WaitJoin, .value = thread};
  }
  [[nodiscard]] static StepAction Exit(std::uint64_t code = 0) {
    return {.kind = Kind::Exit, .value = code};
  }
};

class GuestScheduler final {
 public:
  using ThreadId = std::uint64_t;
  using Step = std::function<StepAction(GuestCpuContext&)>;
  using RetraceCallback = std::function<void(std::uint64_t)>;

  enum class RunResult { Executed, AdvancedToAlarm, Idle, Suspended, Shutdown };

  struct ThreadSnapshot {
    ThreadId id = 0;
    int priority = 0;
    ThreadState state = ThreadState::Suspended;
    GuestCpuContext context{};
    std::uint64_t exit_code = 0;
    std::string name;
  };

  ThreadId Create(int priority, std::string name, GuestCpuContext initial, Step step,
                  bool start_suspended = true);
  bool Resume(ThreadId id);
  bool Suspend(ThreadId id);
  bool Cancel(ThreadId id);
  bool Send(std::uint64_t queue);
  void SetBackgrounded(bool backgrounded);
  void ConfigureViRetrace(std::uint64_t operations_per_retrace, RetraceCallback callback);

  [[nodiscard]] RunResult RunOne();
  [[nodiscard]] std::uint64_t Run(std::uint64_t maximum_operations);
  void Shutdown();
  void ReapTerminated();

  [[nodiscard]] std::optional<ThreadSnapshot> Snapshot(ThreadId id) const;
  [[nodiscard]] std::vector<ThreadSnapshot> SnapshotAll() const;
  [[nodiscard]] std::uint64_t LogicalTick() const;
  [[nodiscard]] std::uint64_t OperationCount() const;
  [[nodiscard]] std::size_t ThreadCount() const;

 private:
  struct ThreadRecord {
    ThreadSnapshot snapshot;
    Step step;
    std::uint64_t ready_sequence = 0;
    std::uint64_t wake_tick = 0;
    std::uint64_t wait_value = 0;
  };

  void MarkReady(const std::shared_ptr<ThreadRecord>& thread);
  void WakeDueAlarms();
  void WakeJoiners(ThreadId target);
  [[nodiscard]] std::shared_ptr<ThreadRecord> ChooseReady() const;
  [[nodiscard]] std::optional<std::uint64_t> NextWakeTick() const;

  mutable std::mutex mutex_;
  std::unordered_map<ThreadId, std::shared_ptr<ThreadRecord>> threads_;
  ThreadId next_id_ = 1;
  std::uint64_t next_ready_sequence_ = 1;
  std::uint64_t tick_ = 0;
  std::uint64_t operations_ = 0;
  std::uint64_t vi_period_ = 0;
  std::uint64_t next_vi_operation_ = 0;
  RetraceCallback vi_callback_;
  bool backgrounded_ = false;
  bool shutdown_ = false;
};

}  // namespace kartpad::scheduler
