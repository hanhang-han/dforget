import Foundation

/// V2.0: Pro 订阅管理
/// 使用 StoreKit 2 处理订阅
/// 免费版: 每日 3 条基础提醒
/// Pro: ¥88/年（中国区）/$19.99/年（海外区）

import StoreKit

// MARK: - 订阅产品

enum SubscriptionTier: String, Codable {
    case free = "free"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free: return "免费版"
        case .pro: return "Pro"
        }
    }

    var dailyReminderLimit: Int {
        switch self {
        case .free: return 3
        case .pro: return 99
        }
    }

    var availableCategories: [String] {
        switch self {
        case .free: return ["weather", "calendar", "time"]
        case .pro: return ["weather", "calendar", "time", "health", "finance", "pet", "family"]
        }
    }
}

// MARK: - Pro 功能列表

enum ProFeature: String, CaseIterable {
    case unlimitedReminders = "无限提醒"
    case healthIntegration = "健康数据"
    case advancedCategories = "高级类别"
    case monthlyReport = "月度报告"
    case customSchedule = "自定义调度"
    case widgetAccess = "小组件"

    var description: String {
        switch self {
        case .unlimitedReminders: return "免费版每日3条，Pro无限制"
        case .healthIntegration: return "结合运动、睡眠数据生成提醒"
        case .advancedCategories: return "解锁家庭、宠物、财务等类别"
        case .monthlyReport: return "每月推送使用习惯总结"
        case .customSchedule: return "精确到小时的自定义推送时间"
        case .widgetAccess: return "桌面小组件显示最新提醒"
        }
    }

    var iconName: String {
        switch self {
        case .unlimitedReminders: return "infinity"
        case .healthIntegration: return "heart.fill"
        case .advancedCategories: return "square.grid.2x2"
        case .monthlyReport: return "chart.bar"
        case .customSchedule: return "clock.badge"
        case .widgetAccess: return "widget.small"
        }
    }
}

// MARK: - 订阅管理器

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var currentTier: SubscriptionTier = .free
    @Published var products: [Product] = []
    @Published var isLoadingProducts = false
    @Published var purchaseError: String?

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        loadSavedTier()
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - 产品加载

    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let storeProducts = try await Product.products(for: ["remindme_pro_annual"])
            products = storeProducts
        } catch {
            print("[Subscription] Failed to load products: \(error)")
        }
    }

    // MARK: - 购买

    @MainActor
    func purchasePro() async -> Bool {
        guard let product = products.first else {
            purchaseError = "产品信息加载失败"
            return false
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                return true

            case .userCancelled:
                purchaseError = nil
                return false

            case .pending:
                purchaseError = "购买处理中..."
                return false

            @unknown default:
                purchaseError = "未知错误"
                return false
            }
        } catch {
            purchaseError = "购买失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 恢复购买

    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("[Subscription] Restore failed: \(error)")
        }
    }

    // MARK: - 订阅状态

    @MainActor
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == "remindme_pro_annual" {
                    currentTier = .pro
                    saveTier(.pro)
                    return
                }
            }
        }
        currentTier = .free
        saveTier(.free)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - 验证

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - 持久化

    private func saveTier(_ tier: SubscriptionTier) {
        UserDefaults.standard.set(tier.rawValue, forKey: "subscription_tier")
    }

    private func loadSavedTier() {
        let raw = UserDefaults.standard.string(forKey: "subscription_tier") ?? "free"
        currentTier = SubscriptionTier(rawValue: raw) ?? .free
    }
}
