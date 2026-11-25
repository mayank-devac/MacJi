//
//  UpdateController.swift
//  MacJi
//
//  Created: 2026-11-26
//  Owns the Sparkle updater: start, Check Now, the automatic-check toggle and the last check
//  date, published for Settings.
//  Ported from Octopus: octopus/Updates/SparkleConnector.swift
//

import AppKit
import Combine
import Sparkle

@MainActor
final class UpdateController: ObservableObject {
    private let driverDelegate = BackgroundAppUpdateDriver()
    private let controller: SPUStandardUpdaterController
    private var observations: [NSKeyValueObservation] = []
    private var didStart = false

    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecks: Bool
    @Published private(set) var lastCheckDate: Date?

    init() {
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil,
                                                  userDriverDelegate: driverDelegate)
        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
    }

    ////////////////////
    //// Start
    /// Started from `applicationDidFinishLaunching`, never in tests. Sparkle shows its own alert
    /// if the configuration is broken (missing feed or key), so a bad build fails visibly.
    // SPUUpdater is main-actor bound and posts its KVO changes on the main thread.

    func start() {
        guard !didStart else { return }
        didStart = true
        controller.startUpdater()
        let updater = controller.updater
        observations = [
            updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.canCheckForUpdates = updater.canCheckForUpdates }
            },
            updater.observe(\.lastUpdateCheckDate, options: [.initial, .new]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.lastCheckDate = updater.lastUpdateCheckDate }
            },
        ]
        automaticallyChecks = updater.automaticallyChecksForUpdates
    }

    //////////////////

    func checkForUpdates() {
        start()
        NSApp.activate()
        controller.checkForUpdates(nil)
    }

    /// Sparkle stores this in its own `SUEnableAutomaticChecks` key; Info.plist makes it default on.
    func setAutomaticallyChecks(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
        automaticallyChecks = enabled
    }
}

////////////////////
//// Background-app update alerts
/// MacJi has no Dock icon. Sparkle asks such apps to opt in to "gentle reminders"; it then
/// keeps showing its standard alert but, since Sparkle 2.2, without stealing focus from the
// app the user is typing in (except right after launch).

private final class BackgroundAppUpdateDriver: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }
}

//////////////////
