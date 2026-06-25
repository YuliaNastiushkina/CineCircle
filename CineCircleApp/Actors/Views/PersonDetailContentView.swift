import SwiftUI

struct PersonDetailContentView: View {
    let name: String
    let role: String?
    let profilePath: String?
    let knownForTitles: [String]
    let viewModel: ActorDetailsViewModel

    @State private var isBiographyExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Parameters.sectionSpacing) {
                headerSection

                if !knownForTitles.isEmpty {
                    textListSection(title: "Known for", values: knownForTitles)
                }

                if !displayedAliases.isEmpty {
                    textListSection(title: "Also known as", values: displayedAliases)
                }

                if !displayedCredits.isEmpty {
                    creditsSection
                }

                biographySection
            }
            .padding(.horizontal, Parameters.horizontalPadding)
            .padding(.top, Parameters.topPadding)
            .padding(.bottom, Parameters.bottomPadding)
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LogoView()
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: Parameters.headerSpacing) {
            profileImage

            VStack(alignment: .leading, spacing: Parameters.infoRowSpacing) {
                if let role, !role.isEmpty {
                    Text(role)
                        .font(Parameters.roleFont)
                        .foregroundStyle(.primary)
                        .padding(.bottom, Parameters.roleBottomPadding)
                }

                if let birthday = formattedDate(viewModel.birthday) {
                    infoRow(systemName: "gift", title: "Born", value: birthday)
                }

                if let deathday = formattedDate(viewModel.deathday) {
                    infoRow(systemName: "calendar.badge.minus", title: "Died", value: deathday)
                }

                if let placeOfBirth = viewModel.placeOfBirth, !placeOfBirth.isEmpty {
                    infoRow(systemName: "mappin.and.ellipse", title: "From", value: placeOfBirth)
                }

                if !socialLinks.isEmpty {
                    compactLinks
                        .padding(.top, Parameters.headerLinksTopPadding)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let profilePath,
           let url = URL(string: AppUI.TMDB.profileBase + profilePath) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: Parameters.imageWidth, height: Parameters.imageHeight)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: Parameters.imageWidth, height: Parameters.imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Parameters.imageCornerRadius))
                default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        PosterPlaceholderView(
            cornerRadius: Parameters.imageCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
        .frame(width: Parameters.imageWidth, height: Parameters.imageHeight)
    }

    private func infoRow(systemName: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Parameters.infoIconSpacing) {
            Image(systemName: systemName)
                .font(Parameters.infoIconFont)
                .foregroundStyle(.secondary)
                .frame(width: Parameters.infoIconWidth, alignment: .center)

            Text("\(title):")
                .font(Parameters.infoLabelFont)
                .foregroundStyle(.secondary)
                .fixedSize()

            Text(value)
                .font(Parameters.infoValueFont)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var compactLinks: some View {
        Group {
            if socialLinks.count > Parameters.twoColumnLinkThreshold {
                LazyVGrid(columns: linkColumns, alignment: .leading, spacing: Parameters.headerLinkSpacing) {
                    ForEach(socialLinks) { link in
                        PersonHeaderLinkButton(link: link)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: Parameters.headerLinkSpacing) {
                    ForEach(socialLinks) { link in
                        PersonHeaderLinkButton(link: link)
                    }
                }
            }
        }
    }

    private var linkColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Parameters.headerLinkColumnSpacing, alignment: .leading),
            count: Parameters.linkColumnCount
        )
    }

    private func textListSection(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionTitle(title)

            FlowLayout(spacing: Parameters.chipSpacing) {
                ForEach(values, id: \.self) { value in
                    MetadataChip(
                        text: value,
                        font: Parameters.chipFont,
                        textColor: .primary,
                        backgroundColor: AppUI.ColorPalette.secondarySurface,
                        horizontalPadding: Parameters.chipHorizontalPadding,
                        verticalPadding: Parameters.chipVerticalPadding
                    )
                }
            }
        }
    }

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionTitle("Movies & TV")

            VStack(spacing: Parameters.creditRowSpacing) {
                ForEach(displayedCredits) { credit in
                    NavigationLink {
                        creditDestination(for: credit)
                    } label: {
                        creditRow(credit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.actingCredits.count > Parameters.collapsedCreditLimit {
                NavigationLink {
                    ActorCreditsListView(actorName: name, credits: viewModel.actingCredits)
                } label: {
                    Text("See all movies and TV")
                        .font(Parameters.sectionActionFont)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Parameters.seeAllVerticalPadding)
                        .background(AppUI.ColorPalette.accent)
                        .clipShape(Capsule())
                        .padding(.top, Parameters.showMoreTopPadding)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func creditRow(_ credit: ActorCredit) -> some View {
        PersonCreditRow(credit: credit)
    }

    @ViewBuilder private func creditDestination(for credit: ActorCredit) -> some View {
        if credit.mediaType == ActorCredit.tvMediaType {
            TVShowDetailLoaderView(showID: credit.tmdbID)
        } else {
            MovieDetailViewLoaderView(movieID: credit.tmdbID)
        }
    }

    private var biographySection: some View {
        VStack(alignment: .leading, spacing: Parameters.contentSpacing) {
            sectionTitle("Biography")

            if viewModel.biography.isEmpty {
                Text("No biography available.")
                    .font(Parameters.bodyFont)
                    .foregroundStyle(.secondary)
            } else {
                Text(viewModel.biography)
                    .font(Parameters.bodyFont)
                    .foregroundStyle(.secondary)
                    .lineSpacing(Parameters.biographyLineSpacing)
                    .lineLimit(isBiographyExpanded ? nil : Parameters.collapsedBiographyLineLimit)

                if hasExpandableBiography {
                    Button(isBiographyExpanded ? "Show less" : "Read more") {
                        withAnimation(.easeInOut(duration: Parameters.expandAnimationDuration)) {
                            isBiographyExpanded.toggle()
                        }
                    }
                    .font(Parameters.sectionActionFont)
                    .foregroundStyle(AppUI.ColorPalette.accent)
                }
            }
        }
        .padding(Parameters.biographyPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Parameters.biographyBackground)
        .cornerRadius(AppUI.Radius.card)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Parameters.sectionTitleFont)
            .foregroundStyle(.primary)
    }

    private var displayedAliases: [String] {
        Array(viewModel.alsoKnownAs.prefix(Parameters.aliasDisplayLimit))
    }

    private var displayedCredits: [ActorCredit] {
        Array(viewModel.actingCredits.prefix(Parameters.collapsedCreditLimit))
    }

    private var hasExpandableBiography: Bool {
        viewModel.biography.count > Parameters.collapsedBiographyCharacterThreshold
    }

    private var socialLinks: [PersonLink] {
        var links: [PersonLink] = []

        if let homepage = viewModel.homepage,
           let url = URL(string: homepage),
           !homepage.isEmpty {
            links.append(PersonLink(title: "Website", systemImage: "globe", url: url))
        }

        if let instagramID = viewModel.externalIDs?.instagramID,
           let url = URL(string: AppUI.ExternalLinkBaseURL.instagram + instagramID) {
            links.append(PersonLink(title: "Instagram", systemImage: "camera", url: url))
        }

        if let facebookID = viewModel.externalIDs?.facebookID,
           let url = URL(string: AppUI.ExternalLinkBaseURL.facebook + facebookID) {
            links.append(PersonLink(title: "Facebook", systemImage: "person.2", url: url))
        }

        if let twitterID = viewModel.externalIDs?.twitterID,
           let url = URL(string: AppUI.ExternalLinkBaseURL.x + twitterID) {
            links.append(PersonLink(title: "X", systemImage: "at", url: url))
        }

        if let tiktokID = viewModel.externalIDs?.tiktokID,
           let url = URL(string: AppUI.ExternalLinkBaseURL.tiktok + tiktokID) {
            links.append(PersonLink(title: "TikTok", systemImage: "music.note", url: url))
        }

        if let imdbID = viewModel.externalIDs?.imdbID,
           let url = URL(string: AppUI.ExternalLinkBaseURL.imdbName + imdbID) {
            links.append(PersonLink(title: "IMDb", systemImage: "star", url: url))
        }

        return links
    }

    private func formattedDate(_ rawValue: String?) -> String? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        guard let date = Parameters.apiDateFormatter.date(from: rawValue) else { return rawValue }

        return Parameters.displayDateFormatter.string(from: date)
    }

    struct PersonLink: Identifiable {
        let title: String
        let systemImage: String
        let url: URL

        var id: String { title }
    }

    private enum Parameters {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 32
        static let sectionSpacing: CGFloat = 24
        static let contentSpacing: CGFloat = 10
        static let headerSpacing: CGFloat = 14
        static let infoRowSpacing: CGFloat = 10
        static let infoIconSpacing: CGFloat = 8
        static let infoTextSpacing: CGFloat = 2
        static let chipSpacing: CGFloat = 8
        static let roleBottomPadding: CGFloat = 2
        static let headerLinksTopPadding: CGFloat = 4
        static let headerLinkSpacing: CGFloat = 6
        static let headerLinkColumnSpacing: CGFloat = 6
        static let twoColumnLinkThreshold = 3
        static let linkColumnCount = 2
        static let showMoreTopPadding: CGFloat = 4
        static let seeAllVerticalPadding: CGFloat = 10

        static let imageWidth: CGFloat = 144
        static let imageHeight: CGFloat = 216
        static let imageCornerRadius: CGFloat = AppUI.Radius.medium
        static let placeholderIconSize: CGFloat = 24
        static let infoIconWidth: CGFloat = 18

        static let chipHorizontalPadding: CGFloat = 10
        static let chipVerticalPadding: CGFloat = 5
        static let smallChipHorizontalPadding: CGFloat = 9
        static let smallChipVerticalPadding: CGFloat = 4
        static let aliasDisplayLimit = 6
        static let collapsedCreditLimit = 3
        static let collapsedBiographyLineLimit = 6
        static let collapsedBiographyCharacterThreshold = 260
        static let expandAnimationDuration: TimeInterval = 0.2

        static let creditRowSpacing: CGFloat = 8
        static let creditPosterSpacing: CGFloat = 12
        static let creditTextSpacing: CGFloat = 8
        static let creditVerticalPadding: CGFloat = 4
        static let creditPosterWidth: CGFloat = 64
        static let creditPosterHeight: CGFloat = 96
        static let creditPosterCornerRadius: CGFloat = 10
        static let creditPlaceholderIconSize: CGFloat = 18

        static let sectionTitleFont = Font.custom(AppUI.FontName.poppinsSemiBold, size: 16)
        static let sectionActionFont = Font.custom(AppUI.FontName.poppinsSemiBold, size: 13)
        static let bodyFont = Font.custom(AppUI.FontName.poppins, size: 14)
        static let roleFont = Font.custom(AppUI.FontName.poppinsSemiBold, size: 14)
        static let infoLabelFont = Font.custom(AppUI.FontName.poppins, size: 12)
        static let infoValueFont = Font.custom(AppUI.FontName.poppins, size: 14)
        static let infoIconFont = Font.system(size: 14, weight: .medium)
        static let chipFont = Font.custom(AppUI.FontName.poppins, size: 13)
        static let smallChipFont = Font.custom(AppUI.FontName.poppinsLight, size: 12)
        static let creditTitleFont = Font.custom(AppUI.FontName.poppinsLight, size: 16)
        static let creditMetadataFont = Font.custom(AppUI.FontName.poppins, size: 13)

        static let biographyPadding: CGFloat = 16
        static let biographyBackground = Color.secondary.opacity(0.04)
        static let biographyLineSpacing: CGFloat = 4
        static let apiDateFormat = "yyyy-MM-dd"
        static let displayDateFormat = "MMM d, yyyy"
        static let apiDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = apiDateFormat
            return formatter
        }()

        static let displayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = displayDateFormat
            return formatter
        }()
    }
}

