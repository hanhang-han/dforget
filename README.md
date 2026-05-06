# RemindMe - 灵动提醒

基于上下文感知的 AI 智能生活提醒 App。用户不需要手动输入，系统自动生成并推送生活提醒，以 iOS Live Activity / 灵动岛为主形态。

## 特性

- **零输入提醒**：基于天气、日历、时间自动推送
- **灵动岛常驻**：Live Activity 长居锁屏，不打扰但一直陪伴
- **极简设计**：纯黑白，无装饰，温度靠内容不靠视觉
- **小纸条**：每周 0-1 条特殊关怀卡片
- **渐进式探索**：先给价值再要信息，不需前置问卷

## 项目结构

```
remind-app/
├── RemindMe/          # iOS App (Swift/SwiftUI)
│   ├── App/
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   └── Activities/
├── backend/           # Node.js 后端 (腾讯云 SCF)
│   ├── src/
│   │   ├── functions/
│   │   ├── shared/
│   │   └── layers/
│   └── package.json
└── docs/              # 设计文档
    ├── remind-app-architecture.md
    ├── remind-app-llm-engine.md
    ├── remind-app-ui-design.md
    └── ...
```

## 版本计划

- **V1.0**: 天气+时间+日历提醒，Live Activity，本地通知，极简 UI
- **V1.1**: 反馈机制，偏好存储，推送频率控制，冷启动
- **V2.0**: Health 数据，Pro 功能，Widget，月度报告
- **V2.1**: AI 对话调整偏好，多主题，高级日历联动
- **V3.0**: 位置感知，家庭/宠物/财务，家庭共享，深度学习

## 技术栈

- **iOS**: Swift 5.9+ / SwiftUI / SwiftData / ActivityKit
- **后端**: Node.js (Fastify) / 腾讯云 SCF
- **数据库**: PostgreSQL / Redis
- **AI**: DeepSeek / GLM (V1.0 使用伪代码)

## License

Private
