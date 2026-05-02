import Foundation
import Network

@MainActor
final class LatencyMonitor: ObservableObject {
    @Published private(set) var routerLatency: Double?
    @Published private(set) var googleLatency: Double?
    @Published private(set) var samples: [LatencySample] = []
    @Published private(set) var isRunning = false

    private var task: Task<Void, Never>?
    private var gatewayProvider: () -> String?

    init(gatewayProvider: @escaping () -> String?) {
        self.gatewayProvider = gatewayProvider
    }

    func start() {
        guard task == nil else { return }
        isRunning = true

        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.measureOnce()
                try? await Task.sleep(for: .seconds(2.5))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    func measureOnce() async {
        async let router = measureRouter()
        async let google = measureGoogle()

        let routerValue = await router
        let googleValue = await google

        routerLatency = routerValue
        googleLatency = googleValue

        append(routerValue, target: .router)
        append(googleValue, target: .google)
    }

    private func measureRouter() async -> Double? {
        guard let gateway = gatewayProvider() else { return nil }
        return await TCPProbe.measure(host: gateway, port: 80, timeout: 1.5)
    }

    private func measureGoogle() async -> Double? {
        await HTTPProbe.measure(url: URL(string: "https://www.google.com/generate_204")!, timeout: 2.0)
    }

    private func append(_ value: Double?, target: LatencyTarget) {
        guard let value else { return }

        samples.append(LatencySample(date: Date(), milliseconds: value, target: target))
        if samples.count > 80 {
            samples.removeFirst(samples.count - 80)
        }
    }
}

enum HTTPProbe {
    static func measure(url: URL, timeout: TimeInterval) async -> Double? {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let startedAt = ContinuousClock.now

        do {
            _ = try await URLSession.shared.data(for: request)
            let duration = startedAt.duration(to: ContinuousClock.now)
            return Double(duration.components.seconds * 1_000) + Double(duration.components.attoseconds) / 1_000_000_000_000_000
        } catch {
            return nil
        }
    }
}

enum TCPProbe {
    static func measure(host: String, port: UInt16, timeout: TimeInterval) async -> Double? {
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "airscope.tcp.probe.\(host)")
            let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
            let startedAt = ContinuousClock.now
            var didResume = false

            func finish(_ value: Double?) {
                guard !didResume else { return }
                didResume = true
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let duration = startedAt.duration(to: ContinuousClock.now)
                    let milliseconds = Double(duration.components.seconds * 1_000) + Double(duration.components.attoseconds) / 1_000_000_000_000_000
                    finish(milliseconds)
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }

            queue.asyncAfter(deadline: .now() + timeout) {
                finish(nil)
            }

            connection.start(queue: queue)
        }
    }
}
