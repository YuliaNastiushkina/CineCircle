#if DEBUG
    import Foundation
    import SwiftUI

    private struct PreviewAPIClient: APIClientProtocol {
        func fetch<T: Decodable>(
            path _: String,
            query _: [String: String],
            responseType _: T.Type
        ) async throws -> T {
            throw URLError(.badServerResponse)
        }
    }

    private struct PreviewRecommendationService: MovieRecommendationServiceProtocol {
        func recommendationIntent(for prompt: String) async throws -> MovieRecommendationIntent {
            MovieRecommendationIntent(searchQueries: [prompt], fallbackPrompt: prompt)
        }
    }

    private struct PreviewRecommendationMovieService: MovieRecommendationMovieServiceProtocol {
        func rankedMovies(for _: MovieRecommendationIntent) async throws -> [RemoteMovie] {
            []
        }
    }

    @MainActor private func makePreviewMovieListViewModel(isAIMode: Bool) -> MovieListViewModel {
        let viewModel = MovieListViewModel(
            client: PreviewAPIClient(),
            recommendationIntentService: PreviewRecommendationService(),
            fallbackRecommendationIntentService: PreviewRecommendationService(),
            recommendationMovieService: PreviewRecommendationMovieService()
        )

        if isAIMode {
            viewModel.enterAIMode()
        }

        return viewModel
    }

    private struct MovieSearchControlsPreview: View {
        @State private var viewModel: MovieListViewModel
        @FocusState private var isPromptFocused: Bool
        private let forceFallbackAIGlass: Bool

        init(isAIMode: Bool, forceFallbackAIGlass: Bool = false) {
            _viewModel = State(initialValue: makePreviewMovieListViewModel(isAIMode: isAIMode))
            self.forceFallbackAIGlass = forceFallbackAIGlass
        }

        var body: some View {
            VStack {
                MovieSearchControls(
                    viewModel: viewModel,
                    isAIPromptFocused: $isPromptFocused,
                    forceFallbackAIGlass: forceFallbackAIGlass,
                    submitAIRecommendationPrompt: {}
                )
                Spacer()
            }
            .padding(.top, 120)
            .background(Color(.systemBackground))
        }
    }

    #Preview("Movie Search Controls") {
        MovieSearchControlsPreview(isAIMode: false)
    }

    #Preview("AI Search Controls") {
        MovieSearchControlsPreview(isAIMode: true)
    }

    #Preview("AI Fallback Search") {
        MovieSearchControlsPreview(isAIMode: true, forceFallbackAIGlass: true)
    }
#endif
