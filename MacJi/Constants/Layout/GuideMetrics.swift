//
//  GuideMetrics.swift
//  MacJi
//
//  Created: 2026-11-26
//  Sizes of the drag-to-allow Accessibility guide docked beside System Settings.
//  Ported from Octopus: octopus/UI/Permissions/AccessibilityPermissionGuideView.swift, octopus/UI/Permissions/AccessibilityGuidePlacement.swift
//

import CoreGraphics

enum GuideMetrics {
    /// Distance from the System Settings window and from screen edges.
    static let gap: CGFloat = 8
    static let width: CGFloat = 340
    static let padding: CGFloat = 14
    static let spacing: CGFloat = 10
    static let cornerRadius: CGFloat = 16
    static let textLeading: CGFloat = 6

    // Drag chip
    static let chipCornerRadius: CGFloat = 14
    static let chipPadding: CGFloat = 8
    static let chipTrailing: CGFloat = 6
    static let chipSpacing: CGFloat = 12
    static let chipStrokeWidth: CGFloat = 1.5
    static let chipDash: [CGFloat] = [5, 3]
    static let iconSize: CGFloat = 40
    static let iconPadding: CGFloat = 4
    static let iconCornerRadius: CGFloat = 10

    // Type
    static let appNameSize: CGFloat = 15
    static let titleSize: CGFloat = 13
    static let detailSize: CGFloat = 11
    static let hintIconSize: CGFloat = 16
    static let closeIconSize: CGFloat = 15
}
