# frontend_flutter_app

A new Flutter project.

## Getting Started

## Categories & filters (demo)

This app supports local filtering (no backend) using demo recipe metadata:

- **Cuisine** (e.g., Italian, Mexican, Indian)
- **Diet** (e.g., Vegan, Vegetarian, Gluten-Free)
- **Cooking time** buckets: `<15`, `15–30`, `30–60`, `>60`

### Home → Categories
Home includes a **Categories** section (horizontal chips) that quickly filters recipes by cuisine.

### Search → Filters
Search includes multi-select filter chips for cuisine, diet, and cooking time.

- Multiple selections **within the same filter type** are combined as **OR**
- Different filter types are combined as **AND**

An active filter summary is shown with a **Clear all** action.
If no recipes match, an empty-state message is displayed.

### Persistence
The last-used filters are saved to local storage using `SharedPreferences` and restored on next launch.

## Image optimization

See `docs/image_optimization.md` for:
- how thumbnails are sized per layout constraints and devicePixelRatio
- lazy loading behavior (near-viewport network fetch)
- cache eviction policies (memory + disk cache managers)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
