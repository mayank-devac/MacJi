/*
  anywhere.js · MacJi website · Created: 2026-11-27
  Type :: or ## anywhere on the home page: the inline panel opens at the pointer, and Return sticks
  the pick onto the page (js/stickers.js). On wide screens a corner dock says so.
*/

(function () {
  "use strict";

  var glyphs = window.MacJiGlyphs;
  var stickers = window.MacJiStickers;
  var box = document.getElementById("anywhere");
  if (!box) return;
  var input = document.getElementById("anywhere-input");
  var panel = document.getElementById("anywhere-panel");
  var term = document.getElementById("anywhere-term");
  var copied = document.getElementById("anywhere-copied");
  var live = document.getElementById("anywhere-live");
  var dock = document.getElementById("dock");
  var dockText = document.getElementById("dock-text");
  var dockClear = document.getElementById("dock-clear");

  var TERM = new RegExp("^(::|##)([A-Za-z0-9_+\\-]{0," + glyphs.QUERY_MAX + "})$");
  //// The second ":" or "#" must follow the first within this long.
  var PAIR_MS = 1500;
  var MARGIN = 12;
  var NAV = 72;
  //// From the anchor to the nearer edge of the typed text.
  var LIFT = 20;
  //// How far the next pick lands to the right when the pointer hasn't moved.
  var ADVANCE = 84;
  //// The dock waits until the visitor has scrolled this share of the window, clear of the hero.
  var DOCK_AFTER = 0.5;

  //// js/pointer.js hides its dot while typing, as macOS does, until the mouse moves.
  function typing(active) {
    document.dispatchEvent(new CustomEvent("macji:typing", { detail: active }));
  }

  var results = window.MacJiPanelGrid({
    grid: document.getElementById("anywhere-grid"),
    input: input,
    count: document.getElementById("anywhere-count"),
    pickEmoji: document.getElementById("anywhere-pick-emoji"),
    pickName: document.getElementById("anywhere-pick-name"),
    announce: function (text) { live.textContent = text; },
    pick: insert,
  });

  var pointer = null;
  var anchor = { x: 0, y: 0 };
  //// Where the last pick landed, until the pointer moves again.
  var typed = null;
  var returnTo = null;
  var keys = { last: "", time: 0 };
  var copyTimer = 0;
  var count = 0;
  var footerSeen = false;

  function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
  }

  ////////////////////
  //// The panel
  /// The typed text sits at the anchor like text at a caret, with the panel under it, or above it
  /// near the bottom of the window.

  function place() {
    var width = document.documentElement.clientWidth;
    var left = clamp(anchor.x - 24, MARGIN, width - box.offsetWidth - MARGIN);
    var below = anchor.y - LIFT + box.offsetHeight + MARGIN <= window.innerHeight;
    var top = below ? anchor.y - LIFT : anchor.y + LIFT - box.offsetHeight;
    box.classList.toggle("above", !below);
    box.style.left = left + "px";
    box.style.top = Math.max(MARGIN, top) + "px";
  }

  function update() {
    var match = TERM.exec(input.value);
    if (!match) {
      close(true);
      return;
    }
    var data = glyphs.PANELS[match[1]];
    input.size = input.value.length + 1;
    term.textContent = match[1] === "##" ? "Symbols" : "Emoji";
    var show = function () {
      //// The text may have moved on, or closed, while the catalog loaded.
      if (box.hidden || input.value !== match[0]) return;
      results.render(glyphs.search(data, match[2]), data.noun);
      place();
    };
    //// Shown at once when possible, so a quick Return always picks from what was just typed.
    if (data.catalog) {
      show();
      return;
    }
    results.clear();
    glyphs.load(data).then(show, function () {
      live.textContent = "The " + data.noun + " couldn't load.";
      close(true);
    });
  }

  function open(trigger, x, y) {
    returnTo = document.activeElement;
    anchor = {
      x: clamp(x, 44, document.documentElement.clientWidth - 44),
      y: clamp(y, NAV, window.innerHeight - 44),
    };
    input.value = trigger;
    results.clear();
    box.hidden = false;
    input.setAttribute("aria-expanded", "true");
    place();
    input.focus({ preventScroll: true });
    input.setSelectionRange(trigger.length, trigger.length);
    requestAnimationFrame(function () { panel.classList.add("shown"); });
    update();
  }

  //// `restore` hands the focus back; it is false when the visitor has already moved elsewhere.
  function close(restore) {
    if (box.hidden) return;
    clearTimeout(copyTimer);
    copied.classList.remove("shown");
    panel.classList.remove("shown");
    box.hidden = true;
    input.setAttribute("aria-expanded", "false");
    input.removeAttribute("aria-activedescendant");
    typing(false);
    if (!restore) return;
    if (returnTo && returnTo !== document.body && returnTo.isConnected) returnTo.focus({ preventScroll: true });
    else input.blur();
  }

  function insert() {
    var entry = results.current();
    var match = TERM.exec(input.value);
    if (!entry || !match) return;
    var alias = entry.aliases[0] || match[2];
    close(true);
    stickers.add(entry.emoji, entry.name, match[1] + alias, anchor.x, anchor.y);
    typed = anchor;
    live.textContent = entry.name + " stuck on the page";
  }

  function copy() {
    var entry = results.current();
    if (!entry) return;
    var done = function (ok) {
      copied.textContent = ok ? "Copied " + entry.emoji : "Couldn't copy";
      copied.classList.add("shown");
      live.textContent = ok ? entry.name + " copied" : "Couldn't copy";
      copyTimer = setTimeout(function () { close(true); }, 900);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(entry.emoji).then(function () { done(true); }, function () { done(false); });
    } else {
      done(false);
    }
  }

  input.addEventListener("input", update);
  input.addEventListener("keydown", function (event) {
    if (event.isComposing) return;
    if (!/^(Shift|Alt|AltGraph|Control|Meta|CapsLock)$/.test(event.key)) typing(true);
    if (event.key === "Enter" && event.shiftKey) copy();
    else if (event.key === "Enter") insert();
    else if (event.key === "Escape") close(true);
    else if (!results.arrow(event.key)) {
      //// Tab closes the panel and moves on as usual.
      if (event.key === "Tab") close(true);
      return;
    }
    event.preventDefault();
  });
  input.addEventListener("blur", function () {
    setTimeout(function () {
      if (document.activeElement !== input) close(false);
    }, 120);
  });
  panel.addEventListener("mousedown", function (event) { event.preventDefault(); });
  window.addEventListener("resize", function () { if (!box.hidden) place(); });

  //////////////////

  ////////////////////
  //// Listening to the whole page
  /// Only the last two characters are kept, and only to spot "::" or "##". Typing in a field is
  /// left alone, and a pair glued to a letter or digit stays quiet, as in the app.

  function lightKeys(typedSoFar) {
    var half = /(^|[^A-Za-z0-9:#])[:#]$/.test(typedSoFar);
    dock.classList.toggle("half", half);
  }

  document.addEventListener("keydown", function (event) {
    if (!box.hidden || event.defaultPrevented || event.metaKey || (event.ctrlKey && !event.altKey)) return;
    if (/^(Shift|Alt|AltGraph|Control|CapsLock)$/.test(event.key)) return;
    var inField = event.target.closest && event.target.closest("input, textarea, select, [contenteditable]");
    if (inField || event.key.length !== 1) {
      keys.last = "";
      lightKeys("");
      return;
    }
    if (event.timeStamp - keys.time > PAIR_MS) keys.last = "";
    keys.time = event.timeStamp;
    keys.last = (keys.last + event.key).slice(-3);
    lightKeys(keys.last);
    var match = /(^|[^A-Za-z0-9:#])(::|##)$/.exec(keys.last);
    if (!match) return;
    event.preventDefault();
    keys.last = "";
    var at = typed ? { x: typed.x + ADVANCE, y: typed.y } : pointer;
    if (at && at.x > document.documentElement.clientWidth - 44) at = { x: 60, y: at.y + ADVANCE };
    at = at || { x: window.innerWidth / 2, y: window.innerHeight / 2 };
    open(match[2], at.x, at.y);
    typing(true);
  });

  document.addEventListener("pointermove", function (event) {
    if (event.pointerType === "touch") return;
    pointer = { x: event.clientX, y: event.clientY };
    typed = null;
  }, { passive: true });

  //////////////////

  ////////////////////
  //// The dock
  /// A corner pill that says the page listens, counts the stickers and clears them. It arrives
  /// below the first screen, stays while there are stickers to clear, and steps aside for the
  /// footer.

  function describe() {
    if (count) dockText.textContent = count + (count === 1 ? " sticker" : " stickers") + " · drag or flick";
    else dockText.textContent = "Type it anywhere";
    dockClear.hidden = !count;
  }

  function showDock() {
    var arrived = count > 0 || window.scrollY > window.innerHeight * DOCK_AFTER;
    dock.classList.toggle("away", footerSeen || !arrived);
  }

  //// Opened from the dock, picks land around the middle of the window, a little apart.
  document.getElementById("dock-open").addEventListener("click", function () {
    open("::",
      window.innerWidth / 2 + (Math.random() - 0.5) * 320,
      window.innerHeight * 0.4 + (Math.random() - 0.5) * 160);
    typed = null;
  });

  dockClear.addEventListener("click", function () {
    stickers.clear();
    typed = null;
    document.getElementById("dock-open").focus({ preventScroll: true });
  });

  stickers.onCount(function (total) {
    count = total;
    describe();
    showDock();
  });
  window.addEventListener("scroll", showDock, { passive: true });
  describe();
  showDock();
  dock.hidden = false;

  var footer = document.querySelector(".footer");
  if (footer && "IntersectionObserver" in window) {
    new IntersectionObserver(function (entries) {
      footerSeen = entries[0].isIntersecting;
      showDock();
    }).observe(footer);
  }

  //////////////////
})();
