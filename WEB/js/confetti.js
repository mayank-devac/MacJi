/*
  confetti.js · MacJi website · Created: 2026-11-26
  Party-popper confetti on one full-page canvas: corner poppers, a pop wherever empty space is
  clicked, and a glitter party shower that sprays out of the 🎉, spreads and drifts down. The
  mouse pointer knocks the pieces away. No dependencies.
*/

(function () {
  "use strict";

  var COLORS_LIGHT = ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#00c7be", "#007aff", "#5856d6", "#af52de", "#ff2d55"];
  var COLORS_DARK = ["#ff453a", "#ff9f0a", "#ffd60a", "#30d158", "#66d4cf", "#0a84ff", "#5e5ce6", "#bf5af2", "#ff375f"];
  var GLITTER_LIGHT = ["#ffb000", "#ff7a00", "#ff2d92", "#af52de", "#007aff", "#00b8d4"];
  var GLITTER_DARK = ["#fff6d5", "#ffd60a", "#ffffff", "#9ecbff", "#e0b3ff", "#ffb4a2"];
  var EMOJI = ["🎉", "✨", "🚀", "🥳", "😀", "❤️", "🎊", "⭐️"];
  //// Listed twice or more means thrown more often.
  var SHAPES = ["strip", "strip", "strip", "dot", "dot", "triangle", "diamond", "ring", "heart", "squiggle", "star", "sparkle"];
  //// Drawn diameter per unit of particle size; shapes not listed use 1.2.
  var SCALE = { strip: 1.15, sparkle: 2.8, star: 1.7, squiggle: 2, heart: 1.5, ring: 1.3, triangle: 1.4, diamond: 1.4, emoji: 2.4 };
  var GRAVITY = 0.32;
  var MAX_PARTICLES = 700;
  var SHOWER_BURST = 60;
  var SHOWER_RATE = 3.5;
  //// The 🎉 mouth, as a fraction of the element's box.
  var MOUTH_X = 0.53;
  var MOUTH_Y = 0.32;
  //// The shower goes up, leaning a little the way the mouth opens, and fans out either side.
  //// Radians, clockwise from the positive x axis.
  var SHOWER_AIM = -1.4;
  var SHOWER_CONE = 0.75;
  //// Confetti thrown by each corner popper.
  var POPPER_COUNT = 80;
  //// The pointer's solid radius, a little wider than its dot so hits are easy to see.
  var POINTER_RADIUS = 22;
  //// Share of the closing speed a piece keeps when it bounces off the pointer.
  var BOUNCE = 0.2;
  //// The most of a swipe's speed a piece can pick up, in pixels per 60 Hz frame.
  var SWIPE_MAX = 8;
  var HIT_SPIN = 0.35;
  //// Controls and the demo's note keep their normal click.
  var QUIET = "a, button, input, textarea, label, summary, kbd, code, .window, .anywhere, .dock";

  var canvas = document.createElement("canvas");
  canvas.className = "confetti";
  canvas.setAttribute("aria-hidden", "true");
  var ctx = canvas.getContext("2d");
  var particles = [];
  var width = 0;
  var height = 0;
  var ratio = 1;
  var raf = 0;
  var last = 0;
  var showerFrom = null;
  var showerUntil = 0;
  var showerLength = 0;
  var showerOwed = 0;
  var showerAnimation = null;
  //// Where the mouse is now, and where it was on the previous frame.
  var pointer = null;
  var pointerBefore = null;
  var sprites = window.MacJiSprites;
  var reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;

  function dark() {
    return document.documentElement.dataset.theme === "dark";
  }
  function pick(list) {
    return list[(Math.random() * list.length) | 0];
  }
  function between(a, b) {
    return a + Math.random() * (b - a);
  }

  function resize() {
    ratio = Math.min(window.devicePixelRatio || 1, 2);
    width = window.innerWidth;
    height = window.innerHeight;
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    canvas.style.width = width + "px";
    canvas.style.height = height + "px";
  }

  ////////////////////
  //// Particles
  /// Flat confetti flips as it falls (cosine of a spin phase squashes it), glitter and sparkles
  /// twinkle, emoji tumble. Everything shares air drag.

  function confetto(x, y, angle, speed) {
    var shape = Math.random() < 0.06 ? "emoji" : pick(SHAPES);
    return {
      shape: shape,
      flat: shape !== "emoji" && shape !== "sparkle",
      twinkle: shape === "sparkle",
      x: x,
      y: y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      drag: between(0.955, 0.975),
      gravity: GRAVITY * between(0.7, 1.1),
      size: between(7, 12),
      scale: SCALE[shape] || 1.2,
      rotation: between(0, Math.PI * 2),
      spin: between(-0.25, 0.25),
      flip: between(0, Math.PI * 2),
      flipSpeed: between(0.08, 0.22),
      wobble: between(0, Math.PI * 2),
      color: shape === "emoji" ? pick(EMOJI) : pick(dark() ? COLORS_DARK : COLORS_LIGHT),
      life: 0,
      maxLife: between(260, 380),
    };
  }

  //// Glitter is flung high out of the mouth, loses its speed to drag, then falls back down the
  //// page. `strength` weakens the throw as the shower runs out.
  function glitter(from, strength) {
    var angle = SHOWER_AIM + between(-SHOWER_CONE, SHOWER_CONE);
    var speed = between(7, 25) * strength;
    var sparkle = Math.random() < 0.2;
    return {
      shape: sparkle ? "sparkle" : "speck",
      flat: false,
      twinkle: true,
      x: from.x + between(-4, 4),
      y: from.y + between(-4, 4),
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      drag: between(0.948, 0.968),
      gravity: between(0.1, 0.17),
      size: between(2, 4),
      scale: sparkle ? 4 : 1.8,
      rotation: between(0, Math.PI * 2),
      spin: between(-0.06, 0.06),
      flip: between(0, Math.PI * 2),
      flipSpeed: between(0.08, 0.26),
      wobble: between(0, Math.PI * 2),
      color: pick(dark() ? GLITTER_DARK : GLITTER_LIGHT),
      life: 0,
      maxLife: between(180, 320),
    };
  }

  function add(particle) {
    if (particles.length < MAX_PARTICLES) particles.push(particle);
  }

  //////////////////

  ////////////////////
  //// Pointer collision
  /// The pointer is a solid disc: pieces bounce off it, and a swipe flicks them away.
  // Only pieces closing in are hit, so a pop thrown from under the pointer leaves cleanly.

  //// The pointer's path since the previous frame, or null while the mouse is off the page.
  function swipe(step) {
    var from = pointerBefore || pointer;
    pointerBefore = pointer;
    if (!pointer) return null;
    var dx = pointer.x - from.x;
    var dy = pointer.y - from.y;
    var length = Math.hypot(dx, dy);
    var capped = Math.min(1, SWIPE_MAX / (length / step)) / step;
    //// A fast swipe is checked at points along its path, so it can't jump over a piece.
    var stops = Math.max(1, Math.ceil(length / POINTER_RADIUS));
    return { x: from.x, y: from.y, dx: dx, dy: dy, vx: dx * capped, vy: dy * capped, stops: stops };
  }

  function collide(p, path) {
    var reach = POINTER_RADIUS + (p.size * p.scale) / 2;
    for (var i = 1; i <= path.stops; i++) {
      var x = path.x + (path.dx * i) / path.stops;
      var y = path.y + (path.dy * i) / path.stops;
      var distance = Math.hypot(p.x - x, p.y - y);
      if (distance >= reach) continue;
      var nx = distance ? (p.x - x) / distance : 0;
      var ny = distance ? (p.y - y) / distance : -1;
      var closing = (p.vx - path.vx) * nx + (p.vy - path.vy) * ny;
      if (closing >= 0) continue;
      p.vx -= (1 + BOUNCE) * closing * nx;
      p.vy -= (1 + BOUNCE) * closing * ny;
      p.x = x + nx * reach;
      p.y = y + ny * reach;
      p.spin = between(-HIT_SPIN, HIT_SPIN);
      return;
    }
  }

  //////////////////

  ////////////////////
  //// Drawing
  /// js/confetti-sprites.js paints each glowing shape once; every frame only copies them.

  function draw(p) {
    var fade = Math.min(1, (p.maxLife - p.life) / 60);
    //// Particles start small, so they seem to leave from inside whatever threw them.
    var grow = Math.min(1, 0.2 + p.life / 14);
    var side = p.size * p.scale * grow * sprites.room;
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rotation);
    if (p.flat) ctx.scale(1, Math.cos(p.flip));
    ctx.globalAlpha = p.twinkle ? fade * (0.65 + 0.35 * Math.sin(p.flip)) : fade;
    ctx.drawImage(sprites.get(p.shape, p.color, dark()), -side / 2, -side / 2, side, side);
    ctx.restore();
  }

  function frame(now) {
    var step = Math.min(3, (now - (last || now)) / 16.67 || 1);
    last = now;
    if (now < showerUntil) {
      //// 1 at the start, 0 at the end: the stream thins and weakens like a real popper.
      var left = (showerUntil - now) / showerLength;
      var from = mouth(showerFrom);
      //// The fraction carries over, so 60 Hz and 120 Hz displays pour the same amount.
      showerOwed += SHOWER_RATE * Math.pow(left, 1.5) * step;
      for (; showerOwed >= 1; showerOwed--) add(glitter(from, 0.55 + 0.45 * left));
    }
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, width, height);
    var path = swipe(step);
    for (var i = particles.length - 1; i >= 0; i--) {
      var p = particles[i];
      p.vx *= Math.pow(p.drag, step);
      p.vy = p.vy * Math.pow(p.drag, step) + p.gravity * step;
      p.wobble += 0.05 * step;
      p.x += (p.vx + Math.sin(p.wobble) * 0.35) * step;
      p.y += p.vy * step;
      p.rotation += p.spin * step;
      p.flip += p.flipSpeed * step;
      p.life += step;
      if (path) collide(p, path);
      if (p.y > height + 40 || p.life > p.maxLife) particles.splice(i, 1);
      else draw(p);
    }
    if (particles.length || now < showerUntil) raf = requestAnimationFrame(frame);
    else {
      raf = 0;
      last = 0;
      pointerBefore = null;
      ctx.clearRect(0, 0, width, height);
    }
  }

  //// Adds the canvas on first use; until then the stage has no size.
  function mount() {
    if (!canvas.isConnected) {
      document.body.appendChild(canvas);
      resize();
    }
  }

  function run() {
    mount();
    if (!raf) raf = requestAnimationFrame(frame);
  }

  //// The loop stops itself when the last particle is gone, so an idle page costs nothing.
  //////////////////

  ////////////////////
  //// Public effects
  /// Visitors who ask for less motion get one small, quick burst and no shower.

  function burst(x, y, angle, spread, count, speed) {
    var total = reduceMotion ? Math.min(18, count) : count;
    for (var i = 0; i < total; i++) {
      add(confetto(x, y, angle + between(-spread, spread), speed * between(0.55, 1.15)));
    }
    run();
  }

  function poppers() {
    mount();
    var power = Math.max(15, Math.min(24, Math.hypot(width, height) / 55));
    burst(-10, height + 10, -Math.PI / 3, 0.38, POPPER_COUNT, power);
    burst(width + 10, height + 10, (-2 * Math.PI) / 3, 0.38, POPPER_COUNT, power);
  }

  function mouth(element) {
    var box = element.getBoundingClientRect();
    return { x: box.left + box.width * MOUTH_X, y: box.top + box.height * MOUTH_Y };
  }

  function rotateShowerSource(element, ms) {
    if (showerAnimation) showerAnimation.cancel();
    var animation = element.animate(
      [{ rotate: "-5deg" }, { rotate: "5deg" }],
      { duration: 520, iterations: ms / 520, direction: "alternate", easing: "ease-in-out" }
    );
    showerAnimation = animation;
    animation.onfinish = function () {
      animation.cancel();
      if (showerAnimation === animation) showerAnimation = null;
    };
  }

  //// A puff of glitter from the element's mouth, then a thinning stream for `ms`.
  function partyShower(element, ms) {
    if (reduceMotion) return;
    rotateShowerSource(element, ms);
    showerFrom = element;
    showerLength = ms;
    showerUntil = performance.now() + ms;
    var from = mouth(element);
    for (var i = 0; i < SHOWER_BURST; i++) add(glitter(from, 1));
    run();
  }

  function popAt(x, y) {
    burst(x, y, -Math.PI / 2, Math.PI, 46, 11);
  }

  //// detail is 0 for keyboard and script clicks, which have no pointer position.
  document.addEventListener("click", function (event) {
    if (!event.detail || event.target.closest(QUIET) || String(window.getSelection())) return;
    popAt(event.clientX, event.clientY);
  });

  //// A finger scrolls rather than pushes, and reduced motion adds no extra movement.
  document.addEventListener("pointermove", function (event) {
    if (reduceMotion || event.pointerType === "touch") return;
    pointer = { x: event.clientX, y: event.clientY };
  }, { passive: true });
  //// Forgetting both positions stops a swipe being drawn from where the mouse left.
  document.documentElement.addEventListener("pointerleave", function () {
    pointer = pointerBefore = null;
  });

  window.addEventListener("resize", function () {
    if (canvas.isConnected) resize();
  });

  window.MacJiConfetti = { poppers: poppers, partyShower: partyShower };

  //////////////////
})();
