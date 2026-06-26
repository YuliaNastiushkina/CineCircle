import SwiftUI
import UIKit

struct ProfileView: View {
    // MARK: Private interface

    @State private var showGenrePicker = false
    @State private var isEditing = false
    @State private var showNameAlert = false
    @State private var showSaveConfirmation = false
    @State private var showImagePicker = false
    @State private var showDeleteAccountConfirmation = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var deleteAccountPassword = ""
    @State private var selectedProfileImage: UIImage?
    @FocusState private var isNameFieldFocused: Bool

    // MARK: Internal interface

    let userId: String
    @StateObject private var viewModel: ProfileViewModel

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId, authService: FirebaseAuthService()))
    }

    var body: some View {
        NavigationStack {
            mainScrollView
                .background(Color(.systemBackground))
                .overlay {
                    overlayViews
                }
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showGenrePicker, onDismiss: {
                    viewModel.saveFavoriteGenres()
                }) {
                    GenrePickerView(selectedGenres: $viewModel.favoriteGenres)
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImage: $selectedProfileImage)
                }
                .alert("Name Required", isPresented: $showNameAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please enter your name before saving your profile.")
                }
                .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete Account", role: .destructive) {
                        Task {
                            await viewModel.deleteAccount()
                        }
                    }
                } message: {
                    Text("This permanently deletes your CineCircle account and local profile, library, and diary data on this device.")
                }
                .alert("Confirm Account Deletion", isPresented: $viewModel.needsReauthentication) {
                    SecureField("Password", text: $deleteAccountPassword)
                    Button("Cancel", role: .cancel) {
                        deleteAccountPassword = ""
                        viewModel.needsReauthentication = false
                    }
                    Button("Delete Account", role: .destructive) {
                        let password = deleteAccountPassword
                        deleteAccountPassword = ""
                        Task {
                            await viewModel.reauthenticateAndDeleteAccount(password: password)
                        }
                    }
                } message: {
                    Text("For security, Firebase requires a recent sign-in before deleting an account. Enter your password to continue.")
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    await viewModel.loadProfile()
                    await viewModel.refreshAccountStatus()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await viewModel.refreshAccountStatus()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .userLibraryDidChange)) { _ in
                    viewModel.loadStats()
                }
                .onReceive(NotificationCenter.default.publisher(for: .tvShowLibraryDidChange)) { notification in
                    guard notification.userInfo?["userID"] as? String == userId else { return }
                    viewModel.loadStats()
                }
                .onReceive(NotificationCenter.default.publisher(for: .tvEpisodeProgressDidChange)) { notification in
                    guard notification.userInfo?["userID"] as? String == userId else { return }
                    viewModel.loadStats()
                }
                .onChange(of: selectedProfileImage) { _, newImage in
                    if newImage != nil {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                    viewModel.setProfileImage(newImage)
                }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: Parameters.sectionSpacing) {
                profileHeaderSection
                emailVerificationReminder
                profileGenresSection
                nameEditingSection
                if !isEditing {
                    ProfileLibrarySectionsView(
                        userId: userId,
                        watchedMovieIDs: viewModel.watchedMovieIDs,
                        savedMovieIDs: viewModel.savedMovieIDs,
                        watchedMovies: viewModel.watchedMovies,
                        savedMovies: viewModel.savedMovies,
                        seenTVShows: viewModel.seenTVShows,
                        savedTVShows: viewModel.savedTVShows,
                        trackedTVShows: viewModel.trackedTVShows,
                        refreshToken: viewModel.libraryRefreshToken
                    )
                    .transition(.opacity)
                }
                signOutSection
            }
            .padding(.horizontal, Parameters.horizontalPadding)
            .padding(.top, Parameters.topPadding)
        }
    }

    @ViewBuilder
    private var profileHeaderSection: some View {
        ProfileHeaderView(
            viewModel: viewModel,
            isEditing: isEditing,
            profileImage: viewModel.profileImage,
            stats: viewModel.movieStats,
            seenTVShowCount: viewModel.seenTVShows.count,
            onProfileImageTap: {
                showImagePicker = true
            }
        )
    }

    @ViewBuilder
    private var emailVerificationReminder: some View {
        EmailVerificationReminderView(viewModel: viewModel)
    }

    @ViewBuilder
    private var profileGenresSection: some View {
        if !isEditing {
            ProfileGenresView(
                viewModel: viewModel,
                showGenrePicker: {
                    showGenrePicker = true
                }
            )
        }
    }

    @ViewBuilder
    private var nameEditingSection: some View {
        if isEditing {
            VStack(alignment: .leading, spacing: Parameters.nameSectionSpacing) {
                Text("Name")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.nameLabelFontSize))
                    .foregroundColor(.primary)

                TextField("Enter your name", text: $viewModel.name)
                    .font(Font.custom(AppUI.FontName.poppins, size: Parameters.nameFieldFontSize))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Parameters.nameFieldVerticalPadding)
                    .padding(.horizontal, Parameters.nameFieldHorizontalPadding)
                    .background(AppUI.ColorPalette.softCardBackground)
                    .cornerRadius(AppUI.Radius.card)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFieldFocused = false
                    }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var signOutSection: some View {
        if !isEditing {
            VStack(spacing: Parameters.accountSectionSpacing) {
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.accountMessageFontSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                ProfileSignOutView(
                    signOutAction: {
                        Task {
                            viewModel.signOut()
                        }
                    },
                    deleteAccountAction: {
                        showDeleteAccountConfirmation = true
                    },
                    isDeletingAccount: viewModel.isDeletingAccount
                )
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var overlayViews: some View {
        Group {
            if showSaveConfirmation {
                saveConfirmationToast
            }
        }
    }

    @ViewBuilder
    private var saveConfirmationToast: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Profile saved!")
                    .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.toastFontSize))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, Parameters.toastHorizontalPadding)
            .padding(.vertical, Parameters.toastVerticalPadding)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .shadow(
                        color: .black.opacity(Parameters.toastShadowOpacity),
                        radius: Parameters.toastShadowRadius,
                        x: 0,
                        y: Parameters.toastShadowYOffset
                    )
            )
            .padding(.bottom, Parameters.toastBottomPadding)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Parameters.toastDismissDelay) {
                    withAnimation {
                        showSaveConfirmation = false
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if isEditing {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: Parameters.toolbarAnimationDuration)) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                        impactFeedback.impactOccurred()
                        viewModel.revertChanges()
                        isEditing = false
                    }
                }
                .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.toolbarButtonFontSize))
                .foregroundColor(.secondary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: Parameters.toolbarAnimationDuration)) {
                    if isEditing {
                        handleSaveAction()
                    } else {
                        handleEditAction()
                    }
                }
            }
            .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.toolbarButtonFontSize))
            .foregroundColor(AppUI.ColorPalette.accent)
        }
    }

    // MARK: - Action Handlers

    private func handleSaveAction() {
        if viewModel.saveProfile() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            isEditing = false
            showSaveConfirmation = true
        } else {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showNameAlert = true
        }
    }

    private func handleEditAction() {
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Parameters.nameFieldFocusDelay) {
            isNameFieldFocused = true
        }
    }

    // MARK: - Design Constants

    private enum Parameters {
        static let sectionSpacing: CGFloat = 32
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 20
        static let nameSectionSpacing: CGFloat = 12
        static let accountSectionSpacing: CGFloat = 8
        static let accountMessageFontSize: CGFloat = 13
        static let nameLabelFontSize: CGFloat = 16
        static let nameFieldFontSize: CGFloat = 16
        static let nameFieldVerticalPadding: CGFloat = 14
        static let nameFieldHorizontalPadding: CGFloat = 20
        static let toastFontSize: CGFloat = 14
        static let toastHorizontalPadding: CGFloat = 16
        static let toastVerticalPadding: CGFloat = 12
        static let toastShadowOpacity: Double = 0.1
        static let toastShadowRadius: CGFloat = 8
        static let toastShadowYOffset: CGFloat = 4
        static let toastBottomPadding: CGFloat = 100
        static let toastDismissDelay: Double = 2.0
        static let toolbarAnimationDuration: Double = 0.3
        static let toolbarButtonFontSize: CGFloat = 16
        static let nameFieldFocusDelay: Double = 0.1
    }
}

