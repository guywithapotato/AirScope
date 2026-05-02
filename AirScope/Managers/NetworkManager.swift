import Combine
import CoreLocation
import Foundation
import Network
import SystemConfiguration.CaptiveNetwork

@MainActor
final class NetworkManager: NSObject, ObservableObject {
    @Published private(set) var snapshot: NetworkSnapshot = .unavailable
    @Published private(set) var locationAuthorization: CLAuthorizationStatus = .notDetermined

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "airscope.network.monitor")
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationAuthorization = locationManager.authorizationStatus
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let manager = self else { return }
            Task { @MainActor in
                manager.refresh(using: path)
            }
        }
        monitor.start(queue: monitorQueue)
        requestSSIDAccessIfNeeded()
        refresh(using: monitor.currentPath)
    }

    func refresh() {
        refresh(using: monitor.currentPath)
    }

    func requestSSIDAccessIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    private func refresh(using path: NWPath) {
        let connectionType: ConnectionType

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = path.status == .satisfied ? .wifi : .unavailable
        }

        snapshot = NetworkSnapshot(
            ssid: currentSSID(),
            localIPAddress: localIPAddress(preferWiFi: path.usesInterfaceType(.wifi)),
            gatewayIPAddress: GatewayResolver.defaultGateway(),
            connectionType: connectionType
        )
    }

    private func currentSSID() -> String? {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways else {
            return nil
        }

        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }

        for interface in interfaces {
            guard
                let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject],
                let ssid = info[kCNNetworkInfoKeySSID as String] as? String,
                !ssid.isEmpty
            else {
                continue
            }
            return ssid
        }

        return nil
    }

    private func localIPAddress(preferWiFi: Bool) -> String? {
        var address: String?
        var interfaces: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else {
            return nil
        }

        defer { freeifaddrs(interfaces) }

        for pointer in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            let addressFamily = interface.ifa_addr.pointee.sa_family

            guard addressFamily == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            let isTargetInterface = preferWiFi ? name == "en0" : name == "pdp_ip0" || name == "en0"
            guard isTargetInterface else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(MemoryLayout<sockaddr_in>.size),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            address = String(cString: hostname)
            break
        }

        return address
    }
}

extension NetworkManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            locationAuthorization = manager.authorizationStatus
            refresh()
        }
    }
}

enum GatewayResolver {
    static func defaultGateway() -> String? {
        // iOS intentionally exposes limited router metadata. A robust gateway
        // parser needs route table access that can vary by platform and network.
        guard let localIP = localWiFiIPComponents(), localIP.count == 4 else {
            return nil
        }

        return "\(localIP[0]).\(localIP[1]).\(localIP[2]).1"
    }

    private static func localWiFiIPComponents() -> [Substring]? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else {
            return nil
        }
        defer { freeifaddrs(interfaces) }

        for pointer in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET), String(cString: interface.ifa_name) == "en0" else {
                continue
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(MemoryLayout<sockaddr_in>.size),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            return String(cString: hostname).split(separator: ".")
        }

        return nil
    }
}
