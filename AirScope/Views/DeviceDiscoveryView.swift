import SwiftUI

struct DeviceDiscoveryView: View {
    @EnvironmentObject private var viewModel: DeviceDiscoveryViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ControlsCard(
                    title: "\(viewModel.devices.count) Devices",
                    subtitle: viewModel.isScanning ? "Scanning Bonjour services" : "Scanner paused",
                    symbol: "network"
                ) {
                    Picker("Sort", selection: $viewModel.sortMode) {
                        ForEach(DeviceSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if viewModel.devices.isEmpty {
                    EmptyStateCard(title: "No Bonjour Devices", symbol: "magnifyingglass", detail: "Local Network permission may be required.")
                } else {
                    ForEach(viewModel.devices) { device in
                        DeviceRow(device: device)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
}

private struct DeviceRow: View {
    let device: DiscoveredDevice

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                IconBubble(symbol: device.iconName, color: .cyan)

                VStack(alignment: .leading, spacing: 6) {
                    Text(device.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(device.serviceType)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("IP \(AirScopeFormatters.fallback(device.ipAddress))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(AirScopeFormatters.lastSeen.localizedString(for: device.lastSeen, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
