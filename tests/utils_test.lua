local BBR = {}
local chunk = assert(loadfile("Utils.lua"))
chunk("BetterBeReady", BBR)

local secretContainer = { isActive = false, duration = "secret" }
issecrettable = function(value) return value == secretContainer end
issecretvalue = function(value) return value == "secret" end
local readableValue, readable = BBR:GetReadableField(secretContainer, "isActive")
assert(readable == true)
assert(readableValue == false)
local hiddenValue, hiddenReadable = BBR:GetReadableField(secretContainer, "duration")
assert(hiddenReadable == false)
assert(hiddenValue == nil)

assert(BBR:FormatDuration(0, false) == "0:00")
assert(BBR:FormatDuration(65.9, false) == "1:05")
assert(BBR:FormatDuration(65.9, true) == "1:05.9")

local ids = { 1, 2, 3 }
local aura = { duration = 600, expirationTime = 700 }

local found, state = BBR:FindFirstAuraBySpellID(function(spellID)
    if spellID == 2 then
        return aura
    end
end, ids)
assert(found == aura)
assert(state == "LOCKED")

found, state = BBR:FindFirstAuraBySpellID(function()
    return nil
end, ids)
assert(found == nil)
assert(state == "READY")

found, state = BBR:FindFirstAuraBySpellID(function()
    error("API refused the aura read")
end, ids)
assert(found == nil)
assert(state == "UNKNOWN")

print("utils_test.lua: OK")
