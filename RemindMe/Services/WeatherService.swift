// V2.0 — 天气服务 (本地 Mock，规划接入和风 API)

import Foundation

// MARK: - 天气数据模型

struct WeatherData {
    let temp: Int           // 摄氏度
    let condition: WeatherCondition
    let uvIndex: Int        // 0-11+
    let windSpeed: Int      // km/h
    let humidity: Int       // 百分比

    /// 是否需要带伞
    var needUmbrella: Bool {
        condition == .rain || condition == .heavyRain
    }

    /// 是否需要防晒
    var needSunscreen: Bool {
        uvIndex >= 5 && (condition == .sunny || condition == .cloudy)
    }

    /// 是否降温明显（温度低于季节平均 5 度以上）
    var isColdSnap: Bool {
        let month = Calendar.current.component(.month, from: Date())
        let seasonAvg: Int
        switch month {
        case 12, 1, 2: seasonAvg = 2
        case 3, 4, 5: seasonAvg = 15
        case 6, 7, 8: seasonAvg = 28
        case 9, 10, 11: seasonAvg = 16
        default: seasonAvg = 15
        }
        return temp < seasonAvg - 5
    }
}

// MARK: - 天气状况枚举

enum WeatherCondition: String, CaseIterable {
    case sunny
    case cloudy
    case overcast
    case rain
    case heavyRain
    case snow

    var displayName: String {
        switch self {
        case .sunny: return "晴"
        case .cloudy: return "多云"
        case .overcast: return "阴"
        case .rain: return "小雨"
        case .heavyRain: return "大雨"
        case .snow: return "雪"
        }
    }

    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "⛅️"
        case .overcast: return "☁️"
        case .rain: return "🌧"
        case .heavyRain: return "⛈"
        case .snow: return "🌨"
        }
    }
}

// MARK: - 天气服务

final class WeatherService {
    static let shared = WeatherService()

    private init() {}

    /// 获取当前天气数据（V2.0 本地 Mock）
    /// - 按月份+随机数生成，模拟真实天气
    /// - 30% 下雨概率，温度按季节区间
    func fetchCurrentWeather() -> WeatherData? {
        let month = Calendar.current.component(.month, from: Date())
        let hour = Calendar.current.component(.hour, from: Date())

        // 按月份确定温度区间
        let (minTemp, maxTemp): (Int, Int)
        switch month {
        case 12, 1, 2: (minTemp, maxTemp) = (-5, 8)
        case 3, 4, 5:  (minTemp, maxTemp) = (8, 25)
        case 6, 7, 8:  (minTemp, maxTemp) = (22, 38)
        case 9, 10, 11: (minTemp, maxTemp) = (5, 22)
        default: (minTemp, maxTemp) = (10, 25)
        }

        let temp = Int.random(in: minTemp...maxTemp)

        // 天气状况：30% 下雨，10% 雪（冬季），其余按权重
        let roll = Int.random(in: 0..<100)
        let condition: WeatherCondition

        if month <= 2 || month == 12 {
            // 冬季：15% 雪，20% 雨
            if roll < 15 {
                condition = .snow
            } else if roll < 35 {
                condition = roll < 25 ? .rain : .heavyRain
            } else if roll < 60 {
                condition = .overcast
            } else if roll < 80 {
                condition = .cloudy
            } else {
                condition = .sunny
            }
        } else {
            // 非冬季：30% 雨
            if roll < 20 {
                condition = .rain
            } else if roll < 30 {
                condition = .heavyRain
            } else if roll < 50 {
                condition = .overcast
            } else if roll < 75 {
                condition = .cloudy
            } else {
                condition = .sunny
            }
        }

        // UV 指数：晴天高，阴天低
        let uvBase: Int
        switch condition {
        case .sunny: uvBase = 6
        case .cloudy: uvBase = 4
        case .overcast: uvBase = 2
        case .rain, .heavyRain: uvBase = 1
        case .snow: uvBase = 3
        }
        // 夏季 UV 更高
        let uvSeason = (month >= 5 && month <= 9) ? 2 : 0
        // 傍晚后 UV 低
        let uvHour = (hour >= 6 && hour <= 16) ? 0 : -3
        let uvIndex = max(0, min(11, uvBase + uvSeason + uvHour + Int.random(in: -1...1)))

        // 风速：雨天偏大
        let windBase: Int
        switch condition {
        case .heavyRain: windBase = Int.random(in: 20...40)
        case .rain: windBase = Int.random(in: 10...25)
        case .snow: windBase = Int.random(in: 5...20)
        default: windBase = Int.random(in: 2...15)
        }

        // 湿度：雨天高
        let humidity: Int
        switch condition {
        case .rain, .heavyRain: humidity = Int.random(in: 70...95)
        case .overcast: humidity = Int.random(in: 50...75)
        case .snow: humidity = Int.random(in: 40...70)
        default: humidity = Int.random(in: 25...60)
        }

        return WeatherData(
            temp: temp,
            condition: condition,
            uvIndex: uvIndex,
            windSpeed: windBase,
            humidity: humidity
        )
    }

    /// 根据天气生成提醒文案片段
    func weatherReminderText(for weather: WeatherData) -> [String] {
        var texts: [String] = []

        if weather.needUmbrella {
            texts.append("今天\(weather.condition.displayName)，记得带伞出门")
        }

        if weather.temp <= 0 {
            texts.append("气温零下\(abs(weather.temp))度，注意保暖防冻")
        } else if weather.temp <= 10 {
            texts.append("今天只有\(weather.temp)度，出门记得穿厚一点")
        }

        if weather.needSunscreen {
            texts.append("紫外线指数\(weather.uvIndex)，外出注意防晒")
        }

        if weather.windSpeed >= 30 {
            texts.append("今天风力较大（\(weather.windSpeed)km/h），注意出行安全")
        }

        if weather.isColdSnap {
            texts.append("今天比近期平均温度低不少，多穿一件")
        }

        return texts
    }
}
