# 智能提醒 App — 数据模型与隐私设计文档

| 项目 | 内容 |
|------|------|
| 文档版本 | v1.0 |
| 日期 | 2026-05-06 |
| 适用范围 | iOS 原生智能提醒 App |
| 设计原则 | 用户可控、最小必要、本地优先、端到端加密 |

---

## 1. 数据分类与分级

### 1.1 敏感级别定义

| 级别 | 标识 | 定义 | 处理要求 |
|------|------|------|----------|
| L4 — 极高 | 🔴 | 泄露将导致严重人身或财产损害 | 仅本地，禁止上传，硬件级加密 |
| L3 — 高 | 🟠 | 泄露可识别个人身份或敏感生活细节 | 端到端加密或仅本地存储 |
| L2 — 中 | 🟡 | 个人偏好数据，非公开但影响有限 | 传输加密 + 服务端加密存储 |
| L1 — 低 | 🟢 | 聚合/匿名化数据，无个人识别风险 | 正常加密传输 |

### 1.2 数据分类表

| 数据类别 | 具体内容 | 敏感级别 | 存储位置 | 保留策略 | 采集方式 |
|----------|----------|----------|----------|----------|----------|
| **Health 数据** | 步数、睡眠、心率、用药记录等 | L4 🔴 | 仅本地（HealthKit 安全域） | 永久（随用户设备），删除 App 时清除 | HealthKit 授权 |
| **财务信息** | 还款日、信用卡账单日、贷款金额等 | L4 🔴 | 仅本地（SwiftData + Keychain） | 永久，用户可手动删除 | 用户手动输入 |
| **地理位置** | 当前/历史位置 | L3 🟠 | 仅本地，缓存 7 天 | 7 天自动清理 | 系统位置权限（V2+） |
| **日历数据** | 日程事件、会议、提醒 | L3 🟠 | 本地为主，摘要上传 | 日程结束后 30 天清理摘要 | 日历读写权限 |
| **用户自填数据** | 宠物信息、药品提醒、证件有效期、生日等 | L3 🟠 | 端到端加密存储 | 用户可随时删除 | 用户手动输入 |
| **用户偏好/反馈** | 提醒频率偏好、反馈内容、标签选择 | L2 🟡 | 端到端加密存储 | 账户存续期间 | 用户交互产生 |
| **行为数据** | 通知点击/忽略率、使用频率、功能使用情况 | L2 🟡 | 匿名化后上传服务端 | 聚合数据保留 90 天 | 系统自动采集 |
| **天气数据** | 天气预报、历史天气 | L1 🟢 | 服务端缓存 | 24 小时自动清除 | 后端 API 调用 |
| **时间/日期** | 当前时间、时区、日期 | L1 🟢 | 无需持久化 | 无 | 系统获取，无需权限 |

### 1.3 数据流向总览

```
┌─────────────────────────────────────────────────────┐
│                    用户设备 (iOS)                     │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  HealthKit   │  │  SwiftData   │  │  Keychain  │ │
│  │  (L4)        │  │  (L3, L2)    │  │  (密钥)    │ │
│  │  永不上传    │  │              │  │            │ │
│  └──────────────┘  └──────┬───────┘  └────────────┘ │
│                           │                           │
│              ┌────────────┼────────────┐              │
│              │            │            │              │
│              ▼            ▼            ▼              │
│        ┌──────────┐ ┌──────────┐ ┌─────────────┐     │
│        │ 匿名行为 │ │ 偏好(加密)│ │ 日历摘要    │     │
│        │ 上传(L2) │ │ 上传(L2) │ │ 上传(L3)    │     │
│        └────┬─────┘ └────┬─────┘ └──────┬──────┘     │
└─────────────┼────────────┼─────────────┼─────────────┘
              │            │             │
              ▼            ▼             ▼
┌─────────────────────────────────────────────────────┐
│                     服务端                           │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  PostgreSQL  │  │  Redis 缓存  │  │  LLM API   │ │
│  │  (主数据库)  │  │  (天气/会话) │  │  (临时上下文)│ │
│  └──────────────┘  └──────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## 2. 数据模型设计

### 2.1 本地数据模型（SwiftData）

#### 用户自填数据

```swift
// MARK: - 提醒条目
@Model
final class ReminderItem {
    @Attribute(.unique) var id: UUID
    var title: String                    // 提醒标题
    var notes: String?                   // 备注
    var dueDate: Date?                   // 到期日期
    var repeatRule: RepeatRule?          // 重复规则
    var category: ReminderCategory       // 分类
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // 关联
    @Relationship(deleteRule: .cascade) var tags: [Tag]
}

