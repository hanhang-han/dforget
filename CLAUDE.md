# CLAUDE.md — RemindMe (灵动提醒)

## 产品定义

**常驻锁屏的智能便签。** 灵动岛和锁屏 Live Activity 始终展示一条当前提醒，用户每次拿起手机自然看到，有用就记住了，没用就放下——零成本，零打扰。

## 核心交互模型

这不是推送产品。没有"叮"一声打断用户。

```
用户自然拿起手机 (日均 100+ 次)
  → 瞥一眼锁屏 / 灵动岛
  → 有用 → 留下印象，偶尔给个 👍
  → 没用 → 无感，放下手机，什么都没发生
```

**"没用"的成本是零。** 用户本来就要看手机，看到没用的内容和没看到一样。但"有用"的收益很高——独占灵动岛，没有其他信息竞争注意力。10 条里有 1 条真正帮到用户，就够了。

## 产品哲学

- **价值在锁屏和灵动岛，不在 App 内部。** App 只是管理和反馈的入口
- **温度靠内容不靠视觉。** 纯黑白极简，让内容本身说话
- **宁软不硬。** 软性建议永远成立 ("天气不错的话，中午出去走走？")，硬性断言容易出错 ("下午有阵雨，带伞")。错了会丧失信任
- **常驻不等于骚扰。** 内容轮换而不是推送通知，用户主动看而不是被动收
- **命中率 > 数量。** 一条真正有用的提醒胜过十条废话

## 展示面

| 展示面 | 位置 | 用户行为 |
|--------|------|----------|
| **灵动岛** (Compact/Expanded) | 手机顶部常驻 | 拿起手机自然看到，点击展开看详情 |
| **锁屏 Live Activity** | 锁屏横幅 | 解锁前就能看到 |
| **桌面小组件** (小/中) | 桌面 | 浏览桌面时扫一眼 |
| **锁屏小组件** (Inline) | 锁屏底部 | 时间旁边始终有一行 |
| **App 首页** | App 内 | 只展示当前 1 条 + 反馈入口，不是浏览页 |

每次生成新提醒时，同一内容同步写入所有展示面（SwiftData → Live Activity → App Group → Widget）。

## 内容策略

### 原则
- **软性建议优先** — "出门前看一眼天气" 而不是 "今天有雨带伞"
- **难以证伪** — 建议类内容永远成立，不依赖外部数据准确性
- **时间感知** — 根据时间段选类别（早晨生活建议、上午效率、下午关怀、晚上情绪）
- **低频高质** — 每天 4-6 条，每 10 分钟轮换展示，用户自然看到新鲜内容

### 类别
| 类别 | 时间段 | 风格 |
|------|--------|------|
| weather 生活建议 | 早晨 7-10 | 天气相关的软性提醒 |
| calendar 日程关怀 | 上午 9-12 | 和日程节奏相关 |
| time 效率/健康 | 全天 | 站起来走走、喝水、深呼吸 |
| general 小纸条 | 晚上/深夜 | 情绪关怀、鼓励，每周最多 1 条 |

### 内容生成
- V1.0: 本地模板池 + 时间规则 + 去重
- V1.1: 信号值反馈学习，调整类别配比
- V2.0: 接入 AI 生成个性化内容
- 内容池目标: 100+ 条，去重周期 14 天

## 信号值系统

不是用来"开关推送"的，而是用来**调整内容配比**：

- 范围: -1.0 ~ +1.0，加权移动平均 (α=0.3)
- 👍 +0.15 / 👎 -0.25 / 忽略 -0.10 / 24h 无动作 +0.02
- **信号值低** → 减少该类别出现频率，但不停掉（因为常驻展示没有打扰）
- **信号值高** → 该类别出现更频繁
- **小纸条始终保留** — 低风险，偶尔暖心
- 冷启动: 保守期(1-3天) → 探索期(4-7天) → 正常期(8天+)

## 反馈机制

- **灵动岛展开按钮**: "换一个" / "关闭"
  - "换一个" = 这条没用，给我看下一条（deeplink: `remindme://refresh`）
  - "关闭" = 暂时不想看（deeplink: `remindme://dismiss`）
