ACP = ACP or {}

local DEFAULT_LOCALE = "enUS"
local detectedCode = GetLocale()

local locales = {}
ACP.Locales = locales

local localeOverride = nil
local activeCode = DEFAULT_LOCALE

local defaultStrings = {}
local activeStrings = {}

local localeWarningShown = false
local missing = {}
local reported = {}

ACP.DEFAULT_LOCALE = DEFAULT_LOCALE

local LOCALE_NAMES = {
	["enUS"] = "English",
	["enGB"] = "English (UK)",
	["enCN"] = "English (Chinese client)",
	["deDE"] = "Deutsch",
	["frFR"] = "Français",
	["esES"] = "Español (España)",
	["esMX"] = "Español (Latinoamérica)",
	["ptBR"] = "Português (Brasil)",
	["itIT"] = "Italiano",
	["ruRU"] = "Русский",
	["koKR"] = "한국어",
	["zhCN"] = "简体中文",
	["zhTW"] = "繁體中文",
}
ACP.LocaleNames = LOCALE_NAMES

local LOCALE_ORDER = {
	"enUS", "enGB", "enCN", "deDE", "frFR", "esES", "esMX",
	"ptBR", "itIT", "ruRU", "koKR", "zhCN", "zhTW",
}
ACP.LocaleOrder = LOCALE_ORDER

local function raw(key)
	local value = activeStrings[key]

	if value == nil or value == true or value == "" then
		value = defaultStrings[key]
	end

	if value == nil or value == true or value == "" then
		return tostring(key), false
	end

	return value, true
end

local L = setmetatable({}, {
	__index = function(t, key)
		local value, translated = raw(key)

		if not translated then
			missing[key] = true
			if ACP.debug and not reported[key] and DEFAULT_CHAT_FRAME then
				reported[key] = true
				DEFAULT_CHAT_FRAME:AddMessage("ACP: " ..
					string.format(raw("Untranslated key: %s"), value))
			end
		end

		return value
	end,
} )

ACP.L = L

local function invalidate()
	for key in pairs(L) do
		rawset(L, key, nil)
	end
	for key in pairs(missing) do
		missing[key] = nil
	end
	for key in pairs(reported) do
		reported[key] = nil
	end
end

local function resolveActive()
	if localeOverride and locales[localeOverride] then
		activeCode = localeOverride
	elseif locales[detectedCode] then
		activeCode = detectedCode
	else
		activeCode = DEFAULT_LOCALE
	end

	defaultStrings = locales[DEFAULT_LOCALE] or {}
	activeStrings = locales[activeCode] or defaultStrings

	invalidate()
end

local function merge(target, source)
	for key, value in pairs(source) do
		if value == true then
			value = key
		end
		if type(value) == "string" and value ~= "" then
			target[key] = value
		end
	end
end

function ACP:RegisterLocale(localeCode, translations, isDefault)
	if type(localeCode) ~= "string" or type(translations) ~= "table" then
		return false
	end

	if isDefault == nil then
		isDefault = (localeCode == DEFAULT_LOCALE)
	end

	local target = locales[localeCode]
	if not target then
		target = {}
		locales[localeCode] = target
	end
	merge(target, translations)

	if isDefault and localeCode ~= DEFAULT_LOCALE then
		local fallback = locales[DEFAULT_LOCALE]
		if not fallback then
			fallback = {}
			locales[DEFAULT_LOCALE] = fallback
		end
		merge(fallback, translations)
	end

	resolveActive()
	return true
end

local function trim(text)
	return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

function ACP:NormalizeLocaleCode(code)
	if type(code) ~= "string" then
		return nil
	end

	code = trim(code)
	if code == "" then
		return nil
	end

	if locales[code] then
		return code
	end

	local lowered = string.lower(code)
	for registered in pairs(locales) do
		if string.lower(registered) == lowered then
			return registered
		end
	end

	return nil
end

function ACP:SetLocale(code)
	local normalized = self:NormalizeLocaleCode(code)
	if not normalized then
		return false, nil
	end

	localeOverride = normalized
	resolveActive()
	return true, normalized
end

function ACP:PruneUnusedLocales()
	for code in pairs(locales) do
		if code ~= DEFAULT_LOCALE and code ~= activeCode then
			locales[code] = {}
		end
	end
	collectgarbage("collect")
end

function ACP:ClearLocaleOverride()
	localeOverride = nil
	resolveActive()
	return true
end

function ACP:GetLocaleOverride()
	return localeOverride
end

function ACP:GetDetectedLocale()
	return detectedCode
end

function ACP:GetEffectiveLocale()
	return activeCode
end

function ACP:GetActiveLocale()
	return activeCode
end

function ACP:IsLocaleRegistered(code)
	return locales[code or detectedCode] ~= nil
end

function ACP:GetLocaleName(code)
	return LOCALE_NAMES[code] or code
