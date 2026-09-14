local _, BBR = ...

local CONTROL_WIDTH = 400
local CONTROL_LABEL_WIDTH = 100
local DROPDOWN_WIDTH = 180

local TAB_ORDER = {
    { id = "general", label = "General" },
    { id = "bloodlust", label = "Bloodlust" },
    { id = "battleRes", label = "Battle Res" },
    { id = "combatPotion", label = "Combat Potion" },
    { id = "combatTimer", label = "Combat Timer" },
    { id = "movementCooldown", label = "Movement" },
}

local settingRefreshers = {}

local function RegisterSettingRefresher(refresh)
    table.insert(settingRefreshers, refresh)
end

local function SetControlsEnabled(controls, enabled)
    local alpha = enabled and 1.0 or 0.5
    for _, control in ipairs(controls) do
        if control.SetEnabled then
            control:SetEnabled(enabled)
        end
        if control.SetAlpha then
            control:SetAlpha(alpha)
        end
        if control.EnableMouse then
            control:EnableMouse(enabled)
        end
    end
end

local function Settings(trackerKey)
    return BBR:GetTrackerSettings(trackerKey)
end

local function CreateCheckbox(parent, label, yOffset, getValue, setValue, xOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", xOffset or 16, yOffset)
    checkbox.Text:SetText(label)
    checkbox.Text:SetFontObject("GameFontHighlight")
    checkbox:SetScript("OnClick", function(self)
        setValue(self:GetChecked())
    end)

    RegisterSettingRefresher(function()
        checkbox:SetChecked(getValue())
    end)
    return checkbox
end

local function CreateDropdown(parent, label, yOffset, options, getValue, setValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 24, yOffset)
    container:SetSize(CONTROL_WIDTH, 30)

    local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetWidth(CONTROL_LABEL_WIDTH)
    labelText:SetJustifyH("LEFT")
    labelText:SetText(label)

    local dropdown = CreateFrame("DropdownButton", nil, container, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT", labelText, "RIGHT", 8, 0)
    dropdown:SetWidth(DROPDOWN_WIDTH)

    local function IsSelected(value)
        return getValue() == value
    end

    local function SetSelected(value)
        setValue(value)
        if dropdown.GenerateMenu then
            dropdown:GenerateMenu()
        end
    end

    dropdown:SetupMenu(function(_, rootDescription)
        local choices = type(options) == "function" and options() or options
        if #choices > 12 and rootDescription.SetScrollMode then
            rootDescription:SetScrollMode(320)
        end
        for _, option in ipairs(choices) do
            rootDescription:CreateRadio(option.label, IsSelected, SetSelected, option.value)
        end
    end)

    dropdown.label = labelText
    dropdown.container = container
    RegisterSettingRefresher(function()
        local choices = type(options) == "function" and options() or options
        for _, option in ipairs(choices) do
            if option.value == getValue() then
                dropdown:SetText(option.label)
            end
        end
    end)
    return dropdown
end

local function CreateHorizontalSlider(parent, label, minVal, maxVal, step, yOffset, getValue, setValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 24, yOffset)
    container:SetSize(CONTROL_WIDTH, 32)

    local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetWidth(CONTROL_LABEL_WIDTH)
    labelText:SetJustifyH("LEFT")
    labelText:SetText(label)

    local sliderFrame = CreateFrame("Frame", nil, container, "MinimalSliderWithSteppersTemplate")
    sliderFrame:SetPoint("LEFT", labelText, "RIGHT", 8, 0)
    sliderFrame:SetPoint("RIGHT", 0, 0)
    sliderFrame:SetHeight(16)

    local steps = math.floor((maxVal - minVal) / step + 0.5)
    local formatters = {}
    formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
        MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return tostring(math.floor(value + 0.5)) end
    )

    sliderFrame.initInProgress = true
    sliderFrame:Init(getValue() or minVal, minVal, maxVal, steps, formatters)
    if sliderFrame.MinText then sliderFrame.MinText:Hide() end
    if sliderFrame.MaxText then sliderFrame.MaxText:Hide() end
    sliderFrame.initInProgress = false

    if sliderFrame.Slider then
        sliderFrame.Slider:HookScript("OnValueChanged", function(_, value)
            if not sliderFrame.initInProgress then
                setValue(math.floor(value / step + 0.5) * step)
            end
        end)
    end

    sliderFrame.container = container
    RegisterSettingRefresher(function()
        sliderFrame.initInProgress = true
        sliderFrame:SetValue(getValue() or minVal)
        sliderFrame.initInProgress = false
    end)
    return sliderFrame
end

local function CreateNote(parent, text, yOffset, xOffset)
    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    note:SetPoint("TOPLEFT", xOffset or 32, yOffset)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText(text)
    note:SetTextColor(0.75, 0.75, 0.75)
    return note
end

local ALIGNMENT_OPTIONS = {
    { label = "Left", value = "LEFT" },
    { label = "Right", value = "RIGHT" },
}

local function MusicOptions()
    local options = { { label = "No sound", value = "" } }
    for _, track in ipairs(BBR.bloodlustMusicTracks) do
        options[#options + 1] = { label = track.title, value = track.id }
    end
    return options
end

local function ChannelOptions()
    local options = {}
    for _, channel in ipairs(BBR.bloodlustMusicChannels) do
        options[#options + 1] = { label = channel.title, value = channel.id }
    end
    return options
end

local function BeginPage(content, title)
    local heading = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 4, -2)
    heading:SetText(title)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -7)
    divider:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -7)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 0.82, 0, 0.35)

    return -38
