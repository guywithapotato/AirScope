import SwiftUI

struct BluetoothScannerView: View {
    @EnvironmentObject private var viewModel: BluetoothViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ControlsCard(
                    title: "\(viewModel.devices.count) BLE Devices",
                    subtitle: viewModel.stateMessage,
                    symbol: "wave.3.right"
                ) {
                    Picker("Sort", selection: $viewModel.sortMode) {
                        ForEach(BluetoothSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if viewModel.devices.isEmpty {
                    EmptyStateCard(title: "No BLE Devices", symbol: "antenna.radiowaves.left.and.right.slash", detail: viewModel.stateMessage)
                } else {
                    ForEach(viewModel.devices) { device in
                        BluetoothRow(device: device)
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

private struct BluetoothRow: View {
    let device: BluetoothDevice

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                IconBubble(symbol: "dot.radiowaves.left.and.right", color: .blue)

                VStack(alignment: .leading, spacing: 6) {
                    Text(device.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(device.uuid.uuidString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("\(device.rssi) dBm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SignalBars(value: device.signalBars)
                    .frame(width: 36, height: 28)
            }
        }
    }
}
