local allFrames = {}
local now = 100
local activeAura
local inCombatLockdown = false
local playedSounds = {}
local stoppedSounds = {}

local Widget = {}
Widget.__index = Widget

local function noop() end

function Widget:SetPoint(point, relativeTo, relativePoint, x, y)
    self.relativeTo = relativeTo
    self.point = { point, relativePoint, x or 0, y or 0 }
end
function Widget:GetPoint()
    local point = self.point or { "CENTER", "CENTER", 0, 0 }
    return point[1], UIParent, point[2], point[3], point[4]
end
function Widget:ClearAllPoints() self.point = nil end
function Widget:SetScript(name, callback) self.scripts[name] = callback end
function Widget:RegisterEvent(event) self.events[event] = true end
function Widget:RegisterUnitEvent(event) self.events[event] = true end
function Widget:UnregisterEvent(event) self.events[event] = nil end
function Widget:CreateTexture()
    return setmetatable({ parent = self, scripts = {}, events = {} }, Widget)
end
function Widget:CreateFontString()
    return setmetatable({ parent = self, scripts = {}, events = {} }, Widget)
end
function Widget:SetText(text) self.textValue = text end
function Widget:GetText() return self.textValue end
function Widget:GetName() return self.name end
function Widget:SetChecked(value) self.checked = value end
function Widget:GetChecked() return self.checked end
function Widget:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function Widget:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Widget:Hide() self.shown = false end
function Widget:IsShown() return self.shown == true end
function Widget:SetShown(shown)
    if shown then self:Show() else self:Hide() end
end
function Widget:SetAttribute(key, value) self.attributes[key] = value end
function Widget:GetAttribute(key) return self.attributes[key] end
function Widget:SetFrameLevel(level) self.frameLevel = level end
function Widget:GetFrameLevel() return self.frameLevel or 1 end
function Widget:EnableMouse(enabled) self.mouseEnabled = enabled end
function Widget:SetSize(width, height)
    self.width = width
    self.height = height or width
end
function Widget:SetDrawSwipe(enabled) self.drawSwipe = enabled end
function Widget:SetHideCountdownNumbers(hidden) self.countdownNumbersHidden = hidden end
function Widget:SetCountdownFormatter(formatter) self.countdownFormatter = formatter end
function Widget:SetDefaultText(text) self.defaultText = text end
function Widget:SetupMenu(generator) self.menuGenerator = generator end
function Widget:SetVertexColor(red, green, blue, alpha)
    self.vertexColor = { red, green, blue, alpha }
end
function Widget:SetTextColor(red, green, blue, alpha)
    self.textColor = { red, green, blue, alpha }
end
function Widget:SetCooldown(startTime, duration, modRate)
    self.cooldownInfo = { startTime, duration, modRate }
end
function Widget:SetEnabled(enabled) self.enabled = enabled end
function Widget:GetWidth() return self.width or 0 end
function Widget:HookScript(name, callback) self.scripts[name] = callback end
function Widget:Init(value)
    self.value = value
    self.Slider = setmetatable({ scripts = {}, events = {} }, Widget)
end

MinimalSliderWithSteppersMixin = { Label = { Right = 2 } }
function CreateMinimalSliderFormatter() return noop end

for _, method in ipairs({
    "SetWidth", "SetHeight", "SetMovable",
    "SetClampedToScreen", "RegisterForDrag", "RegisterForClicks", "StartMoving", "StopMovingOrSizing",
    "SetAllPoints", "SetColorTexture", "SetTexture", "SetTexCoord", "SetVertexColor",
    "SetDrawEdge", "SetSwipeColor",
    "SetJustifyH", "SetJustifyV", "SetTextColor", "SetFont", "SetFontObject", "SetShown", "SetFrameStrata",
    "SetBackdrop", "SetBackdropColor", "SetMinMaxValues", "SetValueStep",
    "SetObeyStepOnDrag", "SetAlpha", "SetDrawBling", "SetMinimumCountdownDuration",
    "SetCountdownAbbrevThreshold", "SetCountdownMillisecondsThreshold", "GenerateMenu",
}) do
    Widget[method] = Widget[method] or noop
end

UIParent = setmetatable({ scripts = {}, events = {} }, Widget)
GameFontNormal = { GetFont = function() return "font.ttf" end }
SlashCmdList = {}
UISpecialFrames = {}

