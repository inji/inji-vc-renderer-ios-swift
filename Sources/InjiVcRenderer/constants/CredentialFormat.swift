public enum CredentialFormat: String {
    case ldp_vc = "ldp_vc"
    case unknown = "unknown"

    static func fromValue(_ value: String) -> CredentialFormat {
        return CredentialFormat(rawValue: value) ?? .unknown
    }
}