end

function ACP:GetRegisteredLocales()
	local out, seen = {}, {}

	for i = 1, #LOCALE_ORDER do
		local code = LOCALE_ORDER[i]
		if locales[code] then
			out[#out + 1] = code
			seen[code] = true
		end
	end

	local extra = {}
	for code in pairs(locales) do
		if not seen[code] then
			extra[#extra + 1] = code
		end
	end
	table.sort(extra)
	for i = 1, #extra do
		out[#out + 1] = extra[i]
	end

	return out
end

function ACP:GetLocaleString(key)
	local value = activeStrings[key]
	if value == true then
		value = key
	end
	if value == "" then
		value = nil
	end
	return value
end

function ACP:WarnUnknownLocale()
	if localeWarningShown or self:IsLocaleRegistered() then
		return false
	end
	localeWarningShown = true
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("ACP: " ..
			string.format(L["No translation is registered for locale %s, using %s."],
				tostring(detectedCode), tostring(activeCode)))
	end
	return true
end

function ACP:ReportMissingLocaleKeys()
	local count = 0
	for key in pairs(missing) do
		count = count + 1
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("ACP: " ..
				string.format(L["Untranslated key: %s"], tostring(key)))
		end
	end
	if count == 0 and DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("ACP: " ..
			L["No untranslated key has been requested so far."])
	end
	return count
end

local LEGACY_LOCALE_KEY_ALIASES = {
	["ReloadUI"]                          = "Reload UI",
	["Reload your User Interface?"]       = "Reload your user interface?",
	["Embeds"]                            = "Embedded Libraries",
	["Active Embeds"]                     = "Active Embedded Libraries",
	["Loadable OnDemand"]                 = "Loadable on demand",
	["Disabled on reloadUI"]              = "Disabled after Reload UI",
	["LoD Child Enable is now %s"]        = "Load on demand child enabling is now %s.",
	["Recursive Enable is now %s"]        = "Recursive enabling is now %s.",
	["Addons [%s] Saved."]                = "AddOn set [%s] saved.",
	["Addons [%s] Loaded."]               = "AddOn set [%s] loaded.",
	["Addons [%s] Unloaded."]             = "AddOn set [%s] unloaded.",
	["Addons [%s] renamed to [%s]."]      = "AddOn set [%s] renamed to [%s].",
	["Save the current addon list to [%s]?"] = "Save the current AddOn list to [%s]?",
	["ACP: Some protected addons aren't loaded. Reload now?"] =
		"ACP: Some protected AddOns are not enabled. Reload the UI now?",
	["*** Unknown Addon <%s> Required ***"] = "*** Unknown AddOn <%s> required ***",
	["Addon <%s> not valid"]              = "AddOn <%s> is not valid.",
	["Use SHIFT to override the current enabling of dependancies behaviour."] =
		"Use SHIFT to override the current dependency enabling behavior.",
}

local LEGACY_SET_KEY = "Set "
local SET_NAME_KEY   = "Set %d"

local LEGACY_PROTECT_1 = "Click to enable protect mode. Protected addons will not be disabled"
local LEGACY_PROTECT_2 = "when performing a reloadui."
local PROTECT_KEY =
	"Click to toggle protected mode. Protected AddOns are re-enabled automatically when you reload the UI."

local function legacyValue(translations, key)
	local value = translations[key]
	if value == true then
		value = key
	end
	if type(value) ~= "string" or value == "" then
		return nil
	end
	return value
end

local function normalizeLegacyKeys(translations)
	local out = {}
	for key, value in pairs(translations) do
		out[key] = value
	end

	for oldKey, newKey in pairs(LEGACY_LOCALE_KEY_ALIASES) do
		if translations[newKey] == nil then
			local value = legacyValue(translations, oldKey)
			if value then
				out[newKey] = value
			end
		end
	end

	if translations[SET_NAME_KEY] == nil then
		local prefix = legacyValue(translations, LEGACY_SET_KEY)
		if prefix then
			out[SET_NAME_KEY] = prefix .. "%d"
		end
	end

	if translations[PROTECT_KEY] == nil then
		local first = legacyValue(translations, LEGACY_PROTECT_1)
		local second = legacyValue(translations, LEGACY_PROTECT_2)
		if first and second then
			out[PROTECT_KEY] = (first:gsub("%s+$", "")) .. " " ..
			                   (second:gsub("^%s+", ""))
		elseif first then
			out[PROTECT_KEY] = first
		elseif second then
			out[PROTECT_KEY] = second
		end
	end

	return out
end

function ACP:UpdateLocale(translations)
	if type(translations) ~= "table" then
		return false
	end
	return self:RegisterLocale(detectedCode, normalizeLegacyKeys(translations), false)
end

ACP.NormalizeLegacyLocaleKeys = normalizeLegacyKeys
