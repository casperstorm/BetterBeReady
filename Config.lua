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
        hasTextAlignment = true,
        hasMusic = true,
        height = 116,
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
        hasTextAlignment = true,
        height = 116,
    },
    {
        key = "combatPotion",
        title = "Combat potion",
        minSize = 8,
        maxSize = 32,
        sizeLabel = "Text size",
        hasTextAlignment = true,
        alignmentY = -38,
        height = 72,
    },
    {
        key = "combatTimer",
        title = "Combat timer",
        minSize = 10,
        maxSize = 72,
        sizeLabel = "Text size",
        height = 72,
    },
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

local function CreateLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function CreateSizeSlider(parent, name, x, y, minimum, maximum, sizeLabel, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(170)
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

local function CreateAlignmentDropdown(parent, trackerKey, x, y)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    dropdown:SetSize(150, 24)
    dropdown:SetDefaultText("Left")
    dropdown:SetupMenu(function(_, rootDescription)
        local function IsSelected(alignment)
            local settings = BBR:GetTrackerSettings(trackerKey)
            return settings and settings.textAlignment == alignment
        end

        local function SetSelected(alignment)
            BBR:SetTrackerTextAlignment(trackerKey, alignment)
        end

        rootDescription:CreateRadio("Left", IsSelected, SetSelected, "LEFT")
        rootDescription:CreateRadio("Right", IsSelected, SetSelected, "RIGHT")
    end)
    return dropdown
end

local function CreateMusicDropdown(parent, trackerKey, x, y)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    dropdown:SetSize(190, 24)
    dropdown:SetDefaultText("No sound")
    if dropdown.SetMouseWheelEnabled then
        dropdown:SetMouseWheelEnabled(true)
    end
    dropdown:SetupMenu(function(_, rootDescription)
        local function IsSelected(trackID)
            local settings = BBR:GetTrackerSettings(trackerKey)
            return settings and settings.musicTrack == trackID
        end

        local function SetSelected(trackID)
            BBR:SetBloodlustMusicTrack(trackID)
        end

        rootDescription:CreateRadio("No sound", IsSelected, SetSelected, "")
        for _, track in ipairs(BBR.bloodlustMusicTracks) do
            rootDescription:CreateRadio(track.title, IsSelected, SetSelected, track.id)
        end
    end)
    return dropdown
end

function BBR:CreateConfig()
    if self.configFrame then
        return
    end

    local frame = CreateFrame("Frame", "BetterBeReadyConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    self.configFrame = frame
    frame:SetSize(600, 540)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

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
    frame.description:SetPoint("TOPLEFT", 20, -38)
    frame.description:SetText("Unlock to move trackers—even during combat.")

    frame.lockButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.lockButton:SetSize(120, 24)
    frame.lockButton:SetPoint("TOPLEFT", 20, -62)
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
    local rowTop = -98
    for index, rowInfo in ipairs(TRACKER_ROWS) do
        local trackerKey = rowInfo.key
        local row = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 18, rowTop)
        row:SetSize(564, rowInfo.height)
        rowTop = rowTop - rowInfo.height - 10
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.045, 0.045, 0.045, 0.72)

        row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.title:SetPoint("TOPLEFT", 12, -10)
        row.title:SetText(rowInfo.title)

        local enabledLabel = trackerKey == "bloodlust" and "Show visuals" or "Enabled"
        row.enabled = CreateCheckbox(row, enabledLabel, 135, -4, function(checked)
            BBR:SetTrackerEnabled(trackerKey, checked)
        end)

        if rowInfo.hasTextMode then
            row.textMode = CreateCheckbox(row, "Text only", 245, -4, function(checked)
                BBR:SetTrackerBooleanSetting(trackerKey, "textMode", checked)
            end)
        end

        if rowInfo.hasRechargeTime then
            row.showRechargeTime = CreateCheckbox(row, "Show recharge time", 10, -40, function(checked)
                BBR:SetTrackerBooleanSetting(trackerKey, "showRechargeTime", checked)
            end)
        end

        if rowInfo.hasTextAlignment then
            local alignmentY = rowInfo.alignmentY or (rowInfo.hasMusic and -38 or -74)
            CreateLabel(row, "Alignment", 12, alignmentY - 13)
            row.textAlignment = CreateAlignmentDropdown(row, trackerKey, 92, alignmentY)
        end

        if rowInfo.hasMusic then
            row.musicEnabled = CreateCheckbox(row, "Enable music", 252, -40, function(checked)
                BBR:SetBloodlustMusicEnabled(checked)
            end)
            CreateLabel(row, "Music", 12, -91)
            row.musicDropdown = CreateMusicDropdown(row, trackerKey, 58, -78)

            row.musicPlayButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.musicPlayButton:SetPoint("TOPLEFT", 256, -78)
            row.musicPlayButton:SetSize(50, 24)
            row.musicPlayButton:SetText("Play")
            row.musicPlayButton:SetScript("OnClick", function()
                BBR:PreviewBloodlustMusic()
            end)

            row.musicStopButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.musicStopButton:SetPoint("TOPLEFT", 312, -78)
            row.musicStopButton:SetSize(50, 24)
            row.musicStopButton:SetText("Stop")
            row.musicStopButton:SetScript("OnClick", function()
                BBR:StopBloodlustMusicPreview()
            end)
        end

        local sliderName = "BetterBeReadySizeSlider" .. index
        row.size = CreateSizeSlider(
            row,
            sliderName,
            374,
            rowInfo.hasTextSize and -30 or -27,
            rowInfo.minSize,
            rowInfo.maxSize,
            rowInfo.sizeLabel,
            function(value)
                BBR:SetTrackerSize(trackerKey, value)
            end
        )

        if rowInfo.hasTextSize then
            local textSliderName = "BetterBeReadyTextSizeSlider" .. index
            row.textSize = CreateSizeSlider(
                row,
                textSliderName,
                374,
                -72,
                8,
                32,
                "Text size",
                function(value)
                    BBR:SetTrackerTextSize(trackerKey, value)
                end
            )
        end

        frame.rows[trackerKey] = row
    end

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
        if row.showRechargeTime then
            row.showRechargeTime:SetChecked(settings.showRechargeTime)
        end
        if row.textMode then
            row.textMode:SetChecked(settings.textMode)
        end
        if row.textAlignment then
            row.textAlignment:SetText(settings.textAlignment == "RIGHT" and "Right" or "Left")
        end
        if row.musicDropdown then
            row.musicDropdown:SetText(self:GetBloodlustMusicTitle(settings.musicTrack))
        end
        if row.musicEnabled then
            row.musicEnabled:SetChecked(settings.musicEnabled)
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
    self:StopBloodlustMusicPreview()
    if self.configFrame and self.configFrame:IsShown() then
        self.configFrame:Hide()
    end
end