function CreateFrame(frameType, name, parent, template)
    local frame = setmetatable({ name = name, parent = parent, template = template, scripts = {}, events = {}, attributes = {}, shown = true }, Widget)
    frame.Text = setmetatable({ scripts = {}, events = {} }, Widget)
    frame.TitleText = setmetatable({ scripts = {}, events = {} }, Widget)
    if template == "BasicFrameTemplateWithInset" then
        frame.CloseButton = setmetatable({ scripts = {}, events = {}, attributes = {} }, Widget)
    end
    allFrames[#allFrames + 1] = frame
    if template == "OptionsSliderTemplate" and name then
        _G[name .. "Low"] = setmetatable({ scripts = {}, events = {} }, Widget)
        _G[name .. "High"] = setmetatable({ scripts = {}, events = {} }, Widget)
        _G[name .. "Text"] = setmetatable({ scripts = {}, events = {} }, Widget)
    end
    return frame
end

function GetTime() return now end
function UnitClass() return "Warrior", "WARRIOR" end
function GetSpecialization() return 1 end
function GetSpecializationInfo() return 71 end
function IsPlayerSpell(spellID) return spellID == 2825 end
function InCombatLockdown() return inCombatLockdown end
function PlaySoundFile(path, channel)
    playedSounds[#playedSounds + 1] = { path = path, channel = channel }
    return true, 7000 + #playedSounds
end
function StopSound(handle)
    stoppedSounds[#stoppedSounds + 1] = handle
end

C_Spell = {
    GetSpellName = function(spellID)
        local names = {
            [2825] = "Bloodlust",
            [32182] = "Heroism",
            [264667] = "Primal Rage",
            [272651] = "Command Pet",
        }
        return names[spellID] or "Spell " .. tostring(spellID)
    end,
    GetOverrideSpell = function() return nil end,
    GetSpellTexture = function() return 12345 end,
    GetSpellCooldown = function()
        return { startTime = 0, duration = 0, modRate = 1, isActive = false }
    end,
    GetSpellCharges = function()
        return {
            currentCharges = 2,
            maxCharges = 3,
            cooldownStartTime = 90,
            cooldownDuration = 90,
            chargeModRate = 1,
            isActive = true,
        }
    end,
}

C_StringUtil = {
    CreateNumericRuleFormatter = function()
        return {
            SetBreakpoints = function(self, breakpoints)
                self.breakpoints = breakpoints
            end,
        }
    end,
}

Enum = {
    SpellBookSpellBank = {
        Player = 0,
        Pet = 1,
    },
}

C_SpellBook = {
    IsSpellInSpellBook = function() return false end,
    HasPetSpells = function() return 0 end,
    GetSpellBookItemInfo = function() return nil end,
}

C_UnitAuras = {
    GetPlayerAuraBySpellID = function(spellID)
        if activeAura and spellID == (activeAura.spellId or 57723) then return activeAura end
    end,
}

local itemCounts = {}
local itemCooldowns = {}
C_Item = {
    GetItemCount = function(itemID)
        return itemCounts[itemID] or 0
    end,
    GetItemCooldown = function(itemID)
        local cooldown = itemCooldowns[itemID]
        if cooldown then
            return cooldown.startTime, cooldown.duration, cooldown.enabled
        end
        return 0, 0, true
    end,
}

local BBR = {}
for _, file in ipairs({
    "BetterBeReady.lua",
    "Utils.lua",
    "TrackerFrame.lua",
    "Music.lua",
    "Trackers/Bloodlust.lua",
    "Trackers/BattleRes.lua",
    "Trackers/CombatPotion.lua",
    "Trackers/CombatTimer.lua",
    "Trackers/MovementCooldown.lua",
    "Config.lua",
}) do
    local chunk = assert(loadfile(file))
    chunk("BetterBeReady", BBR)
end

BetterBeReadyDB = {
    trackers = {
        bloodlust = { clickToCast = true },
        combatTimer = { size = 64 },
        stoneform = { enabled = true, size = 64 },
    },
}

for _, frame in ipairs(allFrames) do
    if frame.events.ADDON_LOADED and frame.scripts.OnEvent then
        frame.scripts.OnEvent(frame, "ADDON_LOADED", "BetterBeReady")
    end
end

assert(BetterBeReadyDB)
assert(BetterBeReadyDB.schemaVersion == 9)
assert(BetterBeReadyDB.trackers.combatTimer.size == 16)
assert(BetterBeReadyDB.trackers.battleRes.showRechargeTime == true)
assert(BetterBeReadyDB.trackers.battleRes.textMode == true)
assert(BetterBeReadyDB.trackers.battleRes.textAlignment == "LEFT")
assert(BetterBeReadyDB.trackers.bloodlust.textMode == true)
assert(BetterBeReadyDB.trackers.bloodlust.textAlignment == "LEFT")
assert(BetterBeReadyDB.trackers.combatPotion.enabled == true)
assert(BetterBeReadyDB.trackers.combatPotion.size == 16)
assert(BetterBeReadyDB.trackers.combatPotion.textAlignment == "LEFT")
assert(BetterBeReadyDB.trackers.bloodlust.musicTrack == "sounds\\DejaVuHero.ogg")
assert(BetterBeReadyDB.trackers.bloodlust.musicEnabled == true)
assert(BetterBeReadyDB.trackers.bloodlust.musicChannel == "Master")
assert(#BBR.bloodlustMusicTracks == 60)
assert(BBR:GetBloodlustMusicTrack("customsongs\\Bruh.ogg") == nil)
assert(BetterBeReadyDB.trackers.bloodlust.showLabel == false)
assert(BetterBeReadyDB.trackers.battleRes.showLabel == false)
assert(BetterBeReadyDB.trackers.bloodlust.clickToCast == nil)
assert(BetterBeReadyDB.trackers.stoneform == nil)
assert(BBR.trackers.bloodlust.frame)
assert(BBR.trackers.combatPotion.frame)
assert(BBR.trackers.combatPotion.status == "UNAVAILABLE")
assert(BBR.trackers.combatPotion.frame.value:GetText() == "POT")
assert(BBR.trackers.combatPotion.frame.statusText:GetText() == "-")
assert(not BBR.trackers.combatPotion.frame.icon:IsShown())
assert(not BBR.trackers.combatPotion.frame.background:IsShown())
assert(not BBR.trackers.combatPotion.frame.border:IsShown())
assert(BBR.trackers.combatPotion.frame.cooldown.drawSwipe == false)
assert(BBR.trackers.combatPotion.frame.cooldown.countdownFormatter)
assert(BBR.trackers.combatPotion.eventFrame.events.BAG_UPDATE_COOLDOWN)
assert(BBR.trackers.combatPotion.eventFrame.events.BAG_UPDATE_DELAYED)
assert(BBR.trackers.battleRes.frame.value.textValue == 2)
assert(BBR.trackers.battleRes.frame.value.parent == BBR.trackers.battleRes.frame.textOverlay)
assert(BBR.trackers.battleRes.frame.value.point[1] == "LEFT")
assert(BBR.trackers.battleRes.frame.value.point[2] == "CENTER")
assert(BBR.trackers.battleRes.frame.value.point[3] == -32)
assert(BBR.trackers.battleRes.frame.value.point[4] == 0)
assert(not BBR.trackers.battleRes.frame.icon:IsShown())
assert(BBR.trackers.battleRes.frame.separator:IsShown())
assert(BBR.trackers.battleRes.frame.cooldown.drawSwipe == false)
assert(BBR.trackers.battleRes.frame.textOverlay:GetFrameLevel()
    > BBR.trackers.battleRes.frame.cooldown:GetFrameLevel())
assert(BBR.trackers.bloodlust.frame.label.textValue == "")
assert(BBR.trackers.battleRes.frame.label.textValue == "")
assert(BBR.trackers.bloodlust.castButton == nil)
assert(BBR.trackers.bloodlust.clickBlocker == nil)

BBR:SetTrackerBooleanSetting("bloodlust", "textMode", true)
assert(not BBR.trackers.bloodlust.frame.icon:IsShown())
assert(not BBR.trackers.bloodlust.frame.background:IsShown())
assert(not BBR.trackers.bloodlust.frame.border:IsShown())
assert(BBR.trackers.bloodlust.frame.value:IsShown())
assert(BBR.trackers.bloodlust.frame.value:GetText() == "BL")
assert(BBR.trackers.bloodlust.frame.separator:IsShown())
assert(BBR.trackers.bloodlust.frame.separator:GetText() == "|")
assert(BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.statusText:GetText() == "READY")
assert(BBR.trackers.bloodlust.frame.cooldown.drawSwipe == false)
assert(BBR.trackers.bloodlust.frame.cooldown.countdownFormatter)
assert(BBR.trackers.bloodlust.frame.cooldown.countdownFormatter.breakpoints[1].format == "%d:%02d")
assert(BBR.trackers.bloodlust.frame.width == 208)
assert(BBR.trackers.bloodlust.frame.value.relativeTo == BBR.trackers.bloodlust.frame)
assert(BBR.trackers.bloodlust.frame.value.point[1] == "LEFT")
assert(BBR.trackers.bloodlust.frame.value.point[2] == "CENTER")
assert(BBR.trackers.bloodlust.frame.statusText.relativeTo == BBR.trackers.bloodlust.frame.separator)
BBR:SetTrackerTextAlignment("bloodlust", "RIGHT")
assert(BBR.trackers.bloodlust.frame.cooldown.relativeTo == BBR.trackers.bloodlust.frame)
assert(BBR.trackers.bloodlust.frame.cooldown.point[1] == "RIGHT")
assert(BBR.trackers.bloodlust.frame.cooldown.point[2] == "CENTER")
BBR:SetTrackerTextAlignment("bloodlust", "LEFT")
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", false)
assert(BBR.trackers.bloodlust.frame.icon:IsShown())
assert(not BBR.trackers.bloodlust.frame.value:IsShown())
assert(BBR.trackers.bloodlust.frame.cooldown.drawSwipe == true)
assert(BBR.trackers.bloodlust.frame.cooldown.countdownFormatter == nil)

BBR:SetTrackerBooleanSetting("battleRes", "textMode", true)
assert(not BBR.trackers.battleRes.frame.icon:IsShown())
assert(not BBR.trackers.battleRes.frame.background:IsShown())
assert(not BBR.trackers.battleRes.frame.border:IsShown())
assert(BBR.trackers.battleRes.frame.separator:IsShown())
assert(BBR.trackers.battleRes.frame.separator:GetText() == "|")
assert(BBR.trackers.battleRes.frame.cooldown.drawSwipe == false)
assert(BBR.trackers.battleRes.frame.cooldown.countdownNumbersHidden == false)
assert(BBR.trackers.battleRes.frame.cooldown.countdownFormatter)
assert(BBR.trackers.battleRes.frame.cooldown.countdownFormatter.breakpoints[1].format == "%d:%02d")
assert(BBR.trackers.battleRes.frame.width == 112)
assert(BBR.trackers.battleRes.frame.value.relativeTo == BBR.trackers.battleRes.frame)
assert(BBR.trackers.battleRes.frame.value.point[1] == "LEFT")
assert(BBR.trackers.battleRes.frame.value.point[2] == "CENTER")
assert(BBR.trackers.battleRes.frame.cooldown.relativeTo == BBR.trackers.battleRes.frame.separator)
assert(not BBR.trackers.battleRes.frame.rechargeFallback:IsShown())
BBR:SetTrackerTextAlignment("battleRes", "RIGHT")
assert(BBR.trackers.battleRes.frame.cooldown.relativeTo == BBR.trackers.battleRes.frame)
assert(BBR.trackers.battleRes.frame.cooldown.point[1] == "RIGHT")
assert(BBR.trackers.battleRes.frame.cooldown.point[2] == "CENTER")
BBR:SetTrackerTextAlignment("battleRes", "LEFT")

C_Spell.GetSpellCharges = function()
    return {
        currentCharges = 3,
        maxCharges = 3,
        cooldownStartTime = 0,
        cooldownDuration = 0,
        chargeModRate = 1,
        isActive = false,
    }
end
BBR.trackers.battleRes:Update()
assert(BBR.trackers.battleRes.frame.rechargeFallback:IsShown())
assert(BBR.trackers.battleRes.frame.rechargeFallback:GetText() == "-")
assert(BBR.trackers.battleRes.frame.rechargeFallback.relativeTo == BBR.trackers.battleRes.frame.separator)
assert(BBR.trackers.battleRes.frame.rechargeFallback.point[1] == "LEFT")
assert(BBR.trackers.battleRes.frame.rechargeFallback.point[2] == "RIGHT")

C_Spell.GetSpellCharges = function() return nil end
BBR.trackers.battleRes:Update()
assert(BBR.trackers.battleRes.frame.value:GetText() == "-")
assert(BBR.trackers.battleRes.frame.rechargeFallback:IsShown())

BBR:SetTrackerBooleanSetting("battleRes", "textMode", false)
assert(BBR.trackers.battleRes.frame.icon:IsShown())
assert(not BBR.trackers.battleRes.frame.separator:IsShown())
assert(BBR.trackers.battleRes.frame.cooldown.drawSwipe == true)
assert(BBR.trackers.battleRes.frame.width == 64)
BBR:SetTrackerBooleanSetting("battleRes", "textMode", true)

local combatPotion = BBR.trackers.combatPotion
local testPotionID = 241288
itemCounts[testPotionID] = 3
combatPotion:Update()
assert(combatPotion.status == "READY")
assert(combatPotion.lastSeenItemID == testPotionID)
assert(combatPotion.frame.statusText:IsShown())
assert(combatPotion.frame.statusText:GetText() == "READY")

itemCooldowns[testPotionID] = { startTime = 100, duration = 300, enabled = true }
combatPotion:Update()
assert(combatPotion.status == "COOLDOWN")
assert(combatPotion.cooldownItemID == testPotionID)
assert(not combatPotion.frame.statusText:IsShown())
assert(combatPotion.frame.cooldown.cooldownInfo[1] == 100)
assert(combatPotion.frame.cooldown.cooldownInfo[2] == 300)

-- Keep tracking the cooldown after the final potion in a stack is consumed.
itemCounts[testPotionID] = 0
combatPotion:Update()
assert(combatPotion.status == "COOLDOWN")

now = 401
combatPotion:Update()
assert(combatPotion.status == "UNAVAILABLE")
assert(combatPotion.frame.statusText:GetText() == "-")
now = 100
itemCooldowns[testPotionID] = nil

BBR:SetTrackerTextAlignment("combatPotion", "RIGHT")
assert(combatPotion.frame.cooldown.point[1] == "RIGHT")
assert(combatPotion.frame.cooldown.point[2] == "CENTER")
BBR:SetTrackerTextAlignment("combatPotion", "LEFT")
assert(combatPotion.frame.value.point[1] == "LEFT")

-- The Bloodlust tracker is a plain visual frame and remains movable in combat.
local bloodlustFrame = BBR.trackers.bloodlust.frame
bloodlustFrame.StartMoving = function(self)
    self.startMovingCalls = (self.startMovingCalls or 0) + 1
end
BBR:SetLocked(false)
inCombatLockdown = true
bloodlustFrame.scripts.OnDragStart(bloodlustFrame)
assert(bloodlustFrame.startMovingCalls == 1)
bloodlustFrame.point = { "CENTER", "CENTER", 17, 23 }
bloodlustFrame.scripts.OnDragStop(bloodlustFrame)
assert(BetterBeReadyDB.trackers.bloodlust.x == 17)
assert(BetterBeReadyDB.trackers.bloodlust.y == 23)
-- Releasing after a drag must not open settings.
bloodlustFrame.scripts.OnMouseUp(bloodlustFrame, "LeftButton")
assert(not BBR.configFrame or not BBR.configFrame:IsShown())
inCombatLockdown = false

-- A normal click opens settings even while trackers are locked.
BBR:SetLocked(true)
assert(bloodlustFrame.mouseEnabled == true)
bloodlustFrame.scripts.OnMouseUp(bloodlustFrame, "LeftButton")
assert(BBR.configFrame:IsShown())
BBR:CloseConfig()

BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
BBR:SetTrackerEnabled("bloodlust", false)
assert(not BBR.trackers.bloodlust.frame:IsShown())
activeAura = { spellId = 2825, duration = 40, expirationTime = 140 }
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", true)
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "ACTIVE")
assert(BBR.trackers.bloodlust.frame.value:GetText() == "BL ACTIVE")
assert(not BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.cooldown.cooldownInfo[1] == 100)
assert(BBR.trackers.bloodlust.frame.width == 208)
assert(#playedSounds == 1)
assert(playedSounds[1].path
    == "Interface\\AddOns\\BetterBeReady\\Media\\BloodlustMusic\\sounds\\GasHero.ogg")
assert(playedSounds[1].channel == "Master")
assert(BBR.trackers.bloodlust.frame.scripts.OnUpdate)
BBR:SetTrackerEnabled("bloodlust", true)
assert(BBR.trackers.bloodlust.frame:IsShown())
local activeColor = BBR.trackers.bloodlust.frame.value.textColor
BBR.trackers.bloodlust.frame.scripts.OnUpdate(BBR.trackers.bloodlust.frame, 0.5)
local advancedColor = BBR.trackers.bloodlust.frame.value.textColor
assert(activeColor[1] ~= advancedColor[1]
    or activeColor[2] ~= advancedColor[2]
    or activeColor[3] ~= advancedColor[3])

activeAura = { spellId = 57723, duration = 600, expirationTime = 700 }
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "LOCKED")
assert(BBR.trackers.bloodlust.frame.value:GetText() == "BL")
assert(not BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.cooldown.cooldownInfo[1] == 100)
assert(BBR.trackers.bloodlust.frame.width == 208)
assert(BBR.trackers.bloodlust.frame.scripts.OnUpdate == nil)
assert(stoppedSounds[1] == 7001)
BBR:SetBloodlustMusicTrack("")
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", false)

activeAura = nil
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "READY")

-- Once the lockout expires, an outstanding Bloodlust spell cooldown remains
-- visible instead of incorrectly falling back to READY.
C_Spell.GetSpellCooldown = function()
    return { startTime = 100, duration = 300, modRate = 1, isActive = true }
end
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", true)
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.cooldownActive == true)
assert(not BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.cooldown.cooldownInfo[1] == 100)
C_Spell.GetSpellCooldown = function()
    return { startTime = 0, duration = 0, modRate = 1, isActive = false }
end
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.statusText:GetText() == "READY")
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", false)

