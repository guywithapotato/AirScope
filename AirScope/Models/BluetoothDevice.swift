import Foundation

struct BluetoothDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var rssi: Int
    var uuid: UUID
    var lastSeen: Date

    var signalBars: Int {
        if rssi >= -55 { return 4 }
        if rssi >= -70 { return 3 }
        if rssi >= -85 { return 2 }
        return 1
    }
}
