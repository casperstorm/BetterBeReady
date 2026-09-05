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
        2825,   -- Bloodlust (Horde Shaman)
        32182,  -- Heroism (Alliance Shaman)
        80353,  -- Time Warp (Mage)
        390386, -- Fury of the Aspects (Evoker)
        466904, -- Harrier's Cry (Marksmanship Hunter)
    },
    bloodlustBuffSpellIDs = {
        2825,   -- Bloodlust
        32182,  -- Heroism
        80353,  -- Time Warp
        90355,  -- Ancient Hysteria
        146555, -- Drums of Rage
        160452, -- Netherwinds
        178207, -- Drums of Fury
        204276, -- Drums of Battle
        230935, -- Drums of the Mountain
        256740, -- Drums of the Maelstrom
        264667, -- Primal Rage
        272678, -- Drums of Battle variant
        275200, -- Drums of Battle variant
        292686, -- Drums of the Maelstrom variant
        309658, -- Drums of Deathly Ferocity
        381301, -- Feral Hide Drums
        390386, -- Fury of the Aspects
        441076, -- Timeless Drums
        444257, -- Thunderous Drums
        466904, -- Harrier's Cry
        1243972, -- Void-Touched Drums
    },
    hunterCommandPetSpellID = 272651,
    primalRageSpellID = 264667,
}

local function SetFontSize(fontString, size)
    local font = GameFontNormal:GetFont()
    fontString:SetFont(font, math.max(9, math.floor(size)), "OUTLINE")
end

local function HueToRGB(hue)
    local section = math.floor(hue * 6)
    local fraction = hue * 6 - section
    local inverse = 1 - fraction
    section = section % 6

    if section == 0 then return 1, fraction, 0 end
    if section == 1 then return inverse, 1, 0 end
    if section == 2 then return 0, 1, fraction end
    if section == 3 then return 0, inverse, 1 end
    if section == 4 then return fraction, 0, 1 end
    return 1, 0, inverse
end

function tracker:ApplyDisplayColor(red, green, blue, includeIcon)
    self.frame.value:SetTextColor(red, green, blue)
    self.frame.separator:SetTextColor(red, green, blue)
    self.frame.statusText:SetTextColor(red, green, blue)
    if self.frame.cooldown.GetCountdownFontString then
        local countdownFont = self.frame.cooldown:GetCountdownFontString()
        if countdownFont then
            countdownFont:SetTextColor(red, green, blue)
        end
    end
    if includeIcon then
        self.frame.icon:SetVertexColor(red, green, blue)
    end
end

function tracker:AdvanceActiveRainbow(elapsed)
    self.rainbowUpdateElapsed = (self.rainbowUpdateElapsed or 0) + (elapsed or 0)
    if self.rainbowUpdateElapsed < 0.03 then
        return
    end

    self.rainbowHue = ((self.rainbowHue or 0) + self.rainbowUpdateElapsed * 2.4) % 1
    self.rainbowUpdateElapsed = 0
    local red, green, blue = HueToRGB(self.rainbowHue)
    self:ApplyDisplayColor(red, green, blue, true)
end

function tracker:SetActiveRainbow(enabled)
    if enabled then
        if not self.rainbowActive then
            self.rainbowActive = true
            self.rainbowHue = 0
            self.rainbowUpdateElapsed = 0
            self.frame:SetScript("OnUpdate", function(_, elapsed)
                self:AdvanceActiveRainbow(elapsed)
            end)
        end
        local red, green, blue = HueToRGB(self.rainbowHue or 0)
        self:ApplyDisplayColor(red, green, blue, true)
    elseif self.rainbowActive then
        self.rainbowActive = false
        self.frame:SetScript("OnUpdate", nil)
    end
end

function tracker:StopBloodlustMusic()
    if self.musicSoundHandle and StopSound then
        pcall(StopSound, self.musicSoundHandle)
    end
    self.musicSoundHandle = nil
    self.musicTrackPlaying = nil
end

