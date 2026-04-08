/**
 * include.js
 * Replaces every <... data-include="path"> element with the HTML
 * content fetched from `path`. Path is resolved against the document
 * <base href> if present.
 *
 * To prevent a flash of unstyled / partial content, set
 *   <body data-include-pending>
 * and the script will remove that attribute once all includes resolve.
 */
(function () {
  "use strict";

  function resolvePath(path) {
    // Honor <base href> via the URL constructor.
    try {
      return new URL(path, document.baseURI).toString();
    } catch (_e) {
      return path;
    }
  }

  // Safety net: even if a fetch hangs (some dev servers stall on
  // partial HTML), we never leave the body invisible forever.
  const FETCH_TIMEOUT_MS = 3000;

  function fetchWithTimeout(url) {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    return fetch(url, { cache: "no-cache", signal: controller.signal })
      .finally(() => clearTimeout(t));
  }

  async function loadInclude(el) {
    const path = el.getAttribute("data-include");
    if (!path) return;
    try {
      const res = await fetchWithTimeout(resolvePath(path));
      if (!res.ok) {
        throw new Error("HTTP " + res.status);
      }
      const html = await res.text();
      // Replace the placeholder element with the partial's contents.
      const tpl = document.createElement("template");
      tpl.innerHTML = html;
      el.replaceWith(tpl.content);
    } catch (err) {
      console.error("[include] failed to load", path, err);
      el.innerHTML =
        '<div class="muted" style="padding:8px 0;font-size:13px;">' +
        "[include failed: " +
        path +
        "]</div>";
    }
  }

  function reveal() {
    if (document.body.hasAttribute("data-include-pending")) {
      document.body.removeAttribute("data-include-pending");
    }
  }

  async function run() {
    // Hard cap: if all includes are not done within FETCH_TIMEOUT_MS + 500ms,
    // reveal the page anyway so the user is never stuck on a blank screen.
    const hardCap = setTimeout(reveal, FETCH_TIMEOUT_MS + 500);
    try {
      const targets = Array.from(document.querySelectorAll("[data-include]"));
      await Promise.all(targets.map(loadInclude));
    } finally {
      clearTimeout(hardCap);
      reveal();
      document.dispatchEvent(new CustomEvent("includes:loaded"));
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", run);
  } else {
    run();
  }
})();
