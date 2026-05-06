# Ralph Agent Configuration

## Environment Setup

```bash
# XcodeGen (项目生成)
which xcodegen || brew install xcodegen

# Node.js (后端)
cd backend && npm install
```

## Build Instructions

```bash
# Step 1: 生成 Xcode 项目（如果 .xcodeproj 不存在或 project.yml 有变更）
cd /Users/hanhang/Desktop/work/home/developer/dforget
xcodegen generate

# Step 2: 编译 iOS 主 App（跳过签名，模拟器）
xcodebuild build \
  -project RemindMe.xcodeproj \
  -scheme RemindMe \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY= \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet
```

## Test Instructions

```bash
# 暂无单元测试，通过编译验证代码正确性
# 编译成功 = 测试通过

# 后端测试（如有）
cd /Users/hanhang/Desktop/work/home/developer/dforget/backend
npm test
```

## Run Instructions

```bash
# iOS 模拟器运行（需要完整模拟器环境）
xcodebuild build \
  -project RemindMe.xcodeproj \
  -scheme RemindMe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# 后端开发服务器
cd /Users/hanhang/Desktop/work/home/developer/dforget/backend
npm run dev
```

## Project Scheme

```bash
# 查看可用 scheme
xcodebuild -list -project RemindMe.xcodeproj

# 两个 Target：
# - RemindMe (主 App)
# - RemindMeWidget (Widget Extension)
```

## Notes
- 项目使用 XcodeGen 管理，`project.yml` 是项目定义文件，**不要直接编辑 .xcodeproj**
- 修改项目结构后需要重新 `xcodegen generate`
- 编译跳过签名，不需要 Apple Developer 证书
- iPhone 17 Pro 是当前可用模拟器（iOS 26.4.1）
- 后端使用腾讯云 SCF，本地开发用 `npm run dev`
- 所有 Services 是单例模式（static let shared），直接调用即可
