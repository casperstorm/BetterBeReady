local now, plays, stopFails = 100, 0, false
local overlaps = 0
local liveSounds = {}
local settings = { enabled = false, musicEnabled = true, musicTrack = "sounds\\DejaVuHero.ogg" }
local BBR = { trackers = {} }
function BBR:RegisterTracker(key, tracker)
    tracker.key = key
    self.trackers[key] = tracker
end
function BBR:GetTrackerSettings() return settings end
function GetTime() return now end
function PlaySoundFile(_, channel)
    assert(channel == "Master")
    if next(liveSounds) then overlaps = overlaps + 1 end
    plays = plays + 1
    liveSounds[plays] = true
    return true, plays
end
function StopSound(handle)
    if stopFails then error("simulated stop failure") end
    liveSounds[handle] = nil
end
for _, file in ipairs({ "Utils.lua", "Music.lua", "Trackers/Bloodlust.lua" }) do
    assert(loadfile(file))("BetterBeReady", BBR)
end
local tracker = BBR.trackers.bloodlust
local function lockout(start) return { duration = 600, expirationTime = start + 600 } end

-- Establish initial state. A new readable lockout can start music in combat
-- while every query for the actual haste aura is restricted.
tracker:UpdateBloodlustMusic(nil, "READY", nil)
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(100))
assert(plays == 1 and liveSounds[1])
for _ = 1, 100 do
    tracker:UpdateBloodlustMusic(nil, "UNKNOWN", nil)
    tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(100))
end
assert(plays == 1 and liveSounds[1])

-- Even a second, different lust application in the same window cannot start
-- another song. Expiry must work without another aura event.
now = 110
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(110))
assert(plays == 1)
now = 140
tracker:ExpireBloodlustMusic()
assert(next(liveSounds) == nil)
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(100))
assert(plays == 1)

-- An early buff removal followed by stale/readable data cannot re-arm playback.
now = 800
tracker:UpdateBloodlustMusic({ duration = 40, expirationTime = 840 }, "LOCKED", lockout(800))
assert(plays == 2)
now = 810
tracker:UpdateBloodlustMusic(nil, "READY", lockout(800))
assert(next(liveSounds) == nil)
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(800))
assert(plays == 2)

-- Settings previews replace automatic music and repeated Play does not stack.
now = 1500
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(1500))
assert(plays == 3)
BBR:PreviewBloodlustMusic()
assert(plays == 4 and liveSounds[4] and not liveSounds[3])
BBR:PreviewBloodlustMusic()
assert(plays == 4)
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(1500))
assert(plays == 4)

-- A failed stop retains the handle and refuses to start a competing sound.
stopFails = true
BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
BBR:PreviewBloodlustMusic()
assert(plays == 4 and liveSounds[4] and BBR.musicSoundHandle == 4)
stopFails = false
BBR:PreviewBloodlustMusic()
assert(plays == 5 and liveSounds[5] and not liveSounds[4])
BBR:StopBloodlustMusicPreview()
assert(next(liveSounds) == nil)

-- Disabled/no-sound settings consume the current window without starting music;
-- enabling or changing the track during that window must not restart it.
now = 2200
settings.musicEnabled = false
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(2200))
settings.musicEnabled = true
tracker:OnMusicEnabledChanged(true)
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(2200))
assert(plays == 5)
now = 2900
BBR:SetBloodlustMusicTrack("")
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(2900))
BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(2900))
assert(plays == 5)

-- A reload with an existing lockout, or delayed recovery from a secret query,
-- must not replay a song partway through its duration.
tracker.musicInitialized = nil
tracker.musicLastWindowStart = nil
tracker.musicEndsAt = nil
now = 3600
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(3600))
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(3600))
assert(plays == 5)
now = 4310
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(4300))
assert(plays == 5)

-- Secret numeric fields are rejected before arithmetic.
local secret = setmetatable({}, { __sub = function() error("secret arithmetic") end })
issecretvalue = function(value) return value == secret end
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", { duration = secret, expirationTime = secret })
assert(plays == 5)
now = 5000
tracker:UpdateBloodlustMusic(nil, "UNKNOWN", lockout(5000))
assert(plays == 6 and liveSounds[6])
assert(overlaps == 0, "overlapping music playback")

