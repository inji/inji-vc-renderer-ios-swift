public enum CredentialFormat: String {
    case ldp_vc = "ldp_vc"
    case unknown = "unknown"

    public static func fromValue(_ value: String) -> CredentialFormat {
        return CredentialFormat(rawValue: value) ?? .unknown
    }
}
