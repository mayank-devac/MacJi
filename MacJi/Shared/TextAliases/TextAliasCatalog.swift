//
//  TextAliasCatalog.swift
//  MacJi
//
//  Created: 2026-11-26
//  The built-in text aliases, in Settings order. docs/convert-symbols.md lists these and the
//  conversions left out on purpose.
//

import Foundation

enum TextAliasCatalog {
    ////////////////////
    //// Built-in aliases
    /// Every alias is on unless the user turns it off, except the emoticons, which start off
    /// (`offByDefault`). IDs are stored, so never rename one.
    /// Emoticons fire only after whitespace, so the "::" trigger, URLs and "note:)" stay intact.
    /// Emoticon spellings come from wooorm/emoticon (MIT, LICENSES/emoticon-MIT.txt), filtered
    /// to the ones that can't fire in ordinary text.
    // Longer aliases may build on shorter ones: "<->" is typed as "<-" (→ "←") then ">".

    static let all: [TextAlias] = arrows + math + symbols + emoticons

    /// IDs registered as the default `disabledTextAliases`. Once the user changes any switch the
    /// stored set wins, so an emoticon added in a later release starts on for them.
    static var offByDefault: [String] { emoticons.map(\.id) }

    private static let arrows: [TextAlias] = [
        TextAlias(id: "rightArrow", texts: ["->"], replacement: "→", group: .arrows, boundary: .anywhere),
        TextAlias(id: "leftArrow", texts: ["<-"], replacement: "←", group: .arrows, boundary: .anywhere),
        TextAlias(id: "leftRightArrow", texts: ["<->"], replacement: "↔", group: .arrows, boundary: .anywhere),
        TextAlias(id: "rightDoubleArrow", texts: ["=>"], replacement: "⇒", group: .arrows, boundary: .anywhere),
        TextAlias(id: "leftDoubleArrow", texts: ["<=="], replacement: "⇐", group: .arrows, boundary: .anywhere),
        TextAlias(id: "leftRightDoubleArrow", texts: ["<=>"], replacement: "⇔", group: .arrows, boundary: .anywhere),
    ]

    private static let math: [TextAlias] = [
        TextAlias(id: "notEqual", texts: ["!="], replacement: "≠", group: .math, boundary: .anywhere),
        TextAlias(id: "lessOrEqual", texts: ["<="], replacement: "≤", group: .math, boundary: .anywhere),
        TextAlias(id: "greaterOrEqual", texts: [">="], replacement: "≥", group: .math, boundary: .anywhere),
        TextAlias(id: "plusMinus", texts: ["+-"], replacement: "±", group: .math, boundary: .anywhere),
        TextAlias(id: "approximately", texts: ["~="], replacement: "≈", group: .math, boundary: .anywhere),
    ]

    private static let symbols: [TextAlias] = [
        TextAlias(id: "ellipsis", texts: ["..."], replacement: "…", group: .symbols, boundary: .anywhere),
        TextAlias(id: "copyright", texts: ["(c)", "(C)"], replacement: "©", group: .symbols, boundary: .afterSpace),
        TextAlias(id: "registered", texts: ["(r)", "(R)"], replacement: "®", group: .symbols, boundary: .afterSpace),
        TextAlias(id: "trademark", texts: ["(tm)", "(TM)"], replacement: "™", group: .symbols, boundary: .afterSpace),
    ]

    private static let emoticons: [TextAlias] = [
        emoticon("smile", [":)", ":-)", ":]", ":-]", "=)", "=-)"], "🙂"),
        emoticon("grin", [":D", ":-D", "=D", "=-D"], "😃"),
        emoticon("happy", ["^_^", ":\")", ":-\")", "=\")"], "😊"),
        emoticon("joy", [":')", ":'-)", ":'D", ":,)", ":,D"], "😂"),
        emoticon("laughing", ["X-D", "X-)"], "😆"),
        emoticon("sweatSmile", ["':)", "':D", ",:)", ",:D"], "😅"),
        emoticon("wink", [";)", ";-)", ";]", ";-]", ";D", ";-D"], "😉"),
        emoticon("innocent", ["O:)", "O:-)", "O:]", "O:D"], "😇"),
        emoticon("smilingImp", ["]:)", "]:-)", "]:D", "]:-D"], "😈"),
        emoticon("cool", ["B-)", "B-]"], "😎"),
        emoticon("kiss", [":*", ":-*"], "😘"),
        emoticon("tongue", [":P", ":-P", "=P", "=-P"], "😛"),
        emoticon("tongueWink", [";P", ";-P"], "😜"),
        emoticon("tongueClosedEyes", ["X-P"], "😝"),
        emoticon("neutral", [":|", ":-|"], "😐"),
        emoticon("unamused", ["-_-"], "😑"),
        emoticon("annoyed", [":$", ":-$", ":-S"], "😒"),
        emoticon("confused", [":-/", ":-\\"], "😕"),
        emoticon("surprised", [":O", ":-O", "=O", "=-O"], "😮"),
        emoticon("frown", [":(", ":-(", ":[", ":-[", "=(", "=-("], "🙁"),
        emoticon("sweat", ["':(", ",:("], "😓"),
        emoticon("cry", [":'(", ":'-(", ":'[", ":,(", "='("], "😢"),
        emoticon("sob", [":',(", ":,'("], "😭"),
        emoticon("angry", [">:(", ">:-(", ">:[", ">:-["], "😠"),
        emoticon("rage", [":@", ":-@"], "😡"),
        emoticon("imp", ["]:(", "]:-("], "👿"),
        emoticon("heart", ["<3"], "❤️"),
        emoticon("brokenHeart", ["</3", "<\\3"], "💔"),
    ]

    private static func emoticon(_ id: String, _ texts: [String], _ replacement: String) -> TextAlias {
        TextAlias(id: id, texts: texts, replacement: replacement, group: .emoticons, boundary: .afterSpace)
    }

    //// Left out of wooorm/emoticon (see docs/convert-symbols.md): lowercase letters (":p", "xD",
    //// "o:)") fire mid-word as in " :open"; digits ("8)", ":3", ":0") break lists and times;
    //// ":/", ":-" and "=/" break vim commands; "=*", "=[", "=|" and ">=(" break code; "B)" and
    //// "X)" break lettered lists.
    //////////////////
}
