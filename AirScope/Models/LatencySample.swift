import Foundation

struct LatencySample: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let milliseconds: Double
    let target: LatencyTarget
}

enum LatencyTarget: String, CaseIterable {
    case router = "Router"
    case google = "Google"

    var symbol: String {
        switch self {
        case .router: return "wifi.router"
        case .google: return "globe"
        }
    }
}
