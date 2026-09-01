local _, BBR = ...

local tracker = {
    spellID = 20484, -- Rebirth exposes the shared encounter battle-res charges.
}

local function SetFontSize(fontString, size)
    local font = GameFontNormal:GetFont()
    fontString:SetFont(font, math.max(9, math.floor(size)), "OUTLINE")
end

function tracker:RefreshRechargeFallback()
    if not self.frame or not self.frame.rechargeFallback then
        return
    end
    local settings = BBR:GetTrackerSettings(self.key)
    local shouldShow = settings
        and settings.textMode
        and settings.showRechargeTime
        and self.rechargeActive == false
    self.frame.rechargeFallback:SetShown(shouldShow)
end

function tracker:Update()
    if not (C_Spell and C_Spell.GetSpellCharges) then
        self.rechargeActive = false
        self.frame.value:SetText("?")
        BBR:ClearTrackerCooldown(self)
        self:RefreshRechargeFallback()
        return
    end

    local ok, chargeInfo = pcall(C_Spell.GetSpellCharges, self.spellID)
    if not ok or not chargeInfo then
        self.rechargeActive = false
        self.frame.value:SetText("-")
        BBR:ClearTrackerCooldown(self)
        self:RefreshRechargeFallback()
        return
    end

    -- isActive is explicitly NeverSecret in SpellChargeInfo. It is therefore
    -- safe to branch on while start/duration remain opaque and widget-driven.
    local isActive, activeReadable = BBR:GetReadableField(chargeInfo, "isActive")
    if activeReadable and type(isActive) == "boolean" then
        self.rechargeActive = isActive
    else
        self.rechargeActive = nil
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
    self:RefreshRechargeFallback()
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, 136080)
    self.frame.label:SetText("")
    self.frame.detail:SetText("")
    self.frame.value:ClearAllPoints()
    self.frame.value:SetPoint("BOTTOM", self.frame, "TOP", 0, 4)
    self.frame.value:SetJustifyH("CENTER")
    self.frame.value:SetJustifyV("BOTTOM")

    self.frame.separator = self.frame.textOverlay:CreateFontString(nil, "OVERLAY")
    self.frame.separator:SetFontObject(GameFontNormal)
    self.frame.separator:SetText("|")
    self.frame.separator:SetTextColor(1, 1, 1)
    self.frame.separator:Hide()

    self.frame.rechargeFallback = self.frame.textOverlay:CreateFontString(nil, "OVERLAY")
    self.frame.rechargeFallback:SetFontObject(GameFontNormal)
    self.frame.rechargeFallback:SetText("-")
    self.frame.rechargeFallback:SetTextColor(1, 1, 1)
    self.frame.rechargeFallback:Hide()

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
    local textMode = settings.textMode == true
    local showRechargeTime = settings.showRechargeTime == true

    self.frame.background:SetShown(not textMode)
    self.frame.icon:SetShown(not textMode)
    self.frame.border:SetShown(not textMode)

    self.frame.value:ClearAllPoints()
    self.frame.cooldown:ClearAllPoints()
    self.frame.cooldown:SetShown(not textMode or showRechargeTime)
    if self.frame.cooldown.SetDrawSwipe then
        self.frame.cooldown:SetDrawSwipe(not textMode)
    end
    BBR:SetMinuteSecondCountdownFormat(self.frame.cooldown, textMode)
    self.frame.cooldown:SetHideCountdownNumbers(not settings.showRechargeTime)

    if textMode then
        local textSize = settings.textSize
        local inlineGap = math.max(3, textSize * 0.25)
        local alignment = settings.textAlignment == "RIGHT" and "RIGHT" or "LEFT"
        self.frame:SetSize(textSize * 7, math.max(20, textSize * 1.6))
        self.frame.separator:SetShown(showRechargeTime)
        SetFontSize(self.frame.separator, textSize)
        SetFontSize(self.frame.rechargeFallback, textSize)

        if showRechargeTime then
            self.frame.separator:ClearAllPoints()
            self.frame.rechargeFallback:ClearAllPoints()
            self.frame.cooldown:SetSize(textSize * 3.4, textSize * 1.5)
            if alignment == "RIGHT" then
                self.frame.cooldown:SetPoint("RIGHT", self.frame, "CENTER", textSize * 2.65, 0)
                self.frame.rechargeFallback:SetPoint(
                    "RIGHT",
                    self.frame,
                    "CENTER",
                    textSize * 2.65,
                    0
                )
                self.frame.separator:SetPoint("RIGHT", self.frame.cooldown, "LEFT", -inlineGap, 0)
                self.frame.value:SetPoint("RIGHT", self.frame.separator, "LEFT", -inlineGap, 0)
                self.frame.rechargeFallback:SetJustifyH("RIGHT")
            else
                self.frame.value:SetPoint("LEFT", self.frame, "CENTER", -textSize * 2, 0)
                self.frame.separator:SetPoint("LEFT", self.frame.value, "RIGHT", inlineGap, 0)
                self.frame.cooldown:SetPoint("LEFT", self.frame.separator, "RIGHT", inlineGap, 0)
                self.frame.rechargeFallback:SetPoint("LEFT", self.frame.separator, "RIGHT", inlineGap, 0)
                self.frame.rechargeFallback:SetJustifyH("LEFT")
            end
        else
            self.frame.value:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
        end
    else
        self.frame.separator:Hide()
        self.frame.value:SetPoint("BOTTOM", self.frame, "TOP", 0, 4)
        self.frame.cooldown:SetAllPoints(self.frame)
    end
    self:RefreshRechargeFallback()
end

BBR:RegisterTracker("battleRes", tracker)
