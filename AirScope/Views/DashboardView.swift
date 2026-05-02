import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                QualityCard(
                    quality: viewModel.quality,
                    routerLatency: viewModel.routerLatency,
                    googleLatency: viewModel.googleLatency
                )

                NetworkOverviewCard(snapshot: viewModel.networkSnapshot)

                LatencyChartCard(samples: viewModel.samples)

                LimitationCard()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private struct QualityCard: View {
    let quality: ConnectionQuality
    let routerLatency: Double?
    let googleLatency: Double?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(quality.rawValue, systemImage: quality.symbol)
                        .font(.title2.bold())
                        .foregroundStyle(quality.color)

                    Spacer()

                    Image(systemName: "sparkline")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    MetricPill(title: "Router", value: AirScopeFormatters.latency(routerLatency), symbol: "wifi.router")
                    MetricPill(title: "Google", value: AirScopeFormatters.latency(googleLatency), symbol: "globe")
                }
            }
        }
    }
}

private struct NetworkOverviewCard: View {
    let snapshot: NetworkSnapshot

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "Current Network", symbol: "wifi")

                VStack(spacing: 12) {
                    InfoRow(title: "SSID", value: AirScopeFormatters.fallback(snapshot.ssid), symbol: "dot.radiowaves.left.and.right")
                    InfoRow(title: "Local IP", value: AirScopeFormatters.fallback(snapshot.localIPAddress), symbol: "number")
                    InfoRow(title: "Gateway", value: AirScopeFormatters.fallback(snapshot.gatewayIPAddress), symbol: "wifi.router")
                    InfoRow(title: "Type", value: snapshot.connectionType.rawValue, symbol: "antenna.radiowaves.left.and.right")
                }
            }
        }
    }
}

private struct LatencyChartCard: View {
    let samples: [LatencySample]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "Latency Monitor", symbol: "chart.xyaxis.line")

                Chart(samples) { sample in
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value("Latency", sample.milliseconds)
                    )
                    .foregroundStyle(by: .value("Target", sample.target.rawValue))

                    AreaMark(
                        x: .value("Time", sample.date),
                        y: .value("Latency", sample.milliseconds)
                    )
                    .foregroundStyle(by: .value("Target", sample.target.rawValue))
                    .opacity(0.10)
                }
                .chartYAxisLabel("ms")
                .frame(height: 190)
                .overlay {
                    if samples.isEmpty {
                        ContentUnavailableView("Collecting latency", systemImage: "waveform.path.ecg")
                    }
                }
            }
        }
    }
}

private struct LimitationCard: View {
    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("MAC addresses and raw ICMP ping are unavailable to App Store apps. AirScope uses Bonjour, BLE, URLSession, and Network framework probes instead.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
