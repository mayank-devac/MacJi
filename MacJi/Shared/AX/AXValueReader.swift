//
//  AXValueReader.swift
//  MacJi
//
//  Created: 2026-11-26
//  Checked reads of Accessibility attributes: every value is type-checked before use,
//  so a misbehaving app can never crash MacJi with an unexpected CF type.
//  Ported from Octopus: octopus/UI/MacJi/MacJiCaretLocator.swift
//

import ApplicationServices

////////////////////
//// Checked AX reads
/// AX calls fail often (no focus, app busy, attribute unsupported); each read returns nil then.
/// A value is used only after its `CFGetTypeID` matches, replacing Octopus's `as!` casts.
// Callers set a short messaging timeout on the element so an unresponsive app cannot stall MacJi.

enum AXValueReader {
    static func element(_ attribute: String, of element: AXUIElement) -> AXUIElement? {
        guard let value = copy(attribute, of: element), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    static func range(_ attribute: String, of element: AXUIElement) -> CFRange? {
        guard let value = axValue(copy(attribute, of: element)) else { return nil }
        var range = CFRange()
        return AXValueGetValue(value, .cfRange, &range) ? range : nil
    }

    /// Screen bounds (AX top-left coordinates) of a text range inside `element`.
    static func bounds(of range: CFRange, in element: AXUIElement) -> CGRect? {
        var range = range
        guard let rangeValue = AXValueCreate(.cfRange, &range) else { return nil }
        var boundsValue: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, kAXBoundsForRangeParameterizedAttribute as CFString,
                                                         rangeValue, &boundsValue) == .success,
              let value = axValue(boundsValue) else { return nil }
        var bounds = CGRect.zero
        return AXValueGetValue(value, .cgRect, &bounds) ? bounds : nil
    }

    private static func copy(_ attribute: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    private static func axValue(_ value: CFTypeRef?) -> AXValue? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return unsafeDowncast(value, to: AXValue.self)
    }
}

//// A nil result means "unavailable"; callers fall back (the caret falls back to the pointer).
//////////////////
