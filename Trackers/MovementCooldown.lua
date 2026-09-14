local _, BBR = ...

-- Ported from EllesmereUI's Movement Cooldown Alert
-- (EllesmereUIQoL/EllesmereUIQoL_MovementAlert.lua). Only the countdown text is
-- kept: icon/bar modes, TTS, Time Spiral, Gateway Shard and the Burning Rush
-- aura lane are not part of this tracker.

-- Class -> specID -> mobility spell IDs. Talent overrides (Blink -> Shimmer)
-- are resolved at cache time through C_Spell.GetOverrideSpell.
local MOVEMENT_ABILITIES = {
    DEATHKNIGHT = { [250] = { 48265, 212552 }, [251] = { 48265, 212552 }, [252] = { 48265, 444010, 444347, 212552 } },
    DEMONHUNTER = { [577] = { 195072 }, [581] = { 189110 }, [1480] = { 1234796 } },
    DRUID = {
        [102] = { 102401, 252216, 1850, 102417 },
        [103] = { 102401, 252216, 1850, 102417 },
        [104] = { 102401, 252216, 106898, 1850, 102417 },
        [105] = { 102401, 252216, 1850, 102417 },
    },
    EVOKER = { [1467] = { 358267 }, [1468] = { 358267 }, [1473] = { 358267 } },
    HUNTER = { [253] = { 186257, 781 }, [254] = { 186257, 781 }, [255] = { 186257, 781 } },
    MAGE = { [62] = { 212653, 1953 }, [63] = { 212653, 1953 }, [64] = { 212653, 1953 } },
    MONK = {
        [268] = { 115008, 109132, 119085, 361138 },
        [269] = { 109132, 119085, 361138, 101545 },
        [270] = { 109132, 119085, 361138 },
    },
    PALADIN = { [65] = { 190784 }, [66] = { 190784 }, [70] = { 190784 } },
    PRIEST = { [256] = { 121536, 73325 }, [257] = { 121536, 73325 }, [258] = { 121536, 73325 } },
    ROGUE = { [259] = { 36554, 2983 }, [260] = { 195457, 2983 }, [261] = { 36554, 2983 } },
    SHAMAN = {
        [262] = { 79206, 90328, 192063, 58875 },
        [263] = { 90328, 192063, 58875 },
        [264] = { 79206, 90328, 192063, 58875 },
    },
    WARLOCK = { [265] = { 48020 }, [266] = { 48020 }, [267] = { 48020 } },
    WARRIOR = { [71] = { 6544 }, [72] = { 6544 }, [73] = { 6544 } },
}

-- Preset spells that are not tracked until explicitly checked.
local DEFAULT_OFF = {
    [2983] = true, -- Sprint
    [73325] = true, -- Leap of Faith
    [106898] = true, [77761] = true, [77764] = true, -- Stampeding Roar
    [1850] = true, -- Dash
    [252216] = true, -- Tiger Dash
    [212552] = true, -- Wraith Walk
    [79206] = true, -- Spiritwalker's Grace
    [58875] = true, [90328] = true, -- Spirit Walk
}

local SPELL_ALIAS_GROUPS = {
    { 102401, 16979, 102417, 252216 },
    { 106898, 77761, 77764 },
}

local SPELL_CATEGORY_DURATION = {
    [102401] = 15, [16979] = 15, [102417] = 15, [252216] = 15,
    [1850] = 18,
    [106898] = 120, [77761] = 120,
}

local SPELL_ALIAS_MAP = {}
for _, group in ipairs(SPELL_ALIAS_GROUPS) do
    for _, id in ipairs(group) do
        SPELL_ALIAS_MAP[id] = group
    end
end

-- Casting one charge ability can briefly lock out a sibling (Skull Bash does
-- this to Wild Charge for ~2s) through the same cooldown fields a real
-- cooldown uses. A window far shorter than the ability's own base cooldown
-- cannot be that cooldown, so it is not shown.
local MIN_REAL_COOLDOWN = 3

local tracker = {
    minSize = 8,
    maxSize = 48,
    entries = {},
    slots = {},
    activeSlotCount = 0,
    movementAbilities = MOVEMENT_ABILITIES,
    defaultOff = DEFAULT_OFF,
}

local function IsSecret(value)
    return BBR:IsSecretValue(value)
end