- **通知 Action**: 👍 有用 / 👎 不需要（锁屏通知直接操作）
- **App 内反馈**: 点击卡片弹出半屏反馈面板

## 首页设计

- **不展示历史提醒**，只展示当前生效的 1 条
- 首页是反馈入口，不是浏览页
- 历史提醒静默保存在 SwiftData，供 PreferenceLearner 学习
- 7 天自动清理旧数据

## 技术栈

| 层级 | 技术 |
|------|------|
| iOS | Swift 5.9+ / SwiftUI / SwiftData / ActivityKit |
| Widget | WidgetKit (小组件 + Live Activity) |
| 设计系统 | QLDesign (Quiet Luxury, 纯黑 + 0.5px 白色边框) |
| 后端 | Node.js (Fastify 5) / ES Module / 腾讯云 SCF |
| 数据库 | PostgreSQL / Redis (规划中，当前内存存储) |
| AI | DeepSeek / GLM (规划中，V1.0 用模板) |
| 部署 | 后端: 腾讯云 SCF Serverless |

## 项目结构

```
dforget/
├── RemindMe/                    # iOS App (Swift/SwiftUI)
│   ├── App/
│   │   ├── RemindMeApp.swift    # @main 入口，SwiftData 容器，服务初始化
│   │   └── ContentView.swift    # 引导/主页路由
│   ├── Design/
│   │   └── DesignTokens.swift   # QLDesign 设计系统令牌 (App + Widget 共享)
│   ├── Models/
│   │   ├── ReminderItem.swift   # @Model SwiftData 核心数据模型
│   │   ├── ReminderCategory.swift # 枚举: weather/calendar/time/general
│   │   └── UserPreferences.swift  # UserDefaults 偏好持久化
│   ├── ViewModels/
│   │   ├── ReminderFeedViewModel.swift # 当前提醒管理 + 反馈 + 数据同步
│   │   └── SettingsViewModel.swift     # 设置管理
│   ├── Views/
│   │   ├── OnboardingView.swift       # 3 步引导 (介绍→通知权限→日历权限)
│   │   ├── TabBarView.swift           # 两 Tab: 提醒/设置
│   │   ├── ReminderFeedView.swift     # 首页：当前提醒单卡片 + 反馈入口
│   │   ├── ReminderCardView.swift     # 标准提醒卡片 + 反馈手势
│   │   ├── SmallNoteCardView.swift    # 小纸条卡片 (手写风格)
│   │   ├── SettingsView.swift         # 设置页面 (频率/免打扰/数据源/Pro)
│   │   ├── AIDialogView.swift         # AI 对话界面 (V2.1)
│   │   └── AdvancedCategoriesView.swift # 高级类别设置 (V3.0)
│   ├── Services/
│   │   ├── MockReminderEngine.swift    # V1.0 提醒生成 (本地模板 + 时间规则)
│   │   ├── NotificationService.swift   # 本地通知 + Action Buttons
│   │   ├── LiveActivityService.swift   # ActivityKit 灵动岛管理
│   │   ├── ContextEngine.swift         # 场景融合引擎 (时间+天气+电量)
│   │   ├── BackgroundRotationService.swift # BGTask 后台轮换
│   │   ├── CalendarService.swift       # EventKit 日历读取 (V2.1)
│   │   ├── SharedDataStore.swift       # App Group 共享数据层
│   │   ├── HealthService.swift         # HealthKit (V2.0, Pro)
│   │   ├── LocationService.swift       # CoreLocation (V3.0)
│   │   ├── PreferenceLearner.swift     # 偏好学习 + 信号值系统
│   │   ├── AIDialogService.swift       # AI 对话偏好调整 (V2.1)
│   │   ├── AdvancedCategories.swift    # 高级类别 (V3.0)
│   │   ├── SubscriptionManager.swift   # StoreKit 2 (V2.0)
│   │   ├── FamilyShareAndProfile.swift # 家庭共享 (V3.0)
│   │   └── MonthlyReportGenerator.swift # 月度报告 (V2.0)
│   ├── Activities/
│   │   ├── RemindMeAttributes.swift  # ActivityKit 属性定义
│   │   └── RemindMeActivity.swift    # 灵动岛 + 锁屏 Live Activity
│   ├── Widget/
│   │   └── RemindMeWidget.swift      # 桌面小组件 (小/中) + 锁屏 Inline
│   └── SupportingFiles/
│       ├── Info.plist               # 权限 + Live Activity + 后台模式
│       ├── WidgetInfo.plist         # Widget Extension Info
│       ├── RemindMe.entitlements    # App Group + APNs
│       └── RemindMeWidget.entitlements
├── backend/                      # Node.js 后端 (腾讯云 SCF)
│   ├── src/
│   │   ├── functions/
│   │   │   ├── scheduler.js      # 定时触发，生成内容
│   │   │   ├── api.js            # HTTP API (提醒/反馈/偏好/设备令牌)
│   │   │   └── activity.js       # Live Activity push token 管理
│   │   └── shared/
│   │       ├── reminder-engine.js # 内容生成引擎
│   │       ├── weather.js        # 天气服务 (规划和风 API)
│   │       ├── signal.js         # 信号值系统
│   │       ├── push.js           # APNs 推送
│   │       └── utils.js          # 工具函数
│   └── package.json              # Fastify 5, ES Module
└── project.yml                   # XcodeGen 项目配置
```