// MARK: - 重复规则
enum RepeatRule: Codable {
    case daily
    case weekly(weekdays: [Int])        // 1=Sun ... 7=Sat
    case monthly(day: Int)
    case yearly(month: Int, day: Int)
    case custom(intervalDays: Int)
}

// MARK: - 提醒分类
enum ReminderCategory: String, Codable, CaseIterable {
    case health       // 健康/用药
    case finance      // 财务（仅本地）
    case pet          // 宠物
    case document     // 证件
    case birthday     // 生日
    case general      // 通用
}

// MARK: - 标签
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var createdAt: Date
}
```

#### 用户偏好与设置

```swift
// MARK: - 用户偏好
@Model
final class UserPreference {
    @Attribute(.unique) var id: UUID
    
    // 通知偏好
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    var maxDailyNotifications: Int       // 默认 10
    var preferredNotificationStyle: NotificationStyle
    
    // 功能开关
    var isWeatherEnabled: Bool           // 天气提醒
    var isCalendarEnabled: Bool          // 日历集成
    var isHealthEnabled: Bool            // HealthKit (V1.1)
    var isLocationEnabled: Bool          // 位置服务 (V2+)
    
    // AI 偏好
    var aiSuggestionLevel: AILevel       // conservative / balanced / proactive
    var feedbackHistory: [FeedbackEntry] // 用户反馈历史
    
    var updatedAt: Date
}

enum NotificationStyle: String, Codable {
    case gentle    // 轻柔
    case normal    // 标准
    case urgent    // 紧急
}

enum AILevel: String, Codable {
    case conservative  // 仅关键提醒
    case balanced      // 适中
    case proactive     // 主动建议
}

struct FeedbackEntry: Codable {
    var notificationId: String
    var action: FeedbackAction  // liked / dismissed / snoozed / edited
    var comment: String?
    var timestamp: Date
}

enum FeedbackAction: String, Codable {
    case liked
    case dismissed
    case snoozed
    case edited
}
```

#### 本地专属数据（永不上传）

```swift
// MARK: - 财务数据（L4，仅本地）
@Model
final class FinanceEntry {
    @Attribute(.unique) var id: UUID
    var title: String              // "信用卡还款"、"房租" 等
    var amount: Double?            // 金额（可选，用户可能不想填）
    var dueDay: Int                // 每月几号
    var accountName: String?       // 账户名称
    var isAutoPaid: Bool
    var createdAt: Date
    
    // 标记：此数据永不上传
    // 通过 isSensitive 标志在同步层过滤
    var isSensitive: Bool { true }
}
```

### 2.2 服务端数据模型

> **核心原则**：服务端只存储必要的运行数据，个人数据尽量少存或加密存储。

#### 数据库选型

| 用途 | 技术方案 | 理由 |
|------|----------|------|
| 主数据库 | PostgreSQL 16+（Supabase / Neon） | 成熟稳定，免费额度足够小团队，加密支持好 |
| 缓存 | Redis（Upstash 免费额度） | 天气缓存、会话管理 |
| 文件存储 | 对象存储（R2 / S3） | 导出数据包临时存储 |

#### 表结构设计

```sql
-- 用户表
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_uid     VARCHAR(256) NOT NULL UNIQUE,   -- Apple ID 唯一标识
    device_token  VARCHAR(512),                    -- APNs 推送令牌
    locale        VARCHAR(10) DEFAULT 'zh-CN',
    timezone      VARCHAR(50),
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    last_active   TIMESTAMPTZ,
    
    -- 端到端加密密钥公钥（用于验证，不存储私钥）
    public_key    TEXT
);

