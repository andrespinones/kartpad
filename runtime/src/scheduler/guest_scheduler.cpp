#include "kartpad/scheduler/guest_scheduler.h"

#include <algorithm>
#include <stdexcept>

namespace kartpad::scheduler {

GuestScheduler::ThreadId GuestScheduler::Create(const int priority, std::string name,
                                                GuestCpuContext initial, Step step,
                                                const bool start_suspended) {
  if (!step) {
    throw std::invalid_argument("guest thread step callback is empty");
  }
  std::scoped_lock lock{mutex_};
  if (shutdown_) {
    throw std::logic_error("cannot create a guest thread after shutdown");
  }
  const ThreadId id = next_id_++;
  auto record = std::make_shared<ThreadRecord>();
  record->snapshot = {.id = id,
                      .priority = priority,
                      .state = start_suspended ? ThreadState::Suspended : ThreadState::Ready,
                      .context = std::move(initial),
                      .exit_code = 0,
                      .name = std::move(name)};
  record->step = std::move(step);
  if (!start_suspended) {
    record->ready_sequence = next_ready_sequence_++;
  }
  threads_.emplace(id, std::move(record));
  return id;
}

void GuestScheduler::MarkReady(const std::shared_ptr<ThreadRecord>& thread) {
  thread->snapshot.state = ThreadState::Ready;
  thread->ready_sequence = next_ready_sequence_++;
  thread->wake_tick = 0;
  thread->wait_value = 0;
}

bool GuestScheduler::Resume(const ThreadId id) {
  std::scoped_lock lock{mutex_};
  const auto found = threads_.find(id);
  if (found == threads_.end() || found->second->snapshot.state == ThreadState::Terminated ||
      found->second->snapshot.state == ThreadState::Cancelled) {
    return false;
  }
  MarkReady(found->second);
  return true;
}

bool GuestScheduler::Suspend(const ThreadId id) {
  std::scoped_lock lock{mutex_};
  const auto found = threads_.find(id);
  if (found == threads_.end() || found->second->snapshot.state == ThreadState::Running ||
      found->second->snapshot.state == ThreadState::Terminated ||
      found->second->snapshot.state == ThreadState::Cancelled) {
    return false;
  }
  found->second->snapshot.state = ThreadState::Suspended;
  return true;
}

void GuestScheduler::WakeJoiners(const ThreadId target) {
  for (auto& [id, thread] : threads_) {
    (void)id;
    if (thread->snapshot.state == ThreadState::WaitingJoin && thread->wait_value == target) {
      MarkReady(thread);
    }
  }
}

bool GuestScheduler::Cancel(const ThreadId id) {
  std::scoped_lock lock{mutex_};
  const auto found = threads_.find(id);
  if (found == threads_.end() || found->second->snapshot.state == ThreadState::Running ||
      found->second->snapshot.state == ThreadState::Terminated ||
      found->second->snapshot.state == ThreadState::Cancelled) {
    return false;
  }
  found->second->snapshot.state = ThreadState::Cancelled;
  WakeJoiners(id);
  return true;
}

bool GuestScheduler::Send(const std::uint64_t queue) {
  std::scoped_lock lock{mutex_};
  std::shared_ptr<ThreadRecord> selected;
  for (const auto& [id, thread] : threads_) {
    (void)id;
    if (thread->snapshot.state != ThreadState::WaitingQueue || thread->wait_value != queue) {
      continue;
    }
    if (!selected || thread->snapshot.priority < selected->snapshot.priority ||
        (thread->snapshot.priority == selected->snapshot.priority &&
         thread->ready_sequence < selected->ready_sequence)) {
      selected = thread;
    }
  }
  if (!selected) {
    return false;
  }
  MarkReady(selected);
  return true;
}

void GuestScheduler::SetBackgrounded(const bool backgrounded) {
  std::scoped_lock lock{mutex_};
  backgrounded_ = backgrounded;
}

void GuestScheduler::ConfigureViRetrace(const std::uint64_t operations_per_retrace,
                                        RetraceCallback callback) {
  std::scoped_lock lock{mutex_};
  vi_period_ = operations_per_retrace;
  vi_callback_ = std::move(callback);
  next_vi_operation_ = operations_ + vi_period_;
}

void GuestScheduler::WakeDueAlarms() {
  for (auto& [id, thread] : threads_) {
    (void)id;
    if (thread->snapshot.state == ThreadState::Sleeping && thread->wake_tick <= tick_) {
      MarkReady(thread);
    }
  }
}

std::shared_ptr<GuestScheduler::ThreadRecord> GuestScheduler::ChooseReady() const {
  std::shared_ptr<ThreadRecord> selected;
  for (const auto& [id, thread] : threads_) {
    (void)id;
    if (thread->snapshot.state != ThreadState::Ready) {
      continue;
    }
    if (!selected || thread->snapshot.priority < selected->snapshot.priority ||
        (thread->snapshot.priority == selected->snapshot.priority &&
         thread->ready_sequence < selected->ready_sequence)) {
      selected = thread;
    }
  }
  return selected;
}

std::optional<std::uint64_t> GuestScheduler::NextWakeTick() const {
  std::optional<std::uint64_t> next;
  for (const auto& [id, thread] : threads_) {
    (void)id;
    if (thread->snapshot.state == ThreadState::Sleeping &&
        (!next || thread->wake_tick < *next)) {
      next = thread->wake_tick;
    }
  }
  return next;
}

GuestScheduler::RunResult GuestScheduler::RunOne() {
  std::shared_ptr<ThreadRecord> selected;
  {
    std::unique_lock lock{mutex_};
    if (shutdown_) {
      return RunResult::Shutdown;
    }
    if (backgrounded_) {
      return RunResult::Suspended;
    }
    WakeDueAlarms();
    selected = ChooseReady();
    if (!selected) {
      const auto next_wake = NextWakeTick();
      if (!next_wake) {
        return RunResult::Idle;
      }
      tick_ = std::max(tick_, *next_wake);
      WakeDueAlarms();
      return RunResult::AdvancedToAlarm;
    }
    selected->snapshot.state = ThreadState::Running;
  }

  // Guest/translated code runs with no scheduler lock held.
  const StepAction action = selected->step(selected->snapshot.context);
  RetraceCallback retrace;
  std::uint64_t retrace_index = 0;
  bool shutdown_during_step = false;
  {
    std::unique_lock lock{mutex_};
    ++operations_;
    ++tick_;
    if (shutdown_) {
      selected->snapshot.state = ThreadState::Cancelled;
      shutdown_during_step = true;
    } else {
      switch (action.kind) {
    case StepAction::Kind::Yield:
      MarkReady(selected);
      break;
    case StepAction::Kind::SleepUntil:
      selected->snapshot.state = ThreadState::Sleeping;
      selected->wake_tick = std::max(action.value, tick_);
      break;
    case StepAction::Kind::WaitQueue:
      selected->snapshot.state = ThreadState::WaitingQueue;
      selected->wait_value = action.value;
      break;
    case StepAction::Kind::WaitJoin: {
      const auto target = threads_.find(action.value);
      if (target == threads_.end() || target->second->snapshot.state == ThreadState::Terminated ||
          target->second->snapshot.state == ThreadState::Cancelled) {
        MarkReady(selected);
      } else {
        selected->snapshot.state = ThreadState::WaitingJoin;
        selected->wait_value = action.value;
      }
      break;
    }
    case StepAction::Kind::Exit:
      selected->snapshot.state = ThreadState::Terminated;
      selected->snapshot.exit_code = action.value;
      WakeJoiners(selected->snapshot.id);
      break;
    }
    }

    if (vi_period_ != 0 && operations_ >= next_vi_operation_) {
      retrace = vi_callback_;
      retrace_index = operations_ / vi_period_;
      next_vi_operation_ += vi_period_;
    }
  }
  if (retrace) {
    retrace(retrace_index);
  }
  return shutdown_during_step ? RunResult::Shutdown : RunResult::Executed;
}

std::uint64_t GuestScheduler::Run(const std::uint64_t maximum_operations) {
  const std::uint64_t start = OperationCount();
  while (OperationCount() - start < maximum_operations) {
    const RunResult result = RunOne();
    if (result == RunResult::Idle || result == RunResult::Suspended ||
        result == RunResult::Shutdown) {
      break;
    }
  }
  return OperationCount() - start;
}

void GuestScheduler::Shutdown() {
  std::scoped_lock lock{mutex_};
  shutdown_ = true;
  for (auto& [id, thread] : threads_) {
    (void)id;
    if (thread->snapshot.state != ThreadState::Terminated) {
      thread->snapshot.state = ThreadState::Cancelled;
    }
  }
}

void GuestScheduler::ReapTerminated() {
  std::scoped_lock lock{mutex_};
  std::erase_if(threads_, [](const auto& entry) {
    return entry.second->snapshot.state == ThreadState::Terminated ||
           entry.second->snapshot.state == ThreadState::Cancelled;
  });
}

std::optional<GuestScheduler::ThreadSnapshot> GuestScheduler::Snapshot(const ThreadId id) const {
  std::scoped_lock lock{mutex_};
  const auto found = threads_.find(id);
  return found == threads_.end() ? std::nullopt
                                : std::optional<ThreadSnapshot>{found->second->snapshot};
}

std::vector<GuestScheduler::ThreadSnapshot> GuestScheduler::SnapshotAll() const {
  std::scoped_lock lock{mutex_};
  std::vector<ThreadSnapshot> result;
  result.reserve(threads_.size());
  for (const auto& [id, thread] : threads_) {
    (void)id;
    result.push_back(thread->snapshot);
  }
  std::sort(result.begin(), result.end(), [](const ThreadSnapshot& left, const ThreadSnapshot& right) {
    return left.id < right.id;
  });
  return result;
}

std::uint64_t GuestScheduler::LogicalTick() const {
  std::scoped_lock lock{mutex_};
  return tick_;
}

std::uint64_t GuestScheduler::OperationCount() const {
  std::scoped_lock lock{mutex_};
  return operations_;
}

std::size_t GuestScheduler::ThreadCount() const {
  std::scoped_lock lock{mutex_};
  return threads_.size();
}

}  // namespace kartpad::scheduler
