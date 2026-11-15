CleanMinimap = LibStub("AceAddon-3.0"):NewAddon("CleanMinimap", "AceEvent-3.0")
CleanMinimap.title = "CleanMinimap"
local self = CleanMinimap
local shape = "SQUARE";

CleanMinimap.defaults = {
	profile = {
		UseSquare = true,
		ShowBorder = true,
		ShowCoord = true,
		ShowZone = true,
		ShowDura = true,
		ShowTrack = true,
		ShowMail = true,
		ShowCalendar = true,
		ScaleAddonButtons = true,
		-- Where CleanMinimap's own icons sit on the border, in degrees
		-- (0 = right, 90 = top): down the left side, in the order they
		-- used to be stacked.
		IconAngles = {
			tracking = 150,
			mail = 172,
			battlefield = 194,
			lfg = 216,
			calendar = 238,
		},
		-- Where other addons' buttons were last dragged to, in degrees, by
		-- button name. Buttons not in here go where their addons put them.
		AddonButtonAngles = {},
		Scale = 1,
		Alpha = 1,
		IconScale = 18,
	}
}

CleanMinimap.options = {
	name = "CleanMinimap",
	desc = self.notes,
	handler = CleanMinimap,
	type = 'group',
	args = {
		General = {
			name = "General Options",
			desc = '',
			order = 1,
			type = 'group',
			guiInline = true,
			args = {
				UseSquare = {
					type = 'toggle',
					name = "Use square minimap",
					desc = "Use the default square minimap.",
					get = "GetUseSquare",
					set = "SetUseSquare",
					width = 'full',
					order = 1,
				},
				ShowBorder = {
					type = 'toggle',
					name = "Show border",
					desc = "Toggle the thin black border around the minimap.",
					get = "GetShowBorder",
					set = "SetShowBorder",
					width = 'full',
					order = 1.5,
				},
				ShowCoord = {
					type = 'toggle',
					name = "Show coordinates",
					desc = "Toggle the coordinates on the minimap.",
					get = "GetShowCoord",
					set = "SetShowCoord",
					width = 'full',
					order = 2,
				},
				ShowZone = {
					type = 'toggle',
					name = "Show zone header",
					desc = "Toggle the zone header on the minimap.",
					get = "GetShowZone",
					set = "SetShowZone",
					width = 'full',
					order = 3,
				},
				ShowDura = {
					type = 'toggle',
					name = "Show durability figure",
					desc = "Toggle the durability figure below the minimap.",
					get = "GetShowDura",
					set = "SetShowDura",
					width = 'full',
					order = 4,
				},
				ShowTrack = {
					type = 'toggle',
					name = "Show tracking icon",
					desc = "Toggle the tracking icon for herbs, minerals, and others.",
					get = "GetShowTrack",
					set = "SetShowTrack",
					width = 'full',
					order = 5,
				},
				ShowMail = {
					type = 'toggle',
					name = "Show mail icon",
					desc = "Toggle the mail icon visibility.",
					get = "GetShowMail",
					set = "SetShowMail",
					width = 'full',
					order = 6,
				},
				ShowCalendar = {
					type = 'toggle',
					name = "Show calendar",
					desc = "Toggle the calendar button, below the other icons beside the minimap.",
					get = "GetShowCalendar",
					set = "SetShowCalendar",
					width = 'full',
					order = 6.5,
				},
				ScaleAddonButtons = {
					type = 'toggle',
					name = "Tidy addon minimap buttons",
					desc = "Give other addons' round minimap buttons all the same size, following the Icon size option, and line them up on the minimap's border. Drag them round the border to move them.",
					get = "GetScaleAddonButtons",
					set = "SetScaleAddonButtons",
					width = 'full',
					order = 6.6,
				},
				Scale = {
					type = 'range',
					name = "Minimap scale",
					desc = "Increases or decreases the size of the minimap.",
					max = 3,
					min = 0.1,
					step = 0.1,
					get = "GetScale",
					set = "SetScale",
					width = 'full',
					order = 7,
				},
				Alpha = {
					type = 'range',
					name = "Minimap opacity",
					desc = "Makes the minimap, its border, icons and zone header see-through. Inside buildings, dungeons and cities such as Orgrimmar the minimap stays fully opaque, because the game cannot draw those maps see-through.",
					max = 1,
					min = 0.1,
					step = 0.05,
					isPercent = true,
					get = "GetMinimapAlpha",
					set = "SetMinimapAlpha",
					width = 'full',
					order = 7.5,
				},
				IconScale = {
					type = 'range',
					name = "Icon size",
					desc = "The size of every icon on the minimap's border: tracking, mail, battleground, Dungeon Finder, calendar and other addons' buttons. Drag any of them round the border to move it.",
					max = 48,
					min = 6,
					step = 1,
					get = "GetIconScale",
					set = "SetIconScale",
					width = 'full',
					order = 8,
				},
			},
		},
	}
}

function GetMinimapShape()
	return shape;
end

-- Backdrop for the black square border (borderFrame). UpdateBorder()
-- adjusts edgeSize and insets to suit the minimap scale.
local backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile =true, tileSize =4,
	edgeFile = "Interface\\Addons\\CleanMinimap\\Texture\\Plain.tga", edgeSize = 4,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
}

local backdropmail = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile =true, tileSize =4,
	edgeFile = "Interface\\Addons\\CleanMinimap\\Texture\\Plain.tga", edgeSize = 4,
	insets = {left = 0, right = 0, top = 0,bottom = 0},
}

local CleanMinimapFrame = CreateFrame("Frame", nil, Minimap);
local loc, text, track;

-- Layers. Blizzard draws the whole minimap in the BACKGROUND strata, and the
-- markers addons put on the map (quest objectives, gathering nodes,
-- waypoints) are children of the map there, each at whatever frame level its
-- addon picks, often above Blizzard's own buttons and the border. Everything
-- CleanMinimap puts round the map goes one strata up instead, which is above
-- any frame level down there and still under bags and windows (MEDIUM):
-- first the border, then the north marker, clock, zone name and dungeon
-- difficulty flag, then the icons. So markers slide under the border and
-- never cover an icon.
local LAYER_STRATA = "LOW"
local BORDER_LEVEL = 2
local FURNITURE_LEVEL = 5
local ICON_LEVEL = 10
local strataOrder = {
	BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5,
	FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8,
}
-- Frames in the icon layer. Layering anything else leaves them alone, so the
-- tracking and Dungeon Finder icons (children of MinimapBackdrop) stay above
-- the furniture.
local iconFrames = {}