C_UnitAuras.GetPlayerAuraBySpellID = function()
    error("secret aura value")
end
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "UNKNOWN")

-- Every current class-provided Bloodlust spell is recognized as castable.
local knownBloodlustSpellID
IsPlayerSpell = function(spellID)
    return spellID == knownBloodlustSpellID
end
for _, spellID in ipairs({ 2825, 32182, 80353, 390386, 466904 }) do
    knownBloodlustSpellID = spellID
    BBR.trackers.bloodlust:SelectBloodlustSpell()
    assert(BBR.trackers.bloodlust.spellID == spellID)
    assert(BBR.trackers.bloodlust.spellAvailable == true)
end

-- Received-lust tracking includes Hunter variants and every drums generation.
local trackedBloodlustBuffs = {}
for _, spellID in ipairs(BBR.trackers.bloodlust.bloodlustBuffSpellIDs) do
    trackedBloodlustBuffs[spellID] = true
end
for _, spellID in ipairs({
    2825, 32182, 80353, 90355, 146555, 160452, 178207,
    230935, 256740, 264667, 292686, 309658, 381301,
    390386, 441076, 444257, 466904, 1243972,
}) do
    assert(trackedBloodlustBuffs[spellID], "missing Bloodlust buff " .. spellID)
end

-- A Ferocity pet exposes Primal Rage by overriding the Hunter's Command Pet.
IsPlayerSpell = function() return false end
C_Spell.GetOverrideSpell = function(spellID)
    if spellID == 272651 then
        return 264667
    end
