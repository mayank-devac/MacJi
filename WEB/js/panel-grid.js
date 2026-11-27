/*
  panel-grid.js · MacJi website · Created: 2026-11-27
  The inline panel's grid of results: drawing, selection, arrow keys and the footer that names the
  pick. Used by the hero demo and the type-anywhere panel.
*/

window.MacJiPanelGrid = function (parts) {
  "use strict";

  var COLUMNS = 8;
  var grid = parts.grid;
  var results = [];
  var selected = 0;

  function cellId(index) {
    return grid.id + "-" + index;
  }

  function select(index) {
    var previous = grid.querySelector(".cell.on");
    if (previous) previous.classList.remove("on");
    selected = index;
    var cell = document.getElementById(cellId(index));
    if (!cell) return;
    cell.classList.add("on");
    cell.setAttribute("aria-selected", "true");
    if (previous && previous !== cell) previous.removeAttribute("aria-selected");
    parts.input.setAttribute("aria-activedescendant", cell.id);
    var entry = results[index];
    parts.pickEmoji.textContent = entry.emoji;
    parts.pickName.textContent = entry.name;
    var top = cell.offsetTop - grid.offsetTop;
    if (top < grid.scrollTop) grid.scrollTop = top;
    if (top + cell.offsetHeight > grid.scrollTop + grid.clientHeight) {
      grid.scrollTop = top + cell.offsetHeight - grid.clientHeight;
    }
  }

  //// Clicking a cell picks it without taking the focus from the text being typed.
  function render(list, noun) {
    results = list;
    selected = 0;
    grid.textContent = "";
    parts.count.textContent = results.length || "";
    if (!results.length) {
      var empty = document.createElement("p");
      empty.className = "panel-empty";
      empty.textContent = "No " + noun + " match. Keep typing or press Esc.";
      grid.appendChild(empty);
      parts.pickEmoji.textContent = "";
      parts.pickName.textContent = "";
      parts.announce("No " + noun + " match");
      return;
    }
    results.forEach(function (entry, index) {
      var cell = document.createElement("button");
      cell.type = "button";
      cell.className = "cell";
      cell.id = cellId(index);
      cell.tabIndex = -1;
      cell.setAttribute("role", "option");
      cell.setAttribute("aria-label", entry.name);
      cell.textContent = entry.emoji;
      cell.addEventListener("mousedown", function (event) {
        event.preventDefault();
        selected = index;
        parts.pick();
      });
      grid.appendChild(cell);
    });
    select(0);
    parts.announce(results.length + " " + noun + ". " + results[0].name + " selected.");
  }

  function move(dx, dy) {
    if (!results.length) return;
    var next = selected + dx + dy * COLUMNS;
    if (dy !== 0 && (next < 0 || next >= results.length)) return;
    select(Math.max(0, Math.min(results.length - 1, next)));
  }

  //// True when the key was an arrow, which the panel keeps for itself.
  function arrow(key) {
    if (key === "ArrowLeft") move(-1, 0);
    else if (key === "ArrowRight") move(1, 0);
    else if (key === "ArrowUp") move(0, -1);
    else if (key === "ArrowDown") move(0, 1);
    else return false;
    return true;
  }

  //// Empties the grid, so Return can't pick from an earlier search.
  function clear() {
    results = [];
    selected = 0;
    grid.textContent = "";
    parts.count.textContent = "";
    parts.pickEmoji.textContent = "";
    parts.pickName.textContent = "";
    parts.input.removeAttribute("aria-activedescendant");
  }

  return {
    clear: clear,
    render: render,
    arrow: arrow,
    current: function () { return results[selected]; },
    index: function () { return selected; },
    indexOf: function (glyph) {
      return results.findIndex(function (entry) { return entry.emoji === glyph; });
    },
  };
};
