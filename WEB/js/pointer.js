/*
  pointer.js · MacJi website · Created: 2026-11-26
  The iPadOS-style pointer and button parallax. A dot that melts into a platter behind small
  controls, disappears over large buttons, and turns into a text beam over text.
  Ported from the Octopus site (WEB/script.js). Mouse and trackpad only.
*/

(function () {
  "use strict";

  var precise = matchMedia("(hover: hover) and (pointer: fine)");
  var calm = matchMedia("(prefers-reduced-motion: reduce)");
  var forced = matchMedia("(forced-colors: active)");
  if (!precise.matches || calm.matches || forced.matches) return;

  var DOT = 18;
  var BEAM_WIDTH = 3;
  var BEAM_MAX = 60;
  var PLATTER_PAD = 4;
  var CELL_PAD = 1;
  //// How far a platter leans after the pointer, and how far a [data-fx] button leans (as a
  //// share of its data-fx pixels). Low values here make controls feel sticky or jumpy.
  var MAGNET = 0.22;
  var MAGNET_MAX = 6;
  var LEAN = 0.5;
  var ATTACH = 0.24;
  var RETURN = 0.32;
  var FLICK = 30;
  var FRAME_MS = 1000 / 60;
  var SETTLE_MS = 450;
  //// Large buttons never take hold of the pointer.
  var BUTTON = ".btn, button.popper";
  var PLATTER = "a, button, summary, [role='option']";
  var TEXT_AREA = ".doc";

  var root = document.documentElement;
  var el = document.createElement("div");
  el.className = "ptr";
  el.setAttribute("aria-hidden", "true");
  document.body.appendChild(el);

  var px = 0;
  var py = 0;
  var hover = { mode: "dot" };
  var seen = false;
  var away = false;
  var stale = false;
  var under = null;
  var now = { x: 0, y: 0, w: DOT, h: DOT, r: DOT / 2, o: 0 };
  var anchor = { x: 0, y: 0 };
  var previous = {};
  var drawn = {};
  var raf = 0;
  var last = 0;
  var awakeUntil = 0;

  function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
  }

  ////////////////////
  //// What is under the pointer
  /// Large buttons hide the dot, other controls get a platter, selectable text gets a beam.
  // The beam appears only over actual glyphs (and anywhere in the demo note, which is a text
  // area), like the system I-beam, not across a paragraph's empty space.

  function overText(node) {
    var range = document.createRange();
    return Array.prototype.some.call(node.childNodes, function (child) {
      if (child.nodeType !== Node.TEXT_NODE || !child.textContent.trim()) return false;
      range.selectNodeContents(child);
      return Array.prototype.some.call(range.getClientRects(), contains);
    });
  }

  function contains(box) {
    return px >= box.left && px <= box.right && py >= box.top && py <= box.bottom;
  }

  function cornerRadius(control, width, height, pad) {
    var value = getComputedStyle(control).borderTopLeftRadius;
    var half = Math.min(width, height) / 2;
    if (value.indexOf("%") > -1) return half;
    return Math.min(half, (parseFloat(value) || 0) + pad);
  }

  function beam(node) {
    var field = node.closest(TEXT_AREA) ? document.querySelector(TEXT_AREA + " input") : node;
    var size = parseFloat(getComputedStyle(field || node).fontSize);
    return { mode: "beam", height: Math.min(BEAM_MAX, Math.round(size * 1.2)) };
  }

  function resolve(node) {
    if (!node || !node.closest) return { mode: "dot" };
    if (node.closest(BUTTON)) return { mode: "button" };
    var control = node.closest(PLATTER);
    if (control) return { mode: "platter", el: control };
    var style = getComputedStyle(node);
    if ((style.userSelect || style.webkitUserSelect) === "none") return { mode: "dot" };
    if (node.closest("input, textarea, " + TEXT_AREA) || overText(node)) return beam(node);
    return { mode: "dot" };
  }

  //// Controls win over text, so link and button labels never show a beam.
  //////////////////

  ////////////////////
  //// Motion
  /// The dot moves with the pointer at any speed; platters ease in, and only the leftover
  /// distance from a control eases out. A fast flick passes over controls as a dot.
  // Smoothing is scaled by frame time, so 60 Hz and 120 Hz displays move at the same speed.
  // The page is measured at most once a frame, and always before anything is written.
  // The loop stops once everything has settled, so an idle page costs nothing.

  function target() {
    var t = { x: px, y: py, w: DOT, h: DOT, r: DOT / 2, o: away || !seen ? 0 : 1 };
    if (hover.mode === "beam") {
      t.w = BEAM_WIDTH;
      t.h = hover.height;
      t.r = BEAM_WIDTH / 2;
    }
    if (hover.mode === "button") t.o = 0;
    if (!hover.el) return t;
    //// A wrapped link has one box per line; hug the line under the pointer.
    var box = Array.prototype.find.call(hover.el.getClientRects(), contains) || hover.el.getBoundingClientRect();
    var pad = hover.el.getAttribute("role") === "option" ? CELL_PAD : PLATTER_PAD;
    var cx = box.left + box.width / 2;
    var cy = box.top + box.height / 2;
    t.el = hover.el;
    t.cx = cx;
    t.cy = cy;
    t.x = cx + clamp((px - cx) * MAGNET, -MAGNET_MAX, MAGNET_MAX);
    t.y = cy + clamp((py - cy) * MAGNET, -MAGNET_MAX, MAGNET_MAX);
    t.w = box.width + pad * 2;
    t.h = box.height + pad * 2;
    t.r = cornerRadius(hover.el, t.w, t.h, pad);
    return t;
  }

  function ease(from, to, perFrame, elapsed) {
    return from + (to - from) * (1 - Math.pow(1 - perFrame, elapsed / FRAME_MS));
  }

  function look(flicking) {
    if (flicking) {
      hover = { mode: "dot" };
    } else {
      var node = under && under.isConnected ? under : document.elementFromPoint(px, py);
      hover = resolve(node);
    }
    //// A flick leaves the page unread, so look again once the pointer slows down.
    stale = flicking;
  }

  //// Skips unchanged values, so a moving dot costs a translate and no layout.
  function write(property, value) {
    if (drawn[property] === value) return;
    drawn[property] = value;
    el.style[property] = value;
  }

  function frame(time) {
    var elapsed = last ? Math.min(64, time - last) : FRAME_MS;
    last = time;
    var travelled = Math.hypot(px - anchor.x, py - anchor.y) * (FRAME_MS / elapsed);
    if (stale || (hover.el && !hover.el.isConnected)) look(travelled > FLICK);
    var t = target();
    if (t.el) {
      //// A control that moves (page scroll, its own spring) carries the pointer with it.
      if (t.el === previous.el) {
        now.x += t.cx - previous.cx;
        now.y += t.cy - previous.cy;
      }
      now.x = ease(now.x, t.x, ATTACH, elapsed);
      now.y = ease(now.y, t.y, ATTACH, elapsed);
    } else {
      now.x = t.x + ease(now.x - anchor.x, 0, RETURN, elapsed);
      now.y = t.y + ease(now.y - anchor.y, 0, RETURN, elapsed);
    }
    previous = t;
    anchor.x = px;
    anchor.y = py;
    var morph = t.el ? ATTACH : RETURN;
    now.w = ease(now.w, t.w, morph, elapsed);
    now.h = ease(now.h, t.h, morph, elapsed);
    now.r = ease(now.r, t.r, morph, elapsed);
    now.o = ease(now.o, t.o, morph, elapsed);

    if (el.dataset.mode !== hover.mode) el.dataset.mode = hover.mode;
    write("translate", (now.x - now.w / 2).toFixed(2) + "px " + (now.y - now.h / 2).toFixed(2) + "px");
    write("width", now.w.toFixed(2) + "px");
    write("height", now.h.toFixed(2) + "px");
    write("borderRadius", now.r.toFixed(2) + "px");
    write("opacity", now.o.toFixed(3));

    var distance = Math.hypot(now.x - t.x, now.y - t.y);
    var moving =
      stale ||
      distance > 0.3 ||
      Math.abs(now.w - t.w) > 0.1 ||
      Math.abs(now.h - t.h) > 0.1 ||
      Math.abs(now.r - t.r) > 0.1 ||
      Math.abs(now.o - t.o) > 0.01;
    if (moving || time < awakeUntil) {
      raf = requestAnimationFrame(frame);
    } else {
      raf = 0;
      last = 0;
    }
  }

  //// Stays awake briefly after each event, while the button under it is still springing.
  function wake() {
    awakeUntil = performance.now() + SETTLE_MS;
    if (!raf) raf = requestAnimationFrame(frame);
  }

  //////////////////

  //// Events only record where the pointer is; the next frame reads the page and draws.
  function point(node) {
    under = node;
    stale = true;
    wake();
  }

  ////////////////////
  //// Events
  /// The system cursor is hidden only once a mouse or trackpad actually moves, and returns for
  /// touch.

  document.addEventListener("pointermove", function (event) {
    if (event.pointerType === "touch") return;
    px = event.clientX;
    py = event.clientY;
    away = false;
    if (!seen) {
      seen = true;
      now.x = anchor.x = px;
      now.y = anchor.y = py;
    }
    root.classList.add("fx-cursor");
    point(event.target);
  }, { passive: true });

  //// Scrolling moves the page under a still pointer; look again.
  window.addEventListener("scroll", function () {
    if (seen) point(null);
  }, { passive: true, capture: true });

  document.addEventListener("pointerdown", function (event) {
    if (event.pointerType === "touch") {
      away = true;
      root.classList.remove("fx-cursor");
      wake();
      return;
    }
    el.classList.add("down");
  });
  function release() {
    el.classList.remove("down");
  }
  document.addEventListener("pointerup", release);
  document.addEventListener("pointercancel", release);
  root.addEventListener("pointerleave", function () {
    away = true;
    wake();
  });

  //////////////////

  ////////////////////
  //// Button parallax
  /// [data-fx] elements lean a few pixels toward the pointer, as iPadOS buttons do, and large
  /// buttons catch a light under it.
  // Clamped so a fast flick never throws the button off its spot.

  document.querySelectorAll("[data-fx]").forEach(function (button) {
    var max = (Number(button.dataset.fx) || 4) * LEAN;
    var tx = 0;
    var ty = 0;
    function lean(x, y) {
      tx = x;
      ty = y;
      button.style.setProperty("--tx", x.toFixed(2) + "px");
      button.style.setProperty("--ty", y.toFixed(2) + "px");
    }
    button.addEventListener("pointermove", function (event) {
      if (event.pointerType === "touch") return;
      var box = button.getBoundingClientRect();
      var nx = (event.clientX - (box.left + box.width / 2 - tx)) / (box.width / 2);
      var ny = (event.clientY - (box.top + box.height / 2 - ty)) / (box.height / 2);
      lean(clamp(nx, -1, 1) * max, clamp(ny, -1, 1) * max);
      button.style.setProperty("--mx", (event.clientX - box.left).toFixed(1) + "px");
      button.style.setProperty("--my", (event.clientY - box.top).toFixed(1) + "px");
    });
    button.addEventListener("pointerleave", function () {
      lean(0, 0);
    });
  });

  //////////////////
})();
