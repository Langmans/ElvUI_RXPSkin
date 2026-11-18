-- The plugin on a simulated client (tests/wow.lua): its page in ElvUI's options, the first-run
-- installer and the API for other plugins, and the skins for RestedXP Guides, Loreward and
-- RestedXP Navigator.

---A frame's shadow as far as the tests look at it, or nil when it has none showing.
---@param frame table
---@return table?
local function shadowOf(frame)
    local s = frame.shadow
    if not s or not s:IsShown() then return nil end
    return { length = s.length, colored = s.colored, wind = s.wind }
end

---@param c table an ElvUI colour
---@param a number? the alpha expected, default the colour's own or 1
---@return number[]
local function rgba(c, a)
    return { c.r, c.g, c.b, a or c.a or 1 }
end

describe("the plugin", function()
    it("registers with LibElvUIPlugin under its folder name and adds its module", function()
        local client = NewClient()
        assert.equals("ElvUI_RXPSkin", client.plugin)
        assert.equals("ElvUI_RXPSkin", client.registered)
    end)

    it("takes every name others see from its folder", function()
        local client = NewClient({ name = "Tester" })
        assert.equals("Tester", client.plugin)
        assert.is_table(client.E.db.Tester)
        assert.is_table(client.E.private.Tester)
        assert.is_table(_G.Tester)
        assert.is_table(client:LoadOptions())
    end)

    it("skins all three addons by default and hides RestedXP's banners", function()
        local db = NewClient():Db()
        local expected = {
            restedxp = true,
            loreward = true,
            navigator = true,
            waymark = true,
            hideArt = true,
            scrollHover = true,
            shadow = true,
            style = "elvui",
            alpha = 0.5,
            -- ElvUI's general font and its style (OUTLINE here), without a shadow.
            fonts = true,
            fontFromElvUI = true,
            font = "PT Sans Narrow",
            fontStyle = "OUTLINE",
            fontShadow = false,
        }
        assert.same(expected, db)
    end)
end)