local function IsReadableNumber(value)
    return type(value) == "number" and not IsSecret(value)
end

local function GetKnownCategoryDuration(spellID)
    if SPELL_CATEGORY_DURATION[spellID] then
        return SPELL_CATEGORY_DURATION[spellID]
    end
    local group = SPELL_ALIAS_MAP[spellID]
    if group then
        for _, id in ipairs(group) do
            if SPELL_CATEGORY_DURATION[id] then
                return SPELL_CATEGORY_DURATION[id]
            end
        end
    end
    return 0
end

-- Static spell data stays readable when live cooldown state is secret.
local function GetBaseCooldown(spellID)
    if GetSpellBaseCooldown then
        local ok, ms = pcall(GetSpellBaseCooldown, spellID)
        if ok and IsReadableNumber(ms) and ms > 1500 then
            return ms / 1000
        end
    end
    return GetKnownCategoryDuration(spellID)
end

local function IsLockoutWindow(entry, seconds)
    if not IsReadableNumber(seconds) then
        return false
    end
    local base = entry.baseDuration or 0
    return base > MIN_REAL_COOLDOWN and seconds < MIN_REAL_COOLDOWN
end

-- A step curve turns a secret duration into a secret 0/1 alpha that the
-- engine evaluates, so Lua never compares the secret value itself.
local function CreateStepCurve(threshold)
    if not (C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType) then
        return false
    end
    local curve = C_CurveUtil.CreateCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    curve:AddPoint(0, 0)
    curve:AddPoint(threshold, 1)
    return curve
end

local lockoutAlphaCurve
local chargeAlphaCurve

local function LockoutAlpha(entry, duration)
    if not (duration and duration.EvaluateTotalDuration) then
        return 1
    end
    if (entry.baseDuration or 0) <= MIN_REAL_COOLDOWN then
        return 1
    end
    if lockoutAlphaCurve == nil then
        lockoutAlphaCurve = CreateStepCurve(MIN_REAL_COOLDOWN)
    end
    if not lockoutAlphaCurve then
        return 1
    end
    return duration:EvaluateTotalDuration(lockoutAlphaCurve, 1) or 1
end

-- Charge spells: currentCharges is secret, but while a charge is banked the
-- spell only reports a GCD-length cooldown. The full recharge drives it once
-- the last charge is spent, so a 1.6s step hides banked-charge states.
local function ApplyVisibility(slot, spellID, chargeInfo, entry, duration)
    local maxCharges = chargeInfo and chargeInfo.maxCharges
    if not IsReadableNumber(maxCharges) or maxCharges <= 1 then
        slot:SetAlpha(LockoutAlpha(entry, duration))
        return
    end
    if chargeAlphaCurve == nil then
        chargeAlphaCurve = CreateStepCurve(1.6)
    end
    -- Deliberately without ignoreGCD: the GCD-length total is the signal.
    local durationObject = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(spellID)
    if chargeAlphaCurve and durationObject and durationObject.EvaluateTotalDuration then
        slot:SetAlpha(durationObject:EvaluateTotalDuration(chargeAlphaCurve, 1) or 1)
    else
        slot:SetAlpha(1)
    end
end

local function GetPlayerSpecID()
    if not (GetSpecialization and GetSpecializationInfo) then
        return nil
    end
    local spec = GetSpecialization()
    if not spec then
        return nil
    end
    local specID = GetSpecializationInfo(spec)
    if specID and specID > 0 then
        return specID
    end
    return nil
end

local function IsSpellKnown(spellID)
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end
    return C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) or false
end

local function GetOverrideSpell(spellID)
    if C_Spell and C_Spell.GetOverrideSpell then
        local ok, overrideID = pcall(C_Spell.GetOverrideSpell, spellID)
        if ok and IsReadableNumber(overrideID) and overrideID > 0 then
            return overrideID
        end
    end
    return spellID
end

local function GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(name) == "string" then
            return name
        end
    end
    return "Spell " .. tostring(spellID)
end

-- Spell IDs listed for the player's current class and specialization.
function tracker:GetSpecSpellIDs()
    local _, classToken = UnitClass("player")
    local classAbilities = classToken and MOVEMENT_ABILITIES[classToken]
    local specID = GetPlayerSpecID()
    return classAbilities and specID and classAbilities[specID] or {}
end