-- Native mode works without readable aura data. Registrations only watch the
-- lockout: repeated haste applications have no matching sound registration.
local native, nativeAdds, nextRegistration = {}, 0, 0
local removalFails, combat, addFailsFor = false, false, nil
Enum = { UnitAuraSoundTrigger = { Added = 0 } }
function InCombatLockdown() return combat end
C_UnitAuras = {
    AddAuraSound = function(trigger, sound)
        assert(trigger == 0)
        if sound.spellID == addFailsFor then return nil end
        nextRegistration = nextRegistration + 1
        nativeAdds = nativeAdds + 1
        native[nextRegistration] = sound
        return nextRegistration
    end,
    RemoveAuraSound = function(id)
        if removalFails then error("simulated native removal failure") end
        native[id] = nil
    end,
    GetPlayerAuraBySpellID = function() error("secret aura") end,
}
BBR:RefreshBloodlustMusicAuraSounds()
assert(next(liveSounds) == nil)
assert(BBR.nativeBloodlustMusicMode)
local expectedCount = #tracker.lockoutSpellIDs
assert(nativeAdds == expectedCount)
local function triggersFor(spellID)
    local count = 0
    for _, sound in pairs(native) do
        if sound.spellID == spellID then count = count + 1 end
    end
    return count
end
for _, spellID in ipairs(tracker.lockoutSpellIDs) do assert(triggersFor(spellID) == 1) end
for _, spellID in ipairs(tracker.bloodlustBuffSpellIDs) do assert(triggersFor(spellID) == 0) end
for _ = 1, 100 do BBR:RefreshBloodlustMusicAuraSounds() end
assert(nativeAdds == expectedCount, "unchanged settings registered duplicate sounds")
combat = true
for _ = 1, 100 do
    tracker:UpdateBloodlustMusic(nil, "UNKNOWN", nil)
    tracker:StartBloodlustMusic()
end
assert(plays == 6, "Lua fallback layered audio over native playback")
assert(triggersFor(57724) == 1)

-- Track selection is deferred in combat; stale native handles are retained if
-- cleanup fails, and no new registration is created until cleanup succeeds.
BBR:SetBloodlustMusicTrack("sounds\\DejaVuHero.ogg")
assert(BBR.bloodlustMusicAuraSoundRefreshPending)
assert(nativeAdds == expectedCount)
combat = false
removalFails = true
for _ = 1, 3 do BBR:RefreshBloodlustMusicAuraSounds() end
assert(nativeAdds == expectedCount)
assert(triggersFor(57724) == 1)
assert(BBR.bloodlustMusicRegistrationError)
removalFails = false
BBR:RefreshBloodlustMusicAuraSounds()
assert(nativeAdds == expectedCount * 2)
assert(triggersFor(57724) == 1)
assert(not BBR.bloodlustMusicAuraSoundRefreshPending)
for _, sound in pairs(native) do assert(sound.soundFileName:find("DejaVuHero", 1, true)) end

-- Failed removal on disable still retains handles and retries successfully.
removalFails = true
BBR:SetBloodlustMusicTrack("")
assert(triggersFor(57724) == 1)
assert(BBR.bloodlustMusicRegistrations[57724])
removalFails = false
BBR:RefreshBloodlustMusicAuraSounds()
assert(next(native) == nil and next(BBR.bloodlustMusicRegistrations) == nil)

-- A partial add failure retries only the missing entry.
addFailsFor = 57724
BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
assert(triggersFor(57724) == 0)
assert(triggersFor(57723) == 1)
local addsBeforeRetry = nativeAdds
addFailsFor = nil
BBR:RefreshBloodlustMusicAuraSounds()
assert(nativeAdds == addsBeforeRetry + 1)
assert(triggersFor(57724) == 1 and triggersFor(57723) == 1)

-- Preview is unavailable when native music could be playing or during combat.
assert(not BBR:CanPreviewBloodlustMusic())
C_UnitAuras.GetPlayerAuraBySpellID = function() return nil end
assert(BBR:CanPreviewBloodlustMusic())
combat = true
assert(not BBR:CanPreviewBloodlustMusic())
combat = false

-- Legacy clients use the matching registration/removal pair too.
BBR:SetBloodlustMusicTrack("")
local modernAdd, modernRemove = C_UnitAuras.AddAuraSound, C_UnitAuras.RemoveAuraSound
C_UnitAuras.AddAuraSound, C_UnitAuras.RemoveAuraSound = nil, nil
C_UnitAuras.AddAuraAppliedSound = function(sound) return modernAdd(0, sound) end
C_UnitAuras.RemoveAuraAppliedSound = modernRemove
BBR:SetBloodlustMusicTrack("sounds\\GasHero.ogg")
assert(triggersFor(57724) == 1)
BBR:SetBloodlustMusicTrack("")
assert(next(native) == nil)
print("music_test.lua: OK")
