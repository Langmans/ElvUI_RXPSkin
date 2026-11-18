--@debug@
-- Tests that run in the game, through WoWUnit (an addon of its own: install it to run them). They
-- check what the busted specs' test client only assumes: ElvUI's media, Skins and installer, the
-- marks Blizzard's templates leave on widgets, and the shape of RestedXP Guides, Navigator,
-- Eltruism and WindTools where they are loaded. The packager drops what is between the debug
-- markers. tests/ingame_spec.lua runs the same tests on the test client.

local NAME, ns = ... ---@type string, ElvUIRXPSkinNamespace
local Unit = WoWUnit
if not Unit then return end

local E = ElvUI[1]
local AreEqual, IsTrue, IsFalse, Exists = Unit.AreEqual, Unit.IsTrue, Unit.IsFalse, Unit.Exists
local Tests = Unit(NAME, "PLAYER_LOGIN")

---@param value function|table|string|number|boolean|nil
---@return boolean
local function isFunction(value)
    return type(value) == "function"
end

---Whether a colour component read back from the client is the one set, within rounding.
---@param value number
---@param expected number
---@return boolean
local function near(value, expected)
    return math.abs(value - expected) < 0.01
end

---A hidden frame for a test.
---@param kind string
---@param template string?
---@return table
local function Hidden(kind, template)
    local f = CreateFrame(kind, nil, UIParent, template)
    f:Hide()
    return f
end

function Tests:ElvUIMediaHasTheColoursUsed()
    for _, key in ipairs({ "backdropcolor", "backdropfadecolor", "bordercolor", "rgbvaluecolor" }) do
        local c = E.media[key] --[[@as ElvUIColor]]
        IsTrue(type(c.r) == "number")
    end
    IsTrue(type(E.media.hexvaluecolor) == "string")
    Exists(E.media.normFont)
    Exists(E.media.blankTex)
    IsTrue(type(E.mult) == "number")
end

function Tests:ElvUISkinsHasTheHandlersUsed()
    local S = E:GetModule("Skins") ---@type ElvUISkins
    IsTrue(isFunction(S.HandleButton) and isFunction(S.HandleCheckBox) and isFunction(S.HandleCloseButton))
    IsTrue(isFunction(S.HandleSliderFrame) and isFunction(S.HandleDropDownBox))
    IsTrue(isFunction(S.AddCallbackForAddon))
end

function Tests:ElvUIPluginInstallerHasItsFrame()
    local PI = E:GetModule("PluginInstaller") ---@type ElvUIPluginInstaller
    IsTrue(isFunction(PI.Queue))
    IsTrue(isFunction(PI.CloseInstall))
    local f = _G.PluginInstallFrame
    Exists(f)
    for _, key in ipairs({ "SubTitle", "Desc1", "Desc2", "Desc3", "Option1", "Option2" }) do
        Exists(f[key])
    end
end

function Tests:SetTemplateLeavesOutOfColourUpdatesOnRequest()
    local f = Hidden("Frame")
    f:SetTemplate("Transparent", nil, true)
    IsTrue(f.ignoreUpdates)
    IsTrue(isFunction(f.GetBackdropColor))
    IsTrue(isFunction(f.CreateShadow))
end

function Tests:AHookOnAFramesSetBackdropRuns()
    local f = Hidden("Frame", "BackdropTemplate")
    local ran = false
    hooksecurefunc(f, "SetBackdrop", function()
        ran = true
    end)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    IsTrue(ran)
end

function Tests:BackdropColourReadsBack()
    local f = Hidden("Frame", "BackdropTemplate")
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    f:SetBackdropColor(0.25, 0.5, 0.75, 0.5)
    IsTrue(near((f:GetBackdropColor()), 0.25))
    IsTrue(near(select(4, f:GetBackdropColor()), 0.5))
end

function Tests:TemplatesLeaveTheMarksWidgetsAreFoundBy()
    local button = Hidden("Button", "UIPanelButtonNoTooltipTemplate")
    Exists(button.Left and button.Middle and button.Right)
    Exists(Hidden("CheckButton", "UICheckButtonTemplate").Text)
    IsFalse(Hidden("CheckButton").Text)
    local close = Hidden("Button", "UIPanelCloseButton")
    AreEqual("RedButton-Exit", close:GetNormalTexture():GetAtlas())
    local dropdown = Hidden("Frame", "UIDropDownMenuTemplate")
    Exists(dropdown.Left and dropdown.Middle and dropdown.Right and dropdown.Button)
end

function Tests:ASkinnedFrameKeepsElvUIsBorderWhenItsOwnerSetsItsBackdrop()
    local f = Hidden("Frame", "BackdropTemplate")
    ns.Skin.Backdrop(f, "Transparent", true)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border" })
    f:SetBackdropBorderColor(1, 0, 0, 1)
    AreEqual(E.media.blankTex, f:GetBackdrop().edgeFile)
    IsTrue(near((f:GetBackdropBorderColor()), E.media.bordercolor.r))
end

function Tests:RestedXPHasWhatTheSkinUses()
    if not C_AddOns.IsAddOnLoaded("RXPGuides") then return end
    local rxp = LibStub("AceAddon-3.0"):GetAddon("RXPGuides", true) --[[@as RXPGuidesAddon]]
    Exists(rxp)
    IsTrue(isFunction(rxp.RegisterTheme) and isFunction(rxp.RenderFrame))
    IsTrue(isFunction(rxp.SetStep) and isFunction(rxp.LoadGuide))
    IsTrue(isFunction(rxp.v2.IsGuideWindowEnabled) and isFunction(rxp.v2.ConvertThemes))
    Exists(rxp.settings.profile.activeTheme)
    local frame = rxp.RXPFrame
    Exists(frame.GuideName.bg and frame.Footer.bg and frame.BottomFrame)
    Exists(frame.CurrentStepFrame.framePool and frame.ScrollChild.framePool)
    IsTrue(isFunction(frame.UpdateVisuals))
    if ns.db().restedxp then Exists(rxp.themes[ns.RestedXP.THEME]) end
end

function Tests:NavigatorHasItsColourTable()
    if not C_AddOns.IsAddOnLoaded("RXP_Navigator") then return end
    local navigator = _G.RXPNavigator --[[@as RXPNavigatorGlobal]]
    local ui = navigator.UI --[[@as {colors: table<string, number[]>}]]
    local colors = ui.colors
    for _, role in ipairs({ "background", "card", "border", "accent" }) do
        AreEqual(4, #colors[role])
    end
end

function Tests:EltruismAndWindToolsHaveTheirShadowSettings()
    local eltruism = _G.ElvUI_EltreumUI
    if eltruism then
        IsTrue(isFunction(eltruism.ShadowColor))
        local shadow = E.db.ElvUI_EltreumUI.skins.shadow ---@type EltruismShadowSettings
        IsTrue(type(shadow.enable) == "boolean" and type(shadow.length) == "number")
    end
    local windTools = _G.WindTools
    if windTools then
        IsTrue(isFunction(windTools[1].Modules.Skins.CreateShadow))
        local skins = E.private.WT.skins ---@type WindToolsSkinSettings
        IsTrue(type(skins.enable) == "boolean" and type(skins.shadow) == "boolean")
    end
end
--@end-debug@