-- A frame and the child frames that move with it, each with its level
-- relative to the frame's, every child kept above its parent. Protected
-- frames, icons, and children deliberately put in a higher strata than their
-- parent (popups and menus) are left out.
local function CollectLayer(frame, rel, base, frames, offsets)
	frames[#frames + 1] = frame
	offsets[#offsets + 1] = rel
	local strata = strataOrder[frame:GetFrameStrata()] or 0
	for _, child in ipairs({ frame:GetChildren() }) do
		if not iconFrames[child] and not child:IsProtected()
				and (strataOrder[child:GetFrameStrata()] or 0) <= strata then
			CollectLayer(child, math.max(rel + 1, child:GetFrameLevel() - base), base, frames, offsets)
		end
	end
end

-- Put a frame, with its child frames, in a strata at a frame level.
local function SetLayer(frame, strata, level)
	if not frame or frame:IsProtected() then
		return
	end
	local frames, offsets = {}, {}
	CollectLayer(frame, 0, frame:GetFrameLevel(), frames, offsets)
	for i, f in ipairs(frames) do
		f:SetFrameStrata(strata)
		f:SetFrameLevel(level + offsets[i])
	end
end

-- The square bezel or round ring is drawn on a frame of its own, in the
-- border layer. CleanMinimapFrame, which catches the mouse wheel over the
-- map, stays down with the map, so it never takes a marker's mouse-over.
local borderFrame = CreateFrame("Frame", nil, Minimap)
borderFrame:SetAllPoints(CleanMinimapFrame)

-- Layout. These gaps stay the same on screen at every minimap scale, so they
-- are in UIParent units and get divided by the scale before use.
local EDGE_GAP = 17        -- screen's right (and top, with no zone name) edge to the map; Blizzard's 100% gap
local HEADER_TOP_GAP = 5   -- screen's top edge to the zone name
local ICON_MARGIN = 7      -- left of the icon column, before the buffs
-- These scale with the minimap, in minimap units.
local ZONE_HEIGHT = 12     -- the zone name's text box (Blizzard's size)
local ZONE_GAP = 2         -- zone name to the border, or to the map with no border
local BOTTOM_SPACE = 30    -- below the map, for the clock; Blizzard's default

-- Round border: four quarter-ring textures around the map's centre. A
-- texture's ring thickness is fixed relative to its size, so there are five
-- (Ring1 = 100% scale ... Ring5 = 300%) and UpdateBorder picks the closest.
-- Each matches the square bezel: 4f thick, 3f outside the map's edge and 1f
-- over it, where f = 1/scale above 100%. The ring's outer edge is 252/256 of
-- the way to each texture's edge.
local RING_EDGE = 252 / 256
local ringRatios = {}  -- thickness / outer radius, as in make_rings.py
for k = 1, 5 do
	local f = 3 ^ (-(k - 1) / 4)
	ringRatios[k] = 4 * f / (70 + 3 * f)
end
local ringQuads = {}
do
	-- point on the texture that sits on the map's centre, then tex coords
	-- (mirrored copies of the one top-right quarter).
	local quads = {
		{ "BOTTOMLEFT",  0, 1, 0, 1 },  -- top-right quarter
		{ "BOTTOMRIGHT", 1, 0, 0, 1 },  -- top-left
		{ "TOPLEFT",     0, 1, 1, 0 },  -- bottom-right
		{ "TOPRIGHT",    1, 0, 1, 0 },  -- bottom-left
	}
	for i, q in ipairs(quads) do
		local tex = borderFrame:CreateTexture(nil, "ARTWORK")
		tex:SetPoint(q[1], Minimap, "CENTER", 0, 0)
		-- Kept so they can be re-applied after each SetTexture.
		tex.l, tex.r, tex.t, tex.b = q[2], q[3], q[4], q[5]
		tex:SetTexCoord(q[2], q[3], q[4], q[5])
		tex:SetVertexColor(0, 0, 0)
		tex:SetAlpha(0.6)
		tex:Hide()
		ringQuads[i] = tex
	end
end

function MessageCoords()
	if (UnitInRaid("player")) then
		SendChatMessage("My coordinate location is " .. text:GetText() .. ".", "RAID");
	elseif (GetNumPartyMembers() > 0) then
		SendChatMessage("My coordinate location is " .. text:GetText() .. ".", "PARTY");
	else
		SendChatMessage("My coordinate location is " .. text:GetText() .. ".", "SAY");
	end
end


function CleanMinimap:GetUseSquare()
	return self.db.profile.UseSquare
end
function CleanMinimap:SetUseSquare()
	self.db.profile.UseSquare = not self.db.profile.UseSquare
	self:ApplyShape()
	self:UpdateLayout()
end
function CleanMinimap:GetShowBorder()
	return self.db.profile.ShowBorder
end
function CleanMinimap:SetShowBorder()
	self.db.profile.ShowBorder = not self.db.profile.ShowBorder
	self:UpdateLayout()
end
function CleanMinimap:GetShowCoord()
	return self.db.profile.ShowCoord
end
function CleanMinimap:SetShowCoord()
	self.db.profile.ShowCoord = not self.db.profile.ShowCoord
	if (self.db.profile.ShowCoord) then
		text:Show()
	else
		text:Hide()
	end
end
function CleanMinimap:GetShowZone()
	return self.db.profile.ShowZone
end
function CleanMinimap:SetShowZone()
	self.db.profile.ShowZone = not self.db.profile.ShowZone
	self:UpdateLayout()
end

function CleanMinimap:GetShowDura()
	return self.db.profile.ShowDura
end
function CleanMinimap:SetShowDura()
	self.db.profile.ShowDura = not self.db.profile.ShowDura
	if (self.db.profile.ShowDura) then
		DurabilityFrame:Show()
		DurabilityFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
	else
		DurabilityFrame:Hide()
		DurabilityFrame:UnregisterEvent("UPDATE_INVENTORY_ALERTS")
	end
end

function CleanMinimap:GetShowTrack()
	return self.db.profile.ShowTrack
end
function CleanMinimap:SetShowTrack()
	self.db.profile.ShowTrack = not self.db.profile.ShowTrack
	if (self.db.profile.ShowTrack) then
		MiniMapTracking:Show();
	else
		MiniMapTracking:Hide();
	end
end

function CleanMinimap:GetShowMail()
	return self.db.profile.ShowMail
end
function CleanMinimap:SetShowMail()
	self.db.profile.ShowMail = not self.db.profile.ShowMail
	if (self.db.profile.ShowMail) then
		MiniMapMailFrame:Show();
	else
		MiniMapMailFrame:Hide();
	end
end
function CleanMinimap:GetShowCalendar()
	return self.db.profile.ShowCalendar
end
function CleanMinimap:SetShowCalendar()
	self.db.profile.ShowCalendar = not self.db.profile.ShowCalendar
	self:UpdateOwnIcons()
end
function CleanMinimap:GetScaleAddonButtons()
	return self.db.profile.ScaleAddonButtons
end
function CleanMinimap:SetScaleAddonButtons()
	self.db.profile.ScaleAddonButtons = not self.db.profile.ScaleAddonButtons
	self:UpdateAddonButtons()
end

-- Keep Blizzard's player aura frames outside the minimap and at the same scale.
-- In WotLK 3.3.5a these are separate UIParent frames, not children of MinimapCluster.
function CleanMinimap:PositionAuraFrames()
	if not self.db or not self.db.profile or not MinimapCluster then
		return
	end

	-- Keep Blizzard's normal aura icon size. Because the anchors are relative
	-- to MinimapCluster, the positions/offsets follow its effective scale.
	if BuffFrame then
		BuffFrame:ClearAllPoints()
		BuffFrame:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -13, -13)
	end

	-- Consolidated buffs are a separate button, and debuffs can anchor to it.
	-- The larger consolidation texture needs a little extra clearance.
	if ConsolidatedBuffs then
		ConsolidatedBuffs:ClearAllPoints()
		ConsolidatedBuffs:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -30, -13)
	end

	-- Temporary weapon enchants are another independent frame. Keep it beside
	-- the consolidation button, matching Blizzard's shown/hidden arrangement.
	if TemporaryEnchantFrame then
		TemporaryEnchantFrame:ClearAllPoints()
		if ConsolidatedBuffs and ConsolidatedBuffs:IsShown() then
			TemporaryEnchantFrame:SetPoint("TOPRIGHT", ConsolidatedBuffs, "TOPLEFT", -6, 0)
		elseif ConsolidatedBuffs then
			TemporaryEnchantFrame:SetPoint("TOPRIGHT", ConsolidatedBuffs, "TOPRIGHT", 0, 0)
		else
			TemporaryEnchantFrame:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -30, -13)
		end
	end
