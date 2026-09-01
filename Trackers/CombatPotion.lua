local _, BBR = ...

local tracker = {
    minSize = 8,
    maxSize = 32,

    -- Midnight combat potions. Each family includes crafted quality variants
    -- and its corresponding fleeting cauldron variants where available.
    potionItemIDs = {
        245897, 245898, 241308, 241309, -- Light's Potential
        245902, 245903, 241288, 241289, -- Potion of Recklessness
        245910, 245911, 241292, 241293, -- Draught of Rampant Abandon
        245900, 245901, 241296, 241297, -- Potion of Zealotry
        274763, 274764, 271886, 271887, -- Liquid Luster
        274765, 274766, 271889, 271890, -- Alluring Nostrum
    },
}

local function SetFontSize(fontString, size)
    local font = GameFontNormal:GetFont()
    fontString:SetFont(font, math.max(9, math.floor(size)), "OUTLINE")
end

local function IsReadableNumber(value)
    if type(value) ~= "number" or BBR:IsSecretValue(value) then
        return false
    end

    if _G.canaccessvalue then
        local ok, accessible = pcall(_G.canaccessvalue, value)
        if ok and accessible == false then
            return false
        end
    end
    return true
end

function tracker:GetItemCount(itemID)
    if not (C_Item and C_Item.GetItemCount) then
        return nil
    end

    local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false, false)
    if not ok or not IsReadableNumber(count) then
        return nil
    end
    return count
end

function tracker:GetItemCooldown(itemID)
    if not (C_Item and C_Item.GetItemCooldown) then
        return nil
    end

    local ok, startTime, duration, enabled = pcall(C_Item.GetItemCooldown, itemID)
    if not ok or not IsReadableNumber(startTime) or not IsReadableNumber(duration) then
        return nil
    end
    if BBR:IsSecretValue(enabled) then
        return nil
    end

    return {
        startTime = startTime,
        duration = duration,
        enabled = enabled,
    }
end

function tracker:RefreshTextStatus()
    local settings = BBR:GetTrackerSettings(self.key)
    if not (settings and self.frame) then
        return
    end

    self.frame.value:SetText("POT")
    self.frame.value:Show()
    self.frame.separator:Show()

    local statusText
    local red, green, blue = 0.65, 0.65, 0.65
    if self.status == "READY" then
        statusText = "READY"
        red, green, blue = 0.35, 1, 0.4
    elseif self.status == "COOLDOWN" then
        red, green, blue = 1, 0.3, 0.3
    elseif self.status == "UNAVAILABLE" then
        statusText = "-"
    else
        statusText = "?"
    end

    self.frame.value:SetTextColor(red, green, blue)
    self.frame.separator:SetTextColor(red, green, blue)
    self.frame.statusText:SetText(statusText or "")
    self.frame.statusText:SetTextColor(red, green, blue)
    self.frame.statusText:SetShown(statusText ~= nil)
    if self.frame.cooldown.GetCountdownFontString then
        local countdownFont = self.frame.cooldown:GetCountdownFontString()
        if countdownFont then
            countdownFont:SetTextColor(red, green, blue)
        end
    end
end

function tracker:Update()
    if not (C_Item and C_Item.GetItemCount and C_Item.GetItemCooldown) then
        self.status = "UNKNOWN"
        BBR:ClearTrackerCooldown(self)
        self:RefreshTextStatus()
        return
    end

    local ownedItemIDs = {}
    for _, itemID in ipairs(self.potionItemIDs) do
        local count = self:GetItemCount(itemID)
        if count and count > 0 then
            ownedItemIDs[#ownedItemIDs + 1] = itemID
            self.lastSeenItemID = itemID
        end
    end

    local candidates = {}
    local candidateSet = {}
    if self.lastSeenItemID then
        candidates[#candidates + 1] = self.lastSeenItemID
        candidateSet[self.lastSeenItemID] = true
    end
    for _, itemID in ipairs(ownedItemIDs) do
        if not candidateSet[itemID] then
            candidates[#candidates + 1] = itemID
            candidateSet[itemID] = true
        end
    end

    local cooldownReadable = false
    local now = GetTime and GetTime() or 0
    for _, itemID in ipairs(candidates) do
        local cooldown = self:GetItemCooldown(itemID)
        if cooldown then
            cooldownReadable = true
            local expirationTime = cooldown.startTime + cooldown.duration
            if cooldown.startTime > 0
                and cooldown.duration > 2
                and expirationTime > now
                and cooldown.enabled ~= false
            then
                self.status = "COOLDOWN"
                self.cooldownItemID = itemID
                self.frame.cooldown:SetCooldown(cooldown.startTime, cooldown.duration)
                self:RefreshTextStatus()
                return
            end
        end
    end

    BBR:ClearTrackerCooldown(self)
    self.cooldownItemID = nil
    if #ownedItemIDs > 0 then
        self.status = cooldownReadable and "READY" or "UNKNOWN"
    else
        self.status = "UNAVAILABLE"
    end
    self:RefreshTextStatus()
end

function tracker:PrintDebug()
    print(string.format(
        "BetterBeReady POT: lastItemID=%s, cooldownItemID=%s, status=%s",
        tostring(self.lastSeenItemID),
        tostring(self.cooldownItemID),
        tostring(self.status)
    ))
end

function tracker:Create()
    BBR:CreateTrackerFrame(self, 134712)
    self.frame.label:SetText("")
    self.frame.value:SetText("POT")
    self.frame.cooldown:SetHideCountdownNumbers(false)
    self.frame.cooldown:SetScript("OnCooldownDone", function()
        self:Update()
    end)

    self.frame.separator = self.frame.textOverlay:CreateFontString(nil, "OVERLAY")
    self.frame.separator:SetFontObject(GameFontNormal)
    self.frame.separator:SetText("|")

    self.frame.statusText = self.frame.textOverlay:CreateFontString(nil, "OVERLAY")
    self.frame.statusText:SetFontObject(GameFontNormal)

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self.eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:SetScript("OnEvent", function()
        self:Update()
    end)

    self:Update()
end

function tracker:ApplySettings()
    BBR:ApplyTrackerFrameSettings(self)
    local settings = BBR:GetTrackerSettings(self.key)
    local textSize = settings.size
    local inlineGap = math.max(3, textSize * 0.25)
    local alignment = settings.textAlignment == "RIGHT" and "RIGHT" or "LEFT"

    self.frame:SetSize(textSize * 10, math.max(20, textSize * 1.6))
    self.frame.background:Hide()
    self.frame.icon:Hide()
    self.frame.border:Hide()
    self.frame.detail:Hide()
    self.frame.cooldown:SetDrawSwipe(false)
    BBR:SetMinuteSecondCountdownFormat(self.frame.cooldown, true)

    SetFontSize(self.frame.value, textSize)
    SetFontSize(self.frame.separator, textSize)
    SetFontSize(self.frame.statusText, textSize)
    if self.frame.cooldown.GetCountdownFontString then
        local countdownFont = self.frame.cooldown:GetCountdownFontString()
        if countdownFont then
            SetFontSize(countdownFont, textSize)
        end
    end

    self.frame.value:ClearAllPoints()
    self.frame.separator:ClearAllPoints()
    self.frame.statusText:ClearAllPoints()
    self.frame.cooldown:ClearAllPoints()
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

    self:RefreshTextStatus()
end

function tracker:OnEnabledChanged(enabled)
    if enabled then
        self:Update()
    end
end

BBR:RegisterTracker("combatPotion", tracker)
