-- The plugin's page in ElvUI's options (/ec > RXP Skin): a switch per addon and one for RestedXP's
-- banners, read and written by key in the profile. Switching a skin off asks for a reload, which
-- is what takes it off; switching one on skins at once.

local NAME, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local L = LibStub("AceLocale-3.0"):GetLocale(NAME)

---@param info string[]
---@return boolean
local function get(info)
    return ns.db()[info[#info]] --[[@as boolean]]
end

---@param info string[]
---@param value boolean
local function set(info, value)
    local key = info[#info]
    ns.db()[key] = value
    if not value and key ~= "hideArt" then E:StaticPopup_Show("CONFIG_RL") end
    ns.Update()
end

---@return boolean
local function rxpOff()
    return not ns.db().restedxp
end

---The shadow switch does something only with Eltruism or WindTools loaded.
---@return boolean
local function noShadowAddon()
    return not ns.Skin.ShadowAddonLoaded()
end

---LibElvUIPlugin calls this once ElvUI's options are loaded.
function ns.InsertOptions()
    local ACH = E.Libs.ACH
    local page = ACH:Group(L.TITLE, nil, 100, nil, get, set)
    local args = page.args
    args.desc = ACH:Description(L.DESC, 0)
    for order, key in ipairs(ns.SWITCHES) do
        args[key] = ACH:Toggle(L[key .. "_TITLE"], L[key .. "_DESC"], order, nil, nil, "full")
    end
    args.hideArt.disabled = rxpOff
    args.shadow.disabled = noShadowAddon
    args.install = ACH:Execute(L.INSTALL_AGAIN, nil, 10, function()
        ns.Install.Queue(true)
    end)
    E.Options.args[NAME] = page
end
