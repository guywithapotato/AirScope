import Combine
import Foundation

@MainActor
final class DeviceDiscoveryViewModel: ObservableObject {
    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var isScanning = false
    @Published var sortMode: DeviceSortMode = .name {
        didSet { sortDevices() }
    }

    private let manager = DeviceDiscoveryManager()

    func start() {
        manager.$devices.assign(to: &$devices)
        manager.$isScanning.assign(to: &$isScanning)
        manager.start()
    }

    func refresh() {
        Haptics.lightImpact()
        manager.refresh()
    }

    private func sortDevices() {
        switch sortMode {
        case .name:
            devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .lastSeen:
            devices.sort { $0.lastSeen > $1.lastSeen }
        }
    }
}

enum DeviceSortMode: String, CaseIterable, Identifiable {
    case name = "Name"
    case lastSeen = "Last Seen"

    var id: String { rawValue }
}