end
C_UnitAuras.GetPlayerAuraBySpellID = function() return nil end
BBR.trackers.bloodlust:SelectBloodlustSpell()
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.spellID == 264667)
assert(BBR.trackers.bloodlust.status == "READY")

-- Primal Rage can be a pet action even when the generic spell cooldown API
-- has no entry for it. Fall back to the matching pet action slot.
GetPetActionInfo = function(slot)
    if slot == 4 then
        return "Primal Rage", 12345, false, false, false, false, 264667
    end
end
GetPetActionCooldown = function(slot)
    assert(slot == 4)
    return 75, 300, 1
end
C_Spell.GetSpellCooldown = function() return nil end
BBR.trackers.bloodlust:SelectBloodlustSpell()
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.primalRagePetActionSlot == 4)
assert(BBR.trackers.bloodlust.cooldownActive == true)
assert(BBR.trackers.bloodlust.frame.cooldown.cooldownInfo[1] == 75)

GetPetActionCooldown = function(slot)
    assert(slot == 4)
    return 0, 0, 1
end
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.cooldownActive == false)
assert(BBR.trackers.bloodlust.frame.statusText:GetText() == "READY")
GetPetActionInfo = nil
GetPetActionCooldown = nil
C_Spell.GetSpellCooldown = function()
    return { startTime = 0, duration = 0, modRate = 1, isActive = false }
