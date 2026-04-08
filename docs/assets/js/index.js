/**
 * index.js
 * On the root page: load data/manifest.json and render the research
 * card list, sorted newest-first.
 */
(function () {
  "use strict";

  const MANIFEST_PATH = "data/manifest.json";

  function el(tag, attrs, children) {
    const node = document.createElement(tag);
    if (attrs) {
      for (const k in attrs) {
        if (k === "class") node.className = attrs[k];
        else if (k === "text") node.textContent = attrs[k];
        else if (k === "html") node.innerHTML = attrs[k];
        else node.setAttribute(k, attrs[k]);
      }
    }
    if (children) {
      for (const c of children) {
        if (c == null) continue;
        node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
      }
    }
    return node;
  }

  function formatDate(iso) {
    if (!iso) return "";
    // Display as "YYYY.MM.DD" - simple, locale-neutral.
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
    if (!m) return iso;
    return m[1] + "." + m[2] + "." + m[3];
  }

  function renderCard(item) {
    const meta = [];
    if (item.date) {
      meta.push(el("span", { text: formatDate(item.date) }));
    }
    if (typeof item.pages === "number") {
      meta.push(el("span", { class: "card__meta-sep" }));
      meta.push(
        el("span", { text: item.pages + (item.pages > 1 ? " pages" : " page") })
      );
    }
    if (item.tags && item.tags.length) {
      meta.push(el("span", { class: "card__meta-sep" }));
      const tags = el("span", { class: "tag-list" });
      item.tags.forEach((t) => tags.appendChild(el("span", { class: "tag", text: t })));
      meta.push(tags);
    }

    return el(
      "a",
      { class: "card", href: item.path },
      [
        el("h2", { class: "card__title", text: item.title || item.id }),
        item.summary
          ? el("p", { class: "card__summary", text: item.summary })
          : null,
        el("div", { class: "card__meta" }, meta),
      ]
    );
  }

  function renderList(items, container) {
    container.innerHTML = "";
    if (!items.length) {
      container.appendChild(
        el("div", { class: "empty-state", text: "아직 등록된 리서치가 없습니다." })
      );
      return;
    }
    const list = el("div", { class: "card-list" });
    items.forEach((item) => list.appendChild(renderCard(item)));
    container.appendChild(list);
  }

  async function run() {
    const container = document.getElementById("research-list");
    if (!container) return;

    try {
      const res = await fetch(MANIFEST_PATH, { cache: "no-cache" });
      if (!res.ok) throw new Error("HTTP " + res.status);
      const data = await res.json();
      const items = Array.isArray(data.researches) ? data.researches.slice() : [];
      // Newest first.
      items.sort((a, b) => (b.date || "").localeCompare(a.date || ""));
      renderList(items, container);
    } catch (err) {
      console.error("[index] failed to load manifest", err);
      container.innerHTML = "";
      container.appendChild(
        el("div", {
          class: "empty-state",
          text: "리서치 목록을 불러오지 못했습니다. (manifest.json 확인 필요)",
        })
      );
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", run);
  } else {
    run();
  }
})();
