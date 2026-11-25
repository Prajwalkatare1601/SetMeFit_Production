# Skill: High-End UI and Asset Handling

## Intent Triggers
- "Create screen", "Build UI", "Design layout", "Add assets", "Add images/icons"

## Core UI Execution Rules
1. **Never Hardcode Dimensions:** Always enforce responsive layouts using `LayoutBuilder`, `Flexible`, or `Expanded`. 
2. **Strict Design System:** Follow standard Material 3 tokens. Use `Theme.of(context).colorScheme` for all colors and `Theme.of(context).textTheme` for typography. Never pass raw hex colors or explicit font sizes inline unless requested.
3. **Immersive Elements:** Prioritize modern layout styling:
   - Use `SliverAppBar` for high-end scrolling animations on content-heavy screens.
   - Enforce explicit `BorderRadius.circular()` values on all cards and containers to match modern design guidelines.
   - Always wrap actionable components in `InkWell` or `ElevatedButton` with proper feedback states.

## Asset & Resource Management Rules
1. **Strict Asset Path Tracking:** Never guess asset paths. Check `pubspec.yaml` to ensure paths match declared asset directories perfectly.
2. **Vector First:** Prioritize `.svg` formats for icons and illustrations using the `flutter_svg` package.
3. **Raster Scaling:** For images, always use `Image.asset` with explicit `fit: BoxFit.cover` or `BoxFit.contain` inside constrained boundaries to prevent layout overflow crashes (`RenderFlex overflowed`).
4. **Loading & Fallbacks:** Every image asset call must include a loading placeholder or an error fallback widget like a themed icon block:
   ```dart
   Image.asset(
     'assets/images/banner.png',
     errorBuilder: (context, error, stackTrace) => const CustomImageFallback(),
   )
   ```
