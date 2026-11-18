# ElvUI RXP Skin

An ElvUI plugin that gives **RestedXP Guides**, **Loreward**, **RestedXP Navigator** and Waymark's
As Told panel ElvUI's look, for WoW: Forever.

- **RestedXP Guides**: the guide window, its steps, step list, scroll bar and the Active Targets
  frame in ElvUI's style, and an "ElvUI" theme in RestedXP's own theme list, in ElvUI's colours and
  font. RestedXP's art in ElvUI's look: no banners, your class icon in an ElvUI frame in place of
  its logo, the settings cog in ElvUI's value colour. The scroll bar shows only while the pointer is
  over the guide window, as the Carrot tracker does it.
- **Loreward**: its windows and cards in ElvUI's colours and borders instead of parchment, its
  buttons, check boxes, edit boxes and scroll bars in ElvUI's style; the progress strip's bar like
  ElvUI's data bars.
- **RestedXP Navigator**: its panels in ElvUI's colours, its close buttons and drop-downs in
  ElvUI's style.
- **Waymark**: its As Told panel on ElvUI's backdrop instead of its own dark glass.
- **Shadows**: with Eltruism or WindTools loaded and that addon's own shadow option on, the skinned
  windows get its shadow.
- **Fonts**: on the text in the skinned windows, at the sizes the addons give it, ElvUI's general
  font and style, followed when you change them in ElvUI; or a SharedMedia font, outline and
  shadow of your own. RestedXP's ElvUI theme takes it too. ElvUI's Font Slug switch (sharper text)
  applies, as the font goes through ElvUI's `FontTemplate`.
- **Three styles**: ElvUI's own; translucent: see-through windows at an alpha of your choice, and
  no backdrop or border on the parts inside them (step numbers, list rows, title tabs, edit boxes);
  transparent: no backdrop, border or shadow anywhere, only the text, like Eltruism's transparent
  chat.

Every addon except ElvUI is optional; a skin only runs for an addon that is loaded.

## Use

The first time, ElvUI's plugin installer asks per loaded addon whether to skin it, and whether
RestedXP should use the ElvUI theme. Everything can be changed later under `/ec` > **RXP Skin**,
where the installer can also be run again. Switching a skin off takes effect after a reload.

## For other plugins

An ElvUI edit's own installer can set this plugin up and skip its installer, through the global
named after the folder (`ElvUI_RXPSkin`):

```lua
local skin = _G.ElvUI_RXPSkin
if skin and not skin:IsInstalled() then
    skin:Configure({
        restedxp = true, loreward = true, navigator = true, waymark = true,
        hideArt = true, shadow = true,
        style = "translucent", alpha = 0.5, -- or style = "elvui" / "transparent"
        scrollHover = true,
        fonts = true, fontFromElvUI = false, font = "Expressway", fontStyle = "OUTLINE", fontShadow = false,
        rxpTheme = true, -- put RestedXP Guides on the ElvUI theme
    })
end
```

`Configure` takes booleans by the option keys, `style`, `alpha` (0 to 1), `font` (a SharedMedia
name) and `fontStyle` (one of ElvUI's outlines, not a "SHADOW..." style), and ignores the rest or a
value out of range; calling it counts as the installer having run. `ShowInstaller()` queues the installer again.

## How it works

- **RestedXP** (`RestedXP.lua`): RestedXP draws from a theme table picked by name in its profile.
  The plugin registers a theme named "ElvUI" with `RegisterTheme`, its colour tables filled from
  `E.media` and refilled in place when ElvUI's media change; RestedXP's v2 copy gets ElvUI's border
  colour and a one-pixel edge. RestedXP falls back to its default for a theme it does not know, so
  the saved name is harmless with the plugin off.
- **Backdrops** (`Skin.lua`): the addons set their own backdrops again on every redraw. A skinned
  frame keeps a hook on `SetBackdrop` that puts ElvUI's template back. RestedXP's frames keep their
  own background colour, which marks step states; Loreward's get ElvUI's colours forced.
- **Translucent**: a skinned frame is a window or "inner" (nested in one). In the translucent
  style windows get the plugin's alpha through ElvUI's `customBackdropAlpha`, inner parts the
  `NoBackdrop` template; in the transparent style every skinned frame gets `NoBackdrop` and the
  shadows are hidden. Switching style re-applies every skinned frame without a reload.
- **Fonts** (`Fonts.lua`): Loreward, Navigator and Waymark use the game's font objects, which the
  whole UI shares, so the font strings inside the skinned windows are taken one by one instead:
  swept when a window is skinned, shown again or resized, and after RestedXP's renders. A hook on
  the shared font string methods `SetFont` and `SetFontObject` puts the chosen font back, through
  ElvUI's `FontTemplate`, on a taken font string whenever its addon sets a font again; the size
  stays the addon's. Text anywhere else is left alone. Switching the fonts off takes a reload.
- **Scroll bar**: RestedXP's `RXPFrame.UpdateScrollBar` only puts its theme's art on the step
  list's bar, on every render; after ElvUI's `HandleScrollBar` it is replaced by an empty function.
  On hover: a frame inside the guide window looks ten times a second (its OnUpdate runs only while
  the window shows) whether the pointer is over it, and fades the bar in (0.15 s) or out (0.4 s)
  with ElvUI's `UIFrameFadeIn`/`UIFrameFadeOut`, the timings of Carrot's own.
- **Art**: RestedXP sets its banners, logo and cog texture again on each render; after its
  `UpdateVisuals` the plugin hides the banners and logo, shows the class icon (the game's
  `Icons-Classes` sheet at the player's `CLASS_ICON_TCOORDS`, its rim cropped) in an ElvUI frame,
  and tints the cog's normal texture.
- **Guide window shadow**: `RXPFrame` is 3 pixels wider than the list and footer it shows, so the
  shadow goes round a frame spanning just those two.
- **Waymark** (`Waymark.lua`): the As Told panel draws its glass as textures on the panel itself,
  made once; they are hidden and ElvUI's backdrop goes on a frame of the panel's level, under the
  words' frame and just their width (the panel is 18 pixels wider, where the glass faded out).
- **Loreward and Navigator** have no API for this. Their windows are named frames built on first
  use; a ticker looks for them twice a second and stops once all are found. Widgets are recognised
  by what their Blizzard template leaves on them (`Left`/`Middle`/`Right`, `Text`, the close
  button's atlas) and each is skinned once, also those added later (on the window's `OnShow`).
- **Shadows**: `Skin.ShadowVariant()` says which edit's shadow is in use: Eltruism's
  (`E.db.ElvUI_EltreumUI.skins.shadow.enable`) first, else WindTools' (`E.private.WT.skins.enable`
  and `.shadow`). The windows that take one are remembered, so the plugin's switch shows, hides or
  first makes their shadows without a reload.
- ElvUI's Skins calls each addon's skin through `S:AddCallbackForAddon`, registered as the files
  load: Skins starts before any plugin's module.

## Development

```
.lua\bin\lua.exe tests\check.lua          lint, tests, coverage
.lua\bin\lua.exe tests\check.lua test     tests only (--filter=x for a part)
.lua\bin\lua.exe tests\check.lua format   StyLua
```

`tests\setup-lua.ps1` builds `.lua\` (needs the Visual Studio C++ tools). The busted specs run on a
simulated client (`tests\wow.lua`); `InGame\Tests.lua` checks that client's assumptions in the real
game through WoWUnit (debug builds only), and `tests\ingame_spec.lua` runs those same tests on the
simulated client.
