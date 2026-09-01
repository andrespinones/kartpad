#pragma once

namespace KartPad::Network {

// Nintendo's NHTTP worker uses a logically blocking TCP receive while waiting
// for NAS authentication. Public-service latency regularly exceeds the old
// 250 ms host-side grace period, which made a healthy HTTP response look like
// a transport failure. Nonblocking guest calls must still return immediately.
inline constexpr int kBlockingStreamReceiveWaitMilliseconds = 5000;

constexpr int StreamReceiveWaitMilliseconds(bool forceNonblocking,
                                             bool socketNonblocking) {
    return (forceNonblocking || socketNonblocking)
        ? 0
        : kBlockingStreamReceiveWaitMilliseconds;
}

}  // namespace KartPad::Network
