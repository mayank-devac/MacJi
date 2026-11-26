/*
  thank-you.js · MacJi website · Created: 2026-11-26
  Starts the .dmg download, celebrates with the party poppers and explains what to do if
  GitHub can't be reached.
*/

(function () {
  "use strict";

  var START_DELAY_MS = 900;
  var SHOWER_MS = 5200;
  var STARTED_KEY = "macji-download-started";

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.getElementById("download-again");
    var status = document.getElementById("download-status");
    var confetti = window.MacJiConfetti;

    ////////////////////
    //// Celebrate
    /// Poppers from both bottom corners, then glitter from the top; a click anywhere pops again.

    if (confetti) {
      setTimeout(function () {
        confetti.poppers();
        confetti.shower(SHOWER_MS);
      }, 250);
      document.addEventListener("pointerdown", function (event) {
        if (event.target.closest("a, button, kbd, code")) return;
        confetti.popAt(event.clientX, event.clientY);
      });
      var again = document.getElementById("pop-again");
      if (again) {
        again.addEventListener("click", function () {
          confetti.poppers();
          confetti.shower(SHOWER_MS / 2);
        });
      }
    }

    //// Links and buttons keep their normal click; only empty space pops.
    //////////////////

    ////////////////////
    //// Download
    /// Start once per tab session per version, so a reload doesn't download a second copy.

    window.MacJiRelease.latest().then(function (release) {
      if (!release) {
        status.textContent = "Couldn't reach GitHub to start the download. Get MacJi from the Releases page instead.";
        button.textContent = "Open the Releases page";
        button.setAttribute("href", window.MacJiRelease.releasesPage);
        return;
      }
      button.setAttribute("href", release.url);
      var started = null;
      try {
        started = sessionStorage.getItem(STARTED_KEY);
      } catch (error) {}
      if (started === release.version) {
        status.textContent = "MacJi " + release.version + " is in your Downloads folder.";
        return;
      }
      status.textContent = "Your download of MacJi " + release.version + " is starting…";
      setTimeout(function () {
        window.location.assign(release.url);
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
