#!/usr/bin/env swift
//
//  verify-update.swift
//  MacJi
//
//  Created: 2026-11-26
//  Checks a release archive against its appcast entry before publishing: EdDSA signature,
//  length, and that the version, build and public key inside the archived app match.
//  Ported from Octopus: scripts/verify-update.swift
//
//  Usage:   swift scripts/verify-update.swift <MacJi-x.y.z.zip> <appcast.xml> <SUPublicEDKey>
//  Example: swift scripts/verify-update.swift .build/release/0.1.1/MacJi-0.1.1.zip dist/appcast.xml "$KEY"
//

import CryptoKit
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("✗ \(message)\n".utf8))
    exit(1)
}

let arguments = CommandLine.arguments
if arguments.count == 2, ["-h", "--help"].contains(arguments[1]) {
    print("Usage: swift scripts/verify-update.swift <archive.zip> <appcast.xml> <SUPublicEDKey>")
    exit(0)
}
guard arguments.count == 4 else { fail("Usage: swift scripts/verify-update.swift <archive.zip> <appcast.xml> <SUPublicEDKey>") }
let archiveURL = URL(fileURLWithPath: arguments[1])
let appcastURL = URL(fileURLWithPath: arguments[2])
let publicKeyText = arguments[3]

////////////////////
//// Find the appcast entry for this archive
/// The entry is the <item> whose enclosure URL ends with the archive's file name.

final class AppcastEntryReader: NSObject, XMLParserDelegate {
    let archiveName: String
    var entry: (version: String, shortVersion: String, signature: String, length: String)?
    private var inItem = false
    private var text = ""
    private var version = ""
    private var shortVersion = ""
    private var enclosure: [String: String] = [:]

    init(archiveName: String) { self.archiveName = archiveName }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String]) {
        text = ""
        if name == "item" { inItem = true; version = ""; shortVersion = ""; enclosure = [:] }
        if inItem, name == "enclosure" { enclosure = attributes }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if name == "sparkle:version" { version = value }
        if name == "sparkle:shortVersionString" { shortVersion = value }
        if name == "item" {
            inItem = false
            if entry == nil, enclosure["url"]?.hasSuffix("/" + archiveName) == true {
                entry = (version, shortVersion, enclosure["sparkle:edSignature"] ?? "", enclosure["length"] ?? "")
            }
        }
    }
}

//////////////////

guard let parser = XMLParser(contentsOf: appcastURL) else { fail("Cannot read \(appcastURL.path).") }
let reader = AppcastEntryReader(archiveName: archiveURL.lastPathComponent)
parser.delegate = reader
guard parser.parse() else { fail("\(appcastURL.lastPathComponent) is not valid XML.") }
guard let entry = reader.entry else { fail("No appcast item has an enclosure for \(archiveURL.lastPathComponent).") }

////////////////////
//// Signature and length
/// Verified with the app's public key, never with a second lookup of the private key.

guard let archive = try? Data(contentsOf: archiveURL) else { fail("Cannot read \(archiveURL.path).") }
guard String(archive.count) == entry.length else { fail("Appcast length \(entry.length) ≠ archive size \(archive.count).") }
guard let keyData = Data(base64Encoded: publicKeyText), let signature = Data(base64Encoded: entry.signature),
      let key = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
    fail("The public key or the appcast signature is not valid base64 Ed25519 data.")
}
guard key.isValidSignature(signature, for: archive) else { fail("EdDSA signature does not match the public key.") }

//////////////////

////////////////////
//// The archived app agrees with the appcast
/// Version, build and SUPublicEDKey are read from the app inside the zip.

let unpacked = FileManager.default.temporaryDirectory.appendingPathComponent("macji-verify-\(UUID().uuidString)")
defer { try? FileManager.default.removeItem(at: unpacked) }
let ditto = Process()
ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
ditto.arguments = ["-x", "-k", archiveURL.path, unpacked.path]
do { try ditto.run() } catch { fail("Cannot unzip the archive: \(error.localizedDescription)") }
ditto.waitUntilExit()
guard ditto.terminationStatus == 0 else { fail("Cannot unzip the archive.") }
let plistURL = unpacked.appendingPathComponent("MacJi.app/Contents/Info.plist")
guard let plist = NSDictionary(contentsOf: plistURL) as? [String: Any] else { fail("The archive does not contain MacJi.app.") }
guard plist["CFBundleVersion"] as? String == entry.version else { fail("Build in app ≠ sparkle:version \(entry.version).") }
guard plist["CFBundleShortVersionString"] as? String == entry.shortVersion else { fail("Version in app ≠ shortVersionString \(entry.shortVersion).") }
guard plist["SUPublicEDKey"] as? String == publicKeyText else { fail("SUPublicEDKey inside the app differs from the key given.") }

//////////////////

print("✓ \(archiveURL.lastPathComponent): EdDSA signature, length, version \(entry.shortVersion) (\(entry.version)) and key match the appcast")