function tracker:StartBloodlustMusic()
    if BBR.nativeBloodlustMusicAuraSoundActive then
        return
    end

    local settings = BBR:GetTrackerSettings(self.key)
    if not (settings and settings.musicEnabled and settings.musicTrack ~= "") then
        return
    end

    local track = BBR:GetBloodlustMusicTrack(settings.musicTrack)
    if not (track and PlaySoundFile) then
        return
    end

    local soundPath = "Interface\\AddOns\\BetterBeReady\\Media\\BloodlustMusic\\" .. track.id
    local callOK, played, soundHandle = pcall(PlaySoundFile, soundPath, "Master")
    if callOK and played then
        self.musicSoundHandle = soundHandle
        self.musicTrackPlaying = track.id
    end
end

function tracker:SetBloodlustMusicActive(active)
    if active then
        if self.musicAuraActive then
            return
        end
        self.musicAuraActive = true
        self:StartBloodlustMusic()
    else
        self.musicAuraActive = false
        self:StopBloodlustMusic()
    end
end

function tracker:OnMusicSelectionChanged()
    self:StopBloodlustMusic()
    if self.status == "ACTIVE" then
        self.musicAuraActive = true
        self:StartBloodlustMusic()
    end
end

function tracker:OnMusicEnabledChanged(enabled)
    if not enabled then
        self:SetBloodlustMusicActive(false)
    elseif self.status == "ACTIVE" then
        self.musicAuraActive = false
        self:SetBloodlustMusicActive(true)
    end
end

function tracker:RefreshTextStatus()
    if not (self.frame and self.frame.statusText) then
        return
    end

    local settings = BBR:GetTrackerSettings(self.key)
    local textMode = settings and settings.textMode == true
    local bloodlustActive = self.status == "ACTIVE"
    self.frame.value:SetText(bloodlustActive and "BL ACTIVE" or "BL")
    self.frame.value:SetShown(textMode)
    self.frame.separator:SetShown(textMode)

    local text
    if bloodlustActive then
        if self.cooldownActive ~= true then
            text = "ACTIVE"
        end
    elseif self.status == "READY" then
        if self.cooldownActive == false then
            text = "READY"
        elseif self.cooldownActive == nil then
            text = "?"
        end
    elseif self.status == "LOCKED" then
        if self.cooldownActive ~= true then
            text = "WAIT"
        end
    elseif self.status == "UNAVAILABLE" then
        text = "-"
    else
        text = "?"
    end
    self.frame.statusText:SetText(text or "")
    self.frame.statusText:SetShown(textMode and text ~= nil)

    if bloodlustActive then
        self:SetActiveRainbow(true)
    else
        self:SetActiveRainbow(false)
        local red, green, blue = 0.65, 0.65, 0.65
        if self.status == "LOCKED" then
            red, green, blue = 1, 0.3, 0.3
        elseif self.status == "READY" and self.cooldownActive == false then
            red, green, blue = 0.35, 1, 0.4
        elseif self.status == "READY" and self.cooldownActive == true then
            red, green, blue = 1, 0.82, 0.25
        end
        self:ApplyDisplayColor(red, green, blue, false)
    end
end

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

function tracker:FindPrimalRagePetActionSlot()
    self.primalRagePetActionSlot = nil
    if not GetPetActionInfo then
        return nil
    end

    for slot = 1, (_G.NUM_PET_ACTION_SLOTS or 10) do
        local ok, name, _, _, _, _, _, spellID = pcall(GetPetActionInfo, slot)
        if ok and self:IsPrimalRageSpell(spellID, name) then
            self.primalRagePetActionSlot = slot
            return slot
        end
    end

    return nil
end

function tracker:FindPrimalRageSpell()
    self:FindPrimalRagePetActionSlot()

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
        "BetterBeReady BL: spellID=%s, petActionSlot=%s, available=%s, status=%s, cooldownActive=%s",
        tostring(self.spellID),
        tostring(self.primalRagePetActionSlot),
        tostring(self.spellAvailable),
        tostring(self.status),
        tostring(self.cooldownActive)
    ))
end

function tracker:ApplySpellCooldownInfo(cooldownInfo)
    -- isActive is NeverSecret in SpellCooldownInfo, so this remains safe while
    -- the timing fields are passed directly to Blizzard's cooldown widget.
    local isActive, activeReadable = BBR:GetReadableField(cooldownInfo, "isActive")
    if not activeReadable or type(isActive) ~= "boolean" then
        return false
    end

    self.cooldownActive = isActive
    if not isActive then
        BBR:ClearTrackerCooldown(self)
        return true
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
    return true
