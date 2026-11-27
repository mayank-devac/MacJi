/*
  demo.js · MacJi website · Created: 2026-11-26
  A working copy of MacJi's inline panels in the hero: type ::term for emoji or ##term for symbols
  in the note and pick one, with the app's trigger rule. Data and ranking are in glyphs.js.
*/

(function () {
  "use strict";

  var glyphs = window.MacJiGlyphs;
  var PANELS = glyphs.PANELS;
  var OPENING = "Tell the team we ship today ";
  /// Typed when GitHub can't name the latest release, or is too slow to hold the demo up for.
  var FALLBACK_VERSION = "0.3.0";
  var VERSION = /^\d+\.\d+\.\d+$/;
  var RELEASE_WAIT_MS = 1500;
  var TRIGGER = new RegExp("(^|[^A-Za-z0-9:#])(::|##)([A-Za-z0-9_+\\-]{0," + glyphs.QUERY_MAX + "})$");

  var demo = document.getElementById("demo");
  if (!demo) return;
  var input = document.getElementById("demo-input");
  var mirror = document.getElementById("demo-mirror");
  var panel = document.getElementById("demo-panel");
  var grid = document.getElementById("demo-grid");
  var termLabel = document.getElementById("demo-term");
  var copied = document.getElementById("demo-copied");
  var hint = document.getElementById("demo-hint");
  var live = document.getElementById("demo-live");
  var doc = document.getElementById("demo-doc");
  var reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;

  var state = { open: false, start: -1, dismissedAt: -1 };
  var autoplay = { running: false, timers: [] };
  var results = window.MacJiPanelGrid({
    grid: grid,
    input: input,
    count: document.getElementById("demo-count"),
    pickEmoji: document.getElementById("demo-pick-emoji"),
    pickName: document.getElementById("demo-pick-name"),
    announce: announce,
    pick: insert,
  });

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
      glyphs.load(panelData).then(update, close);
      return;
    }
    state.start = trigger.start;
    termLabel.textContent = trigger.trigger + trigger.term;
    results.render(glyphs.search(panelData, trigger.term), panelData.noun);
    open();
    place(trigger.start);
  }

  //// Esc remembers where its trigger began so the panel stays shut until that trigger is gone.
  //////////////////

  ////////////////////
  //// Panel

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
    var entry = results.current();
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
    var entry = results.current();
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
    if (event.key === "Enter" && event.shiftKey) copy();
    else if (event.key === "Enter") insert();
    else if (event.key === "Escape") {
      state.dismissedAt = state.start;
      close();
    } else if (!results.arrow(event.key)) return;
    event.preventDefault();
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
  /// Once the note scrolls into view, type the README's example, pick 🚀 and press Return, then
  /// carry on with "##" to put a symbol in the same line.
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

  function typeText(text, done) {
    var at = 0;
    text.split("").forEach(function (character) {
      at += character === " " ? 90 : 40 + Math.random() * 55;
      later(function () {
        input.value += character;
        input.setSelectionRange(input.value.length, input.value.length);
        // A narrow note doesn't follow a scripted caret by itself.
        input.scrollLeft = input.scrollWidth;
        update();
      }, at);
    });
    later(done, at);
  }

  function pick(glyph, done) {
    if (results.indexOf(glyph) > results.index()) {
      press("ArrowRight");
      later(function () { pick(glyph, done); }, 380);
      return;
    }
    later(function () {
      press("Enter");
      // Let the inserted glyph's lift play out before the line moves on.
      later(done, 600);
    }, 520);
  }

  function playStep(steps, number) {
    var step = steps[number];
    if (!step) {
      later(finish, 500);
      return;
    }
    var next = function () { playStep(steps, number + 1); };
    typeText(step.type, function () {
      if (!step.pick) {
        next();
        return;
      }
      later(function () { pick(step.pick, next); }, 650);
    });
  }

  //// What autoplay types, in order; "pick" is the glyph it takes from the panel that opens.
  function play(versions) {
    var steps = [
      { type: OPENING + "::roc", pick: "🚀" },
      { type: " " + versions.from + " ##rarr", pick: "→" },
      { type: " " + versions.to },
    ];
    autoplay.running = true;
    demo.classList.add("playing");
    input.value = "";
    later(function () { playStep(steps, 0); }, 300);
  }

  function showResult(versions) {
    input.value = OPENING + "🚀 " + versions.from + " → " + versions.to;
    finish();
  }

  ////////////////////
  //// Release numbers
  /// The line reads "previous → latest", following the latest GitHub release (release.js).
  // The previous number is one step back, as bump-version.sh counts: 0.3.1 gives "0.3.0 → 0.3.1",
  // 0.3.0 gives "0.2 → 0.3" and 1.0.0 gives "0.x → 1.0".

  function versionStep(version) {
    var parts = version.split(".").map(Number);
    var major = parts[0];
    var minor = parts[1];
    var patch = parts[2];
    if (patch > 0) return { from: major + "." + minor + "." + (patch - 1), to: version };
    var from = minor > 0 ? major + "." + (minor - 1) : major - 1 + ".x";
    return { from: from, to: major + "." + minor };
  }

  function latestVersions() {
    var timeout = new Promise(function (resolve) { setTimeout(resolve, RELEASE_WAIT_MS); });
    return Promise.race([window.MacJiRelease.latest(), timeout]).then(function (release) {
      var known = release && VERSION.test(release.version);
      return versionStep(known ? release.version : FALLBACK_VERSION);
    });
  }

  //////////////////

  function untouched() {
    return document.activeElement !== input && !input.value;
  }

  glyphs.load(PANELS["::"])
    .then(function () {
      demo.classList.add("ready");
      if (reduceMotion || !("IntersectionObserver" in window)) {
        latestVersions().then(function (versions) {
          if (untouched()) showResult(versions);
        });
        return;
      }
      var seen = new IntersectionObserver(function (entries) {
        if (!entries[0].isIntersecting) return;
        seen.disconnect();
        // Symbols load first, so the "##" panel never opens late under the script.
        Promise.all([latestVersions(), glyphs.load(PANELS["##"])]).then(function (ready) {
          if (untouched()) play(ready[0]);
        }, finish);
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
