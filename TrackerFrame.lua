local _, BBR = ...

local function SetFontSize(fontString, size)
    local font = GameFontNormal:GetFont()
    fontString:SetFont(font, math.max(9, math.floor(size)), "OUTLINE")
end

function BBR:SetMinuteSecondCountdownFormat(cooldown, enabled)
    if not (cooldown and cooldown.SetCountdownFormatter) then
        return
    end

    if not enabled then
        pcall(cooldown.SetCountdownFormatter, cooldown, nil)
        return
    end

    if not cooldown.bbrMinuteSecondFormatter
        and C_StringUtil
        and C_StringUtil.CreateNumericRuleFormatter
    then
        local ok, formatter = pcall(C_StringUtil.CreateNumericRuleFormatter)
        if ok and formatter and formatter.SetBreakpoints then
            local configured = pcall(formatter.SetBreakpoints, formatter, {
                {
                    threshold = 0,
                    format = "%d:%02d",
                    components = {
                        { div = 60 },
                        { mod = 60 },
                    },
                },
            })
            if configured then
                cooldown.bbrMinuteSecondFormatter = formatter
            end
        end
    end

    if cooldown.bbrMinuteSecondFormatter then
        pcall(
            cooldown.SetCountdownFormatter,
            cooldown,
            cooldown.bbrMinuteSecondFormatter
        )
    end
end

function BBR:CreateTrackerFrame(tracker, iconTexture)
    local frame = CreateFrame("Frame", "BetterBeReady" .. tracker.key .. "Frame", UIParent)
    tracker.frame = frame
    tracker.conditionVisible = true

    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not BBR.db.locked then
            self.bbrMoving = true
            self.bbrDragged = true
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.bbrMoving then
            return
        end
        self.bbrMoving = nil
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        local settings = BBR:GetTrackerSettings(tracker.key)
        settings.point = point
        settings.relativePoint = relativePoint
        settings.x = x
        settings.y = y
        if tracker.OnPositionChanged then
            tracker:OnPositionChanged()
        end
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then
            return
        end
        if self.bbrDragged then
            self.bbrDragged = nil
            return
        end
        if BBR.OpenConfig then
            BBR:OpenConfig()
        end
    end)

    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()
    frame.background:SetColorTexture(0.02, 0.02, 0.02, 0.92)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexture(iconTexture)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetFrameLevel(frame:GetFrameLevel() + 10)
    frame.cooldown:SetDrawEdge(false)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.72)

    -- Blizzard's normal spell-button border. The texture contains substantial
    -- transparent padding, so action buttons center it over the icon at roughly
    -- 1.8 times the icon size instead of stretching it to the frame bounds.
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    frame.border:SetPoint("CENTER", frame.icon, "CENTER")

    -- Font strings attached directly to the tracker frame render below child
    -- frames such as Cooldown. Keep all tracker text in a higher child frame so
    -- charge counts and labels stay crisp above the dark cooldown swipe.
    frame.textOverlay = CreateFrame("Frame", nil, frame)
    frame.textOverlay:SetAllPoints(frame)
    frame.textOverlay:SetFrameLevel(frame.cooldown:GetFrameLevel() + 2)

    frame.label = frame.textOverlay:CreateFontString(nil, "OVERLAY")
    frame.label:SetFontObject(GameFontNormal)
    frame.label:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    frame.label:SetJustifyH("CENTER")
    frame.label:SetTextColor(1, 1, 1)

    frame.value = frame.textOverlay:CreateFontString(nil, "OVERLAY")
    frame.value:SetFontObject(GameFontNormal)
    frame.value:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.value:SetJustifyH("CENTER")
    frame.value:SetTextColor(1, 1, 1)

    frame.detail = frame.textOverlay:CreateFontString(nil, "OVERLAY")
    frame.detail:SetFontObject(GameFontNormal)
    frame.detail:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    frame.detail:SetJustifyH("CENTER")
    frame.detail:SetTextColor(1, 1, 1)

    return frame
end

function BBR:ApplyTrackerFrameSettings(tracker)
    local settings = self:GetTrackerSettings(tracker.key)
    local frame = tracker.frame
    if not settings or not frame then
        return
    end

    local size = settings.size
    frame:SetSize(size, size)
    frame.border:SetSize(size * 1.8, size * 1.8)
    frame:ClearAllPoints()
    frame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.x, settings.y)
    frame.label:SetShown(settings.showLabel)
    local textSize = settings.textSize or math.max(9, math.floor(size * 0.18))
    SetFontSize(frame.label, textSize)
    SetFontSize(frame.value, textSize)
    SetFontSize(frame.detail, textSize)

    if frame.cooldown.GetCountdownFontString then
        local countdownFont = frame.cooldown:GetCountdownFontString()
        if countdownFont then
            SetFontSize(countdownFont, textSize)
        end
    end
end

function BBR:SetTrackerConditionVisible(tracker, visible)
    tracker.conditionVisible = visible and true or false
    self:RefreshTrackerVisibility(tracker)
end

function BBR:ClearTrackerCooldown(tracker)
    if tracker.frame and tracker.frame.cooldown then
        tracker.frame.cooldown:SetCooldown(0, 0)
    end
end
