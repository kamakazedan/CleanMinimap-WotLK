# CleanMinimap for WotLK 3.3.5a

CleanMinimap 1.6.2 for World of Warcraft 3.3.5a, with fixes and additions. CleanMinimap gives you a clean square (or round) minimap with a thin black border, the zone name above it, optional coordinates and the default minimap icons tidied down its left side.

## Installing

1. Download the repository (**Code → Download ZIP**) and extract it.
2. Copy the `CleanMinimap` folder into `World of Warcraft\Interface\AddOns\`, replacing any older copy. The folder must be named `CleanMinimap`.
3. Restart the game if it's running. A full restart is needed when an update adds texture files, because `/reload` won't load new files.

The settings are under **Interface → AddOns → CleanMinimap**.

## Changes from 1.6.2

- The minimap is pinned to the top-right corner and keeps the same gap to the top and right of the screen at every scale. The quest tracker, durability figure and buffs follow it instead of drifting away, and the buffs sit to its left rather than underneath. The old Alt-drag option to move the minimap is gone.
- The zone name sits just above the map, centred on it, with no box behind it, in square and round mode.
- The border stays the thickness it has at 100% however large you make the minimap. Round mode uses a thin black ring to match the square border, instead of Blizzard's gold frame.
- Every minimap icon sits on the minimap's border and is the same size, set by **Icon size**: tracking, mail, battleground, Dungeon Finder, the calendar, and other addons' round buttons (LibDBIcon buttons and others with the standard gold ring). Drag any of them round the border to move it. CleanMinimap does the dragging for every icon, so they all keep up with the cursor at any minimap scale, and it remembers where you leave each one. **Tidy addon minimap buttons** hands other addons' buttons back to them, at the places their addons have saved. Icons drawn inside the map, such as quest objectives, are sized by their own addons.
- Markers other addons draw on the map, such as quest objectives, gathering nodes and waypoints, stay under the border and under every icon instead of covering them. Bags and windows still cover the minimap as usual.
- Dragging an addon's minimap button in round mode no longer causes a Lua error. 1.6.2 described the round minimap to other addons with a shape name that LibDBIcon doesn't recognise.
- The world map no longer jumps back to your zone while you're browsing it. 1.6.2 moved the game's map to your zone every time you entered a new one, even with the world map open, so on a flight it snapped back at every zone you passed through.
- Blizzard's calendar button is shown (1.6.2 hid it); **Show calendar** turns it off.
- The Dungeon Finder's "Assembling Group..." popup is drawn at normal size instead of at the minimap's scale.
- New options: **Show border** turns the border off, and **Minimap opacity** makes the minimap see-through. In buildings, dungeons and cities such as Orgrimmar it stays fully opaque, because the game can't draw those maps see-through.
- Mouse-wheel zoom, and clicking the zone name to hide the map, work in round mode as well as square.

The first commit is the 1.6.2-fixed build these changes started from: the CurseForge 1.6.2 release with an earlier fix that pinned the minimap to the corner and moved the buffs (see `CleanMinimap/README-FIX.txt`). Each later commit is one version, so the history shows every change after that.

## Credits

CleanMinimap is by Alexia and Valle. It includes the Ace3 libraries.