private struct PersonHeaderLinkButton: View {
    let link: PersonDetailContentView.PersonLink

    var body: some View {
        Link(destination: link.url) {
            HStack(spacing: Parameters.iconSpacing) {
                Image(systemName: link.systemImage)
                    .font(Parameters.iconFont)
                    .frame(width: Parameters.iconWidth, alignment: .center)

                Text(link.title)
                    .font(Parameters.titleFont)
                    .lineLimit(1)
                    .minimumScaleFactor(Parameters.minimumScale)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, Parameters.horizontalPadding)
            .padding(.vertical, Parameters.verticalPadding)
            .background(AppUI.ColorPalette.accent)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private enum Parameters {
        static let iconSpacing: CGFloat = 6
        static let horizontalPadding: CGFloat = 9
        static let verticalPadding: CGFloat = 4
        static let iconWidth: CGFloat = 14
        static let minimumScale: CGFloat = 0.8
        static let titleFont = Font.custom(AppUI.FontName.poppinsSemiBold, size: 12)
        static let iconFont = Font.system(size: 11, weight: .semibold)
    }
}

struct PersonCreditRow: View {
    let credit: ActorCredit
    let showsChevron: Bool

    init(credit: ActorCredit, showsChevron: Bool = true) {
        self.credit = credit
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack(alignment: .top, spacing: Parameters.posterSpacing) {
            creditPoster(path: credit.posterPath)

            VStack(alignment: .leading, spacing: Parameters.textSpacing) {
                Text(credit.displayTitle)
                    .font(Parameters.titleFont)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: Parameters.chipSpacing) {
                    MetadataChip(
                        text: credit.mediaLabel,
                        font: Parameters.smallChipFont,
                        textColor: .black,
                        backgroundColor: AppUI.ColorPalette.accent,
                        horizontalPadding: Parameters.smallChipHorizontalPadding,
                        verticalPadding: Parameters.smallChipVerticalPadding
                    )

                    MetadataChip(
                        text: credit.displayYear,
                        font: Parameters.smallChipFont,
                        horizontalPadding: Parameters.smallChipHorizontalPadding,
                        verticalPadding: Parameters.smallChipVerticalPadding
                    )
                }

                if let character = credit.character, !character.isEmpty {
                    Text(character)
                        .font(Parameters.metadataFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(Parameters.chevronFont)
                    .foregroundStyle(.tertiary)
                    .padding(.top, Parameters.chevronTopPadding)
            }
        }
        .padding(.vertical, Parameters.verticalPadding)
    }

    @ViewBuilder private func creditPoster(path: String?) -> some View {
        if let path,
           let url = URL(string: AppUI.TMDB.posterBase + path) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                creditPosterPlaceholder
            }
            .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: Parameters.posterCornerRadius))
            .clipped()
        } else {
            creditPosterPlaceholder
                .frame(width: Parameters.posterWidth, height: Parameters.posterHeight)
        }
    }

    private var creditPosterPlaceholder: some View {
        PosterPlaceholderView(
            cornerRadius: Parameters.posterCornerRadius,
            iconSize: Parameters.placeholderIconSize
        )
    }

    private enum Parameters {
        static let posterSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 8
        static let chipSpacing: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let posterWidth: CGFloat = 64
        static let posterHeight: CGFloat = 96
        static let posterCornerRadius: CGFloat = 10
        static let placeholderIconSize: CGFloat = 18
        static let chevronTopPadding: CGFloat = 36
        static let smallChipHorizontalPadding: CGFloat = 9
        static let smallChipVerticalPadding: CGFloat = 4
        static let smallChipFont = Font.custom(AppUI.FontName.poppinsLight, size: 12)
        static let chevronFont = Font.system(size: 12, weight: .semibold)
        static let titleFont = Font.custom(AppUI.FontName.poppinsLight, size: 16)
        static let metadataFont = Font.custom(AppUI.FontName.poppins, size: 13)
    }
}
