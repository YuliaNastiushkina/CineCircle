/// Utility for extracting and formatting crew names for specific jobs.
enum CrewFormatter {
    /// Returns a comma-separated string of crew names that match the given jobs.
    /// - Parameters:
    ///   - jobs: List of job titles to filter (e.g., `["Director", "Producer"]`).
    ///   - crew: Full list of crew members.
    /// - Returns: Comma-separated string of names, sorted with directors first, or "—" if empty.
    static func names(for jobs: [String], in crew: [MovieCrew]) -> String {
        let targetJobs = Set(jobs)

        return crew
            .filter { member in
                Set(jobList(from: member.job)).isDisjoint(with: targetJobs) == false
            }
            .sorted { a, b in
                let aIsDirector = jobList(from: a.job).contains("Director")
                let bIsDirector = jobList(from: b.job).contains("Director")
                if aIsDirector != bIsDirector {
                    return aIsDirector
                }
                return a.name < b.name
            }
            .map(\.name)
            .joined(separator: ", ")
            .nonEmptyOrDash
    }

    private static func jobList(from value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
