import SwiftUI

@main
struct AIComputerApp: App {
    @StateObject private var state = AppState.fromLaunchArguments()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            Group {
                switch state.route {
                case .welcome: WelcomeView()
                case .home: HomeView()
                case .desktop: PhoneDesktopView()
                case .agents: ConnectionsView()
                case .mcp: MCPManagerView()
                case .settings: SettingsView()
                }
            }
            .transition(.opacity.combined(with: .offset(x: 16)))
            .id(state.route)

            if state.route.showsTabBar {
                MainTabBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let message = state.toast {
                ToastView(text: message)
                    .padding(.bottom, 110)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: state.route)
        .animation(.easeInOut(duration: 0.25), value: state.toast)
        .fullScreenCover(item: $state.openApp) { app in
            AppContainer(app: app)
                .environmentObject(state)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $state.showAdd) {
            AddConnectionSheet()
                .environmentObject(state)
                .presentationDetents([.medium, .large])
                .presentationBackground(Theme.surface)
                .preferredColorScheme(.dark)
        }
    }
}