end

local function Section(content, label, y, options)
    local heading = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("TOPLEFT", 24, y)
    heading:SetText(label)
    if options then
        table.insert(options, heading)
    end
    return y - 22
end

-- Adds the enable checkbox and returns the list that its state greys out.
local function BuildEnabledToggle(page, content, trackerKey, label, y)
    local options = {}
    page.enabled = CreateCheckbox(content, label, y,
        function() return Settings(trackerKey).enabled end,
        function(checked)
            BBR:SetTrackerEnabled(trackerKey, checked)
            BBR:RefreshConfig()
        end)
    RegisterSettingRefresher(function()
        SetControlsEnabled(options, Settings(trackerKey).enabled)
    end)
    return options
end

local function AddSizeSlider(page, content, options, trackerKey, key, label, minVal, maxVal, y, setter)
    page[key] = CreateHorizontalSlider(content, label, minVal, maxVal, 1, y,
        function() return Settings(trackerKey)[key] end,
        function(value) setter(BBR, trackerKey, value) end)
    table.insert(options, page[key].container)
end

local function AddAlignmentDropdown(page, content, options, trackerKey, y)
    page.textAlignment = CreateDropdown(content, "Alignment:", y, ALIGNMENT_OPTIONS,
        function() return Settings(trackerKey).textAlignment end,
        function(value) BBR:SetTrackerTextAlignment(trackerKey, value) end)
    table.insert(options, page.textAlignment.label)
    table.insert(options, page.textAlignment)
end

local function AddTextModeCheckbox(page, content, options, trackerKey, y)
    page.textMode = CreateCheckbox(content, "Text only", y,
        function() return Settings(trackerKey).textMode end,
        function(checked) BBR:SetTrackerBooleanSetting(trackerKey, "textMode", checked) end,
        24)
    table.insert(options, page.textMode)
end

local builders = {}

function builders.general(page, content)
    local y = BeginPage(content, "General")

    local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", 16, y)
    description:SetText("Unlock to move trackers—even during combat.")
    y = y - 28

    page.lockButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    page.lockButton:SetSize(130, 24)
    page.lockButton:SetPoint("TOPLEFT", 16, y)
    page.lockButton:SetScript("OnClick", function()
        BBR:SetLocked(not BBR.db.locked)
    end)
    RegisterSettingRefresher(function()
        page.lockButton:SetText(BBR.db.locked and "Unlock trackers" or "Lock trackers")
    end)

    page.resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    page.resetButton:SetSize(130, 24)
    page.resetButton:SetPoint("LEFT", page.lockButton, "RIGHT", 10, 0)
    page.resetButton:SetText("Reset positions")
    page.resetButton:SetScript("OnClick", function()
        BBR:ResetPositions()
    end)
    y = y - 40

    CreateNote(content, "Left-click a tracker to open this window. Drag unlocked trackers to move them.\n"
        .. "Commands: /bbr lock, /bbr unlock, /bbr reset, /bbr close", y, 16)
end

