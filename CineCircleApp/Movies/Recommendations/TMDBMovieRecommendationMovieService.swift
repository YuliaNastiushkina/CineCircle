import Foundation

/// Retrieves real movies from TMDB for AI-generated intent and returns locally ranked candidates.
struct TMDBMovieRecommendationMovieService: MovieRecommendationMovieServiceProtocol {
    private let client: APIClientProtocol
    private let scorer: MovieRecommendationScorer
    private let candidateLimit: Int

    init(
        client: APIClientProtocol = APIClient(),
        scorer: MovieRecommendationScorer = MovieRecommendationScorer(),
        candidateLimit: Int = 80
    ) {
        self.client = client
        self.scorer = scorer
        self.candidateLimit = candidateLimit
    }

    func rankedMovies(for intent: MovieRecommendationIntent) async throws -> [RemoteMovie] {
        var collector = CandidateCollector(limit: candidateLimit)

        for query in intent.searchQueries {
            try Task.checkCancellation()
            let response = try await searchMovies(query: query, language: intent.language)
            collector.add(response.results)
        }

        let keywordDiscoveryGenres = keywordDiscoveryGenres(for: intent)
        for keywordIDs in try await keywordGroups(for: intent) {
            try Task.checkCancellation()
            let response = try await discoverMovies(intent: intent, genres: keywordDiscoveryGenres, keywordIDs: keywordIDs)
            collector.add(response.results)
        }

        if !intent.genres.isEmpty || intent.hasDiscoverFilters {
            try Task.checkCancellation()
            let response = try await discoverMovies(intent: intent, genres: intent.genres, keywordIDs: [])
            collector.add(response.results)
        }

        return collector
            .rankedMovies(intent: intent, scorer: scorer)
    }

    private func searchMovies(query: String, language: String?) async throws -> MovieResponse {
        try await client.fetch(
            path: "search/movie",
            query: [
                "language": searchLanguage(from: language),
                "page": "1",
                "query": query,
            ],
            responseType: MovieResponse.self
        )
    }

    private func searchLanguage(from language: String?) -> String {
        guard let language else { return "en-US" }
        return "\(language)-\(language.uppercased())"
    }

    private func keywordDiscoveryGenres(for intent: MovieRecommendationIntent) -> [MoviesGenre] {
        let genres = intent.genres.filter { $0 != .fantasy && !intent.excludedGenres.contains($0) }
        return Array(genres.prefix(2))
    }

    private func keywordGroups(for intent: MovieRecommendationIntent) async throws -> [[Int]] {
        var groups: [[Int]] = []

        for query in keywordQueries(for: intent) {
            try Task.checkCancellation()
            let response = try await searchKeywords(query: query)
            let ids = response.results.prefix(3).map(\.id)

            if !ids.isEmpty {
                groups.append(ids)
            }
        }

        return groups
    }

    private func keywordQueries(for intent: MovieRecommendationIntent) -> [String] {
        var queries: [String] = []
        appendKeywordQueries(from: intent.keywordProbes, to: &queries)
        appendKeywordQueries(from: intent.mustMatchConcepts, to: &queries)
        appendKeywordQueries(from: intent.requiredThemes, to: &queries)
        appendKeywordQueries(from: intent.themes, to: &queries)
        appendKeywordQueries(from: intent.shouldMatchConcepts, to: &queries)
        appendKeywordQueries(from: intent.preferredThemes, to: &queries)
        return Array(queries.prefix(MovieRecommendationIntent.maxKeywordProbes))
    }

    private func appendKeywordQueries(from values: [String], to queries: inout [String]) {
        for value in values {
            let normalizedValue = value.normalizedForKeywordSearch
            guard !normalizedValue.isEmpty else { continue }

            switch normalizedValue {
            case "christmas", "holiday", "holidays", "xmas":
                appendUnique("christmas", to: &queries)
                appendUnique("christmas eve", to: &queries)
                appendUnique("santa claus", to: &queries)
                appendUnique("holiday", to: &queries)
            case "pirates", "pirate":
                appendUnique("pirate", to: &queries)
                appendUnique("pirates", to: &queries)
            case "treasure hunt", "treasure", "hidden treasure", "lost treasure", "treasure map":
                appendUnique("treasure hunt", to: &queries)
                appendUnique("hidden treasure", to: &queries)
                appendUnique("treasure map", to: &queries)
            default:
                appendUnique(normalizedValue, to: &queries)
            }
        }
    }

    private func appendUnique(_ value: String, to values: inout [String]) {
        guard !values.contains(value) else { return }
        values.append(value)
    }

    private func searchKeywords(query: String) async throws -> MovieKeywordResponse {
        try await client.fetch(
            path: "search/keyword",
            query: [
                "page": "1",
                "query": query,
            ],
            responseType: MovieKeywordResponse.self
        )
    }

    private func discoverMovies(intent: MovieRecommendationIntent, genres: [MoviesGenre], keywordIDs: [Int]) async throws -> MovieResponse {
        var query = [
            "language": searchLanguage(from: intent.language),
            "page": "1",
            "include_adult": "false",
            "sort_by": "popularity.desc",
            "vote_count.gte": "80",
        ]

        if !genres.isEmpty {
            query["with_genres"] = genres.map { String($0.id) }.joined(separator: "|")
        }

        if !keywordIDs.isEmpty {
            query["with_keywords"] = keywordIDs.map(String.init).joined(separator: "|")
        }

        if let runtimeMin = intent.runtimeMin {
            query["with_runtime.gte"] = String(runtimeMin)
        }

        if let runtimeMax = intent.runtimeMax {
            query["with_runtime.lte"] = String(runtimeMax)
        }

        if let releaseYearMin = intent.releaseYearMin {
            query["primary_release_date.gte"] = "\(releaseYearMin)-01-01"
        }

        if let releaseYearMax = intent.releaseYearMax {
            query["primary_release_date.lte"] = "\(releaseYearMax)-12-31"
        }

        if let language = intent.language {
            query["with_original_language"] = language
        }

        return try await client.fetch(
            path: "discover/movie",
            query: query,
            responseType: MovieResponse.self
        )
    }
}

struct MovieKeywordResponse: Decodable {
    let results: [MovieKeyword]
}

struct MovieKeyword: Decodable {
    let id: Int
    let name: String
}

private extension MovieRecommendationIntent {
    var hasDiscoverFilters: Bool {
        runtimeMin != nil || runtimeMax != nil || releaseYearMin != nil || releaseYearMax != nil || language != nil
    }
}

private extension String {
    var normalizedForKeywordSearch: String {
        lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
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
                let scoreDifference = abs(lhsScore - rhsScore)

                if scoreDifference > Self.relevanceTieThreshold {
                    return lhsScore > rhsScore
                }

                let lhsQualityScore = qualityTieBreakerScore(for: lhs.movie)
                let rhsQualityScore = qualityTieBreakerScore(for: rhs.movie)
                if lhsQualityScore != rhsQualityScore {
                    return lhsQualityScore > rhsQualityScore
                }

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

    private static let relevanceTieThreshold = 18.0

    private func qualityTieBreakerScore(for movie: RemoteMovie) -> Double {
        let popularityScore = min(log10(max(movie.popularity ?? 0, 0) + 1) / 4, 1)
        let voteConfidence = min(log10(Double(max(movie.voteCount, 0)) + 1) / 5, 1)
        let ratingScore = min(max(movie.voteAverage, 0) / 10, 1)
        return popularityScore * 0.5 + voteConfidence * 0.35 + ratingScore * 0.15
    }

    private func isUsable(_ movie: RemoteMovie) -> Bool {
        !movie.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
