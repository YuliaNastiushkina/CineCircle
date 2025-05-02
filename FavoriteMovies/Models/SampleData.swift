import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()
    let modelContainer: ModelContainer
    var context: ModelContext {
        modelContainer.mainContext
    }

    var friend: Friend {
        Friend.sampleData.first!
    }

    var movie: Movie {
        Movie.sampleData.first!
    }

    var castMember: CastMember {
        CastMember.sampleData.first!
    }

    private init() {
        let schema = Schema([
            Friend.self,
            Movie.self,
            CastMember.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

            insertSampleData()

            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func insertSampleData() {
        for friend in Friend.sampleData {
            context.insert(friend)
        }

        for movie in Movie.sampleData {
            context.insert(movie)
        }

        for castMember in CastMember.sampleData {
            context.insert(castMember)
        }

        Friend.sampleData[2].favoriteMovie = Movie.sampleData[0]
        Friend.sampleData[3].favoriteMovie = Movie.sampleData[4]
        Friend.sampleData[4].favoriteMovie = Movie.sampleData[0]
        Friend.sampleData[0].favoriteMovie = Movie.sampleData[0]

        Movie.sampleData[5].cast = [CastMember.sampleData[0], CastMember.sampleData[1], CastMember.sampleData[4]]
        Movie.sampleData[1].cast = [CastMember.sampleData[2], CastMember.sampleData[3]]
        Movie.sampleData[0].cast = [CastMember.sampleData[2]]
    }
}
