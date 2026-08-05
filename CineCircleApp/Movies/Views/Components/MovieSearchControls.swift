import SwiftUI

struct MovieSearchControls: View {
    @Bindable var viewModel: MovieListViewModel
    let isAIPromptFocused: FocusState<Bool>.Binding
    let forceFallbackAIGlass: Bool
    let submitAIRecommendationPrompt: () -> Void

    @Namespace private var searchTransition

    init(
        viewModel: MovieListViewModel,
        isAIPromptFocused: FocusState<Bool>.Binding,
        forceFallbackAIGlass: Bool = false,
        submitAIRecommendationPrompt: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.isAIPromptFocused = isAIPromptFocused
        self.forceFallbackAIGlass = forceFallbackAIGlass
        self.submitAIRecommendationPrompt = submitAIRecommendationPrompt
    }

    var body: some View {
        VStack(spacing: MovieSearchControlsLayout.searchVerticalSpacing) {
            if viewModel.isAIMode {
                aiPromptBar
            } else {
                normalSearchBar
            }
        }
        .padding(.horizontal, MovieSearchControlsLayout.searchHorizontalPadding)
        .padding(.bottom, MovieSearchControlsLayout.searchBottomPadding)
        .background(Color(.systemBackground))
        .animation(searchModeAnimation, value: viewModel.isAIMode)
    }

    private var normalSearchBar: some View {
        HStack(spacing: MovieSearchControlsLayout.searchControlSpacing) {
            MovieSearchCapsule(
                text: $viewModel.filterText,
                placeholder: "Search movies",
                systemImage: "magnifyingglass",
                style: .standard,
                transitionNamespace: searchTransition,
                submitAction: viewModel.scheduleSearch
            )

            AIAccentCapsuleButton(
                title: "AI",
                systemImage: "sparkles",
                action: enterAIMode
            )
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            .transaction { transaction in
                transaction.animation = buttonModeAnimation
            }
        }
    }

    private var aiPromptBar: some View {
        HStack(alignment: .center, spacing: MovieSearchControlsLayout.searchControlSpacing) {
            MovieSearchCapsule(
                text: $viewModel.aiPromptText,
                placeholder: "Find something for tonight",
                systemImage: "sparkles",
                style: .ai(forceFallbackGlass: forceFallbackAIGlass),
                isDisabled: viewModel.isLoadingRecommendations,
                focus: isAIPromptFocused,
                transitionNamespace: searchTransition,
                submitAction: submitPromptAndDismissKeyboard
            )

            AIAccentIconButton(
                systemImage: viewModel.isLoadingRecommendations ? "hourglass" : "sparkle.magnifyingglass",
                isDisabled: !viewModel.canSubmitAIRecommendationPrompt,
                action: submitPromptAndDismissKeyboard
            )
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            .transaction { transaction in
                transaction.animation = buttonModeAnimation
            }

            Button(action: exitAIMode) {
                Image(systemName: "xmark")
                    .font(.system(size: MovieSearchControlsLayout.aiIconButtonSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: MovieSearchControlsLayout.aiIconButtonFrame, height: MovieSearchControlsLayout.aiIconButtonFrame)
                    .background(AppUI.ColorPalette.secondarySurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            .transaction { transaction in
                transaction.animation = buttonModeAnimation
            }
        }
    }

    private var searchModeAnimation: Animation {
        .spring(
            response: MovieSearchControlsLayout.searchModeAnimationResponse,
            dampingFraction: MovieSearchControlsLayout.searchModeAnimationDamping
        )
    }

    private var buttonModeAnimation: Animation {
        .easeOut(duration: MovieSearchControlsLayout.buttonModeAnimationDuration)
    }

    private func enterAIMode() {
        withAnimation(searchModeAnimation) {
            viewModel.enterAIMode()
        }
    }

    private func exitAIMode() {
        isAIPromptFocused.wrappedValue = false
        withAnimation(searchModeAnimation) {
            viewModel.exitAIMode()
        }
    }

    private func submitPromptAndDismissKeyboard() {
        guard viewModel.canSubmitAIRecommendationPrompt else { return }
        isAIPromptFocused.wrappedValue = false
        submitAIRecommendationPrompt()
    }
}

struct MovieSearchCapsule: View {
    enum Style {
        case standard
        case ai(forceFallbackGlass: Bool)
    }

    @Binding var text: String
    let placeholder: String
    let systemImage: String
    let style: Style
    let isDisabled: Bool
    let focus: FocusState<Bool>.Binding?
    let transitionNamespace: Namespace.ID
    let submitAction: () -> Void

    init(
        text: Binding<String>,
        placeholder: String,
        systemImage: String,
        style: Style,
        isDisabled: Bool = false,
        focus: FocusState<Bool>.Binding? = nil,
        transitionNamespace: Namespace.ID,
        submitAction: @escaping () -> Void
    ) {
        _text = text
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.style = style
        self.isDisabled = isDisabled
        self.focus = focus
        self.transitionNamespace = transitionNamespace
        self.submitAction = submitAction
    }

    var body: some View {
        HStack(alignment: .center, spacing: MovieSearchControlsLayout.searchIconSpacing) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)

            textField
        }
        .padding(.horizontal, MovieSearchControlsLayout.searchFieldHorizontalPadding)
        .padding(.vertical, MovieSearchControlsLayout.searchFieldVerticalPadding)
        .frame(minHeight: MovieSearchControlsLayout.searchFieldHeight)
        .background {
            capsuleBackground
        }
        .overlay {
            capsuleShape
                .stroke(borderStyle, lineWidth: borderWidth)
                .allowsHitTesting(false)
        }
        .contentShape(capsuleShape)
        .onTapGesture {
            focus?.wrappedValue = true
        }
        .shadow(color: glowColor, radius: glowRadius, x: 0, y: 2)
        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 1)
        .matchedGeometryEffect(id: MovieSearchControlsLayout.searchTransitionID, in: transitionNamespace)
    }

