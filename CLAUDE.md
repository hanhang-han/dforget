# CLAUDE.md — RemindMe (灵动提醒)

## 项目概述

基于上下文感知的 AI 智能生活提醒 iOS App。核心卖点：用户无需手动输入，系统根据天气/日历/时间自动生成并推送提醒，以 iOS Live Activity / 灵动岛为主展示形态。

纯黑白极简设计风格，"温度靠内容不靠视觉"。

## 技术栈

| 层级 | 技术 |
|------|------|
| iOS | Swift 5.9+ / SwiftUI / SwiftData / ActivityKit |
| Widget | WidgetKit (小组件 + Live Activity) |
| 后端 | Node.js (Fastify 5) / ES Module / 腾讯云 SCF |
| 数据库 | PostgreSQL / Redis (规划中，当前内存存储) |
| AI | DeepSeek / GLM (规划中，V1.0 用伪代码模板) |
| 部署 | 后端: 腾讯云 SCF Serverless |

## 项目结构

```
dforget/
├── RemindMe/                    # iOS App (Swift/SwiftUI)
│   ├── App/
│   │   ├── RemindMeApp.swift    # @main 入口，SwiftData 容器，服务初始化
│   │   └── ContentView.swift    # 引导/主页路由
│   ├── Models/
│   │   ├── ReminderItem.swift   # @Model SwiftData 核心数据模型
│   │   ├── ReminderCategory.swift # 枚举: weather/calendar/time/general
│   │   └── UserPreferences.swift  # UserDefaults 偏好持久化
│   ├── ViewModels/
│   │   ├── ReminderFeedViewModel.swift # 提醒列表 CRUD + 反馈
│   │   └── SettingsViewModel.swift     # 设置管理
│   ├── Views/
│   │   ├── OnboardingView.swift       # 3 步引导 (介绍→通知权限→日历权限)
│   │   ├── TabBarView.swift           # 三 Tab: 提醒/对话/设置
│   │   ├── ReminderFeedView.swift     # 提醒流 (下拉刷新 + 空状态)
│   │   ├── ReminderCardView.swift     # 标准提醒卡片 + 反馈手势
│   │   ├── SmallNoteCardView.swift    # 小纸条卡片 (手写风格)
│   │   ├── SettingsView.swift         # 设置页面 (频率/免打扰/数据源/Pro)
│   │   ├── AIDialogView.swift         # AI 对话界面 (V2.1)
│   │   └── AdvancedCategoriesView.swift # 高级类别设置 (V3.0)
│   ├── Services/
│   │   ├── MockReminderEngine.swift    # V1.0 提醒生成 (本地模板 + 时间规则)
│   │   ├── NotificationService.swift   # 本地通知 + 定时推送
│   │   ├── LiveActivityService.swift   # ActivityKit 灵动岛管理
│   │   ├── CalendarService.swift       # EventKit 日历读取 (V2.1)
│   │   ├── HealthService.swift         # HealthKit 健康 (V2.0, Pro)
│   │   ├── LocationService.swift       # CoreLocation 位置 (V3.0)
│   │   ├── PreferenceLearner.swift     # 偏好学习 + 信号值系统 (V1.1)
│   │   ├── AIDialogService.swift       # AI 对话偏好调整 (V2.1)
│   │   ├── AdvancedCategories.swift    # 高级类别 + 宠物/社交 (V3.0)
│   │   ├── SubscriptionManager.swift   # StoreKit 2 订阅 (V2.0)
│   │   ├── FamilyShareAndProfile.swift # 家庭共享 + 用户画像 (V3.0)
│   │   └── MonthlyReportGenerator.swift # 月度报告 (V2.0)
│   ├── Activities/
│   │   ├── RemindMeAttributes.swift  # ActivityKit 属性定义
│   │   └── RemindMeActivity.swift    # 灵动岛 Widget (@main WidgetBundle)
│   ├── Widget/
│   │   └── RemindMeWidget.swift      # 桌面小组件 (小/中/大, V2.0 Pro)
│   └── SupportingFiles/
│       ├── Info.plist               # 权限声明 + Live Activity + 后台模式
│       ├── WidgetInfo.plist         # Widget Extension Info
│       └── RemindMe.entitlements    # HealthKit + APNs
├── backend/                      # Node.js 后端 (腾讯云 SCF)
│   ├── src/
│   │   ├── functions/
│   │   │   ├── scheduler.js      # 定时触发 (每 2 小时), 生成推送
│   │   │   ├── api.js            # HTTP API (提醒/反馈/偏好/设备令牌)
│   │   │   └── activity.js       # Live Activity token 管理
│   │   └── shared/
│   │       ├── reminder-engine.js # 提醒生成 (40% 规则 + 60% 伪 AI)
│   │       ├── weather.js        # 天气服务 (V1.0 Mock, 规划和风 API)
│   │       ├── signal.js         # 信号值系统 (-1.0 ~ +1.0)
│   │       ├── push.js           # APNs 推送 (V1.0 Mock)
│   │       └── utils.js          # 工具函数 (时区/免打扰/冷启动)
│   └── package.json              # Fastify 5, ES Module
└── project.yml                   # XcodeGen 项目配置
```

