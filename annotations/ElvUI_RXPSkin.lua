---@meta
-- Editor-only types: the parts of ElvUI, RestedXP Guides, RestedXP Navigator and Eltruism the plugin
-- touches, as their own code defines them (ElvUI's General\Core.lua, Toolkit.lua, Skins.lua and
-- PluginInstaller.lua; RestedXP's Themes.lua and GuideWindow.lua; Navigator's UI\Theme.lua), and
-- the plugin's own tables. Not in the .toc, not in releases.

---ElvUI's global: { E, L, V, P, G }; the plugin uses the engine, private and profile defaults.
---@class ElvUIGlobal
---@field [1] ElvUIEngine
---@field [3] table<string, table> private defaults (V)
---@field [4] {general: {font: string, fontStyle: string}, [string]: table} profile defaults (P)

---@type ElvUIGlobal
ElvUI = nil

---An ElvUI colour: a table with r, g, b and sometimes a.
---@class ElvUIColor
---@field r number
---@field g number
---@field b number
---@field a? number

---@class ElvUIMedia
---@field backdropcolor ElvUIColor
---@field backdropfadecolor ElvUIColor
---@field bordercolor ElvUIColor
---@field rgbvaluecolor ElvUIColor
---@field hexvaluecolor string the value colour as "|cffrrggbb"
---@field blankTex string
---@field normTex string ElvUI's primary status bar texture
---@field normFont string the file of ElvUI's general font

---@class ElvUIEngine
---@field media ElvUIMedia
---@field mult number one screen pixel in UI units
---@field db table<string, any>|{general: {font: string, fontStyle: string}} the profile; the plugin's settings under its folder name
---@field public private table<string, any> the private settings; install_complete once ElvUI's installer ran
---@field Libs {ACH: LibAceConfigHelper, LSM: LibSharedMedia}
---@field Options {args: table<string, table>}
---@field NewModule fun(self: ElvUIEngine, name: string, ...: string): ElvUIRXPSkinModule
---@field RegisterModule fun(self: ElvUIEngine, name: string)
---@field GetModule fun(self: ElvUIEngine, name: string): any
---@field UpdateMedia fun(self: ElvUIEngine, mediaType: string?)
---@field Delay fun(self: ElvUIEngine, delay: number, fn: function, ...: any)
---@field StaticPopup_Show fun(self: ElvUIEngine, which: string)
---@field RegisterStatusBar fun(self: ElvUIEngine, bar: table) kept in ElvUI's primary texture
---@field UIFrameFadeIn fun(self: ElvUIEngine, frame: table, time: number, from: number, to: number)
---@field UIFrameFadeOut fun(self: ElvUIEngine, frame: table, time: number, from: number, to: number)

---The plugin's module: an ElvUI module with AceHook mixed in.
---@class ElvUIRXPSkinModule
---@field GetName fun(self: ElvUIRXPSkinModule): string
---@field SecureHook fun(self: ElvUIRXPSkinModule, object: table, method: string, handler: string)

---@class LibElvUIPlugin
---@field RegisterPlugin fun(self: LibElvUIPlugin, name: string, callback: fun())

---ElvUI's LibAceConfigHelper: AceConfig tables in one call each.
---@class LibAceConfigHelper
---@field Group fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, childGroups: string?, get: function?, set: function?): {args: table<string, table>}
---@field Toggle fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, tristate: boolean?, confirm: boolean?, width: string?, get: function?, set: function?, disabled: function?): table
---@field Execute fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, func: function): table
---@field Select fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, values: table<string, string>, confirm: boolean?, width: string?, get: function?, set: function?, disabled: function?): table
---@field Range fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, values: {min: number, max: number, step: number, isPercent: boolean?}, width: string?, get: function?, set: function?, disabled: function?): table
---@field Description fun(self: LibAceConfigHelper, name: string, order: number): table
---@field FontValues table<string, string> ElvUI's font styles by key, "SHADOW..." ones included
---@field SharedMediaFont fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, width: string?, get: function?, set: function?, disabled: function?): table
---@field FontFlags fun(self: LibAceConfigHelper, name: string, desc: string?, order: number, width: string?, get: function?, set: function?, disabled: function?): {values: table<string, string>}

---ElvUI's Toolkit adds these to every frame.
---@class Frame
---@field SetTemplate fun(self: Frame, template: string?, glossTex: string|boolean?, ignoreUpdates: boolean?)
---@field CreateShadow fun(self: Frame, size: number?)
---@field shadow? Frame the shadow CreateShadow made

