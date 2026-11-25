//
//  SettingsMetrics.swift
//  MacJi
//
//  Created: 2026-11-26
//  Size limits of the Settings window and spacing inside its sections.
//

import CoreGraphics

enum SettingsMetrics {
    // Window: fixed width, resizable height only
    static let width: CGFloat = 480
    static let initialHeight: CGFloat = 720
    static let minHeight: CGFloat = 420
    static let maxHeight: CGFloat = 1400

    // Rows
    static let rowSpacing: CGFloat = 4
    static let statusIconSize: CGFloat = 14
    static let triggerFieldWidth: CGFloat = 72
    static let aboutIconSize: CGFloat = 56
    static let aboutSpacing: CGFloat = 12
    static let linkSpacing: CGFloat = 16
}
