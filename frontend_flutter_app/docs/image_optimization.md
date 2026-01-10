# Image optimization / thumbnails

This app uses a small thumbnail utility to reduce memory usage and network/image decode cost on different devices and tile sizes.

## Goals

- Decode images close to the **rendered** size based on:
  - `BoxConstraints` (layout size in logical pixels)
  - `MediaQuery.devicePixelRatio` (1x/2x/3x…)
- Use `cacheWidth`/`cacheHeight` equivalents to avoid decoding full-resolution images for thumbnails.
- Avoid layout shifts by reserving space with `AspectRatio`.
- Keep API surface minimal and non-breaking.

## How it works

- `ThumbnailProvider.computeFromConstraints(...)` converts logical size + DPR → **physical** pixel target (`memCacheWidth`/`memCacheHeight` for network).
- Values are clamped (`minPhysicalPx`, `maxPhysicalPx`) and snapped to multiples of 8 to increase cache hits across similar sizes.
- Network images use `CachedNetworkImage(memCacheWidth/memCacheHeight)`.
- Asset/file/provider images use `ResizeImage(... width/height ...)`.
- Thumbnails default to `BoxFit.cover` for center-crop behavior.

## Usage

```dart
Thumbnail.image(
  url: recipe.imageUrl,
  aspectRatio: 16 / 9,
  fit: BoxFit.cover,
)
```

Provide exactly one source: `url`, `file`, `asset`, or `provider`.

## Lazy loading (near-viewport)

To avoid fetching/decoding images for offscreen list/grid items, the app uses a
viewport-aware wrapper (`LazyLoad`) around network images:

- `GridView.builder` / `ListView.builder` provide lazy widget construction.
- `LazyLoad` defers building `CachedNetworkImage` until the widget is near the
  viewport (using `Scrollable.recommendDeferredLoadingForContext` + a preload margin).
- Placeholders reserve space via `AspectRatio` to avoid layout shift.

This is integrated via `Thumbnail.image(lazy: true)` for list and grid tiles.

## Cache eviction policy

This app controls caching at two levels:

### 1) Flutter in-memory decoded image cache (ImageCache)

Configured in `main.dart` via `AppImageCachePolicy.configureMemoryCache(...)`:

- `maximumSize`: max number of decoded image entries kept in memory
- `maximumSizeBytes`: max bytes of decoded image memory

On memory pressure / backgrounding, `ImageCacheLifecycleObserver` trims the cache.

### 2) Disk cache (cached_network_image / flutter_cache_manager)

Two separate disk cache stores are used:

- Thumbnails: `recipe_thumbnails_v1` (more objects, shorter stale period)
- Full-size: `recipe_fullsize_v1` (fewer objects, longer stale period)

This helps balance performance and storage while keeping thumbnails responsive.

## Integration points

- Recipe list cards (`RecipeCard`) -> `Thumbnail.image(lazy: true)`
- Recipe grid tiles (`RecipeGridTile`) -> `Thumbnail.image(lazy: true)`
- Recipe detail header (`RecipeDetailScreen`) -> `Thumbnail.image(useFullSizeCache: true)`
