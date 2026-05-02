import SwiftUI

enum ConnectionQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case poor = "Poor"
    case unavailable = "Unavailable"

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .yellow
        case .poor: return .red
        case .unavailable: return .secondary
        }
    }

    var symbol: String {
        switch self {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.octagon.fill"
        case .unavailable: return "questionmark.circle.fill"
        }
    }

    static func from(latency milliseconds: Double?) -> ConnectionQuality {
        guard let milliseconds else { return .unavailable }
        switch milliseconds {
        case ..<60: return .excellent
        case ..<150: return .good
        default: return .poor
        }
    }
}
