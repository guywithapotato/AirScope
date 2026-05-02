import Foundation

enum AirScopeFormatters {
    static let lastSeen: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static func latency(_ value: Double?) -> String {
        guard let value else { return "-- ms" }
        return "\(Int(value.rounded())) ms"
    }

    static func fallback(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Unavailable on iOS" }
        return value
    }
}
