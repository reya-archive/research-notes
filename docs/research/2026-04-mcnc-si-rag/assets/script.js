/**
 * MCNC SI RAG 리서치 - 비교 매트릭스 및 인터랙션
 *
 * 동작:
 *  - [data-matrix] 요소가 있으면 products.json을 fetch 하여 9 카테고리 비교표 렌더
 *  - 카테고리 헤더 클릭으로 접기/펼치기
 *  - 수치 기반 최저가 항목 자동 하이라이트
 *  - 별점 항목은 기준(criterion)을 함께 표시
 *
 *  데이터 파일: research/2026-04-mcnc-si-rag/assets/products.json
 */
(function () {
  "use strict";

  var DATA_URL = "research/2026-04-mcnc-si-rag/assets/products.json";

  function resolveField(obj, path) {
    return path.split(".").reduce(function (acc, key) {
      return acc == null ? undefined : acc[key];
    }, obj);
  }

  function starsHTML(value) {
    var n = Math.max(0, Math.min(5, Number(value) || 0));
    var filled = "";
    var empty = "";
    for (var i = 0; i < n; i++) filled += "\u2605";
    for (var j = 0; j < 5 - n; j++) empty += "\u2606";
    return (
      '<span class="r-2026-04-mcnc-si-rag__star">' +
      '<span class="r-2026-04-mcnc-si-rag__star-filled">' + filled + "</span>" +
      empty +
      "</span>"
    );
  }

  function formatValue(val, row) {
    if (val === undefined || val === null) return "-";
    if (row.bool) return val ? "\u2713" : "-";
    if (row.star) return starsHTML(val);
    if (row.unit) {
      if (row.unit === "USD" || row.unit === "USD/mo") {
        var num = Number(val);
        if (!isNaN(num)) {
          return "$" + num.toLocaleString("en-US") + (row.unit === "USD/mo" ? "/mo" : "");
        }
      }
      return val + " " + row.unit;
    }
    if (Array.isArray(val)) return val.join(", ");
    return String(val);
  }

  function lowestIndex(values) {
    var minIdx = -1;
    var minVal = Infinity;
    values.forEach(function (v, i) {
      var n = Number(v);
      if (!isNaN(n) && n < minVal) {
        minVal = n;
        minIdx = i;
      }
    });
    return minIdx;
  }

  function renderMatrix(container, data) {
    var products = data.products;
    var categories = data.matrix.categories;

    var html = "";
    html += '<div class="r-2026-04-mcnc-si-rag__matrix">';

    categories.forEach(function (cat, ci) {
      var bodyId = "matrix-body-" + cat.id;
      html += '<section class="r-2026-04-mcnc-si-rag__matrix-category">';
      html += '<button type="button" class="r-2026-04-mcnc-si-rag__matrix-header" ';
      html += 'aria-expanded="true" aria-controls="' + bodyId + '">';
      html += '<span>' + cat.label + '</span>';
      html += '<span class="r-2026-04-mcnc-si-rag__matrix-toggle" aria-hidden="true">\u25BE</span>';
      html += '</button>';
      html += '<div class="r-2026-04-mcnc-si-rag__matrix-body" id="' + bodyId + '">';
      html += '<table class="r-2026-04-mcnc-si-rag__matrix-table">';
      html += '<thead><tr><th>항목</th>';
      products.forEach(function (p) {
        html += '<th>' + p.shortName + '</th>';
      });
      html += '</tr></thead><tbody>';

      cat.rows.forEach(function (row) {
        var values = products.map(function (p) { return resolveField(p, row.field); });
        var highlightIdx = row.highlightLowest ? lowestIndex(values) : -1;

        html += '<tr>';
        html += '<td class="r-2026-04-mcnc-si-rag__matrix-row-label">';
        html += row.label;
        if (row.criterion) {
          html += '<span class="r-2026-04-mcnc-si-rag__matrix-criterion">기준: ' + row.criterion + '</span>';
        }
        html += '</td>';
        values.forEach(function (val, vi) {
          var cellClass = (vi === highlightIdx)
            ? ' class="r-2026-04-mcnc-si-rag__matrix-cell--highlight"'
            : '';
          html += '<td' + cellClass + '>' + formatValue(val, row) + '</td>';
        });
        html += '</tr>';
      });

      html += '</tbody></table>';
      html += '</div>';
      html += '</section>';
    });

    html += '</div>';
    container.innerHTML = html;
  }

  function wireToggles(container) {
    container.querySelectorAll(".r-2026-04-mcnc-si-rag__matrix-header").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var bodyId = btn.getAttribute("aria-controls");
        var body = document.getElementById(bodyId);
        if (!body) return;
        var expanded = btn.getAttribute("aria-expanded") === "true";
        btn.setAttribute("aria-expanded", expanded ? "false" : "true");
        body.hidden = expanded;
      });
    });
  }

  function initMatrix() {
    var container = document.querySelector("[data-matrix]");
    if (!container) return;

    fetch(DATA_URL)
      .then(function (r) {
        if (!r.ok) throw new Error("products.json load failed: " + r.status);
        return r.json();
      })
      .then(function (data) {
        renderMatrix(container, data);
        wireToggles(container);
      })
      .catch(function (err) {
        container.innerHTML =
          '<p class="empty-state">비교 매트릭스 데이터를 불러오지 못했습니다. ' +
          '로컬에서 확인하려면 VSCode Live Server로 http://127.0.0.1:5500/research-notes/ 로 접근하세요.</p>';
        // eslint-disable-next-line no-console
        console.error(err);
      });
  }

  function initFaq() {
    // <details> 기본 동작에 맡기고, 클릭 시 외부 다른 FAQ가 자동으로 닫히지는 않음 (accordion 강요 X)
    // 필요 시 여기서 확장
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      initMatrix();
      initFaq();
    });
  } else {
    initMatrix();
    initFaq();
  }
})();
