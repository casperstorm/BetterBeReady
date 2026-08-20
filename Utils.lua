local _, BBR = ...

local function CallBooleanProbe(probe, value)
    if not probe then
        return false
    end
    local ok, result = pcall(probe, value)
    return ok and result == true
end

function BBR:IsSecretValue(value)
    return CallBooleanProbe(_G.issecretvalue, value)
end

function BBR:IsSecretTable(value)
    return CallBooleanProbe(_G.issecrettable, value)
end

function BBR:GetReadableField(value, key)
    if self:IsSecretTable(value) then
        return nil, false
    end

    local ok, field = pcall(function()
        return value[key]
    end)
    if not ok or self:IsSecretValue(field) then
        return nil, false
    end

    if _G.canaccessvalue then
        local accessOK, accessible = pcall(_G.canaccessvalue, field)
        if accessOK and accessible == false then
            return nil, false
        end
    end

    return field, true
end

function BBR:FindFirstAuraBySpellID(getAura, spellIDs)
    local failed = false

    for _, spellID in ipairs(spellIDs) do
        local ok, aura = pcall(getAura, spellID)
        if not ok then
            failed = true
        elseif aura ~= nil then
            if self:IsSecretTable(aura) then
                return nil, "UNKNOWN"
            end
            return aura, "LOCKED"
        end
    end

    if failed then
        return nil, "UNKNOWN"
    end
    return nil, "READY"
end

function BBR:FormatDuration(seconds, includeTenths)
    seconds = math.max(0, tonumber(seconds) or 0)
    if includeTenths then
        local totalTenths = math.floor(seconds * 10 + 0.0001)
        local minutes = math.floor(totalTenths / 600)
        local wholeSeconds = math.floor((totalTenths % 600) / 10)
        local tenths = totalTenths % 10
        return string.format("%d:%02d.%d", minutes, wholeSeconds, tenths)
    end

    local totalSeconds = math.floor(seconds)
    return string.format("%d:%02d", math.floor(totalSeconds / 60), totalSeconds % 60)
end