end

function tracker:ApplyPetActionCooldown()
    local slot = self.primalRagePetActionSlot
    if not (slot and GetPetActionCooldown) then
        return false
    end

    local ok, startTime, duration = pcall(GetPetActionCooldown, slot)
    if not ok
        or BBR:IsSecretValue(startTime)
        or BBR:IsSecretValue(duration)
        or type(startTime) ~= "number"
        or type(duration) ~= "number"
    then
        return false
    end

    self.cooldownActive = startTime > 0 and duration > 0
    if self.cooldownActive then
        local applied = pcall(function()
            self.frame.cooldown:SetCooldown(startTime, duration)
        end)
        if not applied then
            BBR:ClearTrackerCooldown(self)
        end
    else
        BBR:ClearTrackerCooldown(self)
    end
    return true
end

function tracker:SetSpellCooldown()
    if C_Spell and C_Spell.GetSpellCooldown then
        local spellIDs = { self.spellID }
        if self:IsPrimalRageSpell(self.spellID, self:GetSpellName(self.spellID)) then
            spellIDs[#spellIDs + 1] = self.hunterCommandPetSpellID
        end

        for _, spellID in ipairs(spellIDs) do
            local ok, cooldownInfo = pcall(C_Spell.GetSpellCooldown, spellID)
            if ok and cooldownInfo and self:ApplySpellCooldownInfo(cooldownInfo) then
                return
            end
        end
    end

    if self:ApplyPetActionCooldown() then
        return
    end

    self.cooldownActive = nil
    BBR:ClearTrackerCooldown(self)
end

function tracker:SetLockoutCooldown(aura)
    local duration, durationReadable = BBR:GetReadableField(aura, "duration")
    local expirationTime, expirationReadable = BBR:GetReadableField(aura, "expirationTime")

    if durationReadable and expirationReadable
        and type(duration) == "number"
        and type(expirationTime) == "number"
        and duration > 0
    then
        self.cooldownActive = true
        self.frame.cooldown:SetCooldown(expirationTime - duration, duration)
    else
        self.cooldownActive = nil
        BBR:ClearTrackerCooldown(self)
    end
end

function tracker:Update()
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        self.status = "UNKNOWN"
        self.cooldownActive = nil
        self.frame.icon:SetVertexColor(0.55, 0.55, 0.55)
        self.frame.detail:SetText("")
        BBR:ClearTrackerCooldown(self)
        self:SetBloodlustMusicActive(false)
        self:RefreshTextStatus()
        return
    end

    local activeAura, activeState = BBR:FindFirstAuraBySpellID(function(spellID)
        return C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    end, self.bloodlustBuffSpellIDs)

    if activeState == "LOCKED" then
        self.status = "ACTIVE"
        self.frame.icon:SetVertexColor(0.25, 1, 0.35)
        self.frame.detail:SetText("")
        self:SetLockoutCooldown(activeAura)
        self:SetBloodlustMusicActive(true)
        self:RefreshTextStatus()
        return
    end

    local aura, state = BBR:FindFirstAuraBySpellID(function(spellID)
        return C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    end, self.lockoutSpellIDs)

    if state == "READY" and activeState == "UNKNOWN" then
        state = "UNKNOWN"
    end

    if state == "LOCKED" then
        self.frame.icon:SetVertexColor(1, 0.22, 0.22)
        self.frame.detail:SetText("")
        self:SetLockoutCooldown(aura)
    elseif state == "READY" and self.spellAvailable then
        self.frame.icon:SetVertexColor(0.25, 1, 0.35)
        self.frame.detail:SetText("")
        self:SetSpellCooldown()
    elseif state == "READY" then
        state = "UNAVAILABLE"
        self.cooldownActive = false
        self.frame.icon:SetVertexColor(0.45, 0.45, 0.45)
        self.frame.detail:SetText("")
        BBR:ClearTrackerCooldown(self)
    else
        self.cooldownActive = nil
        self.frame.icon:SetVertexColor(0.65, 0.65, 0.65)
        self.frame.detail:SetText("")
        BBR:ClearTrackerCooldown(self)
    end

    self.status = state
    self:SetBloodlustMusicActive(false)
    self:RefreshTextStatus()
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, 136012)
    self.frame.cooldown:SetHideCountdownNumbers(false)
    self.frame.label:SetText("")
    self.frame.value:SetText("BL")

    self.frame.separator = self.frame.textOverlay:CreateFontString(nil, "OVERLAY")
    self.frame.separator:SetFontObject(GameFontNormal)
    self.frame.separator:SetText("|")
    self.frame.separator:Hide()

    self.frame.statusText = self.frame.textOverlay:CreateFontString(nil, "OVERLAY")
    self.frame.statusText:SetFontObject(GameFontNormal)
    self.frame.statusText:Hide()

    self:SelectBloodlustSpell()

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    self.eventFrame:RegisterUnitEvent("UNIT_PET", "player")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self.eventFrame:RegisterEvent("SPELLS_CHANGED")
    self.eventFrame:RegisterEvent("PET_BAR_UPDATE")
    self.eventFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "SPELLS_CHANGED"
            or event == "UNIT_PET"
            or event == "PET_BAR_UPDATE"
            or event == "PLAYER_ENTERING_WORLD"
        then
            self:SelectBloodlustSpell()
        end
        if event == "PLAYER_REGEN_ENABLED" and BBR.bloodlustMusicAuraSoundRefreshPending then
            BBR:RefreshBloodlustMusicAuraSounds()
        end
        self:Update()
    end)

    BBR:RefreshBloodlustMusicAuraSounds()
    self:Update()