---The plugin's settings in ElvUI's profile.
---@class ElvUIRXPSkinSettings
---@field restedxp boolean skin RestedXP Guides and offer the ElvUI theme
---@field loreward boolean skin Loreward's windows
---@field navigator boolean skin RestedXP Navigator's windows
---@field waymark boolean skin Waymark's As Told panel
---@field hideArt boolean ElvUI's look for RestedXP's art: no banners, the class icon, a tinted cog
---@field scrollHover boolean RestedXP's scroll bar only while the pointer is over the guide window
---@field markSteps boolean the current step marked and finished steps dimmed in RestedXP's list
---@field nameColors boolean a step's mobs, NPCs and items coloured in its text
---@field shadow boolean Eltruism's or WindTools' shadow round the skinned windows
---@field style string one of Skin.styles: "elvui", "translucent" or "transparent"
---@field alpha number the translucent style's backdrop alpha, 0 to 1
---@field fonts boolean the chosen font on the skinned windows' text
---@field fontFromElvUI boolean ElvUI's general font and style instead of the three below
---@field font string SharedMedia name of that font
---@field fontStyle string an outline from ElvUI's font styles, not a "SHADOW..." one
---@field fontShadow boolean a drop shadow behind the text

---An addon the plugin skins: a module in ns.addons.
---@class ElvUIRXPSkinAddon
---@field ADDON string the addon's folder name
---@field key string its switch in the settings
---@field present? boolean the addon is loaded
---@field applied? boolean Load ran
---@field Load fun(self: ElvUIRXPSkinAddon) the first skinning, once the addon is loaded and switched on
---@field Update fun(self: ElvUIRXPSkinAddon) again after a setting or ElvUI's media changed
---@field UseTheme? fun() its installer step, when "skin it" does more than the switch

---A RestedXP theme (Themes.lua): colours as { r, g, b, a }, missing fields from RXP Blue's.
---@class RXPGuidesTheme
---@field name string
---@field displayName string
---@field author string
---@field applicable boolean
---@field background number[]
---@field bottomFrameBG number[]
---@field bottomFrameHighlight number[]
---@field mapPins number[]
---@field tooltip? string
---@field font? string
---@field bgTextures {edge: string?, bottom: string?}

---A theme's v2 copy, made by ConvertThemes.
---@class RXPGuidesThemeV2
---@field borderColors table<string, number[]>
---@field edge {edgeFile: string, edgeSize: number}

---A step of a RestedXP guide, the parts the plugin reads.
---@class RXPGuidesStep
---@field index number its place in the guide
---@field active? boolean one of the steps you are on
---@field completed? boolean done
---@field elements? table[] its lines (.mob, .collect, the text and so on)

---A row of RestedXP's step list (GuideWindow.lua's LoadGuide): its step and its number box.
---@class RXPGuidesListRow : Frame
---@field step? RXPGuidesStep
---@field number? {text: FontString}

---A step frame of RestedXP's v1 window, with its number box.
---@class RXPGuidesStepFrame : Frame
---@field number Frame

---RestedXP's v1 guide window (GuideWindow.lua).
---@class RXPGuidesFrame : Frame
---@field BottomFrame Frame|{UpdateFrame: fun(self: table?, stepn: number?)} the step list's frame
---@field GuideName Frame|{bg: Texture, icon: Texture, classIcon: Texture} its banner, logo and class icon
---@field Footer Frame|{bg: Texture, cog: Button} its banner and the settings cog
---@field CurrentStepFrame {framePool: RXPGuidesStepFrame[]}
---@field ScrollChild {framePool: RXPGuidesListRow[]}
---@field ScrollFrame {ScrollBar: Slider} the step list's UIPanelScrollFrameTemplate
---@field UpdateVisuals fun(self: RXPGuidesFrame)
---@field UpdateScrollBar fun() puts the theme's art on the scroll bar

---RestedXP Guides' AceAddon object, the parts the plugin touches.
---@class RXPGuidesAddon
---@field settings {profile: {activeTheme: string}, ReplaceColors: fun(element: any): string?}
---@field guideTextColors table<string, string> the colours of its text tags, AARRGGBB by tag
---@field Call fun(label: string?, func: function, ...: any): ...
---@field themes table<string, RXPGuidesTheme> the v1 themes by name
---@field activeTheme? {textColor: number[]} the theme drawn with now
---@field GetGuideProgress fun(): number? the step the guide stands at; nil without a guide
---@field v2 {themes: table<string, RXPGuidesThemeV2>, IsGuideWindowEnabled: fun(self: table): boolean, ConvertThemes: fun(self: table)}
---@field RXPFrame RXPGuidesFrame
---@field RegisterTheme fun(self: RXPGuidesAddon, theme: RXPGuidesTheme)
---@field RenderFrame fun(themeUpdate: boolean?)
---@field SetStep fun(n: number)
---@field LoadGuide fun(self: RXPGuidesAddon, ...: any)

---RestedXP Navigator's global, the colour table its UI helper builds panels from.
---@class RXPNavigatorGlobal
---@field UI? {colors: table<string, number[]>}

---@type RXPNavigatorGlobal?
RXPNavigator = nil