end

-- Every icon on the minimap -- CleanMinimap's own and other addons' -- is the
-- same size: the width of its ring, in minimap units, set by Icon size.
function CleanMinimap:IconFootprint()
	local size = 18
	if self.db and self.db.profile then
		size = tonumber(self.db.profile.IconScale) or 18
	end
	return (size + 6) * 33 / 40
end

-- CleanMinimap's own icons: Blizzard's tracking, mail, battleground, Dungeon
-- Finder and calendar buttons. Each keeps Blizzard's normal ringed look and
-- layout and is scaled as a whole, the same way as other addons' buttons, so
-- they all come out the same size. Each sits centred on the border at its
-- saved angle (IconAngles, in degrees); drag one to move it round the border.
-- footprint: the width of its ring at scale 1, in minimap units.
local ownIcons = {
	tracking = { frame = "MiniMapTracking", handle = "MiniMapTrackingButton", footprint = 33 },
	mail = { frame = "MiniMapMailFrame", footprint = 33 },
	battlefield = { frame = "MiniMapBattlefieldFrame", footprint = 33 },
	lfg = { frame = "MiniMapLFGFrame", footprint = 33 },
	calendar = { frame = "GameTimeFrame", footprint = 34 },
}
for _, info in pairs(ownIcons) do
	if _G[info.frame] then
		iconFrames[_G[info.frame]] = true
	end
end

function CleanMinimap:PlaceOwnIcon(key)
	local info = ownIcons[key]
	local frame = info and _G[info.frame]
	if not frame or not self.db or not self.db.profile then
		return
	end
	local angles = self.db.profile.IconAngles
	local angle = math.rad(tonumber(angles and angles[key]) or 180)
	local k = self:IconFootprint() / info.footprint
	frame:SetScale(k)
	self:PlaceOnBorder(frame, angle, k, info.footprint)
end

function CleanMinimap:UpdateOwnIcons()
	for key, info in pairs(ownIcons) do
		-- In the icon layer, above the map's markers.
		local frame = _G[info.frame]
		if frame then
			iconFrames[frame] = true
			SetLayer(frame, LAYER_STRATA, ICON_LEVEL)
		end
		self:PlaceOwnIcon(key)
	end
	if GameTimeFrame and self.db and self.db.profile then
		if self.db.profile.ShowCalendar then
			GameTimeFrame:Show()
		else
			GameTimeFrame:Hide()
		end
	end
end

-- Dragging. Every icon round the border, CleanMinimap's own (key) and other
-- addons' buttons (button), is dragged by this one frame: while the mouse
-- is held it puts the icon at the cursor's direction from the map's centre,
-- worked out in the minimap's own units, so every icon keeps up with the
-- cursor the same way. Addons' own drag code isn't relied on for this: some
-- measure the cursor as if the minimap were at 100% scale, so with it scaled
-- up their buttons crawl a few degrees for a whole lap of the cursor.
local iconDragFrame = CreateFrame("Frame")
iconDragFrame:Hide()

