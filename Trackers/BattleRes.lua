local _, BBR = ...

local tracker = {
    spellID = 20484, -- Rebirth exposes the shared encounter battle-res charges.
}

function tracker:Update()
    if not (C_Spell and C_Spell.GetSpellCharges) then
        self.frame.value:SetText("?")
        BBR:ClearTrackerCooldown(self)
        return
    end

    local ok, chargeInfo = pcall(C_Spell.GetSpellCharges, self.spellID)
    if not ok or not chargeInfo then
        self.frame.value:SetText("-")
        BBR:ClearTrackerCooldown(self)
        return
    end

    -- These fields may be secret in combat. Pass them directly to Blizzard widgets;
    -- never compare them or perform arithmetic on them in Lua.
    local textApplied = pcall(function()
        self.frame.value:SetText(chargeInfo.currentCharges)
    end)
    if not textApplied then
        self.frame.value:SetText("?")
    end

    local cooldownApplied = pcall(function()
        self.frame.cooldown:SetCooldown(
            chargeInfo.cooldownStartTime,
            chargeInfo.cooldownDuration,
            chargeInfo.chargeModRate
        )
    end)
    if not cooldownApplied then
        BBR:ClearTrackerCooldown(self)
    end
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, 136080)
    self.frame.label:SetText("")
    self.frame.detail:SetText("")
    self.frame.value:ClearAllPoints()
    self.frame.value:SetPoint("BOTTOM", self.frame, "TOP", 0, 4)
    self.frame.value:SetJustifyH("CENTER")
    self.frame.value:SetJustifyV("BOTTOM")

    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, self.spellID)
        if ok and texture then
            self.frame.icon:SetTexture(texture)
        end
    end

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    self.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self.eventFrame:RegisterEvent("ENCOUNTER_START")
    self.eventFrame:RegisterEvent("ENCOUNTER_END")
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.eventFrame:SetScript("OnEvent", function()
        self:Update()
    end)

    self:Update()
end

function tracker:ApplySettings()
    BBR:ApplyTrackerFrameSettings(self)
    local settings = BBR:GetTrackerSettings(self.key)
    self.frame.cooldown:SetHideCountdownNumbers(not settings.showRechargeTime)
end

BBR:RegisterTracker("battleRes", tracker)
