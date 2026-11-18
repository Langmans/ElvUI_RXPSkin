-- A simulated client for the plugin. ElvUI: E with its media, profile, private settings and options,
-- SetTemplate as Toolkit.lua has it, the Skins module's Handle* functions and addon callbacks, the
-- PluginInstaller and its frame, LibElvUIPlugin, AceLocale and LibAceConfigHelper. RestedXP Guides:
-- its themes (Themes.lua) and the v1 guide window (GuideWindow.lua) that sets its own backdrops.
-- Loreward and RestedXP Navigator: named windows they build later, with the widgets they use.
-- NewClient() resets the globals, loads the addons, then the .toc's files, then logs in.

---@class TestClientOptions
---@field name string? the folder name the plugin is loaded under, default ElvUI_RXPSkin
---@field rxp boolean? default true: RestedXP Guides is loaded
---@field loreward boolean? default true: Loreward is loaded
---@field navigator boolean? default true: RestedXP Navigator is loaded
---@field installed boolean? the plugin's installer already ran on this character
---@field elvuiInstalled boolean? default true: ElvUI's own installer is done
---@field v2 boolean? RestedXP's v2 interface is on
---@field rxpTheme string? RestedXP's saved theme, default "RXP Blue"
---@field noOptions boolean? ElvUI_Options not loaded
---@field db table? the plugin's settings in the profile, over its defaults
---@field eltruism boolean? Eltruism (ElvUI_EltreumUI) is loaded, with its shadows on (true) or off
---@field windtools boolean? ElvUI_WindTools is loaded, with its skins on (true) or off
---@field windtoolsShadow boolean? WindTools' own shadow option, default on
---@field waymark boolean? default true: Waymark is loaded
---@field elvuiFont string? ElvUI's general font in the profile (E.db.general.font)
---@field elvuiFontStyle string? and its style (E.db.general.fontStyle)