end

-- A non-Ferocity pet makes the tracker unavailable.
C_Spell.GetOverrideSpell = function(spellID) return spellID end
BBR.trackers.bloodlust:SelectBloodlustSpell()
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "UNAVAILABLE")

-- Characters without a Bloodlust spell still track received lust effects and
-- the personal lockout before returning to the unavailable idle state.
C_UnitAuras.GetPlayerAuraBySpellID = function(spellID)
    if activeAura and spellID == activeAura.spellId then return activeAura end
end
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", true)
activeAura = { spellId = 80353, duration = 40, expirationTime = 140 }
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "ACTIVE")
assert(BBR.trackers.bloodlust.frame.value:GetText() == "BL ACTIVE")

activeAura = { spellId = 1243972, duration = 40, expirationTime = 140 }
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "ACTIVE")
assert(BBR.trackers.bloodlust.frame.value:GetText() == "BL ACTIVE")

activeAura = { spellId = 57723, duration = 600, expirationTime = 700 }
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "LOCKED")
assert(BBR.trackers.bloodlust.frame.value:GetText() == "BL")

activeAura = nil
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "UNAVAILABLE")
assert(BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.statusText:GetText() == "-")
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", false)

BBR.trackers.combatTimer:Start(false)
now = 165.9
BBR.trackers.combatTimer:UpdateDisplay()
assert(BBR.trackers.combatTimer.frame.value.textValue == "1:05")

