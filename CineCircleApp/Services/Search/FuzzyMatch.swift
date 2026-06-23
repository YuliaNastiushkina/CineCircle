import Foundation

enum FuzzyMatch {
    static func matches(_ value: String, query: String) -> Bool {
        score(value, query: query) != nil
    }

    static func ranked<T>(_ items: [T], query: String, text: (T) -> String) -> [T] {
        items.enumerated()
            .map { index, item in
                (index: index, item: item, score: score(text(item), query: query) ?? Int.max)
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.index < rhs.index
                }
                return lhs.score < rhs.score
            }
            .map(\.item)
    }

    static func score(_ value: String, query: String) -> Int? {
        let normalizedValue = normalized(value)
        let normalizedQuery = normalized(query)

        guard !normalizedQuery.isEmpty else { return 0 }
        guard !normalizedValue.isEmpty else { return nil }

        if normalizedValue == normalizedQuery { return 0 }
        if normalizedValue.hasPrefix(normalizedQuery) { return 1 }
        if normalizedValue.contains(normalizedQuery) { return 2 }

        let valueWords = normalizedValue.split(separator: " ").map(String.init)
        if valueWords.contains(where: { $0.hasPrefix(normalizedQuery) }) { return 3 }

        let maxDistance = normalizedQuery.count <= 4 ? 1 : 2
        if valueWords.contains(where: { hasMatchingPrefix($0, normalizedQuery) && levenshteinDistance($0, normalizedQuery, maxDistance: maxDistance) <= maxDistance }) {
            return 4
        }

        if hasMatchingPrefix(normalizedValue, normalizedQuery), levenshteinDistance(normalizedValue, normalizedQuery, maxDistance: maxDistance) <= maxDistance {
            return 5
        }

        return nil
    }

    private static func normalized(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func hasMatchingPrefix(_ value: String, _ query: String) -> Bool {
        guard let firstValue = value.first, let firstQuery = query.first else { return false }
        return firstValue == firstQuery
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String, maxDistance: Int) -> Int {
        let lhsCharacters = Array(lhs)
        let rhsCharacters = Array(rhs)

        if abs(lhsCharacters.count - rhsCharacters.count) > maxDistance {
            return maxDistance + 1
        }

        if lhsCharacters.isEmpty { return rhsCharacters.count }
        if rhsCharacters.isEmpty { return lhsCharacters.count }

        var previousRow = Array(0...rhsCharacters.count)
        var currentRow = Array(repeating: 0, count: rhsCharacters.count + 1)

        for lhsIndex in 1...lhsCharacters.count {
            currentRow[0] = lhsIndex
            var rowMinimum = currentRow[0]

            for rhsIndex in 1...rhsCharacters.count {
                let substitutionCost = lhsCharacters[lhsIndex - 1] == rhsCharacters[rhsIndex - 1] ? 0 : 1
                currentRow[rhsIndex] = min(
                    previousRow[rhsIndex] + 1,
                    currentRow[rhsIndex - 1] + 1,
                    previousRow[rhsIndex - 1] + substitutionCost
                )
                rowMinimum = min(rowMinimum, currentRow[rhsIndex])
            }

            if rowMinimum > maxDistance {
                return maxDistance + 1
            }

            swap(&previousRow, &currentRow)
        }

        return previousRow[rhsCharacters.count]
    }
}
