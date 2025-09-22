/// Returns the string itself if non-empty, or "—" otherwise.
extension String {
    var nonEmptyOrDash: String { isEmpty ? "—" : self }
}