## 构建 & 运行

### 前置条件
- Xcode 15+ (iOS 17.0 SDK)
- XcodeGen (`brew install xcodegen`)
- Node.js 18+ (后端开发)

### iOS 构建

```bash
# 生成 Xcode 项目 (如无 .xcodeproj)
xcodegen generate

# 构建运行 (模拟器, 跳过签名)
xcodebuild -project RemindMe.xcodeproj \
  -scheme RemindMe \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

### 后端

```bash
cd backend
npm install
npm run dev
```

## 架构要点

### 双 Target 结构
- **RemindMe** (主 App): 包含所有业务代码 + `RemindMeAttributes.swift` (共享)
- **RemindMeWidget** (Widget Extension): 包含 Widget/ + Activities/，有自己的 `@main`

### 数据层
- **SwiftData** (`ReminderItem`): 本地持久化，ModelContainer 注入
- **UserDefaults** (`UserPreferences`): 偏好设置
- **后端**: 当前内存存储，V1.1 接入 PostgreSQL/Redis

### 提醒生成流程
1. `MockReminderEngine` 根据时间段选类别 (早晨天气/日历，上午时间，下午混合，晚上小纸条)
2. 每天生成 4-6 条，小纸条每周最多 1 条 (5% 概率)
3. `NotificationService` 定时推送，支持免打扰时段
4. `PreferenceLearner` 信号值系统根据反馈自适应频率

### 信号值系统
- 范围: -1.0 ~ +1.0，加权移动平均 (α=0.3)
- 反馈权重: 👍 +0.15 / 👎 -0.25 / 忽略 -0.10 / 24h 无动作 +0.02
- 暂停阈值: < 0.10 / 恢复阈值: ≥ 0.30
- 冷启动: 保守期(1-3天) → 探索期(4-7天) → 正常期(8天+)

### 后端 API

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/reminders` | 生成提醒 |
| GET | `/api/reminders` | 提醒历史 |
| POST | `/api/feedback` | 提交反馈 |
| GET/PUT | `/api/preferences` | 偏好管理 |
| POST | `/api/device-token` | 注册推送 Token |
| POST/DELETE | `/api/activity-token` | Live Activity Token |

## 版本路线图

| 版本 | 核心功能 | 状态 |
|------|---------|------|
| **V1.0** | 天气+时间+日历模板提醒，Live Activity，本地通知，极简 UI | ✅ 当前 |
| **V1.1** | PreferenceLearner 信号值，反馈机制，偏好存储，推送频率控制 | 🔧 部分实现 |
| **V2.0** | HealthKit，Pro 订阅 (StoreKit 2)，Widget，月度报告 | 📝 代码占位 |
| **V2.1** | AI 对话调偏好，多主题，日历智能 | 📝 代码占位 |
| **V3.0** | 位置感知，家庭/宠物/财务，家庭共享，深度学习 | 📝 代码占位 |

## 代码约定

- 语言: Swift (iOS) / JavaScript (后端)
- UI: 纯 SwiftUI，无 UIKit 包装
- 数据: SwiftData (`@Model`)，不用 CoreData
- 架构: MVVM (ViewModel 用 `@Published` + `ObservableObject`)
- 单例模式: Services 使用 `static let shared`
- 权限: Info.plist 声明，运行时动态请求
- 版本标注: 每个文件头部注释标注目标版本 (`V1.0`/`V1.1`/`V2.0`/`V3.0`)

## 已知问题 & 修复记录

项目代码为早期原型，存在以下编译问题 (已在本地修复):

1. **字符串插值转义** — `AdvancedCategories.swift` / `HealthService.swift` 中 `\"` 在 `\(...)` 内不合法，需用 raw string `#"...\#()..."#`
2. **类型引用路径** — `AdvancedCategoriesView.swift` 中 `PetProfileManager.PetProfile.PetType` 应为 `PetProfileManager.PetType`
3. **访问控制** — `PreferenceLearner.signalValue` 需为 `internal` 而非 `private` (被 `FamilyShareAndProfile` 引用)
4. **MainActor 隔离** — `AIDialogService` 需标注 `@MainActor` 以访问 `SubscriptionManager.shared.currentTier`
5. **元组类型推断** — `PreferenceLearner.getSortedCategories()` 中元组类型需与返回值一致

## 重要 TODO 汇总

- 接入真实 AI 模型 (DeepSeek/GLM) 替换 MockReminderEngine
- 后端数据持久化 (PostgreSQL/Redis)
- APNs 真实推送替换 Mock
- 和风天气 API 替换 Mock 天气
- Widget App Group 数据共享
- 通讯录读取 (社交生日提醒)
- CloudKit 家庭同步
