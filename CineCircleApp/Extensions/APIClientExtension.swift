/// Conformance of the real `APIClient` to the `APIClientProtocol`.
/// Allows injecting the real client where a protocol-based abstraction is used.
extension APIClient: APIClientProtocol {}
