/*
  listener.js · MacJi website · Created: 2026-11-27
  The dot-matrix face beside the feedback form. It wears the chosen mood, watches the pointer,
  reads along while you type, glitches for a crash, shakes its head at an empty message and winks
  when a draft opens. Drawn on a canvas that rests when nothing moves. No dependencies.
*/

(function () {
  "use strict";

  var canvas = document.getElementById("listener");
  var ctx = canvas && canvas.getContext("2d");
  if (!ctx) return;

  var form = document.getElementById("feedback-form");
  var message = document.getElementById("message");
  var calm = matchMedia("(prefers-reduced-motion: reduce)");

  var face = window.MacJiFace;
  var SPAN = face.SPAN;
  var LOOKS = face.LOOKS;
  //// Dots across the grid; small canvases get fewer so each dot stays visible.
  var DOTS = 43;
  var DOTS_SMALL = 33;
  var SMALL = 320;
  var BLINK_MS = 170;
  var BLINK_GAP = 2400;
  var BLINK_SPREAD = 3600;
  var WINK_MS = 1100;
  var SHAKE_MS = 600;
  var GLITCH_MS = 520;
  var RIPPLE_MS = 900;
  var MAX_RIPPLES = 5;
  //// Characters the eyes take to sweep across the message box once.
  var READING_LINE = 56;

  var mood = "Idle";
  var now = 0;
  var last = 0;
  var raf = 0;
  var size = 0;
  var ratio = 1;
  var colors = {};
  var shape = Object.assign({}, LOOKS.Idle);
  var speed = { curve: 0, open: 0, tilt: 0, width: 0, joy: 0, brow: 0 };
  var gaze = { x: 0, y: 0 };
  var gazeTo = { x: 0, y: 0 };
  var lens = null;
  var ripples = [];
  var blinkAt = -Infinity;
  var winkUntil = 0;
  var shakeAt = -Infinity;
  var glitchAt = -Infinity;
  var tearAt = -Infinity;

  function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
  }

  //// 0 to 1 while an effect that started at `start` is running, otherwise 1.
  function progress(start, length) {
    return clamp((now - start) / length, 0, 1);
  }

  ////////////////////
  //// Drawing
  /// Dots are batched into one path per colour and tenth of opacity. Inside the head they take
  /// the accent colour; outside they fade away in the text colour.

  function draw() {
    if (!size) return;
    var count = size < SMALL ? DOTS_SMALL : DOTS;
    var gap = size / count;
    var step = (2 * SPAN) / count;
    var blink = 1 - Math.sin(Math.PI * progress(blinkAt, BLINK_MS));
    var pose = {
      shape: shape,
      gaze: gaze,
      lids: { left: blink, right: now < winkUntil ? 0 : blink },
      age: now - tearAt
    };
    var shaking = progress(shakeAt, SHAKE_MS);
    var shake = Math.sin(shaking * Math.PI * 6) * (1 - shaking) * 0.12;
    var glitch = 1 - progress(glitchAt, GLITCH_MS);
    var offsetX = (canvas.width / ratio - size) / 2;
    var offsetY = (canvas.height / ratio - size) / 2;
    var batches = {};

    for (var row = 0; row < count; row++) {
      var y = -SPAN + (row + 0.5) * step;
      //// A crash tears some rows sideways, reshuffled every few frames.
      var noise = Math.sin(row * 91.7 + Math.floor(now / 60) * 47.3);
      var slip = Math.abs(noise) > 0.6 ? noise * glitch * 0.28 : 0;
      for (var column = 0; column < count; column++) {
        var x = -SPAN + (column + 0.5) * step;
        var far = Math.hypot(x, y);
        var wave = 0;
        for (var i = 0; i < ripples.length; i++) {
          var ripple = ripples[i];
          var age = progress(ripple.start, RIPPLE_MS);
          var edge = (Math.hypot(x - ripple.x, y - ripple.y) - age * 2.6) / 0.11;
          wave += Math.exp(-edge * edge) * (1 - age) * ripple.strength;
        }
        if (lens) {
          var near = Math.hypot(x - lens.x, y - lens.y) / 0.22;
          wave += Math.exp(-near * near) * 0.7;
        }
        var marked = face.ink(x - shake + slip, y, pose, step);
        var inside = far < face.HEAD;
        var rest = inside ? 0.2 : 0.22 * clamp(1 - (far - face.HEAD) / (SPAN - face.HEAD), 0, 1);
        var alpha = Math.round(clamp(rest + marked * (1 - rest) + wave * 0.45 * Math.min(1, rest * 5), 0, 1) * 10);
        if (!alpha) continue;
        var key = (inside || marked > 0.05 || wave > 0.25 ? "accent" : "quiet") + ":" + alpha;
        var path = batches[key] || (batches[key] = new Path2D());
        var radius = gap * Math.min(0.48, 0.13 + marked * 0.31 + wave * 0.16);
        var cx = offsetX + (column + 0.5) * gap;
        var cy = offsetY + (row + 0.5) * gap;
        path.moveTo(cx + radius, cy);
        path.arc(cx, cy, radius, 0, Math.PI * 2);
      }
    }

    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    Object.keys(batches).forEach(function (key) {
      var parts = key.split(":");
      ctx.fillStyle = colors[parts[0]];
      ctx.globalAlpha = parts[1] / 10;
      ctx.fill(batches[key]);
    });
  }

  //////////////////

  ////////////////////
  //// Motion
  /// The mouth and eyes spring to the new mood and the gaze eases after its target. Frames stop
  /// once everything has settled. Visitors who ask for less motion get still expressions.

  function target() {
    return now < winkUntil ? LOOKS.Good : LOOKS[mood];
  }

  function advance(frames) {
    var goal = target();
    var moving = false;
    Object.keys(shape).forEach(function (key) {
      for (var i = 0; i < frames; i++) {
        speed[key] = (speed[key] + (goal[key] - shape[key]) * 0.11) * 0.72;
        shape[key] += speed[key];
      }
      if (Math.abs(goal[key] - shape[key]) > 0.002 || Math.abs(speed[key]) > 0.002) moving = true;
    });
    var follow = 1 - Math.pow(0.86, frames);
    gaze.x += (gazeTo.x - gaze.x) * follow;
    gaze.y += (gazeTo.y - gaze.y) * follow;
    return moving || Math.hypot(gazeTo.x - gaze.x, gazeTo.y - gaze.y) > 0.004;
  }

  function frame() {
    now = performance.now();
    var frames = clamp(Math.round((now - last) / (1000 / 60)), 1, 4);
    last = now;
    var moving = advance(frames);
    ripples = ripples.filter(function (ripple) {
      return now - ripple.start < RIPPLE_MS;
    });
    draw();
    var busy = moving || ripples.length > 0 ||
      now - blinkAt < BLINK_MS || now < winkUntil + 50 ||
      now - shakeAt < SHAKE_MS + 50 || now - glitchAt < GLITCH_MS + 50 ||
      (mood === "Sad" && now - tearAt < face.TEARS_LAST + 50);
    raf = busy ? requestAnimationFrame(frame) : 0;
  }

  function still() {
    now = performance.now();
    Object.assign(shape, LOOKS[mood]);
    gaze = { x: 0, y: 0 };
    lens = null;
    ripples = [];
    blinkAt = shakeAt = glitchAt = tearAt = -Infinity;
    winkUntil = 0;
    draw();
  }

  function wake() {
    if (calm.matches) {
      still();
    } else if (!raf) {
      last = performance.now();
      raf = requestAnimationFrame(frame);
    }
  }

  function blinkLater() {
    setTimeout(function () {
      if (!document.hidden && !calm.matches) {
        blinkAt = performance.now();
        wake();
      }
      blinkLater();
    }, BLINK_GAP + Math.random() * BLINK_SPREAD);
  }

  //////////////////

  ////////////////////
  //// Reactions

  //// A point on the screen in face coordinates.
  function place(clientX, clientY) {
    var box = canvas.getBoundingClientRect();
    var half = size / 2 / SPAN;
    return {
      x: (clientX - box.left - box.width / 2) / half,
      y: (clientY - box.top - box.height / 2) / half
    };
  }

  function lookAt(clientX, clientY) {
    //// Until the canvas has a size there is nothing to measure against.
    if (!size) return;
    var point = place(clientX, clientY);
    var reach = Math.max(1.6, Math.hypot(point.x, point.y));
    gazeTo = { x: point.x / reach, y: point.y / reach };
  }

  function splash(x, y, strength) {
    ripples.push({ x: x, y: y, strength: strength, start: performance.now() });
    if (ripples.length > MAX_RIPPLES) ripples.shift();
  }

  //// Eyes sweep along the line being written, and each keystroke ripples in from that side.
  function read() {
    var box = message.getBoundingClientRect();
    var line = message.value.slice(0, message.selectionStart).split("\n").pop();
    var x = box.left + box.width * ((line.length % READING_LINE) / READING_LINE);
    var y = box.top + box.height / 2;
    lookAt(x, y);
    var from = place(x, y);
    var away = Math.hypot(from.x, from.y) || 1;
    splash((from.x / away) * SPAN, (from.y / away) * SPAN, 0.55);
    wake();
  }

  form.addEventListener("change", function (event) {
    if (event.target.name === "mood") {
      mood = event.target.value;
      tearAt = performance.now();
      splash(0, 0, 1);
    } else if (event.target.name === "kind") {
      if (event.target.value === "crash") glitchAt = performance.now();
      else splash(0, 0, 0.7);
    }
    wake();
  });

  message.addEventListener("input", read);

  //// js/feedback.js says whether a draft opened or the message was still empty.
  document.addEventListener("macji:feedback", function (event) {
    if (event.detail === "empty") {
      shakeAt = performance.now();
    } else {
      winkUntil = performance.now() + WINK_MS;
      splash(0, 0, 1.4);
    }
    wake();
  });

  window.addEventListener("pointermove", function (event) {
    if (event.pointerType !== "mouse" || calm.matches) return;
    lookAt(event.clientX, event.clientY);
    var point = place(event.clientX, event.clientY);
    lens = Math.hypot(point.x, point.y) < SPAN ? point : null;
    wake();
  }, { passive: true });

  document.documentElement.addEventListener("pointerleave", function () {
    lens = null;
    gazeTo = { x: 0, y: 0 };
    wake();
  });

  //// Drawn at once, so the theme's view transition captures the new colours.
  function paint() {
    var style = getComputedStyle(document.documentElement);
    colors = { accent: style.getPropertyValue("--accent").trim(), quiet: style.getPropertyValue("--text2").trim() };
    draw();
  }

  document.addEventListener("macji:theme", paint);
  calm.addEventListener("change", wake);

  new ResizeObserver(function () {
    ratio = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(canvas.clientWidth * ratio);
    canvas.height = Math.round(canvas.clientHeight * ratio);
    size = Math.min(canvas.clientWidth, canvas.clientHeight);
    draw();
  }).observe(canvas);

  //// A browser may restore the visitor's choice when they come back to the page.
  var restored = form.querySelector('input[name="mood"]:checked');
  if (restored) mood = restored.value;
  Object.assign(shape, LOOKS[mood]);
  now = performance.now();
  paint();
  splash(0, 0, 1);
  wake();
  blinkLater();

  //////////////////
})();
