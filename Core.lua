-- The plugin's ElvUI module and its API for other plugins. Its settings live in ElvUI's profile
-- under the folder name (E.db[NAME]), whether its installer ran in ElvUI's private settings. Each
-- skinned addon is a module in ns.addons (RestedXP.lua, Loreward.lua, Navigator.lua, Waymark.lua):
-- ElvUI's Skins calls it once that addon is loaded, Load the first time it is switched on, Update
-- after that.

local NAME, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E, V, P = ElvUI[1], ElvUI[3], ElvUI[4]

ns.NAME = NAME
ns.addons = {}
-- The switches other plugins may set through the API, with the option page's order.
ns.SWITCHES = { "restedxp", "loreward", "navigator", "waymark", "hideArt", "shadow", "fonts" }

-- ElvUI's general font style, split as the options show it: an outline and a shadow switch.
local shadow = P.general.fontStyle:sub(1, 6) == "SHADOW"
local outline = shadow and P.general.fontStyle:sub(7) or P.general.fontStyle

P[NAME] = {
    restedxp = true,
    loreward = true,
    navigator = true,
    waymark = true,
    hideArt = true,
    shadow = true,
    style = "elvui",
    alpha = 0.5,
    fonts = true,
    font = P.general.font,
    fontStyle = outline ~= "" and outline or "NONE",
    fontShadow = shadow,
}
V[NAME] = { installed = false }

local M = E:NewModule(NAME, "AceHook-3.0")

---The plugin's settings in the current profile.
---@return ElvUIRXPSkinSettings
function ns.db()
    return E.db[NAME] --[[@as ElvUIRXPSkinSettings]]
end

local outlines ---@type table<string, string>?

---ElvUI's font styles less its "Shadow ..." ones, which the shadow switch stands for: the outlines
---the plugin offers, by key with their names. Built the first time it is asked for.
---@return table<string, string>
function ns.outlines()
    if not outlines then
        outlines = {}
        for key, styleName in pairs(E.Libs.ACH.FontValues) do
            if key:sub(1, 6) ~= "SHADOW" then outlines[key] = styleName end
        end
    end
    return outlines
end

---Skins the addon when it is loaded and its switch is on: the first time with Load, then Update.
---@param module ElvUIRXPSkinAddon
local function apply(module)
    if not module.present or not ns.db()[module.key] then return end
    if module.applied then
        module:Update()
    else
        module.applied = true
        module:Load()
    end
end

---Skins every loaded addon again with the current settings and ElvUI's media.
function ns.Update()
    ns.Fonts.Update()
    ns.Skin.Refresh()
    for _, module in ipairs(ns.addons) do
        apply(module)
    end
end

---After ElvUI read its media again. With a media type it is SharedMedia announcing a new font or
---texture, which changes nothing of ElvUI's own.
---@param _ table E
---@param mediaType string?
function M:MediaChanged(_, mediaType)
    if not mediaType then ns.Update() end
end

function M:Initialize()
    LibStub("LibElvUIPlugin-1.0"):RegisterPlugin(NAME, ns.InsertOptions)
    self:SecureHook(E, "UpdateMedia", "MediaChanged")
    -- A moment later, so another plugin's own installer can configure this one first.
    if not ns.Install.Done() then E:Delay(1, ns.Install.Queue) end
end

local S = E:GetModule("Skins") ---@type ElvUISkins

---Adds an addon's skin. ElvUI's Skins calls it during its own start for an addon already loaded,
---before any plugin's module, so this runs as the files load and not in Initialize.
---@param module ElvUIRXPSkinAddon
function ns.AddAddon(module)
    ns.addons[#ns.addons + 1] = module
    S:AddCallbackForAddon(module.ADDON, NAME .. "_" .. module.ADDON, function()
        module.present = true
        apply(module)
    end)
end

-- The API other plugins (an ElvUI edit's installer, say) use to set this one up: _G[NAME].
---@class ElvUIRXPSkinAPI
local API = {}
_G[NAME] = API

---Sets the plugin up as its installer would, and counts as the installer having run.
---`settings` holds booleans by the option keys (restedxp, loreward, navigator, waymark, hideArt,
---shadow, fonts, fontShadow), `style` ("elvui", "translucent" or "transparent"), `alpha` (0 to 1,
---the translucent backdrop's), `font` (a SharedMedia font name) and `fontStyle` (an outline from
---ElvUI's font styles, not a "SHADOW..." one); anything else, or a value out of range, is ignored.
---`rxpTheme = true` also puts RestedXP Guides on the ElvUI theme.
---@param settings table?
function API:Configure(settings)
    settings = settings or {}
    local db = ns.db()
    for _, key in ipairs(ns.SWITCHES) do
        if type(settings[key]) == "boolean" then db[key] = settings[key] end
    end
    if type(settings.fontShadow) == "boolean" then db.fontShadow = settings.fontShadow end
    if ns.Skin.styles[settings.style] then db.style = settings.style end
    local alpha = type(settings.alpha) == "number" and tonumber(settings.alpha) or nil
    if alpha and alpha >= 0 and alpha <= 1 then db.alpha = alpha end
    if type(settings.font) == "string" and settings.font ~= "" then db.font = settings.font end
    if ns.outlines()[settings.fontStyle] then db.fontStyle = settings.fontStyle end
    ns.Update()
    if settings.rxpTheme then ns.RestedXP.UseTheme() end
    ns.Install.Finish()
end

---Whether the installer ran (or another plugin configured this one) on this character.
---@return boolean
function API:IsInstalled()
    return ns.Install.Done()
end

---Shows the installer, also when it ran before.
function API:ShowInstaller()
    ns.Install.Queue(true)
end

E:RegisterModule(M:GetName())
