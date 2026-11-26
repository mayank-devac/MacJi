/*
  confetti-sprites.js · MacJi website · Created: 2026-11-26
  The confetti shapes and their glow. Each shape and colour is painted once on its own small
  canvas, which js/confetti.js then only copies.
*/

(function () {
  "use strict";

  //// A square canvas with room around the shape for its glow.
  var SPRITE = 96;
  var SHAPE = 44;
  //// A wide bloom, a tight one, then the crisp shape, drawn twice so its edge stays sharp.
  var GLOW_BLURS = [20, 6, 0, 0];
  var LIGHT_GLOW_BLURS = [10, 3, 0, 0];

  var cache = {};

  ////////////////////
  //// Shapes
  /// Every path fits a circle of radius `r` around the origin.

  //// A star with `points` tips; `waist` is how deep it pinches between them.
  function starPath(g, r, points, waist) {
    for (var i = 0; i < points * 2; i++) {
      var radius = i % 2 === 0 ? r : r * waist;
      var a = (i * Math.PI) / points - Math.PI / 2;
      g.lineTo(Math.cos(a) * radius, Math.sin(a) * radius);
    }
    g.closePath();
  }

  function polygonPath(g, points) {
    points.forEach(function (point) {
      g.lineTo(point[0], point[1]);
    });
    g.closePath();
  }

  var PATHS = {
    strip: function (g, r) { g.rect(-r, -r / 2, r * 2, r); },
    speck: function (g, r) { g.arc(0, 0, r * 0.55, 0, Math.PI * 2); },
    dot: function (g, r) { g.arc(0, 0, r * 0.75, 0, Math.PI * 2); },
    sparkle: function (g, r) { starPath(g, r, 4, 0.28); },
    star: function (g, r) { starPath(g, r, 5, 0.46); },
    triangle: function (g, r) { polygonPath(g, [[0, -r], [r * 0.87, r * 0.5], [-r * 0.87, r * 0.5]]); },
    diamond: function (g, r) { polygonPath(g, [[0, -r], [r * 0.65, 0], [0, r], [-r * 0.65, 0]]); },
    heart: function (g, r) {
      g.moveTo(0, r * 0.85);
      g.bezierCurveTo(-r * 1.5, -r * 0.1, -r * 0.7, -r * 1.2, 0, -r * 0.4);
      g.bezierCurveTo(r * 0.7, -r * 1.2, r * 1.5, -r * 0.1, 0, r * 0.85);
    },
    ring: function (g, r) { g.arc(0, 0, r * 0.7, 0, Math.PI * 2); },
    squiggle: function (g, r) {
      g.moveTo(-r, 0);
      g.bezierCurveTo(-r * 0.55, -r * 0.8, -r * 0.2, -r * 0.8, 0, 0);
      g.bezierCurveTo(r * 0.2, r * 0.8, r * 0.55, r * 0.8, r, 0);
    },
  };
  //// Outlines rather than fills, with the line width as a fraction of the radius.
  var STROKED = { ring: 0.42, squiggle: 0.36 };

  //////////////////

  ////////////////////
  //// Painting
  /// A glow is far too slow to blur for every particle on every frame, hence the cache. Light
  /// pages add a wider tinted halo, which a blur alone is too faint to give on white.

  function paint(g, shape, color, dark) {
    var r = SHAPE / 2;
    g.translate(SPRITE / 2, SPRITE / 2);
    if (shape === "emoji") {
      g.font = SHAPE + "px -apple-system, 'Apple Color Emoji', 'Segoe UI Emoji', sans-serif";
      g.textAlign = "center";
      g.textBaseline = "middle";
      g.fillText(color, 0, 0);
      return;
    }
    if (!dark) {
      var halo = g.createRadialGradient(0, 0, 0, 0, 0, SPRITE / 2);
      halo.addColorStop(0, color + "38");
      halo.addColorStop(0.5, color + "12");
      halo.addColorStop(1, color + "00");
      g.fillStyle = halo;
      g.fillRect(-SPRITE / 2, -SPRITE / 2, SPRITE, SPRITE);
    }
    g.fillStyle = color;
    g.strokeStyle = color;
    g.lineWidth = r * (STROKED[shape] || 0);
    g.lineCap = "round";
    g.shadowColor = color;
    g.beginPath();
    PATHS[shape](g, r);
    (dark ? GLOW_BLURS : LIGHT_GLOW_BLURS).forEach(function (blur) {
      g.shadowBlur = blur;
      if (STROKED[shape]) g.stroke();
      else g.fill();
    });
  }

  //// For emoji, `color` holds the emoji itself. Each theme has its own colours, so shape and
  //// colour are enough to tell two sprites apart.
  function get(shape, color, dark) {
    var key = shape + color;
    if (!cache[key]) {
      var image = document.createElement("canvas");
      image.width = image.height = SPRITE;
      paint(image.getContext("2d"), shape, color, dark);
      cache[key] = image;
    }
    return cache[key];
  }

  //// `room` is how much larger a sprite is than the shape on it.
  window.MacJiSprites = { get: get, room: SPRITE / SHAPE };

  //////////////////
})();