function tracker:IsSpellEnabled(spellID)
    local settings = BBR:GetTrackerSettings(self.key)
    local choice = settings and settings.spells and settings.spells[spellID]
    if choice ~= nil then
        return choice == true
    end
    return not DEFAULT_OFF[spellID]
end

function tracker:SetSpellEnabled(spellID, enabled)
    local settings = BBR:GetTrackerSettings(self.key)
    if not settings then
        return
    end
    settings.spells = settings.spells or {}
    settings.spells[spellID] = enabled and true or false
    self:CacheSpells()
    self:Update()
end

-- Rows for the settings page: every preset spell for the current spec.
function tracker:GetSpellOptions()
    local options = {}
    for _, spellID in ipairs(self:GetSpecSpellIDs()) do
        options[#options + 1] = {
            spellID = spellID,
            name = GetSpellName(GetOverrideSpell(spellID)),
            known = IsSpellKnown(spellID),
            enabled = self:IsSpellEnabled(spellID),
        }
    end
    return options
end

function tracker:CacheSpells()
    local entries, seen = {}, {}
    for _, spellID in ipairs(self:GetSpecSpellIDs()) do
        if not seen[spellID] and self:IsSpellEnabled(spellID) and IsSpellKnown(spellID) then
            local displayID = GetOverrideSpell(spellID)
            if not seen[displayID] then
                seen[spellID] = true
                seen[displayID] = true
                local base = GetBaseCooldown(displayID)
                if base <= 0 and displayID ~= spellID then
                    base = GetBaseCooldown(spellID)
                end
                entries[#entries + 1] = {
                    spellID = displayID,
                    baseSpellID = displayID ~= spellID and spellID or nil,
                    name = GetSpellName(displayID),
                    baseDuration = base,
                }
            end
        end
    end
    self.entries = entries
end

function tracker:CreateSlot()
    local slot = CreateFrame("Frame", nil, self.frame.textOverlay)
    slot.name = slot:CreateFontString(nil, "OVERLAY")
    slot.name:SetFontObject(GameFontNormal)
    slot.name:SetTextColor(1, 1, 1)

    -- Blizzard draws the countdown number, so secret combat timings still
    -- render; only the number is kept.
    slot.cooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
    slot.cooldown:SetDrawSwipe(false)
    slot.cooldown:SetDrawEdge(false)
    if slot.cooldown.SetDrawBling then
        slot.cooldown:SetDrawBling(false)
    end
    slot.cooldown:SetHideCountdownNumbers(false)
    -- Blizzard hides countdown text on short cooldowns by default.
    if slot.cooldown.SetMinimumCountdownDuration then
        slot.cooldown:SetMinimumCountdownDuration(0)
    end
    -- Print 90 rather than 1:30.
    if slot.cooldown.SetCountdownAbbrevThreshold then
        slot.cooldown:SetCountdownAbbrevThreshold(0)
    end
    if slot.cooldown.GetCountdownFontString then
        slot.countdownText = slot.cooldown:GetCountdownFontString()
    end
    slot.cooldown:SetScript("OnCooldownDone", function()
        self:RequestUpdate()
    end)
    slot:Hide()
    return slot
end

function tracker:GetSlot(index)
    if not self.slots[index] then
        self.slots[index] = self:CreateSlot()
        self:StyleSlot(self.slots[index])
    end
    return self.slots[index]
end

