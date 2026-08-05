enum MovieRecommendationPromptSuggestions {
    static let visibleCount = 3

    static let all = [
        "Christmas movies for family",
        "Funny adventure with treasure",
        "Something like Knives Out",
        "Light romance, happy ending",
        "Smart sci-fi, not too dark",
        "Feel-good movie after work",
        "90s comfort comedy",
        "Epic fantasy with adventure",
        "Crime thriller with a twist",
        "Beautiful movie about friendship",
        "Not scary Halloween movie",
        "Cozy mystery for tonight",
        "Road trip comedy",
        "Underrated heist movie",
        "Warm movie for a rainy day",
    ]

    static var initial: [String] {
        Array(all.prefix(visibleCount))
    }

    static func next(excluding currentPrompts: [String]) -> [String] {
        let shuffledPrompts = all.shuffled()
        let nextPrompts = Array(shuffledPrompts.prefix(visibleCount))

        if nextPrompts == currentPrompts, all.count > visibleCount {
            return Array(shuffledPrompts.dropFirst(visibleCount).prefix(visibleCount))
        }

        return nextPrompts
    }
}
