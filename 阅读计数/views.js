/* 阅读计数（2026-11-04）：向自建接口取数/计数，失败就静默降级，不打断页面 */
(function () {
  var API = 'https://api.zyx0407.com/views';

  function paint(slug, n) {
    var els = document.querySelectorAll('[data-views="' + slug + '"]');
    for (var i = 0; i < els.length; i++) els[i].textContent = n;
  }

  function get(slug) {
    fetch(API + '?slug=' + encodeURIComponent(slug), { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (j) { if (j && typeof j.n === 'number') paint(slug, j.n); })
      .catch(function () { /* 取不到就留原样（—） */ });
  }

  function post(slug) {
    fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ slug: slug })
    }).then(function (r) { return r.json(); })
      .then(function (j) { if (j && typeof j.n === 'number') paint(slug, j.n); })
      .catch(function () { });
  }

  function start() {
    var seen = {};
    var nodes = document.querySelectorAll('[data-views]');
    for (var i = 0; i < nodes.length; i++) {
      var s = nodes[i].getAttribute('data-views');
      if (s && !seen[s]) { seen[s] = 1; get(s); }
    }
    var slug = document.body.getAttribute('data-views-post');
    if (slug) {
      try {
        var k = 'viewed:' + slug;
        if (!sessionStorage.getItem(k)) {
          sessionStorage.setItem(k, '1');
          post(slug);
        }
      } catch (e) { /* 隐私模式下忽略 */ }
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
