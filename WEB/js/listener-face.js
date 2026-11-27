/*
  listener-face.js · MacJi website · Created: 2026-11-27
  The shape of the feedback page's dot face: each mood's expression, and how strongly a point on
  the face is inked. js/listener.js draws and animates it.
*/

window.MacJiFace = (function () {
  "use strict";

  //// Face coordinates run from -SPAN to SPAN on both axes, y downwards.
  var SPAN = 1.18;
  var HEAD = 0.9;
  var LOOKS = {
    Idle: { curve: 0.4, open: 0, tilt: 0, width: 0.32, joy: 0, brow: 0 },
    Sad: { curve: -0.9, open: 0, tilt: 0, width: 0.3, joy: 0, brow: 1 },
    Meh: { curve: -0.2, open: 0, tilt: 0.09, width: 0.3, joy: 0, brow: 0 },
    Okay: { curve: 0, open: 0, tilt: 0, width: 0.28, joy: 0, brow: 0 },
    Good: { curve: 0.85, open: 0, tilt: 0, width: 0.38, joy: 0, brow: 0 },
    Amazing: { curve: 0.25, open: 0.6, tilt: 0, width: 0.44, joy: 1, brow: 0 }
  };
  var TEAR_MS = 1100;
  var TEARS = 3;

  function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
  }

  ////////////////////
  //// The face
  /// Each part is a distance to its shape; a dot is inked by how far inside the nearest one it
  /// lies, softened over one grid step so shapes morph smoothly instead of popping dot by dot.

  function cover(distance, step) {
    return clamp(0.5 - distance / step, 0, 1);
  }

  function segment(x, y, ax, ay, bx, by) {
    var dx = bx - ax;
    var dy = by - ay;
    var along = clamp(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0, 1);
    return Math.hypot(x - ax - dx * along, y - ay - dy * along);
  }

  //// An oval that closes with `lid`, crossfading into a ^ shape as joy rises.
  function eye(x, y, side, lid, joyful, step) {
    var dx = x - side * 0.32;
    var dy = y + 0.2;
    var tall = Math.max(0.15 * lid, 0.03);
    var oval = cover((Math.hypot(dx / 0.1, dy / tall) - 1) * Math.min(0.1, tall), step);
    var t = clamp(dx / 0.14, -1, 1);
    var arch = Math.hypot(Math.max(0, Math.abs(dx) - 0.14), (dy - t * t * 0.11 + 0.04) * 0.8) - 0.045;
    //// A blinking or winking eye stays an oval; a rounding error short of open still counts as open.
    var joy = lid < 0.99 ? 0 : clamp(joyful, 0, 1);
    return oval * (1 - joy) + cover(arch, step) * joy;
  }

  //// A curve that bends and tilts; opening it fills the space down to a second, lower lip.
  function mouth(x, y, shape, step) {
    var t = clamp(x / shape.width, -1, 1);
    var top = 0.3 + shape.curve * (0.5 - t * t) * 0.3 + shape.tilt * t;
    var bottom = top + Math.max(0, shape.open) * (1 - t * t) * 0.34;
    var slope = (shape.tilt - 0.6 * shape.curve * t) / shape.width;
    var off = y < top ? top - y : y > bottom ? y - bottom : 0;
    var distance = Math.hypot(Math.max(0, Math.abs(x) - shape.width), off / Math.hypot(1, slope));
    return cover(distance - 0.048, step);
  }

  //// Falls a few times from the left eye, then rests on the cheek.
  function tear(x, y, age, step) {
    var fall = age < TEAR_MS * TEARS ? (age % TEAR_MS) / TEAR_MS : 0.45;
    return cover(Math.hypot(x + 0.47, (y - 0.02 - fall * fall * 0.45) * 0.75) - 0.06, step);
  }

  //// `pose` holds the current shape, gaze, lids and how long ago the mood was picked.
  function ink(x, y, pose, step) {
    var shape = pose.shape;
    var gaze = pose.gaze;
    var ring = cover(Math.abs(Math.hypot(x, y) - HEAD) - 0.028, step);
    //// The features slide further than the outline, so the head seems to turn.
    var fx = x - gaze.x * 0.09;
    var fy = y - gaze.y * 0.07;
    var ex = fx - gaze.x * 0.03;
    var ey = fy - gaze.y * 0.03;
    var found = Math.max(
      ring,
      eye(ex, ey, -1, pose.lids.left, shape.joy, step),
      eye(ex, ey, 1, pose.lids.right, shape.joy, step),
      mouth(fx, fy, shape, step)
    );
    if (shape.brow > 0.02) {
      var brow = segment(-Math.abs(fx), fy, -0.18, -0.52, -0.46, -0.42) - 0.035;
      found = Math.max(found, shape.brow * cover(brow, step), shape.brow * tear(fx, fy, pose.age, step));
    }
    return found;
  }

  //////////////////

  return { SPAN: SPAN, HEAD: HEAD, LOOKS: LOOKS, TEARS_LAST: TEAR_MS * TEARS, ink: ink };
})();
