import Foundation
import AVFoundation
import CoreLocation
import Combine
import UIKit
import UserNotifications

// MARK: - Local Notifier
final class LocalNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifier()

    func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    @Published var currentVolume: Float = 0.7
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(
                .ambient,
                options: [.duckOthers, .defaultToSpeaker]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }

    func setVolume(to level: Int) {
        let volumeValue = Float(level) / 100.0
        DispatchQueue.main.async {
            self.currentVolume = volumeValue
        }
    }

    func setNotificationMode(to mode: NotificationMode) {
        do {
            switch mode {
            case .normal:
                try audioSession.setCategory(
                    .ambient,
                    options: [.duckOthers, .defaultToSpeaker]
                )
            case .vibration:
                try audioSession.setCategory(
                    .ambient,
                    options: [.duckOthers]
                )
            case .silent:
                try audioSession.setCategory(
                    .ambient,
                    options: []
                )
            }
        } catch {
            print("❌ Failed to set notification mode: \(error)")
        }
    }
}

// MARK: - Location Service
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var activeLocationRule: Location?

    private let locationManager = CLLocationManager()
    private var monitoredRegions: [String: CLCircularRegion] = [:]
    private var currentLocationHandler: ((CLLocationCoordinate2D?) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        currentLocationHandler = completion
        locationManager.requestLocation()
    }

    func addGeofence(for location: Location) {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ),
            radius: location.radiusInMeters,
            identifier: location.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)
        monitoredRegions[location.id.uuidString] = region
        print("✓ Started monitoring region: \(location.name)")
    }

    func removeGeofence(for locationId: UUID) {
        if let region = monitoredRegions[locationId.uuidString] {
            locationManager.stopMonitoring(for: region)
            monitoredRegions.removeValue(forKey: locationId.uuidString)
            print("✓ Stopped monitoring region")
        }
    }

    // MARK: - Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        DispatchQueue.main.async {
            self.currentLocationHandler?(coordinate)
            self.currentLocationHandler = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to get current location: \(error)")
        DispatchQueue.main.async {
            self.currentLocationHandler?(nil)
            self.currentLocationHandler = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("📍 Entered region: \(circularRegion.identifier)")
            NotificationCenter.default.post(
                name: NSNotification.Name("LocationEntered"),
                object: circularRegion.identifier
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("📍 Exited region: \(circularRegion.identifier)")
            NotificationCenter.default.post(
                name: NSNotification.Name("LocationExited"),
                object: circularRegion.identifier
            )
        }
    }
}

// MARK: - Schedule Service
class ScheduleService: ObservableObject {
    @Published var activeSchedule: TimeSchedule?
    private var scheduleTimer: Timer?
    private var schedules: [TimeSchedule] = []

    func startScheduleMonitoring() {
        // Check every minute
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.evaluateSchedules()
        }
        // Also check immediately
        evaluateSchedules()
    }

    func stopScheduleMonitoring() {
        scheduleTimer?.invalidate()
        scheduleTimer = nil
    }

    func updateSchedules(_ schedules: [TimeSchedule]) {
        self.schedules = schedules
        evaluateSchedules()
    }

    private func evaluateSchedules() {
        let now = Calendar.current.dateComponents([.hour, .minute, .weekday], from: Date())

        let activeSchedules = schedules.filter { schedule in
            guard schedule.isEnabled else { return false }

            // Check day of week if specified
            if let daysOfWeek = schedule.daysOfWeek, !daysOfWeek.isEmpty {
                guard daysOfWeek.contains(now.weekday ?? 0) else { return false }
            }

            // Check time range
            return isTimeInRange(now, startHour: schedule.startHour, startMinute: schedule.startMinute,
                               endHour: schedule.endHour, endMinute: schedule.endMinute)
        }

        let newActiveSchedule = activeSchedules.min(by: { $0.volumeLevel < $1.volumeLevel })
        let didChange = newActiveSchedule?.id != activeSchedule?.id

        DispatchQueue.main.async {
            self.activeSchedule = newActiveSchedule
        }

        if didChange {
            NotificationCenter.default.post(
                name: NSNotification.Name("ScheduleChanged"),
                object: newActiveSchedule?.id
            )
        }
    }

    private func isTimeInRange(
        _ current: DateComponents,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Bool {
        let currentMinutes = (current.hour ?? 0) * 60 + (current.minute ?? 0)
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Wraps around midnight
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }
}

// MARK: - Rules Engine
class RulesEngine: ObservableObject {
    @Published var currentRule: ActiveRule?

