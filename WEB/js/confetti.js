/*
  confetti.js · MacJi website · Created: 2026-11-26
  Party-popper confetti on one full-page canvas: corner poppers, bursts at a point, and a glitter
  shower that falls from the top centre in a widening cone. No dependencies.
*/

(function () {
  "use strict";

  var COLORS_LIGHT = ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#00c7be", "#007aff", "#5856d6", "#af52de", "#ff2d55"];
  var COLORS_DARK = ["#ff453a", "#ff9f0a", "#ffd60a", "#30d158", "#66d4cf", "#0a84ff", "#5e5ce6", "#bf5af2", "#ff375f"];
  var GLITTER_LIGHT = ["#c9a227", "#b8860b", "#8e8e93", "#007aff", "#af52de"];
  var GLITTER_DARK = ["#fff6d5", "#ffd60a", "#ffffff", "#9ecbff", "#e0b3ff", "#ffb4a2"];
  var EMOJI = ["🎉", "✨", "🚀", "🥳", "😀", "❤️", "🎊", "⭐️"];
  var GRAVITY = 0.32;
  var MAX_PARTICLES = 1400;

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
  var showerUntil = 0;
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
  /// Confetti strips and dots flip as they fall (cosine of a spin phase squashes them),
  /// glitter twinkles and drifts, emoji tumble. Everything shares gravity and air drag.

  function confetto(x, y, angle, speed) {
    var kind = Math.random();
    return {
      type: kind < 0.07 ? "emoji" : kind < 0.62 ? "strip" : kind < 0.85 ? "dot" : "star",
      x: x,
      y: y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      drag: between(0.955, 0.975),
      gravity: GRAVITY * between(0.7, 1.1),
      size: between(6, 11),
      rotation: between(0, Math.PI * 2),
      spin: between(-0.25, 0.25),
      flip: between(0, Math.PI * 2),
      flipSpeed: between(0.08, 0.22),
      wobble: between(0, Math.PI * 2),
      color: pick(dark() ? COLORS_DARK : COLORS_LIGHT),
      emoji: pick(EMOJI),
      life: 0,
      maxLife: between(260, 380),
    };
  }

  function glitter(x, y) {
    var spread = between(-1, 1) * between(0.2, 1.3);
    return {
      type: Math.random() < 0.18 ? "star" : "speck",
      x: x + between(-14, 14),
      y: y,
      vx: spread,
      vy: between(0.6, 2.2),
      drag: 0.992,
      gravity: 0.012,
      size: between(1.2, 3.2),
      rotation: 0,
      spin: between(-0.05, 0.05),
      flip: between(0, Math.PI * 2),
      flipSpeed: between(0.1, 0.35),
      wobble: between(0, Math.PI * 2),
      color: pick(dark() ? GLITTER_DARK : GLITTER_LIGHT),
      life: 0,
      maxLife: between(320, 520),
    };
  }

  function add(particle) {
    if (particles.length < MAX_PARTICLES) particles.push(particle);
  }

  //// Glitter barely feels gravity, so the shower hangs in the air like the reference image.
  //////////////////

  ////////////////////
  //// Drawing

  function drawStar(p, r) {
    ctx.beginPath();
    for (var i = 0; i < 8; i++) {
      var radius = i % 2 === 0 ? r : r * 0.32;
      var a = (i * Math.PI) / 4;
      ctx.lineTo(Math.cos(a) * radius, Math.sin(a) * radius);
    }
    ctx.closePath();
    ctx.fill();
  }

  function draw(p) {
    var fade = Math.min(1, (p.maxLife - p.life) / 60);
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rotation);
    ctx.fillStyle = p.color;
    if (p.type === "speck" || p.type === "star") {
      var twinkle = 0.55 + 0.45 * Math.sin(p.flip);
      ctx.globalAlpha = fade * twinkle;
      if (dark()) {
        ctx.shadowColor = p.color;
        ctx.shadowBlur = p.size * 3;
      }
      if (p.type === "star") drawStar(p, p.size * 2.2);
      else ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size);
    } else if (p.type === "emoji") {
      ctx.globalAlpha = fade;
      ctx.font = p.size * 2.4 + "px -apple-system, 'Apple Color Emoji', 'Segoe UI Emoji', sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(p.emoji, 0, 0);
    } else {
      ctx.globalAlpha = fade;
      ctx.scale(1, Math.cos(p.flip));
      if (p.type === "strip") ctx.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2);
      else {
        ctx.beginPath();
        ctx.arc(0, 0, p.size / 2.6, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.restore();
  }

  function frame(now) {
    var step = Math.min(3, (now - (last || now)) / 16.67 || 1);
    last = now;
    if (now < showerUntil) {
      var taper = Math.min(1, (showerUntil - now) / 1200);
      var count = Math.round(7 * taper * step);
      for (var n = 0; n < count; n++) add(glitter(width / 2, -6));
    }
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, width, height);
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
      if (p.y > height + 40 || p.life > p.maxLife) particles.splice(i, 1);
      else draw(p);
    }
    if (particles.length || now < showerUntil) raf = requestAnimationFrame(frame);
    else {
      raf = 0;
      last = 0;
      ctx.clearRect(0, 0, width, height);
    }
  }

  function run() {
    if (!canvas.isConnected) {
      document.body.appendChild(canvas);
      resize();
    }
    if (!raf) raf = requestAnimationFrame(frame);
  }

  //// The loop stops itself when the last particle lands, so an idle page costs nothing.
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
    var power = Math.max(15, Math.min(24, Math.hypot(width, height) / 55));
    burst(-10, height + 10, -Math.PI / 3, 0.38, 140, power);
    burst(width + 10, height + 10, (-2 * Math.PI) / 3, 0.38, 140, power);
  }

  function shower(ms) {
    if (reduceMotion) return;
    showerUntil = performance.now() + ms;
    run();
  }

  function popAt(x, y) {
    burst(x, y, -Math.PI / 2, Math.PI, 46, 11);
  }

  window.addEventListener("resize", function () {
    if (canvas.isConnected) resize();
  });

  window.MacJiConfetti = { poppers: poppers, shower: shower, popAt: popAt };

  //////////////////
})();
