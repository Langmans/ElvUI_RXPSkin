-- The first-run installer, in ElvUI's PluginInstaller: a welcome page, a page per loaded addon
-- with "skin it" or "leave it", and an end page. It is done when its end page or its skip button
-- is clicked, or when another plugin configured this one (the API); until then it comes back at
-- each login. It waits for ElvUI's own installer.

local NAME, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local L = LibStub("AceLocale-3.0"):GetLocale(NAME)
local PI = E:GetModule("PluginInstaller") ---@type ElvUIPluginInstaller

local Install = {}
ns.Install = Install

---@return boolean
function Install.Done()
    return E.private[NAME].installed == true
end

---Marks the installer as run.
function Install.Finish()
    E.private[NAME].installed = true
end

---Clears the installer frame's texts and buttons, then sets the page's title and text.
---@param title string
---@param desc string
---@param desc2 string?
---@return table frame PluginInstallFrame
local function page(title, desc, desc2)
    local f = _G.PluginInstallFrame
    f.SubTitle:SetText(title)
    f.Desc1:SetText(desc)
    f.Desc2:SetText(desc2 or "")
    f.Desc3:SetText("")
    return f
end

---Shows an option button with its text and what a click does.
---@param button table
---@param text string
---@param onClick function
local function option(button, text, onClick)
    button:Show()
    button:SetText(text)
    button:SetScript("OnClick", onClick)
end

---The page for one addon: its switch on (plus the addon's own install step) or off.
---@param module ElvUIRXPSkinAddon
---@return function
local function addonPage(module)
    local key = module.key
    return function()
        local f = page(L[key .. "_TITLE"], L[key .. "_DESC"])
        -- rawget: AceLocale answers a missing key with the key itself.
        option(f.Option1, rawget(L, key .. "_YES") or L.YES, function()
            ns.db()[key] = true
            ns.Update()
            if module.UseTheme then module.UseTheme() end
        end)
        option(f.Option2, rawget(L, key .. "_NO") or L.NO, function()
            ns.db()[key] = false
        end)
    end
end

local function welcome()
    local f = page(L.WELCOME, L.WELCOME_DESC, L.WELCOME_SKIP)
    option(f.Option1, L.SKIP, function()
        Install.Finish()
        PI:CloseInstall()
    end)
end

local function finished()
    local f = page(L.FINISHED, L.FINISHED_DESC)
    option(f.Option1, L.FINISH, function()
        Install.Finish()
        ReloadUI()
    end)
end

---Queues the installer with a page per loaded addon. Without `again`, only when it never ran
---and ElvUI's own installer is done.
---@param again boolean?
function Install.Queue(again)
    if not again and (Install.Done() or not E.private.install_complete) then return end
    local pages, titles = { welcome }, { L.WELCOME }
    for _, module in ipairs(ns.addons) do
        if C_AddOns.IsAddOnLoaded(module.ADDON) then
            pages[#pages + 1] = addonPage(module)
            titles[#titles + 1] = L[module.key .. "_TITLE"]
        end
    end
    pages[#pages + 1] = finished
    titles[#titles + 1] = L.FINISHED
    PI:Queue({ Title = L.INSTALL_TITLE, Name = NAME, Pages = pages, StepTitles = titles })
end
