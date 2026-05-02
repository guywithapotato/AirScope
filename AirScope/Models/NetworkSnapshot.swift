import Foundation

enum ConnectionType: String {
    case wifi = "Wi-Fi"
    case cellular = "Cellular"
    case wired = "Wired"
    case unavailable = "Unavailable"
}

struct NetworkSnapshot {
    var ssid: String?
    var localIPAddress: String?
    var gatewayIPAddress: String?
    var connectionType: ConnectionType

    static let unavailable = NetworkSnapshot(
        ssid: nil,
        localIPAddress: nil,
        gatewayIPAddress: nil,
        connectionType: .unavailable
    )
}
