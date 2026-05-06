import Foundation
import HealthKit

/// V2.0: HealthKit 数据服务
/// 读取步数、运动、睡眠数据，用于生成健康类提醒
/// TODO: AI Integration — 用 Health 数据做更精准的场景推断

final class HealthService: ObservableObject {
    static let shared = HealthService()

    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayExerciseMinutes: Double = 0
    @Published var lastNightSleep: Double = 0  // 小时

    private let healthStore = HKHealthStore()

    // MARK: - 支持的 Health 类型

    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

    /// HealthKit 是否可用
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - 授权

    /// 请求 HealthKit 权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard Self.isAvailable else {
            completion(false)
            return
        }

        let typesToRead: Set<HKObjectType> = [stepType, exerciseType, sleepType]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                completion(success)
            }
        }
    }

    /// 检查授权状态
    func checkAuthorizationStatus() {
        guard Self.isAvailable else { return }

        let status = healthStore.authorizationStatus(for: stepType)
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - 读取数据

    /// 获取今日步数
    func fetchTodaySteps() async -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                DispatchQueue.main.async {
                    self.todaySteps = Int(steps)
                }
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }

    /// 获取今日运动时长（分钟）
    func fetchTodayExercise() async -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: exerciseType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let minutes = statistics?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                DispatchQueue.main.async {
                    self.todayExerciseMinutes = minutes
                }
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        }
    }

    /// 获取昨晚睡眠时长（小时）
    func fetchLastNightSleep() async -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay.addingTimeInterval(-86400), end: startOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                var totalInBed: TimeInterval = 0

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                for sample in sleepSamples {
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        totalInBed += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }

                let hours = totalInBed / 3600
                DispatchQueue.main.async {
                    self.lastNightSleep = hours
                }
                continuation.resume(returning: hours)
            }
            healthStore.execute(query)
        }
    }

    /// 一次性获取所有健康数据
    func fetchAllHealthData() async {
        guard Self.isAvailable && isAuthorized else { return }

        async let steps = fetchTodaySteps()
        async let exercise = fetchTodayExercise()
        async let sleep = fetchLastNightSleep()

        _ = await steps
        _ = await exercise
        _ = await sleep
    }

    // MARK: - 生成健康提醒

    /// 基于健康数据生成提醒文案
    func generateHealthReminders() -> [String] {
        var reminders: [String] = []

        // 步数
        let hour = Calendar.current.component(.hour, from: .now)
        if hour >= 18 && todaySteps < 3000 {
            reminders.append("今天才走了 \\(todaySteps) 步，饭后出去走走？")
        } else if hour >= 14 && todaySteps < 2000 {
            reminders.append("今天活动量有点少，起身活动一下。")
        }

        // 运动
        if hour >= 20 && todayExerciseMinutes < 10 {
            reminders.append("今天运动时间不够，做几个拉伸也行。")
        }

        // 睡眠
        if hour >= 7 && hour <= 10 && lastNightSleep > 0 && lastNightSleep < 6 {
            reminders.append("昨晚只睡了 \\(String(format: \"%.1f\", lastNightSleep)) 小时，今晚早点睡。")
        } else if hour >= 7 && hour <= 10 && lastNightSleep > 0 && lastNightSleep > 9 {
            reminders.append("昨晚睡了 \\(String(format: \"%.1f\", lastNightSleep)) 小时，睡眠充足。")
        }

        return reminders
    }
}