BBR:ToggleConfig()
assert(BBR.configFrame:IsShown())
assert(BBR.configFrame.width == 720)
assert(BBR.configFrame.height == 500)
assert(BBR.configFrame.activeTabId == "general")
for _, tabID in ipairs({ "general", "bloodlust", "battleRes", "combatPotion", "combatTimer", "movementCooldown" }) do
    assert(BBR.configFrame.tabButtons[tabID], "missing tab " .. tabID)
    assert(BBR.configFrame.pages[tabID], "missing page " .. tabID)
end
BBR.configFrame.tabButtons.movementCooldown.scripts.OnClick()
assert(BBR.configFrame.activeTabId == "movementCooldown")
assert(BBR.configFrame.pages.movementCooldown.content:IsShown())
assert(not BBR.configFrame.pages.general.content:IsShown())
assert(BBR.configFrame.pages.general.lockButton:GetText() == "Unlock trackers")
assert(BBR.configFrame.pages.bloodlust.size.value == 64)
assert(BBR.configFrame.pages.bloodlust.textSize.value == 16)
assert(BBR.configFrame.pages.combatPotion.size.value == 16)
assert(BBR.configFrame.pages.combatTimer.size.value == 16)
assert(BBR.configFrame.pages.bloodlust.enabled.Text:GetText() == "Show visuals")
assert(BBR.configFrame.pages.bloodlust.textMode:GetChecked() == false)
assert(BBR.configFrame.pages.bloodlust.musicEnabled:GetChecked() == true)
BBR.configFrame.pages.bloodlust.size.Slider.scripts.OnValueChanged(nil, 80)
assert(BetterBeReadyDB.trackers.bloodlust.size == 80)
BBR:SetTrackerSize("bloodlust", 64)

for _, trackerKey in ipairs({ "bloodlust", "battleRes", "combatPotion", "combatTimer" }) do
    local enabledCheckbox = BBR.configFrame.pages[trackerKey].enabled
    enabledCheckbox:SetChecked(false)
    enabledCheckbox.scripts.OnClick(enabledCheckbox)
    assert(BetterBeReadyDB.trackers[trackerKey].enabled == false)
    assert(not BBR.trackers[trackerKey].frame:IsShown())
    assert(BBR.configFrame.pages[trackerKey].size.container.enabled == false)

    enabledCheckbox:SetChecked(true)
    enabledCheckbox.scripts.OnClick(enabledCheckbox)
    assert(BetterBeReadyDB.trackers[trackerKey].enabled == true)
    assert(BBR.trackers[trackerKey].frame:IsShown())
    assert(BBR.configFrame.pages[trackerKey].size.container.enabled == true)
end

-- The Bloodlust visuals and music use separate settings, allowing the music
-- to play while the timer and icon are hidden.
local bloodlustMusicEnabled = BBR.configFrame.pages.bloodlust.musicEnabled
bloodlustMusicEnabled:SetChecked(false)
bloodlustMusicEnabled.scripts.OnClick(bloodlustMusicEnabled)
assert(BetterBeReadyDB.trackers.bloodlust.musicEnabled == false)
bloodlustMusicEnabled:SetChecked(true)
bloodlustMusicEnabled.scripts.OnClick(bloodlustMusicEnabled)
assert(BetterBeReadyDB.trackers.bloodlust.musicEnabled == true)

local function GetDropdownRadios(dropdown)
    local radios = {}
    local root = {
        CreateRadio = function(_, title, isSelected, setSelected, value)
            radios[#radios + 1] = {
                title = title,
                isSelected = isSelected,
                setSelected = setSelected,
                value = value,
            }
        end,
    }
    dropdown.menuGenerator(dropdown, root)
    return radios
end

