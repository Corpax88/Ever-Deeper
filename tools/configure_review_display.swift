#!/usr/bin/env swift
// Use only display modes advertised by the macOS runner. Never substitute a
// smaller framebuffer for the requested rendered review.
import CoreGraphics
import Foundation
import Darwin

let minimumWidth = 1920
let minimumHeight = 1080
let display = CGMainDisplayID()

func describe(_ mode: CGDisplayMode) -> [String: Any] {
    return [
        "mode_id": mode.ioDisplayModeID,
        "logical_size": [mode.width, mode.height],
        "pixel_size": [mode.pixelWidth, mode.pixelHeight],
        "refresh_hz": mode.refreshRate.isFinite ? mode.refreshRate : 0.0,
        "usable_for_desktop": mode.isUsableForDesktopGUI(),
    ]
}

func meetsMinimum(_ mode: CGDisplayMode) -> Bool {
    return mode.isUsableForDesktopGUI()
        && mode.width >= minimumWidth && mode.height >= minimumHeight
        && mode.pixelWidth >= minimumWidth && mode.pixelHeight >= minimumHeight
}

var report: [String: Any] = [
    "display_id": display,
    "minimum_logical_size": [minimumWidth, minimumHeight],
    "minimum_pixel_size": [minimumWidth, minimumHeight],
    "configuration_scope": "current_login_session",
    "success": false,
]

func finish(_ reason: String? = nil) -> Never {
    if let mode = CGDisplayCopyDisplayMode(display) {
        report["current_after"] = describe(mode)
    }
    let bounds = CGDisplayBounds(display)
    report["display_bounds"] = [bounds.origin.x, bounds.origin.y, bounds.width, bounds.height]
    if let reason = reason { report["error"] = reason }
    let data = try! JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
    if let reason = reason {
        FileHandle.standardError.write(Data("Rendered review display setup failed: \(reason)\n".utf8))
        exit(1)
    }
    exit(0)
}

guard display != 0, let original = CGDisplayCopyDisplayMode(display) else {
    finish("No active main display or readable current display mode.")
}
report["current_before"] = describe(original)

let options = [kCGDisplayShowDuplicateLowResolutionModes as String: true] as CFDictionary
guard let advertised = CGDisplayCopyAllDisplayModes(display, options) as? [CGDisplayMode] else {
    finish("CoreGraphics could not enumerate advertised display modes.")
}
report["advertised_modes"] = advertised.map(describe)

if meetsMinimum(original) {
    report["changed"] = false
    report["success"] = true
    finish()
}

let candidates = advertised.filter(meetsMinimum).sorted {
    let leftArea = $0.width * $0.height
    let rightArea = $1.width * $1.height
    if leftArea != rightArea { return leftArea < rightArea }
    let leftPixels = $0.pixelWidth * $0.pixelHeight
    let rightPixels = $1.pixelWidth * $1.pixelHeight
    if leftPixels != rightPixels { return leftPixels < rightPixels }
    if $0.refreshRate != $1.refreshRate { return $0.refreshRate > $1.refreshRate }
    return $0.ioDisplayModeID < $1.ioDisplayModeID
}
guard !candidates.isEmpty else {
    finish("No advertised desktop mode provides at least 1920x1080 in both logical and framebuffer pixels. The 1696x780 review cannot run honestly on this display.")
}

var attempts: [[String: Any]] = []
for mode in candidates {
    var attempt: [String: Any] = ["mode": describe(mode)]
    var configuration: CGDisplayConfigRef?
    let begin = CGBeginDisplayConfiguration(&configuration)
    attempt["begin_result"] = begin.rawValue
    guard begin == .success, let configuration = configuration else {
        attempts.append(attempt)
        continue
    }
    let configure = CGConfigureDisplayWithDisplayMode(configuration, display, mode, nil)
    attempt["configure_result"] = configure.rawValue
    guard configure == .success else {
        CGCancelDisplayConfiguration(configuration)
        attempts.append(attempt)
        continue
    }
    // Session scope survives this setup process without changing the machine's
    // permanent display preference. A process-local mode switch would not.
    let complete = CGCompleteDisplayConfiguration(configuration, .forSession)
    attempt["complete_result"] = complete.rawValue
    attempts.append(attempt)
    report["attempts"] = attempts
    guard complete == .success else { continue }

    for _ in 0..<30 {
        if let current = CGDisplayCopyDisplayMode(display), meetsMinimum(current) {
            report["selected"] = describe(mode)
            report["changed"] = true
            report["success"] = true
            finish()
        }
        Thread.sleep(forTimeInterval: 0.1)
    }
}
report["attempts"] = attempts
finish("The runner rejected or did not apply every advertised mode meeting 1920x1080. See CoreGraphics result codes and current_after; no smaller review was started.")
