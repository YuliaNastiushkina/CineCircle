/// Utility for formatting movie details such as runtime, genres, etc.
enum MovieFormatter {
    /// Converts a runtime in minutes to a formatted string like `"2h 10m"`.
    /// - Parameter minutes: Runtime in minutes.
    /// - Returns: A formatted runtime string, or "—" if `nil`.
    static func runtimeText(minutes: Int?) -> String {
        guard let min = minutes else { return "—" }
        return "\(min / 60)h \(min % 60)m"
    }

    /// Joins a list of strings into a comma-separated string.
    /// - Parameter values: List of values to join.
    /// - Returns: A comma-separated string, or "—" if the list is empty.
    static func commaJoined(_ values: [String]) -> String {
        let separation = values.joined(separator: ", ")
        return separation.nonEmptyOrDash
    }
}
