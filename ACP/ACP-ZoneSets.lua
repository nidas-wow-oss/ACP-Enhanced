if not ACP then return end

local L = ACP.L

local ZONES = { "bg", "arena", "world" }
local MENU_TEXT = {
	bg    = "Use in battlegrounds",
	arena = "Use in arenas",
	world = "Use everywhere else",
}
local PLACE_TEXT = {
	bg    = "battlegrounds",
	arena = "arenas",
	world = "outside battlegrounds and arenas",
}

local function DB()
	if type(ACP_Data) ~= "table" then return nil end
	local z = ACP_Data.ZoneSets
	if type(z) ~= "table" then
		z = {}
		ACP_Data.ZoneSets = z
	end
	return z
end

local function SetList(set)
	local sets = ACP_Data and ACP_Data.AddonSet
	local list = sets and sets[set]
	if type(list) == "table" and #list > 0 then return list end
	return nil
end

local function ZoneKind()
	local _, kind = IsInInstance()
	if kind == "pvp" then return "bg" end
	if kind == "arena" then return "arena" end
	return "world"
end

local function SetMatches(list)
	local inSet = {}
	for i = 1, #list do inSet[list[i]] = true end
	for i = 1, GetNumAddOns() do
		local name, _, _, enabled = GetAddOnInfo(i)
		if name ~= "ACP" and not ACP:IsAddOnProtected(name) then
			if (enabled and true or false) ~= (inSet[name] or false) then
				return false
			end
		end
	end
	return true
end

function ACP:ApplyZoneSet(set)
	local db = DB()
	if not db or not SetList(set) then return end
	self:ClearSelectionAndLoadSet(set)

	db.applied = set
	ReloadUI()
end

StaticPopupDialogs["ACP_ZONESET"] = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data) ACP:ApplyZoneSet(data) end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

local lastKind, declined

local function Check()
	local db = DB()
	if not db then return end
	local kind = ZoneKind()

	if kind ~= lastKind then declined = false end
	lastKind = kind
	if declined then return end

	local set = db[kind]
	local list = set and SetList(set)
	if not list then return end
	if db.applied == set then return end
	if SetMatches(list) then
		db.applied = set
		return
	end

	local msg = string.format(L["Switch to addon set [%s] for %s and reload?"],
		ACP:GetSetName(set), L[PLACE_TEXT[kind]])
	local dialog = StaticPopup_Show("ACP_ZONESET", msg, nil, set)
	if not dialog then return end

	declined = true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", Check)

function ACP:ZoneSetMenu(level, set)
	if type(set) ~= "number" and type(set) ~= "string" then return end
	if set == 0 then return end
	local db = DB()
	if not db then return end

	local info = UIDropDownMenu_CreateInfo()
	info.text = L["Switch automatically"]
	info.isTitle = 1
	info.notCheckable = 1
	UIDropDownMenu_AddButton(info, level)

	for _, kind in ipairs(ZONES) do
		info = UIDropDownMenu_CreateInfo()
		info.text = L[MENU_TEXT[kind]]
		info.checked = (db[kind] == set) and 1 or nil
		info.keepShownOnClick = 1
		info.func = function()
			if db[kind] == set then
				db[kind] = nil
			else
				if not SetList(set) then
					ACP:Print(L["Save the set first."])
					return
				end
				db[kind] = set
			end

			db.applied = nil
		end
		UIDropDownMenu_AddButton(info, level)
	end
end
