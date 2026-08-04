import Foundation

/// Retrieves real movies from TMDB for AI-generated intent and returns locally ranked candidates.
struct TMDBMovieRecommendationMovieService: MovieRecommendationMovieServiceProtocol {
    private let client: APIClientProtocol
    private let scorer: MovieRecommendationScorer
    private let candidateLimit: Int

    init(
        client: APIClientProtocol = APIClient(),
        scorer: MovieRecommendationScorer = MovieRecommendationScorer(),
        candidateLimit: Int = 40
    ) {
        self.client = client
        self.scorer = scorer
        self.candidateLimit = candidateLimit
    }

    func rankedMovies(for intent: MovieRecommendationIntent) async throws -> [RemoteMovie] {
        var collector = CandidateCollector(limit: candidateLimit)

        for query in intent.searchQueries {
            try Task.checkCancellation()
            let response = try await searchMovies(query: query)
            collector.add(response.results)
            guard !collector.isFull else { break }
        }

        if !collector.isFull, !intent.genres.isEmpty {
            try Task.checkCancellation()
            let response = try await discoverMovies(genres: intent.genres)
            collector.add(response.results)
        }

        return collector
            .rankedMovies(intent: intent, scorer: scorer)
    }

    private func searchMovies(query: String) async throws -> MovieResponse {
        try await client.fetch(
            path: "search/movie",
            query: [
                "language": "en-US",
                "page": "1",
                "query": query,
            ],
            responseType: MovieResponse.self
        )
    }

    private func discoverMovies(genres: [MoviesGenre]) async throws -> MovieResponse {
        try await client.fetch(
            path: "discover/movie",
            query: [
                "language": "en-US",
                "page": "1",
                "sort_by": "popularity.desc",
                "with_genres": genres.map { String($0.id) }.joined(separator: ","),
            ],
            responseType: MovieResponse.self
        )
    }
}

private struct CandidateCollector {
    private struct Candidate {
        var movie: RemoteMovie
        var appearanceCount: Int
        let sourceOrder: Int
    }

    private let limit: Int
    private var candidatesByID: [Int: Candidate] = [:]
    private var nextSourceOrder = 0

    var isFull: Bool {
        candidatesByID.count >= limit
    }

    init(limit: Int) {
        self.limit = max(1, limit)
    }

    mutating func add(_ movies: [RemoteMovie]) {
        for movie in movies where isUsable(movie) {
            if var candidate = candidatesByID[movie.id] {
                candidate.appearanceCount += 1
                candidatesByID[movie.id] = candidate
            } else if candidatesByID.count < limit {
                candidatesByID[movie.id] = Candidate(
                    movie: movie,
                    appearanceCount: 1,
                    sourceOrder: nextSourceOrder
                )
                nextSourceOrder += 1
            }
        }
    }

    func rankedMovies(intent: MovieRecommendationIntent, scorer: MovieRecommendationScorer) -> [RemoteMovie] {
        candidatesByID.values
            .sorted { lhs, rhs in
                let lhsScore = scorer.score(lhs.movie, intent: intent, appearanceCount: lhs.appearanceCount)
                let rhsScore = scorer.score(rhs.movie, intent: intent, appearanceCount: rhs.appearanceCount)

                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }

                if lhs.sourceOrder != rhs.sourceOrder {
                    return lhs.sourceOrder < rhs.sourceOrder
                }

                return lhs.movie.title.localizedCaseInsensitiveCompare(rhs.movie.title) == .orderedAscending
            }
            .map(\.movie)
    }

    private func isUsable(_ movie: RemoteMovie) -> Bool {
        !movie.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
