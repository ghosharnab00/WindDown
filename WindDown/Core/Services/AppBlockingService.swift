import AppKit
import Combine

final class AppBlockingService: ObservableObject {
    static let shared = AppBlockingService()

    @Published private(set) var isActive: Bool = false
    @Published private(set) var blockedBundleIDs: Set<String> = []

    private var workspaceNotificationObserver: NSObjectProtocol?

    private init() {}

    // MARK: - Activation
    func activate(blocking bundleIDs: Set<String>) {
        guard !isActive else { return }

        blockedBundleIDs = bundleIDs
        isActive = true

        startMonitoring()
        terminateBlockedApps()

        print("[AppBlockingService] Activated with \(bundleIDs.count) blocked apps")
    }

    func deactivate() {
        guard isActive else { return }

        stopMonitoring()
        blockedBundleIDs = []
        isActive = false

        print("[AppBlockingService] Deactivated")
    }

    func updateBlockedApps(_ bundleIDs: Set<String>) {
        blockedBundleIDs = bundleIDs
        if isActive {
            terminateBlockedApps()
        }
    }

    // MARK: - Monitoring
    private func startMonitoring() {
        let workspace = NSWorkspace.shared

        workspaceNotificationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLaunch(notification)
        }
    }

    private func stopMonitoring() {
        if let observer = workspaceNotificationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceNotificationObserver = nil
        }
    }

    private func handleAppLaunch(_ notification: Notification) {
        guard isActive,
              let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier,
              blockedBundleIDs.contains(bundleID) else {
            return
        }

        print("[AppBlockingService] Blocked app launched: \(bundleID)")
        terminateApp(app)

        // Send notification
        let appName = app.localizedName ?? bundleID
        NotificationService.shared.sendAppBlockedNotification(appName: appName)
    }

    // MARK: - App Termination
    private func terminateBlockedApps() {
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            guard let bundleID = app.bundleIdentifier,
                  blockedBundleIDs.contains(bundleID) else {
                continue
            }

            terminateApp(app)
        }
    }

    private func terminateApp(_ app: NSRunningApplication) {
        let terminated = app.terminate()
        if !terminated {
            app.forceTerminate()
        }
        print("[AppBlockingService] Terminated: \(app.bundleIdentifier ?? "unknown")")
    }

    // MARK: - Querying
    func isAppBlocked(_ bundleID: String) -> Bool {
        isActive && blockedBundleIDs.contains(bundleID)
    }
}
