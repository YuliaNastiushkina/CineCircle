@testable import CineCircle
import XCTest

@MainActor
final class TVEpisodeProgressTests: XCTestCase {
    func testFetchSeasonUsesTVSeasonEndpoint() async {
        let episode = makeEpisode(id: 101, number: 1)
        let client = MockAPIClient { path, query in
            XCTAssertEqual(path, "tv/55/season/2")
            XCTAssertEqual(query["language"], "en-US")
            return RemoteTVSeasonDetail(id: 22, name: "Season 2", seasonNumber: 2, episodes: [episode])
        }
        let viewModel = TVSeasonViewModel(client: client)

        await viewModel.fetchSeason(showID: 55, seasonNumber: 2)

        XCTAssertEqual(viewModel.episodes.map(\.id), [101])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testEpisodeProgressPersistsPerUserAndShow() throws {
        let suiteName = "TVEpisodeProgressTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = TVEpisodeProgressService(defaults: defaults)

        service.setWatched(true, episodeID: 101, userID: "userA", showID: 55)

        XCTAssertEqual(service.watchedEpisodeIDs(userID: "userA", showID: 55), [101])
        XCTAssertTrue(service.watchedEpisodeIDs(userID: "userB", showID: 55).isEmpty)
        XCTAssertTrue(service.watchedEpisodeIDs(userID: "userA", showID: 99).isEmpty)
    }

    func testTrackedShowsIncludeProgressMetadata() throws {
        let suiteName = "TVEpisodeProgressTrackedTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = TVEpisodeProgressService(defaults: defaults)

        service.setWatched(
            true,
            episodeID: 101,
            userID: "userA",
            showID: 55,
            seasonNumber: 2,
            episodeNumber: 4
        )
        service.setWatched(true, episodeID: 102, userID: "userA", showID: 55)
        service.setWatched(true, episodeID: 301, userID: "userA", showID: 99)

        let trackedShows = service.trackedShows(userID: "userA")

        XCTAssertEqual(Set(trackedShows.map(\.id)), [55, 99])
        let show = try XCTUnwrap(trackedShows.first { $0.id == 55 })
        XCTAssertEqual(show.watchedEpisodeCount, 2)
        XCTAssertEqual(show.lastEpisodeCode, "S2 E4")
    }

    func testMarkAndClearEntireSeason() throws {
        let suiteName = "TVEpisodeProgressSeasonTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = TVEpisodeProgressService(defaults: defaults)

        service.setSeasonWatched(true, episodeIDs: [1, 2, 3], userID: "user", showID: 8)
        XCTAssertEqual(service.watchedEpisodeIDs(userID: "user", showID: 8), [1, 2, 3])

        service.setSeasonWatched(false, episodeIDs: [1, 2, 3], userID: "user", showID: 8)
        XCTAssertTrue(service.watchedEpisodeIDs(userID: "user", showID: 8).isEmpty)
    }

    private func makeEpisode(id: Int, number: Int) -> RemoteTVEpisode {
        RemoteTVEpisode(
            id: id,
            name: "Episode \(number)",
            overview: "",
            episodeNumber: number,
            seasonNumber: 2,
            airDate: "2025-01-01",
            runtime: 45,
            stillPath: nil
        )
    }
}
