-- RestedXP Navigator. Its UI helper (UI\Theme.lua) builds every panel, button and check box from
-- one colour table, RXPNavigator.UI.colors, read when a panel is made; this fills it with ElvUI's
-- colours. Its named windows then get their remaining Blizzard widgets skinned: close buttons and
-- drop-down menus.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local Skin = ns.Skin

---@class ElvUIRXPSkinNavigator: ElvUIRXPSkinAddon
local N = { ADDON = "RXP_Navigator", key = "navigator" }
ns.Navigator = N

N.WINDOWS = {
    "RXPNavigatorControlCenter",
    "RXPNavigatorSetupWizard",
    "RXPNavigatorLayoutPanel",
    "RXPNavigatorNews",
    "RXPNavigatorCopyDialog",
}

-- Navigator's colour roles, each with the ElvUI colour that takes it.
local roles = {
    background = "backdropfadecolor",
    card = "backdropcolor",
    border = "bordercolor",
    accent = "rgbvaluecolor",
}

---Navigator's colour table in ElvUI's colours, filled in place. A panel takes the values when it
---is made, so one made before a colour change keeps the old colour until a reload.
local function color()
    local navigator = _G.RXPNavigator
    local colors = navigator and navigator.UI and navigator.UI.colors
    if not colors then return end
    for role, media in pairs(roles) do
        local t, c = colors[role], E.media[media] --[[@as ElvUIColor]]
        t[1], t[2], t[3], t[4] = c.r, c.g, c.b, c.a or 1
    end
end

---A window gets its widgets skinned; its panels already have ElvUI's colours.
---@param frame table
local function skin(frame)
    Skin.Window(frame)
end

function N:Load()
    color()
    Skin.Watch(self.WINDOWS, skin)
end

function N:Update()
    color()
end

ns.AddAddon(N)
