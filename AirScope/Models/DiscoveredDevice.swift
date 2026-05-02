import Foundation

struct DiscoveredDevice: Identifiable, Hashable {
    let id: String
    var name: String
    var host: String?
    var ipAddress: String?
    var serviceType: String
    var lastSeen: Date

    var iconName: String {
        let lowercased = "\(name) \(serviceType)".lowercased()

        if lowercased.contains("iphone") || lowercased.contains("ipad") {
            return "iphone"
        }

        if lowercased.contains("mac") || lowercased.contains("workstation") || lowercased.contains("smb") {
            return "laptopcomputer"
        }

        if lowercased.contains("router") || lowercased.contains("gateway") {
            return "wifi.router"
        }

        if lowercased.contains("tv") || lowercased.contains("airplay") {
            return "tv"
        }

        if lowercased.contains("printer") || lowercased.contains("ipp") {
            return "printer"
        }

        return "network"
    }
}
