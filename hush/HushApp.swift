import SwiftUI
import Combine

@main
struct HushApp: App {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var scheduleService = ScheduleService()
    @StateObject private var rulesEngine = RulesEngine()
    @StateObject private var appState = AppState()

    @State private var activeLocationId: String?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(locationService)
                .environmentObject(scheduleService)
                .environmentObject(rulesEngine)
                .environmentObject(appState)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        // Request location permission
        locationService.requestPermission()

        // Request notification permission
        LocalNotifier.shared.requestAuthorization()

        // Start schedule monitoring
        scheduleService.startScheduleMonitoring()

        // Start watching geofences for all saved locations
        for location in appState.locations where location.isEnabled {
            locationService.addGeofence(for: location)
        }
        scheduleService.updateSchedules(appState.schedules)

        // Set up listeners for location and schedule changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LocationEntered"),
            object: nil,
            queue: .main
        ) { notification in
            if let locationId = notification.object as? String {
                activeLocationId = locationId
                if appState.settings.notifyOnLocationEnterExit,
                   let location = appState.locations.first(where: { $0.id.uuidString == locationId }) {
                    LocalNotifier.shared.post(title: "Hush", body: "Entered \(location.name)")
                }
            }
            reevaluateRules()
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LocationExited"),
            object: nil,
            queue: .main
        ) { notification in
            if let locationId = notification.object as? String, activeLocationId == locationId {
                activeLocationId = nil
                if appState.settings.notifyOnLocationEnterExit,
                   let location = appState.locations.first(where: { $0.id.uuidString == locationId }) {
                    LocalNotifier.shared.post(title: "Hush", body: "Left \(location.name)")
                }
            }
            reevaluateRules()
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ScheduleChanged"),
            object: nil,
            queue: .main
        ) { _ in
            reevaluateRules()
        }
    }

    private func reevaluateRules() {
        let activeLocation = activeLocationId.flatMap { id in
            appState.locations.first(where: { $0.id.uuidString == id })
        }
        locationService.activeLocationRule = activeLocation
        rulesEngine.resolveAndApplyRules(
            locationRule: activeLocation,
            scheduleRule: scheduleService.activeSchedule,
            settings: appState.settings,
            audioManager: audioManager
        )
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var locations: [Location] = [] {
        didSet { Self.save(locations, forKey: StorageKey.locations) }
    }
    @Published var schedules: [TimeSchedule] = [] {
        didSet { Self.save(schedules, forKey: StorageKey.schedules) }
    }
    @Published var settings: AppSettings = AppSettings() {
        didSet { Self.save(settings, forKey: StorageKey.settings) }
    }

    private enum StorageKey {
        static let locations = "hush.locations"
        static let schedules = "hush.schedules"
        static let settings = "hush.settings"
    }

    init() {
        locations = Self.load([Location].self, forKey: StorageKey.locations) ?? []
        schedules = Self.load([TimeSchedule].self, forKey: StorageKey.schedules) ?? []
        settings = Self.load(AppSettings.self, forKey: StorageKey.settings) ?? AppSettings()
    }

    private static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