## 构建 & 运行

```bash
# 生成 Xcode 项目
xcodegen generate

# 构建 (模拟器, 跳过签名)
xcodebuild -project RemindMe.xcodeproj \
  -scheme RemindMe \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

# 后端
cd backend && npm install && npm run dev
```

## 架构要点

### 双 Target 结构
- **RemindMe** (主 App): 所有业务代码 + `RemindMeAttributes.swift` (共享)
- **RemindMeWidget** (Widget Extension): Widget/ + Activities/ + DesignTokens.swift + SharedDataStore.swift

### 数据层
- **SwiftData** (`ReminderItem`): 本地持久化
- **App Group** (`SharedDataStore`): 主 App 与 Widget 共享最新提醒数据
- **UserDefaults** (`UserPreferences`): 偏好设置

### 内容轮换机制
- 每 10 分钟轮换一条新内容 (`ReminderFeedViewModel` Timer)
- 同一文本同步写入: SwiftData → Live Activity → App Group → Widget
- 后台轮换: `BGTaskRefresh` 保证 App 不在前台时也能更新灵动岛
- 去重: `seenToday` 集合保证当天不重复

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
| **V1.0** | 常驻灵动岛/锁屏，本地模板内容，Live Activity，反馈机制，Quiet Luxury UI | ✅ 当前 |
| **V1.1** | 信号值反馈学习，类别配比调整，内容池扩充 100+，去重优化 | 🔧 部分实现 |
| **V2.0** | AI 个性化内容生成，Pro 订阅，桌面 Widget，月度报告 | 📝 规划中 |
| **V2.1** | AI 对话调偏好，日历智能，多主题 | 📝 规划中 |
| **V3.0** | 位置感知，家庭/宠物/财务，家庭共享 | 📝 规划中 |

## 代码约定

- 语言: Swift (iOS) / JavaScript (后端)
- UI: 纯 SwiftUI，无 UIKit 包装
- 数据: SwiftData (`@Model`)，不用 CoreData
- 架构: MVVM (`@Published` + `ObservableObject`)
- 设计系统: `QLDesign` 命名空间，所有 UI 文件统一引用
- 单例模式: Services 使用 `static let shared`
- 版本标注: 文件头部注释标注目标版本

## 已知编译问题 (已修复)

1. **字符串插值转义** — `AdvancedCategories.swift` / `HealthService.swift` 中 `\"` 在 `\(...)` 内不合法
2. **类型引用路径** — `PetProfileManager.PetProfile.PetType` → `PetProfileManager.PetType`
3. **访问控制** — `PreferenceLearner.signalValue` 需为 `internal`
4. **MainActor 隔离** — `AIDialogService` 需标注 `@MainActor`

## 关键 TODO

- 扩充内容池至 100+ 条，软性建议风格
- 接入 AI 生成个性化内容 (DeepSeek/GLM)
- 后端数据持久化 (PostgreSQL/Redis)
- 和风天气 API 接入
- 通讯录读取 (社交生日提醒)