function tracker:StyleSlot(slot)
    local settings = BBR:GetTrackerSettings(self.key)
    local textSize = settings.size
    local font = GameFontNormal:GetFont()
    local alignment = settings.textAlignment == "RIGHT" and "RIGHT" or "LEFT"
    local showName = settings.showName == true
    local gap = math.max(3, textSize * 0.25)
    local rowHeight = math.max(20, textSize * 1.6)

    slot:SetSize(self.frame:GetWidth(), rowHeight)
    slot.name:SetFont(font, textSize, "OUTLINE")
    slot.name:SetShown(showName)
    if slot.countdownText then
        slot.countdownText:SetFont(font, textSize, "OUTLINE")
        slot.countdownText:SetTextColor(1, 1, 1)
    end
    if slot.cooldown.SetCountdownMillisecondsThreshold then
        slot.cooldown:SetCountdownMillisecondsThreshold(settings.showDecimals and 86400 or 0)
    end

    slot.name:ClearAllPoints()
    slot.cooldown:ClearAllPoints()
    slot.cooldown:SetSize(textSize * 3.4, rowHeight)
    if slot.countdownText then
        slot.countdownText:ClearAllPoints()
        slot.countdownText:SetJustifyH(alignment)
        slot.countdownText:SetPoint(alignment, slot.cooldown, alignment, 0, 0)
    end

    if alignment == "RIGHT" then
        slot.cooldown:SetPoint("RIGHT", slot, "RIGHT", 0, 0)
        slot.name:SetPoint("RIGHT", slot.cooldown, "LEFT", -gap, 0)
        slot.name:SetJustifyH("RIGHT")
    elseif showName then
        slot.name:SetPoint("LEFT", slot, "LEFT", 0, 0)
        slot.name:SetJustifyH("LEFT")
        slot.cooldown:SetPoint("LEFT", slot.name, "RIGHT", gap, 0)
    else
        slot.cooldown:SetPoint("LEFT", slot, "LEFT", 0, 0)
    end
end

-- Returns true when the slot was bound to an active cooldown.
function tracker:ShowSlot(slot, entry, cooldownInfo, duration)
    local fromDuration = false
    local secret = false

    if duration then
        local remaining, total = duration:GetRemainingDuration(), duration:GetTotalDuration()
        if IsSecret(remaining) or IsSecret(total) then
            secret = true
            fromDuration = true
        elseif IsReadableNumber(total) and total > 1.5 and not IsLockoutWindow(entry, total)
            and IsReadableNumber(remaining) and remaining > 0
        then
            fromDuration = true
        end
    end

    local startTime, cooldownDuration, modRate
    if not fromDuration then
        if not cooldownInfo then
            return false
        end
        local readableStart = IsReadableNumber(cooldownInfo.startTime)
        local readableDuration = IsReadableNumber(cooldownInfo.duration)
        if not (readableStart and readableDuration) then
            -- Only a duration object can carry a secret cooldown to the widget.
            return false
        end
        startTime, cooldownDuration = cooldownInfo.startTime, cooldownInfo.duration
        modRate = IsReadableNumber(cooldownInfo.modRate) and cooldownInfo.modRate or 1
        if cooldownDuration <= 0 or IsLockoutWindow(entry, cooldownDuration)
            or (startTime + cooldownDuration) - GetTime() <= 0
        then
            return false
        end
    end

    slot.name:SetText(entry.name)
    if fromDuration and slot.cooldown.SetCooldownFromDurationObject then
        slot.cooldown:SetCooldownFromDurationObject(duration)
    elseif fromDuration then
        if secret then
            return false
        end
        slot.cooldown:SetCooldown(duration:GetStartTime(), duration:GetTotalDuration(), duration:GetModRate())
    else
        slot.cooldown:SetCooldown(startTime, cooldownDuration, modRate)
    end
    slot:Show()
    return true
end

local function GetCooldownDuration(spellID, isCharge)
    local duration
    if isCharge and C_Spell.GetSpellChargeDuration then
        duration = C_Spell.GetSpellChargeDuration(spellID)
    elseif C_Spell.GetSpellCooldownDuration then
        -- ignoreGCD: otherwise a running GCD replaces the spell's own cooldown.
        duration = C_Spell.GetSpellCooldownDuration(spellID, true)
    end
    if not duration then
        if isCharge and C_Spell.GetSpellCooldownDuration then
            duration = C_Spell.GetSpellCooldownDuration(spellID, true)
        elseif C_Spell.GetSpellChargeDuration then
            duration = C_Spell.GetSpellChargeDuration(spellID)
        end
    end
    return duration
end

function tracker:HideSlots(fromIndex)
    for index = fromIndex, #self.slots do
        local slot = self.slots[index]
        slot.cooldown:SetCooldown(0, 0)
        slot:Hide()
    end
end