-- Finish a drag. An addon button's place is saved by name, so it stays where
-- it was left (CleanMinimap's own icons save theirs as they move).
function CleanMinimap:EndIconDrag()
	local button = iconDragFrame.button
	iconDragFrame:Hide()
	iconDragFrame.key, iconDragFrame.button = nil, nil
	if button and button.cleanMinimapAngle and self.db and self.db.profile then
		local name = button:GetName()
		if name and self.db.profile.AddonButtonAngles then
			self.db.profile.AddonButtonAngles[name] = math.deg(button.cleanMinimapAngle) % 360
		end
		self:PlaceAddonButton(button)
	end
end

iconDragFrame:SetScript("OnUpdate", function(frame)
	local mx, my = Minimap:GetCenter()
	if not mx or not CleanMinimap.db or not (frame.key or frame.button) then
		return
	end
	local cx, cy = GetCursorPosition()
	local ms = Minimap:GetEffectiveScale()
	local angle = math.atan2(cy / ms - my, cx / ms - mx)
	if frame.key then
		CleanMinimap.db.profile.IconAngles[frame.key] = math.deg(angle) % 360
		CleanMinimap:PlaceOwnIcon(frame.key)
	else
		frame.button.cleanMinimapAngle = angle
		CleanMinimap:PlaceAddonButton(frame.button)
	end
	-- In case a drag ends without its stop script running (say the icon
	-- was hidden mid-drag).
	if not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then
		CleanMinimap:EndIconDrag()
	end
end)

function CleanMinimap:SetUpOwnIcons()
	-- Show the rings CleanMinimap used to hide. Everything else about these
	-- buttons stays at Blizzard's sizes, so their own press and click
	-- scripts work as Blizzard wrote them.
	MiniMapTrackingBackground:Show()
	MiniMapTrackingButtonBorder:Show()
	MiniMapMailBorder:Show()
	MiniMapBattlefieldBorder:Show()
	if MiniMapLFGFrameBorder then
		MiniMapLFGFrameBorder:Show()
	end
	-- Left-drag to move. A drag doesn't count as a click, so clicking still
	-- opens their menus as normal.
	for key, info in pairs(ownIcons) do
		local handle = _G[info.handle or info.frame]
		if handle then
			handle.cleanMinimapKey = key
			handle:RegisterForDrag("LeftButton")
			handle:HookScript("OnDragStart", function(button)
				iconDragFrame.key, iconDragFrame.button = button.cleanMinimapKey, nil
				iconDragFrame:Show()
			end)
			handle:HookScript("OnDragStop", function()
				CleanMinimap:EndIconDrag()
			end)
		end
	end
	self:UpdateOwnIcons()
end

-- Other addons' minimap buttons: LibDBIcon buttons and the usual round
-- buttons with the tracking-ring border. Left alone they are a jumble: each
-- addon picks its own size and distance from the map, and they all grow with
-- the minimap scale. Instead every one is scaled to the same size (that of a
-- standard button scaled like the calendar, so they follow the Icon size
-- option) and centred on the map's border, square or round. Dragging one is
-- done by CleanMinimap like its own icons (iconDragFrame), and where it's
-- left is saved by the button's name (AddonButtonAngles). Until it has been
-- dragged, a button goes in the direction its addon puts it: whenever the
-- addon places it, the direction is taken from where it asked for and the
-- button goes back on the border there. Buttons an addon already scales
-- itself, and protected ones, are left alone.
local addonButtons = {}  -- button -> scale we applied
local minimapParents = { [Minimap] = true, [MinimapBackdrop] = true, [MinimapCluster] = true }

local function IsAddonMinimapButton(frame)
	local name = frame:GetName()
	if not name or frame:IsProtected() then
		return false
	end
	-- Blizzard's own minimap frames.
	if name:find("^MiniMap") or name:find("^Minimap") or name:find("^GameTime") or name:find("^TimeManager") then
		return false
	end
	if name:find("^LibDBIcon10_") then
		return true
	end
	if frame:GetObjectType() ~= "Button" then
		return false
	end
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			local texture = region:GetTexture()
			if type(texture) == "string" and texture:lower():find("trackingborder") then
				return true
			end
		end
	end
	return false
end

-- Where each anchor point sits on a frame, as fractions of its size from its
-- centre.
local pointOffsets = {
	TOPLEFT = { -0.5, 0.5 }, TOP = { 0, 0.5 }, TOPRIGHT = { 0.5, 0.5 },
	LEFT = { -0.5, 0 }, CENTER = { 0, 0 }, RIGHT = { 0.5, 0 },
	BOTTOMLEFT = { -0.5, -0.5 }, BOTTOM = { 0, -0.5 }, BOTTOMRIGHT = { 0.5, -0.5 },
}

-- Direction (radians, from the map's centre) of the place a button's addon
-- asked for, worked out from the anchor it gave. Offsets and size are taken
-- at the button's normal scale, as its addon meant them.
local function RequestedAngle(button, point, relativeTo, relativePoint, x, y)
	if type(relativeTo) == "number" then
		-- SetPoint(point, x, y): relative to the parent, same point.
		relativeTo, relativePoint, x, y = nil, point, relativeTo, relativePoint
	end
	if type(relativeTo) == "string" then
		relativeTo = _G[relativeTo]
	end
	relativeTo = relativeTo or button:GetParent()
	if type(relativeTo) ~= "table" or not relativeTo.GetCenter then
		return nil
	end
	point = type(point) == "string" and point:upper() or "CENTER"
	relativePoint = type(relativePoint) == "string" and relativePoint:upper() or point
	local p, r = pointOffsets[point], pointOffsets[relativePoint]
	if not p or not r then
		return nil
	end
	-- The anchor's position from the map's centre, in minimap units.
	local ax, ay
	if relativeTo == Minimap then
		ax, ay = r[1] * Minimap:GetWidth(), r[2] * Minimap:GetHeight()
	else
		local rx, ry = relativeTo:GetCenter()
		local mx, my = Minimap:GetCenter()
		if not rx or not mx then
			return nil
		end
		local rs, ms = relativeTo:GetEffectiveScale(), Minimap:GetEffectiveScale()
		ax = ((rx + r[1] * relativeTo:GetWidth()) * rs - mx * ms) / ms
		ay = ((ry + r[2] * relativeTo:GetHeight()) * rs - my * ms) / ms
	end
	-- Its parent is the minimap or a frame at the same scale, so the
	-- button's own units at scale 1 are minimap units.
	local cx = ax + (tonumber(x) or 0) - p[1] * button:GetWidth()
	local cy = ay + (tonumber(y) or 0) - p[2] * button:GetHeight()
	if cx == 0 and cy == 0 then
		return nil
	end
	return math.atan2(cy, cx)
end

-- Point on the border at an angle, in minimap units from the map's centre:
-- on the square's edge (corners included), or on the circle.
local function BorderPoint(angle, square, distance)
	local c, s = math.cos(angle), math.sin(angle)
	if square then
		local m = math.max(math.abs(c), math.abs(s))
		return distance * c / m, distance * s / m
	end
	return distance * c, distance * s
end

-- Centre any icon (ours or another addon's) on the border at an angle. k is
-- the frame's scale (its anchor offsets are in its own units) and footprint
-- the width of its ring at scale 1. The screen's right and top edges are
-- close at large scales, so an icon there sits further over the map to stay
-- on screen.
function CleanMinimap:PlaceOnBorder(frame, angle, k, footprint)
	if not self.db or not self.db.profile then
		return
	end
	local half = Minimap:GetWidth() / 2
	local x, y = BorderPoint(angle, self.db.profile.UseSquare, half + (self.borderReach or 0) / 2)
	local h = footprint * k / 2
	if self.spaceRight then
		x = math.min(x, half + self.spaceRight - h)
	end
	if self.spaceTop then
		y = math.min(y, half + self.spaceTop - h)
	end
	frame.cleanMinimapMoving = true
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Minimap, "CENTER", x / k, y / k)
	frame.cleanMinimapMoving = nil
end

-- A standard addon button is 31 units with its ring 2 wider.
local function AddonButtonFootprint(button)
	local native = math.max(button:GetWidth(), button:GetHeight())
	if native <= 0 then
		native = 31
	end
	return native + 2
end

-- Put a managed addon button on the border at its angle.
function CleanMinimap:PlaceAddonButton(button)
	local k, angle = addonButtons[button], button.cleanMinimapAngle
	if not k or not angle then
		return
	end
	self:PlaceOnBorder(button, angle, k, AddonButtonFootprint(button))
end

function CleanMinimap:PlaceAddonButtons()
	for button in pairs(addonButtons) do
		self:PlaceAddonButton(button)
	end
end

-- Where the button was last dragged to (radians), if it has been.
local function SavedAddonButtonAngle(button)
	local name = button:GetName()
	local angles = CleanMinimap.db and CleanMinimap.db.profile and CleanMinimap.db.profile.AddonButtonAngles
	local degrees = name and angles and tonumber(angles[name])
	return degrees and math.rad(degrees)
end

-- Stop managing a button: back to its normal size, and to the layer it had
-- unless something (such as an addon that collects minimap buttons into a
-- bag) has given it another since.
local function DropAddonButton(button)
	if iconDragFrame.button == button then
		iconDragFrame:Hide()
		iconDragFrame.button = nil
	end
	addonButtons[button] = nil
	iconFrames[button] = nil
	button:SetScale(1)
	local strata, level = button.cleanMinimapStrata, button.cleanMinimapLevel
	button.cleanMinimapStrata, button.cleanMinimapLevel = nil, nil
	if strata and button:GetFrameStrata() == LAYER_STRATA and button:GetFrameLevel() == ICON_LEVEL then
		SetLayer(button, strata, level)
	end
end

-- Hooked onto each button's SetPoint: its addon has just placed it (on load,
-- or while its own drag code runs), so note what it asked for, which is
-- where it goes back to if it's ever handed back. While you drag the button,
-- or once you have, its addon's choice of place is overruled: it goes back
-- on the border at the cursor's direction, or where you left it. Until then
-- it goes on the border in the direction its addon asked for.
local function OnAddonButtonSetPoint(button, point, relativeTo, relativePoint, x, y)
	if button.cleanMinimapMoving then
		return
	end
	button.cleanMinimapRequested = { point, relativeTo, relativePoint, x, y }
	if not addonButtons[button] then
		return
	end
	if not minimapParents[button:GetParent()] then
		-- Moved off the minimap (e.g. into a button-bag addon): let it go.
		DropAddonButton(button)
		return
	end
	if iconDragFrame.button ~= button then
		local angle = SavedAddonButtonAngle(button) or RequestedAngle(button, point, relativeTo, relativePoint, x, y)
		if angle then
			button.cleanMinimapAngle = angle
		end
	end
	CleanMinimap:PlaceAddonButton(button)
end

-- A drag on a managed button: CleanMinimap moves it from here on, the same
-- way as its own icons. An addon that moves its button by hand (StartMoving)
-- would fight that, so the hand move is stopped.
local function OnAddonButtonDragStart(button)
	if not addonButtons[button] then
		return
	end
	if button:IsMovable() then
		button:StopMovingOrSizing()
	end
	iconDragFrame.key, iconDragFrame.button = nil, button
	iconDragFrame:Show()
end

-- The end of a drag. Normally ours: save where it was left. Otherwise (the
-- drag began before CleanMinimap took the button over, say) an addon that
-- lets you drop its button anywhere may have left it off the border, so put
-- it back on the border in that direction.
local function OnAddonButtonDragStop(button)
	if not addonButtons[button] then
		return
	end
	if iconDragFrame.button == button then
		CleanMinimap:EndIconDrag()
		return
	end
	local point, relativeTo = button:GetPoint(1)
	if point == "CENTER" and relativeTo == Minimap then
		return  -- still where we put it; its addon moved it with SetPoint
	end
	local bx, by = button:GetCenter()
	local mx, my = Minimap:GetCenter()
	if bx and mx then
		local bs, ms = button:GetEffectiveScale(), Minimap:GetEffectiveScale()
		button.cleanMinimapAngle = math.atan2(by * bs - my * ms, bx * bs - mx * ms)
	end
	CleanMinimap:PlaceAddonButton(button)
end

-- Hook a button's drag scripts, again if its addon has replaced them since.
-- A button its addon gave no drag at all gets a left-drag, so every icon can
-- be moved the same way.
local function HookAddonButtonDrag(button)
	if not button:GetScript("OnDragStart") then
		button:RegisterForDrag("LeftButton")
	end
	if not button.cleanMinimapDragStart or button:GetScript("OnDragStart") ~= button.cleanMinimapDragStart then
		button:HookScript("OnDragStart", OnAddonButtonDragStart)
		button.cleanMinimapDragStart = button:GetScript("OnDragStart")
	end
	if not button.cleanMinimapDragStop or button:GetScript("OnDragStop") ~= button.cleanMinimapDragStop then
		button:HookScript("OnDragStop", OnAddonButtonDragStop)
		button.cleanMinimapDragStop = button:GetScript("OnDragStop")
	end
end

local function ManageAddonButton(button, k)
	if not button.cleanMinimapHooked then
		button.cleanMinimapHooked = true
		hooksecurefunc(button, "SetPoint", OnAddonButtonSetPoint)
	end
	HookAddonButtonDrag(button)
	if not addonButtons[button] then
		-- Start from where it was last dragged to, or else wherever its
		-- addon has put it so far.
		local point, relativeTo, relativePoint, x, y = button:GetPoint(1)
		if point then
			button.cleanMinimapRequested = { point, relativeTo, relativePoint, x, y }
			button.cleanMinimapAngle = RequestedAngle(button, point, relativeTo, relativePoint, x, y) or button.cleanMinimapAngle
		end
		button.cleanMinimapAngle = SavedAddonButtonAngle(button) or button.cleanMinimapAngle or math.rad(225)
		-- Kept to give back if the button is ever handed back.
		button.cleanMinimapStrata, button.cleanMinimapLevel = button:GetFrameStrata(), button:GetFrameLevel()
	end
	addonButtons[button] = k
	iconFrames[button] = true
	button:SetScale(k)
	-- In the icon layer with CleanMinimap's own icons, above the map's
	-- markers. (LibDBIcon's own choice is MEDIUM, the strata bags and
	-- windows use, so its buttons could show through them.)
	SetLayer(button, LAYER_STRATA, ICON_LEVEL)
	CleanMinimap:PlaceAddonButton(button)
end

-- Hand a button back to its addon: normal size and layer, where its addon
-- last put it.
local function ReleaseAddonButton(button)
	DropAddonButton(button)
	local r = button.cleanMinimapRequested
	if r and r[1] then
		button.cleanMinimapMoving = true
		button:ClearAllPoints()
		button:SetPoint(r[1], r[2] or button:GetParent(), r[3] or r[1], tonumber(r[4]) or 0, tonumber(r[5]) or 0)
		button.cleanMinimapMoving = nil
	end
end

function CleanMinimap:UpdateAddonButtons()
	if not self.db or not self.db.profile then
		return
	end
	local on = self.db.profile.ScaleAddonButtons
	for button in pairs(addonButtons) do
		if not on then
			ReleaseAddonButton(button)
		elseif not minimapParents[button:GetParent()] then
			DropAddonButton(button)
		end
	end
	if not on then
		return
	end
	-- The same size as CleanMinimap's own icons, whatever size its addon made it.
	local size = self:IconFootprint()
	for parent in pairs(minimapParents) do
		for _, child in ipairs({ parent:GetChildren() }) do
			if addonButtons[child] or (IsAddonMinimapButton(child) and child:GetScale() == 1) then
				ManageAddonButton(child, size / AddonButtonFootprint(child))
			end
		end
	end
end

-- Addons can create their buttons late, so look again a few times after
-- each loading screen and each addon that loads later.
local buttonScanFrame = CreateFrame("Frame")
buttonScanFrame:Hide()
buttonScanFrame:SetScript("OnUpdate", function(frame, elapsed)
	frame.elapsed = frame.elapsed + elapsed
	if frame.marks[1] and frame.elapsed >= frame.marks[1] then
		table.remove(frame.marks, 1)
		CleanMinimap:UpdateAddonButtons()
	end
	if not frame.marks[1] then
		frame:Hide()
	end
end)
function CleanMinimap:ScheduleAddonButtonScans()
	buttonScanFrame.elapsed = 0
	buttonScanFrame.marks = { 1, 5, 15 }
	buttonScanFrame:Show()
end

-- Keep the Dungeon Finder status popup (LFDSearchStatus, the "Assembling
-- Group..." panel) at the normal UI scale. OnInitialize moves it from the eye
-- to UIParent, which makes this 1; it is still checked each time it opens in
-- case something parents it back under the scaled minimap.
function CleanMinimap:UpdateLFDSearchStatusScale()
	if not LFDSearchStatus or not UIParent then
		return
	end
	local parent = LFDSearchStatus:GetParent()
	local parentScale = parent and parent:GetEffectiveScale()
	if parentScale and parentScale > 0 then
		LFDSearchStatus:SetScale(UIParent:GetEffectiveScale() / parentScale)
	end
end

-- The border layer and, above it, the furniture: MinimapBackdrop (which
-- holds the north marker, and the compass ring when the minimap rotates),
-- the clock, the zone name and the dungeon difficulty flag. They overlap the
-- border, so they go over it, as before. The icons go above all of these
-- (UpdateOwnIcons and ManageAddonButton). The clock comes with Blizzard's
-- load-on-demand clock addon, so this runs again when that loads.
local furnitureFrames = { "MinimapBackdrop", "TimeManagerClockButton", "MinimapZoneTextButton", "MiniMapInstanceDifficulty" }
function CleanMinimap:UpdateLayers()
	SetLayer(borderFrame, LAYER_STRATA, BORDER_LEVEL)
	for _, name in ipairs(furnitureFrames) do
		SetLayer(_G[name], LAYER_STRATA, FURNITURE_LEVEL)
	end
end

-- Square or round: map mask, the shape other addons ask for, coordinates and
-- clock. Blizzard's round border and zone-name bar are replaced by our own
-- border in both shapes.
function CleanMinimap:ApplyShape()
	MinimapBorder:Hide()
	MinimapBorderTop:Hide()
	-- Always shown, border or not: it catches the mouse wheel for zooming.
	CleanMinimapFrame:Show()
	loc:ClearAllPoints()
	if self.db.profile.UseSquare then
		shape = "SQUARE"
		Minimap:SetMaskTexture("Interface\\AddOns\\CleanMinimap\\texture\\Mask")
		loc:SetWidth(60)
		text:SetWidth(60)
		loc:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
	else
		-- GetMinimapShape must answer with one of the standard names
		-- ("ROUND", "SQUARE", "CORNER-TOPLEFT", ...). LibDBIcon looks the
		-- name up in its own table and errors on any other, so dragging an
		-- addon's button failed in round mode when this said "CIRCULAR".
		shape = "ROUND"
		Minimap:SetMaskTexture("Textures\\MinimapMask")
		loc:SetWidth(Minimap:GetWidth())
		text:SetWidth(Minimap:GetWidth())
		loc:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 8)
	end
	if TimeManagerClockButton then
		TimeManagerClockButton:ClearAllPoints()
		TimeManagerClockButton:SetPoint("CENTER", Minimap, "CENTER", 0, self.db.profile.UseSquare and -76 or -68)
	end
end

-- The square bezel or round ring. f is 1/scale above 100% (1 otherwise), so
-- the border keeps the thickness it has at 100% however big the map gets.
-- Returns how far the border reaches beyond the map's edge, in minimap units.
function CleanMinimap:UpdateBorder(f)
	local p = self.db.profile
	CleanMinimapFrame:ClearAllPoints()
	CleanMinimapFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3 * f, 3 * f)
	CleanMinimapFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 3 * f, -3 * f)

	local reach = 0
	if p.ShowBorder and p.UseSquare then
		reach = 3 * f
		backdrop.edgeSize = 4 * f
		backdrop.insets.left = 4 * f
		backdrop.insets.right = 4 * f
		backdrop.insets.top = 4 * f
		backdrop.insets.bottom = 4 * f
		-- SetBackdrop resets the colours, so set them again every time.
		borderFrame:SetBackdrop(backdrop)
		borderFrame:SetBackdropColor(0,0,0,0)
		borderFrame:SetBackdropBorderColor(0,0,0,0.6)
	else
		borderFrame:SetBackdrop(nil)
	end

	if p.ShowBorder and not p.UseSquare then
		local half = Minimap:GetWidth() / 2
		local want = 4 * f / (half + 3 * f)
		local best, bestDiff = 1, nil
		for k, r in ipairs(ringRatios) do
			local diff = math.abs(math.log(want / r))
			if not bestDiff or diff < bestDiff then
				best, bestDiff = k, diff
			end
		end
		-- Size the ring so its inner edge is always 1f over the map's edge,
		-- leaving no gap at the rim whichever texture is closest.
		local outer = (half - f) / (1 - ringRatios[best])
		local size = outer / RING_EDGE
		reach = outer - half
		for _, tex in ipairs(ringQuads) do
			tex:SetTexture("Interface\\AddOns\\CleanMinimap\\texture\\Ring" .. best)
			tex:SetTexCoord(tex.l, tex.r, tex.t, tex.b)
			tex:SetVertexColor(0, 0, 0)
			tex:SetAlpha(0.6)
			tex:SetWidth(size)
			tex:SetHeight(size)
			tex:Show()
		end
	else
		for _, tex in ipairs(ringQuads) do
			tex:Hide()
		end
	end
	return reach