private struct EmailVerificationReminderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var statusDismissalTask: Task<Void, Never>?

    var body: some View {
        if viewModel.shouldShowEmailVerificationReminder {
            HStack(alignment: .top, spacing: Parameters.spacing) {
                Image(systemName: "envelope.badge")
                    .foregroundColor(AppUI.ColorPalette.accent)
                    .font(.system(size: Parameters.iconSize, weight: .semibold))

                VStack(alignment: .leading, spacing: Parameters.textSpacing) {
                    Text("Email not verified")
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.titleFontSize))
                        .foregroundColor(.primary)

                    Text("Check your inbox to verify \(viewModel.accountEmail ?? "your email"). This helps keep password reset and future account recovery secure.")
                        .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task {
                            await viewModel.resendEmailVerification()
                        }
                    } label: {
                        HStack(spacing: Parameters.buttonSpacing) {
                            if viewModel.isSendingVerificationEmail {
                                ProgressView()
                            }
                            Text("Resend verification email")
                        }
                        .font(Font.custom(AppUI.FontName.poppinsSemiBold, size: Parameters.buttonFontSize))
                    }
                    .disabled(viewModel.isSendingVerificationEmail)

                    if let verificationEmailStatus = viewModel.verificationEmailStatus {
                        Text(verificationEmailStatus.message)
                            .font(Font.custom(AppUI.FontName.poppins, size: Parameters.bodyFontSize))
                            .foregroundColor(verificationEmailStatus.isFailure ? .red : .secondary)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Parameters.padding)
            .background(AppUI.ColorPalette.softCardBackground)
            .cornerRadius(AppUI.Radius.card)
            .animation(.easeInOut(duration: Parameters.statusAnimationDuration), value: viewModel.verificationEmailStatus)
            .onChange(of: viewModel.verificationEmailStatus) { _, status in
                scheduleStatusDismissal(for: status)
            }
            .onDisappear {
                statusDismissalTask?.cancel()
            }
        }
    }

    private func scheduleStatusDismissal(for status: VerificationEmailStatus?) {
        statusDismissalTask?.cancel()
        guard status != nil else { return }

        statusDismissalTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Parameters.statusDismissDelay))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: Parameters.statusAnimationDuration)) {
                viewModel.clearVerificationEmailStatus()
            }
        }
    }

    private enum Parameters {
        static let spacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        static let iconSize: CGFloat = 18
        static let titleFontSize: CGFloat = 14
        static let bodyFontSize: CGFloat = 12
        static let buttonFontSize: CGFloat = 12
        static let buttonSpacing: CGFloat = 6
        static let padding: CGFloat = 14
        static let statusDismissDelay: TimeInterval = 8
        static let statusAnimationDuration: TimeInterval = 0.25
    }
}

#Preview {
    ProfileView(userId: "previewUser")
}
