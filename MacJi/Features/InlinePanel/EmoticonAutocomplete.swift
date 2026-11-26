//
//  EmoticonAutocomplete.swift
//  MacJi
//
//  Created: 2026-11-27
//  Decides, for the text just typed, whether it is the start of an emoticon worth suggesting
//  ("^_" → ^_^). A pure value type so the rules are unit-tested.
//

import Foundation

struct EmoticonAutocomplete {
    /// Characters a run needs before suggestions open; 0 turns autocomplete off.
    let minimumLength: Int
    /// Active triggers: a run that starts with one belongs to that trigger's panel.
    let triggers: [String]
    /// Every proper prefix of every emoticon, so the tap decides with one set lookup.
    private let prefixes: Set<String>
    /// The run Esc dismissed; suggestions stay closed while the run still starts with it.
    private var dismissed: String?

    ////////////////////
    //// Building the prefix set
    /// Only proper prefixes: typing a whole emoticon ("8)") suggests nothing, so Return passes.
    /// Starts common in code, markup, paths, times and ranges never suggest, though those
    /// emoticons stay searchable: an open suggestion takes Return, Esc, the arrows and Tab.
    // The second line covers calls and groups ("((", "(*", "\(" Swift interpolation), closing
    // tags, comparisons, "0:30" and "8-10".

    static let deniedStarts = ["--", "//", "/*", "*/", "./", "../", "~/", "==", "=-", "=>", "**", "__",
                               "<!", "${", "#{", "&&", "||", ":=", "+=", "-=", "<<", ">>", "?.", "!!",
                               "((", "(*", "(.", "(-", "(?", "(=", "(>", "(;", "<(", "\\(", "</", ">=",
                               "]=", "':", "'=", "0:", "8-"]

    init(emoticons: [String], minimumLength: Int, triggers: [String]) {
        self.minimumLength = minimumLength
        self.triggers = triggers.filter { !$0.isEmpty }
        var prefixes = Set<String>()
        for emoticon in emoticons {
            let characters = Array(emoticon)
            for length in stride(from: 1, to: min(characters.count, Limits.emoticonRunMaxLength + 1), by: 1) {
                prefixes.insert(String(characters[..<length]))
            }
        }
        self.prefixes = prefixes
    }

    //// Built once per catalog or settings change, off the typing path.
    //////////////////

    ////////////////////
    //// The run being typed
    /// The run is the text after the last whitespace. It suggests when it is long enough, holds
    /// at least one character that is not a letter or digit (so "ow" in "own" never matches
    // "owo"), is the start of an emoticon (case-sensitive) and was not dismissed with Esc.

    mutating func run(in buffer: String) -> String? {
        let run = String(buffer.split(omittingEmptySubsequences: false, whereSeparator: \.isWhitespace).last ?? "")
        if let dismissed, !run.hasPrefix(dismissed) { self.dismissed = nil }
        guard minimumLength > 0, run.count >= minimumLength, dismissed == nil,
              run.contains(where: { !$0.isLetter && !$0.isNumber }),
              prefixes.contains(run),
              !triggers.contains(where: run.hasPrefix),
              !Self.deniedStarts.contains(where: run.hasPrefix) else { return nil }
        return run
    }

    mutating func dismiss(_ run: String) {
        dismissed = run
    }

    //////////////////
}
