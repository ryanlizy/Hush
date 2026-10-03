import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var rulesEngine: RulesEngine
    @EnvironmentObject var appState: AppState

    @State private var showSettings = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                VStack(spacing: 20) {
                    // Status Card
                    VStack(alignment: .center, spacing: 8) {
                        Text("Hush")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)

                        if let rule = rulesEngine.currentRule {
                            Text(rule.sourceName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Normal Mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Volume Control
                    VStack(alignment: .center, spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(Int(audioManager.currentVolume * 100))%")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.blue)
                        }

                        Slider(value: $audioManager.currentVolume, in: 0...1, step: 0.01)
                            .accentColor(.blue)

                        HStack(spacing: 12) {
                            Button(action: { audioManager.setVolume(to: 0) }) {
                                Text("Mute")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            Button(action: { audioManager.setVolume(to: 50) }) {
                                Text("50%")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            Button(action: { audioManager.setVolume(to: 100) }) {
                                Text("Max")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Active Rules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Rules")
                            .font(.headline)

                        VStack(spacing: 0) {
                            RuleStatusRow(
                                icon: "location.fill",
                                label: "Location",
                                value: locationService.activeLocationRule?.name ?? "No location detected",
                                isActive: locationService.activeLocationRule != nil
                            )

                            Divider()
                                .padding(.leading, 52)

                            RuleStatusRow(
                                icon: "clock.fill",
                                label: "Time",
                                value: scheduleService.activeSchedule?.name ?? "No time rule active",
                                isActive: scheduleService.activeSchedule != nil
                            )
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            // Locations Tab
            NavigationStack {
                LocationsListView()
            }
            .tabItem {
                Label("Locations", systemImage: "location.fill")
            }
            .tag(1)

            // Schedules Tab
            NavigationStack {
                SchedulesListView()
            }
            .tabItem {
                Label("Schedules", systemImage: "clock.fill")
            }
            .tag(2)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Rule Status Row
struct RuleStatusRow: View {
    let icon: String
    let label: String
    let value: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isActive ? .white : .secondary)
                .frame(width: 28, height: 28)
                .background(isActive ? Color.blue : Color(.systemGray4))
                .clipShape(Circle())

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .blue : .secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Locations List View
struct LocationsListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationService: LocationService
    @State private var showAddLocation = false

    var body: some View {
        Group {
            if appState.locations.isEmpty {
                EmptyStateView(
                    systemImage: "location.slash",
                    title: "No Locations Yet",
                    message: "Add a location to automatically adjust volume and notifications when you arrive."
                )
            } else {
                List {
                    ForEach(appState.locations) { location in
                        NavigationLink {
                            EditLocationView(location: location, locations: $appState.locations)
                        } label: {
                            LocationRowView(location: location)
                        }
                    }
                    .onDelete(perform: deleteLocation)
                }
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddLocation = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddLocation) {
            AddLocationView(locations: $appState.locations)
        }
    }

    private func deleteLocation(at offsets: IndexSet) {
        for index in offsets {
            locationService.removeGeofence(for: appState.locations[index].id)
        }
        appState.locations.remove(atOffsets: offsets)
    }
}

struct LocationRowView: View {
    let location: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(location.name)
                    .font(.headline)
                Spacer()
                Text("\(location.volumeLevel)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(location.notificationMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Map Location Picker
struct MapLocationPickerView: View {
    let initialCoordinate: CLLocationCoordinate2D
    let onConfirm: (CLLocationCoordinate2D) -> Void

    var body: some View {
        if #available(iOS 17.0, *) {
            ModernMapLocationPickerView(initialCoordinate: initialCoordinate, onConfirm: onConfirm)
        } else {
            LegacyMapLocationPickerView(initialCoordinate: initialCoordinate, onConfirm: onConfirm)
        }
    }
}

@available(iOS 17.0, *)
private struct ModernMapLocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var currentCenter: CLLocationCoordinate2D
    let onConfirm: (CLLocationCoordinate2D) -> Void

    init(initialCoordinate: CLLocationCoordinate2D, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        let region = MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        self._cameraPosition = State(initialValue: .region(region))
        self._currentCenter = State(initialValue: initialCoordinate)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition)
                    .onMapCameraChange(frequency: .continuous) { context in
                        currentCenter = context.region.center
                    }
                    .ignoresSafeArea(edges: .bottom)

                Image(systemName: "mappin")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
                    .offset(y: -18)
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") {
                        onConfirm(currentCenter)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct LegacyMapLocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion
    let onConfirm: (CLLocationCoordinate2D) -> Void

    init(initialCoordinate: CLLocationCoordinate2D, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        self._region = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region)
                    .ignoresSafeArea(edges: .bottom)

                Image(systemName: "mappin")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
                    .offset(y: -18)
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") {
                        onConfirm(region.center)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddLocationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var appState: AppState
    @Binding var locations: [Location]

    @State private var name = ""
    @State private var latitude: Double = 37.7749
    @State private var longitude: Double = -122.4194
    @State private var volumeLevel: Double = 50
    @State private var notificationMode: NotificationMode = .normal
    @State private var showMapPicker = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Location Name", text: $name)

                Section("Location") {
                    Button {
                        showMapPicker = true
                    } label: {
                        Label("Choose on Map", systemImage: "map")
                    }

                    Button {
                        locationService.requestCurrentLocation { coordinate in
                            if let coordinate {
                                latitude = coordinate.latitude
                                longitude = coordinate.longitude
                            }
                        }
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }

                    DisclosureGroup("Coordinates") {
                        TextField("Latitude", value: $latitude, format: .number)
                        TextField("Longitude", value: $longitude, format: .number)
                    }
                }

                Section("Audio Settings") {
                    VStack(alignment: .leading) {
                        Text("Volume: \(Int(volumeLevel))%")
                        Slider(value: $volumeLevel, in: 0...100, step: 1)
                    }

                    Picker("Notification Mode", selection: $notificationMode) {
                        ForEach(NotificationMode.allCases, id: \.self) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                }
            }
            .navigationTitle("Add Location")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let newLocation = Location(
                            name: name,
                            latitude: latitude,
                            longitude: longitude,
                            radiusInMeters: appState.settings.geofenceRadiusDefault,
                            volumeLevel: Int(volumeLevel),
                            notificationMode: notificationMode
                        )
                        locations.append(newLocation)
                        locationService.addGeofence(for: newLocation)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapLocationPickerView(
                    initialCoordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                ) { coordinate in
                    latitude = coordinate.latitude
                    longitude = coordinate.longitude
                }
            }
        }
    }
}

struct EditLocationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationService: LocationService
    @Binding var locations: [Location]

    private let original: Location

    @State private var name: String
    @State private var latitude: Double
    @State private var longitude: Double
    @State private var volumeLevel: Double
    @State private var notificationMode: NotificationMode
    @State private var showMapPicker = false

    init(location: Location, locations: Binding<[Location]>) {
        self.original = location
        self._locations = locations
        self._name = State(initialValue: location.name)
        self._latitude = State(initialValue: location.latitude)
        self._longitude = State(initialValue: location.longitude)
        self._volumeLevel = State(initialValue: Double(location.volumeLevel))
        self._notificationMode = State(initialValue: location.notificationMode)
    }

    var body: some View {
        Form {
            TextField("Location Name", text: $name)

            Section("Location") {
                Button {
                    showMapPicker = true
                } label: {
                    Label("Choose on Map", systemImage: "map")
                }

                Button {
                    locationService.requestCurrentLocation { coordinate in
                        if let coordinate {
                            latitude = coordinate.latitude
                            longitude = coordinate.longitude
                        }
                    }
                } label: {
                    Label("Use Current Location", systemImage: "location.fill")
                }

                DisclosureGroup("Coordinates") {
                    TextField("Latitude", value: $latitude, format: .number)
                    TextField("Longitude", value: $longitude, format: .number)
                }
            }

            Section("Audio Settings") {
                VStack(alignment: .leading) {
                    Text("Volume: \(Int(volumeLevel))%")
                    Slider(value: $volumeLevel, in: 0...100, step: 1)
                }

                Picker("Notification Mode", selection: $notificationMode) {
                    ForEach(NotificationMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
            }
        }
        .navigationTitle("Edit Location")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    guard let index = locations.firstIndex(where: { $0.id == original.id }) else {
                        dismiss()
                        return
                    }

                    let updatedLocation = Location(
                        id: original.id,
                        name: name,
                        latitude: latitude,
                        longitude: longitude,
                        radiusInMeters: original.radiusInMeters,
                        isEnabled: original.isEnabled,
                        volumeLevel: Int(volumeLevel),
                        notificationMode: notificationMode,
                        screenBrightness: original.screenBrightness,
                        muteSound: original.muteSound,
                        createdAt: original.createdAt,
                        updatedAt: Date()
                    )
                    locations[index] = updatedLocation
                    locationService.removeGeofence(for: original.id)
                    locationService.addGeofence(for: updatedLocation)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
        .sheet(isPresented: $showMapPicker) {
            MapLocationPickerView(
                initialCoordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            ) { coordinate in
                latitude = coordinate.latitude
                longitude = coordinate.longitude
            }
        }
    }
}

// MARK: - Schedules List View
struct SchedulesListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var scheduleService: ScheduleService
    @State private var showAddSchedule = false

    var body: some View {
        Group {
            if appState.schedules.isEmpty {
                EmptyStateView(
                    systemImage: "clock.badge.xmark",
                    title: "No Schedules Yet",
                    message: "Add a schedule to automatically adjust volume and notifications during set hours."
                )
            } else {
                List {
                    ForEach(appState.schedules) { schedule in
                        NavigationLink {
                            EditScheduleView(schedule: schedule, schedules: $appState.schedules)
                        } label: {
                            ScheduleRowView(schedule: schedule)
                        }
                    }
                    .onDelete(perform: deleteSchedule)
                }
            }
        }
        .navigationTitle("Schedules")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddSchedule = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSchedule) {
            AddScheduleView(schedules: $appState.schedules)
        }
    }

    private func deleteSchedule(at offsets: IndexSet) {
        appState.schedules.remove(atOffsets: offsets)
        scheduleService.updateSchedules(appState.schedules)
    }
}

struct ScheduleRowView: View {
    let schedule: TimeSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(schedule.name)
                    .font(.headline)
                Spacer()
                Text("\(schedule.volumeLevel)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Text(schedule.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(schedule.notificationMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var scheduleService: ScheduleService
    @Binding var schedules: [TimeSchedule]

    @State private var name = ""
    @State private var startHour = 22
    @State private var startMinute = 0
    @State private var endHour = 7
    @State private var endMinute = 0
    @State private var volumeLevel: Double = 50
    @State private var notificationMode: NotificationMode = .normal

    private static let minuteOptions = [0, 15, 30, 45]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Schedule Name", text: $name)

                Section("Start Time") {
                    Picker("Hour", selection: $startHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    Picker("Minute", selection: $startMinute) {
                        ForEach(Self.minuteOptions, id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                }

                Section("End Time") {
                    Picker("Hour", selection: $endHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    Picker("Minute", selection: $endMinute) {
                        ForEach(Self.minuteOptions, id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                }

                Section("Audio Settings") {
                    VStack(alignment: .leading) {
                        Text("Volume: \(Int(volumeLevel))%")
                        Slider(value: $volumeLevel, in: 0...100, step: 1)
                    }

                    Picker("Notification Mode", selection: $notificationMode) {
                        ForEach(NotificationMode.allCases, id: \.self) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                }
            }
            .navigationTitle("Add Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let newSchedule = TimeSchedule(
                            name: name,
                            startHour: startHour,
                            startMinute: startMinute,
                            endHour: endHour,
                            endMinute: endMinute,
                            volumeLevel: Int(volumeLevel),
                            notificationMode: notificationMode
                        )
                        schedules.append(newSchedule)
                        scheduleService.updateSchedules(schedules)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var scheduleService: ScheduleService
    @Binding var schedules: [TimeSchedule]

    private let original: TimeSchedule

    @State private var name: String
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int
    @State private var volumeLevel: Double
    @State private var notificationMode: NotificationMode

    private static let minuteOptions = [0, 15, 30, 45]

    init(schedule: TimeSchedule, schedules: Binding<[TimeSchedule]>) {
        self.original = schedule
        self._schedules = schedules
        self._name = State(initialValue: schedule.name)
        self._startHour = State(initialValue: schedule.startHour)
        self._startMinute = State(initialValue: schedule.startMinute)
        self._endHour = State(initialValue: schedule.endHour)
        self._endMinute = State(initialValue: schedule.endMinute)
        self._volumeLevel = State(initialValue: Double(schedule.volumeLevel))
        self._notificationMode = State(initialValue: schedule.notificationMode)
    }

    var body: some View {
        Form {
            TextField("Schedule Name", text: $name)

            Section("Start Time") {
                Picker("Hour", selection: $startHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                Picker("Minute", selection: $startMinute) {
                    ForEach(Self.minuteOptions, id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
            }

            Section("End Time") {
                Picker("Hour", selection: $endHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                Picker("Minute", selection: $endMinute) {
                    ForEach(Self.minuteOptions, id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
            }

            Section("Audio Settings") {
                VStack(alignment: .leading) {
                    Text("Volume: \(Int(volumeLevel))%")
                    Slider(value: $volumeLevel, in: 0...100, step: 1)
                }

                Picker("Notification Mode", selection: $notificationMode) {
                    ForEach(NotificationMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
            }
        }
        .navigationTitle("Edit Schedule")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    guard let index = schedules.firstIndex(where: { $0.id == original.id }) else {
                        dismiss()
                        return
                    }

                    let updatedSchedule = TimeSchedule(
                        id: original.id,
                        name: name,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute,
                        isEnabled: original.isEnabled,
                        daysOfWeek: original.daysOfWeek,
                        volumeLevel: Int(volumeLevel),
                        notificationMode: notificationMode,
                        screenBrightness: original.screenBrightness,
                        muteSound: original.muteSound,
                        createdAt: original.createdAt,
                        updatedAt: Date()
                    )
                    schedules[index] = updatedSchedule
                    scheduleService.updateSchedules(schedules)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Automation") {
                    Toggle("Automation Enabled", isOn: $appState.settings.isAutomationEnabled)

                    Picker("Priority Mode", selection: $appState.settings.priorityMode) {
                        ForEach(PriorityMode.allCases, id: \.self) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Notify on Rule Change", isOn: $appState.settings.notifyOnRuleChange)
                    Toggle("Notify on Location Change", isOn: $appState.settings.notifyOnLocationEnterExit)
                }

                Section("Location") {
                    Stepper(
                        "Geofence Radius: \(Int(appState.settings.geofenceRadiusDefault))m",
                        value: $appState.settings.geofenceRadiusDefault,
                        in: 100...2000,
                        step: 100
                    )
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioManager())
        .environmentObject(LocationService())
        .environmentObject(ScheduleService())
        .environmentObject(RulesEngine())
        .environmentObject(AppState())
}
