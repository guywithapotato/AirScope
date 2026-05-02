import Foundation

struct BluetoothDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var rssi: Int
    var uuid: UUID
    var lastSeen: Date

    var signalBars: Int {
        switch rssi {
        case -55...: return 4
        case -70 ... -56: return 3
        case -85 ... -71: return 2
        default: return 1
        }
    }
}
