# Loyalty card colors

The canonical API/database field is `LoyaltyCard.visualStyle.primaryColor`, an uppercase `#RRGGBB` string. Create/Edit preserves other visual style metadata. Both backend card write routes validate the six-digit hex format and normalize casing. Legacy documents need no migration.

`CardColor` reads a business card or joined customer card. It prefers `visualStyle.primaryColor`, then a legacy `cardColor`, then `visualStyle.theme`. Missing or invalid colors become `#0B6B63`. Legacy names and zero-based indices use the original Create Card swatches' first gradient stops:

| Theme / index | Color |
| --- | --- |
| coral / 0 | #FF8368 |
| teal / 1 | #14B8A6 |
| purple / 2 | #8B7FF5 |
| gold / 3 | #FFC658 |

The picker uses Flutter CustomPainter/gestures for saturation and brightness, a hue Slider, live hex validation, and live previews; no package was added. Cancel or dismiss restores the previous selection.

`CardPalette` caches up to 256 palettes and derives same-hue HSL gradient stops, text/icons, punch tokens, borders and overlays. Gradient lightness is adjusted further when necessary to keep white or `#14201F` text at least 4.5:1 across the gradient. Thus colors in the middle luminance range may render slightly lighter or darker than the saved base.

Shared surfaces cover Home deck layers, customer card detail, Explore tiles/transition/detail, the business dashboard card, Create/Edit preview and picker preview. Explore businesses without a card retain the original tint cycle. No loyalty card surface was omitted.

Customer REST responses join the current business card rather than copying its color. Home/Explore pull-to-refresh receives edits; Home also refreshes after returning from card detail. Customer card detail fetches the current card on open and supports pull-to-refresh. An already-open Explore detail uses the Explore snapshot: refresh Explore and reopen the detail to see an edit. This is REST refresh behavior, without a new realtime subscription.

Verification includes hex/legacy/fallback/contrast tests, preset/custom/drag/cancel/invalid picker behavior, keyboard layout, edit request metadata preservation, deck refresh colors, and 360px RTL/large text layouts. Release version: 1.0.5 (6).
