# Ralph Fix Plan — RemindMe V1.0 完善版

> 目标：完善 V1.0 基础功能，让产品体验对齐设计文档
> 设计文档：docs/remind-app-ui-design.md, docs/remind-app-onboarding.md, docs/remind-app-warmth.md

## High Priority — P0 核心体验

- [ ] Task 1: 砍掉 AI 对话 Tab，改为 2 页 + Modal 结构
  - 修改：RemindMe/Views/TabBarView.swift → 改为只有 Feed + Settings 两个 Tab
  - 删除或隐藏：AIDialogView 的 Tab 入口（保留文件供 V2.1 使用）
  - 修改：RemindMe/Views/ReminderFeedView.swift — Tab 标题从"提醒"改为"提醒"
  - 验证：App 启动后只有 2 个 Tab（提醒 + 设置）

- [ ] Task 2: 实现半屏反馈 Modal（点击卡片弹出）
  - 新建或修改：RemindMe/Views/ReminderCardView.swift
  - 点击卡片 → 弹出 .sheet 半屏面板，包含：
    - 提醒文案 + 时间
    - 👍 有用 / 👎 不需要 两个按钮
    - "暂时不推这类了" 文字按钮
    - 推送频率选择（正常/减少）
  - 反馈后调用 ReminderFeedViewModel.setFeedback()
  - 反馈操作后显示 Undo 提示条（3 秒消失）
  - 移除当前的长按上下文菜单反馈方式
  - 验证：点击卡片弹出半屏面板，反馈后卡片状态更新

- [ ] Task 3: Feed 按天分组显示
  - 修改：RemindMe/Views/ReminderFeedView.swift
  - 提醒按日期分组：今天 / 昨天 / 更早（显示具体日期如"5月4日"）
  - 分组标题用极浅灰小字
  - 每组内按时间倒序
  - 验证：提醒列表显示"今天"分组标题，昨天的提醒在"昨天"分组下

## Medium Priority — P1 重要功能

- [ ] Task 4: 设置页完善（每日上限 + 分段时段 + 音效）
  - 修改：RemindMe/Views/SettingsView.swift
  - 新增"每天上限"：数字选择器（3/5/8/10 条）
  - 新增"推送时段"：5 个 Toggle（早间 07-09/上午 09-12/午间 12-14/下午 14-18/晚间 18-22）
  - 新增"音效"选择：柔和叮/紧急叮叮/静默
  - 新增"隐私政策"链接行
  - 修改：RemindMe/Models/UserPreferences.swift — 添加 dailyLimit, timeSlotToggles, soundType 字段
  - 验证：设置页显示所有新选项，选择后生效

- [ ] Task 5: Live Activity 增加 [换一个] [关闭] 按钮
  - 修改：RemindMe/Activities/RemindMeActivity.swift
  - 展开布局底部添加两个 Button：
    - [换一个] → 通知 App 生成新提醒
  - 紧凑布局保持不变（图标+文案）
  - 验证：长按灵动岛展开后能看到两个按钮

- [ ] Task 6: Lock Screen Inline Widget
  - 修改：RemindMe/Widget/RemindMeWidget.swift
  - 新增 Lock Screen Inline Widget（显示在时间下方）
  - 格式：图标 + 一句话提醒（如 "🌧️ 带伞出门"）
  - 删除 Large Widget（设计稿已砍掉）
  - 验证：锁屏底部显示一句话提醒

- [ ] Task 7: 通知添加 action buttons
  - 修改：RemindMe/Services/NotificationService.swift
  - 每条通知附带 2 个 action：有用 / 不需要
  - 点击 action 后触发反馈逻辑（调用 PreferenceLearner）
  - 通知标题固定为"智能提醒"
  - 验证：收到通知后能看到两个按钮，点击后反馈生效

## Low Priority — P2 打磨

- [ ] Task 8: 设计规范对齐（强调色 + 左滑删除 + 动画）
  - 添加强调色 #FF6B35（温暖橙），用于反馈按钮和关键交互
  - Feed 卡片支持左滑删除
  - 卡片点击动效 scale(0.97) → 1.0（0.1s）
  - Live Activity 内容切换交叉淡入淡出 0.3s
  - 验证：视觉风格和设计稿一致

## Completed
- [x] V1.0 基础架构（SwiftUI + SwiftData + ActivityKit）
- [x] 32 条提醒模板生成
- [x] 本地通知推送
- [x] 灵动岛基础展示
- [x] 引导页 3 步流程
- [x] 偏好学习信号值系统
- [x] 编译问题修复
- [x] CLAUDE.md 项目文档

## Notes
- 构建：xcodegen generate → xcodebuild（见 AGENT.md）
- 每个任务完成后编译验证
- 不要删除任何现有 Service 文件，只修改/新增
- 提交信息用中文
- 不要修改 .ralph/ 目录和 .ralphrc