    func resolveAndApplyRules(
        locationRule: Location?,
        scheduleRule: TimeSchedule?,
        settings: AppSettings,
        audioManager: AudioManager
    ) {
        guard settings.isAutomationEnabled else { return }

        let resolvedRule = resolveConflict(location: locationRule, schedule: scheduleRule, settings: settings)

        if let rule = resolvedRule {
            let didChange = rule.sourceName != currentRule?.sourceName
                || rule.volumeLevel != currentRule?.volumeLevel
                || rule.notificationMode != currentRule?.notificationMode

            applyRule(rule, audioManager: audioManager)
            DispatchQueue.main.async {
                self.currentRule = rule
            }

            if didChange && settings.notifyOnRuleChange {
                LocalNotifier.shared.post(
                    title: "Hush",
                    body: "\(rule.sourceName): Volume \(rule.volumeLevel)%, \(rule.notificationMode.description)"
                )
            }
        }
    }

    private func resolveConflict(
        location: Location?,
        schedule: TimeSchedule?,
        settings: AppSettings
    ) -> ActiveRule? {
        switch settings.priorityMode {
        case .timePriority:
            if let schedule = schedule {
                return convertScheduleToRule(schedule)
            } else if let location = location {
                return convertLocationToRule(location)
            }

        case .locationPriority:
            if let location = location {
                return convertLocationToRule(location)
            } else if let schedule = schedule {
                return convertScheduleToRule(schedule)
            }

        case .mostRestrictive:
            var finalRule = ActiveRule(sourceType: .none, sourceName: "None", volumeLevel: 100, notificationMode: .normal, screenBrightness: nil)

            if let location = location {
                let locRule = convertLocationToRule(location)
                finalRule = mergeRules(finalRule, locRule, preferQuietest: true)
            }

            if let schedule = schedule {
                let schedRule = convertScheduleToRule(schedule)
                finalRule = mergeRules(finalRule, schedRule, preferQuietest: true)
            }

            if case .none = finalRule.sourceType {
                return nil
            }
            return finalRule
        }

        return nil
    }

    private func convertLocationToRule(_ location: Location) -> ActiveRule {
        return ActiveRule(
            sourceType: .location(location),
            sourceName: location.name,
            volumeLevel: location.volumeLevel,
            notificationMode: location.notificationMode,
            screenBrightness: location.screenBrightness
        )
    }

    private func convertScheduleToRule(_ schedule: TimeSchedule) -> ActiveRule {
        return ActiveRule(
            sourceType: .schedule(schedule),
            sourceName: schedule.name,
            volumeLevel: schedule.volumeLevel,
            notificationMode: schedule.notificationMode,
            screenBrightness: schedule.screenBrightness
        )
    }

    private func mergeRules(_ rule1: ActiveRule, _ rule2: ActiveRule, preferQuietest: Bool) -> ActiveRule {
        if preferQuietest {
            let screenBrightness: Double?
            switch (rule1.screenBrightness, rule2.screenBrightness) {
            case let (b1?, b2?): screenBrightness = min(b1, b2)
            case let (b1?, nil): screenBrightness = b1
            case let (nil, b2?): screenBrightness = b2
            case (nil, nil): screenBrightness = nil
            }
            return ActiveRule(
                sourceType: rule1.volumeLevel <= rule2.volumeLevel ? rule1.sourceType : rule2.sourceType,
                sourceName: rule1.volumeLevel <= rule2.volumeLevel ? rule1.sourceName : rule2.sourceName,
                volumeLevel: min(rule1.volumeLevel, rule2.volumeLevel),
                notificationMode: quieterMode(rule1.notificationMode, rule2.notificationMode),
                screenBrightness: screenBrightness
            )
        }
        return rule1
    }

    private func quieterMode(_ mode1: NotificationMode, _ mode2: NotificationMode) -> NotificationMode {
        let order: [NotificationMode] = [.silent, .vibration, .normal]
        return order.contains(mode1) && order.contains(mode2) ?
            order[min(order.firstIndex(of: mode1)!, order.firstIndex(of: mode2)!)] :
            mode1
    }

    private func applyRule(_ rule: ActiveRule, audioManager: AudioManager) {
        audioManager.setVolume(to: rule.volumeLevel)
        audioManager.setNotificationMode(to: rule.notificationMode)

        if let brightness = rule.screenBrightness {
            DispatchQueue.main.async {
                let screen = UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.screen }
                    .first
                screen?.brightness = brightness
            }
        }
    }
}
