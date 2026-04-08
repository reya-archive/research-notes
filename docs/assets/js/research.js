/**
 * research.js
 * Marks the current page link in a research sidebar with
 * `aria-current="page"`. Uses the file name (last path segment) as the key.
 */
(function () {
  "use strict";

  function currentFile() {
    const segs = window.location.pathname.split("/").filter(Boolean);
    return segs[segs.length - 1] || "index.html";
  }

  function markActive() {
    const here = currentFile();
    const links = document.querySelectorAll(".sidebar a[href]");
    links.forEach((a) => {
      const href = a.getAttribute("href");
      if (!href) return;
      const last = href.split("/").pop();
      if (last === here) {
        a.setAttribute("aria-current", "page");
      }
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", markActive);
  } else {
    markActive();
  }
})();