end

-- Positions everything from the scale and options. The cluster stays pinned to
-- the screen's top-right corner, because Blizzard docks the quest tracker,
-- durability figure and boss/arena frames under its bottom-right corner. It is
-- sized to wrap the map, and the map sits inside it so its gaps to the screen
-- edges stay the same on screen at every scale.
function CleanMinimap:UpdateLayout()
	if not self.db or not self.db.profile then
		return
	end
	-- Boss and arena frames are protected and anchored to the cluster, so it
	-- can't be resized in combat. Do it as soon as combat ends.
	if InCombatLockdown() then
		self.layoutPending = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	self.layoutPending = nil
	local p = self.db.profile

	local scale = math.max(0.1, math.min(3, tonumber(p.Scale) or 1))
	p.Scale = scale
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
	MinimapCluster:SetScale(scale)

	-- The map's scale relative to the UI (this also covers another addon
	-- scaling Minimap itself).
	local s = scale
	local uiScale = UIParent:GetEffectiveScale()
	if uiScale and uiScale > 0 then
		s = Minimap:GetEffectiveScale() / uiScale
	end
	local f = 1 / math.max(1, s)

	local border = self:UpdateBorder(f)

	-- Zone name: centred over the map, just above the border.
	MinimapBorderTop:Hide()
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetWidth(150)
	MinimapZoneTextButton:SetHeight(ZONE_HEIGHT)
	MinimapZoneTextButton:SetPoint("BOTTOM", Minimap, "TOP", 0, border + ZONE_GAP)
	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetPoint("CENTER", MinimapZoneTextButton, "CENTER", 0, 0)
	if p.ShowZone then
		MinimapZoneTextButton:Show()
	else
		MinimapZoneTextButton:Hide()
	end

	-- The map's offset inside the cluster, in minimap units: the fixed
	-- on-screen gaps divided by the scale, plus the zone name and border,
	-- which scale with the map.
	local top
	if p.ShowZone then
		top = HEADER_TOP_GAP / s + ZONE_HEIGHT + ZONE_GAP + border
	else
		top = EDGE_GAP / s
	end
	local right = EDGE_GAP / s
	Minimap:ClearAllPoints()
	Minimap:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", -right, -top)
	-- For placing other addons' buttons on the border, and keeping them on
	-- screen: the border's reach and the room to the screen's edges, in
	-- minimap units.
	self.borderReach, self.spaceRight, self.spaceTop = border, right, top

	-- Blizzard anchors these to the cluster. Keep them where they normally
	-- sit relative to the map.
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", -9, -24)
	if MiniMapInstanceDifficulty then
		MiniMapInstanceDifficulty:ClearAllPoints()
		MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -13, 5)
	end

	-- Wrap the map, the half of each icon that hangs past its left border,
	-- and the gaps, keeping Blizzard's space below the map for the clock. The
	-- buffs sit just left of this.
	local left = border / 2 + self:IconFootprint() / 2 + ICON_MARGIN / s
	MinimapCluster:SetWidth(left + Minimap:GetWidth() + right)
	MinimapCluster:SetHeight(top + Minimap:GetHeight() + BOTTOM_SPACE)

	self:PositionAuraFrames()
	self:UpdateLFDSearchStatusScale()
	self:UpdateLayers()
	self:UpdateOwnIcons()
	self:PlaceAddonButtons()
