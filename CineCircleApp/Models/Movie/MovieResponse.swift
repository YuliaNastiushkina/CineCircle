import Foundation

struct MovieResponse: Decodable {
    let results: [RemoteMovie]
}
