---@meta
-- WoWUnit (github.com/Jaliborc/WoWUnit), the addon the in-game tests run in: only what
-- InGame/Tests.lua uses.

---A group of tests: each function set on it is a test.
---@class WoWUnitGroup: { [string]: fun(self: WoWUnitGroup) }

---@class WoWUnitLibrary
---@overload fun(name: string, ...: string): WoWUnitGroup
---@field AreEqual fun(expected: any, actual: any)
---@field IsTrue fun(value: any)
---@field IsFalse fun(value: any)
---@field Exists fun(value: any)

---@type WoWUnitLibrary?
WoWUnit = nil
