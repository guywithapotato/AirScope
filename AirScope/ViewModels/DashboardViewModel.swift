import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var networkSnapshot: NetworkSnapshot = .unavailable
    @Published private(set) var routerLatency: Double?
    @Published private(set) var googleLatency: Double?
    @Published private(set) var samples: [LatencySample] = []
    @Published private(set) var isRefreshing = false

    private let networkManager = NetworkManager()
    private lazy var latencyMonitor = LatencyMonitor { [weak self] in
        self?.networkSnapshot.gatewayIPAddress
    }
    private var cancellables = Set<AnyCancellable>()

    var quality: ConnectionQuality {
        let values = [routerLatency, googleLatency].compactMap { $0 }
        guard !values.isEmpty else { return .unavailable }
        return ConnectionQuality.from(latency: values.reduce(0, +) / Double(values.count))
    }

    func start() {
        bind()
        networkManager.start()
        latencyMonitor.start()
    }

    func refresh() async {
        isRefreshing = true
        Haptics.lightImpact()
        networkManager.refresh()
        await latencyMonitor.measureOnce()
        isRefreshing = false
    }

    private func bind() {
        guard cancellables.isEmpty else { return }

        networkManager.$snapshot
            .receive(on: RunLoop.main)
            .assign(to: &$networkSnapshot)

        latencyMonitor.$routerLatency
            .receive(on: RunLoop.main)
            .assign(to: &$routerLatency)

        latencyMonitor.$googleLatency
            .receive(on: RunLoop.main)
            .assign(to: &$googleLatency)

        latencyMonitor.$samples
            .receive(on: RunLoop.main)
            .assign(to: &$samples)
    }
}
