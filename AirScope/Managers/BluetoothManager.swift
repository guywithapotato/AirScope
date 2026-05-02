import CoreBluetooth
import Foundation
import SwiftUI

@MainActor
final class BluetoothManager: NSObject, ObservableObject {
    @Published private(set) var devices: [BluetoothDevice] = []
    @Published private(set) var state: CBManagerState = .unknown
    @Published var sortMode: BluetoothSortMode = .signal {
        didSet { sortDevices() }
    }

    private var centralManager: CBCentralManager?

    func start() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        } else if state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    func refresh() {
        devices.removeAll()
        guard state == .poweredOn else { return }
        centralManager?.stopScan()
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    private func upsert(peripheral: CBPeripheral, rssi: NSNumber) {
        let name = peripheral.name?.isEmpty == false ? peripheral.name! : "Unnamed BLE Device"
        let device = BluetoothDevice(
            id: peripheral.identifier,
            name: name,
            rssi: rssi.intValue,
            uuid: peripheral.identifier,
            lastSeen: Date()
        )

        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                devices[index] = device
                sortDevices()
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                devices.append(device)
                sortDevices()
            }
        }
    }

    private func sortDevices() {
        switch sortMode {
        case .signal:
            devices.sort { $0.rssi > $1.rssi }
        case .name:
            devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            state = central.state
            if central.state == .poweredOn {
                central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            upsert(peripheral: peripheral, rssi: RSSI)
        }
    }
}

enum BluetoothSortMode: String, CaseIterable, Identifiable {
    case signal = "Signal"
    case name = "Name"

    var id: String { rawValue }
}
