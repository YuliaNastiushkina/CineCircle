import Foundation

struct MockAPIKeys: APIKeySource {
    let obfuscatedKey: [UInt8]
    let salt: [UInt8]
}
