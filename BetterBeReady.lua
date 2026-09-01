local addonName, BBR = ...

BBR.addonName = addonName
BBR.displayName = "BetterBeReady"
BBR.trackers = {}
BBR.trackerOrder = {}

local DEFAULTS = {
    schemaVersion = 6,
    locked = false,
    trackers = {
        bloodlust = {
            enabled = true,
            showLabel = false,
            size = 64,
            textSize = 16,
            textMode = true,
            textAlignment = "LEFT",
            musicTrack = "sounds\\DejaVuHero.ogg",
            point = "CENTER",
            relativePoint = "CENTER",
            x = -90,
            y = 0,
        },
        battleRes = {
            enabled = true,
            showLabel = false,
            size = 64,
            textSize = 16,
            showRechargeTime = true,
            textMode = true,
            textAlignment = "LEFT",
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
        },
        combatTimer = {
            enabled = true,
            showLabel = false,
            size = 24,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 90,
            y = 0,
        },
    },
}

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function BBR:RegisterTracker(key, tracker)
    tracker.key = key
    self.trackers[key] = tracker
    self.trackerOrder[#self.trackerOrder + 1] = key
end

function BBR:GetTrackerSettings(key)
    return self.db and self.db.trackers and self.db.trackers[key]
end

function BBR:RefreshTrackerVisibility(tracker)
    if not tracker or not tracker.frame then
        return
    end

    local settings = self:GetTrackerSettings(tracker.key)
    local enabled = settings and settings.enabled
    local shouldShow = enabled and (not self.db.locked or tracker.conditionVisible ~= false)

    tracker.frame:SetMovable(not self.db.locked)
    tracker.frame:EnableMouse(true)
    if shouldShow and not tracker.frame:IsShown() then
        tracker.frame:Show()
    elseif not shouldShow and tracker.frame:IsShown() then
        tracker.frame:Hide()
    end
end

function BBR:RefreshAllTrackers()
    for _, key in ipairs(self.trackerOrder) do
        local tracker = self.trackers[key]
        if tracker.ApplySettings then
            tracker:ApplySettings()
        end
        self:RefreshTrackerVisibility(tracker)
    end
end

function BBR:SetLocked(locked)
    self.db.locked = locked and true or false
    for _, key in ipairs(self.trackerOrder) do
        local tracker = self.trackers[key]
        self:RefreshTrackerVisibility(tracker)
    end
    if self.RefreshConfig then
        self:RefreshConfig()
    end
end

function BBR:SetTrackerEnabled(key, enabled)
    local settings = self:GetTrackerSettings(key)
    local tracker = self.trackers[key]
    if not settings or not tracker then
        return
    end
    settings.enabled = enabled and true or false
    if tracker.OnEnabledChanged then
        tracker:OnEnabledChanged(settings.enabled)
    end
    self:RefreshTrackerVisibility(tracker)
end

function BBR:SetTrackerSize(key, size)
    local settings = self:GetTrackerSettings(key)
    local tracker = self.trackers[key]
    if not settings or not tracker then
        return
    end
    local minimum = tracker.minSize or 32
    local maximum = tracker.maxSize or 128
    settings.size = math.max(minimum, math.min(maximum, math.floor(size + 0.5)))
    tracker:ApplySettings()
end

function BBR:SetTrackerLabelVisible(key, visible)
    local settings = self:GetTrackerSettings(key)
    local tracker = self.trackers[key]
    if not settings or not tracker then
        return
    end
    settings.showLabel = visible and true or false
    tracker:ApplySettings()
end

function BBR:SetTrackerTextSize(key, size)
    local settings = self:GetTrackerSettings(key)
    local tracker = self.trackers[key]
    if not settings or not tracker then
        return
    end
    settings.textSize = math.max(8, math.min(32, math.floor(size + 0.5)))
    tracker:ApplySettings()
end

function BBR:SetTrackerBooleanSetting(key, settingKey, enabled)
    local settings = self:GetTrackerSettings(key)
    local tracker = self.trackers[key]
    if not settings or not tracker then
        return
    end
    settings[settingKey] = enabled and true or false
    tracker:ApplySettings()
end

function BBR:SetTrackerTextAlignment(key, alignment)
    local settings = self:GetTrackerSettings(key)
    local tracker = self.trackers[key]
    if not settings or not tracker then
        return
    end
    settings.textAlignment = alignment == "RIGHT" and "RIGHT" or "LEFT"
    tracker:ApplySettings()
    if self.RefreshConfig then
        self:RefreshConfig()
    end
end

function BBR:ResetPositions()
    for key, defaults in pairs(DEFAULTS.trackers) do
        local settings = self:GetTrackerSettings(key)
        if settings then
            settings.point = defaults.point
            settings.relativePoint = defaults.relativePoint
            settings.x = defaults.x
            settings.y = defaults.y
            settings.size = defaults.size
        end
    end
    self:RefreshAllTrackers()
    if self.RefreshConfig then
        self:RefreshConfig()
    end
end

function BBR:Initialize()
    _G.BetterBeReadyDB = _G.BetterBeReadyDB or {}

    -- Version 1 used a 32-128 square-frame size for every tracker. Combat Time
    -- is text-only from version 2 onward, so preserve its approximate visual
    -- scale by converting the old frame size to the font size it produced.
    local databaseVersion = tonumber(_G.BetterBeReadyDB.schemaVersion) or 1
    if databaseVersion < 2 then
        local trackers = _G.BetterBeReadyDB.trackers
        local combatTimer = trackers and trackers.combatTimer
        if combatTimer and type(combatTimer.size) == "number" then
            combatTimer.size = math.max(10, math.min(72, math.floor(combatTimer.size * 0.38 + 0.5)))
        end
    end
    if databaseVersion < 4 then
        local trackers = _G.BetterBeReadyDB.trackers
        if trackers and trackers.bloodlust then
            trackers.bloodlust.showLabel = false
        end
        if trackers and trackers.battleRes then
            trackers.battleRes.showLabel = false
        end
        _G.BetterBeReadyDB.schemaVersion = 4
    end
    if databaseVersion < 5 then
        local trackers = _G.BetterBeReadyDB.trackers
        if trackers and trackers.bloodlust then
            trackers.bloodlust.clickToCast = nil
        end
        _G.BetterBeReadyDB.schemaVersion = 5
    end
    if databaseVersion < 6 then
        local trackers = _G.BetterBeReadyDB.trackers
        if trackers then
            trackers.stoneform = nil
        end
        _G.BetterBeReadyDB.schemaVersion = 6
    end

    ApplyDefaults(_G.BetterBeReadyDB, DEFAULTS)
    self.db = _G.BetterBeReadyDB

    for _, key in ipairs(self.trackerOrder) do
        local tracker = self.trackers[key]
        if tracker.Create then
            tracker:Create()
        end
        if tracker.ApplySettings then
            tracker:ApplySettings()
        end
        self:RefreshTrackerVisibility(tracker)
    end

    SLASH_BETTERBEREADY1 = "/bbr"
    SLASH_BETTERBEREADY2 = "/betterbeready"
    SlashCmdList.BETTERBEREADY = function(message)
        local command = string.lower((message or ""):match("^%s*(.-)%s*$"))
        if command == "lock" then
            BBR:SetLocked(true)
        elseif command == "unlock" then
            BBR:SetLocked(false)
        elseif command == "reset" then
            BBR:ResetPositions()
        elseif command == "close" then
            BBR:CloseConfig()
        elseif command == "debug" then
            local tracker = BBR.trackers.bloodlust
            if tracker and tracker.PrintDebug then
                tracker:PrintDebug()
            end
        else
            BBR:ToggleConfig()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon == addonName then
        eventFrame:UnregisterEvent("ADDON_LOADED")
        BBR:Initialize()
    end
end)
