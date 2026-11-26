/*
  release.js · MacJi website · Created: 2026-11-26
  Finds the latest MacJi release on GitHub and its .dmg, so the download never needs a site edit.
  Falls back to the Releases page when GitHub can't be reached.
*/

(function () {
  "use strict";

  var REPO = "mayank-devac/MacJi";
  var RELEASES_PAGE = "https://github.com/" + REPO + "/releases/latest";
  var API = "https://api.github.com/repos/" + REPO + "/releases/latest";
  var CACHE_KEY = "macji-release";
  var TIMEOUT_MS = 6000;

  ////////////////////
  //// Latest release
  /// One API call per visit (cached for the tab session); the anonymous limit is 60 an hour per IP.
  // Resolves to null when there is no reachable release with a .dmg; callers then link the Releases page.

  function cached() {
    try {
      return JSON.parse(sessionStorage.getItem(CACHE_KEY) || "null");
    } catch (error) {
      return null;
    }
  }

  function remember(release) {
    try {
      sessionStorage.setItem(CACHE_KEY, JSON.stringify(release));
    } catch (error) {}
  }

  function fetchLatest() {
    var controller = "AbortController" in window ? new AbortController() : null;
    var timer = controller && setTimeout(function () { controller.abort(); }, TIMEOUT_MS);
    return fetch(API, {
      headers: { Accept: "application/vnd.github+json" },
      signal: controller ? controller.signal : undefined,
    })
      .then(function (response) {
        if (!response.ok) throw new Error("GitHub answered " + response.status);
        return response.json();
      })
      .then(function (data) {
        var dmg = (data.assets || []).filter(function (asset) {
          return /\.dmg$/i.test(asset.name);
        })[0];
        if (!dmg) return null;
        var release = {
          version: String(data.tag_name || "").replace(/^v/, ""),
          url: dmg.browser_download_url,
          name: dmg.name,
          size: dmg.size,
          page: data.html_url || RELEASES_PAGE,
        };
        remember(release);
        return release;
      })
      .catch(function () {
        return null;
      })
      .finally(function () {
        if (timer) clearTimeout(timer);
      });
  }

  var pending = null;
  function latest() {
    var hit = cached();
    if (hit) return Promise.resolve(hit);
    if (!pending) pending = fetchLatest();
    return pending;
  }

  //// Never rejects, so a page can always render a usable link.
  //////////////////

  function megabytes(bytes) {
    return (bytes / 1e6).toFixed(1) + " MB";
  }

  //// Fills every [data-release] slot on the page once the release is known.
  document.addEventListener("DOMContentLoaded", function () {
    latest().then(function (release) {
      if (!release) return;
      document.querySelectorAll("[data-release]").forEach(function (el) {
        var field = el.dataset.release;
        if (field === "version") el.textContent = release.version;
        if (field === "size") el.textContent = megabytes(release.size);
        if (field === "file") el.textContent = release.name;
        if (field === "page") el.setAttribute("href", release.page);
        el.hidden = false;
      });
    });
  });

  window.MacJiRelease = { latest: latest, releasesPage: RELEASES_PAGE, repo: REPO };
})();
