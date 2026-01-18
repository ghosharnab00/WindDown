import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lockManager = LockStateManager.shared

    @State private var currentTab: MenuTab = .status
    @State private var brainDumpText: String = ""
    @State private var showingAddApp: Bool = false
    @State private var showingAddWebsite: Bool = false
    @State private var settingsSection: SettingsSection = .schedule

    enum MenuTab {
        case status
        case settings
        case ritual
    }

    enum SettingsSection {
        case schedule
        case apps
        case websites
    }

    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                OnboardingFlow()
            } else {
                mainView
            }
        }
        .frame(width: 300, height: 420)
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            tabBar

            Group {
                switch currentTab {
                case .status:
                    statusView
                case .settings:
                    settingsView
                case .ritual:
                    ritualView
                }
            }
            .frame(maxHeight: .infinity)

            footerView
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 2) {
            tabButton("Status", icon: "circle.fill", tab: .status)
            tabButton("Settings", icon: "slider.horizontal.3", tab: .settings)
            tabButton("Wind Down", icon: "moon.zzz", tab: .ritual)
        }
        .padding(6)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private func tabButton(_ title: String, icon: String, tab: MenuTab) -> some View {
        Button(action: { currentTab = tab }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(currentTab == tab ? Color(nsColor: .controlBackgroundColor) : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(currentTab == tab ? .primary : .secondary)
    }

    // MARK: - Status View
    private var statusView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Status indicator
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(lockManager.isLocked ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(lockManager.isLocked ? Color.orange.opacity(0.3) : Color.green.opacity(0.3))
                        .frame(width: 60, height: 60)
                    Image(systemName: lockManager.isLocked ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundColor(lockManager.isLocked ? .orange : .green)
                }

                Text(lockManager.isLocked ? "Blocking Active" : "Work Mode")
                    .font(.system(size: 18, weight: .semibold))

                if lockManager.isLocked {
                    if let next = settings.schedule.nextTransitionDate() {
                        Text("Unlocks \(relativeTimeString(for: next))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                } else {
                    if settings.schedule.isEnabled, let next = settings.schedule.nextTransitionDate() {
                        Text("Blocks \(relativeTimeString(for: next))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Stats row
            if lockManager.isLocked {
                HStack(spacing: 20) {
                    statBadge("\(settings.blockList.enabledApps.count)", label: "Apps")
                    statBadge("\(settings.blockList.enabledWebsites.count)", label: "Sites")
                }
                .padding(.bottom, 20)
            }

            // Action button
            Button(action: {
                if lockManager.isLocked {
                    lockManager.manualUnlock()
                } else {
                    lockManager.manualLock()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: lockManager.isLocked ? "lock.open.fill" : "lock.fill")
                    Text(lockManager.isLocked ? "Unlock" : "Start Blocking")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(lockManager.isLocked ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .foregroundColor(lockManager.isLocked ? .green : .orange)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private func statBadge(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 70)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Settings View
    private var settingsView: some View {
        VStack(spacing: 0) {
            // Section Picker
            HStack(spacing: 0) {
                settingsSectionButton("Schedule", section: .schedule)
                settingsSectionButton("Apps", section: .apps)
                settingsSectionButton("Websites", section: .websites)
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch settingsSection {
                    case .schedule:
                        scheduleSettingsView
                    case .apps:
                        appsSettingsView
                    case .websites:
                        websitesSettingsView
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAddApp) {
            AddAppSheet(isPresented: $showingAddApp)
        }
        .sheet(isPresented: $showingAddWebsite) {
            AddWebsiteSheet(isPresented: $showingAddWebsite)
        }
    }

    private func settingsSectionButton(_ title: String, section: SettingsSection) -> some View {
        Button(action: { settingsSection = section }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(settingsSection == section ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                .cornerRadius(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(settingsSection == section ? .primary : .secondary)
    }

    private var scheduleSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enable toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Schedule")
                        .font(.system(size: 13, weight: .medium))
                    Text("Block automatically at set times")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.schedule.isEnabled },
                    set: { newValue in
                        var schedule = settings.schedule
                        schedule.isEnabled = newValue
                        settings.schedule = schedule
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            if settings.schedule.isEnabled {
                // Time pickers
                VStack(spacing: 12) {
                    // Start time
                    HStack {
                        Text("From")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Picker("", selection: Binding(
                            get: { settings.schedule.startTime.hour },
                            set: { h in
                                var s = settings.schedule
                                s.startTime.hour = h
                                settings.schedule = s
                            }
                        )) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHourAMPM(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 75)

                        Text(":")
                            .foregroundColor(.secondary)

                        Picker("", selection: Binding(
                            get: { settings.schedule.startTime.minute },
                            set: { m in
                                var s = settings.schedule
                                s.startTime.minute = m
                                settings.schedule = s
                            }
                        )) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 55)

                        Spacer()
                    }

                    // End time
                    HStack {
                        Text("Until")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Picker("", selection: Binding(
                            get: { settings.schedule.endTime.hour },
                            set: { h in
                                var s = settings.schedule
                                s.endTime.hour = h
                                settings.schedule = s
                            }
                        )) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHourAMPM(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 75)

                        Text(":")
                            .foregroundColor(.secondary)

                        Picker("", selection: Binding(
                            get: { settings.schedule.endTime.minute },
                            set: { m in
                                var s = settings.schedule
                                s.endTime.minute = m
                                settings.schedule = s
                            }
                        )) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 55)

                        Spacer()
                    }
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

                // Day picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Days")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            Button(action: { toggleDay(day) }) {
                                Text(String(day.shortName.prefix(1)))
                                    .font(.system(size: 11, weight: .medium))
                                    .frame(width: 32, height: 32)
                                    .background(settings.schedule.activeDays.contains(day) ? Color.orange : Color(nsColor: .controlBackgroundColor))
                                    .foregroundColor(settings.schedule.activeDays.contains(day) ? .white : .secondary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var appsSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add button
            Button(action: { showingAddApp = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                    Text("Add App")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(WorkCategory.allCases, id: \.self) { category in
                let apps = settings.blockList.blockedApps.filter { $0.category == category }
                if !apps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(spacing: 0) {
                            ForEach(Array(apps.enumerated()), id: \.element.bundleID) { index, app in
                                appRow(app)
                                if index < apps.count - 1 {
                                    Divider().padding(.leading, 12)
                                }
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private func appRow(_ app: BlockedApp) -> some View {
        HStack(spacing: 12) {
            Text(app.name)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: Binding(
                get: { app.isEnabled },
                set: { enabled in
                    settings.toggleApp(bundleID: app.bundleID, enabled: enabled)
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            Button(action: {
                settings.removeBlockedApp(bundleID: app.bundleID)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var websitesSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add button
            Button(action: { showingAddWebsite = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                    Text("Add Website")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(WorkCategory.allCases, id: \.self) { category in
                let sites = settings.blockList.blockedWebsites.filter { $0.category == category }
                if !sites.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(spacing: 0) {
                            ForEach(Array(sites.enumerated()), id: \.element.domain) { index, site in
                                websiteRow(site)
                                if index < sites.count - 1 {
                                    Divider().padding(.leading, 12)
                                }
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private func websiteRow(_ site: BlockedWebsite) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(site.name)
                    .font(.system(size: 13))
                Text(site.domain)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { site.isEnabled },
                set: { enabled in
                    settings.toggleWebsite(domain: site.domain, enabled: enabled)
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            Button(action: {
                settings.removeBlockedWebsite(domain: site.domain)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func toggleDay(_ day: Weekday) {
        var schedule = settings.schedule
        if schedule.activeDays.contains(day) {
            schedule.activeDays.remove(day)
        } else {
            schedule.activeDays.insert(day)
        }
        settings.schedule = schedule
    }

    // MARK: - Ritual View
    @State private var showingHistory = false

    private var ritualView: some View {
        VStack(spacing: 0) {
            // Toggle between write and history
            HStack(spacing: 0) {
                Button(action: { showingHistory = false }) {
                    Text("Write")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!showingHistory ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .foregroundColor(!showingHistory ? .primary : .secondary)

                Button(action: { showingHistory = true }) {
                    Text("History")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(showingHistory ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .foregroundColor(showingHistory ? .primary : .secondary)
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            if showingHistory {
                brainDumpHistoryView
            } else {
                brainDumpWriteView
            }
        }
    }

    private var brainDumpWriteView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("Brain Dump")
                    .font(.system(size: 16, weight: .semibold))
                Text("Write down what's on your mind, then let it go")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            TextEditor(text: $brainDumpText)
                .font(.system(size: 13))
                .frame(maxHeight: .infinity)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

            Button(action: {
                if !brainDumpText.isEmpty {
                    BrainDumpStore.shared.addEntry(brainDumpText)
                }
                brainDumpText = ""
                lockManager.manualLock()
                currentTab = .status
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                    Text("Done & Start Blocking")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private var brainDumpHistoryView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                let grouped = BrainDumpStore.shared.entriesGroupedByDate()

                if grouped.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No entries yet")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(grouped, id: \.0) { dateString, entries in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(dateString)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            ForEach(entries) { entry in
                                Text(entry.text)
                                    .font(.system(size: 13))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("WindDown")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
            Spacer()
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - Helper Functions
private func formatHourAMPM(_ hour: Int) -> String {
    if hour == 0 {
        return "12 AM"
    } else if hour < 12 {
        return "\(hour) AM"
    } else if hour == 12 {
        return "12 PM"
    } else {
        return "\(hour - 12) PM"
    }
}

private func formatTimeAMPM(hour: Int, minute: Int) -> String {
    let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
    let ampm = hour < 12 ? "AM" : "PM"
    return String(format: "%d:%02d %@", h, minute, ampm)
}

// MARK: - Onboarding Flow (Inline)
struct OnboardingFlow: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= step ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding()

            Divider()

            // Content
            Group {
                switch step {
                case 0: welcomeStep
                case 1: scheduleStep
                case 2: readyStep
                default: EmptyView()
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Navigation
            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.bordered)
                }
                Spacer()
                if step < 2 {
                    Button("Next") { step += 1 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        settings.hasCompletedOnboarding = true
                        LockStateManager.shared.start()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Welcome to WindDown")
                .font(.title2)
                .fontWeight(.bold)

            Text("Block work apps & websites after hours to maintain healthy boundaries.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                featureRow("moon.fill", "Automatic blocking on schedule")
                featureRow("brain", "Brain dump before disconnecting")
                featureRow("hand.raised", "Works locally, no data sent")
            }
            .padding()
        }
        .padding()
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }

    private var scheduleStep: some View {
        VStack(spacing: 16) {
            Text("Set Your Schedule")
                .font(.title3)
                .fontWeight(.semibold)

            Text("When should blocking start?")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Text("Block from")
                        .font(.system(size: 12))
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.schedule.startTime.hour },
                        set: { h in
                            var s = settings.schedule
                            s.startTime.hour = h
                            settings.schedule = s
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHourAMPM(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 75)

                    Text(":")
                        .foregroundColor(.secondary)

                    Picker("", selection: Binding(
                        get: { settings.schedule.startTime.minute },
                        set: { m in
                            var s = settings.schedule
                            s.startTime.minute = m
                            settings.schedule = s
                        }
                    )) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 55)
                }

                HStack {
                    Text("Until")
                        .font(.system(size: 12))
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.schedule.endTime.hour },
                        set: { h in
                            var s = settings.schedule
                            s.endTime.hour = h
                            settings.schedule = s
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHourAMPM(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 75)

                    Text(":")
                        .foregroundColor(.secondary)

                    Picker("", selection: Binding(
                        get: { settings.schedule.endTime.minute },
                        set: { m in
                            var s = settings.schedule
                            s.endTime.minute = m
                            settings.schedule = s
                        }
                    )) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 55)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Text("Default: 6:00 PM - 9:00 AM on weekdays")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("You're Ready!")
                .font(.title2)
                .fontWeight(.bold)

            Text("WindDown will live in your menu bar. Click the moon icon anytime to:")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                featureRow("lock.fill", "Lock/unlock manually")
                featureRow("gear", "Adjust settings")
                featureRow("brain", "Do a brain dump")
            }
            .padding()
        }
        .padding()
    }
}

// MARK: - Add App Sheet
struct AddAppSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settings = SettingsStore.shared

    @State private var appName: String = ""
    @State private var bundleID: String = ""
    @State private var selectedCategory: WorkCategory = .communication

    var body: some View {
        VStack(spacing: 16) {
            Text("Add App to Block")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("App Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. Discord", text: $appName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Bundle ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. com.hnc.Discord", text: $bundleID)
                    .textFieldStyle(.roundedBorder)
                Text("Find in /Applications → Right-click app → Show Package Contents → Info.plist")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WorkCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .labelsHidden()
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add") {
                    if !appName.isEmpty && !bundleID.isEmpty {
                        let app = BlockedApp(
                            bundleID: bundleID.trimmingCharacters(in: .whitespaces),
                            name: appName.trimmingCharacters(in: .whitespaces),
                            category: selectedCategory,
                            isEnabled: true
                        )
                        settings.addBlockedApp(app)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appName.isEmpty || bundleID.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 320)
    }
}

// MARK: - Add Website Sheet
struct AddWebsiteSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settings = SettingsStore.shared

    @State private var siteName: String = ""
    @State private var domain: String = ""
    @State private var selectedCategory: WorkCategory = .communication

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Website to Block")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Site Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. Discord", text: $siteName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Domain")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. discord.com", text: $domain)
                    .textFieldStyle(.roundedBorder)
                Text("Don't include https:// or www.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WorkCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .labelsHidden()
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Add") {
                    if !siteName.isEmpty && !domain.isEmpty {
                        var cleanDomain = domain.trimmingCharacters(in: .whitespaces)
                        cleanDomain = cleanDomain.replacingOccurrences(of: "https://", with: "")
                        cleanDomain = cleanDomain.replacingOccurrences(of: "http://", with: "")
                        cleanDomain = cleanDomain.replacingOccurrences(of: "www.", with: "")
                        if cleanDomain.hasSuffix("/") {
                            cleanDomain = String(cleanDomain.dropLast())
                        }

                        let site = BlockedWebsite(
                            domain: cleanDomain,
                            name: siteName.trimmingCharacters(in: .whitespaces),
                            category: selectedCategory,
                            isEnabled: true
                        )
                        settings.addBlockedWebsite(site)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(siteName.isEmpty || domain.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 300)
    }
}

#Preview {
    MenuBarView()
}