---@param t table
---@return table
local function copy(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = type(v) == "table" and copy(v) or v
    end
    return c
end

-- The globals named frames of earlier clients left, cleared by the next one.
local namedFrames = {}

---@param opts TestClientOptions?
function NewClient(opts)
    opts = opts or {}
    for _, frameName in ipairs(namedFrames) do
        _G[frameName] = nil
    end
    namedFrames = {}
    local name = opts.name or "ElvUI_RXPSkin"
    local client = { modules = {}, ns = {}, NAME = name, timers = {}, delays = {}, popups = {} }

    function hooksecurefunc(object, method, hook)
        if type(object) == "string" then
            object, method, hook = _G, object, method
        end
        local original = object[method]
        object[method] = function(...)
            local results = { original(...) }
            hook(...)
            return unpack(results)
        end
    end
    function wipe(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end
    function CopyTable(t)
        return copy(t)
    end
    -- The player is a warrior; the class icon sheet's cells as the client has them.
    function UnitClass()
        return "Warrior", "WARRIOR", 1
    end
    CLASS_ICON_TCOORDS = { WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 } }
    ReloadUI = function()
        client.reloaded = true
    end

    -- C_Timer's ticker, run by hand: client:Tick() fires every live one once.
    C_Timer = {
        NewTicker = function(_, fn)
            local ticker = { fn = fn }
            function ticker:Cancel()
                self.cancelled = true
            end
            client.timers[#client.timers + 1] = ticker
            return ticker
        end,
    }
    function client:Tick()
        for _, ticker in ipairs(self.timers) do
            if not ticker.cancelled then ticker.fn(ticker) end
        end
    end
    ---The tickers still running.
    ---@return integer
    function client:LiveTimers()
        local n = 0
        for _, ticker in ipairs(self.timers) do
            if not ticker.cancelled then n = n + 1 end
        end
        return n
    end

    -- Font strings share one metatable, as in the client: a hook on it reaches every one. Font
    -- objects (CreateFont) have their own, with the same font methods.
    local fontMethods = {}
    function fontMethods:GetObjectType()
        return "FontString"
    end
    function fontMethods:SetFont(path, size, flags)
        self.font, self.size, self.flags = path, size, flags or ""
    end
    function fontMethods:GetFont()
        return self.font, self.size, self.flags
    end
    function fontMethods:SetFontObject(object)
        self.fontObject = object
        self.font, self.size, self.flags = object:GetFont()
    end
    function fontMethods:SetShadowColor(_, _, _, a)
        self.shadowAlpha = a
    end
    function fontMethods:SetShadowOffset(x, y)
        self.shadowX, self.shadowY = x, y
    end
    function fontMethods:SetText(text)
        self.text = text
    end
    function fontMethods:Show()
        self.shown = true
    end
    function fontMethods:Hide()
        self.shown = false
    end
    function fontMethods:IsShown()
        return self.shown
    end
    local fontMeta = { __index = fontMethods }
    local objectMethods = setmetatable({
        GetObjectType = function()
            return "Font"
        end,
    }, { __index = fontMethods })
    function CreateFont(fontName)
        local font = setmetatable({}, { __index = objectMethods })
        if fontName then _G[fontName] = font end
        return font
    end
    GameFontNormal = CreateFont("GameFontNormal")
    GameFontNormal:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    client.fontMethods = fontMethods

    ---A region: a texture, or a font string, which takes a font template's font as the client
    ---does, without a call.
    ---@param kind string? "Texture" or "FontString"
    ---@param template string? a font object's name, for a font string
    local function Region(kind, template)
        if kind == "FontString" then
            local fs = setmetatable({ shown = true }, fontMeta)
            if template then
                fs.font, fs.size, fs.flags = _G[template]:GetFont()
            end
            return fs
        end
        local r = { shown = true, kind = "Texture" }
        function r:GetObjectType()
            return self.kind
        end
        function r:SetTexture(file)
            self.file = file
        end
        function r:Show()
            self.shown = true
        end
        function r:Hide()
            self.shown = false
        end
        function r:IsShown()
            return self.shown
        end
        function r:SetShown(shown)
            self.shown = not not shown
        end
        function r:SetColorTexture(red, g, b, a)
            self.color = { red, g, b, a }
        end
        function r:SetVertexColor(red, g, b, a)
            self.color = { red, g, b, a or 1 }
        end
        function r:SetDesaturated(desaturated)
            self.desaturated = desaturated
        end
        function r:SetTexCoord(...)
            self.coords = { ... }
        end
        function r:SetInside()
            self.inside = true
        end
        return r
    end

    ---A frame as the client makes one: a named one is a global, with BackdropTemplate it has the
    ---backdrop API. Extra fields (Left, Text, ...) stand for what a template adds.
    ---@param kind string? the object type, default "Frame"
    ---@param frameName string?
    ---@param parent table?
    ---@param template string?
    ---@return table
    local function Frame(kind, frameName, parent, template)
        local f = { kind = kind or "Frame", name = frameName, children = {}, regions = {}, scripts = {} }
        f.shown, f.parent, f.points = true, parent, {}
        -- A child sits one level above its parent, as the client stacks them.
        f.level = parent and parent.level and parent.level + 1 or 1
        function f:SetPoint(point, relativeTo, relativePoint, x, y)
            self.points[#self.points + 1] = { point, relativeTo, relativePoint, x, y }
        end
        function f:GetFrameLevel()
            return self.level
        end
        function f:SetSize(w, h)
            self.width, self.height = w, h
        end
        f.alpha = 1
        function f:SetAlpha(alpha)
            self.alpha = alpha
        end
        function f:GetAlpha()
            return self.alpha
        end
        ---Whether the pointer is over the frame: set by a test as mouseOver.
        function f:IsMouseOver()
            return self.mouseOver == true
        end
        function f:SetShown(shown)
            self.shown = not not shown
        end
        function f:SetFrameLevel(level)
            self.level = level
        end
        if parent then parent.children[#parent.children + 1] = f end
        if frameName then
            _G[frameName] = f
            namedFrames[#namedFrames + 1] = frameName
        end
        function f:GetName()
            return self.name
        end
        function f:GetObjectType()
            return self.kind
        end
        function f:GetChildren()
            return unpack(self.children)
        end
        function f:GetRegions()
            return unpack(self.regions)
        end
        function f:CreateTexture()
            local t = Region("Texture")
            self.regions[#self.regions + 1] = t
            return t
        end
        function f:CreateFontString(_, _, template)
            local t = Region("FontString", template)
            self.regions[#self.regions + 1] = t
            return t
        end
        function f:Show()
            self.shown = true
            if self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function f:Hide()
            self.shown = false
        end
        function f:IsShown()
            return self.shown
        end
        function f:SetScript(script, fn)
            self.scripts[script] = fn
        end
        function f:HookScript(script, fn)
            local old = self.scripts[script]
            self.scripts[script] = function(...)
                if old then old(...) end
                fn(...)
            end
        end
        function f:SetTemplate(...)
            return client.E:SetTemplate(self, ...)
        end
        ---Toolkit.lua's CreateShadow: a shadow frame of the given size round the frame.
        function f:CreateShadow(size)
            self.shadow = Frame("Frame", nil, self)
            self.shadow.length = size
        end
        if template == "BackdropTemplate" then client.Mixin(f) end
        -- What the Blizzard templates leave on a widget (InGame/Tests.lua checks these in the game).
        if template == "UIPanelButtonNoTooltipTemplate" or template == "UIDropDownMenuTemplate" then
            f.Left, f.Middle, f.Right = f:CreateTexture(), f:CreateTexture(), f:CreateTexture()
        end
        if template == "UIDropDownMenuTemplate" then f.Button = Frame("Button", nil, f) end
        if template == "UICheckButtonTemplate" then f.Text = f:CreateFontString() end
        if template == "UIPanelCloseButton" then
            local normal = f:CreateTexture()
            function normal:GetAtlas()
                return "RedButton-Exit"
            end
            function f:GetNormalTexture()
                return normal
            end
        end
        return f
    end
    client.Frame = Frame

    ---BackdropTemplateMixin: the backdrop API, recording what was set last.
    ---@param f table
    function client.Mixin(f)
        function f:SetBackdrop(backdrop)
            self.backdrop = backdrop
            self.backdropColor, self.borderColor = nil, { 1, 1, 1, 1 }
        end
        function f:ClearBackdrop()
            self.backdrop = nil
        end
        function f:SetBackdropColor(r, g, b, a)
            self.backdropColor = { r, g, b, a or 1 }
        end
        function f:GetBackdropColor()
            if self.backdropColor then return unpack(self.backdropColor) end
        end
        function f:GetBackdrop()
            return self.backdrop
        end
        function f:GetBackdropBorderColor()
            return unpack(self.borderColor)
        end
        function f:SetBackdropBorderColor(r, g, b, a)
            self.borderColor = { r, g, b, a or 1 }
        end
    end
    function CreateFrame(kind, frameName, parent, template)
        return Frame(kind, frameName, parent, template)
    end
    UIParent = Frame("Frame", "UIParent")

    -- LibStub with the libraries the plugin asks for; RestedXP's addon object comes later.
    local locales, aceAddons = {}, {}
    local ACH = {}
    function ACH:Group(groupName, desc, order, childGroups, get, set)
        return { type = "group", name = groupName, desc = desc, order = order, get = get, set = set, args = {} }
    end
    function ACH:Toggle(toggleName, desc, order, _, _, width, get, set, disabled)
        return {
            type = "toggle",
            name = toggleName,
            desc = desc,
            order = order,
            width = width,
            get = get,
            set = set,
            disabled = disabled,
        }
    end
    function ACH:Select(selectName, desc, order, values, _, width, get, set, disabled)
        return {
            type = "select",
            name = selectName,
            desc = desc,
            order = order,
            values = values,
            width = width,
            get = get,
            set = set,
            disabled = disabled,
        }
    end
    function ACH:Range(rangeName, desc, order, values, width, get, set, disabled)
        return {
            type = "range",
            name = rangeName,
            desc = desc,
            order = order,
            min = values.min,
            max = values.max,
            step = values.step,
            isPercent = values.isPercent,
            width = width,
            get = get,
            set = set,
            disabled = disabled,
        }
    end
    function ACH:Execute(execName, desc, order, func)
        return { type = "execute", name = execName, desc = desc, order = order, func = func }
    end
    function ACH:Description(descName, order)
        return { type = "description", name = descName, order = order }
    end
    function ACH:Header(headerName, order)
        return { type = "header", name = headerName, order = order }
    end
    ACH.FontValues = { NONE = "None", OUTLINE = "Outline", SHADOW = "Shadow", SHADOWOUTLINE = "Shadow Outline" }
    function ACH:SharedMediaFont(fontName, desc, order, width, get, set, disabled)
        return {
            type = "select",
            dialogControl = "LSM30_Font",
            name = fontName,
            desc = desc,
            order = order,
            width = width,
            get = get,
            set = set,
            disabled = disabled,
        }
    end
    function ACH:FontFlags(flagsName, desc, order, width, get, set, disabled)
        return {
            type = "select",
            values = ACH.FontValues,
            name = flagsName,
            desc = desc,
            order = order,
            width = width,
            get = get,
            set = set,
            disabled = disabled,
        }
    end
    -- SharedMedia: every font name is a file in its folder here.
    local LSM = {
        Fetch = function(_, _, fontName)
            return "Fonts\\SharedMedia\\" .. fontName .. ".ttf"
        end,
    }
    local libs = {
        ["AceLocale-3.0"] = {
            NewLocale = function(_, app, _, isDefault)
                if not isDefault then return nil end
                locales[app] = setmetatable({}, {
                    __newindex = function(t, k, v)
                        rawset(t, k, v == true and k or v)
                    end,
                })
                return locales[app]
            end,
            GetLocale = function(_, app)
                return locales[app]
            end,
        },
        ["AceAddon-3.0"] = {
            GetAddon = function(_, addonName, silent)
                assert(silent, "GetAddon without silent errors on a missing addon")
                return aceAddons[addonName]
            end,
        },
        ["LibElvUIPlugin-1.0"] = {
            RegisterPlugin = function(_, pluginName, callback)
                client.plugin = pluginName
                client.optionsCallback = callback
            end,
        },
    }
    function LibStub(libName)
        return assert(libs[libName], "no library " .. libName)
    end

    -- ElvUI: the engine, its profile defaults (P), private defaults (V) and media.
    local E = { mult = 0.71, frames = {}, texts = {}, Libs = { ACH = ACH, LSM = LSM } }
    local P, V = { general = { font = "PT Sans Narrow", fontStyle = "OUTLINE" } }, { general = {} }
    ---Toolkit.lua's FontTemplate, which ElvUI adds to every font string: a SharedMedia font name,
    ---a size and a style, "SHADOW..." being a shadow; the text kept for ElvUI's font updates.
    function fontMethods:FontTemplate(fontName, size, style)
        E.texts[self] = { fontName = fontName, fontSize = size, fontStyle = style }
        local shadow = style:sub(1, 6) == "SHADOW"
        local flags = shadow and style:sub(7) or style
        self:SetFont(LSM:Fetch("font", fontName), size, flags == "NONE" and "" or flags)
        self:SetShadowColor(0, 0, 0, shadow and 1 or 0)
        self:SetShadowOffset(shadow and 1 or 0, shadow and -1 or 0)
    end
    E.media = {
        backdropcolor = { r = 0.1, g = 0.1, b = 0.1 },
        backdropfadecolor = { r = 0.06, g = 0.06, b = 0.06, a = 0.8 },
        bordercolor = { r = 0, g = 0, b = 0 },
        rgbvaluecolor = { r = 0.09, g = 0.52, b = 0.82 },
        hexvaluecolor = "|cff1784d1",
        blankTex = "Interface\\ElvUI\\Blank",
        normTex = "Interface\\ElvUI\\Norm",
        normFont = "Fonts\\ElvUI\\Expressway.ttf",
    }
    ---ElvUI keeps registered status bars in its primary texture when that setting changes.
    E.statusbars = {}
    function E:RegisterStatusBar(bar)
        self.statusbars[bar] = true
    end
    E.Options = not opts.noOptions and { args = {} } or nil
    client.E = E

    ---Toolkit.lua's SetTemplate: ElvUI's blank backdrop (none for "NoBackdrop"), its colours (the
    ---faded one for "Transparent", the frame's customBackdropAlpha over the alpha), the border
    ---colour in any case, and the frame registered for ElvUI's colour updates unless told not to.
    function E:SetTemplate(frame, template, _, ignoreUpdates)
        frame.template = template or "Default"
        frame.ignoreUpdates = ignoreUpdates
        if not frame.SetBackdrop then client.Mixin(frame) end
        if template == "NoBackdrop" then
            frame:SetBackdrop(nil)
        else
            frame:SetBackdrop({ edgeFile = self.media.blankTex, bgFile = self.media.blankTex, edgeSize = 1 })
            local c = template == "Transparent" and self.media.backdropfadecolor or self.media.backdropcolor
            local a = frame.customBackdropAlpha or (template == "Transparent" and c.a) or 1
            frame:SetBackdropColor(c.r, c.g, c.b, a)
        end
        local b = self.media.bordercolor
        frame:SetBackdropBorderColor(b.r, b.g, b.b, 1)
        if not ignoreUpdates then self.frames[frame] = true end
    end
    function E:Delay(_, fn, ...)
        client.delays[#client.delays + 1] = { fn = fn, args = { ... } }
    end
    ---Runs the E:Delay calls made so far.
    function client:RunDelays()
        local delays = self.delays
        self.delays = {}
        for _, d in ipairs(delays) do
            d.fn(unpack(d.args))
        end
    end
    function E:StaticPopup_Show(which)
        client.popups[#client.popups + 1] = which
    end
    -- ElvUI's fades (Animation.lua): recorded, and the frame at its end alpha at once.
    client.fades = {}
    function E:UIFrameFadeIn(frame, time, from, to)
        client.fades[#client.fades + 1] = { "in", time, from, to }
        frame:SetAlpha(to)
    end
    function E:UIFrameFadeOut(frame, time, from, to)
        client.fades[#client.fades + 1] = { "out", time, from, to }
        frame:SetAlpha(to)
    end
    ---Where ElvUI reads its media again (after a colour or font option, a new profile).
    function E:UpdateMedia(_) end

    -- The Skins module: each Handle* marks what it was given.
    local S = { callbacks = {} }
    for _, fn in ipairs({ "Button", "CheckBox", "CloseButton", "EditBox", "SliderFrame", "DropDownBox", "ScrollBar" }) do
        S["Handle" .. fn] = function(_, frame)
            frame.handled = fn
        end
    end
    ---S:AddCallbackForAddon runs the function once ElvUI's skins are up and the addon is loaded.
    function S:AddCallbackForAddon(addonName, _, fn)
        self.callbacks[#self.callbacks + 1] = { addon = addonName, fn = fn }
    end
    -- The PluginInstaller: Queue shows the first queued install; the frame has its texts and buttons.
    local PI = { queue = {} }
    function PI:Queue(install)
        self.queue[#self.queue + 1] = install
    end
    function PI:CloseInstall()
        self.closed = true
    end
    local installFrame = Frame("Frame", "PluginInstallFrame", UIParent)
    for _, key in ipairs({ "SubTitle", "Desc1", "Desc2", "Desc3" }) do
        local text = Region("FontString")
        function text:SetText(value)
            self.text = value
        end
        installFrame[key] = text
    end
    for i = 1, 4 do
        local option = Frame("Button", nil, installFrame)
        option.shown = false
        function option:SetText(text)
            self.text = text
        end
        installFrame["Option" .. i] = option
    end
    local modules = { Skins = S, PluginInstaller = PI }
    function E:GetModule(moduleName)
        return modules[moduleName]
    end
    client.S, client.PI = S, PI

    function E:NewModule(moduleName)
        local module = { name = moduleName }
        function module:GetName()
            return self.name
        end
        function module:SecureHook(object, method, handler)
            hooksecurefunc(object, method, function(...)
                self[handler](self, ...)
            end)
        end
        client.modules[moduleName] = module
        return module
    end
    function E:RegisterModule(moduleName)
        client.registered = moduleName
    end

    ElvUI = { E, {}, V, P, {} }

    _G.RXPNavigator = nil
    if opts.rxp ~= false then aceAddons.RXPGuides = LoadRXPForClient(client, opts) end
    if opts.navigator ~= false and opts.rxp ~= false then client.navigator = LoadNavigatorForClient(client) end
    local function isLoaded(addonName)
        return (addonName == "RXPGuides" and opts.rxp ~= false)
            or (addonName == "Loreward" and opts.loreward ~= false)
            or (addonName == "RXP_Navigator" and client.navigator ~= nil)
            or (addonName == "Waymark" and opts.waymark ~= false)
    end
    C_AddOns = { IsAddOnLoaded = isLoaded }

    for _, file in ipairs(TOC_FILES) do
        assert(loadfile(file))(name, client.ns)
    end

    -- Login: ElvUI reads the profile and private settings, defaults included. Its own modules come
    -- first, Skins among them, which runs the addon callbacks of loaded addons; then the plugins'.
    E.db = copy(P)
    E.private = copy(V)
    E.private.install_complete = opts.elvuiInstalled ~= false and "16.01" or nil
    if opts.installed then E.private[name].installed = true end
    for k, v in pairs(opts.db or {}) do
        E.db[name][k] = v
    end
    -- The user's own general font and style in ElvUI's profile, over its defaults.
    E.db.general.font = opts.elvuiFont or E.db.general.font
    E.db.general.fontStyle = opts.elvuiFontStyle or E.db.general.fontStyle
    -- WindTools: its private skin settings, and its Skins module's CreateShadow (which checks
    -- its own shadow switch).
    _G.WindTools = nil
    if opts.windtools ~= nil then
        E.private.WT = { skins = { enable = opts.windtools, shadow = opts.windtoolsShadow ~= false } }
        local skins = {
            CreateShadow = function(_, frame)
                frame.shadow = Frame("Frame", nil, frame)
                frame.shadow.wind = true
            end,
        }
        _G.WindTools = { { Modules = { Skins = skins } } }
    end
    -- Eltruism: its profile's shadow settings and ShadowColor, which colours a shadow its way.
    _G.ElvUI_EltreumUI = nil
    if opts.eltruism ~= nil then
        E.db.ElvUI_EltreumUI = { skins = { shadow = { enable = opts.eltruism, length = 4 } } }
        _G.ElvUI_EltreumUI = {
            ShadowColor = function(_, shadow)
                shadow.colored = true
            end,
        }
    end
    for _, cb in ipairs(S.callbacks) do
        if isLoaded(cb.addon) then cb.fn() end
    end
    for _, module in pairs(client.modules) do
        module:Initialize()
    end

    ---Loads ElvUI_Options: LibElvUIPlugin runs the plugin's callback.
    function client:LoadOptions()
        self.optionsCallback()
        return E.Options.args[name]
    end
    ---Changes a setting as its option on the page does.
    function client:Set(key, value)
        local page = self:LoadOptions()
        page.set({ key }, value)
    end
    ---The plugin's settings in the profile.
    function client:Db()
        return E.db[name]
    end
    ---Runs the installer the plugin queued: every page in turn, returning the frame after each.
    function client:InstallPage(n)
        local install = PI.queue[#PI.queue]
        for i = 1, 4 do
            installFrame["Option" .. i].shown = false
            installFrame["Option" .. i].scripts.OnClick = nil
        end
        install.Pages[n]()
        return installFrame
    end
    ---A Loreward window as its files build one, on first use: a named BackdropTemplate frame in its
    ---parchment look, with a panel button, a template check box, its own check box (no template),
    ---an edit box and a scroll bar.
    ---@param windowName string
    ---@return table
    function client:LorewardWindow(windowName)
        local box = Frame("Frame", windowName, UIParent, "BackdropTemplate")
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border" })
        box:SetBackdropColor(0.95, 0.88, 0.7, 0.9)
        box:SetBackdropBorderColor(0.6, 0.45, 0.2, 1)
        box.button = Frame("Button", nil, box, "UIPanelButtonNoTooltipTemplate")
        box.check = Frame("CheckButton", nil, box, "UICheckButtonTemplate")
        box.ownCheck = Frame("CheckButton", nil, box)
        box.edit = Frame("EditBox", nil, box, "BackdropTemplate")
        box.edit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        box.bar = Frame("Slider", nil, box)
        function box.bar:GetThumbTexture()
            return {}
        end
        -- Text from the game's font object, on the window and in a row inside it.
        box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        box.row = Frame("Frame", nil, box)
        box.row.text = box.row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        return box
    end
    ---Waymark's As Told panel (AsToldPanel.lua's Build), made the first time it shows: its glass as
    ---textures on the panel itself, its words in a child frame over all of it with the gold mark
    ---behind a name under the pointer.
    ---@return table
    function client:WaymarkPanel()
        local panel = Frame("Frame", "WaymarkToldPanel", UIParent)
        panel.glass = { panel:CreateTexture(), panel:CreateTexture(), panel:CreateTexture() }
        panel.body = Frame("Frame", nil, panel)
        panel.body.mark = panel.body:CreateTexture()
        panel.body.line = panel.body:CreateFontString(nil, nil, "GameFontNormal")
        return panel
    end
    ---Loreward's progress strip (Progress.lua's makeFrame): its own backdrop, a status bar gold on a
    ---dark track, and a gold hairline above the lines below; each coloured once, when it is built.
    ---@return table
    function client:LorewardStrip()
        local f = Frame("Frame", "LorewardProgressStrip", UIParent, "BackdropTemplate")
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8" })
        local bar = Frame("StatusBar", nil, f)
        function bar:SetStatusBarTexture(file)
            self.texture = file
        end
        function bar:SetStatusBarColor(r, g, b, a)
            self.color = { r, g, b, a or 1 }
        end
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetStatusBarColor(0.82, 0.66, 0.32, 0.95)
        bar.track = bar:CreateTexture()
        bar.track:SetColorTexture(0.22, 0.17, 0.09, 0.9)
        f.bar = bar
        f.divider = f:CreateTexture()
        f.divider:SetColorTexture(0.6, 0.5, 0.3, 0.45)
        return f
    end
    ---A RestedXP Navigator window: a close button and a drop-down menu.
    ---@param windowName string
    ---@return table
    function client:NavigatorWindow(windowName)
        local f = Frame("Frame", windowName, UIParent, "BackdropTemplate")
        f.close = Frame("Button", nil, f, "UIPanelCloseButton")
        f.dropdown = Frame("Frame", nil, f, "UIDropDownMenuTemplate")
        return f
    end
    ---Clicks an option button of the installer page shown.
    function client:Click(i)
        installFrame["Option" .. i].scripts.OnClick(installFrame["Option" .. i])
    end

    return client
end

---RestedXP Guides as far as the plugin reaches into it: its themes, LoadActiveTheme and
---RenderFrame, the v2 theme conversion, and the v1 window whose frames set RestedXP's backdrops.
---@param client table
---@param opts TestClientOptions
---@return table
function LoadRXPForClient(client, opts)
    local Frame = client.Frame
    local rxp = { themes = {}, v2 = { themes = {} }, renders = 0 }
    rxp.settings = { profile = { activeTheme = opts.rxpTheme or "RXP Blue", enableV2Interface = opts.v2 } }
    local blue = {
        name = "RXP Blue",
        author = "RestedXP",
        background = { 0.05, 0.05, 0.1, 1 },
        bottomFrameBG = { 0.07, 0.07, 0.15, 1 },
        bottomFrameHighlight = { 0.2, 0.24, 0.42, 1 },
        texturePath = "Interface/AddOns/RXPGuides/Textures/",
        headerTexture = "rxp-banner",
        textColor = { 1, 1, 1 },
        font = "Fonts\\FRIZQT__.TTF",
        edges = { edge = "Interface/AddOns/RXPGuides/Textures/rxp-borders" },
    }
    rxp.themes["RXP Blue"] = blue
    rxp.v2.themes["RXP Blue V2"] = {
        name = "RXP Blue",
        borderColors = { common = { 0.2, 0.2, 0.4, 1 }, commonEdge = { 0.7, 0.7, 0.8, 1 } },
        edge = { edgeFile = "Interface/AddOns/RXPGuides/Textures/v2/rxp-borders-v2", edgeSize = 1 },
    }
    function rxp.v2:IsGuideWindowEnabled()
        return rxp.settings.profile.enableV2Interface
    end
    ---Themes.lua: missing fields from RXP Blue, then the v2 copies when v2 is on.
    function rxp:RegisterTheme(theme)
        for k, v in pairs(blue) do
            if theme[k] == nil then theme[k] = v end
        end
        self.themes[theme.name] = theme
        if self.v2:IsGuideWindowEnabled() then self.v2:ConvertThemes() end
    end
    ---ConvertThemes: a v2 copy of each v1 theme, its edge file from the theme's bgTextures and every
    ---border in its highlight colour.
    function rxp.v2:ConvertThemes()
        for themeName, source in pairs(rxp.themes) do
            if themeName ~= "RXP Blue" then
                local edge = CopyTable(source.bottomFrameHighlight)
                self.themes[themeName] = {
                    name = themeName,
                    borderColors = { common = edge, commonEdge = edge },
                    edge = {
                        edgeFile = source.bgTextures and source.bgTextures.edge or "Interface/BUTTONS/WHITE8X8",
                        edgeSize = 1,
                    },
                }
            end
        end
    end
    function rxp:LoadActiveTheme()
        self.activeTheme = self.themes[self.settings.profile.activeTheme] or blue
        self.colors = self.activeTheme
        self.font = self.activeTheme.font
        return self.activeTheme
    end

    -- The v1 window: its frames take RestedXP's backdrops and theme colours on every render.
    local RXPFrame = Frame("Frame", "RXPFrame", UIParent, "BackdropTemplate")
    RXPFrame.BottomFrame = Frame("Frame", "RXPFrame_bottomFrame", RXPFrame, "BackdropTemplate")
    RXPFrame.GuideName = Frame("Frame", "RXPFrameGuideName", RXPFrame, "BackdropTemplate")
    RXPFrame.Footer = Frame("Frame", "RXPFrameFooter", RXPFrame, "BackdropTemplate")
    RXPFrame.GuideName.bg = RXPFrame.GuideName:CreateTexture()
    RXPFrame.Footer.bg = RXPFrame.Footer:CreateTexture()
    -- The logo on the guide name with the theme's class icon over it, and the settings cog button.
    RXPFrame.GuideName.icon = RXPFrame.GuideName:CreateTexture()
    RXPFrame.GuideName.classIcon = RXPFrame.GuideName:CreateTexture()
    local cog = Frame("Button", "RXPFrameCogwheel", RXPFrame)
    local cogTexture = cog:CreateTexture()
    function cog:SetNormalTexture(file)
        cogTexture:SetTexture(file)
        cogTexture.desaturated, cogTexture.color = nil, { 1, 1, 1, 1 }
    end
    function cog:GetNormalTexture()
        return cogTexture
    end
    RXPFrame.Footer.cog = cog
    RXPFrame.CurrentStepFrame = Frame("Frame", nil, RXPFrame)
    RXPFrame.CurrentStepFrame.framePool = {}
    RXPFrame.ScrollChild = Frame("Frame", "RXPFrame_steps", RXPFrame.BottomFrame)
    RXPFrame.ScrollChild.framePool = {}
    -- The step list's scroll frame (UIPanelScrollFrameTemplate); UpdateScrollBar puts the theme's
    -- art on its bar, called through the table on every render.
    RXPFrame.ScrollFrame = Frame("ScrollFrame", "RXPFrameScrollFrame", RXPFrame.BottomFrame)
    RXPFrame.ScrollFrame.ScrollBar = Frame("Slider", nil, RXPFrame.ScrollFrame)
    RXPFrame.ScrollFrame.ScrollBar.themed = 0
    function RXPFrame.UpdateScrollBar()
        local bar = RXPFrame.ScrollFrame.ScrollBar
        bar.themed = bar.themed + 1
    end
    rxp.RXPFrame = RXPFrame
    local edge = { bgFile = "Interface/BUTTONS/WHITE8X8", edgeFile = "rxp-borders", edgeSize = 8 }
    function RXPFrame:UpdateVisuals()
        for _, key in ipairs({ "BottomFrame", "GuideName", "Footer" }) do
            local f = self[key]
            f:ClearBackdrop()
            f:SetBackdrop(edge)
            f:SetBackdropColor(unpack(rxp.colors.background))
        end
        self.GuideName.bg:SetTexture(rxp.activeTheme.texturePath .. "rxp-banner")
        self.Footer.bg:SetTexture(rxp.activeTheme.texturePath .. "rxp-banner")
        self.GuideName.icon:SetTexture(rxp.activeTheme.texturePath .. "rxp_logo-64")
        self.GuideName.classIcon:SetTexture(rxp.activeTheme.texturePath .. "WARRIOR")
        self.Footer.cog:SetNormalTexture(rxp.activeTheme.texturePath .. "rxp_cog-32")
        RXPFrame.UpdateScrollBar()
    end
    ---Targeting.lua's CreateTargetFrame: the Active Targets frame and its title tab, built on first
    ---use, each with RestedXP's border and the theme's background.
    function client:RXPTargetFrame()
        local f = Frame("Frame", "RXPTargetFrame", UIParent, "BackdropTemplate")
        f.title = Frame("Frame", "RXPTargetFrame_title", f, "BackdropTemplate")
        for _, part in ipairs({ f, f.title }) do
            part:SetBackdrop(edge)
            part:SetBackdropColor(unpack(rxp.colors.background))
        end
        return f
    end
    function rxp.RenderFrame()
        rxp:LoadActiveTheme()
        rxp.renders = rxp.renders + 1
        RXPFrame:UpdateVisuals()
    end
    ---SetStep: the active steps, pooled frames with a number box, backdrops set when the theme changed.
    function rxp.SetStep(n)
        local pool = RXPFrame.CurrentStepFrame.framePool
        for i = 1, n do
            local step = pool[i]
            if not step then
                step = Frame("Frame", nil, RXPFrame.CurrentStepFrame, "BackdropTemplate")
                step.number = Frame("Frame", nil, step, "BackdropTemplate")
                step.text = step:CreateFontString()
                pool[i] = step
            end
            -- Each step's text in the theme's font, at the guide's font size.
            step.text:SetFont(rxp.font, 12, "")
            if step.theme ~= rxp.activeTheme then
                step.theme = rxp.activeTheme
                step:SetBackdrop(edge)
                step:SetBackdropColor(unpack(rxp.colors.background))
                step.number:SetBackdrop(edge)
            end
        end
    end
    ---LoadGuide: a frame per step in the list below the active steps.
    function rxp:LoadGuide(steps)
        local pool = RXPFrame.ScrollChild.framePool
        for i = 1, steps do
            pool[i] = pool[i] or Frame("Frame", nil, RXPFrame.ScrollChild, "BackdropTemplate")
            pool[i]:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8" })
            pool[i]:SetBackdropColor(unpack(rxp.colors.bottomFrameBG))
        end
    end

    -- RestedXP's OnInitialize, before any plugin: the saved theme (ours unknown yet), the window.
    rxp:LoadActiveTheme()
    rxp.RenderFrame()
    client.rxp = rxp
    return rxp
end

---RestedXP Navigator: its UI helper with the colour table its panels are made from.
---@param client table
---@return table
function LoadNavigatorForClient(client)
    local Frame = client.Frame
    local navigator = Frame("Frame")
    navigator.UI = {
        colors = {
            background = { 0.035, 0.043, 0.057, 0.99 },
            card = { 0.065, 0.079, 0.101, 0.98 },
            border = { 0.14, 0.19, 0.24, 1 },
            accent = { 0.12, 0.72, 1, 1 },
            muted = { 0.62, 0.69, 0.77, 1 },
        },
    }
    _G.RXPNavigator = navigator
    return navigator
end
