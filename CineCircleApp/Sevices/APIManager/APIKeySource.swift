import Foundation

protocol APIKeySource {
    var obfuscatedKey: [UInt8] { get }
    var salt: [UInt8] { get }
}
