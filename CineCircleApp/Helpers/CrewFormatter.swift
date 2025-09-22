/// Utility for extracting and formatting crew names for specific jobs.
enum CrewFormatter {
    /// Returns a comma-separated string of crew names that match the given jobs.
    /// - Parameters:
    ///   - jobs: List of job titles to filter (e.g., `["Director", "Producer"]`).
    ///   - crew: Full list of crew members.
    /// - Returns: Comma-separated string of names, sorted with directors first, or "—" if empty.
    static func names(for jobs: [String], in crew: [MovieCrew]) -> String {
        crew
            .filter { jobs.contains($0.job) }
            .sorted { a, b in
                if a.job == "Director", b.job != "Director" { return true }
                if b.job == "Director", a.job != "Director" { return false }
                return a.name < b.name
            }
            .map(\.name)
            .joined(separator: ", ")
            .nonEmptyOrDash
    }
}
