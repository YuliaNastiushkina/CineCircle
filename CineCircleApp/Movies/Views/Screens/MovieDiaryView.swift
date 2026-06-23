import SwiftUI

struct MovieDiaryView: View {
    let target: MovieDiaryEntryTarget
    let userId: String
    let title: String
    let subtitle: String?
    let parentTitle: String?
    let navigationTitle: String
    let onSave: (() -> Void)?

    init(movieId: Int, userId: String, movieTitle: String) {
        target = .movie(movieId: movieId)
        self.userId = userId
        title = movieTitle
        subtitle = nil
        parentTitle = nil
        navigationTitle = "Movie Diary"
        onSave = nil
    }

    init(
        target: MovieDiaryEntryTarget,
        userId: String,
        title: String,
        subtitle: String? = nil,
        parentTitle: String? = nil,
        navigationTitle: String = "Diary",
        onSave: (() -> Void)? = nil
    ) {
        self.target = target
        self.userId = userId
        self.title = title
        self.subtitle = subtitle
        self.parentTitle = parentTitle ?? subtitle
        self.navigationTitle = navigationTitle
        self.onSave = onSave
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isReflectionFocused: Bool

    @State private var privateReflection: String = ""
    @State private var watchedDate: Date = .now
    @State private var watchType: MovieDiaryWatchType = .firstWatch
    @State private var watchedWith: MovieDiaryWatchedWith = .alone
    @State private var selectedMoods: [MovieDiaryMood] = []
    @State private var hasSpoilers: Bool = false
    @State private var saveError: String?
    @State private var isSaveErrorPresented: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                    header
                        .simultaneousGesture(TapGesture().onEnded { isReflectionFocused = false })
                    watchedDetailsSection
                    moodSection
                        .simultaneousGesture(TapGesture().onEnded { isReflectionFocused = false })
                    spoilerSection
                        .simultaneousGesture(TapGesture().onEnded { isReflectionFocused = false })
                    reflectionSection
                }
                .padding(Parameters.contentPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDiaryEntry()
                    }
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.toolbarFontSize))
                }
            }
            .onAppear(perform: loadExistingEntry)
            .alert("Failed to Save Diary", isPresented: $isSaveErrorPresented) {
                Button("OK", role: .cancel) {
                    isSaveErrorPresented = false
                }
            } message: {
                Text(saveError ?? "Unknown error")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Parameters.headerSpacing) {
            Text(title)
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.movieTitleFontSize))
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.subtitleFontSize))
                    .foregroundStyle(.secondary)
            }

            Text("Capture what this watch felt like. This stays private unless sharing is added later.")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.captionFontSize))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var watchedDetailsSection: some View {
        VStack(alignment: .leading, spacing: Parameters.controlSpacing) {
            sectionTitle("Watched")

            DatePicker("Date", selection: $watchedDate, displayedComponents: .date)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                .simultaneousGesture(TapGesture().onEnded { isReflectionFocused = false })

            Picker("Watch type", selection: $watchType) {
                ForEach(MovieDiaryWatchType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .simultaneousGesture(TapGesture().onEnded { isReflectionFocused = false })

            VStack(alignment: .leading, spacing: Parameters.smallControlSpacing) {
                Text("With")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                    .foregroundStyle(.primary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Parameters.withChipSpacing) {
                        ForEach(MovieDiaryWatchedWith.allCases) { option in
                            Button {
                                watchedWith = option
                                isReflectionFocused = false
                            } label: {
                                Text(option.title)
                                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.chipFontSize))
                                    .foregroundStyle(watchedWith == option ? .black : .primary)
                                    .lineLimit(1)
                                    .padding(.horizontal, Parameters.withChipHorizontalPadding)
                                    .padding(.vertical, Parameters.chipVerticalPadding)
                                    .background(watchedWith == option ? AppUI.ColorPalette.accent : AppUI.ColorPalette.softCardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Parameters.withScrollHorizontalInset)
                }
                .scrollClipDisabled()
            }
            .simultaneousGesture(TapGesture().onEnded { isReflectionFocused = false })
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Parameters.controlSpacing) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("Mood")

                Spacer()

                Text("\(selectedMoods.count)/\(Parameters.maximumMoodCount)")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.captionFontSize))
                    .foregroundStyle(.secondary)
            }

            Text("Choose up to three feelings that describe this watch.")
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.captionFontSize))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Parameters.moodColumns, alignment: .leading, spacing: Parameters.chipSpacing) {
                ForEach(MovieDiaryMood.allCases) { mood in
                    Button {
                        toggleMood(mood)
                    } label: {
                        Text(mood.title)
                            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.chipFontSize))
                            .foregroundStyle(isMoodSelected(mood) ? .black : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(Parameters.chipMinimumScaleFactor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Parameters.chipVerticalPadding)
                            .padding(.horizontal, Parameters.chipHorizontalPadding)
                            .background(isMoodSelected(mood) ? AppUI.ColorPalette.accent : AppUI.ColorPalette.softCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var spoilerSection: some View {
        Toggle(isOn: $hasSpoilers) {
            VStack(alignment: .leading, spacing: Parameters.toggleTextSpacing) {
                Text("Contains spoilers")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.bodyFontSize))
                Text("Useful later if you choose to share a take from this diary entry.")
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.captionFontSize))
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .padding(Parameters.cardPadding)
        .background(AppUI.ColorPalette.softCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: Parameters.controlSpacing) {
            sectionTitle("Private reflection")

            TextEditor(text: $privateReflection)
                .focused($isReflectionFocused)
                .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                .scrollContentBackground(.hidden)
                .padding(Parameters.editorInnerPadding)
                .frame(minHeight: Parameters.editorMinHeight)
                .background(AppUI.ColorPalette.softCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card))
                .overlay(alignment: .topLeading) {
                    if privateReflection.isEmpty {
                        Text("What stayed with you after watching this?")
                            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                            .foregroundStyle(.secondary.opacity(Parameters.placeholderOpacity))
                            .padding(Parameters.placeholderPadding)
                            .allowsHitTesting(false)
                    }
                }
                .onTapGesture {
                    isReflectionFocused = true
                }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.sectionTitleFontSize))
            .foregroundStyle(.primary)
    }

    private func loadExistingEntry() {
        guard let existing = NoteService.shared.fetchDiaryEntries(for: target, userId: userId).first else { return }

        privateReflection = existing.content ?? ""
        watchedDate = existing.watchedDate ?? existing.createdAt ?? .now
        watchType = MovieDiaryWatchType(rawValue: existing.watchType ?? "") ?? .firstWatch
        watchedWith = MovieDiaryWatchedWith(rawValue: existing.watchedWith ?? "") ?? .alone
        selectedMoods = Array(MovieDiaryMood.decoded(from: existing.mood).prefix(Parameters.maximumMoodCount))
        hasSpoilers = existing.hasSpoilers
    }

    private func saveDiaryEntry() {
        let error = NoteService.shared.createOrUpdateDiaryEntry(
            for: target,
            userId: userId,
            draft: MovieDiaryEntryDraft(
                privateReflection: privateReflection,
                title: title,
                parentTitle: parentTitle,
                watchedDate: watchedDate,
                watchType: watchType,
                moods: selectedMoods,
                watchedWith: watchedWith,
                hasSpoilers: hasSpoilers
            )
        )

        if let error {
            saveError = error.localizedDescription
            isSaveErrorPresented = true
        } else {
            onSave?()
            dismiss()
        }
    }

    private func isMoodSelected(_ mood: MovieDiaryMood) -> Bool {
        selectedMoods.contains(mood)
    }

    private func toggleMood(_ mood: MovieDiaryMood) {
        if selectedMoods.contains(mood) {
            selectedMoods.removeAll { $0 == mood }
        } else if selectedMoods.count < Parameters.maximumMoodCount {
            selectedMoods.append(mood)
        }
    }

    private enum Parameters {
        static let maximumMoodCount = 3
        static let contentPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let controlSpacing: CGFloat = 12
        static let smallControlSpacing: CGFloat = 6
        static let headerSpacing: CGFloat = 6
        static let toggleTextSpacing: CGFloat = 2
        static let cardPadding: CGFloat = 14
        static let withChipSpacing: CGFloat = 10
        static let withChipHorizontalPadding: CGFloat = 14
        static let withScrollHorizontalInset: CGFloat = 2
        static let editorInnerPadding: CGFloat = 8
        static let editorMinHeight: CGFloat = 220
        static let placeholderOpacity: Double = 0.7
        static let placeholderPadding: CGFloat = 16
        static let chipSpacing: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 10
        static let chipHorizontalPadding: CGFloat = 8
        static let chipMinimumScaleFactor: CGFloat = 0.85
        static let toolbarFontSize: CGFloat = 16
        static let movieTitleFontSize: CGFloat = 20
        static let subtitleFontSize: CGFloat = 13
        static let sectionTitleFontSize: CGFloat = 16
        static let bodyFontSize: CGFloat = 14
        static let captionFontSize: CGFloat = 12
        static let chipFontSize: CGFloat = 13
        static let moodColumns = [GridItem(.flexible()), GridItem(.flexible())]
    }
}

#Preview {
    MovieDiaryView(movieId: 1, userId: "previewUser", movieTitle: "Preview Movie")
}
