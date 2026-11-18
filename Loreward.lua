-- Loreward. It has no API for others: its windows and cards are named frames it builds on first
-- use, each setting its own backdrop in its theme's colours (parchment or high contrast). Each one
-- found gets ElvUI's template with ElvUI's colours forced over Loreward's, and its widgets skinned.
-- The progress strip's bar looks like ElvUI's data bars: ElvUI's status bar texture in its value
-- colour, on ElvUI's backdrop instead of Loreward's track; Loreward colours them once, when built.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local Skin = ns.Skin

---@class ElvUIRXPSkinLoreward: ElvUIRXPSkinAddon
local L = { ADDON = "Loreward", key = "loreward" }
ns.Loreward = L

-- Loreward's named frames: its windows (the .NAME of each file), cards and tooltip.
-- stylua: ignore start
L.WINDOWS = {
    "LorewardClassQuestsBox", "LorewardCompartmentTip", "LorewardDirectionsWindow", "LorewardDiscordBox",
    "LorewardEventBox", "LorewardFindWindow", "LorewardStepNotes", "LorewardPlanWindow",
    "LorewardProgressStrip", "LorewardRecapCard", "LorewardSetupBox", "LorewardTourCard",
    "LorewardWhereNextBox",
}
-- stylua: ignore end

-- The windows with a progress bar (the strip), for the colours after a change of ElvUI's media.
local bars = {} ---@type table[]

---The bar in ElvUI's value colour and the hairline above the lines below in its border colour.
---@param frame table
local function colorBar(frame)
    local value, border = E.media.rgbvaluecolor, E.media.bordercolor
    frame.bar:SetStatusBarColor(value.r, value.g, value.b, 1)
    if frame.divider then frame.divider:SetColorTexture(border.r, border.g, border.b, 1) end
end

---A window's progress bar as ElvUI's data bars have theirs: ElvUI's texture, kept by ElvUI when
---that setting changes, ElvUI's backdrop round it (a part inside the window) instead of the track.
---@param frame table
local function skinBar(frame)
    local bar = frame.bar ---@type StatusBar|{track: Texture?}
    bar:SetStatusBarTexture(E.media.normTex)
    E:RegisterStatusBar(bar)
    if bar.track then bar.track:Hide() end
    Skin.Backdrop(bar, "Transparent", true, true)
    colorBar(frame)
    bars[#bars + 1] = frame
end

---@param frame table
local function skin(frame)
    Skin.Window(frame, "Transparent")
    if frame.bar and frame.bar:GetObjectType() == "StatusBar" then skinBar(frame) end
end

function L:Load()
    Skin.Watch(self.WINDOWS, skin)
end

---ElvUI keeps the colours of templates it made up to date itself; the bars' colours are the plugin's.
function L:Update()
    for _, frame in ipairs(bars) do
        colorBar(frame)
    end
end

ns.AddAddon(L)
