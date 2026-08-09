import SwiftUI

enum MoviesListLayout {
    static let filterAll = "All"
    static let filterPopular = "Popular"
    static let filterSpacing = AppUI.Spacing.small
    static let filterHorizontalPadding = AppUI.Spacing.large
    static let filterVerticalPadding: CGFloat = 10
    static let filterFontSize = AppUI.FontSize.footnote
    static let filterHorizontalChipPadding: CGFloat = 14
    static let filterVerticalChipPadding = AppUI.Spacing.small

    static let searchHorizontalPadding = AppUI.Spacing.large
    static let modeTransitionDuration = 0.2
    static let titleTransitionDuration = 0.2
    static let genreFilterID = "genreFilter"
    static let aiSuggestionFilterID = "aiSuggestionFilter"

    static let statusMessageSpacing = AppUI.Spacing.small
    static let statusMessageFontSize = AppUI.FontSize.caption
    static let statusMessageBottomPadding = AppUI.Spacing.small

    static let aiLoadingSpacing: CGFloat = 10
    static let aiLoadingOuterCircle: CGFloat = 64
    static let aiLoadingIconSize = AppUI.FontSize.title2
    static let aiLoadingTitleFontSize = AppUI.FontSize.callout
    static let aiLoadingSubtitleFontSize = AppUI.FontSize.caption
    static let aiLoadingPulseDuration = 0.9
    static let aiLoadingPulseMinScale = 0.92
    static let aiLoadingPulseMaxScale = 1.14

    static let resultsHeaderSpacing = AppUI.Spacing.xxSmall
    static let resultsTitleFontSize = AppUI.FontSize.callout
    static let resultsActionFontSize = AppUI.FontSize.caption
    static let resultsExplanationFontSize = AppUI.FontSize.caption
    static let resultsHeaderBottomPadding = AppUI.Spacing.small

    static let recommendationScrollDuration = 0.25
    static let paginationSpacing = AppUI.Spacing.small
    static let paginationVerticalSpacing: CGFloat = 6
    static let paginationHintFontSize: CGFloat = 11
    static let paginationIconSize = AppUI.FontSize.footnote
    static let paginationIconFrame: CGFloat = 34
    static let paginationVerticalPadding = AppUI.Spacing.small
    static let maximumGenreCount = 3
}
