/*
  thank-you.js · MacJi website · Created: 2026-11-26
  Starts the .dmg download, celebrates with confetti and explains what to do if GitHub
  can't be reached.
*/

(function () {
  "use strict";

  var START_DELAY_MS = 900;
  var SHOWER_MS = 3200;
  //// A page is never told that a download has ended, so the shower waits about as long as the
  //// file should take on a modest connection.
  var BYTES_PER_MS = 1500;
  var MIN_DOWNLOAD_MS = 2500;
  var MAX_DOWNLOAD_MS = 8000;
  var STARTED_KEY = "macji-download-started";

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.getElementById("download-again");
    var status = document.getElementById("download-status");
    var confetti = window.MacJiConfetti;

    ////////////////////
    //// Celebrate
    /// Poppers from both bottom corners when a download starts, then glitter spraying out of the
    /// 🎉 once it has likely finished and the visitor can see this page. Clicking the 🎉 fires
    /// both at once; a click on empty space pops (js/confetti.js).

    var popper = document.getElementById("pop-again");
    var showerTimer = 0;
    function showerWhenSeen() {
      if (document.visibilityState === "visible") confetti.partyShower(popper, SHOWER_MS);
      else document.addEventListener("visibilitychange", showerWhenSeen, { once: true });
    }
    function celebrateDownload(bytes) {
      if (!confetti) return;
      confetti.poppers();
      var wait = Math.max(MIN_DOWNLOAD_MS, Math.min(MAX_DOWNLOAD_MS, bytes / BYTES_PER_MS));
      clearTimeout(showerTimer);
      showerTimer = setTimeout(showerWhenSeen, wait);
    }
    popper.addEventListener("click", function () {
      if (!confetti) return;
      confetti.poppers();
      confetti.partyShower(popper, SHOWER_MS / 2);
    });

    //////////////////

    ////////////////////
    //// Download
    /// Every arrival from a Download button starts it. A reload, or coming back through history,
    /// doesn't download a second copy of a version this tab already started.

    var visit = performance.getEntriesByType("navigation")[0];
    var revisit = Boolean(visit) && visit.type !== "navigate";

    window.MacJiRelease.latest().then(function (release) {
      if (!release) {
        status.textContent = "Couldn't reach GitHub to start the download. Get MacJi from the Releases page instead.";
        button.textContent = "Open the Releases page";
        button.setAttribute("href", window.MacJiRelease.releasesPage);
        return;
      }
      button.setAttribute("href", release.url);
      button.addEventListener("click", function () {
        celebrateDownload(release.size);
      });
      var started = null;
      try {
        started = sessionStorage.getItem(STARTED_KEY);
      } catch (error) {}
      if (revisit && started === release.version) {
        status.textContent = "MacJi " + release.version + " is in your Downloads folder.";
        return;
      }
      status.textContent = "Your download of MacJi " + release.version + " is starting…";
      setTimeout(function () {
        window.location.assign(release.url);
        celebrateDownload(release.size);
        try {
          sessionStorage.setItem(STARTED_KEY, release.version);
        } catch (error) {}
        status.textContent = "MacJi " + release.version + " is downloading. Didn't start? Use the button below.";
      }, START_DELAY_MS);
    });

    //// GitHub serves release files as attachments, so assigning the URL keeps this page open.
    //////////////////
  });
})();
