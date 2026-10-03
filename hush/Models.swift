import Foundation

// MARK: - Notification Mode
enum NotificationMode: String, Codable, CaseIterable {
    case normal = "normal"
    case vibration = "vibration"
    case silent = "silent"

    var description: String {
        switch self {
        case .normal: return "Normal"
        case .vibration: return "Vibration Only"
        case .silent: return "Silent"
        }
    }
}

// MARK: - Priority Mode
enum PriorityMode: String, Codable, CaseIterable {
    case timePriority = "timePriority"
    case locationPriority = "locationPriority"
    case mostRestrictive = "mostRestrictive"

    var description: String {
        switch self {
        case .timePriority: return "⏰ Time Priority"
        case .locationPriority: return "📍 Location Priority"
        case .mostRestrictive: return "✓ Most Restrictive"
        }
    }
}

// MARK: - Location Model
struct Location: Identifiable, Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let radiusInMeters: Double
    let isEnabled: Bool

    // Auto-settings for this location
    let volumeLevel: Int
    let notificationMode: NotificationMode
    let screenBrightness: Double?
    let muteSound: Bool

    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radiusInMeters: Double = 500,
        isEnabled: Bool = true,
        volumeLevel: Int = 50,
        notificationMode: NotificationMode = .normal,
        screenBrightness: Double? = nil,
        muteSound: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radiusInMeters = radiusInMeters
        self.isEnabled = isEnabled
        self.volumeLevel = volumeLevel
        self.notificationMode = notificationMode
        self.screenBrightness = screenBrightness
        self.muteSound = muteSound
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Time Schedule Model
struct TimeSchedule: Identifiable, Codable {
    let id: UUID
    let name: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let isEnabled: Bool
    let daysOfWeek: Set<Int>?

    // Auto-settings for this time period
    let volumeLevel: Int
    let notificationMode: NotificationMode
    let screenBrightness: Double?
    let muteSound: Bool

    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        isEnabled: Bool = true,
        daysOfWeek: Set<Int>? = nil,
        volumeLevel: Int = 50,
        notificationMode: NotificationMode = .normal,
        screenBrightness: Double? = nil,
        muteSound: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = isEnabled
        self.daysOfWeek = daysOfWeek
        self.volumeLevel = volumeLevel
        self.notificationMode = notificationMode
        self.screenBrightness = screenBrightness
        self.muteSound = muteSound
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var timeRange: String {
        let startStr = String(format: "%02d:%02d", startHour, startMinute)
        let endStr = String(format: "%02d:%02d", endHour, endMinute)
        return "\(startStr) - \(endStr)"
    }
}

// MARK: - App Settings Model
struct AppSettings: Codable {
    var priorityMode: PriorityMode = .timePriority
    var isAutomationEnabled: Bool = true
    var notifyOnRuleChange: Bool = true
    var notifyOnLocationEnterExit: Bool = true
    var geofenceRadiusDefault: Double = 500
    var lastSyncDate: Date?
}

// MARK: - Active Rule (result of conflict resolution)
struct ActiveRule: Identifiable {
    let id: UUID = UUID()
    let sourceType: RuleSourceType
    let sourceName: String
    let volumeLevel: Int
    let notificationMode: NotificationMode
    let screenBrightness: Double?
    let appliedAt: Date = Date()

    enum RuleSourceType {
        case location(Location)
        case schedule(TimeSchedule)
        case none
    }
}
