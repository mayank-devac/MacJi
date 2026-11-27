/*
  stickers.js · MacJi website · Created: 2026-11-27
  Die-cut stickers that live on the page: they stamp down, can be dragged, nudged with the arrow
  keys, poked, flicked away or deleted, and a few have a trick (🚀 takes off, 🎉 sprays, hearts
  float). Held in memory only.
*/

window.MacJiStickers = (function () {
  "use strict";

  var calm = matchMedia("(prefers-reduced-motion: reduce)");
  var LIMIT = 40;
  var TILT = 12;
  var NUDGE = 12;
  //// Pixels per millisecond at release that count as a flick.
  var FLICK = 1.4;
  var FLICK_REACH = 520;
  //// A press that travels less than this is a poke, not a drag.
  var POKE = 5;
  var LEAN_MAX = 28;
  var SPARKS = 14;
  var HEARTS = ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💖", "💕", "😍", "🥰"];
  var LIFTOFF_MS = 650;
  var FLIGHT_MS = 1300;
  var PUFF_EVERY_MS = 70;

  var layer = document.createElement("div");
  layer.className = "stickers";
  var stickers = [];
  var listener = function () {};

  function between(low, high) {
    return low + Math.random() * (high - low);
  }

  function animate(element, frames, options) {
    return calm.matches ? null : element.animate(frames, options);
  }

  function mount() {
    if (!layer.isConnected) document.body.appendChild(layer);
  }

  //// Positions are document coordinates, x as a share of the width so a resize keeps it on screen.
  function moveTo(sticker, x, y) {
    var width = document.documentElement.clientWidth;
    sticker.x = Math.max(0, Math.min(width, x));
    sticker.y = Math.max(0, y);
    sticker.element.style.left = (sticker.x / width) * 100 + "%";
    sticker.element.style.top = sticker.y + "px";
  }

  function centre(element) {
    var box = element.getBoundingClientRect();
    return { x: box.left + box.width / 2 + window.scrollX, y: box.top + box.height / 2 + window.scrollY };
  }

  ////////////////////
  //// Tricks
  /// Short-lived bits are plain spans that remove themselves when their animation ends.

  function bit(className, x, y, text) {
    var span = document.createElement("span");
    span.className = className;
    span.setAttribute("aria-hidden", "true");
    span.textContent = text || "";
    span.style.left = x + "px";
    span.style.top = y + "px";
    layer.appendChild(span);
    return span;
  }

  function fly(span, dx, dy, ms) {
    var motion = animate(span, [
      { translate: "-50% -50%", opacity: 1, scale: 1 },
      { translate: "calc(-50% + " + dx + "px) calc(-50% + " + dy + "px)", opacity: 0, scale: 0.4 },
    ], { duration: ms, easing: "cubic-bezier(0.15, 0.7, 0.3, 1)", fill: "forwards" });
    if (motion) motion.onfinish = function () { span.remove(); };
    else span.remove();
  }

  //// A ring of dots, like a stamp hitting paper.
  function sparks(x, y) {
    if (calm.matches) return;
    for (var i = 0; i < SPARKS; i++) {
      var angle = (i / SPARKS) * Math.PI * 2;
      var reach = i % 2 ? 62 : 46;
      fly(bit("spark", x, y), Math.cos(angle) * reach, Math.sin(angle) * reach, 520);
    }
  }

  function hearts(sticker) {
    for (var i = 0; i < 7; i++) {
      fly(bit("mini", sticker.x, sticker.y, sticker.glyph), between(-70, 70), between(-150, -60), between(700, 1300));
    }
  }

  //// The rocket is drawn pointing up and right, so -45° stands it upright before it leaves.
  function launch(sticker) {
    var element = sticker.element;
    if (sticker.flying || calm.matches) return;
    sticker.flying = true;
    element.animate({ rotate: "-45deg" }, { duration: LIFTOFF_MS * 0.6, fill: "forwards", easing: "ease-out" });
    element.animate(
      [{ translate: "-50% -50%" }, { translate: "calc(-50% - 3px) -50%" }, { translate: "calc(-50% + 3px) -50%" }],
      { duration: 90, iterations: LIFTOFF_MS / 90 }
    );
    setTimeout(function () {
      if (!element.isConnected) return;
      var height = element.getBoundingClientRect().bottom + 160;
      var flight = element.animate(
        [{ translate: "-50% -50%" }, { translate: "-50% calc(-50% - " + height + "px)" }],
        { duration: FLIGHT_MS, easing: "cubic-bezier(0.5, 0, 0.9, 0.5)", fill: "forwards" }
      );
      var trail = setInterval(function () {
        var at = centre(element);
        fly(bit("mini", at.x, at.y + 30, "💨"), between(-24, 24), between(40, 90), 700);
      }, PUFF_EVERY_MS);
      flight.onfinish = function () {
        clearInterval(trail);
        drop(sticker);
      };
    }, LIFTOFF_MS);
  }

  function trick(sticker) {
    if (sticker.glyph === "🚀") launch(sticker);
    else if (sticker.glyph === "🎉" && window.MacJiConfetti) window.MacJiConfetti.partyShower(sticker.element, 1600);
    else if (HEARTS.indexOf(sticker.glyph) > -1) hearts(sticker);
  }

  //////////////////

  ////////////////////
  //// Leaving

  function drop(sticker) {
    var index = stickers.indexOf(sticker);
    if (index > -1) stickers.splice(index, 1);
    sticker.element.remove();
    listener(stickers.length);
  }

  //// Counted out at once; the element stays just long enough to leave.
  function leave(sticker, frames, ms) {
    var index = stickers.indexOf(sticker);
    if (index < 0) return;
    stickers.splice(index, 1);
    listener(stickers.length);
    var element = sticker.element;
    element.style.pointerEvents = "none";
    var motion = animate(element, frames, { duration: ms, easing: "cubic-bezier(0.3, 0, 0.8, 0.6)", fill: "forwards" });
    if (motion) motion.onfinish = function () { element.remove(); };
    else element.remove();
  }

  function peel(sticker) {
    leave(sticker, [
      { opacity: 1 },
      { translate: "-50% calc(-50% + 90px)", rotate: sticker.tilt + 40 + "deg", scale: 0.7, opacity: 0 },
    ], 380);
  }

  function flick(sticker, vx, vy) {
    var speed = Math.hypot(vx, vy);
    var dx = (vx / speed) * FLICK_REACH;
    var dy = (vy / speed) * FLICK_REACH;
    leave(sticker, [
      { opacity: 1 },
      { translate: "calc(-50% + " + dx + "px) calc(-50% + " + dy + "px)", rotate: (dx > 0 ? 220 : -220) + "deg", opacity: 0 },
    ], 520);
  }

  //////////////////

  ////////////////////
  //// Hands on
  /// A held sticker lifts and leans into the drag. Released fast it flies off; released after
  /// barely moving it wobbles and does its trick again.

  function wobble(sticker) {
    var tilt = sticker.tilt;
    animate(sticker.element, [
      { rotate: tilt + "deg" }, { rotate: tilt - 18 + "deg" }, { rotate: tilt + 14 + "deg" },
      { rotate: tilt - 6 + "deg" }, { rotate: tilt + "deg" },
    ], { duration: 520, easing: "ease-in-out" });
  }

  function hold(sticker) {
    var element = sticker.element;
    var held = null;

    element.addEventListener("pointerdown", function (event) {
      if (event.button || sticker.flying) return;
      event.preventDefault();
      element.setPointerCapture(event.pointerId);
      element.classList.add("held");
      element.focus({ preventScroll: true });
      held = {
        offsetX: sticker.x - event.pageX, offsetY: sticker.y - event.pageY,
        startX: event.pageX, startY: event.pageY, travelled: 0,
        x: event.pageX, y: event.pageY, time: event.timeStamp, vx: 0, vy: 0,
      };
    });

    element.addEventListener("pointermove", function (event) {
      if (!held) return;
      var elapsed = Math.max(1, event.timeStamp - held.time);
      //// Averaged with the last reading, so one jumpy event can't throw a sticker away.
      held.vx = (held.vx + (event.pageX - held.x) / elapsed) / 2;
      held.vy = (held.vy + (event.pageY - held.y) / elapsed) / 2;
      held.x = event.pageX;
      held.y = event.pageY;
      held.time = event.timeStamp;
      held.travelled = Math.max(held.travelled, Math.hypot(event.pageX - held.startX, event.pageY - held.startY));
      moveTo(sticker, event.pageX + held.offsetX, event.pageY + held.offsetY);
      var lean = Math.max(-LEAN_MAX, Math.min(LEAN_MAX, held.vx * 18));
      element.style.rotate = sticker.tilt + (calm.matches ? 0 : lean) + "deg";
    });

    function release(event) {
      if (!held) return;
      var last = held;
      held = null;
      element.classList.remove("held");
      element.style.rotate = sticker.tilt + "deg";
      if (event.type === "pointercancel") return;
      //// A pause before letting go means the sticker was placed, not thrown.
      var moving = event.timeStamp - last.time < 80;
      if (last.travelled < POKE) {
        wobble(sticker);
        trick(sticker);
      } else if (moving && Math.hypot(last.vx, last.vy) > FLICK) {
        flick(sticker, last.vx, last.vy);
      }
    }

    element.addEventListener("pointerup", release);
    element.addEventListener("pointercancel", release);

    element.addEventListener("keydown", function (event) {
      var step = {
        ArrowLeft: [-NUDGE, 0], ArrowRight: [NUDGE, 0], ArrowUp: [0, -NUDGE], ArrowDown: [0, NUDGE],
      }[event.key];
      if (step) moveTo(sticker, sticker.x + step[0], sticker.y + step[1]);
      else if (event.key === "Delete" || event.key === "Backspace") peel(sticker);
      else if (event.key === "Enter" || event.key === " ") {
        wobble(sticker);
        trick(sticker);
      } else return;
      event.preventDefault();
    });
  }

  //////////////////

  //// `x` and `y` are viewport coordinates; `term` is what to type to get this glyph again.
  function add(glyph, name, term, x, y) {
    mount();
    var element = document.createElement("button");
    element.type = "button";
    //// Text symbols such as → sit on a white chip; emoji are cut out around their own shape.
    element.className = term.indexOf("##") === 0 ? "sticker symbol" : "sticker";
    element.textContent = glyph;
    element.dataset.term = term;
    element.setAttribute("aria-label", name + " sticker. Arrow keys move it, Delete removes it.");
    var sticker = { element: element, glyph: glyph, tilt: Math.round(between(-TILT, TILT)), x: 0, y: 0, flying: false };
    element.style.rotate = sticker.tilt + "deg";
    layer.appendChild(element);
    moveTo(sticker, x + window.scrollX, y + window.scrollY);
    hold(sticker);
    stickers.push(sticker);
    if (stickers.length > LIMIT) peel(stickers[0]);
    listener(stickers.length);
    var stamp = animate(element, [
      { scale: 2.6, opacity: 0, rotate: sticker.tilt - 25 + "deg" },
      { scale: 0.86, opacity: 1, offset: 0.65 },
      { scale: 1, rotate: sticker.tilt + "deg" },
    ], { duration: 420, easing: "cubic-bezier(0.3, 0.6, 0.4, 1)" });
    var landed = function () {
      if (!element.isConnected) return;
      sparks(sticker.x, sticker.y);
      trick(sticker);
    };
    if (stamp) stamp.onfinish = landed;
    else landed();
  }

  function clear() {
    stickers.slice().forEach(function (sticker, index) {
      setTimeout(function () { peel(sticker); }, index * 35);
    });
  }

  return {
    add: add,
    clear: clear,
    onCount: function (callback) { listener = callback; },
  };
})();
