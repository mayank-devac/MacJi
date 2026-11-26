/*
  theme.js · MacJi website · Created: 2026-11-26
  Light/dark theme (system default, visitor's choice remembered) and the nav bar: its scrolled
  material and the current section. Loaded in <head> so the theme is set before paint.
*/

(function () {
  "use strict";

  var root = document.documentElement;
  var STORAGE_KEY = "macji-theme";
  var BAR_COLOR = { light: "#fbfbfd", dark: "#0e0e10" };
  var systemDark = matchMedia("(prefers-color-scheme: dark)");
  var calm = matchMedia("(prefers-reduced-motion: reduce)");

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
        spread(button, next);
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
      markCurrentSection(nav);
    }
  });

  //// The new theme spreads out from the toggle where the browser supports view transitions.
  function spread(button, theme) {
    if (!document.startViewTransition || calm.matches) {
      applyTheme(theme);
      return;
    }
    var box = button.getBoundingClientRect();
    root.style.setProperty("--wipe-x", box.left + box.width / 2 + "px");
    root.style.setProperty("--wipe-y", box.top + box.height / 2 + "px");
    document.startViewTransition(function () {
      applyTheme(theme);
    });
  }

  ////////////////////
  //// Current section
  /// The nav link of the section crossing the middle of the window is marked, none above them.

  function markCurrentSection(nav) {
    if (!("IntersectionObserver" in window)) return;
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var link = nav.querySelector('.nav-links a[href="#' + entry.target.id + '"]');
        if (entry.isIntersecting) link.setAttribute("aria-current", "true");
        else link.removeAttribute("aria-current");
      });
    }, { rootMargin: "-45% 0px -54% 0px" });
    nav.querySelectorAll('.nav-links a[href^="#"]').forEach(function (link) {
      var section = document.querySelector(link.getAttribute("href"));
      if (section) spy.observe(section);
    });
  }

  //////////////////
})();
