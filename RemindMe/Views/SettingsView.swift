import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 提醒频率
                Section {
                    Picker("提醒频率", selection: $viewModel.pushFrequency) {
                        Text("每小时").tag(1)
                        Text("每 2 小时").tag(2)
                        Text("每 3 小时").tag(3)
                        Text("每 4 小时").tag(4)
                    }
                    .tint(.primary)
                } header: {
                    Text("提醒频率")
                } footer: {
                    Text("设置提醒推送的时间间隔")
                }

                // MARK: - 安静时段
                Section {
                    DatePicker("开始时间", selection: $viewModel.quietTimeStart, displayedComponents: .hourAndMinute)
                    DatePicker("结束时间", selection: $viewModel.quietTimeEnd, displayedComponents: .hourAndMinute)
                } header: {
                    Text("安静时段")
                } footer: {
                    Text("安静时段内不会推送通知")
                }

                // MARK: - 数据来源
                Section {
                    Toggle("天气提醒", isOn: $viewModel.weatherEnabled)
                    Toggle("日历提醒", isOn: $viewModel.calendarEnabled)
                } header: {
                    Text("数据来源")
                }

                // MARK: - 权限管理
                Section {
                    HStack {
                        Text("通知权限")
                        Spacer()
                        if viewModel.notificationAuthorized {
                            Label("已开启", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14))
                        } else {
                            Button("开启") {
                                viewModel.requestNotificationPermission()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    HStack {
                        Text("日历权限")
                        Spacer()
                        if viewModel.calendarAuthorized {
                            Label("已开启", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14))
                        } else {
                            Button("开启") {
                                viewModel.requestCalendarPermission()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } header: {
                    Text("权限管理")                }

                // MARK: - V1.1 信号值
                Section {
                    HStack {
                        Text("推送信号")
                        Spacer()
                        let learner = PreferenceLearner.shared
                        let signal = learner.signalValue
                        Text(String(format: "%.2f", signal))
                            .foregroundStyle(signal < 0.10 ? .red : signal < 0.30 ? .orange : .secondary)
                    }

                    HStack {
                        Text("推送状态")
                        Spacer()
                        if PreferenceLearner.shared.isPushPaused {
                            Label("已暂停", systemImage: "pause.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14))
                        } else {
                            Label("正常", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14))
                        }
                    }

                    Text("信号值基于你的反馈自动调整，不需要手动设置")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } header: {
                    Text("智能推送")
                }

                // MARK: - Pro 订阅
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(SubscriptionManager.shared.currentTier == .pro ? "Pro 会员" : "升级 Pro")
                                .font(.system(size: 16, weight: .medium))
                            Text(SubscriptionManager.shared.currentTier == .pro ? "已解锁全部功能" : "解锁健康数据、无限提醒、高级类别")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if SubscriptionManager.shared.currentTier == .pro {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 20))
                        } else {
                            Button("¥88/年") {
                                Task { await SubscriptionManager.shared.purchasePro() }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } header: {
                    Text("订阅")
                }

                // MARK: - 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("v\(viewModel.appVersion)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("灵动提醒")
                        Spacer()
                        Text("RemindMe")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .tint(.primary)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                viewModel.save()
            }
        }
    }
}
