# LLM 决策引擎设计文档

> **版本**: v1.0  
> **日期**: 2026-05-06  
> **作者**: AI 产品架构师  
> **适用团队**: 1-2 人  
> **状态**: 设计稿

---

## 目录

1. [引擎总览](#1-引擎总览)
2. [决策流程](#2-决策流程)
3. [LLM 使用策略](#3-llm-使用策略)
4. [规则引擎设计](#4-规则引擎设计)
5. [上下文管理](#5-上下文管理)
6. [推送调度](#6-推送调度)
7. [兜底策略](#7-兜底策略)
8. [评估与优化](#8-评估与优化)

---

## 1. 引擎总览

### 1.1 核心问题

> **什么时候、给谁、推什么。**

将这个决策分解为两个层面：

| 层面 | 问题 | 谁负责 |
|------|------|--------|
| **推什么** | 从 120+ 场景中选出最相关的 | 规则引擎（候选过滤）+ LLM（排序 + 文案生成） |
| **什么时候** | 推送时机、频率、间隔 | 规则引擎（频率控制 + 时间窗口） |
| **推什么话** | 提醒文案的措辞和温度 | LLM（文案生成） |

### 1.2 LLM 与规则引擎的职责边界

```
┌─────────────────────────────────────────────────────────┐
│                     推送决策流水线                        │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │ 规则引擎  │──▶│   LLM    │──▶│ 规则引擎  │──▶ 推送    │
│  │ (上游)    │   │ (核心)    │   │ (下游)    │            │
│  └──────────┘   └──────────┘   └──────────┘            │
│                                                         │
│  上下文采集      排序+文案生成    频率控制+去重            │
│  场景触发                       时间窗口                 │
│  候选过滤                       冷启动限流                │
│  权重初筛                       兜底拦截                 │
└─────────────────────────────────────────────────────────┘
```

**原则：规则引擎兜底一切，LLM 只做它擅长的事。**

| 能力 | 规则引擎 | LLM | 理由 |
|------|:--------:|:---:|------|
| 场景触发（时间/天气/事件） | ✅ | ❌ | 规则精确、零延迟、零成本 |
| 权重计算 | ✅ | ❌ | 确定性逻辑不需要生成 |
| 频率控制 / 冷启动限流 | ✅ | ❌ | 硬约束，不允许概率偏差 |
| 候选排序（多因子综合） | 半 ✅ | ✅ | 多因子加权可规则化，但 LLM 能捕捉微妙关联 |
| 文案生成 | ❌ | ✅ | 核心优势：个性化、温度感、上下文衔接 |
| 去重 / 相似检测 | ✅ | 辅助 | 规则做精确去重，LLM 辅助语义去重 |
| 惊喜推送选题 | 半 ✅ | ✅ | 规则圈定候选池，LLM 选最有惊喜感的 |

### 1.3 为什么不全用规则？

规则引擎能处理 80% 的场景，但：

1. **文案温度**：120+ 场景 × 每场景多套模板 = 维护灾难，且模板语气生硬
2. **上下文融合**：用户刚跑步完 + 天气转凉 → "跑完别急着吹空调"，这种组合规则写不出来
3. **惊喜选题**：需要"创造性"地关联用户兴趣与当下情境
4. **长尾个性化**：1万用户有1万种生活节奏，不可能穷举规则

### 1.4 为什么不全用 LLM？

1. **成本**：全链路 LLM 调用 ≈ 每天 10-20 元/千用户
2. **延迟**：LLM 响应 500ms-2s，批量推送不可接受
3. **确定性**：频率控制、冷启动等硬约束不能有概率偏差
4. **可靠性**：LLM 不可用时整个系统不能停摆

---

## 2. 决策流程

### 2.1 完整流程图

```
                    用户上下文
                        │
                        ▼
              ┌─────────────────┐
              │  1. 上下文采集    │  规则引擎
              │  - 时间/日期/时段  │
              │  - 天气/地理位置   │
              │  - 用户行为事件    │
              │  - 用户画像       │
              │  - 历史推送记录    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  2. 候选生成      │  规则引擎
              │  - 120+ 场景匹配  │
              │  - 权重初筛(>0.1) │
              │  - 输出 20-40 候选│
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  3. 优先级排序    │  LLM（核心调用）
              │  - 多因子综合排序  │
              │  - 选出 Top 12    │
              │  - 标记惊喜候选    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  4. 文案生成      │  LLM
              │  - 个性化措辞     │
              │  - 温度控制       │
              │  - 结论先行格式    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  5. 去重          │  规则引擎 + LLM辅助
              │  - 同类合并       │
              │  - 近期重复过滤   │
              │  - 语义相似检测   │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  6. 频率控制      │  规则引擎
              │  - 日限额(8条)    │
              │  - 冷启动递增     │
              │  - 时段限流       │
              │  - 间隔最小 30min │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  7. 最终输出      │  推送队列
              │  - 推送时间安排    │
              │  - 优先级队列     │
              │  - 写入推送表     │
              └─────────────────┘
```

### 2.2 每步详细说明

#### Step 1: 上下文采集

每次决策前采集以下信息，组装成结构化上下文对象：

```json
{
  "timestamp": "2026-05-06T14:30:00+08:00",
  "timeContext": {
    "hour": 14,
    "period": "afternoon",
    "dayOfWeek": "tuesday",
    "dayOfYear": 126,
    "isWeekend": false,
    "isHoliday": false,
    "holidayName": null
  },
  "weather": {
    "temp": 22,
    "condition": "sunny",
    "humidity": 45,
    "aqi": 65,
    "uv": 6,
    "tempDiff": "+3"  // 较昨日
  },
  "location": {
    "city": "上海",
    "gps": [31.23, 121.47]
  },
  "userProfile": {
    "daysSinceSignup": 45,
    "lifestyleTags": ["上班族", "有猫", "关注健康"],
    "sleepPattern": "night_owl",
    "exerciseFreq": "3-4次/周"
  },
  "recentEvents": [
    { "type": "app_open", "time": "08:20" },
    { "type": "exercise_logged", "time": "07:00", "detail": "跑步5km" },
    { "type": "push_dismissed", "time": "yesterday_19:00", "category": "water" }
  ],
  "recentPushes": [
    { "time": "today_08:00", "category": "morning", "title": "..." },
    { "time": "today_12:30", "category": "lunch", "title": "..." }
  ]
}
```

#### Step 2: 候选生成（规则引擎）

120+ 场景按触发条件匹配，产出候选列表：

| 场景大类 | 示例场景 | 触发条件 | 基础权重 |
|---------|---------|---------|---------|
| 健康饮水 | 该喝水了 | 距上次喝水提醒 ≥ 2h | 0.6 |
| 天气提醒 | 带伞出门 | 降水概率 > 60%，且未来2h外出 | 0.8 |
| 运动鼓励 | 该运动了 | 今日无运动记录，运动日 | 0.5 |
| 用眼休息 | 休息一下眼睛 | 连续使用手机 > 40min | 0.7 |
| ... | ... | ... | ... |

**初筛规则**：
- 用户权重 > 0.10（否则该类暂停）
- 场景冷却期已过（同一场景最短间隔，如饮水 2h）
- 时间窗口匹配（如"睡前提醒"只在 21:00-23:00 匹配）
- 输出 20-40 个候选

#### Step 3: 优先级排序（LLM 核心）

LLM 接收候选列表 + 上下文，综合排序：

**输入**：上下文 JSON + 候选列表（每条含场景名、基础权重、触发原因）

**输出**：排序后的列表，每条含：
- `finalScore`：0-100 的综合评分
- `reason`：一句话排序理由（用于调试和日志）
- `isSurprise`：是否为惊喜推送候选

#### Step 4: 文案生成（LLM）

对 Top 12 生成个性化文案。

**输入**：场景详情 + 用户画像 + 近期推送记录（避免重复措辞）

**输出**：
```json
{
  "title": "今天气温比昨天高了3度",
  "body": "出门注意防晒，涂个防晒霜再走~",
  "actionText": "查看紫外线指数",
  "tone": "warm"
}
```

#### Step 5: 去重

**规则去重**：
- 同大类去重：Top 12 中同一大类最多 2 条
- 近期过滤：过去 48h 推送过的相同场景直接移除
- 关键词去重：title 相似度 > 70% 的合并

**LLM 辅助去重**（仅在规则去重后仍有 ≥ 2 条时触发）：
- 将剩余候选两两比较，标记语义重复
- 保留权重更高的

#### Step 6: 频率控制

```python
def frequency_control(user, candidates, now):
    max_daily = get_cold_start_limit(user)  # Day1-3: 3, Day4-7: 5, Day8+: 8
    pushed_today = count_today_pushes(user)
    remaining = max_daily - pushed_today
    
    if remaining <= 0:
        return []
    
    # 时段限流
    hour = now.hour
    if hour in [0, 1, 2, 3, 4, 5]:
        return []  # 凌晨不推
    
    # 时段配额
    slot = get_time_slot(hour)
    slot_limit = get_slot_limit(slot)  # 早晨2条, 上午2条, 下午2条, 晚上2条
    slot_used = count_slot_pushes(user, slot)
    
    available = min(remaining, slot_limit - slot_used)
    
    # 确保间隔 ≥ 30min
    last_push_time = get_last_push_time(user)
    if (now - last_push_time) < timedelta(minutes=30):
        return []
    
    # 惊喜配额：每10条中1-2条
    surprise_quota = max(1, remaining // 10)
    normal_quota = available - surprise_quota
    
    return select_final_pushes(candidates, normal_quota, surprise_quota)
```

#### Step 7: 最终输出

写入推送队列表：

```sql
INSERT INTO push_queue (user_id, category, title, body, action_text, 
                         scheduled_at, priority, is_surprise, created_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
```

---

## 3. LLM 使用策略

### 3.1 模型选型

| 用途 | 推荐模型 | 理由 | 备选 |
|------|---------|------|------|
| 优先级排序 | DeepSeek-V3 / Qwen-Plus | 推理强，中文好，价格低 | GLM-4-Flash（更便宜） |
| 文案生成 | DeepSeek-V3 / Qwen-Plus | 中文表达自然，成本低 | 通义千问-Turbo |
| 语义去重 | BGE-M3 Embedding | 专用向量模型，成本低 | text2vec-chinese |
| 惊喜选题 | Qwen-Plus | 创造性稍强 | DeepSeek-V3 |

**选型原则**：
- 不用 GPT-4o 级别模型，成本过高
- 排序和文案可以用同一模型，减少接入复杂度
- Embedding 用本地部署或极低价 API，避免主模型成本

### 3.2 调用架构

```
每用户每日 LLM 调用（批量模式）:

┌─────────────┐     ┌──────────────┐
│  定时任务     │────▶│  批量采集上下文  │
│  (每小时)     │     │  (并行)       │
└─────────────┘     └──────┬───────┘
                           │
                    用户列表 (分片)
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         ┌─────────┐ ┌─────────┐ ┌─────────┐
         │ Batch 1 │ │ Batch 2 │ │ Batch 3 │  每批 50-100 用户
         │ 50 users│ │ 50 users│ │ 50 users│
         └────┬────┘ └────┬────┘ └────┬────┘
              │           │           │
              ▼           ▼           ▼
         ┌─────────────────────────────┐
         │     合并 Prompt (批量请求)    │
         │  或 并发单独请求 (rate limit) │
         └──────────────┬──────────────┘
                        │
                        ▼
                   ┌─────────┐
                   │  LLM API │
                   └────┬────┘
                        │
                        ▼
                   ┌─────────┐
                   │  解析结果  │
                   │  写入队列  │
                   └─────────┘
```

### 3.3 Prompt 模板（5 个核心示例）

#### Prompt 1: 优先级排序

```markdown
你是一个智能提醒助手，负责从候选提醒中选出最适合当前用户的推送。

## 用户信息
{userProfile}

## 当前上下文
时间: {timestamp}
天气: {weather}
近期事件: {recentEvents}
今日已推送: {todayPushes} (共 {todayCount}/8 条)

## 候选提醒 (共 {candidateCount} 条)
{candidates}

## 任务
请根据以下维度综合评分，选出 Top 12：
1. **时效性** (30%): 此时此刻的紧急程度
2. **相关性** (30%): 与用户画像/生活节奏的匹配度
3. **多样性** (20%): 与今日已推送内容的互补性
4. **惊喜感** (20%): 能否给用户带来新的有价值信息

## 输出格式
返回 JSON 数组，每项包含：
- index: 候选编号
- score: 0-100 综合评分
- reason: 一句话排序理由
- isSurprise: boolean (是否为惊喜推送候选，最多 2 条)

仅返回 JSON，不要其他内容。
```

#### Prompt 2: 文案生成（日常提醒）

```markdown
你是一个关心用户生活的好朋友，请生成一条提醒文案。

## 规则
1. 结论先行：第一句话就说清楚要做什么
2. 像朋友说话：自然、温暖、不生硬
3. 简短有力：title ≤ 20字，body ≤ 50字
4. 不要用感叹号堆砌，一句话最多一个
5. 不要说教，不要用"建议你""你应该"
6. 根据上下文加入个性化细节

## 场景
{scenario}

## 用户画像
{userProfile}

## 当前上下文
{context}

## 近期推送（避免重复）
{recentPushTitles}

## 输出格式
JSON:
{
  "title": "标题",
  "body": "正文",
  "actionText": "按钮文案（可选）"
}
```

#### Prompt 3: 惊喜推送选题

```markdown
你是一个擅长发现生活趣味的助手。请为用户推荐一条意想不到但有用的提醒。

## 用户画像
{userProfile}

## 当前情境
{context}

## 用户近期关注 / 兴趣标签
{interests}

## 已推送过的惊喜主题（避免重复）
{pastSurpriseTopics}

## 任务
推荐 3 个惊喜推送选题，要求：
1. 与当前情境有关联但不是直接触发
2. 能给用户带来"诶，这个没想到"的感觉
3. 实用但不无聊
4. 不能是常见提醒的变体

## 输出格式
JSON 数组，每项：
{
  "topic": "选题名",
  "hook": "一句话吸引点",
  "relevance": "为什么现在推这个",
  "category": "归属场景大类"
}
```

#### Prompt 4: 小纸条生成（每周）

```markdown
你是一个细腻的朋友，偶尔会写一张小纸条给用户。

## 用户画像
{userProfile}

## 本周回顾
{weeklySummary}

## 任务
写一张温暖的小纸条，要求：
1. 像手写便条一样自然，可以有涂改感（用～或...）
2. 提到一件本周发生的小事（真实感）
3. 传递一种"我注意到了"的感觉，而不是说教
4. 50-100字
5. 不定期发送（不是每周都有），这张是否发送由规则决定

## 输出格式
JSON:
{
  "send": true/false (这次是否值得发),
  "content": "小纸条内容",
  "reason": "为什么选择发/不发"
}
```

#### Prompt 5: 语义去重检测

```markdown
判断以下推送文案是否语义重复。

## 规则
- 核心意思相同 = 重复，即使措辞不同
- 同一场景的不同角度 = 不重复
- "多喝水" 和 "起来活动一下" = 不重复
- "该喝水了" 和 "补充点水分" = 重复

## 待比较文案
A: "{titleA}" - "{bodyA}"
B: "{titleB}" - "{bodyB}"

## 输出
JSON:
{
  "isDuplicate": true/false,
  "confidence": 0.0-1.0,
  "reason": "判断理由"
}
```

### 3.4 Token 成本估算

#### 单用户每日 Token 消耗

| 调用 | 次数/天 | Input Token | Output Token | 模型 | 单价 (元/百万token) |
|------|---------|-------------|--------------|------|-------------------|
| 优先级排序 | 4次（每小时批量） | 800×4=3,200 | 500×4=2,000 | Qwen-Plus | 4/1 |
| 文案生成 | 8条 | 600×8=4,800 | 100×8=800 | Qwen-Plus | 4/1 |
| 惊喜选题 | 0.5次 | 500 | 300 | Qwen-Plus | 4/1 |
| 语义去重 | 2次 | 200×2=400 | 50×2=100 | Qwen-Plus | 4/1 |
| 小纸条 | 0.15次/周 | 500 | 150 | Qwen-Plus | 4/1 |

**单用户日均值**：
- Input: ~8,900 tokens/天
- Output: ~3,250 tokens/天
- 成本: (8,900 × 4 + 3,250 × 1) / 1,000,000 ≈ **0.039 元/天/用户**

#### 1 万用户规模

| 项目 | 数值 |
|------|------|
| 日总 Input Token | 8,900 × 10,000 = 8,900万 |
| 日总 Output Token | 3,250 × 10,000 = 3,250万 |
| 日均成本 | (8,900×4 + 3,250×1)/100 ≈ **389 元** |
| 月均成本 | 389 × 30 ≈ **11,670 元** |

> **⚠️ 注意**：这个估算偏高，因为实际场景中：
> - 不是所有用户每天都被推送（活跃用户可能只占 30-50%）
> - 冷启动用户推送更少
> - 可通过合并 Prompt（多用户打包一次调用）进一步降低
>
> **实际预估：日均 < 200 元（1万活跃用户），目标 < 50 元需优化。**

#### 成本优化策略（目标日均 < 50 元）

| 策略 | 节省幅度 | 实现难度 |
|------|---------|---------|
| 多用户打包（10用户一次调用） | ~40% | 中 |
| 排序用 Flash 模型（Qwen-Turbo） | ~50%（排序部分） | 低 |
| 缓存相似用户上下文 | ~20% | 中 |
| 降低排序频率（2h 一次） | ~50%（排序部分） | 低 |
| 本地 Embedding 替代 LLM 去重 | ~10% | 低 |
| **组合使用** | **~70%** | 中 |

**优化后估算**：389 × 0.3 ≈ **117 元/天**，仍有优化空间。

**进一步压缩到 50 元/天的方案**：
1. 排序降级为纯规则（多因子加权公式），仅在"惊喜选题"和"文案生成"调用 LLM
2. 文案生成使用更便宜的模型（Qwen-Turbo，单价 2/0.5）
3. 缓存 + 模板复用：相似场景复用文案模板，仅替换个性化变量

**纯文案生成 + 惊喜模式**：
- 文案：8条 × 600 input + 100 output = 5,600 tokens/天/活跃用户
- 惊喜：0.5次 × 500 + 300 = 400 tokens
- 合计：~6,000 tokens/天/活跃用户
- 按活跃用户 5,000 人：6,000 × 5,000 = 3,000万 tokens
- 成本：(3,000×4 + 500×1)/100 ≈ **125 元/天**

**结论**：日均 50 元目标在 1 万用户规模下，需要规则引擎承担大部分排序工作，LLM 仅负责文案生成和惊喜选题，并使用 Qwen-Turbo 级别模型。具体可达成的用户规模约 **2,000-3,000 活跃用户**。

> **务实的建议**：产品初期（< 1 万用户）优先用 Qwen-Plus 保证体验，月成本 1.2 万以内可接受。规模增长后逐步引入成本优化。

### 3.5 响应延迟

| 调用类型 | 预期延迟 | 是否可接受 | 优化方案 |
|---------|---------|:----------:|---------|
| 优先级排序 | 1-3s | ✅ | 异步批量，用户无感 |
| 文案生成 | 0.5-1.5s | ✅ | 预生成 + 缓存 |
| 惊喜选题 | 2-4s | ✅ | 每日生成一次 |
| 语义去重 | 0.3-0.8s | ✅ | 批量比较 |

**整体决策延迟**：从触发到推送入队 < 10s（批量模式），用户完全无感。

**缓存策略**：
- 文案缓存：同一场景 + 同一天气/时段 → 复用（TTL 2h）
- 排序结果缓存：用户上下文变化不大时复用（TTL 30min）
- Embedding 缓存：文案向量永久缓存，用于去重

---

## 4. 规则引擎设计

### 4.1 架构

规则引擎是整个系统的骨架，分为三层：

```
┌─────────────────────────────────────────┐
│              规则引擎三层架构              │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  第一层：触发规则 (Trigger)       │    │
│  │  - 什么条件下产生候选             │    │
│  │  - 纯条件判断，零 AI 参与         │    │
│  └──────────────┬──────────────────┘    │
│                 │                        │
│  ┌──────────────▼──────────────────┐    │
│  │  第二层：评分规则 (Scoring)       │    │
│  │  - 多因子加权计算基础分           │    │
│  │  - 确定性公式，可调试可回溯        │    │
│  └──────────────┬──────────────────┘    │
│                 │                        │
│  ┌──────────────▼──────────────────┐    │
│  │  第三层：控制规则 (Control)       │    │
│  │  - 频率、冷启动、时段、间隔        │    │
│  │  - 硬约束，任何情况不可违反        │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 4.2 场景触发规则

每个场景定义为一组触发条件，全部满足才激活：

```yaml
# 示例：天气提醒 - 带伞出门
- id: weather_umbrella
  category: 天气提醒
  name: 带伞出门
  triggers:
    - type: weather
      field: precipitation_prob
      op: gt
      value: 0.6
      window: 2h  # 未来2小时内
    - type: time
      field: period
      op: in
      value: [morning, afternoon]  # 只在上午和下午提醒
    - type: user_state
      field: is_outdoor_likely
      op: eq
      value: true  # 用户可能外出（工作日白天）
  cooldown: 4h  # 同一场景最短触发间隔
  base_weight: 0.8
```

```yaml
# 示例：健康饮水提醒
- id: health_water
  category: 健康饮水
  name: 该喝水了
  triggers:
    - type: interval
      field: last_push_same_category
      op: gt
      value: 2h
    - type: time
      field: hour
      op: in
      value: [9, 10, 11, 14, 15, 16, 19, 20]  # 工作时段
    - type: user_state
      field: days_since_signup
      op: gte
      value: 3  # 冷启动期间不推此类
  cooldown: 2h
  base_weight: 0.5
```

**触发条件类型汇总**：

| 类型 | 字段 | 操作 | 示例 |
|------|------|------|------|
| time | hour, period, dayOfWeek | eq, in, between | 9-11点 |
| weather | temp, condition, aqi, uv, precipitation_prob | gt, lt, eq, between | 温度 < 5°C |
| interval | last_push_same, last_push_category, last_app_open | gt, lt | 距上次同类 > 2h |
| user_state | days_since_signup, is_weekend, location_type | eq, neq, gte | 注册 > 7天 |
| event | exercise_logged, sleep_recorded, flight_booked | exists, not_exists | 今日有运动 |
| composite | AND / OR 组合 | - | 天气冷 AND 外出 |

### 4.3 权重计算

#### 基础权重 → 动态权重

```
dynamicWeight = baseWeight × timeMultiplier × recencyMultiplier × diversityMultiplier
```

**时间乘数**：
```python
def time_multiplier(scenario, now):
    """场景与当前时间的匹配程度"""
    # 完美时段 = 1.2，合适时段 = 1.0，边缘时段 = 0.6，不合适 = 0.3
    if now.hour in scenario.peak_hours:
        return 1.2
    elif now.hour in scenario.ok_hours:
        return 1.0
    elif now.hour in scenario.edge_hours:
        return 0.6
    return 0.3
```

**新鲜度乘数**：
```python
def recency_multiplier(scenario, user):
    """距离上次推送同类场景越久，权重越高"""
    days_since_last = (now - user.last_push_time(scenario.category)).days
    if days_since_last >= 7:
        return 1.5   # 很久没推，提升
    elif days_since_last >= 3:
        return 1.2
    elif days_since_last >= 1:
        return 1.0
    else:
        return 0.5   # 今天推过，大幅降低
```

**多样性乘数**：
```python
def diversity_multiplier(scenario, today_pushes):
    """今日已推送同类越多，权重越低"""
    same_category_today = count_same_category(today_pushes, scenario.category)
    if same_category_today == 0:
        return 1.3   # 今日尚未推送此类，提升
    elif same_category_today == 1:
        return 1.0
    else:
        return 0.3   # 已有2条以上，几乎不再推
```

#### 规则评分公式（替代 LLM 排序的轻量方案）

```python
def rule_score(candidate, context):
    """纯规则评分，0-100"""
    score = 0
    
    # 时效性 (35%)
    score += urgency_score(candidate, context) * 0.35
    
    # 用户匹配度 (30%)
    score += profile_match_score(candidate, context.user_profile) * 0.30
    
    # 新鲜度 (20%)
    score += recency_score(candidate, context.recent_pushes) * 0.20
    
    # 多样性 (15%)
    score += diversity_score(candidate, context.today_pushes) * 0.15
    
    return round(score, 1)
```

### 4.4 频率控制

#### 冷启动策略

```
Day 1-3:   ≤ 3 条/天     只推最高权重的，建立信任
Day 4-7:   ≤ 5 条/天     逐步增加，观察用户反馈
Day 8-14:  ≤ 7 条/天     接近正常
Day 15+:   ≤ 8 条/天     正常上限
```

**冷启动期间的推送选择**：
- 只选 baseWeight ≥ 0.7 的场景
- 不推惊喜推送（避免不可控影响第一印象）
- 不推小纸条（还没积累足够上下文）

#### 时段配额

| 时段 | 时间 | 配额 | 说明 |
|------|------|------|------|
| 晨间 | 7:00 - 9:00 | 2条 | 起床、早餐、通勤 |
| 上午 | 9:00 - 12:00 | 2条 | 工作间隙 |
| 午后 | 12:00 - 14:00 | 1条 | 午休 |
| 下午 | 14:00 - 18:00 | 1条 | 下午茶、运动 |
| 晚间 | 18:00 - 22:00 | 2条 | 晚餐、休闲 |
| 深夜 | 22:00 - 7:00 | 0条 | 不推送 |

#### 间隔控制

```python
MIN_INTERVAL = timedelta(minutes=30)  # 两条推送最短间隔

def can_push_now(user, now):
    last = get_last_push_time(user)
    if last is None:
        return True
    return (now - last) >= MIN_INTERVAL
```

#### 惊喜配额

```
每 10 条推送中，1-2 条为惊喜推送
即：正常 8-9 条，惊喜 1-2 条
惊喜推送不影响总配额（8条/天的上限已包含惊喜）
```

### 4.5 规则与 LLM 协作

#### 两种运行模式

| 模式 | 排序 | 文案 | 适用场景 |
|------|------|------|---------|
| **规则优先** | 规则评分 | LLM 生成 | 日常运行，节省成本 |
| **LLM 优先** | LLM 排序 | LLM 生成 | 新用户前 7 天，保证体验 |

#### 降级策略

```python
def decide_mode(user, llm_available):
    # LLM 不可用 → 纯规则 + 模板
    if not llm_available:
        return "rule_only"
    
    # 新用户 → LLM 优先（建立信任）
    if user.days_since_signup <= 7:
        return "llm_priority"
    
    # 老用户，按比例分流
    if random.random() < 0.3:  # 30% 用 LLM 排序
        return "llm_priority"
    else:
        return "rule_priority"
```

#### 数据流

```
规则引擎(触发+初筛) 
    → 候选列表 (20-40条)
    → [LLM排序] 或 [规则评分]
    → Top 12
    → [LLM文案生成] 或 [模板填充]
    → [LLM去重] 或 [规则去重]
    → 规则引擎(频率控制)
    → 最终推送队列
```

**关键原则**：LLM 可以"建议"，但规则引擎有"否决权"。任何 LLM 输出都要经过规则引擎的最后一道检查。

---

## 5. 上下文管理

### 5.1 用户画像构建

```json
{
  "userId": "u_12345",
  
  // 静态画像（注册时收集 + 后续推断）
  "profile": {
    "ageGroup": "25-30",
    "gender": "male",
    "city": "上海",
    "occupation": "互联网",
    "lifestyle": ["上班族", "有猫", "关注健康"],
    "sleepPattern": "night_owl",  // 猫头鹰型/早起型
    "exerciseFrequency": "3-4次/周",
    "dietPreference": null,
    "commuteType": "subway"
  },
  
  // 动态画像（持续更新）
  "dynamic": {
    "activeHours": [8, 9, 10, 12, 14, 19, 20, 21],
    "preferredCategories": ["天气", "健康", "运动"],
    "ignoredCategories": ["理财"],
    "avgResponseRate": 0.35,
    "avgResponseDelay": "15min"
  },
  
  // 权重（每大类一个）
  "categoryWeights": {
    "健康饮水": 0.7,
    "天气提醒": 0.9,
    "运动鼓励": 0.6,
    "用眼休息": 0.3,
    "...": "..."
  },
  
  // 版本
  "profileVersion": 3,
  "lastUpdated": "2026-05-06T08:00:00"
}
```

**画像更新机制**：

| 数据源 | 更新频率 | 更新内容 |
|--------|---------|---------|
| 用户行为（点击/忽略/关闭） | 实时 | categoryWeights、preferredCategories |
| 主动设置 | 实时 | profile 静态字段 |
| 模型推断 | 每日一次 | sleepPattern、activeHours |
| 累计统计 | 每周一次 | avgResponseRate、exerciseFrequency |

### 5.2 短期上下文（Session Context）

每次 LLM 调用时组装的即时上下文：

```json
{
  // 时间上下文
  "now": "2026-05-06T14:30:00+08:00",
  "timeOfDay": "afternoon",
  "dayContext": "工作日",
  
  // 环境上下文
  "weather": {
    "temp": 22, "condition": "sunny", "aqi": 65,
    "change": "气温较昨日升高3度"
  },
  
  // 行为上下文（最近24h）
  "recentActions": [
    "07:00 跑步5km",
    "08:20 打开App",
    "12:30 收到午餐提醒（已点击查看）"
  ],
  
  // 推送上下文
  "todayPushSummary": {
    "count": 3,
    "categories": ["晨间", "饮水", "天气"],
    "lastPushTime": "12:30",
    "nextSlot": "afternoon"  // 14:00-18:00
  },
  
  // 情绪推断（可选，基于行为模式）
  "moodInference": null  // 暂不实现
}
```

**短期上下文窗口**：
- 时间：最近 24h 的行为事件
- 推送：今日已推送列表 + 昨日推送摘要
- 天气：当前 + 未来 3h 预报

### 5.3 长期上下文（Persistent Context）

持久化存储，跨会话共享：

```json
{
  // 历史推送摘要（最近30天）
  "pushHistorySummary": {
    "dailyAvg": 6.5,
    "topCategories": ["天气", "健康饮水", "运动"],
    "leastCategories": ["理财", "学习"],
    "responseTrend": "stable"
  },
  
  // 里程碑事件
  "milestones": [
    { "date": "2026-04-20", "event": "连续运动7天", "category": "运动" },
    { "date": "2026-05-01", "event": "假期模式" }
  ],
  
  // 季节性模式
  "seasonalPatterns": {
    "currentSeason": "spring",
    "allergySeason": true,  // 当前是否过敏季
    "upcomingHolidays": ["端午节: 2026-05-31"]
  },
  
  // 用户反馈
  "feedback": {
    "helpful": ["天气提醒", "运动鼓励"],
    "annoying": [],
    "suggestions": []
  }
}
```

### 5.4 上下文窗口与 Token 预算

LLM 输入的上下文需要严格控制 token 数：

```
上下文组成（优先级从高到低）:

┌─────────────────────────────────────────┐
│  1. 任务指令 (Prompt 模板)      ~300 token │  固定
│  2. 短期上下文                  ~600 token │  动态
│  3. 用户画像（精简版）          ~200 token │  缓存
│  4. 候选列表 (20-40条)          ~800 token │  动态
│  5. 近期推送标题                ~100 token │  动态
│  ─────────────────────────────────────── │
│  合计 Input                    ~2,000 token │
│  预留 Output                    ~500 token │
│  总计                          ~2,500 token │
└─────────────────────────────────────────┘
```

**精简策略**：
- 用户画像只传 `lifestyleTags` 和 `activeHours`，不传完整画像
- 候选列表只传 `id, name, baseWeight, triggerReason`，不传完整触发规则
- 近期推送只传 title，不传 body

---

## 6. 推送调度

### 6.1 定时 vs 事件驱动

| 维度 | 定时触发 | 事件触发 |
|------|---------|---------|
| 定义 | 每小时/每半小时执行一次 | 用户行为/外部事件触发 |
| 示例 | 整点检查是否有合适推送 | 用户打开 App、天气突变 |
| 优点 | 可控、可预测、利于成本控制 | 及时、相关性强 |
| 缺点 | 可能错过最佳时机 | 频率不可控、成本高 |
| 适用 | 日常提醒的批量生成 | 高时效性场景（天气突变等） |

**策略：定时为主，事件为辅**

```
主循环（定时）:
  每小时 :00 执行一次批量决策
  → 遍历活跃用户 → 生成候选 → 排序 → 入队

事件触发（辅助）:
  天气突变 (降水概率从 <30% 跳到 >60%)
  → 立即检查相关用户 → 插入高优先级推送
  
  用户打开 App
  → 检查是否有"适合此刻"的推送 → 可能立即展示
```

### 6.2 批量 vs 实时

**推送入队是批量的，推送发出是准实时的。**

```
批处理（每小时）:
  1. 采集所有待决策用户的上下文 (并行)
  2. 批量调用 LLM 排序 + 文案 (10-50 用户打包)
  3. 写入 push_queue 表，设定 scheduled_at
  
准实时发送:
  push_worker 每 30s 扫描 push_queue
  → 找到 scheduled_at <= now 的记录
  → 调用推送服务发送
  → 更新状态 (sent/delivered/opened)
```

### 6.3 时间窗口优化

#### 最佳推送时间（基于用户画像）

```python
def optimize_push_time(user, candidate):
    """为每条推送选择最佳发送时间"""
    
    base_time = candidate.preferred_time  # 场景默认时间
    
    # 根据用户习惯调整
    if user.sleep_pattern == "night_owl":
        if base_time.hour < 9:
            base_time = base_time.replace(hour=9)  # 猫头鹰不推早间
    
    # 根据时段配额调整
    slot = get_time_slot(base_time)
    if is_slot_full(user, slot):
        # 当前时段满了，找下一个空位
        base_time = find_next_available_slot(user, base_time)
    
    # 确保间隔
    while not can_push_at(user, base_time):
        base_time += timedelta(minutes=15)  # 每次延后15分钟重试
    
    return base_time
```

#### 智能打散

```python
def distribute_pushes(pushes, user):
    """将今日推送均匀分布到各个时段"""
    
    daily_slots = [
        TimeSlot("晨间", "07:00-09:00", 2),
        TimeSlot("上午", "09:00-12:00", 2),
        TimeSlot("午后", "12:00-14:00", 1),
        TimeSlot("下午", "14:00-18:00", 1),
        TimeSlot("晚间", "18:00-22:00", 2),
    ]
    
    # 高优先级 → 高偏好时段
    # 低优先级 → 填充空位
    for push in sorted(pushes, key=lambda p: p.score, reverse=True):
        best_slot = find_best_slot(push, daily_slots, user)
        push.scheduled_at = random_time_in(best_slot)
        best_slot.used += 1
    
    return pushes
```

### 6.4 并发处理

#### 架构（1-2 人团队可实现）

```
                    ┌──────────────┐
                    │   Scheduler  │  定时触发
                    │  (Cron Job)  │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │   Decision   │  批量决策
                    │   Service    │  (核心服务)
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Context  │ │   LLM    │ │   Rule   │
        │ Collector│ │  Client  │ │  Engine  │
        └──────────┘ └──────────┘ └──────────┘
              │            │            │
              └────────────┼────────────┘
                           ▼
                    ┌──────────────┐
                    │  Push Queue  │  数据库表
                    │  (PostgreSQL)│
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Push Worker  │  每30s轮询
                    │  (Daemon)    │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Push Service │  APNs/FCM
                    │  (第三方)     │
                    └──────────────┘
```

#### 并发策略

```python
# 批量决策（每小时执行一次）
async def hourly_batch():
    # 1. 获取活跃用户列表（分片）
    users = get_active_users()  # 假设 5000 人
    
    # 2. 分批处理，每批 50 人
    batches = chunk(users, 50)  # 100 批
    
    # 3. 并发处理（控制并发度）
    semaphore = asyncio.Semaphore(10)  # 最多 10 个并发
    
    async def process_batch(batch):
        async with semaphore:
            contexts = await collect_contexts(batch)  # 并发采集
            results = await llm_decide(contexts)       # 批量 LLM 调用
            await enqueue_pushes(results)
    
    await asyncio.gather(*[process_batch(b) for b in batches])
```

**LLM API 限流处理**：
```python
# 指数退避
@retry(max_attempts=3, backoff=[1, 2, 4])
async def call_llm(prompt):
    try:
        return await llm_client.chat(prompt)
    except RateLimitError:
        raise  # 让 retry 处理
    except TimeoutError:
        return fallback_to_rule_engine()
```

#### 数据库表设计（核心）

```sql
-- 推送队列
CREATE TABLE push_queue (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    category VARCHAR(32) NOT NULL,
    scenario_id VARCHAR(64) NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    action_text TEXT,
    scheduled_at TIMESTAMPTZ NOT NULL,
    priority INT DEFAULT 50,
    is_surprise BOOLEAN DEFAULT FALSE,
    status VARCHAR(16) DEFAULT 'pending',  -- pending, sent, delivered, failed
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_user_scheduled (user_id, scheduled_at),
    INDEX idx_status_scheduled (status, scheduled_at)
);

-- 用户推送记录（历史）
CREATE TABLE push_history (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    category VARCHAR(32),
    scenario_id VARCHAR(64),
    title TEXT,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    action_taken BOOLEAN DEFAULT FALSE,
    
    INDEX idx_user_date (user_id, sent_at)
);

-- 用户画像
CREATE TABLE user_profile (
    user_id VARCHAR(64) PRIMARY KEY,
    profile JSONB,
    category_weights JSONB,
    dynamic_profile JSONB,
    version INT DEFAULT 1,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 7. 兜底策略

### 7.1 三级降级

```
Level 0: 正常模式
  规则引擎(触发+初筛) → LLM(排序+文案) → 规则引擎(控制) → 推送

Level 1: LLM 降级（API 异常/超时/限流）
  规则引擎(触发+初筛) → 规则评分(排序) → 模板填充(文案) → 规则引擎(控制) → 推送

Level 2: 网络不可用
  本地规则引擎(触发+排序) → 预置模板(文案) → 本地频率控制 → 延迟推送队列

Level 3: 全部不可用
  静默，不推送。恢复后自动补发（补发时重新检查频率，避免雪崩）。
```

### 7.2 Level 1: LLM 不可用 → 纯规则 + 模板

#### 排序降级

LLM 排序降级为 **多因子加权公式**（见 4.3 节的 `rule_score` 函数），完全确定性，零延迟。

```python
def fallback_sort(candidates, context):
    """LLM 不可用时的排序"""
    scored = []
    for c in candidates:
        score = rule_score(c, context)  # 纯公式计算
        scored.append((c, score))
    scored.sort(key=lambda x: x[1], reverse=True)
    return scored[:12]
```

#### 文案降级

每