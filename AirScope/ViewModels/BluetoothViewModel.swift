import Combine
import CoreBluetooth
import Foundation

@MainActor
final class BluetoothViewModel: ObservableObject {
    @Published private(set) var devices: [BluetoothDevice] = []
    @Published private(set) var state: CBManagerState = .unknown
    @Published var sortMode: BluetoothSortMode = .signal {
        didSet { manager.sortMode = sortMode }
    }

    private let manager = BluetoothManager()

    var stateMessage: String {
        switch state {
        case .poweredOn: return "Scanning"
        case .poweredOff: return "Bluetooth Off"
        case .unauthorized: return "Permission Needed"
        case .unsupported: return "Unsupported"
        case .resetting: return "Resetting"
        case .unknown: return "Preparing"
        @unknown default: return "Unavailable"
        }
    }

    func start() {
        manager.$devices.assign(to: &$devices)
        manager.$state.assign(to: &$state)
        manager.start()
    }

    func refresh() {
        Haptics.lightImpact()
        manager.refresh()
    }
}
