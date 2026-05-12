// V2.0 — Quiet Luxury 首页：当前提醒单卡片视图
import SwiftUI
import SwiftData

struct ReminderFeedView: View {
    @StateObject private var viewModel = ReminderFeedViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                if viewModel.hasContent {
                    currentCard
                } else {
                    ProgressView()
                        .tint(.white)
                        .onAppear { viewModel.rotateToNext() }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(QLDesign.Color.background)
            .navigationTitle("灵动提醒")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            viewModel.start(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    // MARK: - 当前提醒卡片

    private var currentCard: some View {
        VStack(spacing: 20) {
            // 分类 + 时间
            HStack {
                Label(
                    viewModel.currentCategory.displayName,
                    systemImage: viewModel.currentCategory.iconName
                )
                .font(QLDesign.Font.label(13))
                .foregroundStyle(QLDesign.Color.secondaryText)

                Spacer()

                Text(viewModel.lastRotationTime, style: .relative)
                    .font(QLDesign.Font.label(12))
                    .foregroundStyle(QLDesign.Color.labelText)
            }

            // 提醒文案
            Text(viewModel.currentText)
                .font(viewModel.currentIsSmallNote
                    ? QLDesign.Font.serif(18).italic()
                    : QLDesign.Font.heading(18))
                .foregroundStyle(QLDesign.Color.primaryText)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 小纸条标签
            if viewModel.currentIsSmallNote {
                HStack {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(QLDesign.Color.border)
                        .frame(width: 20, height: 3)
                    Text("小纸条")
                        .font(QLDesign.Font.label(11))
                        .foregroundStyle(QLDesign.Color.labelText)
                    Spacer()
                }
            }

            // 反馈按钮
            HStack(spacing: 16) {
                feedbackButton(
                    emoji: "👍", label: "有用",
                    isPrimary: true
                ) {
                    viewModel.setFeedback(type: "positive")
                }

                feedbackButton(
                    emoji: "👎", label: "不需要",
                    isPrimary: false
                ) {
                    viewModel.setFeedback(type: "negative")
                }
            }
            .padding(.top, 4)
        }
        .padding(QLDesign.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: QLDesign.Shape.cardRadius, style: .continuous)
                .fill(QLDesign.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QLDesign.Shape.cardRadius, style: .continuous)
                .stroke(QLDesign.Color.border, lineWidth: 0.5)
        )
        .padding(.horizontal, QLDesign.Spacing.pageMargin)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentText)
    }

    // MARK: - 反馈按钮

    private func feedbackButton(emoji: String, label: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 18))
                Text(label)
                    .font(QLDesign.Font.bodyMedium(15))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: QLDesign.Shape.buttonRadius, style: .continuous)
                    .fill(isPrimary ? SwiftUI.Color.white : QLDesign.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: QLDesign.Shape.buttonRadius, style: .continuous)
                    .stroke(isPrimary ? SwiftUI.Color.clear : QLDesign.Color.border, lineWidth: 0.5)
            )
            .foregroundStyle(isPrimary ? SwiftUI.Color.black : SwiftUI.Color.white)
        }
        .buttonStyle(.plain)
    }
}
