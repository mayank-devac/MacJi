/*
  feedback.js · MacJi website · Created: 2026-11-27
  Builds the feedback as a mail draft, a Gmail draft or a prefilled GitHub issue, the same way
  the app's Send Feedback sheet does. Nothing is stored or sent by the page.
*/

(function () {
  "use strict";

  var MAX_LENGTH = 2000;
  var KINDS = {
    bug: { title: "Bug", subject: "MacJi bug report", placeholder: "Tell me what happened, what you expected, and which app you were typing in." },
    feature: { title: "Feature idea", subject: "MacJi feature idea", placeholder: "Describe the idea and how it would help." },
    crash: { title: "Crash report", subject: "MacJi crash report", placeholder: "What were you doing when MacJi quit? Which macOS and MacJi version?" },
    other: { title: "Other", subject: "MacJi feedback", placeholder: "Questions, thanks, anything else." }
  };
  var FACES = { Sad: "😢", Meh: "😕", Okay: "😐", Good: "🙂", Amazing: "😄" };
  //// Issue-form ids, matching .github/ISSUE_TEMPLATE like the app's FeedbackReport.IssueForm.
  var FORM = {
    bugTemplate: "bug_report.yml",
    featureTemplate: "feature_request.yml",
    whatHappened: "what-happened",
    problem: "problem"
  };

  document.addEventListener("DOMContentLoaded", function () {
    var form = document.getElementById("feedback-form");
    var name = document.getElementById("name");
    var message = document.getElementById("message");
    var count = document.getElementById("count");
    var problem = document.getElementById("problem");
    var status = document.getElementById("status");
    var copy = document.getElementById("copy-message");
    var email = form.dataset.email;

    function picked(group) {
      var input = form.querySelector('input[name="' + group + '"]:checked');
      return input ? input.value : "";
    }

    ////////////////////
    //// The report
    /// The message first, then what the visitor chose under a rule, so the developer reads the
    /// words before the labels. The kind is repeated there because a crash files as a bug on
    /// GitHub. Empty choices are left out.

    function body() {
      var mood = picked("mood");
      var lines = ["Kind: " + KINDS[picked("kind")].title];
      if (name.value.trim()) lines.push("Name: " + name.value.trim());
      if (mood) lines.push("Experience: " + FACES[mood] + " " + mood);
      lines.push("Sent from the MacJi website");
      return message.value.trim() + "\n\n---\n" + lines.join("\n");
    }

    //// encodeURIComponent keeps "+" encoded, which mail apps and GitHub would read as a space.
    function query(pairs) {
      return Object.keys(pairs).map(function (key) {
        return encodeURIComponent(key) + "=" + encodeURIComponent(pairs[key]);
      }).join("&");
    }

    function mailURL() {
      return "mailto:" + email + "?" + query({ subject: KINDS[picked("kind")].subject, body: body() });
    }

    function gmailURL() {
      return form.dataset.gmail + "?" + query({
        view: "cm", fs: "1", to: email, su: KINDS[picked("kind")].subject, body: body()
      });
    }

    function issueURL() {
      var kind = picked("kind");
      var pairs;
      if (kind === "bug" || kind === "crash") {
        pairs = { template: FORM.bugTemplate };
        pairs[FORM.whatHappened] = body();
      } else if (kind === "feature") {
        pairs = { template: FORM.featureTemplate };
        pairs[FORM.problem] = body();
      } else {
        pairs = { body: body() };
      }
      return form.dataset.issues + "?" + query(pairs);
    }

    //////////////////

    ////////////////////
    //// Form behaviour
    /// The message is the one required field. The placeholder follows the kind, the counter
    /// follows the text, and a problem clears as soon as the visitor starts typing.

    function updateCount() {
      count.textContent = message.value.length.toLocaleString("en") + " of " + MAX_LENGTH.toLocaleString("en") + " characters";
      if (message.value.trim()) {
        problem.textContent = "";
        message.removeAttribute("aria-invalid");
      }
    }

    //// js/listener.js reacts to these.
    function tell(what) {
      document.dispatchEvent(new CustomEvent("macji:feedback", { detail: what }));
    }

    function hasMessage() {
      if (message.value.trim()) return true;
      tell("empty");
      problem.textContent = "Write a message first.";
      message.setAttribute("aria-invalid", "true");
      message.focus();
      return false;
    }

    message.addEventListener("input", function () {
      updateCount();
      if (!copy.hidden) copy.textContent = "Copy message";
    });
    form.addEventListener("change", function (event) {
      if (event.target.name === "kind") message.placeholder = KINDS[event.target.value].placeholder;
    });

    //////////////////

    ////////////////////
    //// Sending without losing the text
    /// Both routes open in a new tab, never this one: a browser set as the mail app (Chrome with
    /// Gmail, for example) would otherwise replace this page and the message with it. The text
    /// stays in the form, and Copy message is offered in case the draft arrives empty.

    function opened(where) {
      tell("opened");
      status.textContent = where + " If your message isn't there, copy it and paste it in, or write to " + email + ".";
      copy.textContent = "Copy message";
      copy.hidden = false;
    }

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      if (!hasMessage()) return;
      window.open(mailURL(), "_blank", "noopener");
      opened("Your mail app should open with the draft.");
    });

    document.getElementById("open-gmail").addEventListener("click", function () {
      if (!hasMessage()) return;
      window.open(gmailURL(), "_blank", "noopener");
      opened("Gmail opened in a new tab with the draft.");
    });

    document.getElementById("open-github").addEventListener("click", function () {
      if (!hasMessage()) return;
      window.open(issueURL(), "_blank", "noopener");
      opened("GitHub opened in a new tab.");
    });

    //// The Clipboard API needs a secure context; selecting the text lets ⌘C work anywhere else.
    copy.addEventListener("click", function () {
      var text = body();
      var done = function () { copy.textContent = "Copied"; };
      var fallback = function () {
        message.focus();
        message.select();
        copy.textContent = "Press ⌘C to copy";
      };
      if (navigator.clipboard && window.isSecureContext) navigator.clipboard.writeText(text).then(done, fallback);
      else fallback();
    });

    updateCount();

    //////////////////
  });
})();
