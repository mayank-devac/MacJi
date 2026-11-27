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

    // Aliases page
    static let aliasSpacing: CGFloat = 8
    static let aliasTextWidth: CGFloat = 96
    static let pageHeaderPadding: CGFloat = 12
    static let tagHorizontalPadding: CGFloat = 5

    // Alias editor sheet
    static let editorWidth: CGFloat = 440
    static let editorHeight: CGFloat = 560

    // Send Feedback sheet
    static let feedbackWidth: CGFloat = 460
    static let feedbackHeight: CGFloat = 640
    static let feedbackEditorHeight: CGFloat = 100
    static let feedbackPlaceholderInset: CGFloat = 5
    static let feedbackBulletSpacing: CGFloat = 6
}