end

function CleanMinimap:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if self.layoutPending then
		self:UpdateLayout()
	end
end

function CleanMinimap:GetMinimapAlpha()
	return self.db.profile.Alpha or 1
end
function CleanMinimap:SetMinimapAlpha(info, value)
	self.db.profile.Alpha = math.max(0.1, math.min(1, tonumber(value) or 1))
	self:UpdateAlpha()
end
-- Is the minimap drawing an indoor-style map? Buildings and dungeons do, and
-- so do cities such as Orgrimmar even where IsIndoors() says you're outside.
-- The minimap keeps separate zoom levels for outdoor and indoor maps (the
-- minimapZoom and minimapInsideZoom settings); whichever one matches the
-- current zoom is the mode it is in. If both are the same, step the zoom for
-- a moment so they differ, then put it back. This is the check the Astrolabe
-- map library uses; SetZoom does not fire MINIMAP_UPDATE_ZOOM, so it can't
-- loop, but guard against re-entry anyway.
local checkingMinimapMode = false
local function MinimapInIndoorMode()
	if checkingMinimapMode then
		return false
	end
	checkingMinimapMode = true
	local zoom = Minimap:GetZoom()
	local stepped = false
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		if zoom < 2 then
			Minimap:SetZoom(zoom + 1)
		else
			Minimap:SetZoom(zoom - 1)
		end
		stepped = true
	end
	local indoor = tonumber(GetCVar("minimapZoom")) ~= Minimap:GetZoom()
	if stepped then
		Minimap:SetZoom(zoom)
	end
	checkingMinimapMode = false
	return indoor
