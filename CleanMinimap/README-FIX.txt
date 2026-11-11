CleanMinimap 1.6.4 - minimap, aura and Dungeon Finder position/scale fix for WoW 3.3.5a

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
