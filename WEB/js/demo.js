/*
  demo.js · MacJi website · Created: 2026-11-26
  A working copy of MacJi's inline panels in the hero: type ::term for emoji or ##term for symbols
  in the note and pick one. Uses the app's own emoji.json and symbols.json and the same trigger
  rule and ranking as GlyphSearch.swift.
*/

(function () {
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
  var COLUMNS = 8;
  var RESULT_LIMIT = 64;
  var QUERY_MAX = 32;
  var SCRIPT = "Tell the team we ship today ::roc";
  var TARGET = "🚀";
  var TRIGGER = new RegExp("(^|[^A-Za-z0-9:#])(::|##)([A-Za-z0-9_+\\-]{0," + QUERY_MAX + "})$");

  var demo = document.getElementById("demo");
  if (!demo) return;
  var input = document.getElementById("demo-input");
  var mirror = document.getElementById("demo-mirror");
  var panel = document.getElementById("demo-panel");
  var grid = document.getElementById("demo-grid");
  var termLabel = document.getElementById("demo-term");
  var countLabel = document.getElementById("demo-count");
  var pickEmoji = document.getElementById("demo-pick-emoji");
  var pickName = document.getElementById("demo-pick-name");
  var copied = document.getElementById("demo-copied");
  var hint = document.getElementById("demo-hint");
  var live = document.getElementById("demo-live");
  var doc = document.getElementById("demo-doc");
  var reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;

  var state = { open: false, panel: null, start: -1, results: [], selected: 0, dismissedAt: -1 };
  var autoplay = { running: false, timers: [] };

  ////////////////////
  //// Catalog and ranking
  /// Mirrors GlyphCatalog + GlyphSearch: 0 exact alias · 1 alias prefix · 2 word prefix · 3 anywhere.
  /// Each panel's data loads once, the symbols only when "##" is first typed.
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

  ////////////////////
  //// Trigger tracking
  /// Same rule as InlineTrigger: "::" or "##" not glued to a letter or digit (so std::string and
  /// a##b stay quiet), then letters, digits, _ + or -. A space or punctuation ends the term.

  function readTrigger() {
    var caret = input.selectionStart;
    if (caret !== input.selectionEnd) return null;
    var match = TRIGGER.exec(input.value.slice(0, caret));
    if (!match) return null;
    return { trigger: match[2], start: caret - match[3].length - 2, term: match[3], caret: caret };
  }

  function update() {
    var trigger = readTrigger();
    if (!trigger || trigger.start === state.dismissedAt) {
      if (!trigger) state.dismissedAt = -1;
      close();
      return;
    }
    var panelData = PANELS[trigger.trigger];
    if (!panelData.catalog) {
      load(panelData).then(update, close);
      return;
    }
    state.panel = panelData;
    state.start = trigger.start;
    state.results = search(panelData, trigger.term);
    state.selected = 0;
    termLabel.textContent = trigger.trigger + trigger.term;
    render();
    open();
    place(trigger.start);
  }

  //// Esc remembers where its trigger began so the panel stays shut until that trigger is gone.
  //////////////////

  ////////////////////
  //// Panel

  function render() {
    grid.textContent = "";
    countLabel.textContent = state.results.length || "";
    if (!state.results.length) {
      var empty = document.createElement("p");
      empty.className = "panel-empty";
      empty.textContent = "No " + state.panel.noun + " match. Keep typing or press Esc.";
      grid.appendChild(empty);
      pickEmoji.textContent = "";
      pickName.textContent = "";
      announce("No " + state.panel.noun + " match");
      return;
    }
    state.results.forEach(function (entry, index) {
      var cell = document.createElement("button");
      cell.type = "button";
      cell.className = "cell";
      cell.id = "demo-cell-" + index;
      cell.tabIndex = -1;
      cell.setAttribute("role", "option");
      cell.setAttribute("aria-label", entry.name);
      cell.textContent = entry.emoji;
      cell.addEventListener("mousedown", function (event) {
        event.preventDefault();
        state.selected = index;
        insert();
      });
      grid.appendChild(cell);
    });
    select(0);
    announce(state.results.length + " " + state.panel.noun + ". " + state.results[0].name + " selected.");
  }

  function select(index) {
    var previous = grid.querySelector(".cell.on");
    if (previous) previous.classList.remove("on");
    state.selected = index;
    var cell = document.getElementById("demo-cell-" + index);
    if (!cell) return;
    cell.classList.add("on");
    cell.setAttribute("aria-selected", "true");
    if (previous && previous !== cell) previous.removeAttribute("aria-selected");
    input.setAttribute("aria-activedescendant", cell.id);
    var entry = state.results[index];
    pickEmoji.textContent = entry.emoji;
    pickName.textContent = entry.name;
    var top = cell.offsetTop - grid.offsetTop;
    if (top < grid.scrollTop) grid.scrollTop = top;
    if (top + cell.offsetHeight > grid.scrollTop + grid.clientHeight) {
      grid.scrollTop = top + cell.offsetHeight - grid.clientHeight;
    }
  }

  function move(dx, dy) {
    var count = state.results.length;
    if (!count) return;
    var next = state.selected + dx + dy * COLUMNS;
    if (dy !== 0 && (next < 0 || next >= count)) return;
    select(Math.max(0, Math.min(count - 1, next)));
  }

  function open() {
    if (state.open) return;
    state.open = true;
    panel.hidden = false;
    input.setAttribute("aria-expanded", "true");
    requestAnimationFrame(function () { panel.classList.add("shown"); });
  }

  function close() {
    if (!state.open) return;
    state.open = false;
    panel.classList.remove("shown");
    panel.hidden = true;
    input.setAttribute("aria-expanded", "false");
    input.removeAttribute("aria-activedescendant");
  }

  //// Under the trigger like the real panel under the caret; clamped inside the note.
  function place(start) {
    mirror.textContent = input.value.slice(0, start) || "​";
    var lineBox = input.getBoundingClientRect();
    var docBox = doc.getBoundingClientRect();
    var x = lineBox.left - docBox.left + mirror.offsetWidth - input.scrollLeft;
    var maxX = doc.clientWidth - panel.offsetWidth - 12;
    panel.style.left = Math.max(12, Math.min(x - 14, maxX)) + "px";
    panel.style.top = lineBox.bottom - docBox.top + 8 + "px";
  }

  //////////////////

  ////////////////////
  //// Actions: Return inserts, Shift-Return copies, Esc closes

  function insert() {
    var entry = state.results[state.selected];
    if (!entry) return;
    var caret = input.selectionStart;
    var value = input.value;
    input.value = value.slice(0, state.start) + entry.emoji + value.slice(caret);
    var after = state.start + entry.emoji.length;
    input.setSelectionRange(after, after);
    float(entry.emoji, state.start);
    close();
    announce(entry.name + " inserted");
  }

  function copy() {
    var entry = state.results[state.selected];
    if (!entry) return;
    var done = function (ok) {
      copied.textContent = ok ? "Copied " + entry.emoji : "Couldn't copy";
      copied.classList.add("shown");
      announce(ok ? entry.name + " copied" : "Couldn't copy");
      setTimeout(function () {
        copied.classList.remove("shown");
        close();
      }, 900);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(entry.emoji).then(function () { done(true); }, function () { done(false); });
    } else {
      done(false);
    }
  }

  //// A small lift of the inserted emoji, so the swap is easy to see.
  function float(emoji, start) {
    if (reduceMotion) return;
    mirror.textContent = input.value.slice(0, start) || "​";
    var bubble = document.createElement("span");
    bubble.className = "float";
    bubble.textContent = emoji;
    bubble.setAttribute("aria-hidden", "true");
    var lineBox = input.getBoundingClientRect();
    var docBox = doc.getBoundingClientRect();
    bubble.style.left = lineBox.left - docBox.left + mirror.offsetWidth - input.scrollLeft + "px";
    bubble.style.top = lineBox.top - docBox.top + "px";
    doc.appendChild(bubble);
    setTimeout(function () { bubble.remove(); }, 1100);
  }

  function announce(text) {
    live.textContent = text;
  }

  input.addEventListener("keydown", function (event) {
    if (autoplay.running && event.isTrusted) stopAutoplay();
    if (!state.open) return;
    var handled = true;
    if (event.key === "ArrowLeft") move(-1, 0);
    else if (event.key === "ArrowRight") move(1, 0);
    else if (event.key === "ArrowUp") move(0, -1);
    else if (event.key === "ArrowDown") move(0, 1);
    else if (event.key === "Enter" && event.shiftKey) copy();
    else if (event.key === "Enter") insert();
    else if (event.key === "Escape") {
      state.dismissedAt = state.start;
      close();
    } else handled = false;
    if (handled) event.preventDefault();
  });

  input.addEventListener("input", update);
  input.addEventListener("click", update);
  input.addEventListener("blur", function () {
    setTimeout(function () {
      if (document.activeElement !== input) close();
    }, 120);
  });
  input.addEventListener("pointerdown", function () { if (autoplay.running) stopAutoplay(); });
  window.addEventListener("resize", function () { if (state.open) place(state.start); });

  //////////////////

  ////////////////////
  //// Ways in
  /// The whole note is a text area, as in a real editor, and the chips under it type a term.
  // Clicks inside the panel never take the focus, just like the app's panel.

  function writeAtEnd(value) {
    if (input.disabled) return;
    if (autoplay.running) stopAutoplay();
    input.value = value;
    input.focus({ preventScroll: true });
    input.setSelectionRange(value.length, value.length);
    state.dismissedAt = -1;
    update();
  }

  panel.addEventListener("mousedown", function (event) { event.preventDefault(); });

  doc.addEventListener("click", function (event) {
    if (event.target.closest("input, #demo-panel") || String(window.getSelection())) return;
    writeAtEnd(input.value);
  });

  //// Keeps the sentence already in the note when the new term still fits on its line.
  document.querySelectorAll("[data-try]").forEach(function (chip) {
    chip.addEventListener("click", function () {
      var term = chip.dataset.try;
      var kept = input.value.replace(/(::|##)[A-Za-z0-9_+\-]*$/, "").trim();
      var line = kept ? kept + " " + term : term;
      mirror.textContent = line;
      writeAtEnd(mirror.offsetWidth < input.clientWidth ? line : term);
    });
  });

  //////////////////

  ////////////////////
  //// Autoplay
  /// Once the note scrolls into view, type the README's example, pick 🚀 and press Return.
  // Any real key or click hands control to the visitor at once.

  function later(fn, ms) {
    autoplay.timers.push(setTimeout(fn, ms));
  }

  function press(key) {
    input.dispatchEvent(new KeyboardEvent("keydown", { key: key, bubbles: true, cancelable: true }));
  }

  function stopAutoplay() {
    autoplay.timers.forEach(clearTimeout);
    autoplay.timers = [];
    finish();
  }

  function finish() {
    autoplay.running = false;
    demo.classList.remove("playing");
    hint.classList.add("shown");
  }

  function play() {
    autoplay.running = true;
    demo.classList.add("playing");
    input.value = "";
    var at = 300;
    SCRIPT.split("").forEach(function (character, index) {
      at += character === " " ? 90 : 40 + Math.random() * 55;
      later(function () {
        input.value = SCRIPT.slice(0, index + 1);
        input.setSelectionRange(input.value.length, input.value.length);
        update();
      }, at);
    });
    at += 650;
    later(function stepToTarget() {
      var index = state.results.findIndex(function (entry) { return entry.emoji === TARGET; });
      if (index > state.selected) {
        press("ArrowRight");
        later(stepToTarget, 380);
        return;
      }
      later(function () {
        press("Enter");
        later(finish, 500);
      }, 520);
    }, at);
  }

  function showResult() {
    input.value = SCRIPT.replace("::roc", TARGET);
    finish();
  }

  load(PANELS["::"])
    .then(function () {
      demo.classList.add("ready");
      if (reduceMotion || !("IntersectionObserver" in window)) {
        showResult();
        return;
      }
      var seen = new IntersectionObserver(function (entries) {
        if (!entries[0].isIntersecting) return;
        seen.disconnect();
        if (document.activeElement !== input && !input.value) play();
      }, { threshold: 0.6 });
      seen.observe(demo);
    })
    .catch(function () {
      input.disabled = true;
      input.placeholder = "The live demo couldn't load. Reload the page to try again.";
      hint.hidden = true;
    });

  //// Autoplay only runs for an empty note the visitor hasn't touched.
  //////////////////
})();
