CleanMinimap 1.7.3 - minimap, aura and Dungeon Finder position/scale fix for WoW 3.3.5a

What changed in 1.7.3
---------------------
- The world map no longer jumps to your zone while you're browsing it. On
  every zone change CleanMinimap puts the game's map on your new zone, so
  its coordinates keep working, and it did that even with the world map
  open: on a flight it pulled the map back to you at every zone you passed
  through. It now leaves the map alone while the world map is open.
  Blizzard's world map puts the game's map back on your zone when it
  closes, so the coordinates still come right. While the world map shows a
  zone you're not in, the coordinates read 0,0 until you close it, as they
  always have when browsing.

What changed in 1.7.2
---------------------
- Every icon drags the same way. CleanMinimap now does the dragging for
  other addons' buttons as well as its own icons, instead of leaving it to
  each addon's drag code, so every icon keeps up with the cursor. Some
  addons' drag code (AtlasLootFu's, for one) measures the cursor as if the
  minimap were at 100% scale; with the minimap scaled up, their buttons
  crawled a few degrees for a whole lap of the cursor. A button its addon
  gave no drag at all can now be dragged too.
- CleanMinimap saves where you leave each addon's button (by the button's
  name), so it stays there after a reload. A button you haven't dragged yet
  starts where its addon puts it. Turning "Tidy addon minimap buttons" off
  hands each button back to its addon, at the place its addon has saved.