    @ViewBuilder
    private var textField: some View {
        if let focus {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(searchFont)
                .lineLimit(1...4)
                .submitLabel(.search)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .focused(focus)
                .disabled(isDisabled)
                .onSubmit(submitAction)
        } else {
            TextField(placeholder, text: $text)
                .font(searchFont)
                .submitLabel(.search)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isDisabled)
                .onSubmit(submitAction)
        }
    }

    @ViewBuilder
    private var capsuleBackground: some View {
        switch style {
        case .standard:
            capsuleShape
                .fill(AppUI.ColorPalette.secondarySurface)

        case let .ai(forceFallbackGlass):
            if !forceFallbackGlass, #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(
                        .regular.tint(AppUI.ColorPalette.accent.opacity(MovieSearchControlsLayout.aiPromptGlassTintOpacity)).interactive(),
                        in: capsuleShape
                    )
            } else {
                capsuleShape
                    .fill(.ultraThinMaterial)

                capsuleShape
                    .fill(aiFallbackSurface)

                capsuleShape
                    .fill(glassHighlight)
            }
        }
    }

    private var capsuleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MovieSearchControlsLayout.searchFieldHeight / 2, style: .continuous)
    }

    private var searchFont: Font {
        Font.custom(AppUI.FontName.poppins, size: MovieSearchControlsLayout.searchFontSize)
    }

    private var iconColor: Color {
        switch style {
        case .standard: .secondary
        case .ai: AppUI.ColorPalette.accent
        }
    }

    private var borderStyle: LinearGradient {
        switch style {
        case .standard:
            LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ai:
            LinearGradient(
                colors: [
                    .white.opacity(0.94),
                    AppUI.ColorPalette.accent.opacity(0.12),
                    .black.opacity(0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .standard: 0
        case .ai: MovieSearchControlsLayout.aiPromptStrokeWidth
        }
    }

    private var glowColor: Color {
        switch style {
        case .standard: .clear
        case .ai: AppUI.ColorPalette.accent.opacity(MovieSearchControlsLayout.aiPromptGlowOpacity)
        }
    }

    private var glowRadius: CGFloat {
        switch style {
        case .standard: 0
        case .ai: 4
        }
    }

    private var shadowOpacity: CGFloat {
        switch style {
        case .standard: 0
        case .ai: 0.04
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .standard: 0
        case .ai: 3
        }
    }

    private var aiFallbackSurface: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.98),
                .white.opacity(0.9),
                AppUI.ColorPalette.accent.opacity(0.01),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glassHighlight: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.22),
                .white.opacity(0.05),
                .clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AIAccentCapsuleButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: MovieSearchControlsLayout.aiButtonFontSize))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.black)
                .padding(.horizontal, MovieSearchControlsLayout.aiButtonHorizontalPadding)
                .frame(height: MovieSearchControlsLayout.searchFieldHeight)
                .background(AppUI.ColorPalette.accent, in: Capsule())
                .overlay {
                    Capsule()
                        .fill(aiGlassHighlight)
                }
                .overlay {
                    Capsule()
                        .stroke(aiAccentStroke, lineWidth: MovieSearchControlsLayout.aiControlStrokeWidth)
                }
                .shadow(color: AppUI.ColorPalette.accent.opacity(0.14), radius: 5, x: 0, y: 3)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct AIAccentIconButton: View {
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: MovieSearchControlsLayout.aiIconButtonSize, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: MovieSearchControlsLayout.aiIconButtonFrame, height: MovieSearchControlsLayout.aiIconButtonFrame)
                .background(AppUI.ColorPalette.accent, in: Circle())
                .overlay {
                    Circle()
                        .fill(aiGlassHighlight)
                }
                .overlay {
                    Circle()
                        .stroke(aiAccentStroke, lineWidth: MovieSearchControlsLayout.aiControlStrokeWidth)
                }
                .shadow(color: AppUI.ColorPalette.accent.opacity(0.14), radius: 5, x: 0, y: 3)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private var aiAccentStroke: LinearGradient {
    LinearGradient(
        colors: [
            .white.opacity(0.78),
            AppUI.ColorPalette.accent.opacity(0.85),
            .white.opacity(0.32),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private var aiGlassHighlight: LinearGradient {
    LinearGradient(
        colors: [
            .white.opacity(0.38),
            .white.opacity(0.12),
            .clear,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum MovieSearchControlsLayout {
    static let searchHorizontalPadding: CGFloat = 16
    static let searchBottomPadding: CGFloat = 10
    static let searchVerticalSpacing: CGFloat = 8
    static let searchControlSpacing: CGFloat = 8
    static let searchIconSpacing: CGFloat = 8
    static let searchFieldHeight: CGFloat = 42
    static let searchFieldVerticalPadding: CGFloat = 6
    static let searchModeAnimationResponse = 0.58
    static let searchModeAnimationDamping = 0.82
    static let buttonModeAnimationDuration = 0.16
    static let searchTransitionID = "movieSearchSurface"
    static let searchFieldHorizontalPadding: CGFloat = 14
    static let searchFontSize: CGFloat = 14

    static let aiPromptStrokeWidth: CGFloat = 1.25
    static let aiPromptGlassTintOpacity = 0.035
    static let aiPromptGlowOpacity = 0.025
    static let aiButtonFontSize: CGFloat = 13
    static let aiButtonHorizontalPadding: CGFloat = 14
    static let aiIconButtonSize: CGFloat = 14
    static let aiIconButtonFrame: CGFloat = 42
    static let aiControlStrokeWidth: CGFloat = 1
}
