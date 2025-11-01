# Home Screen

Home delivers the storefront landing surface for the app. It mixes static marketing banners with product discovery widgets and wires navigation hooks into downstream screens such as on-sale, kids, and product detail routes.

## Directory layout

- `views/home_screen.dart` – entry point that composes all slivers inside a `CustomScrollView`.
- `views/components/offer_carousel_and_categories.dart` – groups the hero carousel and the horizontal category list.
- `views/components/offers_carousel.dart` – auto-playing marketing banners (medium size variants).
- `views/components/categories.dart` – pill buttons that deep-link to curated sections.
- `views/components/popular_products.dart` – async loader that surfaces featured inventory via `ProductService`.
- `views/components/most_popular.dart` – lightweight list backed by demo data to highlight trending deals.

## Render pipeline

1. `HomeScreen` builds a `Scaffold > SafeArea > CustomScrollView`.
2. Slivers are added in the order users should see them:
   - `OffersCarouselAndCategories` (hero + navigation affordances).
   - `PopularProducts` (dynamic feed powered by Supabase data through `ProductService`).
   - `BannerSStyle1` marketing block (navigates to `onSaleScreenRoute`).
   - `MostPopular` (secondary feed using `demoPopularProducts`).
   - `BannerSStyle5` closing promotion card.
3. Gutter spacing is controlled by `defaultPadding`; any new sliver should honor that constant for visual harmony.

## Component responsibilities

| Component | Purpose | Notable APIs |
| --- | --- | --- |
| `OffersCarousel` | Auto-scrolls through four medium banners and surfaces dot indicators. | Manages `PageController`, `Timer`, and active index state. |
| `Categories` | Horizontally scrollable pills with optional SVG icons. | Uses `Navigator.pushNamed` when a `route` is provided in `demoCategories`. |
| `PopularProducts` | Fetches featured products asynchronously and displays `ProductCard`s. | `ProductService.getFeaturedProducts(limit: 10)` + `FutureBuilder` for loading/error/empty states. |
| `MostPopular` | Shows mock data via `SecondaryProductCard`s for quick access. | Navigates to `productDetailScreenRoute` using list index. |
| `BannerSStyle1/5` | Promotional large-format cards imported from the shared `Banner` component library. | Hard-coded copy, but accept callbacks for navigation. |

## Data & state notes

- `PopularProducts` is the only widget hitting a backend service. It logs load progress, catches errors, and falls back to an empty list; adapt this if you need richer error UX.
- Skeleton states (`ProductsSkelton`, `BannerSSkelton`, etc.) are already imported/commented. Swap them in during actual data fetches to prevent layout shifts.
- Category and most-popular feeds use local demo lists. Replace with services when real endpoints exist (keep the same builder signatures to avoid churn).

## Extending the screen

- **Add a new promo section:** Introduce another `SliverToBoxAdapter` in `home_screen.dart`, keep padding consistent, and re-use existing banner variants when possible.
- **Wire real categories:** Replace `demoCategories` with a repository call. Consider caching results and handling tap debounce to avoid duplicate navigations.
- **Analytics hooks:** The touch points (`press` callbacks) are centralized per widget; wrap them to emit tracking events before navigation.
- **Theme alignment:** Colors and typography derive from app themes plus `primaryColor`. Any bespoke styles should still read values from `Theme.of(context)` to support light/dark modes.

## Testing & verification checklist

- Confirm the carousel auto-advances every 4 seconds and resumes correctly after manual swipes.
- Validate each navigation target (`onSaleScreenRoute`, `kidsScreenRoute`, `productDetailScreenRoute`) is registered in `screen_export.dart`/`route_constants.dart`.
- Simulate offline mode to see `PopularProducts` fall back to the empty-state message.
- Run `flutter analyze` and `flutter test` after adding new widgets to catch regressions early.

Keep this doc up to date when swapping demo data for real services or when reordering slivers—the layout order is tightly coupled to the merchandising strategy.
