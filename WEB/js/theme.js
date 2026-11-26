/*
  theme.js · MacJi website · Created: 2026-11-26
  Light/dark theme (system default, visitor's choice remembered), the scrolled nav material and
  the iPadOS-style pointer parallax on buttons. Loaded in <head> so the theme is set before paint.
*/

(function () {
  "use strict";

  var root = document.documentElement;
  var STORAGE_KEY = "macji-theme";
  var BAR_COLOR = { light: "#fbfbfd", dark: "#1c1c1e" };
  var systemDark = matchMedia("(prefers-color-scheme: dark)");

  ////////////////////
  //// Theme
  /// A stored choice wins; otherwise follow the system, live, as the system changes.
  // localStorage can throw in private windows, so every access is guarded.

  function storedTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (error) {
      return null;
    }
  }

  function applyTheme(theme) {
    root.dataset.theme = theme;
    var bar = document.getElementById("theme-color");
    if (bar) bar.setAttribute("content", BAR_COLOR[theme]);
    var button = document.getElementById("theme");
    if (button) {
      button.setAttribute("aria-label", theme === "dark" ? "Switch to light theme" : "Switch to dark theme");
    }
    document.dispatchEvent(new CustomEvent("macji:theme", { detail: theme }));
  }

  applyTheme(storedTheme() || (systemDark.matches ? "dark" : "light"));

  systemDark.addEventListener("change", function (event) {
    if (!storedTheme()) applyTheme(event.matches ? "dark" : "light");
  });

  //// The toggle and the rest need the DOM.
  //////////////////

  document.addEventListener("DOMContentLoaded", function () {
    applyTheme(root.dataset.theme);

    var button = document.getElementById("theme");
    if (button) {
      button.addEventListener("click", function () {
        var next = root.dataset.theme === "dark" ? "light" : "dark";
        applyTheme(next);
        try {
          localStorage.setItem(STORAGE_KEY, next);
        } catch (error) {}
      });
    }

    var nav = document.querySelector(".nav");
    if (nav) {
      var onScroll = function () {
        nav.classList.toggle("scrolled", window.scrollY > 8);
      };
      window.addEventListener("scroll", onScroll, { passive: true });
      onScroll();
    }

    ////////////////////
    //// Pointer parallax
    /// The button follows the pointer a few pixels, as iPadOS buttons do. Mouse and trackpad only.

    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    document.querySelectorAll("[data-fx]").forEach(function (el) {
      var max = Number(el.dataset.fx) || 4;
      var tx = 0;
      var ty = 0;
      function set(x, y) {
        tx = x;
        ty = y;
        el.style.setProperty("--tx", x.toFixed(2) + "px");
        el.style.setProperty("--ty", y.toFixed(2) + "px");
      }
      el.addEventListener("pointermove", function (event) {
        if (event.pointerType === "touch") return;
        var box = el.getBoundingClientRect();
        var nx = (event.clientX - (box.left + box.width / 2 - tx)) / (box.width / 2);
        var ny = (event.clientY - (box.top + box.height / 2 - ty)) / (box.height / 2);
        set(Math.max(-1, Math.min(1, nx)) * max, Math.max(-1, Math.min(1, ny)) * max);
      });
      el.addEventListener("pointerleave", function () {
        set(0, 0);
      });
    });

    //// Clamped so a fast flick never throws the button off its spot.
    //////////////////
  });
})();
