# ACP Enhanced

Addon Control Panel for World of Warcraft 3.3.5a (WotLK): an in-game addon manager with addon sets, opened from the **AddOns** button of the game menu or with `/acp`.

Based on **ACP** by **sylvanaar, Rophy and Saien** (WotLK Community Edition maintained by Mapache-Warmane2077), MIT license. All credit for the original addon goes to its authors.

## What this version does differently

- **Per-zone addon sets.** In the Sets menu, each set can be marked *Use in battlegrounds*, *Use in arenas* or *Use everywhere else*. When you enter a zone whose set is not loaded, a window asks to switch to that set and reload. If the right set is already loaded, it does nothing.
- **Lower memory use.** Only the language in use stays in memory; the other translations are released after loading.
- **Smoother list.** Addon memory is refreshed at most every 5 seconds instead of on every scroll step and click.

## Installation

1. Download this repository (**Code → Download ZIP**).
2. Copy the `ACP` folder into `World of Warcraft/Interface/AddOns/`.
