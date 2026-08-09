import Foundation

struct ProfileLibrarySectionLoadRequest {
    let watchedMovies: [ProfileMovieSnapshot]
    let savedMovies: [ProfileMovieSnapshot]
    let seenTVShows: [TVShowLibraryRecord]
    let trackedTVShows: [TVShowProgressRecord]
    let previewMovieCount: Int
    let previewNoteCount: Int
}

struct ProfileLibrarySectionsSnapshot {
    let watchedMovies: [ProfileMovieSnapshot]
    let savedMovies: [ProfileMovieSnapshot]
    let seenTVShows: [TVShowLibraryRecord]
    let trackedShows: [ProfileTrackedTVShowItem]
    let noteItems: [ProfileNoteItem]
}

@MainActor
struct ProfileLibrarySectionLoader {
    let userId: String

    private let apiClient = APIClient()
    private let noteService = NoteService.shared

    func loadSections(_ request: ProfileLibrarySectionLoadRequest) async -> ProfileLibrarySectionsSnapshot {
        let watchedPreview = Array(request.watchedMovies.prefix(request.previewMovieCount))
        let savedPreview = Array(request.savedMovies.prefix(request.previewMovieCount))

        async let enrichedWatched = enrichMovies(watchedPreview)
        async let enrichedSaved = enrichMovies(savedPreview)
        async let loadedTrackedShows = loadTrackedShowItems(
            trackedTVShows: request.trackedTVShows,
            previewMovieCount: request.previewMovieCount
        )
        async let loadedNotes = loadNoteItems(previewNoteCount: request.previewNoteCount)

        let trackedShowResult = await loadedTrackedShows

        return await ProfileLibrarySectionsSnapshot(
            watchedMovies: enrichedWatched,
            savedMovies: enrichedSaved,
            seenTVShows: mergedSeenShows(request.seenTVShows, with: trackedShowResult.completedShows),
            trackedShows: trackedShowResult.trackingShows,
            noteItems: loadedNotes
        )
    }

    private func enrichMovies(_ movies: [ProfileMovieSnapshot]) async -> [ProfileMovieSnapshot] {
        var enrichedMovies = movies

        for index in enrichedMovies.indices {
            guard needsEnrichment(enrichedMovies[index]) else { continue }

            do {
                let detail = try await apiClient.fetch(
                    path: "movie/\(enrichedMovies[index].id)",
                    query: [:],
                    responseType: RemoteMovieDetail.self
                )

                enrichedMovies[index] = ProfileMovieSnapshot(
                    id: detail.id,
                    title: detail.title,
                    posterPath: detail.posterPath,
                    createdAt: enrichedMovies[index].createdAt
                )
            } catch {
                continue
            }
        }

        return enrichedMovies
    }

    private func needsEnrichment(_ movie: ProfileMovieSnapshot) -> Bool {
        movie.posterPath == nil || movie.title == "Movie #\(movie.id)"
    }

    private func mergedSeenShows(
        _ seenTVShows: [TVShowLibraryRecord],
        with completedShows: [TVShowLibraryRecord]
    ) -> [TVShowLibraryRecord] {
        var recordsByID = Dictionary(uniqueKeysWithValues: seenTVShows.map { ($0.id, $0) })
        for show in completedShows where recordsByID[show.id] == nil {
            recordsByID[show.id] = show
        }
        return recordsByID.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func loadTrackedShowItems(
        trackedTVShows: [TVShowProgressRecord],
        previewMovieCount: Int
    ) async -> ProfileTrackedShowLoadResult {
        let progressRecords = Array(trackedTVShows.prefix(previewMovieCount))
        var trackingShows: [ProfileTrackedTVShowItem] = []
        var completedShows: [TVShowLibraryRecord] = []

        for record in progressRecords {
            do {
                let detail = try await apiClient.fetch(
                    path: "tv/\(record.id)",
                    query: [:],
                    responseType: RemoteTVShowDetail.self
                )

                if detail.numberOfEpisodes > 0, record.watchedEpisodeCount >= detail.numberOfEpisodes {
                    let completedShow = TVShowLibraryRecord(
                        id: detail.id,
                        title: detail.name,
                        posterPath: detail.posterPath,
                        updatedAt: record.updatedAt == .distantPast ? Date() : record.updatedAt
                    )
                    completedShows.append(completedShow)
                    TVShowLibraryService().set(
                        .seen,
                        isSet: true,
                        showID: detail.id,
                        userID: userId,
                        title: detail.name,
                        posterPath: detail.posterPath
                    )
                    continue
                }

                trackingShows.append(
                    ProfileTrackedTVShowItem(
                        id: detail.id,
                        title: detail.name,
                        posterPath: detail.posterPath,
                        watchedEpisodeCount: record.watchedEpisodeCount,
                        totalEpisodeCount: detail.numberOfEpisodes,
                        updatedAt: record.updatedAt,
                        lastEpisodeCode: record.lastEpisodeCode
                    )
                )
            } catch {
                trackingShows.append(
                    ProfileTrackedTVShowItem(
                        id: record.id,
                        title: "TV Show #\(record.id)",
                        posterPath: nil,
                        watchedEpisodeCount: record.watchedEpisodeCount,
                        totalEpisodeCount: nil,
                        updatedAt: record.updatedAt,
                        lastEpisodeCode: record.lastEpisodeCode
                    )
                )
            }
        }

        return ProfileTrackedShowLoadResult(
            trackingShows: trackingShows.sorted { $0.updatedAt > $1.updatedAt },
            completedShows: completedShows
        )
    }

    private func loadNoteItems(previewNoteCount: Int) async -> [ProfileNoteItem] {
        let notes = Array(noteService.allNotes(for: userId).prefix(previewNoteCount))
        let ids = Set(
            notes
                .filter { $0.diaryMediaType == .movie && ($0.movieTitle ?? "").isEmpty }
                .map { Int($0.movieID) }
        )
        var titlesByID: [Int: String] = [:]

        for id in ids {
            do {
                let detail = try await apiClient.fetch(
                    path: "movie/\(id)",
                    query: [:],
                    responseType: RemoteMovieDetail.self
                )
                titlesByID[id] = detail.title
            } catch {
                titlesByID[id] = "Movie #\(id)"
            }
        }

        return notes.map { note in
            let movieID = Int(note.movieID)
            return ProfileNoteItem(
                id: note.objectID.uriRepresentation().absoluteString,
                mediaType: note.diaryMediaType,
                movieID: movieID,
                title: note.diaryMediaType == .movie
                    ? note.movieTitle ?? titlesByID[movieID] ?? "Movie #\(movieID)"
                    : note.diaryDisplayTitle,
                subtitle: note.diarySubtitle,
                content: note.content ?? "",
                createdAt: note.createdAt,
                watchedDate: note.watchedDate,
                moods: MovieDiaryMood.decoded(from: note.mood),
                watchType: MovieDiaryWatchType(rawValue: note.watchType ?? "") ?? .firstWatch,
                watchedWith: MovieDiaryWatchedWith(rawValue: note.watchedWith ?? "") ?? .alone,
                hasSpoilers: note.hasSpoilers
            )
        }
    }
}
