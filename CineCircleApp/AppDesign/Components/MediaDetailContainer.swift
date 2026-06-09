import SwiftUI

private enum MediaDetailContainerParameters {
    static let animationDuration: TimeInterval = 0.2
    static let fractionalHeight: CGFloat = 0.47
    static let sheetCornerRadius: CGFloat = 24
    static let dismissTranslation: CGFloat = 100
}

private enum MediaPosterHeaderParameters {
    static let posterBaseURL = "https://image.tmdb.org/t/p/w500"
    static let ratingFontSize: CGFloat = 16
    static let ratingPaddingVertical: CGFloat = 10
    static let ratingPaddingHorizontal: CGFloat = 16
    static let bottomPadding: CGFloat = 24
    static let topPadding: CGFloat = 84
    static let posterHeightRatio: CGFloat = 0.7
    static let overlayHeightRatio: CGFloat = 0.66
    static let posterContainerHeightRatio: CGFloat = 0.5
}

struct MediaDetailContainer<Header: View, Content: View, BottomInset: View>: View {
    let header: (@escaping () -> Void) -> Header
    let content: () -> Content
    let bottomInset: () -> BottomInset

    @Environment(\.dismiss) private var dismiss
    @State private var showingBottomSheet = true

    init(
        @ViewBuilder header: @escaping (@escaping () -> Void) -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder bottomInset: @escaping () -> BottomInset
    ) {
        self.header = header
        self.content = content
        self.bottomInset = bottomInset
    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                header(dismissScreen)
            }
            .sheet(isPresented: $showingBottomSheet) {
                NavigationStack {
                    ScrollView {
                        content()
                            .padding(.top)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    bottomInset()
                }
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
                .presentationDetents([.fraction(MediaDetailContainerParameters.fractionalHeight), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .large))
                .presentationCornerRadius(MediaDetailContainerParameters.sheetCornerRadius)
                .presentationBackground(Color(.systemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > MediaDetailContainerParameters.dismissTranslation {
                    dismissScreen()
                }
            }
        )
    }

    private func dismissScreen() {
        withAnimation(.easeOut(duration: MediaDetailContainerParameters.animationDuration)) {
            showingBottomSheet = false
        }
        dismiss()
    }
}

extension MediaDetailContainer where BottomInset == EmptyView {
    init(
        @ViewBuilder header: @escaping (@escaping () -> Void) -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(header: header, content: content, bottomInset: EmptyView.init)
    }
}

struct MediaPosterHeaderView<TopTrailing: View, BottomTrailing: View>: View {
    let posterPath: String?
    let rating: Double
    let onDismiss: () -> Void
    let topTrailing: () -> TopTrailing
    let bottomTrailing: () -> BottomTrailing

    init(
        posterPath: String?,
        rating: Double,
        onDismiss: @escaping () -> Void,
        @ViewBuilder topTrailing: @escaping () -> TopTrailing,
        @ViewBuilder bottomTrailing: @escaping () -> BottomTrailing
    ) {
        self.posterPath = posterPath
        self.rating = rating
        self.onDismiss = onDismiss
        self.topTrailing = topTrailing
        self.bottomTrailing = bottomTrailing
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                posterImage(geometry: geometry)
                overlayContent(geometry: geometry)
            }
            .frame(height: geometry.size.height * MediaPosterHeaderParameters.posterContainerHeightRatio)
            .navigationBarBackButtonHidden(true)
        }
    }

    private func posterImage(geometry: GeometryProxy) -> some View {
        Group {
            if let posterPath,
               let url = URL(string: MediaPosterHeaderParameters.posterBaseURL + posterPath) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * MediaPosterHeaderParameters.posterHeightRatio
                            )
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * MediaPosterHeaderParameters.posterHeightRatio
                            )
                            .clipped()
                            .mask(posterMask)
                    default:
                        posterFallback(geometry: geometry)
                    }
                }
                .ignoresSafeArea(edges: .top)
            } else {
                posterFallback(geometry: geometry)
                    .ignoresSafeArea(edges: .top)
            }
        }
    }

    private func posterFallback(geometry: GeometryProxy) -> some View {
        Color.gray
            .frame(
                width: geometry.size.width,
                height: geometry.size.height * MediaPosterHeaderParameters.posterHeightRatio
            )
    }

    private var posterMask: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.95),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func overlayContent(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                CircleButton(systemName: "chevron.left", action: onDismiss)
                    .foregroundStyle(.white)
                Spacer()
                topTrailing()
            }
            .padding(.horizontal)
            .padding(.top, MediaPosterHeaderParameters.topPadding)

            Spacer()

            HStack {
                ratingView
                Spacer()
                bottomTrailing()
            }
            .padding(.horizontal)
            .padding(.bottom, MediaPosterHeaderParameters.bottomPadding)
        }
        .frame(height: geometry.size.height * MediaPosterHeaderParameters.overlayHeightRatio)
    }

    private var ratingView: some View {
        HStack {
            Text(String(format: "%.1f", rating))
                .font(Font.custom(AppUI.FontName.poppins, size: MediaPosterHeaderParameters.ratingFontSize))
                .foregroundStyle(.white)

            Image(systemName: "star.fill")
                .foregroundStyle(AppUI.ColorPalette.accent)
                .font(Font.custom(AppUI.FontName.poppins, size: MediaPosterHeaderParameters.ratingFontSize))
        }
        .padding(.vertical, MediaPosterHeaderParameters.ratingPaddingVertical)
        .padding(.horizontal, MediaPosterHeaderParameters.ratingPaddingHorizontal)
        .background(Color(white: 0.32).opacity(0.8))
        .clipShape(Capsule())
    }
}
