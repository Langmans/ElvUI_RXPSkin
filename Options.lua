-- The plugin's page in ElvUI's options (/ec > RXP Skin): a switch per addon, RestedXP's banners,
-- the shadows, the style with its alpha, and the fonts, read and written by key in the profile.
-- Switching a skin or the fonts off asks for a reload, which is what takes it off; everything else
-- applies at once.

local NAME, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local L = LibStub("AceLocale-3.0"):GetLocale(NAME)

---@param info string[]
---@return boolean|string|number
local function get(info)
    return ns.db()[info[#info]] --[[@as boolean|string|number]]
end

-- The switches that take effect both ways at once; switching off any other skin needs a reload.
local live = { hideArt = true, shadow = true, fontShadow = true }

---@param info string[]
---@param value boolean|string|number
local function set(info, value)
    local key = info[#info]
    ns.db()[key] = value
    if value == false and not live[key] then E:StaticPopup_Show("CONFIG_RL") end
    ns.Update()
end

---@return boolean
local function rxpOff()
    return not ns.db().restedxp
end

---The shadow switch does something only with Eltruism or WindTools loaded, and not in the
---transparent style.
---@return boolean
local function noShadow()
    return not ns.Skin.ShadowAddonLoaded() or ns.Skin.Transparent()
end

---The alpha slider does something only in the translucent style.
---@return boolean
local function notTranslucent()
    return ns.db().style ~= ns.Skin.styles.translucent
end

---@return boolean
local function fontsOff()
    return not ns.db().fonts
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
    args.shadow.disabled = noShadow
    local styles = {
        [ns.Skin.styles.elvui] = L.STYLE_ELVUI,
        [ns.Skin.styles.translucent] = L.STYLE_TRANSLUCENT,
        [ns.Skin.styles.transparent] = L.STYLE_TRANSPARENT,
    }
    args.style = ACH:Select(L.STYLE, L.STYLE_DESC, 10, styles)
    local range = { min = 0, max = 1, step = 0.05, isPercent = true }
    args.alpha = ACH:Range(L.ALPHA, L.ALPHA_DESC, 11, range, nil, nil, nil, notTranslucent)
    -- The fonts, below the styles.
    args.fonts.order = 20
    args.font = ACH:SharedMediaFont(L.FONT, nil, 21, nil, nil, nil, fontsOff)
    args.fontStyle = ACH:FontFlags(L.FONT_STYLE, nil, 22, nil, nil, nil, fontsOff)
    args.fontStyle.values = ns.outlines()
    args.fontShadow = ACH:Toggle(L.FONT_SHADOW, L.FONT_SHADOW_DESC, 23, nil, nil, nil, nil, nil, fontsOff)
    args.install = ACH:Execute(L.INSTALL_AGAIN, nil, 30, function()
        ns.Install.Queue(true)
    end)
    E.Options.args[NAME] = page
end
