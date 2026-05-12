import SwiftUI

// V2.0 — Quiet Luxury Tab Bar
enum Tab: Int, CaseIterable {
    case feed
    case settings

    var icon: String {
        switch self {
        case .feed: return "bell"
        case .settings: return "gearshape"
        }
    }

    var title: String {
        switch self {
        case .feed: return "提醒"
        case .settings: return "设置"
        }
    }
}

struct TabBarView: View {
    @State private var selectedTab: Tab = .feed

    var body: some View {
        ZStack(alignment: .bottom) {
            // 内容
            Group {
                switch selectedTab {
                case .feed:
                    ReminderFeedView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab Bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(selectedTab == tab ? QLDesign.Color.primaryText : QLDesign.Color.secondaryText)
                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == tab ? .medium : .regular))
                                .foregroundStyle(selectedTab == tab ? QLDesign.Color.primaryText : QLDesign.Color.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                Rectangle()
                    .fill(QLDesign.Color.background)
                    .ignoresSafeArea(edges: .bottom)
            )
            .overlay(
                Rectangle()
                    .fill(QLDesign.Color.border)
                    .frame(height: 0.5),
                alignment: .top
            )
        }
    }
}