function builders.bloodlust(page, content)
    local key = "bloodlust"
    local y = BeginPage(content, "Bloodlust")
    local options = BuildEnabledToggle(page, content, key, "Show visuals", y)
    y = y - 32

    AddTextModeCheckbox(page, content, options, key, y)
    y = y - 36
    AddAlignmentDropdown(page, content, options, key, y)
    y = y - 36
    AddSizeSlider(page, content, options, key, "size", "Icon size:", 32, 128, y, BBR.SetTrackerSize)
    y = y - 34
    AddSizeSlider(page, content, options, key, "textSize", "Text size:", 8, 32, y, BBR.SetTrackerTextSize)
    y = y - 44

    y = Section(content, "Music", y)
    page.musicEnabled = CreateCheckbox(content, "Enable music", y,
        function() return Settings(key).musicEnabled end,
        function(checked) BBR:SetBloodlustMusicEnabled(checked) end,
        24)
    y = y - 36

    page.musicDropdown = CreateDropdown(content, "Track:", y, MusicOptions,
        function() return Settings(key).musicTrack end,
        function(value) BBR:SetBloodlustMusicTrack(value) end)
    RegisterSettingRefresher(function()
        page.musicDropdown:SetText(BBR:GetBloodlustMusicTitle(Settings(key).musicTrack))
    end)

    page.musicPlayButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    page.musicPlayButton:SetPoint("LEFT", page.musicDropdown, "RIGHT", 8, 0)
    page.musicPlayButton:SetSize(50, 24)
    page.musicPlayButton:SetText("Play")
    page.musicPlayButton:SetScript("OnClick", function()
        BBR:PreviewBloodlustMusic()
    end)

    page.musicStopButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    page.musicStopButton:SetPoint("LEFT", page.musicPlayButton, "RIGHT", 4, 0)
    page.musicStopButton:SetSize(50, 24)
    page.musicStopButton:SetText("Stop")
    page.musicStopButton:SetScript("OnClick", function()
        BBR:StopBloodlustMusicPreview()
    end)
    y = y - 36

    page.musicChannel = CreateDropdown(content, "Channel:", y, ChannelOptions,
        function() return BBR:GetBloodlustMusicChannel() end,
        function(value) BBR:SetBloodlustMusicChannel(value) end)
    y = y - 40

    CreateNote(content, "Music plays independently of the visuals. Changes made during combat apply when combat ends.", y, 24)
end

function builders.battleRes(page, content)
    local key = "battleRes"
    local y = BeginPage(content, "Battle Res")
    local options = BuildEnabledToggle(page, content, key, "Enabled", y)
    y = y - 32

    AddTextModeCheckbox(page, content, options, key, y)
    page.showRechargeTime = CreateCheckbox(content, "Show recharge time", y,
        function() return Settings(key).showRechargeTime end,
        function(checked) BBR:SetTrackerBooleanSetting(key, "showRechargeTime", checked) end,
        200)
    table.insert(options, page.showRechargeTime)
    y = y - 36
    AddAlignmentDropdown(page, content, options, key, y)
    y = y - 36
    AddSizeSlider(page, content, options, key, "size", "Icon size:", 32, 128, y, BBR.SetTrackerSize)
    y = y - 34
    AddSizeSlider(page, content, options, key, "textSize", "Text size:", 8, 32, y, BBR.SetTrackerTextSize)
end

function builders.combatPotion(page, content)
    local key = "combatPotion"
    local y = BeginPage(content, "Combat Potion")
    local options = BuildEnabledToggle(page, content, key, "Enabled", y)
    y = y - 36

    AddAlignmentDropdown(page, content, options, key, y)
    y = y - 36
    AddSizeSlider(page, content, options, key, "size", "Text size:", 8, 32, y, BBR.SetTrackerSize)
end

function builders.combatTimer(page, content)
    local key = "combatTimer"
    local y = BeginPage(content, "Combat Timer")
    local options = BuildEnabledToggle(page, content, key, "Enabled", y)
    y = y - 36

    AddSizeSlider(page, content, options, key, "size", "Text size:", 10, 72, y, BBR.SetTrackerSize)
end