end

function tracker:ApplySettings()
    BBR:ApplyTrackerFrameSettings(self)
    local settings = BBR:GetTrackerSettings(self.key)
    local textMode = settings.textMode == true

    self.frame.background:SetShown(not textMode)
    self.frame.icon:SetShown(not textMode)
    self.frame.border:SetShown(not textMode)
    self.frame.cooldown:ClearAllPoints()
    if self.frame.cooldown.SetDrawSwipe then
        self.frame.cooldown:SetDrawSwipe(not textMode)
    end
    BBR:SetMinuteSecondCountdownFormat(self.frame.cooldown, textMode)

    if textMode then
        local textSize = settings.textSize
        local inlineGap = math.max(3, textSize * 0.25)
        local alignment = settings.textAlignment == "RIGHT" and "RIGHT" or "LEFT"
        self.frame:SetSize(textSize * 13, math.max(20, textSize * 1.6))
        SetFontSize(self.frame.separator, textSize)
        SetFontSize(self.frame.statusText, textSize)

        self.frame.value:ClearAllPoints()
        self.frame.separator:ClearAllPoints()
        self.frame.statusText:ClearAllPoints()
        self.frame.cooldown:SetSize(textSize * 3.4, textSize * 1.5)
        if alignment == "RIGHT" then
            self.frame.cooldown:SetPoint("RIGHT", self.frame, "CENTER", textSize * 3, 0)
            self.frame.statusText:SetPoint("RIGHT", self.frame, "CENTER", textSize * 3, 0)
            self.frame.separator:SetPoint("RIGHT", self.frame.cooldown, "LEFT", -inlineGap, 0)
            self.frame.value:SetPoint("RIGHT", self.frame.separator, "LEFT", -inlineGap, 0)
            self.frame.statusText:SetJustifyH("RIGHT")
        else
            self.frame.value:SetPoint("LEFT", self.frame, "CENTER", -textSize * 2.1, 0)
            self.frame.separator:SetPoint("LEFT", self.frame.value, "RIGHT", inlineGap, 0)
            self.frame.cooldown:SetPoint("LEFT", self.frame.separator, "RIGHT", inlineGap, 0)
            self.frame.statusText:SetPoint("LEFT", self.frame.separator, "RIGHT", inlineGap, 0)
            self.frame.statusText:SetJustifyH("LEFT")
        end
    else
        self.frame.value:Hide()
        self.frame.separator:Hide()
        self.frame.statusText:Hide()
        self.frame.cooldown:SetAllPoints(self.frame)
    end
    self:RefreshTextStatus()
end

BBR:RegisterTracker("bloodlust", tracker)
