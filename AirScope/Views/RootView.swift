import SwiftUI

struct RootView: View {
    @State private var selectedTab: AirScopeTab = .dashboard

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 14) {
                    HeaderView()

                    Picker("Section", selection: $selectedTab) {
                        ForEach(AirScopeTab.allCases) { tab in
                            Label(tab.title, systemImage: tab.symbol).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Group {
                        switch selectedTab {
                        case .dashboard:
                            DashboardView()
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        case .devices:
                            DeviceDiscoveryView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        case .bluetooth:
                            BluetoothScannerView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .animation(.spring(response: 0.42, dampingFraction: 0.86), value: selectedTab)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.accentColor)
    }
}

private struct HeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            .shadow(color: .cyan.opacity(0.24), radius: 18, y: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("AirScope")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Live local network visibility")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 18)
    }
}

private enum AirScopeTab: String, CaseIterable, Identifiable {
    case dashboard
    case devices
    case bluetooth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Scope"
        case .devices: return "LAN"
        case .bluetooth: return "BLE"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: return "speedometer"
        case .devices: return "network"
        case .bluetooth: return "wave.3.right"
        }
    }
}

#Preview {
    RootView()
        .environmentObject(DashboardViewModel())
        .environmentObject(DeviceDiscoveryViewModel())
        .environmentObject(BluetoothViewModel())
}