---ElvUI's Skins module (Modules\Skins\Skins.lua), the functions the plugin calls.
---@class ElvUISkins
---@field HandleButton fun(self: ElvUISkins, button: table)
---@field HandleCloseButton fun(self: ElvUISkins, button: table)
---@field HandleCheckBox fun(self: ElvUISkins, checkbox: table)
---@field HandleSliderFrame fun(self: ElvUISkins, slider: table)
---@field HandleDropDownBox fun(self: ElvUISkins, dropdown: table)
---@field HandleScrollBar fun(self: ElvUISkins, scrollBar: table)
---@field AddCallbackForAddon fun(self: ElvUISkins, addonName: string, name: string, func: fun())

---ElvUI's PluginInstaller (General\PluginInstaller.lua).
---@class ElvUIPluginInstaller
---@field Queue fun(self: ElvUIPluginInstaller, install: {Title: string, Name: string, Pages: function[], StepTitles: string[]})
---@field CloseInstall fun(self: ElvUIPluginInstaller)

---Eltruism's addon object: ShadowColor colours a shadow CreateShadow made.
---@class EltruismAddon
---@field ShadowColor fun(self: EltruismAddon, shadow: Frame?)

---@type EltruismAddon?
ElvUI_EltreumUI = nil

---Eltruism's shadow settings in ElvUI's profile (E.db.ElvUI_EltreumUI.skins.shadow).
---@class EltruismShadowSettings
---@field enable boolean
---@field length number

---WindTools' skin settings in ElvUI's private settings (E.private.WT.skins).
---@class WindToolsSkinSettings
---@field enable boolean
---@field shadow boolean

---WindTools' global: its namespace, [1] the addon with its modules.
---@class WindToolsGlobal
---@field [1] {Modules: {Skins: {CreateShadow: fun(self: table, frame: table)}}}

---@type WindToolsGlobal?
WindTools = nil

---Install.lua.
---@class ElvUIRXPSkinInstall
---@field Done fun(): boolean
---@field Finish fun()
---@field Queue fun(again: boolean?)

---Fonts.lua.
---@class ElvUIRXPSkinFonts
---@field Style fun(db: ElvUIRXPSkinSettings): string the style FontTemplate takes
---@field Current fun(): string, string the font name and style in use
---@field Sweep fun(frame: table)
---@field Watch fun(frame: table)
---@field Update fun()

---SharedMedia, as ElvUI keeps it in E.Libs.
---@class LibSharedMedia
---@field Fetch fun(self: LibSharedMedia, mediaType: string, name: string): string

---ElvUI's Toolkit adds this to textures: anchored inside its parent by ElvUI's border.
---@class Texture
---@field SetInside fun(self: Texture, anchor: table?, x: number?, y: number?)

---ElvUI adds this to every font string: a SharedMedia font name, a size, and a style where
---"SHADOW..." is a shadow.
---@class FontString
---@field FontTemplate fun(self: FontString, fontName: string, size: number?, style: string?)

---Skin.lua.
---@class ElvUIRXPSkinSkin
---@field Backdrop fun(frame: table, template: string, force: boolean?, inner: boolean?, hud: boolean?)
---@field styles {elvui: string, translucent: string, transparent: string} the looks the plugin offers
---@field Alpha fun(): number? the current style's backdrop alpha, nil in ElvUI's own
---@field Transparent fun(): boolean the transparent style is on
---@field Refresh fun()
---@field Widgets fun(frame: table)
---@field Shadow fun(frame: table, hud: boolean?)
---@field shadows {eltruism: string, windtools: string} the shadow variants
---@field ShadowVariant fun(): string?
---@field ShadowAddonLoaded fun(): boolean
---@field Window fun(frame: table, template: string?, hud: boolean?)
---@field Watch fun(names: string[], fn: fun(frame: table))

---ElvUI's PluginInstaller frame: a title, three lines of text and four option buttons.
---@class ElvUIPluginInstallFrame : Frame
---@field SubTitle FontString
---@field Desc1 FontString
---@field Desc2 FontString
---@field Desc3 FontString
---@field Option1 Button
---@field Option2 Button
---@field Option3 Button
---@field Option4 Button

---@type ElvUIPluginInstallFrame
PluginInstallFrame = nil

---The addon's namespace.
---@class ElvUIRXPSkinNamespace
---@field NAME string the folder name
---@field addons ElvUIRXPSkinAddon[]
---@field SWITCHES string[]
---@field db fun(): ElvUIRXPSkinSettings
---@field Update fun()
---@field AddAddon fun(module: ElvUIRXPSkinAddon)
---@field InsertOptions fun()
---@field Skin ElvUIRXPSkinSkin
---@field Install ElvUIRXPSkinInstall
---@field Fonts ElvUIRXPSkinFonts
---@field Names {Hook: fun(addon: RXPGuidesAddon)} Names.lua
---@field outlines fun(): table<string, string> ElvUI's font styles less the "SHADOW..." ones
---@field RestedXP ElvUIRXPSkinRestedXP
---@field Loreward ElvUIRXPSkinLoreward|{HUD: table<string, boolean>}
---@field Navigator ElvUIRXPSkinNavigator
---@field Waymark ElvUIRXPSkinWaymark