end

-- Opacity for the whole minimap. The game can't draw an indoor-style map
-- see-through (the map goes blank and only a dark see-through square is
-- left), so the minimap stays fully opaque whenever it is showing one.
function CleanMinimap:UpdateAlpha()
	if not self.db or not self.db.profile then
		return
	end
	local alpha = tonumber(self.db.profile.Alpha) or 1
	if alpha < 1 and (IsIndoors() or MinimapInIndoorMode()) then
		alpha = 1
	end
	MinimapCluster:SetAlpha(alpha)
end

function CleanMinimap:GetScale()
	if not self.db.profile then
		return 1
	end
	return self.db.profile.Scale or 1
end
function CleanMinimap:SetScale(table, size)
	size = tonumber(size) or 1
	self.db.profile.Scale = math.max(0.1, math.min(3, size))
	self:UpdateLayout()
end
function CleanMinimap:GetIconScale()
	if not self.db.profile then
		return 18
	end
	return self.db.profile.IconScale or 18
end
function CleanMinimap:SetIconScale(table, size)
	self.db.profile.IconScale = size
	-- Every icon is scaled whole from this; UpdateLayout also re-places ours
	-- (and widens the cluster to fit them).
	self:UpdateOwnIcons()
	self:UpdateAddonButtons()
	self:UpdateLayout()
end

