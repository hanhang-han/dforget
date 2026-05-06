import Foundation
import CoreLocation

/// V3.0: 位置感知服务
/// 根据用户位置生成上下文提醒
/// 需要用户授权位置权限（后台定位）
/// TODO: AI Integration — 结合位置+时间+天气做多维度场景推断

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published var isAuthorized = false
    @Published var currentLocation: CLLocation?
    @Published var currentPlacemark: String?
    @Published var lastKnownPlaceType: PlaceType?

    private let locationManager = CLLocationManager()

    // MARK: - 地点类型

    enum PlaceType: String {
        case home = "家"
        case work = "公司"
        case gym = "健身房"
        case supermarket = "超市"
        case unknown = "其他"
    }

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // 100米内不重复更新
    }

    // MARK: - 授权

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// 请求后台位置（用于离家/到家提醒）
    func requestBackgroundLocation() {
        var needsAlways = false
        if #available(iOS 17, *) {
            needsAlways = true
        }
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - 获取位置

    func startUpdatingLocation() {
        guard isAuthorized else { return }
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - 反向地理编码

    func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.name
        } catch {
            print("[Location] Reverse geocode failed: \\(error)")
            return nil
        }
    }

    // MARK: - 地点推断

    /// 根据位置历史推断地点类型
    func inferPlaceType(from location: CLLocation) -> PlaceType {
        // TODO: 结合位置历史+时间段推断
        // 简化版：基于时间+位置半径
        let hour = Calendar.current.component(.hour, from: .now)
        let weekday = Calendar.current.component(.weekday, from: .now)

        // 工作日白天 → 公司
        if weekday >= 2 && weekday <= 6 && hour >= 9 && hour <= 18 {
            return .work
        }

        // 晚上/周末 → 家
        if hour >= 20 || hour < 7 {
            return .home
        }

        // 其他 → 未知
        return .unknown
    }

    // MARK: - 生成位置提醒

    /// 基于位置变化生成提醒
    func generateLocationReminders() async -> [String] {
        guard let location = currentLocation else { return [] }

        var reminders: [String] = []

        let place = inferPlaceType(from: location)
        lastKnownPlaceType = place

        // 离家提醒
        let hour = Calendar.current.component(.hour, from: .now)
        if place == .home && hour >= 7 && hour <= 9 {
            reminders.append("准备出门了，检查一下有没有忘带的东西")
        }

        // 到家提醒
        if place == .home && hour >= 18 && hour <= 22 {
            reminders.append("到家了，换双拖鞋放松一下")
        }

        // 到公司提醒
        if place == .work && hour >= 8 && hour <= 10 {
            reminders.append("到公司了，今天有什么重要的事？")
        }

        // 查询天气（结合位置）
        // TODO: 调用天气 API

        return reminders
    }

    /// 地理围栏监控
    /// TODO: 设置家和公司的地理围栏，进出时触发提醒
    func startMonitoringGeofences() {
        // TODO: AI Integration — 根据用户常用地点自动设置围栏
        // let homeRegion = CLCircularRegion(center: homeCoordinate, radius: 200, identifier: "home")
        // locationManager.startMonitoring(for: homeRegion)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.currentPlacemark = await self.reverseGeocode(location)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        // TODO: 处理地理围栏进入/离开事件
    }
}
