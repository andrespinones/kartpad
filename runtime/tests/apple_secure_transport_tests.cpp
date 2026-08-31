#include <kartpad/network/apple_secure_transport.h>

#include <array>
#include <cstdio>
#include <cstring>
#include <sys/socket.h>
#include <unistd.h>

namespace {

bool Check(bool condition, const char* message) {
  if (!condition) {
    std::fprintf(stderr, "Apple Secure Transport contract failure: %s\n",
                 message);
  }
  return condition;
}

}  // namespace

int main() {
  using kartpad::network::ClassifySecureTransportStatus;
  using kartpad::network::SecureTransportResult;
  using kartpad::network::SecureTransportSocketRead;
  using kartpad::network::SecureTransportSocketWrite;

  bool passed = true;
  passed &= Check(ClassifySecureTransportStatus(noErr) ==
                      SecureTransportResult::kSuccess,
                  "noErr classification");
  passed &= Check(ClassifySecureTransportStatus(errSSLWouldBlock) ==
                      SecureTransportResult::kWouldBlock,
                  "would-block classification");
  passed &= Check(ClassifySecureTransportStatus(errSSLClosedGraceful) ==
                      SecureTransportResult::kClosed,
                  "closed classification");
  passed &= Check(ClassifySecureTransportStatus(errSSLHostNameMismatch) ==
                      SecureTransportResult::kHostnameMismatch,
                  "hostname classification");
  passed &= Check(ClassifySecureTransportStatus(errSSLBadRecordMac) ==
                      SecureTransportResult::kFailed,
                  "generic failure classification");

  std::array<int, 2> sockets{-1, -1};
  passed &= Check(socketpair(AF_UNIX, SOCK_STREAM, 0, sockets.data()) == 0,
                  "socketpair creation");
  if (sockets[0] < 0 || sockets[1] < 0) {
    return 1;
  }

  constexpr char incoming[] = "hello";
  passed &= Check(send(sockets[1], incoming, sizeof(incoming) - 1, 0) ==
                      static_cast<ssize_t>(sizeof(incoming) - 1),
                  "fixture send");
  std::array<char, 8> read_buffer{};
  size_t read_size = sizeof(incoming) - 1;
  OSStatus status = SecureTransportSocketRead(
      &sockets[0], read_buffer.data(), &read_size);
  passed &= Check(status == noErr, "complete callback read status");
  passed &= Check(read_size == sizeof(incoming) - 1,
                  "complete callback read size");
  passed &= Check(std::memcmp(read_buffer.data(), incoming, read_size) == 0,
                  "complete callback read payload");

  constexpr char outgoing[] = "world";
  size_t write_size = sizeof(outgoing) - 1;
  status = SecureTransportSocketWrite(&sockets[0], outgoing, &write_size);
  passed &= Check(status == noErr, "complete callback write status");
  passed &= Check(write_size == sizeof(outgoing) - 1,
                  "complete callback write size");
  std::array<char, 8> peer_buffer{};
  const ssize_t peer_read = recv(sockets[1], peer_buffer.data(), write_size, 0);
  passed &= Check(peer_read == static_cast<ssize_t>(write_size),
                  "peer callback write size");
  passed &= Check(std::memcmp(peer_buffer.data(), outgoing, write_size) == 0,
                  "peer callback write payload");

  close(sockets[1]);
  sockets[1] = -1;
  read_size = 1;
  status = SecureTransportSocketRead(&sockets[0], read_buffer.data(), &read_size);
  passed &= Check(status == errSSLClosedGraceful,
                  "closed-peer callback read status");
  passed &= Check(read_size == 0, "closed-peer callback read size");

  close(sockets[0]);
  return passed ? 0 : 1;
}