function CleanMinimap:OnInitialize()
	CleanMinimap.db = LibStub("AceDB-3.0"):New("CleanMinimapDB", CleanMinimap.defaults)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("CleanMinimap", CleanMinimap.options, "cmm")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("CleanMinimap", nil, nil)
	
	-- Keep the minimap in Blizzard's default top-right position.
	-- Older versions saved a TOPLEFT position on every mouse-up, even
	-- when the player had not moved the minimap. Ignore and discard it.
	self.db.profile.posx = nil
	self.db.profile.posy = nil
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
	
	--self:SetScript("OnEvent",self.OnEvent)
	CleanMinimapFrame:EnableMouseWheel(true)
	CleanMinimapFrame:SetScript("OnMouseWheel", function() self:Zoom() end)
	
	--Setting Up (border and position are set by UpdateLayout below)
	CleanMinimapFrame:EnableMouse(false)

	--Coords button
	loc = CreateFrame("Button", nil, Minimap)
	loc:SetWidth(60)
	loc:SetHeight(16)
	loc:SetPoint("BOTTOMLEFT", CleanMinimapFrame, "BOTTOMLEFT", 3, 3)
	loc:SetScript("OnUpdate", function() CleanMinimap:UpdateCoords() end)
	loc:SetScript("OnClick", MessageCoords)

	text = loc:CreateFontString(nil, "OVERLAY","GameFontNormal")
	text:SetWidth(60)
	text:SetHeight(16)
	text:SetPoint("TOP", loc)
	text:SetJustifyH("CENTER")

	--Zone name: clicking it hides/shows the map, in either shape. Its
	--position is set by UpdateLayout.
	MinimapZoneTextButton:SetScript("OnClick", ToggleMinimap)
	self:ApplyShape()

-- The minimap is intentionally not made movable. Keeping MinimapCluster's
-- TOPRIGHT anchor means SetScale grows/shrinks it inward from the screen edge.
-- We also leave Blizzard's original Minimap mouse-up handler untouched.

--Minimap extras clean up.
	MinimapZoomIn:Hide();
	MinimapZoomOut:Hide();
	--MinimapToggleButton:Hide();
	MiniMapWorldMapButton:Hide();

	--Tracking, mail, battleground, Dungeon Finder and calendar icons: on the
	--border at their saved angles, the same size as every other icon, and
	--draggable round it.
	self:SetUpOwnIcons()
	--Other addons' minimap buttons that already exist (more are picked up
	--after loading screens and as addons load).
	self:UpdateAddonButtons()

	--The Dungeon Finder's "Assembling Group..." popup. Blizzard parents it
	--to the eye, so it would take on the minimap's scale and opacity. Give it
	--to UIParent instead (it still anchors to the eye), and hide it whenever
	--the eye hides, as it did as a child.
	if LFDSearchStatus then
		LFDSearchStatus:SetParent(UIParent)
		LFDSearchStatus:SetFrameStrata("TOOLTIP")
		LFDSearchStatus:SetClampedToScreen(true)
		LFDSearchStatus:HookScript("OnShow", function()
			self:UpdateLFDSearchStatusScale()
		end)
		if MiniMapLFGFrame then
			MiniMapLFGFrame:HookScript("OnHide", function()
				LFDSearchStatus:Hide()
			end)
		end
	end

	if (self.db.profile.ShowCoord) then
		text:Show()
	else
		text:Hide()
	end
	if (self.db.profile.ShowDura) then
		DurabilityFrame:Show()
		DurabilityFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
	else
		DurabilityFrame:Hide()
		DurabilityFrame:UnregisterEvent("UPDATE_INVENTORY_ALERTS")
	end
	if (self.db.profile.ShowTrack) then
		MiniMapTracking:Show();
	else
		MiniMapTracking:Hide();
	end
	-- Scale, border, zone name, map position and cluster size.
	self:UpdateLayout()
	self:UpdateAlpha()

	-- Blizzard can reposition the aura frames during frame-management and
	-- aura/enchant transitions. Re-apply our anchors after those updates.
	if hooksecurefunc then
		if UIParent_ManageFramePositions then
			hooksecurefunc("UIParent_ManageFramePositions", function()
				self:PositionAuraFrames()
			end)
		end
		if TemporaryEnchantFrame_Hide then
			hooksecurefunc("TemporaryEnchantFrame_Hide", function()
				self:PositionAuraFrames()
			end)
		end
		if ConsolidatedBuffs_OnShow then
			hooksecurefunc("ConsolidatedBuffs_OnShow", function()
				self:PositionAuraFrames()
			end)
		end
		if ConsolidatedBuffs_OnHide then
			hooksecurefunc("ConsolidatedBuffs_OnHide", function()
				self:PositionAuraFrames()
			end)
		end
	end

--Square Time
	
end

function CleanMinimap:OnEnable()
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	-- Indoor/outdoor and area changes, for the opacity.
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("MINIMAP_UPDATE_ZOOM")
	-- Addons loading later may add minimap buttons.
	self:RegisterEvent("ADDON_LOADED")
end

function CleanMinimap:OnDisable()
	self:UnregisterAllEvents()
end

--Event Handler
function CleanMinimap:PLAYER_LOGIN()
	SetMapToCurrentZone()
	self:PositionAuraFrames()
end

function CleanMinimap:PLAYER_ENTERING_WORLD()
	self:UpdateLayout()
	self:PositionAuraFrames()
	self:UpdateAlpha()
	self:UpdateAddonButtons()
	self:ScheduleAddonButtonScans()
end

function CleanMinimap:ADDON_LOADED(event, name)
	if name == "Blizzard_TimeManager" then
		-- Blizzard's clock has just been created.
		self:UpdateLayers()
		self:UpdateOwnIcons()
	end
	self:ScheduleAddonButtonScans()
end

function CleanMinimap:ZONE_CHANGED_NEW_AREA()
	SetMapToCurrentZone()
	self:UpdateAlpha()
end

function CleanMinimap:ZONE_CHANGED()
	self:UpdateAlpha()
end

function CleanMinimap:ZONE_CHANGED_INDOORS()
	self:UpdateAlpha()
end

function CleanMinimap:MINIMAP_UPDATE_ZOOM()
	self:UpdateAlpha()
end

--Mousewheel zoom
function CleanMinimap:Zoom()
    if not arg1 then return end
    if arg1 > 0 and Minimap:GetZoom() < 5 then
        Minimap:SetZoom(Minimap:GetZoom() + 1)
    elseif arg1 < 0 and Minimap:GetZoom() > 0 then
        Minimap:SetZoom(Minimap:GetZoom() - 1)
    end
end

--Coord update
function CleanMinimap:UpdateCoords()
    local x, y = GetPlayerMapPosition("player")
    text:SetText(string.format("%.1f,%.1f", 100*x, 100*y))
	if (self.db.profile.UseSquare) then
		Minimap:SetMaskTexture("Interface\\AddOns\\CleanMinimap\\texture\\Mask");
	else
		Minimap:SetMaskTexture("Textures\\MinimapMask");
	end
	if (self.db.profile.UseSquare and TimeManagerClockButton) then
		TimeManagerClockButton:ClearAllPoints();
		TimeManagerClockButton:SetPoint("CENTER", Minimap, "CENTER", 0, -76);
	elseif (TimeManagerClockButton) then
		TimeManagerClockButton:ClearAllPoints();
		TimeManagerClockButton:SetPoint("CENTER", Minimap, "CENTER", 0, -68);
	end
end
	