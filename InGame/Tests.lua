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
    IsTrue(isFunction(S.HandleSliderFrame) and isFunction(S.HandleDropDownBox) and isFunction(S.HandleScrollBar))
    IsTrue(isFunction(S.AddCallbackForAddon))
end

function Tests:TheClassIconSheetKnowsThePlayersClass()
    local _, class = UnitClass("player")
    ---@type number[]?
    local cell = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    Exists(cell)
    IsTrue(cell ~= nil and #cell == 4)
end

function Tests:ElvUIHasItsFades()
    IsTrue(isFunction(E.UIFrameFadeIn) and isFunction(E.UIFrameFadeOut))
end

function Tests:LorewardsStripHasItsBarTrackAndDivider()
    IsTrue(isFunction(E.RegisterStatusBar))
    ---@type table?
    local strip = _G.LorewardProgressStrip
    if not strip then return end
    AreEqual("StatusBar", strip.bar:GetObjectType())
    Exists(strip.bar.track)
    Exists(strip.divider)
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

function Tests:ColoursOnAFrameWithoutBackdropAreHarmless()
    -- The translucent style leaves nested parts without a backdrop; RestedXP still colours them.
    local f = Hidden("Frame", "BackdropTemplate")
    f:SetTemplate("NoBackdrop", nil, true)
    f:SetBackdropColor(1, 0, 0, 1)
    f:SetBackdropBorderColor(1, 0, 0, 1)
    IsFalse(f:GetBackdrop())
end

function Tests:FontStringsShareTheMethodsTheFontHookIsOn()
    local fs = UIParent:CreateFontString()
    local methods = getmetatable(fs).__index --[[@as table]]
    IsTrue(isFunction(methods.SetFont) and isFunction(methods.SetFontObject))
    IsTrue(isFunction(methods.FontTemplate))
end

function Tests:AWatchedWindowsTextKeepsTheChosenFont()
    if not ns.db().fonts then return end
    local f = Hidden("Frame")
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal") --[[@as FontString]]
    ns.Fonts.Watch(f)
    fs:SetFont("Fonts\\MORPHEUS.ttf", 15, "")
    -- The font in use: ElvUI's general one while the plugin follows it, else its own.
    AreEqual(E.Libs.LSM:Fetch("font", (ns.Fonts.Current())), (fs:GetFont()))
    IsTrue(near(select(2, fs:GetFont()), 15))
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

---A frame skinned as the plugin does it, whose owner then sets its own backdrop and border colour.
---@param hud boolean
---@return table
local function OwnedFrame(hud)
    local f = Hidden("Frame", "BackdropTemplate")
    ns.Skin.Backdrop(f, "Transparent", true, false, hud)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border" })
    f:SetBackdropBorderColor(1, 0, 0, 1)
    return f
end

---ElvUI's one-pixel backdrop in its border colour.
---@param f table
local function HasElvUIsBorder(f)
    ---@type {edgeFile: string?}?
    local backdrop = f:GetBackdrop()
    AreEqual(E.media.blankTex, backdrop and backdrop.edgeFile)
    IsTrue(near((f:GetBackdropBorderColor()), E.media.bordercolor.r))
end

function Tests:AWindowKeepsElvUIsBorderWhenItsOwnerSetsItsBackdrop()
    HasElvUIsBorder(OwnedFrame(false))
end

function Tests:TheHUDKeepsItsStyleWhenItsOwnerSetsItsBackdrop()
    local f = OwnedFrame(true)
    -- The transparent style leaves the HUD no backdrop at all, whatever the owner sets.
    if ns.Skin.Transparent() then
        IsFalse(f:GetBackdrop())
        return
    end
    HasElvUIsBorder(f)
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
    IsTrue(isFunction(frame.UpdateVisuals) and isFunction(frame.UpdateScrollBar))
    Exists(frame.ScrollFrame.ScrollBar)
    -- Where names get their colours: the text colours by tag, the two functions hooked.
    IsTrue(isFunction(rxp.settings.ReplaceColors) and isFunction(rxp.Call))
    IsTrue(type(rxp.guideTextColors.RXP_ENEMY_) == "string" and type(rxp.guideTextColors.RXP_LOOT_) == "string")
    -- The step list the plugin marks: the guide's progress, the list's update, and with a guide
    -- loaded, rows with their step and number.
    IsTrue(isFunction(rxp.GetGuideProgress) and isFunction(frame.BottomFrame.UpdateFrame))
    local row = frame.ScrollChild.framePool[1]
    if row then Exists(row.step and row.number and row.number.text) end
    -- The art the plugin swaps: the logo and its class icon, and the cog button's texture.
    Exists(frame.GuideName.icon and frame.GuideName.classIcon)
    Exists(frame.Footer.cog:GetNormalTexture())
    -- The Active Targets frame, once RestedXP built it, has its title tab.
    ---@type table?
    local targets = _G.RXPTargetFrame
    if targets then Exists(targets.title) end
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

function Tests:WaymarksPanelHasItsGlassOnItselfAndItsWordsAbove()
    ---@type table?
    local panel = _G.WaymarkToldPanel
    if not panel then return end
    IsTrue(select("#", panel:GetRegions()) > 0)
    local words = panel:GetChildren() --[[@as table]]
    Exists(words)
    IsTrue(words:GetFrameLevel() > panel:GetFrameLevel())
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
