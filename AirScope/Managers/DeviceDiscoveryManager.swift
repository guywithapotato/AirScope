import Foundation
import Network
import SwiftUI

@MainActor
final class DeviceDiscoveryManager: ObservableObject {
    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var isScanning = false

    private var browsers: [NWBrowser] = []
    private let queue = DispatchQueue(label: "airscope.bonjour.browser")
    private let serviceTypes = ["_http._tcp", "_airplay._tcp", "_workstation._tcp", "_ipp._tcp", "_raop._tcp"]

    func start() {
        guard browsers.isEmpty else { return }
        isScanning = true

        for type in serviceTypes {
            let browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: .tcp)

            browser.browseResultsChangedHandler = { [weak self] results, _ in
                Task { @MainActor in
                    self?.merge(results: Array(results), serviceType: type)
                }
            }

            browser.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    if case .failed = state {
                        self?.isScanning = false
                    }
                }
            }

            browser.start(queue: queue)
            browsers.append(browser)
        }
    }

    func refresh() {
        stop()
        devices.removeAll()
        start()
    }

    func stop() {
        browsers.forEach { $0.cancel() }
        browsers.removeAll()
        isScanning = false
    }

    private func merge(results: [NWBrowser.Result], serviceType: String) {
        for result in results {
            guard case let .service(name, type, domain, interface) = result.endpoint else {
                continue
            }

            let id = "\(name).\(type).\(domain)"
            let host = interface?.debugDescription
            let device = DiscoveredDevice(
                id: id,
                name: name,
                host: host,
                ipAddress: nil,
                serviceType: serviceType,
                lastSeen: Date()
            )

            if let index = devices.firstIndex(where: { $0.id == id }) {
                devices[index].lastSeen = Date()
                devices[index].host = host
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    devices.append(device)
                    devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                }
            }
        }
    }
}
