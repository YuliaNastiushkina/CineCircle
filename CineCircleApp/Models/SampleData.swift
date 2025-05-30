// swiftlint:disable force_unwrapping
import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()
    let modelContainer: ModelContainer
    var context: ModelContext {
        modelContainer.mainContext
    }

    var movie: Movie {
        Movie.sampleData.first!
    }

    var castMember: CastMember {
        CastMember.sampleData.first!
    }

    private init() {
        let schema = Schema([
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
        for movie in Movie.sampleData {
            context.insert(movie)
        }

        for castMember in CastMember.sampleData {
            context.insert(castMember)
        }

        Movie.sampleData[5].cast = [CastMember.sampleData[0], CastMember.sampleData[1], CastMember.sampleData[4]]
        Movie.sampleData[1].cast = [CastMember.sampleData[2], CastMember.sampleData[3]]
        Movie.sampleData[0].cast = [CastMember.sampleData[2]]
    }
}
