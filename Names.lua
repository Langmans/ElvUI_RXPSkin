-- Names in RestedXP guide text. RestedXP's own guides tag names (|cRXP_ENEMY_Raptor|r), which it
-- colours from its text colour settings; Loreward's guides hardly do, while each step's .mob,
-- .target and .collect lines name them. This colours those names in the step's text, in RestedXP's
-- own colours: mobs as enemies, targets as friendly, collected items as loot. A plural comes
-- along ("Dalaran Watchers"), a longer name goes before a shorter one inside it, and a name that
-- already has a colour (the guide's own tag, or this) is left alone.
-- Static text is coloured after RestedXP's ReplaceColors, which builds it from its original each
-- time; the objective lines ("0/8 Dalaran Watcher slain") after each element update (addon.Call).

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace

local Names = {}
ns.Names = Names

-- Which tag colours a name, by the element field that lists it.
local LISTS = { mobs = "RXP_ENEMY_", unitscan = "RXP_ENEMY_", targets = "RXP_FRIENDLY_" }
local LOOT = "RXP_LOOT_"
-- The text fields of an element that can hold names.
local FIELDS = { "text", "rawtext", "tooltipText" }

local rxp ---@type RXPGuidesAddon

-- Each step's names, longest first, with the tag of each: worked out once per step. Weak keys.
---@type table<table, {order: string[], tags: table<string, string>, patterns: table<string, string>}>
local byStep = setmetatable({}, { __mode = "k" })

---@param a string
---@param b string
---@return boolean
local function longer(a, b)
    return #a > #b
end

---@param names {order: string[], tags: table<string, string>, patterns: table<string, string>}
---@param name string|number|nil
---@param tag string
local function add(names, name, tag)
    if type(name) ~= "string" then return end
    local text = name --[[@as string]]
    -- A name, not an NPC id still waiting for its name.
    if not text:find("%a") or names.tags[text] then return end
    names.tags[text] = tag
    names.order[#names.order + 1] = text
    -- Where it starts, and the name with a plural or possessive after it.
    names.patterns[text] = "()(" .. text:gsub("%p", "%%%0") .. "[%w']*)"
end

---The names a step's lines give, longest first.
---@param step table
---@return {order: string[], tags: table<string, string>, patterns: table<string, string>}
local function namesOf(step)
    local names = byStep[step]
    if names then return names end
    names = { order = {}, tags = {}, patterns = {} }
    ---@type table<string, (string|number)[]|string|nil>[]
    local elements = step.elements or {}
    for _, element in ipairs(elements) do
        for field, tag in pairs(LISTS) do
            local list = element[field]
            if type(list) == "table" then
                for _, name in ipairs(list) do
                    add(names, name, tag)
                end
            end
        end
        add(names, element.itemName --[[@as string?]], LOOT)
    end
    table.sort(names.order, longer)
    byStep[step] = names
    return names
end

---Whether a position in a text lies inside a coloured span: more |c before it than |r.
---@param text string
---@param at number
---@return boolean
local function coloured(text, at)
    local before = text:sub(1, at - 1)
    local _, opens = before:gsub("|c", "")
    local _, closes = before:gsub("|r", "")
    return opens > closes
end

---A text with the step's names in their colours.
---@param text string
---@param names {order: string[], tags: table<string, string>, patterns: table<string, string>}
---@return string
local function colour(text, names)
    for _, name in ipairs(names.order) do
        local code = rxp.guideTextColors[names.tags[name]]
        if code and text:find(name, 1, true) then
            text = text:gsub(names.patterns[name], function(at, word)
                if coloured(text, at) then return nil end
                return "|c" .. code .. word .. "|r"
            end)
        end
    end
    return text
end

---Colours the names in an element's text fields (or a step's own), from its step's lines.
---@param element table|string|nil an element or step; RestedXP also passes plain strings
local function tag(element)
    if not ns.db().nameColors or type(element) ~= "table" then return end
    local step = element.step or element
    if type(step) ~= "table" or not step.elements then return end
    local names = namesOf(step)
    if #names.order == 0 then return end
    for _, field in ipairs(FIELDS) do
        ---@type string?
        local text = element[field]
        if type(text) == "string" and text ~= "" then element[field] = colour(text, names) end
    end
end

---After an element update: the element is the third argument.
---@param _label string?
---@param _func function
---@param element table|string|nil
local function afterCall(_label, _func, element)
    tag(element)
end

---Hooks RestedXP's ReplaceColors and Call.
---@param addon RXPGuidesAddon
function Names.Hook(addon)
    rxp = addon
    hooksecurefunc(rxp.settings, "ReplaceColors", tag)
    hooksecurefunc(rxp, "Call", afterCall)
end
