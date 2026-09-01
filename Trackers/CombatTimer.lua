local _, BBR = ...

local tracker = {
    active = false,
    encounterActive = false,
    elapsed = 0,
    minSize = 10,
    maxSize = 72,
}

function tracker:Start(isEncounter)
    if isEncounter or not self.active then
        self.startedAt = GetTime()
        self.elapsed = 0
    end
    self.active = true
    if isEncounter then
        self.encounterActive = true
    end
    BBR:SetTrackerConditionVisible(self, true)
end

function tracker:Stop(isEncounter)
    if isEncounter then
        self.encounterActive = false
    end
    if not self.encounterActive then
        self.active = false
        BBR:SetTrackerConditionVisible(self, false)
    end
end

function tracker:UpdateDisplay()
    if self.active and self.startedAt then
        self.elapsed = GetTime() - self.startedAt
    end
    self.frame.value:SetText(BBR:FormatDuration(self.elapsed, false))
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, "Interface\\Icons\\INV_Misc_PocketWatch_01")
    self.frame.label:SetText("")
    self.frame.detail:SetText("")
    self.frame.background:Hide()
    self.frame.icon:Hide()
    self.frame.cooldown:Hide()
    self.frame.border:Hide()
    self.frame.label:Hide()
    self.frame.detail:Hide()
    self.conditionVisible = false

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("ENCOUNTER_START")
    self.eventFrame:RegisterEvent("ENCOUNTER_END")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "ENCOUNTER_START" then
            self:Start(true)
        elseif event == "ENCOUNTER_END" then
            self:Stop(true)
        elseif event == "PLAYER_REGEN_DISABLED" then
            self:Start(false)
        elseif event == "PLAYER_REGEN_ENABLED" then
            self:Stop(false)
        end
        self:UpdateDisplay()
    end)

    self.frame:SetScript("OnUpdate", function(_, elapsed)
        if not self.active then
            return
        end

        self.updateAccumulator = (self.updateAccumulator or 0) + elapsed
        if self.updateAccumulator >= 0.1 then
            self.updateAccumulator = 0
            self:UpdateDisplay()
        end
    end)

    self:UpdateDisplay()
end

function tracker:ApplySettings()
    BBR:ApplyTrackerFrameSettings(self)
    local settings = BBR:GetTrackerSettings(self.key)
    local font = GameFontNormal:GetFont()
    self.frame:SetSize(settings.size * 4.5, settings.size * 1.5)
    self.frame.value:SetFont(font, settings.size, "OUTLINE")
    self.frame.background:Hide()
    self.frame.icon:Hide()
    self.frame.cooldown:Hide()
    self.frame.border:Hide()
    self.frame.label:Hide()
    self.frame.detail:Hide()
end

BBR:RegisterTracker("combatTimer", tracker)
