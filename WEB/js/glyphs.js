/*
  glyphs.js · MacJi website · Created: 2026-11-27
  The inline panels' catalogs and ranking for the website, from the app's own emoji.json and
  symbols.json, with the same ranking as GlyphSearch.swift.
*/

window.MacJiGlyphs = (function () {
  "use strict";

  /// One entry per panel: its data file, what an empty term shows, and the word for its glyphs.
  var PANELS = {
    "::": {
      url: "assets/data/emoji.json", noun: "emoji",
      favourites: ["🚀", "🎉", "❤️", "👍", "😂", "✨", "🔥", "✅", "👀", "🙏", "🥳", "💯", "👋", "🤔", "😎", "🫶"],
    },
    "##": {
      url: "assets/data/symbols.json", noun: "symbols",
      favourites: ["→", "←", "↔", "⇒", "≠", "≈", "±", "×", "÷", "°", "€", "£", "©", "™", "⌘", "⌥"],
    },
  };
  var RESULT_LIMIT = 64;
  var QUERY_MAX = 32;

  ////////////////////
  //// Catalog and ranking
  /// Mirrors GlyphCatalog + GlyphSearch: 0 exact alias · 1 alias prefix · 2 word prefix · 3 anywhere.
  /// Each panel's data loads once, when something first needs it.
  // Buckets keep catalog order inside each rank, exactly like the app, so "roc" shows 🪨 then 🚀.

  function load(panel) {
    if (panel.loading) return panel.loading;
    panel.loading = fetch(panel.url)
      .then(function (response) {
        if (!response.ok) throw new Error(panel.url + " " + response.status);
        return response.json();
      })
      .then(function (items) {
        panel.byGlyph = {};
        panel.catalog = items.map(function (item) {
          var words = [item.description].concat(item.tags).join(" ").toLowerCase();
          var entry = {
            emoji: item.emoji,
            name: item.description.charAt(0).toUpperCase() + item.description.slice(1),
            aliases: item.aliases.map(function (alias) { return alias.toLowerCase(); }),
            keywords: [item.description].concat(item.aliases, item.tags).join(" ").toLowerCase(),
            words: words.split(/[^a-z0-9]+/).filter(Boolean),
          };
          panel.byGlyph[item.emoji] = entry;
          return entry;
        });
      });
    return panel.loading;
  }

  function rank(entry, term) {
    if (entry.aliases.indexOf(term) > -1) return 0;
    if (entry.aliases.some(function (alias) { return alias.indexOf(term) === 0; })) return 1;
    if (entry.words.some(function (word) { return word.indexOf(term) === 0; })) return 2;
    return 3;
  }

  function search(panel, query) {
    var term = query.toLowerCase();
    if (!term) {
      return panel.favourites.map(function (glyph) { return panel.byGlyph[glyph]; }).filter(Boolean);
    }
    var buckets = [[], [], [], []];
    panel.catalog.forEach(function (entry) {
      if (entry.keywords.indexOf(term) > -1) buckets[rank(entry, term)].push(entry);
    });
    return buckets[0].concat(buckets[1], buckets[2], buckets[3]).slice(0, RESULT_LIMIT);
  }

  //// One term only: the trigger ends at the first space, so multi-term queries can't happen inline.
  //////////////////

  return { PANELS: PANELS, QUERY_MAX: QUERY_MAX, load: load, search: search };
})();