function builders.movementCooldown(page, content)
    local key = "movementCooldown"
    local tracker = BBR.trackers[key]
    local y = BeginPage(content, "Movement Cooldown")
    local options = BuildEnabledToggle(page, content, key, "Enabled", y)
    CreateNote(content, "Counts down until your movement ability is ready again.", y - 6, 214)
    y = y - 32

    page.combatOnly = CreateCheckbox(content, "Only in combat", y,
        function() return Settings(key).combatOnly end,
        function(checked) BBR:SetTrackerBooleanSetting(key, "combatOnly", checked) end,
        24)
    table.insert(options, page.combatOnly)
    page.showDecimals = CreateCheckbox(content, "Show decimals", y,
        function() return Settings(key).showDecimals end,
        function(checked) BBR:SetTrackerBooleanSetting(key, "showDecimals", checked) end,
        200)
    table.insert(options, page.showDecimals)
    y = y - 28

    page.showName = CreateCheckbox(content, "Show spell name", y,
        function() return Settings(key).showName end,
        function(checked) BBR:SetTrackerBooleanSetting(key, "showName", checked) end,
        24)
    table.insert(options, page.showName)
    y = y - 36

    AddAlignmentDropdown(page, content, options, key, y)
    y = y - 36
    AddSizeSlider(page, content, options, key, "size", "Text size:", tracker.minSize, tracker.maxSize, y,
        BBR.SetTrackerSize)
    y = y - 44

    y = Section(content, "Tracked spells", y, options)
    local spellsTop = y
    page.spellCheckboxes = {}
    page.spellEmpty = CreateNote(content, "No movement spells for your current specialization.", spellsTop, 24)

    RegisterSettingRefresher(function()
        local spells = tracker:GetSpellOptions()
        for index, spell in ipairs(spells) do
            local checkbox = page.spellCheckboxes[index]
            if not checkbox then
                checkbox = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
                checkbox:SetPoint("TOPLEFT", 24, spellsTop - (index - 1) * 28)
                checkbox.Text:SetFontObject("GameFontHighlight")
                checkbox:SetScript("OnClick", function(self)
                    tracker:SetSpellEnabled(self.spellID, self:GetChecked())
                end)
                page.spellCheckboxes[index] = checkbox
            end
            checkbox.spellID = spell.spellID
            checkbox.Text:SetText(spell.known and spell.name or (spell.name .. " (not learned)"))
            checkbox:SetChecked(spell.enabled)
            checkbox:Show()
        end
        for index = #spells + 1, #page.spellCheckboxes do
            page.spellCheckboxes[index]:Hide()
        end
        page.spellEmpty:SetShown(#spells == 0)
        SetControlsEnabled(page.spellCheckboxes, Settings(key).enabled)
    end)
end

function BBR:CreateConfig()
    if self.configFrame then
        return
    end

    settingRefreshers = {}

    local frame = CreateFrame("Frame", "BetterBeReadyConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    self.configFrame = frame
    frame:SetSize(720, 500)
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

    local tabsPane = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    tabsPane:SetPoint("TOPLEFT", 12, -34)
    tabsPane:SetPoint("BOTTOMLEFT", 12, 8)
    tabsPane:SetWidth(138)

    local contentPane = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    contentPane:SetPoint("TOPLEFT", tabsPane, "TOPRIGHT", 8, 0)
    contentPane:SetPoint("BOTTOMRIGHT", -12, 8)

    frame.tabButtons = {}
    frame.pages = {}
    local contents = {}

    local function ShowTab(id)
        for _, tab in ipairs(TAB_ORDER) do
            contents[tab.id]:SetShown(tab.id == id)
            frame.tabButtons[tab.id]:SetEnabled(tab.id ~= id)
        end
        frame.activeTabId = id
    end
    frame.ShowTab = ShowTab

    local prevButton
    for _, tab in ipairs(TAB_ORDER) do
        local button = CreateFrame("Button", nil, tabsPane, "UIPanelButtonTemplate")
        button:SetSize(116, 22)
        button:SetText(tab.label)
        if prevButton then
            button:SetPoint("TOP", prevButton, "BOTTOM", 0, -4)
        else
            button:SetPoint("TOP", tabsPane, "TOP", 0, -8)
        end
        prevButton = button
        button:SetScript("OnClick", function()
            ShowTab(tab.id)
        end)
        frame.tabButtons[tab.id] = button

        local content = CreateFrame("Frame", nil, contentPane)
        content:SetPoint("TOPLEFT", 12, -12)
        content:SetPoint("BOTTOMRIGHT", -12, 12)
        content:Hide()
        contents[tab.id] = content

        local page = { content = content }
        frame.pages[tab.id] = page
        builders[tab.id](page, content)
    end

    frame:SetScript("OnShow", function()
        BBR:RefreshConfig()
    end)

    ShowTab("general")
end

function BBR:RefreshConfig()
    if not self.configFrame then
        return
    end

    for _, refresh in ipairs(settingRefreshers) do
        refresh()
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
