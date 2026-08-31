#pragma once

#if !defined(__APPLE__)
#error "apple_secure_transport.h is only available on Apple platforms"
#endif

#include <Security/SecureTransport.h>

#include <cerrno>
#include <cstddef>
#include <sys/socket.h>

namespace kartpad::network {

enum class SecureTransportResult {
  kSuccess,
  kWouldBlock,
  kClosed,
  kHostnameMismatch,
  kFailed,
};

inline SecureTransportResult ClassifySecureTransportStatus(OSStatus status) {
  switch (status) {
    case noErr:
      return SecureTransportResult::kSuccess;
    case errSSLWouldBlock:
      return SecureTransportResult::kWouldBlock;
    case errSSLClosedGraceful:
    case errSSLClosedNoNotify:
      return SecureTransportResult::kClosed;
    case errSSLHostNameMismatch:
      return SecureTransportResult::kHostnameMismatch;
    default:
      return SecureTransportResult::kFailed;
  }
}

// Secure Transport keeps this opaque pointer and returns it to the callbacks.
// Point it at a socket owned by the surrounding session; the socket value may
// change during a WFC 443-to-80 reconnect without rebuilding the TLS context.
inline OSStatus SecureTransportSocketRead(SSLConnectionRef connection,
                                          void* data,
                                          size_t* data_length) {
  if (connection == nullptr || data == nullptr || data_length == nullptr) {
    return errSSLInternal;
  }
  const int socket = *static_cast<const int*>(connection);
  const size_t requested = *data_length;
  *data_length = 0;
  if (socket < 0 || requested == 0) {
    return requested == 0 ? static_cast<OSStatus>(noErr)
                          : static_cast<OSStatus>(errSSLClosedAbort);
  }

  for (;;) {
    const ssize_t received = recv(socket, data, requested, 0);
    if (received > 0) {
      *data_length = static_cast<size_t>(received);
      return static_cast<size_t>(received) == requested
                 ? static_cast<OSStatus>(noErr)
                 : static_cast<OSStatus>(errSSLWouldBlock);
    }
    if (received == 0) {
      return errSSLClosedGraceful;
    }
    if (errno == EINTR) {
      continue;
    }
    return errno == EAGAIN || errno == EWOULDBLOCK ? errSSLWouldBlock
                                                   : errSSLClosedAbort;
  }
}

inline OSStatus SecureTransportSocketWrite(SSLConnectionRef connection,
                                           const void* data,
                                           size_t* data_length) {
  if (connection == nullptr || data == nullptr || data_length == nullptr) {
    return errSSLInternal;
  }
  const int socket = *static_cast<const int*>(connection);
  const size_t requested = *data_length;
  *data_length = 0;
  if (socket < 0 || requested == 0) {
    return requested == 0 ? static_cast<OSStatus>(noErr)
                          : static_cast<OSStatus>(errSSLClosedAbort);
  }

  for (;;) {
    const ssize_t sent = send(socket, data, requested, 0);
    if (sent > 0) {
      *data_length = static_cast<size_t>(sent);
      return static_cast<size_t>(sent) == requested
                 ? static_cast<OSStatus>(noErr)
                 : static_cast<OSStatus>(errSSLWouldBlock);
    }
    if (sent == 0) {
      return errSSLClosedGraceful;
    }
    if (errno == EINTR) {
      continue;
    }
    return errno == EAGAIN || errno == EWOULDBLOCK ? errSSLWouldBlock
                                                   : errSSLClosedAbort;
  }
}

}  // namespace kartpad::network
