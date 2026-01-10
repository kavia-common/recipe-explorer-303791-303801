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

## Integration points

- Recipe list cards (`RecipeCard`)
- Recipe grid tiles (`RecipeGridTile`)
- Recipe detail header (`RecipeDetailScreen`)
