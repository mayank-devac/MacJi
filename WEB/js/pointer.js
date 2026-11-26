/*
  pointer.js · MacJi website · Created: 2026-11-26
  The iPadOS-style pointer and button parallax. A dot that melts into a platter behind small
  controls, morphs into a large button as it lifts, and turns into a text beam over text.
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
  var MAGNET = 0.08;
  var MAGNET_MAX = 3;
  var FRAME_MS = 1000 / 60;
  var SETTLE_MS = 450;
  var LIFT = ".btn, button.popper";
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
  var catching = false;
  var now = { x: 0, y: 0, w: DOT, h: DOT, r: DOT / 2, o: 0 };
  var previous = {};
  var raf = 0;
  var last = 0;
  var awakeUntil = 0;

  function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
  }

  ////////////////////
  //// What is under the pointer
  /// Large buttons lift, other controls get a platter, selectable text gets a beam.
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
    var control = node.closest(LIFT);
    if (control) return { mode: "lift", el: control };
    control = node.closest(PLATTER);
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
  /// The dot tracks the pointer exactly; platters and lifts ease in, and ease back out.
  // Smoothing is scaled by frame time, so 60 Hz and 120 Hz displays move at the same speed.
  // The loop stops once everything has settled, so an idle page costs nothing.

  function target() {
    var t = { x: px, y: py, w: DOT, h: DOT, r: DOT / 2, o: away || !seen ? 0 : 1 };
    if (hover.mode === "beam") {
      t.w = BEAM_WIDTH;
      t.h = hover.height;
      t.r = BEAM_WIDTH / 2;
    }
    if (!hover.el) return t;
    //// A wrapped link has one box per line; hug the line under the pointer.
    var box = Array.prototype.find.call(hover.el.getClientRects(), contains) || hover.el.getBoundingClientRect();
    var pad = hover.mode === "lift" ? 0 : hover.el.getAttribute("role") === "option" ? CELL_PAD : PLATTER_PAD;
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
    if (hover.mode === "lift") t.o = 0;
    return t;
  }

  function ease(from, to, perFrame, elapsed) {
    return from + (to - from) * (1 - Math.pow(1 - perFrame, elapsed / FRAME_MS));
  }

  function frame(time) {
    var elapsed = last ? Math.min(64, time - last) : FRAME_MS;
    last = time;
    if (hover.el && !hover.el.isConnected) hover = resolve(document.elementFromPoint(px, py));
    var t = target();
    //// A control that moves (page scroll, its own spring) carries the pointer with it.
    if (t.el && t.el === previous.el) {
      now.x += t.cx - previous.cx;
      now.y += t.cy - previous.cy;
    }
    previous = t;
    if (hover.el) catching = true;
    var follow = catching ? 0.3 : 1;
    now.x = ease(now.x, t.x, follow, elapsed);
    now.y = ease(now.y, t.y, follow, elapsed);
    var distance = Math.hypot(now.x - t.x, now.y - t.y);
    if (!hover.el && distance < 1.5) catching = false;
    now.w = ease(now.w, t.w, 0.28, elapsed);
    now.h = ease(now.h, t.h, 0.28, elapsed);
    now.r = ease(now.r, t.r, 0.28, elapsed);
    now.o = ease(now.o, t.o, 0.3, elapsed);

    el.style.translate = (now.x - now.w / 2).toFixed(2) + "px " + (now.y - now.h / 2).toFixed(2) + "px";
    el.style.width = now.w.toFixed(2) + "px";
    el.style.height = now.h.toFixed(2) + "px";
    el.style.borderRadius = now.r.toFixed(2) + "px";
    el.style.opacity = now.o.toFixed(3);

    var moving =
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

  function point(node) {
    hover = resolve(node);
    el.dataset.mode = hover.mode === "lift" ? "dot" : hover.mode;
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
      now.x = px;
      now.y = py;
    }
    root.classList.add("fx-cursor");
    point(event.target);
  }, { passive: true });

  //// Scrolling moves the page under a still pointer; look again.
  window.addEventListener("scroll", function () {
    if (seen) point(document.elementFromPoint(px, py));
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
    var max = Number(button.dataset.fx) || 4;
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
