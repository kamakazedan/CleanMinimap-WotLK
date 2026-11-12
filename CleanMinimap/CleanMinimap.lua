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
					desc = "Increases or decreases the size of the default icons around the minimap.",
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

-- Backdrop for the black square border (CleanMinimapFrame). UpdateBorder()
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
		local tex = CleanMinimapFrame:CreateTexture(nil, "ARTWORK")
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

-- Dungeon Finder eye (MiniMapLFGFrame). In 3.3.5a it is a child of
-- MinimapBackdrop, so it already inherits MinimapCluster's scale, but Blizzard
-- anchors it for the round border, which leaves it sitting over the left edge
-- of the square map. Give it its own slot in the icon column, below the
-- battleground icon, and size it from the "Icon size" option like the others.
function CleanMinimap:UpdateLFGFrame()
	if not MiniMapLFGFrame or not MiniMapBattlefieldFrame then
		return
	end
	local size = 18
	if self.db and self.db.profile then
		size = tonumber(self.db.profile.IconScale) or 18
	end

	-- The eye artwork has transparent padding, so it is drawn 6 units larger
	-- than the tracking/mail icons to look the same size. The button is 2 units
	-- larger again (Blizzard uses 33 vs 30) to leave room for the hover glow.
	MiniMapLFGFrame:SetWidth(size + 8)
	MiniMapLFGFrame:SetHeight(size + 8)
	if MiniMapLFGFrameIcon then
		MiniMapLFGFrameIcon:SetWidth(size + 6)
		MiniMapLFGFrameIcon:SetHeight(size + 6)
	end
	if MiniMapLFGFrameBorder then
		MiniMapLFGFrameBorder:Hide()
	end

	-- The battleground button's centre is 1.5 units right of the line the
	-- tracking and mail icons are centred on, so shift left by that. This also
	-- keeps the eye clear of the map's edge at every icon size.
	MiniMapLFGFrame:ClearAllPoints()
	MiniMapLFGFrame:SetPoint("TOP", MiniMapBattlefieldFrame, "BOTTOM", -1.5, -3)
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
		shape = "CIRCULAR"
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
		CleanMinimapFrame:SetBackdrop(backdrop)
		CleanMinimapFrame:SetBackdropColor(0,0,0,0)
		CleanMinimapFrame:SetBackdropBorderColor(0,0,0,0.6)
	else
		CleanMinimapFrame:SetBackdrop(nil)
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

	-- Blizzard anchors these to the cluster. Keep them where they normally
	-- sit relative to the map.
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", -9, -24)
	if MiniMapInstanceDifficulty then
		MiniMapInstanceDifficulty:ClearAllPoints()
		MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -13, 5)
	end

	-- Wrap the icon column, map and gaps, keeping Blizzard's space below the
	-- map for the clock. The buffs sit just left of this.
	local iconSize = tonumber(p.IconScale) or 18
	local left = 10 + iconSize + ICON_MARGIN / s
	MinimapCluster:SetWidth(left + Minimap:GetWidth() + right)
	MinimapCluster:SetHeight(top + Minimap:GetHeight() + BOTTOM_SPACE)

	self:PositionAuraFrames()
	self:UpdateLFDSearchStatusScale()
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
	MiniMapTracking:SetHeight(self.db.profile.IconScale);
	MiniMapTracking:SetWidth(self.db.profile.IconScale);
	MiniMapTrackingIcon:SetHeight(self.db.profile.IconScale);
	MiniMapTrackingIcon:SetWidth(self.db.profile.IconScale);
	MiniMapTrackingButton:SetHeight(self.db.profile.IconScale + 8);
	MiniMapTrackingButton:SetWidth(self.db.profile.IconScale + 8);
	MiniMapMailFrame:SetHeight(self.db.profile.IconScale);
	MiniMapMailFrame:SetWidth(self.db.profile.IconScale);
	MiniMapMailIcon:SetHeight(self.db.profile.IconScale);
	MiniMapMailIcon:SetWidth(self.db.profile.IconScale);
	MiniMapBattlefieldFrame:SetHeight(self.db.profile.IconScale + 15);
	MiniMapBattlefieldFrame:SetWidth(self.db.profile.IconScale + 15);
	MiniMapBattlefieldIcon:SetHeight(self.db.profile.IconScale + 14);
	MiniMapBattlefieldIcon:SetWidth(self.db.profile.IconScale + 14);
	self:UpdateLFGFrame()
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
	GameTimeFrame:Hide();
	
	--Tracking Frame
	MiniMapTracking:SetHeight(self.db.profile.IconScale);
	MiniMapTracking:SetWidth(self.db.profile.IconScale);
	MiniMapTrackingIcon:SetHeight(self.db.profile.IconScale);
	MiniMapTrackingIcon:SetWidth(self.db.profile.IconScale);
	MiniMapTracking:ClearAllPoints();
	MiniMapTracking:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -10, 6);
	MiniMapTrackingBackground:Hide();
	MiniMapTrackingButtonBorder:Hide();
	MiniMapTrackingButton:SetHighlightTexture(nil);
	MiniMapTrackingButton:SetHeight(self.db.profile.IconScale + 8);
	MiniMapTrackingButton:SetWidth(self.db.profile.IconScale + 8);
	MiniMapTrackingButtonShine:SetHeight(self.db.profile.IconScale + 8);
	MiniMapTrackingButtonShine:SetWidth(self.db.profile.IconScale + 8);
	MiniMapTrackingButton:SetScript("OnMouseDown", function()
					MiniMapTrackingIcon:SetPoint("TOPLEFT", MiniMapTracking, "TOPLEFT", 8, -8);
					end)
	MiniMapTrackingButton:SetScript("OnMouseUp", function() 
					MiniMapTrackingIcon:SetPoint("TOPLEFT", MiniMapTracking, "TOPLEFT", 6, -6);
					end)
	
	--Mail Frame
	MiniMapMailFrame:SetHeight(self.db.profile.IconScale);
	MiniMapMailFrame:SetWidth(self.db.profile.IconScale);
	MiniMapMailIcon:SetHeight(self.db.profile.IconScale);
	MiniMapMailIcon:SetWidth(self.db.profile.IconScale);
	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint("TOPLEFT", MiniMapTracking, "BOTTOMLEFT", -1, -3);
	MiniMapMailBorder:Hide();
	
	--Battlefield Frame
	MiniMapBattlefieldFrame:SetHeight(self.db.profile.IconScale + 15);
	MiniMapBattlefieldFrame:SetWidth(self.db.profile.IconScale + 15);
	MiniMapBattlefieldIcon:SetHeight(self.db.profile.IconScale + 14);
	MiniMapBattlefieldIcon:SetWidth(self.db.profile.IconScale + 14);
	MiniMapBattlefieldFrame:ClearAllPoints();
	MiniMapBattlefieldFrame:SetPoint("TOPLEFT", MiniMapMailFrame, "BOTTOMLEFT", 1, -3);
	MiniMapBattlefieldBorder:Hide();

	--Dungeon Finder eye, and its "Assembling Group..." popup. Blizzard
	--parents the popup to the eye, so it would take on the minimap's scale
	--and opacity. Give it to UIParent instead (it still anchors to the eye),
	--and hide it whenever the eye hides, as it did as a child.
	self:UpdateLFGFrame()
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
	