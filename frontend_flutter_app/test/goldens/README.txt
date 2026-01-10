This directory contains golden PNG baselines for widget golden tests.

Scenarios covered include:
- Loaded thumbnails across common sizes + DPRs
- Loading/placeholder state (before image resolves)
- Error state (broken image/error placeholder)
- Lazy-loading phases (deferred/offscreen vs in-view)

To (re)generate goldens:
  flutter test --update-goldens

See docs/image_optimization.md for details (naming conventions, scenarios).
