#include "kartpad/network/blocking_stream_wait.h"

#include <iostream>

namespace {

bool Check(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << '\n';
    }
    return condition;
}

}  // namespace

int main() {
    using namespace KartPad::Network;

    bool ok = true;
    ok &= Check(kBlockingStreamReceiveWaitMilliseconds == 5000,
                "blocking receive uses the production-tested five-second window");
    ok &= Check(StreamReceiveWaitMilliseconds(false, false) == 5000,
                "logically blocking receive waits for a public NAS response");
    ok &= Check(StreamReceiveWaitMilliseconds(true, false) == 0,
                "MSG_DONTWAIT-style receive remains immediate");
    ok &= Check(StreamReceiveWaitMilliseconds(false, true) == 0,
                "nonblocking socket receive remains immediate");
    ok &= Check(StreamReceiveWaitMilliseconds(true, true) == 0,
                "all nonblocking combinations remain immediate");
    return ok ? 0 : 1;
}
