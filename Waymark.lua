-- Waymark's As Told panel (AsToldPanel.lua): a named frame built the first time it shows, its dark
-- glass and gold rule drawn as textures straight on the panel, its words in a child frame over all
-- of it. Waymark makes those textures once and never touches them again, so hiding them takes the
-- glass away for good. The panel is the words' width plus EDGE on the right, where the glass faded
-- out; ElvUI's backdrop goes on a frame of its own, under the words and just their width.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local Skin = ns.Skin

---@class ElvUIRXPSkinWaymark: ElvUIRXPSkinAddon
---@field backdrop? Frame the frame with ElvUI's backdrop under the panel's words
local W = { ADDON = "Waymark", key = "waymark" }
ns.Waymark = W

W.WINDOWS = { "WaymarkToldPanel" }
-- AsToldPanel.lua's EDGE: how far the glass reached beyond the words on the right.
W.EDGE = 18

---Hides the glass textures on the panel itself (not those of its child frames).
---@param ... table the panel's regions
local function hideGlass(...)
    for i = 1, select("#", ...) do
        local region = select(i, ...) ---@type table
        if region:GetObjectType() == "Texture" then region:Hide() end
    end
end

---@param panel table
local function skin(panel)
    hideGlass(panel:GetRegions())
    local backdrop = CreateFrame("Frame", nil, panel)
    backdrop:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    backdrop:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -W.EDGE, 0)
    -- The panel's own level, below the words' frame one above it.
    backdrop:SetFrameLevel(panel:GetFrameLevel())
    W.backdrop = backdrop
    -- Part of the HUD: it stays on screen while playing.
    Skin.Backdrop(backdrop, "Transparent", true, false, true)
    Skin.Shadow(backdrop, true)
    -- Its lines are made as the quests change; the panel is resized each time.
    ns.Fonts.Watch(panel)
end

function W:Load()
    Skin.Watch(self.WINDOWS, skin)
end

-- ElvUI keeps the colours of templates it made up to date itself.
function W:Update() end

ns.AddAddon(W)
