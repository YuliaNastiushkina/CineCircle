import SwiftUI

struct AIStatusMessageView: View {
    let message: String?

    var body: some View {
        if let message {
            HStack(spacing: MoviesListLayout.statusMessageSpacing) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.statusMessageFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
            .padding(.bottom, MoviesListLayout.statusMessageBottomPadding)
            .background(Color(.systemBackground))
        }
    }
}

struct AILoadingView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: MoviesListLayout.aiLoadingSpacing) {
            ZStack {
                Circle()
                    .fill(AppUI.ColorPalette.accent.opacity(0.22))
                    .frame(
                        width: MoviesListLayout.aiLoadingOuterCircle,
                        height: MoviesListLayout.aiLoadingOuterCircle
                    )
                    .scaleEffect(pulse ? MoviesListLayout.aiLoadingPulseMaxScale : MoviesListLayout.aiLoadingPulseMinScale)

                Image(systemName: "sparkles")
                    .font(.system(size: MoviesListLayout.aiLoadingIconSize, weight: .semibold))
                    .foregroundStyle(AppUI.ColorPalette.accent)
            }

            Text("Thinking through your request")
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.aiLoadingTitleFontSize))

            Text("Comparing themes, mood, and popularity")
                .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.aiLoadingSubtitleFontSize))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
        .onAppear {
            withAnimation(.easeInOut(duration: MoviesListLayout.aiLoadingPulseDuration).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct AIResultsHeaderView: View {
    let viewModel: MovieListViewModel
    let clearAction: () -> Void

    var body: some View {
        if viewModel.isAIMode, !viewModel.rankedRecommendationMovies.isEmpty {
            VStack(alignment: .leading, spacing: MoviesListLayout.resultsHeaderSpacing) {
                HStack {
                    Label("AI Picks", systemImage: "sparkles")
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MoviesListLayout.resultsTitleFontSize))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(action: clearAction) {
                        Label("Clear", systemImage: "trash")
                            .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.resultsActionFontSize))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                if let explanation = viewModel.recommendationExplanation {
                    Text(explanation)
                        .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.resultsExplanationFontSize))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
            .padding(.bottom, MoviesListLayout.resultsHeaderBottomPadding)
            .background(Color(.systemBackground))
        }
    }
}

struct AIPaginationControlsView: View {
    let viewModel: MovieListViewModel
    let showPreviousAction: () -> Void
    let showNextAction: () -> Void

    var body: some View {
        if viewModel.canShowNextRecommendations || viewModel.canShowPreviousRecommendations || viewModel.shouldSuggestRefiningAIRequest {
            VStack(spacing: MoviesListLayout.paginationVerticalSpacing) {
                HStack(spacing: MoviesListLayout.paginationSpacing) {
                    if viewModel.canShowPreviousRecommendations {
                        Button(action: showPreviousAction) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: MoviesListLayout.paginationIconSize, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(
                                    width: MoviesListLayout.paginationIconFrame,
                                    height: MoviesListLayout.paginationIconFrame
                                )
                                .background(AppUI.ColorPalette.secondarySurface, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.canShowNextRecommendations {
                        AIAccentCapsuleButton(
                            title: "Show others",
                            systemImage: "sparkles",
                            action: showNextAction
                        )
                    }
                }

                if viewModel.shouldSuggestRefiningAIRequest {
                    Text("Try adding more detail to get closer picks.")
                        .font(Font.custom(AppUI.FontName.poppins, size: MoviesListLayout.paginationHintFontSize))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MoviesListLayout.searchHorizontalPadding)
            .padding(.vertical, MoviesListLayout.paginationVerticalPadding)
            .background(Color(.systemBackground))
        }
    }
}
