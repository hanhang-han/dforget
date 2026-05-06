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
                    Text("权限管理")
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
