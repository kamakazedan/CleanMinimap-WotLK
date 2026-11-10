CleanMinimap 1.6.2 - minimap and aura position/scale fix for WoW 3.3.5a

What changed
------------
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
4. Start the game. The minimap should remain anchored at the top-right at every scale. Buffs, debuffs, consolidated buffs and temporary weapon enchants should appear just to the left of the minimap and move with its scaled edge. Aura icons retain their normal size.

Notes
-----
This build intentionally disables Alt-drag repositioning. The minimap remains in
Blizzard's standard top-right position, as requested. Existing CleanMinimapDB
settings such as square mode, coordinates, zone header, icon size and minimap
scale are retained; only the obsolete saved position fields are cleared.

This is a source-level fix. It has been checked against the 3.3.5a FrameXML anchor/layout logic and statically validated, but cannot be runtime-tested here inside a WoW 3.3.5a client.
