local _, BBR = ...

local TRACKER_ROWS = {
    {
        key = "bloodlust",
        title = "Bloodlust",
        minSize = 32,
        maxSize = 128,
        sizeLabel = "Icon size",
        hasTextSize = true,
        hasTextMode = true,
        allowLabel = false,
    },
    {
        key = "battleRes",
        title = "Battle res",
        minSize = 32,
        maxSize = 128,
        sizeLabel = "Icon size",
        hasTextSize = true,
        hasRechargeTime = true,
        hasTextMode = true,
        allowLabel = false,
    },
    { key = "combatTimer", title = "Combat timer", minSize = 10, maxSize = 72, sizeLabel = "Text size", allowLabel = false },
}

local function CreateCheckbox(parent, label, x, y, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox.Text:SetText(label)
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked())
    end)
    return checkbox
end

local function CreateSizeSlider(parent, name, x, y, minimum, maximum, sizeLabel, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(180)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText(tostring(minimum))
    _G[name .. "High"]:SetText(tostring(maximum))
    slider:SetScript("OnValueChanged", function(self, value)
        local exactSize = math.floor(value + 0.5)
        _G[name .. "Text"]:SetText(string.format("%s: %d px", sizeLabel, exactSize))
        if not self.refreshing then
            onChanged(exactSize)
        end
    end)
    return slider
end

function BBR:CreateConfig()
    if self.configFrame then
        return
    end

    local frame = CreateFrame("Frame", "BetterBeReadyConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    self.configFrame = frame
    frame:SetSize(540, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Keep every close path independent from tracker refreshes so the settings
    -- window can always be dismissed during combat.
    if frame.CloseButton then
        frame.CloseButton:SetScript("OnClick", function()
            BBR:CloseConfig()
        end)
    end
    if UISpecialFrames then
        table.insert(UISpecialFrames, frame:GetName())
    end

    frame.TitleText:SetText("BetterBeReady")

    frame.description = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.description:SetPoint("TOPLEFT", 18, -38)
    frame.description:SetText("Unlock to drag trackers, including during combat.")

    frame.lockButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.lockButton:SetSize(120, 24)
    frame.lockButton:SetPoint("TOPLEFT", 18, -66)
    frame.lockButton:SetScript("OnClick", function()
        BBR:SetLocked(not BBR.db.locked)
    end)

    frame.resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resetButton:SetSize(120, 24)
    frame.resetButton:SetPoint("LEFT", frame.lockButton, "RIGHT", 10, 0)
    frame.resetButton:SetText("Reset positions")
    frame.resetButton:SetScript("OnClick", function()
        BBR:ResetPositions()
    end)

    frame.rows = {}
    for index, rowInfo in ipairs(TRACKER_ROWS) do
        local row = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 18, -105 - ((index - 1) * 110))
        row:SetSize(500, 98)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.08, 0.08, 0.08, 0.65)

        row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.title:SetPoint("TOPLEFT", 10, -8)
        row.title:SetText(rowInfo.title)

        row.enabled = CreateCheckbox(row, "Enabled", 8, -28, function(checked)
            BBR:SetTrackerEnabled(rowInfo.key, checked)
        end)

        if rowInfo.allowLabel ~= false then
            row.showLabel = CreateCheckbox(row, "Show label", 105, -28, function(checked)
                BBR:SetTrackerLabelVisible(rowInfo.key, checked)
            end)
        end

        if rowInfo.hasRechargeTime then
            row.showRechargeTime = CreateCheckbox(row, "Show recharge time", 8, -58, function(checked)
                BBR:SetTrackerBooleanSetting(rowInfo.key, "showRechargeTime", checked)
            end)
        end

        if rowInfo.hasTextMode then
            row.textMode = CreateCheckbox(row, "Text-only display", 145, -58, function(checked)
                BBR:SetTrackerBooleanSetting(rowInfo.key, "textMode", checked)
            end)
        end

        local sliderName = "BetterBeReadySizeSlider" .. index
        row.size = CreateSizeSlider(
            row,
            sliderName,
            295,
            rowInfo.hasTextSize and -24 or -36,
            rowInfo.minSize,
            rowInfo.maxSize,
            rowInfo.sizeLabel,
            function(value)
                BBR:SetTrackerSize(rowInfo.key, value)
            end
        )

        if rowInfo.hasTextSize then
            local textSliderName = "BetterBeReadyTextSizeSlider" .. index
            row.textSize = CreateSizeSlider(
                row,
                textSliderName,
                295,
                -62,
                8,
                32,
                "Text size",
                function(value)
                    BBR:SetTrackerTextSize(rowInfo.key, value)
                end
            )
        end

        frame.rows[rowInfo.key] = row
    end

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("BOTTOMLEFT", 18, 14)
    frame.footer:SetText("Commands: /bbr, close, lock, unlock, reset, debug")

    frame:SetScript("OnShow", function()
        BBR:RefreshConfig()
    end)
end

function BBR:RefreshConfig()
    if not self.configFrame then
        return
    end

    self.configFrame.lockButton:SetText(self.db.locked and "Unlock trackers" or "Lock trackers")
    for key, row in pairs(self.configFrame.rows) do
        local settings = self:GetTrackerSettings(key)
        row.enabled:SetChecked(settings.enabled)
        if row.showLabel then
            row.showLabel:SetChecked(settings.showLabel)
        end
        if row.showRechargeTime then
            row.showRechargeTime:SetChecked(settings.showRechargeTime)
        end
        if row.textMode then
            row.textMode:SetChecked(settings.textMode)
        end
        row.size.refreshing = true
        row.size:SetValue(settings.size)
        row.size.refreshing = false
        if row.textSize then
            row.textSize.refreshing = true
            row.textSize:SetValue(settings.textSize)
            row.textSize.refreshing = false
        end
    end
end

function BBR:ToggleConfig()
    self:CreateConfig()
    if self.configFrame:IsShown() then
        self:CloseConfig()
    else
        self.configFrame:Show()
    end
end

function BBR:OpenConfig()
    self:CreateConfig()
    self.configFrame:Show()
end

function BBR:CloseConfig()
    if self.configFrame and self.configFrame:IsShown() then
        self.configFrame:Hide()
    end
end
