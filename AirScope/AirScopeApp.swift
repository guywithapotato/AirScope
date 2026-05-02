import SwiftUI

@main
struct AirScopeApp: App {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var deviceDiscoveryViewModel = DeviceDiscoveryViewModel()
    @StateObject private var bluetoothViewModel = BluetoothViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dashboardViewModel)
                .environmentObject(deviceDiscoveryViewModel)
                .environmentObject(bluetoothViewModel)
                .task {
                    dashboardViewModel.start()
                    deviceDiscoveryViewModel.start()
                    bluetoothViewModel.start()
                }
        }
    }
}