What changed in 1.7.1
---------------------
- Map markers (quest objectives, gathering nodes, waypoints and other
  addons' pins) no longer cover the minimap's icons or draw across its
  border. Blizzard draws the minimap and every marker on it in the
  BACKGROUND strata, where each addon picks its own frame level, so a marker
  could land on top of the calendar or across the ring. CleanMinimap now
  puts what it draws round the map one strata up (LOW): the border, then the
  north marker, clock, zone name and dungeon difficulty flag, then every
  icon. Markers slide under the border and never cover an icon, and bags
  and windows (MEDIUM) still cover the minimap as before. Other addons'
  buttons join the icon layer while "Tidy addon minimap buttons" is on and
  get their own layer back when it's off.
- Fixed a Lua error (LibDBIcon-1.0.lua:184, "attempt to index local
  'quadTable'") when dragging an addon's minimap button, such as Questie's,
  in round mode. GetMinimapShape() answered "CIRCULAR", which isn't one of
  the standard shape names LibDBIcon knows; it now answers "ROUND". The bug
  dates back to the original 1.6.2.

What changed in 1.7.0
---------------------
- Every minimap icon now works the same way. Blizzard's tracking, mail,
  battleground, Dungeon Finder and calendar icons join other addons' buttons
  on the minimap's border instead of sitting in a column beside it, so they
  no longer drift away from the map as Icon size goes up.
- All icons are the same size. Blizzard's icons keep their normal gold ring
  and layout (CleanMinimap used to hide the rings and resize the insides,
  which is why the sizes never matched) and every icon is scaled whole to
  one ring size set by "Icon size".
- Drag any icon round the border to move it. CleanMinimap saves where
  Blizzard's icons go; other addons still save their own buttons. Their
  default places are down the left side, in the order they used to be
  stacked; at large icon sizes, drag them apart.
- The cluster's width follows the icon size, so the buffs stay just clear
  of icons on the left border.

What changed in 1.6.9
---------------------
- Other addons' round minimap buttons are tidied, not just resized: every
  one is the same size (following "Icon size") and sits centred on the
  minimap's border, square or round, at the angle its addon puts it. Drag a
  button and it slides round the border with the cursor; its addon still
  saves where you leave it. Buttons that their addon lets you drag anywhere
  snap back onto the border, in the direction you dropped them. Near the
  screen's right and top edges a button sits further over the map so it
  stays on screen. The option is now called "Tidy addon minimap buttons";
  turning it off hands every button back to its addon as it was.

What changed in 1.6.8
---------------------
- Other addons' round minimap buttons (LibDBIcon buttons, and buttons with
  Blizzard's standard gold-ring border) follow the "Icon size" option, the
  same size as the calendar, instead of growing with the minimap scale. Each
  keeps the position its addon gives it and can still be dragged. Buttons an
  addon already scales itself, and protected buttons, are left alone. A new
  option, "Resize addon minimap buttons", turns this off. Icons drawn inside
  the map (quest objectives, gathering nodes) are sized by their own addons.

What changed in 1.6.7
---------------------
- Blizzard's calendar button is shown again (CleanMinimap used to hide it).
  It has its own slot at the bottom of the icon column left of the minimap,
  below the Dungeon Finder slot, so it never moves when the mail,
  battleground or Dungeon Finder icons appear. It follows the "Icon size"
  option, and a new "Show calendar" option hides it.

What changed in 1.6.6
---------------------
- Fixed the map vanishing (a dark see-through square left behind) in cities
  such as Orgrimmar when "Minimap opacity" is below 100%. The game can't draw
  indoor-style maps see-through, and 1.6.5 only went fully opaque when
  IsIndoors() said so, which is false in places like the Valley of Strength.
  It now also checks which zoom mode the minimap itself is in (indoor or
  outdoor), the same check the Astrolabe map library uses, and stays fully
  opaque whenever the minimap is showing an indoor-style map.

What changed in 1.6.5
---------------------
- The map keeps the same gap to the right and top edges of the screen at every
  scale (17 UI units, Blizzard's gap at 100%). The cluster stays pinned to the
  top-right corner and is sized to wrap the map, so the quest tracker,
  durability figure and buffs follow the map instead of drifting away.
- The zone name sits just above the map (or its border), centred on it, in
  both square and round mode. Its top stays 5 UI units from the top of the
  screen. The box behind it is gone in round mode too.
- Round mode uses a thin black ring like the square bezel, instead of
  Blizzard's gold border. Like the bezel, it keeps its 100% thickness above
  100% scale. Mouse-wheel zoom now also works in round mode.
- New option "Show border" turns the square bezel / round ring off.
- New option "Minimap opacity" (10-100%) fades the whole minimap: map, border,
  icons and zone name. Indoors it stays fully opaque, because the game can't
  draw the indoor map see-through. The Dungeon Finder popup is moved to
  UIParent so it is never faded or scaled.
- Clicking the zone name hides/shows the map in round mode as well as square.
- New texture files (texture/Ring1-5.tga), so restart the game fully after
  installing; /reload won't pick them up.

What changed in 1.6.4
---------------------
- The black square border no longer gets thicker as the minimap scale goes
  above 100%. It stays the thickness it has at 100%, however large the map is.
  At or below 100% it behaves as before.
- The box behind the zone name above the square minimap has been removed; the
  zone name is shown on its own.

What changed in 1.6.3
---------------------
- The Dungeon Finder eye (MiniMapLFGFrame) now has its own slot in the icon
  column left of the minimap, below the battleground icon, instead of
  Blizzard's round-minimap spot over the map's left edge. It scales and moves
  with the minimap, follows the "Icon size" option, and its round border is
  hidden like the other icons.
- The Dungeon Finder status popup ("Assembling Group...", LFDSearchStatus) is
  drawn at the normal UI scale again. Blizzard parents it to the eye, so it was
  inheriting the minimap scale; it is now counter-scaled each time it opens and
  kept on screen.

What changed in 1.6.2
---------------------
- The minimap cluster is anchored to TOPRIGHT of UIParent at all times.
- Legacy per-character posx/posy saved by older versions are ignored and cleared.
- The old Alt-drag movement and unconditional mouse-up position saving were removed.
- Scale values are clamped to the addon's advertised 0.1-3.0 range.
- Blizzard's original Minimap mouse-up click handler is left intact.
- BuffFrame, ConsolidatedBuffs and TemporaryEnchantFrame are moved to the left of the minimap.
- Aura-frame anchors follow MinimapCluster scale while icon, counter and timer sizes remain at Blizzard defaults.
- Aura-frame anchors are re-applied after Blizzard frame management, consolidation and weapon-enchant transitions.

Installation
------------
1. Exit World of Warcraft completely.
2. Back up or rename Interface/AddOns/CleanMinimap.
3. Extract the CleanMinimap folder from this archive into Interface/AddOns.
4. Start the game. The minimap should remain anchored at the top-right at every scale. Buffs, debuffs, consolidated buffs and temporary weapon enchants should appear just to the left of the minimap and move with its scaled edge. Aura icons retain their normal size. When queued for a dungeon, the eye should sit in the icon column left of the minimap, and hovering it should show the "Assembling Group..." popup at the same size as your other UI panels, whatever the minimap scale.

Notes
-----
This build intentionally disables Alt-drag repositioning. The minimap remains in
Blizzard's standard top-right position, as requested. Existing CleanMinimapDB
settings such as square mode, coordinates, zone header, icon size and minimap
scale are retained; only the obsolete saved position fields are cleared.

This is a source-level fix. It has been checked against the 3.3.5a FrameXML anchor/layout logic and statically validated, but cannot be runtime-tested here inside a WoW 3.3.5a client.
