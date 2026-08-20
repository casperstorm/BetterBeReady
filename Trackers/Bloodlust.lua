local _, BBR = ...

local tracker = {
    lockoutSpellIDs = {
        57724,  -- Sated
        57723,  -- Exhaustion
        80354,  -- Temporal Displacement
        160455, -- Fatigued
        95809,  -- Insanity
        390435, -- Exhaustion variant
        264689, -- Fatigued variant
    },
    bloodlustSpellIDs = {
        2825,  -- Bloodlust
        32182, -- Heroism
    },
    hunterCommandPetSpellID = 272651,
    primalRageSpellID = 264667,
}

function tracker:GetSpellName(spellID)
    if not (spellID and C_Spell and C_Spell.GetSpellName) then
        return nil
    end

    local ok, name = pcall(C_Spell.GetSpellName, spellID)
    return ok and name or nil
end

function tracker:IsPrimalRageSpell(spellID, spellName)
    if spellID == self.primalRageSpellID then
        return true
    end

    local primalRageName = self:GetSpellName(self.primalRageSpellID)
    return primalRageName and spellName == primalRageName
end

function tracker:FindPrimalRageSpell()
    -- Command Pet's live override reliably tells us whether the active Hunter
    -- pet provides Primal Rage, even when the pet spellbook query is stale.
    if C_Spell and C_Spell.GetOverrideSpell then
        local ok, overrideSpellID = pcall(C_Spell.GetOverrideSpell, self.hunterCommandPetSpellID)
        if ok and overrideSpellID
            and self:IsPrimalRageSpell(overrideSpellID, self:GetSpellName(overrideSpellID))
        then
            return overrideSpellID
        end
    end

    if not (C_SpellBook and Enum and Enum.SpellBookSpellBank) then
        return nil
    end

    local playerBank = Enum.SpellBookSpellBank.Player
    local petBank = Enum.SpellBookSpellBank.Pet
    if C_SpellBook.IsSpellInSpellBook then
        for _, spellBank in ipairs({ playerBank, petBank }) do
            local ok, known = pcall(
                C_SpellBook.IsSpellInSpellBook,
                self.primalRageSpellID,
                spellBank,
                true
            )
            if ok and known then
                return self.primalRageSpellID
            end
        end
    end

    -- Fallback for clients where the direct known-spell query misses pet
    -- actions: scan the small pet bank and compare the localized spell name.
    if C_SpellBook.HasPetSpells and C_SpellBook.GetSpellBookItemInfo then
        local countOK, count = pcall(C_SpellBook.HasPetSpells)
        if countOK and type(count) == "number" then
            for slot = 1, count do
                local infoOK, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, petBank)
                if infoOK and info then
                    local spellID = info.spellID or info.actionID
                    if self:IsPrimalRageSpell(spellID, info.name) then
                        return spellID or self.primalRageSpellID
                    end
                end
            end
        end
    end

    return nil
end

function tracker:SelectBloodlustSpell()
    self.spellID = nil
    if _G.IsPlayerSpell then
        for _, spellID in ipairs(self.bloodlustSpellIDs) do
            local ok, known = pcall(_G.IsPlayerSpell, spellID)
            if ok and known then
                self.spellID = spellID
                break
            end
        end
    end

    if not self.spellID then
        local primalRageSpellID = self:FindPrimalRageSpell()
        if primalRageSpellID then
            self.spellID = primalRageSpellID
        end
    end

    self.spellAvailable = self.spellID ~= nil

    if self.spellID and C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, self.spellID)
        if ok and texture then
            self.frame.icon:SetTexture(texture)
        end
    end

end

function tracker:PrintDebug()
    print(string.format(
        "BetterBeReady BL: spellID=%s, available=%s, status=%s",
        tostring(self.spellID),
        tostring(self.spellAvailable),
        tostring(self.status)
    ))
end

function tracker:SetSpellCooldown()
    if not (C_Spell and C_Spell.GetSpellCooldown) then
        BBR:ClearTrackerCooldown(self)
        return
    end

    local ok, cooldownInfo = pcall(C_Spell.GetSpellCooldown, self.spellID)
    if not ok or not cooldownInfo then
        BBR:ClearTrackerCooldown(self)
        return
    end

    local applied = pcall(function()
        self.frame.cooldown:SetCooldown(
            cooldownInfo.startTime,
            cooldownInfo.duration,
            cooldownInfo.modRate
        )
    end)
    if not applied then
        BBR:ClearTrackerCooldown(self)
    end
end

function tracker:SetLockoutCooldown(aura)
    local duration, durationReadable = BBR:GetReadableField(aura, "duration")
    local expirationTime, expirationReadable = BBR:GetReadableField(aura, "expirationTime")

    if durationReadable and expirationReadable
        and type(duration) == "number"
        and type(expirationTime) == "number"
        and duration > 0
    then
        self.frame.cooldown:SetCooldown(expirationTime - duration, duration)
    else
        BBR:ClearTrackerCooldown(self)
    end
end

function tracker:Update()
    if not self.spellAvailable then
        self.status = "UNAVAILABLE"
        self.frame.icon:SetVertexColor(0.45, 0.45, 0.45)
        self.frame.detail:SetText("")
        BBR:ClearTrackerCooldown(self)
        return
    end

    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        self.status = "UNKNOWN"
        self.frame.icon:SetVertexColor(0.55, 0.55, 0.55)
        self.frame.detail:SetText("")
        BBR:ClearTrackerCooldown(self)
        return
    end

    local aura, state = BBR:FindFirstAuraBySpellID(function(spellID)
        return C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    end, self.lockoutSpellIDs)

    if state == "LOCKED" then
        self.frame.icon:SetVertexColor(1, 0.22, 0.22)
        self.frame.detail:SetText("")
        self:SetLockoutCooldown(aura)
    elseif state == "READY" then
        self.frame.icon:SetVertexColor(0.25, 1, 0.35)
        self.frame.detail:SetText("")
        self:SetSpellCooldown()
    else
        self.frame.icon:SetVertexColor(0.65, 0.65, 0.65)
        self.frame.detail:SetText("")
        BBR:ClearTrackerCooldown(self)
    end

    self.status = state
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, 136012)
    self.frame.cooldown:SetHideCountdownNumbers(false)
    self.frame.label:SetText("")
    self.frame.value:SetText("")

    self:SelectBloodlustSpell()

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    self.eventFrame:RegisterUnitEvent("UNIT_PET", "player")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self.eventFrame:RegisterEvent("SPELLS_CHANGED")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "SPELLS_CHANGED" or event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then
            self:SelectBloodlustSpell()
        end
        self:Update()
    end)

    self:Update()
end

function tracker:ApplySettings()
    BBR:ApplyTrackerFrameSettings(self)
end

BBR:RegisterTracker("bloodlust", tracker)