function tracker:Update()
    if not self.frame then
        return
    end

    local settings = BBR:GetTrackerSettings(self.key)
    local count = 0
    local combatAllowed = not settings.combatOnly or self.inCombat
    if settings.enabled and combatAllowed and C_Spell then
        for _, entry in ipairs(self.entries) do
            local spellID = entry.baseSpellID or entry.spellID
            local chargeInfo = C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(spellID)
            local cooldownInfo = C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID)
            local isOnGCD = cooldownInfo and cooldownInfo.isOnGCD
            if IsSecret(isOnGCD) then
                isOnGCD = nil
            end
            if cooldownInfo and (isOnGCD == false or (isOnGCD == nil and not chargeInfo)) then
                local maxCharges = chargeInfo and chargeInfo.maxCharges
                local isCharge = IsReadableNumber(maxCharges) and maxCharges > 1
                local duration = GetCooldownDuration(spellID, isCharge)
                local slot = self:GetSlot(count + 1)
                if self:ShowSlot(slot, entry, cooldownInfo, duration) then
                    count = count + 1
                    ApplyVisibility(slot, spellID, chargeInfo, entry, duration)
                end
            end
        end
    end

    self:HideSlots(count + 1)
    self.activeSlotCount = count
    self:LayoutSlots()
    BBR:SetTrackerConditionVisible(self, count > 0)
end

function tracker:LayoutSlots()
    local settings = BBR:GetTrackerSettings(self.key)
    local rowHeight = math.max(20, settings.size * 1.6)
    for index = 1, self.activeSlotCount do
        local slot = self.slots[index]
        slot:ClearAllPoints()
        slot:SetPoint("TOP", self.frame, "TOP", 0, -(index - 1) * rowHeight)
    end
end

function tracker:RequestUpdate()
    if self.updateFrame then
        self.updateFrame:Show()
    end
end

function tracker:SetEventsRegistered(registered)
    if registered == self.eventsRegistered then
        return
    end
    self.eventsRegistered = registered
    local events = {
        "PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE",
        "TRAIT_CONFIG_UPDATED", "SPELLS_CHANGED", "UPDATE_SHAPESHIFT_FORM",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES",
    }
    for _, event in ipairs(events) do
        if registered then
            self.eventFrame:RegisterEvent(event)
        else
            self.eventFrame:UnregisterEvent(event)
        end
    end
    if registered then
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    else
        self.eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
end

function tracker:OnEvent(event)
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE"
        or event == "TRAIT_CONFIG_UPDATED" or event == "SPELLS_CHANGED"
    then
        if not InCombatLockdown() then
            self:CacheSpells()
        end
        self:RequestUpdate()
        if BBR.RefreshConfig then
            BBR:RefreshConfig()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORM" then
        self.inCombat = UnitAffectingCombat and UnitAffectingCombat("player") or false
        self:CacheSpells()
        self:RequestUpdate()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self.inCombat = true
        self:RequestUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.inCombat = false
        self:CacheSpells()
        self:RequestUpdate()
    else
        self:RequestUpdate()
    end
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, "Interface\\Icons\\Ability_Rogue_Sprint")
    self.frame.background:Hide()
    self.frame.icon:Hide()
    self.frame.cooldown:Hide()
    self.frame.border:Hide()
    self.frame.label:Hide()
    self.frame.detail:Hide()
    self.frame.value:Hide()
    self.conditionVisible = false

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        self:OnEvent(event)
    end)

    -- Cooldown and charge events arrive in bursts; coalesce them into one
    -- update on the next frame.
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:Hide()
    self.updateFrame:SetScript("OnUpdate", function(frame)
        frame:Hide()
        self:Update()
    end)

    self.inCombat = InCombatLockdown()
    self:OnEnabledChanged(BBR:GetTrackerSettings(self.key).enabled)
end

function tracker:ApplySettings()
    BBR:ApplyTrackerFrameSettings(self)
    local settings = BBR:GetTrackerSettings(self.key)
    local textSize = settings.size
    local width = textSize * (settings.showName and 12 or 5)

    self.frame:SetSize(width, math.max(20, textSize * 1.6))
    self.frame.background:Hide()
    self.frame.icon:Hide()
    self.frame.cooldown:Hide()
    self.frame.border:Hide()
    self.frame.label:Hide()
    self.frame.detail:Hide()
    self.frame.value:Hide()

    for _, slot in ipairs(self.slots) do
        self:StyleSlot(slot)
    end
    self:Update()
end

function tracker:OnEnabledChanged(enabled)
    self:SetEventsRegistered(enabled == true)
    if enabled then
        self:CacheSpells()
    end
    self:Update()
end

function tracker:OnLockChanged()
    self:Update()
end

BBR:RegisterTracker("movementCooldown", tracker)
