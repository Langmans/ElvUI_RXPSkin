-- Loreward. It has no API for others: its windows and cards are named frames it builds on first
-- use, each setting its own backdrop in its theme's colours (parchment or high contrast). Each one
-- found gets ElvUI's template with ElvUI's colours forced over Loreward's, and its widgets skinned.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
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

---@param frame table
local function skin(frame)
    Skin.Window(frame, "Transparent")
end

function L:Load()
    Skin.Watch(self.WINDOWS, skin)
end

-- ElvUI keeps the colours of templates it made up to date itself.
function L:Update() end

ns.AddAddon(L)