describe("the installer", function()
    it("is queued once, a moment after login, on a character that never ran it", function()
        local client = NewClient()
        assert.equals(0, #client.PI.queue)
        client:RunDelays()
        assert.equals(1, #client.PI.queue)
        assert.equals("ElvUI_RXPSkin", client.PI.queue[1].Name)
    end)

    it("is not queued once it ran", function()
        local client = NewClient({ installed = true })
        client:RunDelays()
        assert.equals(0, #client.PI.queue)
    end)

    it("waits for ElvUI's own installer", function()
        local client = NewClient({ elvuiInstalled = false })
        client:RunDelays()
        assert.equals(0, #client.PI.queue)
    end)

    it("has a page per loaded addon between its welcome and its end", function()
        local client = NewClient()
        client:RunDelays()
        assert.equals(6, #client.PI.queue[1].Pages)
        client = NewClient({ loreward = false, navigator = false, waymark = false })
        client:RunDelays()
        assert.equals(3, #client.PI.queue[1].Pages)
    end)

    it("puts RestedXP on the ElvUI theme, or leaves it be", function()
        local client = NewClient()
        client:RunDelays()
        local frame = client:InstallPage(2)
        assert.is_true(frame.Option1.shown and frame.Option2.shown)
        local renders = client.rxp.renders
        client:Click(1)
        assert.equals("ElvUI", client.rxp.settings.profile.activeTheme)
        assert.is_true(client:Db().restedxp)
        assert.equals(renders + 1, client.rxp.renders)

        client = NewClient({ rxpTheme = "RXP Green" })
        client:RunDelays()
        client:InstallPage(2)
        client:Click(2)
        assert.equals("RXP Green", client.rxp.settings.profile.activeTheme)
        assert.is_false(client:Db().restedxp)
    end)

    it("turns the Loreward, Navigator and Waymark skins on or off", function()
        local client = NewClient()
        client:RunDelays()
        client:InstallPage(3)
        client:Click(2)
        assert.is_false(client:Db().loreward)
        client:InstallPage(4)
        client:Click(2)
        assert.is_false(client:Db().navigator)
        client:InstallPage(4)
        client:Click(1)
        assert.is_true(client:Db().navigator)
        client:InstallPage(5)
        client:Click(2)
        assert.is_false(client:Db().waymark)
    end)

    it("is done on its last page, which offers a reload", function()
        local client = NewClient()
        client:RunDelays()
        client:InstallPage(6)
        client:Click(1)
        assert.is_true(client.E.private.ElvUI_RXPSkin.installed)
        assert.is_true(client.reloaded)
    end)

    it("can be skipped on its first page", function()
        local client = NewClient()
        client:RunDelays()
        local frame = client:InstallPage(1)
        assert.is_true(frame.Option1.shown)
        client:Click(1)
        assert.is_true(client.E.private.ElvUI_RXPSkin.installed)
        assert.is_nil(client.reloaded)
    end)
end)

describe("the API for other plugins", function()
    it("sets the known switches, ignores the rest, and counts as the installer", function()
        local client = NewClient()
        local api = _G.ElvUI_RXPSkin
        assert.is_false(api:IsInstalled())
        api:Configure({ loreward = false, hideArt = false, navigator = "no", shadow = false, bogus = true })
        local db = client:Db()
        assert.same(
            { true, false, true, false, false },
            { db.restedxp, db.loreward, db.navigator, db.hideArt, db.shadow }
        )
        assert.is_nil(db.bogus)
        assert.is_true(api:IsInstalled())
        client:RunDelays()
        assert.equals(0, #client.PI.queue)
    end)

    it("puts RestedXP on the ElvUI theme when asked to", function()
        local client = NewClient()
        _G.ElvUI_RXPSkin:Configure({ rxpTheme = true })
        assert.equals("ElvUI", client.rxp.settings.profile.activeTheme)
    end)

    it("works without a table and without RestedXP", function()
        NewClient({ rxp = false })
        _G.ElvUI_RXPSkin:Configure()
        _G.ElvUI_RXPSkin:Configure({ rxpTheme = true })
        assert.is_true(_G.ElvUI_RXPSkin:IsInstalled())
    end)

    it("shows the installer again", function()
        local client = NewClient({ installed = true })
        _G.ElvUI_RXPSkin:ShowInstaller()
        assert.equals(1, #client.PI.queue)
    end)
end)

describe("the options page", function()
    it("is a page in ElvUI's options with a switch per addon", function()
        local page = NewClient():LoadOptions()
        assert.equals("group", page.type)
        for _, key in ipairs({ "restedxp", "loreward", "navigator", "waymark", "hideArt", "scrollHover", "shadow" }) do
            assert.equals("toggle", page.args[key].type)
            assert.is_true(page.get({ key }))
        end
    end)

    it("greys out the banner switch while RestedXP's skin is off", function()
        local client = NewClient()
        local page = client:LoadOptions()
        assert.is_false(page.args.hideArt.disabled())
        client:Set("restedxp", false)
        assert.is_true(page.args.hideArt.disabled())
    end)

    it("asks for a reload when a skin is turned off, not when one is turned on", function()
        local client = NewClient()
        client:Set("loreward", false)
        assert.same({ "CONFIG_RL" }, client.popups)
        client:Set("loreward", true)
        assert.same({ "CONFIG_RL" }, client.popups)
    end)

    it("runs the installer again from its button", function()
        local client = NewClient({ installed = true })
        client:LoadOptions().args.install.func()
        assert.equals(1, #client.PI.queue)
    end)

    it("is not built without ElvUI_Options", function()
        assert.is_nil(NewClient({ noOptions = true }).E.Options)
    end)
end)

describe("RestedXP Guides", function()
    it("gets an ElvUI theme in ElvUI's colours and font", function()
        local client = NewClient()
        local theme = client.rxp.themes.ElvUI
        local m = client.E.media
        assert.same(rgba(m.backdropfadecolor), theme.background)
        assert.same(rgba(m.backdropcolor), theme.bottomFrameBG)
        assert.same(rgba(m.rgbvaluecolor, 0.5), theme.bottomFrameHighlight)
        assert.same(rgba(m.rgbvaluecolor), theme.mapPins)
        -- The plugin's font (ElvUI's general one by default); ElvUI's own file with the fonts off.
        assert.equals("Fonts\\SharedMedia\\PT Sans Narrow.ttf", theme.font)
        assert.equals(m.blankTex, theme.bgTextures.edge)
        assert.is_true(theme.applicable)
    end)

    it("draws with it at once when RestedXP had it saved", function()
        local client = NewClient({ rxpTheme = "ElvUI" })
        assert.equals(client.rxp.themes.ElvUI, client.rxp.activeTheme)
    end)

    it("follows ElvUI's colours when they change", function()
        local client = NewClient({ rxpTheme = "ElvUI" })
        local theme = client.rxp.themes.ElvUI
        local background = theme.background
        client.E.media.backdropfadecolor = { r = 0.3, g = 0.2, b = 0.1, a = 0.5 }
        local renders = client.rxp.renders
        client.E:UpdateMedia()
        assert.equals(background, theme.background)
        assert.same({ 0.3, 0.2, 0.1, 0.5 }, theme.background)
        assert.equals(renders + 1, client.rxp.renders)
        -- SharedMedia announcing a font changes nothing of ElvUI's own.
        client.E:UpdateMedia("font")
        assert.equals(renders + 1, client.rxp.renders)
    end)

    it("leaves RestedXP's window alone on a colour change while another theme is on", function()
        local client = NewClient()
        local renders = client.rxp.renders
        client.E:UpdateMedia()
        assert.equals(renders, client.rxp.renders)
    end)

    it("gives the v2 copy ElvUI's border colour and a one-pixel edge", function()
        local client = NewClient({ v2 = true })
        local v2 = client.rxp.v2.themes.ElvUI
        local border = rgba(client.E.media.bordercolor)
        assert.same(border, v2.borderColors.common)
        assert.same(border, v2.borderColors.commonEdge)
        assert.equals(client.E.mult, v2.edge.edgeSize)
        client.E.media.bordercolor = { r = 0.5, g = 0.5, b = 0.5 }
        client.E:UpdateMedia()
        assert.same({ 0.5, 0.5, 0.5, 1 }, client.rxp.v2.themes.ElvUI.borderColors.common)
    end)

    it("puts the guide window's frames in ElvUI's template, RestedXP's colour kept", function()
        local client = NewClient({ rxpTheme = "ElvUI" })
        local frame = client.rxp.RXPFrame
        for _, key in ipairs({ "BottomFrame", "GuideName", "Footer" }) do
            assert.equals("Transparent", frame[key].template)
            assert.equals(client.E.media.blankTex, frame[key].backdrop.edgeFile)
            assert.same(rgba(client.E.media.bordercolor), frame[key].borderColor)
        end
        -- RestedXP sets its backdrop again on the next render: ElvUI's comes back.
        client.rxp.RenderFrame()
        assert.equals(client.E.media.blankTex, frame.BottomFrame.backdrop.edgeFile)
        assert.same(client.rxp.themes.ElvUI.background, frame.BottomFrame.backdropColor)
        assert.is_true(frame.BottomFrame.ignoreUpdates)
    end)

    it("skins the active steps and the step list as RestedXP builds them", function()
        local client = NewClient()
        client.rxp.SetStep(2)
        local pool = client.rxp.RXPFrame.CurrentStepFrame.framePool
        assert.equals("Transparent", pool[2].template)
        assert.equals("Transparent", pool[2].number.template)
        client.rxp:LoadGuide(3)
        local list = client.rxp.RXPFrame.ScrollChild.framePool[3]
        assert.equals("Default", list.template)
        assert.same(client.rxp.colors.bottomFrameBG, list.backdropColor)
    end)

    it("skins the step list's scroll bar, and RestedXP no longer puts its own art back", function()
        local client = NewClient()
        local bar = client.rxp.RXPFrame.ScrollFrame.ScrollBar
        assert.equals("ScrollBar", bar.handled)
        local themed = bar.themed
        client.rxp.RenderFrame()
        assert.equals(themed, bar.themed)
    end)

    it("shows the step list's scroll bar only while the pointer is over the guide window", function()
        local client = NewClient()
        local frame = client.rxp.RXPFrame
        local bar = frame.ScrollFrame.ScrollBar
        local driver = client.ns.RestedXP.scrollDriver
        assert.equals(0, bar:GetAlpha())
        assert.equals(frame, driver.parent)
        frame.mouseOver = true
        driver.scripts.OnUpdate(driver, 0.2)
        assert.same({ "in", 0.15, 0, 1 }, client.fades[#client.fades])
        local fades = #client.fades
        driver.scripts.OnUpdate(driver, 0.2)
        assert.equals(fades, #client.fades)
        frame.mouseOver = false
        driver.scripts.OnUpdate(driver, 0.05)
        assert.equals(fades, #client.fades) -- a tenth of a second between looks
        driver.scripts.OnUpdate(driver, 0.06)
        assert.same({ "out", 0.4, 1, 0 }, client.fades[#client.fades])
    end)

    it("keeps the scroll bar in sight with its switch off, at once", function()
        local client = NewClient()
        local bar = client.rxp.RXPFrame.ScrollFrame.ScrollBar
        local driver = client.ns.RestedXP.scrollDriver
        client:Set("scrollHover", false)
        assert.equals(1, bar:GetAlpha())
        assert.is_false(driver:IsShown())
        assert.same({}, client.popups)
        client:Set("scrollHover", true)
        assert.equals(0, bar:GetAlpha())
        assert.is_true(driver:IsShown())
    end)

    it("skins the Active Targets frame and its title once RestedXP builds them", function()
        local client = NewClient({ eltruism = true })
        local f = client:RXPTargetFrame()
        assert.is_nil(f.template)
        client:Tick()
        assert.equals("Transparent", f.template)
        assert.equals("Transparent", f.title.template)
        assert.same(client.rxp.colors.background, f.backdropColor)
        assert.is_table(f.shadow)
        -- RestedXP renders it again: ElvUI's border stays.
        f:SetBackdrop({ edgeFile = "rxp-borders" })
        assert.equals(client.E.media.blankTex, f.backdrop.edgeFile)
    end)

    it("hides the banners behind the guide name and footer, unless told not to", function()
        local client = NewClient()
        local frame = client.rxp.RXPFrame
        assert.is_false(frame.GuideName.bg:IsShown())
        assert.is_false(frame.Footer.bg:IsShown())
        client:Set("hideArt", false)
        assert.is_true(frame.GuideName.bg:IsShown())
        client:Set("hideArt", true)
        assert.is_false(frame.Footer.bg:IsShown())
    end)

    it("puts the player's class icon in an ElvUI frame where RestedXP's logo was", function()
        local client = NewClient()
        local guideName = client.rxp.RXPFrame.GuideName
        assert.is_false(guideName.icon:IsShown())
        assert.is_false(guideName.classIcon:IsShown())
        local holder = client.ns.RestedXP.classIcon
        assert.equals(guideName, holder.parent)
        assert.same({ "CENTER", guideName, "LEFT", 16, 0 }, holder.points[1])
        assert.equals("Default", holder.template)
        assert.is_true(holder:IsShown())
        local icon = holder.icon
        assert.equals("Interface\\WorldStateFrame\\Icons-Classes", icon.file)
        -- The warrior's cell, its round edge cropped.
        assert.same({ 0.02, 0.23, 0.02, 0.23 }, icon.coords)
        -- RestedXP sets its logo again on a render: it stays hidden.
        client.rxp.RenderFrame()
        guideName.icon:Show()
        client.rxp.RenderFrame()
        assert.is_false(guideName.icon:IsShown())
    end)

    it("tints the settings cog in ElvUI's value colour, white under the pointer", function()
        local client = NewClient()
        local cog = client.rxp.RXPFrame.Footer.cog
        local texture = cog:GetNormalTexture()
        local value = client.E.media.rgbvaluecolor
        assert.is_true(texture.desaturated)
        assert.same({ value.r, value.g, value.b, 1 }, texture.color)
        client.rxp.RenderFrame()
        assert.is_true(texture.desaturated)
        assert.same({ value.r, value.g, value.b, 1 }, texture.color)
        cog.scripts.OnEnter(cog)
        assert.same({ 1, 1, 1, 1 }, texture.color)
        cog.scripts.OnLeave(cog)
        assert.same({ value.r, value.g, value.b, 1 }, texture.color)
    end)

    it("gives RestedXP's own logo and cog back with its art switch off, at once", function()
        local client = NewClient()
        local frame = client.rxp.RXPFrame
        client:Set("hideArt", false)
        assert.is_true(frame.GuideName.icon:IsShown())
        assert.is_true(frame.GuideName.classIcon:IsShown())
        assert.is_false(client.ns.RestedXP.classIcon:IsShown())
        local texture = frame.Footer.cog:GetNormalTexture()
        assert.is_false(texture.desaturated)
        assert.same({ 1, 1, 1, 1 }, texture.color)
        frame.Footer.cog.scripts.OnLeave(frame.Footer.cog)
        assert.same({ 1, 1, 1, 1 }, texture.color)
    end)

    it("frames the class icon as a part inside the window: no backdrop in the see-through styles", function()
        local client = NewClient({ db = { style = "transparent" } })
        assert.equals("NoBackdrop", client.ns.RestedXP.classIcon.template)
    end)

    it("leaves RestedXP untouched with its switch off", function()
        local client = NewClient({ db = { restedxp = false } })
        assert.is_nil(client.rxp.themes.ElvUI)
        assert.is_nil(client.rxp.RXPFrame.BottomFrame.template)
        client.rxp.SetStep(1)
        assert.is_nil(client.rxp.RXPFrame.CurrentStepFrame.framePool[1].template)
        assert.is_true(client.rxp.RXPFrame.GuideName.bg:IsShown())
        assert.is_nil(client.rxp.RXPFrame.ScrollFrame.ScrollBar.handled)
        local f = client:RXPTargetFrame()
        client:Tick()
        assert.is_nil(f.template)
    end)

    it("does nothing without RestedXP", function()
        local client = NewClient({ rxp = false })
        assert.is_nil(client.rxp)
        client.E:UpdateMedia()
    end)
end)

describe("Loreward", function()
    it("skins a window the moment it exists, ElvUI's colours over Loreward's own", function()
        local client = NewClient()
        local box = client:LorewardWindow("LorewardWhereNextBox")
        assert.is_nil(box.template)
        client:Tick()
        assert.equals("Transparent", box.template)
        local fade = rgba(client.E.media.backdropfadecolor)
        assert.same(fade, box.backdropColor)
        -- Loreward recolours the card for its theme: ElvUI's colours stay.
        box:SetBackdropColor(0.95, 0.88, 0.7, 0.9)
        box:SetBackdropBorderColor(0.6, 0.45, 0.2, 1)
        assert.same(fade, box.backdropColor)
        assert.same(rgba(client.E.media.bordercolor), box.borderColor)
        box:SetBackdrop({ bgFile = "parchment" })
        assert.equals(client.E.media.blankTex, box.backdrop.bgFile)
    end)

    it("skins its buttons, template check boxes, edit boxes and scroll bars", function()
        local client = NewClient()
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        assert.equals("Button", box.button.handled)
        assert.equals("CheckBox", box.check.handled)
        assert.is_nil(box.ownCheck.handled)
        assert.equals("Default", box.edit.template)
        assert.equals("SliderFrame", box.bar.handled)
    end)

    it("skins widgets added later when the window is shown again, each once", function()
        local client = NewClient()
        local box = client:LorewardWindow("LorewardRecapCard")
        client:Tick()
        local row = client.Frame("Button", nil, box, "UIPanelButtonNoTooltipTemplate")
        box:Show()
        assert.equals("Button", row.handled)
        row.handled = nil
        box:Show()
        assert.is_nil(row.handled)
    end)

    it("stops looking once every window it knows is there", function()
        local client = NewClient({ rxp = false, waymark = false })
        assert.equals(1, client:LiveTimers())
        for _, windowName in ipairs(client.ns.Loreward.WINDOWS) do
            client:LorewardWindow(windowName)
        end
        client:Tick()
        assert.equals(0, client:LiveTimers())
    end)

    it("is left alone with its switch off, or without Loreward", function()
        -- Without RestedXP and Waymark too, whose skins look for frames of their own.
        assert.equals(0, NewClient({ loreward = false, rxp = false, waymark = false }):LiveTimers())
        local client = NewClient({ db = { loreward = false }, rxp = false, waymark = false })
        assert.equals(0, client:LiveTimers())
    end)
end)

describe("Waymark", function()
    it("hides the As Told panel's glass and puts ElvUI's backdrop under its words", function()
        local client = NewClient({ eltruism = true })
        local panel = client:WaymarkPanel()
        client:Tick()
        for _, texture in ipairs(panel.glass) do
            assert.is_false(texture:IsShown())
        end
        assert.is_true(panel.body.mark:IsShown())
        local backdrop = client.ns.Waymark.backdrop
        assert.equals(panel, backdrop.parent)
        assert.equals("Transparent", backdrop.template)
        assert.same({ "TOPLEFT", panel, "TOPLEFT", 0, 0 }, backdrop.points[1])
        assert.same({ "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 0 }, backdrop.points[2])
        assert.equals(panel.level, backdrop.level)
        assert.is_true(panel.body.level > backdrop.level)
        assert.is_table(backdrop.shadow)
    end)

    it("is left alone with its switch off, or without Waymark", function()
        for _, opts in ipairs({ { db = { waymark = false } }, { waymark = false } }) do
            local client = NewClient(opts)
            local panel = client:WaymarkPanel()
            client:Tick()
            assert.is_true(panel.glass[1]:IsShown())
        end
    end)
end)

describe("the translucent style", function()
    local TRANSLUCENT = { style = "translucent", alpha = 0.4 }

    it("gives windows a see-through backdrop and nested parts none", function()
        local client = NewClient({ db = TRANSLUCENT, rxpTheme = "ElvUI" })
        local rxp = client.rxp
        rxp.SetStep(1)
        rxp:LoadGuide(1)
        local step = rxp.RXPFrame.CurrentStepFrame.framePool[1]
        assert.equals("Transparent", step.template)
        assert.equals(0.4, step.customBackdropAlpha)
        assert.equals("NoBackdrop", step.number.template)
        assert.equals("NoBackdrop", rxp.RXPFrame.ScrollChild.framePool[1].template)
        assert.equals(0.4, rxp.themes.ElvUI.background[4])
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        assert.equals(0.4, box.backdropColor[4])
        assert.equals("NoBackdrop", box.edit.template)
        -- Loreward colours its edit box: nothing comes back.
        box.edit:SetBackdropColor(1, 1, 1, 1)
        assert.equals("NoBackdrop", box.edit.template)
        local targets = client:RXPTargetFrame()
        client:Tick()
        assert.equals("NoBackdrop", targets.title.template)
    end)

    it("switches back and forth without a reload, and follows its alpha", function()
        local client = NewClient()
        client.rxp:LoadGuide(1)
        local row = client.rxp.RXPFrame.ScrollChild.framePool[1]
        local bottom = client.rxp.RXPFrame.BottomFrame
        client:Set("style", "translucent")
        assert.equals("NoBackdrop", row.template)
        assert.equals(0.5, bottom.customBackdropAlpha)
        client:Set("alpha", 0.3)
        assert.equals(0.3, bottom.customBackdropAlpha)
        client:Set("style", "elvui")
        assert.equals("Default", row.template)
        assert.is_nil(bottom.customBackdropAlpha)
        assert.same({}, client.popups)
    end)

    it("has a style choice, and an alpha slider greyed out in ElvUI's style", function()
        local client = NewClient()
        local page = client:LoadOptions()
        assert.equals("select", page.args.style.type)
        assert.is_table(page.args.style.values.elvui and page.args.style.values.translucent and page.args.style.values)
        assert.equals("range", page.args.alpha.type)
        assert.is_true(page.args.alpha.disabled())
        client:Set("style", "translucent")
        assert.is_false(page.args.alpha.disabled())
    end)

    it("can be set through the API, a wrong value ignored", function()
        local client = NewClient()
        _G.ElvUI_RXPSkin:Configure({ style = "translucent", alpha = 0.25 })
        assert.equals("translucent", client:Db().style)
        assert.equals(0.25, client:Db().alpha)
        _G.ElvUI_RXPSkin:Configure({ style = "glass", alpha = 2 })
        assert.equals("translucent", client:Db().style)
        assert.equals(0.25, client:Db().alpha)
    end)
end)

describe("the transparent style", function()
    it("takes every backdrop and border away, windows too, and the shadows with them", function()
        local client = NewClient({ eltruism = true, db = { style = "transparent" }, rxpTheme = "ElvUI" })
        local rxp = client.rxp
        rxp.SetStep(1)
        rxp:LoadGuide(1)
        local frame = rxp.RXPFrame
        for _, f in ipairs({ frame.BottomFrame, frame.GuideName, frame.Footer, frame.CurrentStepFrame.framePool[1] }) do
            assert.equals("NoBackdrop", f.template)
        end
        assert.equals("NoBackdrop", frame.ScrollChild.framePool[1].template)
        assert.equals(0, rxp.themes.ElvUI.background[4])
        local box = client:LorewardWindow("LorewardFindWindow")
        local panel = client:WaymarkPanel()
        client:Tick()
        assert.equals("NoBackdrop", box.template)
        assert.equals("NoBackdrop", client.ns.Waymark.backdrop.template)
        assert.is_nil(shadowOf(box))
        assert.is_nil(shadowOf(client.ns.RestedXP.shadowFrame))
        assert.is_false(panel.glass[1]:IsShown())
    end)

    it("gives everything back when the style goes back to ElvUI's", function()
        local client = NewClient({ eltruism = true, db = { style = "transparent" } })
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        client:Set("style", "elvui")
        assert.equals("Transparent", box.template)
        assert.equals("Transparent", client.rxp.RXPFrame.BottomFrame.template)
        assert.same({ length = 4, colored = true }, shadowOf(box))
    end)

    it("is a choice in the options, with the shadow switch and the alpha greyed out", function()
        local client = NewClient({ eltruism = true })
        local page = client:LoadOptions()
        assert.is_string(page.args.style.values.transparent)
        assert.is_false(page.args.shadow.disabled())
        client:Set("style", "transparent")
        assert.is_true(page.args.shadow.disabled())
        assert.is_true(page.args.alpha.disabled())
    end)
end)

describe("the fonts", function()
    local SM = "Fonts\\SharedMedia\\"

    ---What ElvUI's FontTemplate was last given for a font string.
    local function template(client, fs)
        return client.E.texts[fs]
    end

    it("put the chosen font on the text in a skinned window, at the size the addon gave it", function()
        local client = NewClient()
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        for _, fs in ipairs({ box.title, box.row.text }) do
            assert.same({ fontName = "PT Sans Narrow", fontSize = 12, fontStyle = "OUTLINE" }, template(client, fs))
            assert.equals(SM .. "PT Sans Narrow.ttf", (fs:GetFont()))
        end
    end)

    it("come back when the addon sets a font or a font object again", function()
        local client = NewClient()
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        box.title:SetFont("Fonts\\MORPHEUS.ttf", 16, "")
        assert.equals(SM .. "PT Sans Narrow.ttf", (box.title:GetFont()))
        assert.equals(16, template(client, box.title).fontSize)
        box.title:SetFontObject(GameFontNormal)
        assert.equals(SM .. "PT Sans Narrow.ttf", (box.title:GetFont()))
        assert.equals(12, template(client, box.title).fontSize)
    end)

    it("leave text outside the skinned windows alone", function()
        local client = NewClient()
        client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        local other = client.Frame("Frame", "ChatFrame1", UIParent):CreateFontString()
        other:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
        assert.equals("Fonts\\FRIZQT__.TTF", (other:GetFont()))
        assert.is_nil(template(client, other))
    end)

    it("reach text a window gains later, when it shows again or changes size", function()
        local client = NewClient()
        local box = client:LorewardWindow("LorewardFindWindow")
        local panel = client:WaymarkPanel()
        client:Tick()
        local shown = box:CreateFontString(nil, nil, "GameFontNormal")
        box:Show()
        assert.is_table(template(client, shown))
        local line = panel.body:CreateFontString(nil, nil, "GameFontNormal")
        panel.scripts.OnSizeChanged(panel, 300, 80)
        assert.is_table(template(client, line))
        assert.is_table(template(client, panel.body.line))
    end)

    it("give RestedXP's theme the chosen font, and reach its steps' text", function()
        local client = NewClient({ rxpTheme = "ElvUI" })
        assert.equals(SM .. "PT Sans Narrow.ttf", client.rxp.themes.ElvUI.font)
        client.rxp.SetStep(1)
        local text = client.rxp.RXPFrame.CurrentStepFrame.framePool[1].text
        assert.equals("PT Sans Narrow", template(client, text).fontName)
        local targets = client:RXPTargetFrame()
        targets.label = targets:CreateFontString(nil, nil, "GameFontNormal")
        client:Tick()
        assert.is_table(template(client, targets.label))
    end)

    it("follow ElvUI's own font and style by default, also when they change in ElvUI", function()
        local client = NewClient({ rxpTheme = "ElvUI", elvuiFont = "Expressway", elvuiFontStyle = "SHADOWOUTLINE" })
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        assert.same(
            { fontName = "Expressway", fontSize = 12, fontStyle = "SHADOWOUTLINE" },
            template(client, box.title)
        )
        assert.equals(SM .. "Expressway.ttf", client.rxp.themes.ElvUI.font)
        client.E.db.general.font, client.E.db.general.fontStyle = "Roboto", "NONE"
        client.E:UpdateMedia()
        assert.same({ fontName = "Roboto", fontSize = 12, fontStyle = "NONE" }, template(client, box.title))
        assert.equals(SM .. "Roboto.ttf", client.rxp.themes.ElvUI.font)
        -- The plugin's own choice once it no longer follows ElvUI, at once.
        client:Set("fontFromElvUI", false)
        assert.same({ fontName = "PT Sans Narrow", fontSize = 12, fontStyle = "OUTLINE" }, template(client, box.title))
        assert.same({}, client.popups)
    end)

    it("follow a change of font, outline or shadow at once", function()
        local client = NewClient({ rxpTheme = "ElvUI", db = { fontFromElvUI = false } })
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        client:Set("font", "Expressway")
        assert.equals("Expressway", template(client, box.title).fontName)
        assert.equals(SM .. "Expressway.ttf", client.rxp.themes.ElvUI.font)
        client:Set("fontShadow", true)
        assert.equals("SHADOWOUTLINE", template(client, box.title).fontStyle)
        client:Set("fontStyle", "NONE")
        assert.equals("SHADOW", template(client, box.title).fontStyle)
        client:Set("fontShadow", false)
        assert.equals("NONE", template(client, box.title).fontStyle)
        assert.same({}, client.popups)
    end)

    it("stop with their switch off, which asks for a reload; on again, they reach every window", function()
        local client = NewClient({ db = { fonts = false }, rxpTheme = "ElvUI" })
        local box = client:LorewardWindow("LorewardFindWindow")
        client:Tick()
        assert.is_nil(template(client, box.title))
        assert.equals(client.E.media.normFont, client.rxp.themes.ElvUI.font)
        client:Set("fonts", true)
        assert.is_table(template(client, box.title))
        client:Set("fonts", false)
        assert.same({ "CONFIG_RL" }, client.popups)
        box.title:SetFont("Fonts\\MORPHEUS.ttf", 16, "")
        assert.equals("Fonts\\MORPHEUS.ttf", (box.title:GetFont()))
    end)

    it(
        "have a font, an outline without ElvUI's shadow styles, and a shadow switch, greyed out with fonts off",
        function()
            local client = NewClient()
            local args = client:LoadOptions().args
            assert.equals("toggle", args.fonts.type)
            assert.equals("LSM30_Font", args.font.dialogControl)
            assert.is_nil(args.fontStyle.values.SHADOW)
            assert.is_nil(args.fontStyle.values.SHADOWOUTLINE)
            assert.equals("Outline", args.fontStyle.values.OUTLINE)
            assert.equals("toggle", args.fontShadow.type)
            assert.equals("toggle", args.fontFromElvUI.type)
            -- Greyed out while they follow ElvUI's font, the default.
            for _, key in ipairs({ "font", "fontStyle", "fontShadow" }) do
                assert.is_true(args[key].disabled())
            end
            client:Set("fontFromElvUI", false)
            for _, key in ipairs({ "font", "fontStyle", "fontShadow" }) do
                assert.is_false(args[key].disabled())
            end
            client:Set("fonts", false)
            assert.is_true(args.font.disabled())
            assert.is_true(args.fontFromElvUI.disabled())
        end
    )

    it("can be set through the API, a wrong value ignored", function()
        local client = NewClient()
        local api = _G.ElvUI_RXPSkin
        api:Configure({
            fonts = false,
            fontFromElvUI = false,
            font = "Expressway",
            fontStyle = "NONE",
            fontShadow = true,
        })
        local db = client:Db()
        local got = { db.fonts, db.fontFromElvUI, db.font, db.fontStyle, db.fontShadow }
        assert.same({ false, false, "Expressway", "NONE", true }, got)
        api:Configure({ font = 3, fontStyle = "SHADOW", fontShadow = "yes", fontFromElvUI = 1 })
        assert.same({ false, "Expressway", "NONE", true }, { db.fontFromElvUI, db.font, db.fontStyle, db.fontShadow })
    end)
end)

describe("Eltruism", function()
    it("puts its shadow round the guide window and every skinned window when its shadows are on", function()
        local client = NewClient({ eltruism = true })
        local loreward = client:LorewardWindow("LorewardPlanWindow")
        local navigator = client:NavigatorWindow("RXPNavigatorNews")
        client:Tick()
        for _, frame in ipairs({ client.ns.RestedXP.shadowFrame, loreward, navigator }) do
            assert.same({ length = 4, colored = true }, shadowOf(frame))
        end
    end)

    it("takes the shadows off and puts them back with the switch, without a reload", function()
        local client = NewClient({ eltruism = true })
        local box = client:LorewardWindow("LorewardPlanWindow")
        client:Tick()
        local holder = client.ns.RestedXP.shadowFrame
        client:Set("shadow", false)
        assert.is_nil(shadowOf(holder))
        assert.is_nil(shadowOf(box))
        client:Set("shadow", true)
        assert.same({ length = 4, colored = true }, shadowOf(holder))
        assert.same({ length = 4, colored = true }, shadowOf(box))
        assert.same({}, client.popups)
    end)

    it("makes the shadows when the switch goes on after a login with it off", function()
        local client = NewClient({ eltruism = true, db = { shadow = false } })
        local box = client:LorewardWindow("LorewardPlanWindow")
        client:Tick()
        assert.is_nil(shadowOf(box))
        client:Set("shadow", true)
        assert.same({ length = 4, colored = true }, shadowOf(box))
        assert.same({ length = 4, colored = true }, shadowOf(client.ns.RestedXP.shadowFrame))
    end)

    it("puts the guide window's shadow round what shows, not round RestedXP's wider frame", function()
        local client = NewClient({ eltruism = true })
        local frame = client.rxp.RXPFrame
        local holder = client.ns.RestedXP.shadowFrame
        assert.is_nil(frame.shadow)
        assert.equals(frame, holder.parent)
        assert.same({ "TOPLEFT", frame.BottomFrame, "TOPLEFT" }, holder.points[1])
        assert.same({ "BOTTOMRIGHT", frame.Footer, "BOTTOMRIGHT" }, holder.points[2])
        assert.is_true(holder.level < frame.BottomFrame.level)
    end)

    it("leaves the shadows out with Eltruism's shadows off, or without Eltruism", function()
        for _, opts in ipairs({ { eltruism = false }, {} }) do
            local client = NewClient(opts)
            local box = client:LorewardWindow("LorewardPlanWindow")
            client:Tick()
            assert.is_nil(shadowOf(client.ns.RestedXP.shadowFrame))
            assert.is_nil(shadowOf(box))
        end
    end)
end)

describe("WindTools", function()
    it("puts its shadow round the skinned windows while its skins are on", function()
        local client = NewClient({ windtools = true })
        local box = client:LorewardWindow("LorewardPlanWindow")
        client:Tick()
        assert.same({ wind = true }, shadowOf(client.ns.RestedXP.shadowFrame))
        assert.same({ wind = true }, shadowOf(box))
    end)

    it("leaves them out with its skins off", function()
        local client = NewClient({ windtools = false })
        assert.is_nil(shadowOf(client.ns.RestedXP.shadowFrame))
    end)

    it("gives way to Eltruism's shadow, so a window has one", function()
        local client = NewClient({ windtools = true, eltruism = true })
        assert.same({ length = 4, colored = true }, shadowOf(client.ns.RestedXP.shadowFrame))
    end)

    it("leaves them out with its shadow option off, its skins on", function()
        local client = NewClient({ windtools = true, windtoolsShadow = false })
        assert.is_nil(shadowOf(client.ns.RestedXP.shadowFrame))
    end)
end)

describe("the shadow variant", function()
    it("is the one whose addon is loaded with its shadow option on, Eltruism first", function()
        local cases = {
            { {}, nil },
            { { eltruism = true }, "eltruism" },
            { { eltruism = false }, nil },
            { { windtools = true }, "windtools" },
            { { windtools = true, windtoolsShadow = false }, nil },
            { { eltruism = false, windtools = true }, "windtools" },
            { { eltruism = true, windtools = true }, "eltruism" },
        }
        for _, case in ipairs(cases) do
            local client = NewClient(case[1])
            assert.equals(case[2], client.ns.Skin.ShadowVariant())
        end
    end)

    it("is none with the plugin's own shadow switch off", function()
        local client = NewClient({ eltruism = true, db = { shadow = false } })
        assert.is_nil(shadowOf(client.ns.RestedXP.shadowFrame))
        local box = client:LorewardWindow("LorewardPlanWindow")
        client:Tick()
        assert.is_nil(shadowOf(box))
    end)

    it("has its switch greyed out while neither Eltruism nor WindTools is loaded", function()
        local disabled = NewClient():LoadOptions().args.shadow.disabled
        assert.is_true(disabled())
        -- Loaded with its own option off still counts: the switch is there for when it is on.
        assert.is_false(NewClient({ eltruism = false }):LoadOptions().args.shadow.disabled())
        assert.is_false(NewClient({ windtools = false }):LoadOptions().args.shadow.disabled())
    end)
end)

describe("RestedXP Navigator", function()
    it("builds its panels from ElvUI's colours", function()
        local client = NewClient()
        local colors = client.navigator.UI.colors
        local m = client.E.media
        assert.same(rgba(m.backdropfadecolor), colors.background)
        assert.same(rgba(m.backdropcolor), colors.card)
        assert.same(rgba(m.bordercolor), colors.border)
        assert.same(rgba(m.rgbvaluecolor), colors.accent)
    end)

    it("skins the close buttons and drop-downs of its windows", function()
        local client = NewClient({ loreward = false })
        local f = client:NavigatorWindow("RXPNavigatorControlCenter")
        client:Tick()
        assert.equals("CloseButton", f.close.handled)
        assert.equals("DropDownBox", f.dropdown.handled)
        assert.is_nil(f.dropdown.Button.handled)
    end)
end)