-- 用户偏好（端到端加密）
CREATE TABLE user_preferences (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 全部加密存储，服务端无法读取
    encrypted_data BYTEA NOT NULL,         -- AES-256-GCM 加密的偏好数据
    iv            BYTEA NOT NULL,          -- 初始化向量
    version       INT DEFAULT 1,           -- 数据版本，支持迁移
    updated_at    TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- 用户反馈（端到端加密）
CREATE TABLE user_feedback (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    encrypted_data BYTEA NOT NULL,         -- 加密的反馈内容
    iv            BYTEA NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 提醒同步（加密元数据 + 加密内容）
-- 仅存储需要跨设备同步的提醒（日历类、自填非敏感类）
CREATE TABLE synced_reminders (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 明文元数据（仅用于索引和调度）
    reminder_uuid UUID NOT NULL,           -- 与本地 UUID 对应
    category      VARCHAR(50) NOT NULL,    -- 分类（不含具体内容）
    due_date      TIMESTAMPTZ,             -- 到期时间（用于调度）
    is_completed  BOOLEAN DEFAULT FALSE,
    is_deleted    BOOLEAN DEFAULT FALSE,
    version       INT DEFAULT 1,
    
    -- 加密内容
    encrypted_title   BYTEA,              -- 加密的标题
    encrypted_notes   BYTEA,              -- 加密的备注
    iv                BYTEA NOT NULL,
    
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_user_due (user_id, due_date, is_completed, is_deleted)
);

-- 通知记录（用于行为分析，匿名化）
CREATE TABLE notification_logs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    notification_type VARCHAR(50),         -- 类型（不包含具体内容）
    action        VARCHAR(20) NOT NULL,    -- clicked / dismissed / snoozed
    latency_ms    INT,                     -- 从发送到操作的延迟
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    
    -- 90 天后自动删除
    -- 不记录通知具体内容
    INDEX idx_user_time (user_id, created_at)
);

-- 日历摘要（脱敏后，仅用于 AI 上下文）
CREATE TABLE calendar_summaries (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 仅存摘要，不存原始日历内容
    summary_type  VARCHAR(50) NOT NULL,    -- "有会议"、"有出行" 等
    time_range    TSTZRANGE NOT NULL,      -- 时间范围
    encrypted_detail BYTEA,               -- 加密的详细摘要（可选）
    iv            BYTEA,
    
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    
    -- 日程结束后 30 天自动清理
    INDEX idx_user_range (user_id, time_range)
);

-- 数据删除请求
CREATE TABLE deletion_requests (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scope         VARCHAR(50) NOT NULL,    -- 'all' / 'preferences' / 'reminders' 等
    status        VARCHAR(20) DEFAULT 'pending',  -- pending / processing / completed
    requested_at  TIMESTAMPTZ DEFAULT NOW(),
    completed_at  TIMESTAMPTZ
);
```

### 2.3 LLM 上下文数据设计

> **核心原则**：只给 LLM 决策所需的最少上下文，绝不发送原始敏感数据。

#### 发送给 LLM 的数据 ✅

| 数据 | 格式 | 示例 |
|------|------|------|
| 当前时间 | 文本 | "现在是 2026年5月6日 周三 下午2点" |
| 天气概况 | 文本 | "北京今天晴，最高28°C，明天有雨" |
| 日历摘要 | 脱敏文本 | "用户今天下午3点有会议，明天出差" |
| 待办提醒列表 | 脱敏文本 | "用户有3个待办：1个已过期、2个今天到期" |
| 近期行为模式 | 聚合数据 | "用户过去7天通知点击率35%，偏好晚上查看提醒" |
| 位置概况 | 模糊化 | "用户在北京"（精确坐标不发送） |

#### 绝不发送给 LLM 的数据 ❌

| 数据 | 原因 |
|------|------|
| Health 原始数据 | L4 级别，仅存本地 |
| 财务具体金额 | L4 级别，仅存本地 |
| 信用卡/银行卡号 | L4 级别 |
| GPS 精确坐标 | 仅发模糊化位置 |
| 日历原始内容 | 仅发脱敏摘要 |
| 用户真实姓名 | 用 "用户" 代指 |
| 用户联系方式 | 不采集 |
| 提醒的具体内容（非必要） | 仅在必要时发送类别和紧急程度 |

#### LLM Prompt 模板示例

```
你是一个智能提醒助手。基于以下上下文，判断是否需要向用户发送提醒。

当前时间：{datetime}
用户时区：{timezone}
天气概况：{weather_summary}
今日日历摘要：{calendar_summary}
待办概况：{task_summary}（注意：不要提及具体内容）
用户行为模式：{behavior_summary}

规则：
1. 只建议真正需要提醒的场景
2. 不要重复已发送的提醒
3. 尊重用户的安静时段
4. 返回 JSON 格式：{ should_remind: bool, reason: string, urgency: "low/medium/high" }
```

---

## 3. 存储架构

### 3.1 本地存储方案

```
┌─────────────────────────────────────────────────┐
│                iOS 本地存储架构                    │
├─────────────────────────────────────────────────┤
│                                                   │
│  SwiftData                                        │
│  ├── ReminderItem        提醒条目                 │
│  ├── FinanceEntry        财务数据（L4）           │
│  ├── Tag                 标签                     │
│  ├── UserPreference      用户偏好                 │
│  └── LocationCache       位置缓存（7天自动清理）  │
│                                                   │
│  Keychain                                          │
│  ├── E2E 私钥            端到端加密密钥           │
│  ├── Auth Token          Apple ID 认证令牌        │
│  └── APNs Key            推送相关密钥             │
│                                                   │
│  UserDefaults                                     │
│  ├── onboarding_complete  引导完成状态            │
│  ├── last_sync_time       上次同步时间            │
│  ├── notification_counts  通知计数（本地统计）    │
│  └── feature_flags        功能开关                │
│                                                   │
│  文件系统 (Documents/)                            │
│  ├── export/              导出数据临时存放         │
│  └── encrypted_prefs/     加密偏好备份            │
│                                                   │
│  HealthKit（系统安全域）                          │
│  └── 仅读写，不导入到 App 沙盒                    │
│                                                   │
└─────────────────────────────────────────────────┘
```

#### 存储选型决策

| 数据类型 | 存储方案 | 理由 |
|----------|----------|------|
| 结构化业务数据 | SwiftData | Apple 原生，自动 iCloud 同步（可选关闭），类型安全 |
| 加密密钥/认证令牌 | Keychain | 硬件级安全，App 卸载可配置保留 |
| 轻量配置/标志 | UserDefaults | 简单键值对，无需查询能力 |
| 导出数据包 | 文件系统 | 临时文件，导出后可删除 |
| Health 数据 | HealthKit 原生 | 不导入沙盒，利用系统安全域 |

### 3.2 服务端存储方案

#### 架构图

```
┌─────────────┐     ┌─────────────────────────────┐
│  iOS App    │────▶│     API Server (Cloudflare   │
│  (Client)   │     │     Workers / Vercel Edge)   │
└─────────────┘     └──────────┬──────────────────┘
                               │
                    ┌──────────┼──────────┐
                    ▼          ▼          ▼
              ┌──────────┐ ┌──────┐ ┌──────────┐
              │PostgreSQL│ │Redis │ │LLM API   │
              │(Neon)    │ │(Upst-│ │(OpenAI/  │
              │          │ │ash)  │ │ DeepSeek)│
              └──────────┘ └──────┘ └──────────┘
                    │
                    ▼
              ┌──────────┐
              │ Cloudflare R2│
              │ (导出文件)   │
              └──────────┘
```

#### 免费额度评估（小团队友好）

| 服务 | 免费额度 | 是否够用 |
|------|----------|----------|
| Neon PostgreSQL | 0.5 GB 存储，需注意冷启动 | ✅ 初期够用 |
| Upstash Redis | 10K 命令/天，256MB | ✅ 足够 |
| Cloudflare Workers | 10 万请求/天 | ✅ 足够 |
| Cloudflare R2 | 10 GB 存储，无出站费 | ✅ 导出文件足够 |

### 3.3 缓存策略

| 缓存对象 | 存储位置 | TTL | 淘汰策略 |
|----------|----------|-----|----------|
| 天气数据 | 服务端 Redis | 24 小时 | 自动过期，到期后重新拉取 |
| LLM 会话上下文 | 服务端 Redis | 1 小时 | 请求完成后清除 |
| 用户设备 Token | 服务端 DB | 跟随用户 | 用户登出时删除 |
| 位置数据 | 本地 SwiftData | 7 天 | 到期自动删除 |
| 日历摘要 | 本地 SwiftData | 事件结束后 30 天 | 定时任务清理 |
| 通知模板 | 本地内存 | App 会话期间 | App 退出即释放 |

---

## 4. 加密方案

### 4.1 传输加密

- **全链路 TLS 1.3**：所有客户端与服务端通信强制 HTTPS
- **证书固定 (Certificate Pinning)**：防止中间人攻击
  - 打包 App 内置服务端证书公钥指纹
  - 连接时校验，不匹配则拒绝连接
- **API 通信**：HTTPS + Bearer Token（JWT，15 分钟有效期）

### 4.2 存储加密

#### 本地加密

| 保护层 | 技术 | 说明 |
|--------|------|------|
| 文件系统级 | iOS Data Protection | 完整加密（设备锁定后） |
| 数据库级 | SwiftData 默认 + SQLCipher（可选） | 数据库文件加密 |
| 密钥存储 | Keychain (kSecAttrAccessible: .whenUnlockedThisDeviceOnly) | 设备锁定时不可访问 |
| 敏感字段 | AES-256-GCM | 财务数据、证件号等额外字段级加密 |

#### 服务端加密

| 保护层 | 技术 | 说明 |
|--------|------|------|
| 数据库级 | PostgreSQL TDE（Transparent Data Encryption） | 静态加密 |
| 字段级 | AES-256-GCM | 用户偏好、反馈、提醒内容 |
| 密钥管理 | 环境变量 + Cloudflare Secrets | 不硬编码，密钥与代码分离 |
| 备份加密 | 加密备份（R2 加密存储） | 导出数据包加密 |

### 4.3 端到端加密（E2EE）方案

> **适用范围**：用户偏好、用户反馈、自填提醒内容

#### 实现方案

```
用户设备                          服务端
┌──────────┐                    ┌──────────┐
│ 生成密钥对│                    │          │
│ 私钥 → Keychain              │          │
│ 公钥 → 上传至 users 表        │ 公钥存储 │
│          │                    │          │
│ 加密数据 │ ─── 加密blob ────▶ │ 存储密文 │
│          │   (服务端无法解密)  │          │
│          │                    │          │
│ 请求下载 │ ◀── 加密blob ───── │ 返回密文 │
│ 本地解密 │                    │          │
└──────────┘                    └──────────┘
```

#### 流程

1. **首次注册**：设备生成 RSA-4096 密钥对，私钥存 Keychain，公钥上传服务端
2. **上传数据**：用 AES-256 生成随机密钥加密数据，再用 RSA 公钥加密 AES 密钥，两者一起上传
3. **下载数据**：用 RSA 私钥解密 AES 密钥，再解密数据
4. **密钥轮换**：用户可在设置中手动触发密钥轮换（重新加密所有数据）

#### 不使用 E2EE 的数据

| 数据 | 原因 | 替代方案 |
|------|------|----------|
| 天气数据 | 无隐私敏感 | 服务端缓存，24h 清除 |
| 通知调度元数据 | 需要服务端处理 | 仅存类别和时间，不存内容 |
| 行为统计数据 | 匿名化后使用 | 聚合统计，不可逆匿名化 |

---

## 5. 隐私合规

### 5.1 中国《个人信息保护法》（PIPL）合规

#### 核心要求对照

| PIPL 要求 | 我们的措施 | 状态 |
|-----------|-----------|------|
| **告知同意** | 首次启动展示隐私政策，按数据类型分别授权 | ✅ |
| **最小必要** | 每类数据只采集实现功能所需的最少信息 | ✅ |
| **个人敏感信息** | Health/财务/位置作为敏感信息，单独授权 | ✅ |
| **数据本地化** | 核心敏感数据仅存本地，不上传 | ✅ |
| **用户删除权** | 一键删除全部或分类别删除 | ✅ |
| **用户导出权** | 一键导出所有数据为 JSON | ✅ |
| **撤回同意权** | 可随时在设置中关闭权限并删除对应数据 | ✅ |
| **数据安全** | 传输加密 + 存储加密 + 访问控制 | ✅ |
| **禁止第三方共享** | 不向任何第三方共享用户数据 | ✅ |
| **未成年人保护** | 注册时声明适用年龄（14+） | ✅ |

#### 敏感个人信息处理

```
敏感个人信息处理流程：

用户授权 → 明确告知目的 → 最小范围采集 → 加密存储 → 用户可随时撤回
    │                                                        │
    └── 每个敏感类别单独弹窗授权，不捆绑
```

### 5.2 iOS App Store 隐私合规

| 隐私标签 | 数据类型 | 是否关联用户 | 使用目的 |
---------|---------|------------|----------|
| 定位 | 精确位置 | 否 | 天气服务、位置提醒 |
| 日历事件 | 日历 | 是 | 日程关联提醒 |
| 健康与健身 | 步数/睡眠 | 是 | 运动/睡眠提醒 |
| 财务信息 | 无 | — | 财务数据仅存本地 |
| 使用数据 | 产品交互 | 是 | 推送质量优化 |
| 诊断数据 | 崩溃日志 | 否 | Bug 修复 |

### 5.3 隐私政策要点

1. **数据控制器**：明确说明开发者主体信息
2. **数据收集清单**：列出每类数据、用途、存储时长
3. **第三方服务**：列出天气 API、推送服务、分析服务（如有）
4. **用户权利**：查看、修改、删除、导出、撤回同意
5. **未成年人条款**：14 岁以下不得使用
6. **联系方式**：开发者邮箱，承诺 48 小时内响应
7. **政策更新**：重大变更通过 App 内通知告知

---

## 6. 数据生命周期

### 6.1 数据采集边界

| 数据 | 采集方式 | 最小必要范围 |
------|---------|-------------|
| 时间/日期 | 系统获取（零权限） | 当前时间、时区 |
| 天气 | 后端调用 API（用户无感） | 城市、温度、天气状况、降水概率 |
| 日历事件 | EventKit 读取 | 事件标题、时间、位置（不读取备注/附件） |
| Health | HealthKit 读取 | 仅用户授权类别（如步数、睡眠时长） |
| 位置 | CoreLocation（需授权） | 城市级精度，不收集精确定位轨迹 |
| 反馈行为 | 前端埋点 | 操作类型（点赞/忽略/关闭）、时间戳 |
| 自填数据 | 用户主动输入 | 用户输入的原始内容 |

### 6.2 数据保留策略

| 数据 | 保留时长 | 到期处理 |
------|---------|----------|
| 提醒记录 | 90 天 | 自动删除，可导出备份 |
| 用户偏好 | 跟随用户 | 账号删除时同步删除 |
| 行为日志 | 30 天 | 自动聚合后删除原始日志 |
| 天气缓存 | 24 小时 | 自动过期 |
| 日历摘要 | 事件结束后 30 天 | 自动清理 |
| 位置缓存 | 7 天 | 自动清理 |
| 导出文件 | 48 小时 | 服务端自动清理 |

### 6.3 数据删除流程

```
用户触发删除（设置→删除数据）
    ├─ 本地：删除 SwiftData 所有记录 + 清除 Keychain
    ├─ 服务端：标记用户数据为「待删除」
    ├─ 异步任务：30 分钟内完成物理删除
    ├─ 通知 APNs 注销 device token
    └─ 返回确认
```

---

## 7. 安全措施

### 7.1 认证与授权

| 机制 | 方案 |
------|------|
| 用户认证 | Apple Sign In（无密码） |
| Token | JWT，15 分钟有效期，refresh token 7 天 |
| API 鉴权 | Bearer Token + 请求签名 |
| 权限控制 | 设备级（同一 Apple ID 可多设备） |

### 7.2 API 安全

- 速率限制：100 请求/分钟/设备
- 请求签名：时间戳 + HMAC
- 输入校验：所有参数白名单校验
- SQL 注入防护：参数化查询（Prisma/Drizzle ORM）
- XSS 防护：API 纯 JSON，无 HTML 渲染

### 7.3 防数据泄露

- 敏感字段数据库层加密
- 日志脱敏：用户 ID、手机号、位置信息哈希处理
- 错误响应不泄露内部信息（统一返回模糊错误码）
- 服务器防火墙：仅开放 443 端口

### 7.4 日志脱敏规则

| 字段 | 处理方式 |
------|--------|
| 用户 ID | 仅保留前 4 位：`usr_a1b2...` |
| 设备 Token | 完全脱敏：`***` |
| 位置 | 仅保留城市名 |
| 日历事件标题 | 替换为 `[CALENDAR_EVENT]` |
| 提醒文案 | 保留前 10 字：`今天下午有雨...` |

---

## 8. 用户控制

### 8.1 一键导出

```swift
func exportAllData() -> Data {
    let reminders = try? SwiftDataManager.shared.getAllReminders()
    let preferences = try? SwiftDataManager.shared.getUserPreferences()
    let healthStats = HealthService.shared.getExportableStats()
    
    let export = ExportBundle(
        exportedAt: ISO8601DateFormatter().string(from: Date()),
        reminders: reminders.map { $0.toDictionary() },
        preferences: preferences?.toDictionary(),
        healthStats: healthStats
    )
    return JSONEncoder().encode(export)
}
```

输出格式：JSON，可导入其他工具或存档。

### 8.2 一键删除

- 设置页 → 关于 → 删除所有数据
- 二次确认（输入"删除"确认）
- 执行后本地+服务端同步删除
- 不可撤销（删除前弹窗提醒导出）

### 8.3 分类别控制

| 类别 | 可独立删除 |
------|-----------|
| 提醒历史 | ✅ |
| 反馈记录 | ✅ |
| 日历缓存 | ✅ |
| 位置缓存 | ✅ |
| Health 数据 | ✅（同时请求 HealthKit 授权删除） |
| 账号 | ✅（全部删除） |

### 8.4 数据可携性

- 导出格式：JSON（结构化，可直接导入其他工具）
- 导出范围：所有本地数据（提醒记录、偏好、自填数据）
- 不导出：系统级数据（HealthKit 数据需通过 Apple Health 导出）
- 导出方式：App 内设置 → 导出数据 → 分享到 Files / AirDrop / 邮件

---

## 9. 审计与监控

### 9.1 数据访问日志

| 日志项 | 记录内容 | 保留时长 |
--------|---------|----------|
| API 调用 | 用户 ID（脱敏）、端点、时间、状态码 | 30 天 |
| 数据查询 | 查询类型、返回记录数（不记录内容） | 30 天 |
| 数据修改 | 修改类型、前后 diff（脱敏） | 90 天 |
| 数据删除 | 删除类型、影响范围 | 90 天 |
| 权限变更 | 权限类型、变更时间 | 90 天 |

### 9.2 异常检测

| 异常类型 | 检测方式 | 响应 |
---------|---------|--------|
| 异常高频请求 | 同一设备 1 分钟 > 100 次 | 自动限流 + 告警 |
| 异常数据访问 | 非用户常用 IP/设备 | 发送安全确认通知 |
| 大规模数据导出 | 单次导出 > 1000 条记录 | 需二次确认 |
| Token 异常 | 过期 refresh token 被使用 | 强制重新登录 |

### 9.3 合规审计

- 每季度自查：检查数据保留策略是否执行
- 每年审计：检查隐私政策与实际数据处理是否一致
- 重大变更审计：功能上线前评估隐私影响（PIA）

---

*文档版本 v1.0 | 2026-05-06*