assert(BBR.configFrame.pages.bloodlust.textAlignment:GetText() == "Left")
local bloodlustAlignments = GetDropdownRadios(BBR.configFrame.pages.bloodlust.textAlignment)
assert(#bloodlustAlignments == 2)
bloodlustAlignments[2].setSelected(bloodlustAlignments[2].value)
assert(BetterBeReadyDB.trackers.bloodlust.textAlignment == "RIGHT")
assert(BBR.configFrame.pages.bloodlust.textAlignment:GetText() == "Right")
bloodlustAlignments[1].setSelected(bloodlustAlignments[1].value)
assert(BetterBeReadyDB.trackers.bloodlust.textAlignment == "LEFT")
assert(BBR.configFrame.pages.battleRes.textMode:GetChecked() == true)
assert(BBR.configFrame.pages.battleRes.textAlignment:GetText() == "Left")
local battleResAlignments = GetDropdownRadios(BBR.configFrame.pages.battleRes.textAlignment)
battleResAlignments[2].setSelected(battleResAlignments[2].value)
assert(BetterBeReadyDB.trackers.battleRes.textAlignment == "RIGHT")
assert(BBR.configFrame.pages.battleRes.textAlignment:GetText() == "Right")
battleResAlignments[1].setSelected(battleResAlignments[1].value)
assert(BetterBeReadyDB.trackers.battleRes.textAlignment == "LEFT")
assert(BBR.configFrame.pages.combatPotion.textAlignment:GetText() == "Left")
local combatPotionAlignments = GetDropdownRadios(BBR.configFrame.pages.combatPotion.textAlignment)
combatPotionAlignments[2].setSelected(combatPotionAlignments[2].value)
assert(BetterBeReadyDB.trackers.combatPotion.textAlignment == "RIGHT")
assert(BBR.configFrame.pages.combatPotion.textAlignment:GetText() == "Right")
combatPotionAlignments[1].setSelected(combatPotionAlignments[1].value)
assert(BetterBeReadyDB.trackers.combatPotion.textAlignment == "LEFT")
assert(BBR.configFrame.pages.bloodlust.musicDropdown:GetText() == "No sound")
local musicRadios = GetDropdownRadios(BBR.configFrame.pages.bloodlust.musicDropdown)
assert(#musicRadios == 61)
assert(musicRadios[1].title == "No sound")
assert(musicRadios[1].value == "")
musicRadios[2].setSelected(musicRadios[2].value)
assert(BetterBeReadyDB.trackers.bloodlust.musicTrack == "sounds\\GasHero.ogg")
assert(BBR.configFrame.pages.bloodlust.musicDropdown:GetText() == "Manuel - GAS GAS GAS")
local channelRadios = GetDropdownRadios(BBR.configFrame.pages.bloodlust.musicChannel)
assert(#channelRadios == 5)
assert(channelRadios[1].value == "Master" and channelRadios[1].isSelected("Master"))
channelRadios[2].setSelected(channelRadios[2].value)
assert(BetterBeReadyDB.trackers.bloodlust.musicChannel == "Music")
assert(BBR.configFrame.pages.bloodlust.musicChannel:GetText() == "Music")
channelRadios[1].setSelected(channelRadios[1].value)
assert(BetterBeReadyDB.trackers.bloodlust.musicChannel == "Master")
assert(BBR.configFrame.pages.bloodlust.musicPlayButton:GetText() == "Play")
assert(BBR.configFrame.pages.bloodlust.musicStopButton:GetText() == "Stop")
BBR.configFrame.pages.bloodlust.musicPlayButton.scripts.OnClick()
assert(#playedSounds == 2)
assert(playedSounds[2].path
    == "Interface\\AddOns\\BetterBeReady\\Media\\BloodlustMusic\\sounds\\GasHero.ogg")
assert(playedSounds[2].channel == "Master")
assert(BBR.musicPreviewSoundHandle == 7002)
BBR.configFrame.pages.bloodlust.musicStopButton.scripts.OnClick()
assert(stoppedSounds[#stoppedSounds] == 7002)
assert(BBR.musicPreviewSoundHandle == nil)
BBR:SetBloodlustMusicTrack("")
assert(#playedSounds == 2)

-- Clients without native triggers retain single-handle playback from readable
-- lockout data while the actual haste buff is secret.
BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
inCombatLockdown = true
now = 1000
C_UnitAuras.GetPlayerAuraBySpellID = function(spellID)
    if spellID == 57724 then
        return { duration = 600, expirationTime = 1600 }
    end
    for _, lockoutID in ipairs(BBR.trackers.bloodlust.lockoutSpellIDs) do
        if spellID == lockoutID then return nil end
    end
    error("secret haste aura")
end
BBR.trackers.bloodlust:Update()
assert(#playedSounds == 3)
for _ = 1, 100 do BBR.trackers.bloodlust:Update() end
assert(#playedSounds == 3)
now = 1040
BBR.trackers.bloodlust.eventFrame.scripts.OnUpdate()
assert(stoppedSounds[#stoppedSounds] == 7003)
BBR.trackers.bloodlust:Update()
assert(#playedSounds == 3)
BBR:SetBloodlustMusicTrack("")
-- Native registrations are installed on entering the world, and pending track
-- changes are reconciled on leaving combat without adding duplicate listeners.
local nativeSounds, nativeID = {}, 0
Enum.UnitAuraSoundTrigger = { Added = 0 }
C_UnitAuras.AddAuraSound = function(trigger, sound)
    assert(trigger == 0)
    nativeID = nativeID + 1
    nativeSounds[nativeID] = sound
    return nativeID
end
C_UnitAuras.RemoveAuraSound = function(id) nativeSounds[id] = nil end
inCombatLockdown = false
BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
local registrationCount = #BBR.trackers.bloodlust.lockoutSpellIDs
assert(nativeID == registrationCount)
BBR.trackers.bloodlust.eventFrame.scripts.OnEvent(nil, "PLAYER_ENTERING_WORLD")
assert(nativeID == registrationCount)
-- Visual toggles leave native music registrations intact.
BBR:SetTrackerEnabled("bloodlust", false)
assert(not BBR.trackers.bloodlust.frame:IsShown())
assert(next(nativeSounds) ~= nil)
assert(nativeID == registrationCount)
BBR:SetTrackerEnabled("bloodlust", true)
assert(nativeID == registrationCount)
-- Music has its own toggle, with one registration per lockout on re-enable.
BBR:SetBloodlustMusicEnabled(false)
assert(next(nativeSounds) == nil)
BBR:SetBloodlustMusicEnabled(true)
assert(nativeID == registrationCount * 2)
BBR:SetBloodlustMusicEnabled(true)
assert(nativeID == registrationCount * 2)
inCombatLockdown = true
BBR:SetBloodlustMusicTrack("sounds\\DejaVuHero.ogg")
assert(BBR.bloodlustMusicAuraSoundRefreshPending)
assert(nativeID == registrationCount * 2)
inCombatLockdown = false
BBR.trackers.bloodlust.eventFrame.scripts.OnEvent(nil, "PLAYER_REGEN_ENABLED")
assert(nativeID == registrationCount * 3)
assert(not BBR.bloodlustMusicAuraSoundRefreshPending)
assert(#playedSounds == 3)
BBR:SetBloodlustMusicTrack("")
assert(next(nativeSounds) == nil)

-- Movement cooldown: disabled by default and registers no events until enabled.
local movement = BBR.trackers.movementCooldown
local movementSettings = BetterBeReadyDB.trackers.movementCooldown
assert(movementSettings.enabled == false)
assert(not movement.frame:IsShown())
assert(next(movement.eventFrame.events) == nil)

IsPlayerSpell = function(spellID) return spellID == 6544 end
GetSpellBaseCooldown = function(spellID) return spellID == 6544 and 45000 or 0 end
C_Spell.GetSpellCharges = function() return nil end
local movementCooldown = { startTime = 0, duration = 0, modRate = 1, isOnGCD = false }
C_Spell.GetSpellCooldown = function() return movementCooldown end
BBR:SetLocked(true)
BBR:SetTrackerEnabled("movementCooldown", true)
assert(movement.eventFrame.events.SPELL_UPDATE_COOLDOWN)
assert(movement.eventFrame.events.UNIT_SPELLCAST_SUCCEEDED)
assert(#movement.entries == 1)
assert(movement.entries[1].spellID == 6544)
assert(movement.entries[1].baseDuration == 45)
assert(movement.activeSlotCount == 0)
assert(not movement.frame:IsShown())

-- A readable cooldown binds the Blizzard countdown and shows the tracker.
movementCooldown.startTime, movementCooldown.duration = now, 45
movement:Update()
assert(movement.activeSlotCount == 1)
assert(movement.frame:IsShown())
assert(movement.slots[1]:IsShown())
assert(movement.slots[1].cooldown.cooldownInfo[2] == 45)

-- Short shared lockouts are not the ability's own cooldown.
movementCooldown.duration = 2
movement:Update()
assert(movement.activeSlotCount == 0)
assert(not movement.frame:IsShown())

-- The GCD alone never counts as the movement cooldown.
movementCooldown.duration, movementCooldown.isOnGCD = 45, true
movement:Update()
assert(movement.activeSlotCount == 0)
movementCooldown.isOnGCD = false

-- Secret combat timings are handed to the widget as a duration object.
local secretDuration = {
    GetRemainingDuration = function() return "secret" end,
    GetTotalDuration = function() return "secret" end,
}
issecretvalue = function(value) return value == "secret" end
movementCooldown.startTime, movementCooldown.duration = "secret", "secret"
C_Spell.GetSpellCooldownDuration = function(_, ignoreGCD)
    assert(ignoreGCD == true)
    return secretDuration
end
local boundDuration
Widget.SetCooldownFromDurationObject = function(_, duration) boundDuration = duration end
movement:Update()
assert(movement.activeSlotCount == 1)
assert(boundDuration == secretDuration)
issecretvalue = nil
C_Spell.GetSpellCooldownDuration = nil
Widget.SetCooldownFromDurationObject = nil
movementCooldown.startTime, movementCooldown.duration = now, 45

-- Only in combat hides the countdown outside combat.
BBR:SetTrackerBooleanSetting("movementCooldown", "combatOnly", true)
assert(movement.activeSlotCount == 0)
movement:OnEvent("PLAYER_REGEN_DISABLED")
movement.updateFrame.scripts.OnUpdate(movement.updateFrame)
assert(movement.activeSlotCount == 1)
movement:OnEvent("PLAYER_REGEN_ENABLED")
movement.updateFrame.scripts.OnUpdate(movement.updateFrame)
BBR:SetTrackerBooleanSetting("movementCooldown", "combatOnly", false)

-- Nothing is written while the ability is ready, even when unlocked.
movementCooldown.duration = 0
BBR:SetLocked(false)
assert(movement.frame:IsShown())
assert(not movement.frame.value:IsShown())
assert(movement.activeSlotCount == 0)
BBR:SetLocked(true)
assert(not movement.frame:IsShown())
movementCooldown.duration = 45

-- The settings page lists the spec's spells and toggles them.
BBR:RefreshConfig()
local movementPage = BBR.configFrame.pages.movementCooldown
assert(movementPage.enabled:GetChecked() == true)
assert(movementPage.spellCheckboxes[1].spellID == 6544)
assert(movementPage.spellCheckboxes[1]:GetChecked() == true)
movementPage.spellCheckboxes[1]:SetChecked(false)
movementPage.spellCheckboxes[1].scripts.OnClick(movementPage.spellCheckboxes[1])
assert(movementSettings.spells[6544] == false)
assert(#movement.entries == 0)
assert(movement.activeSlotCount == 0)
movementPage.spellCheckboxes[1]:SetChecked(true)
movementPage.spellCheckboxes[1].scripts.OnClick(movementPage.spellCheckboxes[1])
assert(movement.activeSlotCount == 1)

BBR:SetTrackerEnabled("movementCooldown", false)
assert(next(movement.eventFrame.events) == nil)
assert(not movement.frame:IsShown())
assert(UISpecialFrames[1] == "BetterBeReadyConfigFrame")

inCombatLockdown = true
BBR.configFrame.CloseButton.scripts.OnClick()
assert(not BBR.configFrame:IsShown())
BBR:ToggleConfig()
assert(BBR.configFrame:IsShown())
SlashCmdList.BETTERBEREADY("close")
assert(not BBR.configFrame:IsShown())
inCombatLockdown = false

print("smoke_test.lua: OK")
