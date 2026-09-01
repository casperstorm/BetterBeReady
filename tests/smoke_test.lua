local allFrames = {}
local now = 100
local activeAura
local inCombatLockdown = false

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
function Widget:SetCooldown(startTime, duration, modRate)
    self.cooldownInfo = { startTime, duration, modRate }
end

for _, method in ipairs({
    "SetWidth", "SetHeight", "SetMovable",
    "SetClampedToScreen", "RegisterForDrag", "RegisterForClicks", "StartMoving", "StopMovingOrSizing",
    "SetAllPoints", "SetColorTexture", "SetTexture", "SetTexCoord", "SetVertexColor",
    "SetDrawEdge", "SetSwipeColor",
    "SetJustifyH", "SetJustifyV", "SetTextColor", "SetFont", "SetFontObject", "SetShown", "SetFrameStrata",
    "SetBackdrop", "SetBackdropColor", "SetMinMaxValues", "SetValueStep",
    "SetObeyStepOnDrag",
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
function IsPlayerSpell(spellID) return spellID == 2825 end
function InCombatLockdown() return inCombatLockdown end

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
        if activeAura and spellID == 57723 then return activeAura end
    end,
}

local BBR = {}
for _, file in ipairs({
    "BetterBeReady.lua",
    "Utils.lua",
    "TrackerFrame.lua",
    "Trackers/Bloodlust.lua",
    "Trackers/BattleRes.lua",
    "Trackers/CombatTimer.lua",
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
assert(BetterBeReadyDB.schemaVersion == 6)
assert(BetterBeReadyDB.trackers.combatTimer.size == 24)
assert(BetterBeReadyDB.trackers.battleRes.showRechargeTime == true)
assert(BetterBeReadyDB.trackers.battleRes.textMode == false)
assert(BetterBeReadyDB.trackers.bloodlust.textMode == false)
assert(BetterBeReadyDB.trackers.bloodlust.showLabel == false)
assert(BetterBeReadyDB.trackers.battleRes.showLabel == false)
assert(BetterBeReadyDB.trackers.bloodlust.clickToCast == nil)
assert(BetterBeReadyDB.trackers.stoneform == nil)
assert(BBR.trackers.bloodlust.frame)
assert(BBR.trackers.battleRes.frame.value.textValue == 2)
assert(BBR.trackers.battleRes.frame.value.parent == BBR.trackers.battleRes.frame.textOverlay)
assert(BBR.trackers.battleRes.frame.value.point[1] == "BOTTOM")
assert(BBR.trackers.battleRes.frame.value.point[2] == "TOP")
assert(BBR.trackers.battleRes.frame.value.point[3] == 0)
assert(BBR.trackers.battleRes.frame.value.point[4] == 4)
assert(BBR.trackers.battleRes.frame.icon:IsShown())
assert(not BBR.trackers.battleRes.frame.separator:IsShown())
assert(BBR.trackers.battleRes.frame.cooldown.drawSwipe == true)
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
assert(BBR.trackers.bloodlust.frame.width == 96)
assert(BBR.trackers.bloodlust.frame.value.relativeTo == BBR.trackers.bloodlust.frame.separator)
assert(BBR.trackers.bloodlust.frame.statusText.relativeTo == BBR.trackers.bloodlust.frame.separator)
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
assert(BBR.trackers.battleRes.frame.width == 96)
assert(BBR.trackers.battleRes.frame.value.relativeTo == BBR.trackers.battleRes.frame.separator)
assert(BBR.trackers.battleRes.frame.value.point[1] == "RIGHT")
assert(BBR.trackers.battleRes.frame.value.point[2] == "LEFT")
assert(BBR.trackers.battleRes.frame.cooldown.relativeTo == BBR.trackers.battleRes.frame.separator)
assert(not BBR.trackers.battleRes.frame.rechargeFallback:IsShown())

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

activeAura = { duration = 600, expirationTime = 700 }
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "LOCKED")
BBR:SetTrackerBooleanSetting("bloodlust", "textMode", true)
assert(not BBR.trackers.bloodlust.frame.statusText:IsShown())
assert(BBR.trackers.bloodlust.frame.cooldown.cooldownInfo[1] == 100)
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

-- A non-Ferocity pet makes the tracker unavailable.
C_Spell.GetOverrideSpell = function(spellID) return spellID end
BBR.trackers.bloodlust:SelectBloodlustSpell()
BBR.trackers.bloodlust:Update()
assert(BBR.trackers.bloodlust.status == "UNAVAILABLE")

BBR.trackers.combatTimer:Start(false)
now = 165.9
BBR.trackers.combatTimer:UpdateDisplay()
assert(BBR.trackers.combatTimer.frame.value.textValue == "1:05.9")

BBR:ToggleConfig()
assert(BBR.configFrame:IsShown())
assert(BetterBeReadySizeSlider1Text.textValue == "Icon size: 64 px")
assert(BetterBeReadySizeSlider3Text.textValue == "Text size: 24 px")
assert(BetterBeReadyTextSizeSlider1Text.textValue == "Text size: 16 px")
assert(BetterBeReadyTextSizeSlider2Text.textValue == "Text size: 16 px")
assert(BBR.configFrame.rows.bloodlust.textMode:GetChecked() == false)
assert(BBR.configFrame.rows.battleRes.textMode:GetChecked() == true)
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
