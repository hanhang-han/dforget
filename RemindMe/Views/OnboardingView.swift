import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var notificationGranted = false
    @State private var calendarGranted = false

    private let totalSteps = 3

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // 内容区域
                TabView(selection: $currentStep) {
                    stepIntroduction.tag(0)
                    stepNotifications.tag(1)
                    stepCalendar.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer(minLength: 40)

                // 底部按钮
                bottomButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                // 页码指示器
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color(.label) : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Step 1: 介绍

    private var stepIntroduction: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.and.waves.left.and.right")
                .font(.system(size: 60))
                .foregroundStyle(Color(.label))

            VStack(spacing: 8) {
                Text("灵动提醒")
                    .font(.system(size: 28, weight: .bold))
                Text("RemindMe")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Text("在恰当的时刻，给你恰好的提醒。\n不多不少，刚刚好。")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 2: 通知权限

    private var stepNotifications: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(notificationGranted ? .green : Color(.label))

            Text("开启通知")
                .font(.system(size: 24, weight: .bold))

            Text("我们需要通知权限来发送提醒。\n你可以在设置中调整频率和安静时段。")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            if notificationGranted {
                Label("已开启", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 15))
            } else {
                Button {
                    NotificationService.shared.requestAuthorization { granted in
                        notificationGranted = granted
                    }
                } label: {
                    Text("开启通知权限")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.label))
                        .foregroundStyle(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 60)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 3: 日历权限

    private var stepCalendar: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(calendarGranted ? .green : Color(.label))

            Text("日历访问")
                .font(.system(size: 24, weight: .bold))

            Text("可选：访问日历可以结合你的日程\n生成更智能的提醒。")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            if calendarGranted {
                Label("已开启", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 15))
            } else {
                Button {
                    CalendarService.shared.requestAuthorization { granted in
                        calendarGranted = granted
                    }
                } label: {
                    Text("开启日历权限")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.label))
                        .foregroundStyle(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 60)

                Button("跳过") {
                    calendarGranted = false
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 底部按钮

    private var bottomButton: some View {
        Button {
            withAnimation {
                if currentStep < totalSteps - 1 {
                    currentStep += 1
                } else {
                    completeOnboarding()
                }
            }
        } label: {
            Text(currentStep == totalSteps - 1 ? "开始使用" : "下一步")
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.label))
                .foregroundStyle(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func completeOnboarding() {
        var prefs = UserPreferences.load()
        prefs.hasCompletedOnboarding = true
        prefs.save()
        onComplete()
    }
}
