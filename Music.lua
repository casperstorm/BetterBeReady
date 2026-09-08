local _, BBR = ...

local MUSIC_ROOT = "Interface\\AddOns\\BetterBeReady\\Media\\BloodlustMusic\\"

BBR.bloodlustMusicTracks = {
    { id = "sounds\\GasHero.ogg", title = "Manuel - GAS GAS GAS" },
    { id = "sounds\\90sHero.ogg", title = "Max Coveri - Running in the 90's" },
    { id = "sounds\\BrainPowerHero.ogg", title = "Noma - Brainpower" },
    { id = "sounds\\BirdHero.ogg", title = "Lynyrd Skynyrd - Freebird" },
    { id = "sounds\\SandHero.ogg", title = "Darude - Sandstorm" },
    { id = "sounds\\NightHero.ogg", title = "Niko - Night of Fire" },
    { id = "sounds\\ElephantHero.ogg", title = "The Elephant Rave" },
    { id = "sounds\\SaiyanHero.ogg", title = "Fartwad - Stereo Saiyan 3D" },
    { id = "sounds\\JellyfishHero.ogg", title = "The Jellyfish Jam" },
    { id = "sounds\\TopHero.ogg", title = "Ken Blast - The Top" },
    { id = "sounds\\DDDHero.ogg", title = "Mega NRG Man - DDD Initial D" },
    { id = "sounds\\Up&DanceHero.ogg", title = "Lou Master - Up & Dance, Up & Go" },
    { id = "sounds\\HardcoreHero.ogg", title = "Fastway - Rockin' Hardcore" },
    { id = "sounds\\PerfectHero.ogg", title = "Chris Stanton - A Perfect Hero" },
    { id = "sounds\\SpeedyHero.ogg", title = "Marco Polo - Speedy Speed Boy" },
    { id = "sounds\\CascadaHero.ogg", title = "Cascada - Everytime We Touch" },
    { id = "sounds\\SunRainHero.ogg", title = "Manuel - Sun In The Rain" },
    { id = "sounds\\DontStopHero.ogg", title = "Lou Grant - Don't Stop The Music" },
    { id = "sounds\\InvadersHero.ogg", title = "The Prodigy - Invaders Must Die" },
    { id = "sounds\\CallOnMeHero.ogg", title = "Eric Prydz - Call On Me" },
    { id = "sounds\\KissKillHero.ogg", title = "Odyssey - Kiss Me Kill Me" },
    { id = "sounds\\LookaHero.ogg", title = "Go2 - Looka Bomba" },
    { id = "sounds\\AnchorHero.ogg", title = "ALESTORM - Fucked With An Anchor" },
    { id = "sounds\\FullMetalHero.ogg", title = "Daniel - Full Metal Cars" },
    { id = "sounds\\KickstartHero.ogg", title = "Mötley Crüe - Kickstart My Heart" },
    { id = "sounds\\RiderHero.ogg", title = "Ace - Rider Of The Sky" },
    { id = "sounds\\RisingSunHero.ogg", title = "Dave Rodgers - Beat Of The Rising Sun" },
    { id = "sounds\\BloodSugarHero.ogg", title = "Pendulum - Blood Sugar" },
    { id = "sounds\\DejaVuHero.ogg", title = "Dave Rodgers - Deja Vu" },
    { id = "sounds\\RumbleHero.ogg", title = "Jock Jams - Let's Get Ready To Rumble" },
    { id = "sounds\\HurricaneHero.ogg", title = "Gold-Rake - Hurricane Man" },
    { id = "sounds\\DontTurnHero1.ogg", title = "Go2 - Don't Turn It Off (Chorus)" },
    { id = "sounds\\DontTurnHero2.ogg", title = "Go2 - Don't Turn It Off (Solo)" },
    { id = "sounds\\EuronightHero.ogg", title = "Eurogroove - Euronight" },
    { id = "sounds\\BeatinWildHero.ogg", title = "Fastway - Rock Beatin' Wild" },
    { id = "sounds\\KingHero.ogg", title = "Jordan - King Of Eurobeat" },
    { id = "sounds\\SuperRiderHero.ogg", title = "Mark Astley - Super Rider" },
    { id = "sounds\\PistonGoHero.ogg", title = "Gordon Jim - Piston Go" },
    { id = "sounds\\DancingHero.ogg", title = "Vicky Vale - Dancing" },
    { id = "sounds\\BeatCrazyHero.ogg", title = "Fastway - Go Beat Crazy" },
    { id = "sounds\\SpitfireHero.ogg", title = "Go2 - Spitfire" },
    { id = "sounds\\ShockOutHero.ogg", title = "Fastway - Shock Out" },
    { id = "sounds\\SpeedLoverHero.ogg", title = "Speedman - Speed Lover" },
    { id = "sounds\\ShrekHero.ogg", title = "Jennifer Saunders - Holding Out For A Hero" },
    { id = "sounds\\BonkersHero.ogg", title = "Dizzee Rascal & Armand van Helden - Bonkers" },
    { id = "sounds\\HyperSuperHero.ogg", title = "Fastway - Hyper Super Power" },
    { id = "sounds\\SuperstarHero.ogg", title = "Go2 & DJ Boss - Superstar" },
    { id = "sounds\\AdrenalineHero.ogg", title = "Ace - Adrenaline" },
    { id = "sounds\\LoveDangerHero.ogg", title = "Priscilla - Love Is In Danger" },
    { id = "sounds\\BurningUpHero.ogg", title = "Sara - Burning Up For You" },
    { id = "sounds\\ImpactHero.ogg", title = "Daniel - Frontal Impact" },
    { id = "sounds\\CountdownHero.ogg", title = "Fastway - Love Countdown" },
    { id = "sounds\\YoungHero.ogg", title = "Symbol - Forever Young" },
    { id = "sounds\\SpeedLightHero.ogg", title = "The Snake - Speed Of Light" },
    { id = "sounds\\SuperDriverHero.ogg", title = "Daniel - Super Driver" },
    { id = "sounds\\RollerMobsterHero.ogg", title = "Carpenter Brut - Roller Mobster" },
    { id = "sounds\\RainbowHighHero.ogg", title = "DJ Paul Elstak - Rainbow High In The Sky" },
    { id = "sounds\\NightChildrenHero.ogg", title = "Nakatomi - Children Of The Night" },
    { id = "sounds\\CrazyEmotionHero.ogg", title = "Ace - Crazy On Emotion" },
    { id = "sounds\\BurningNightHero.ogg", title = "2 Fast - Burning Up The Night" },
}

local tracksByID = {}
for _, track in ipairs(BBR.bloodlustMusicTracks) do
    tracksByID[track.id] = track
end

function BBR:GetBloodlustMusicTrack(trackID)
    return tracksByID[trackID]
end

function BBR:GetBloodlustMusicTitle(trackID)
    local track = self:GetBloodlustMusicTrack(trackID)
    return track and track.title or "No sound"
end

-- Automatic music and settings previews share one playback handle. Never lose
-- that handle on a failed stop: starting another sound would create an overlap.
function BBR:StopBloodlustSound(owner)
    if owner and owner ~= self.musicSoundOwner then
        return true
    end
    if self.musicSoundHandle then
        if not StopSound then return false end
        local ok = pcall(StopSound, self.musicSoundHandle)
        if not ok then return false end
    end
    self.musicSoundHandle = nil
    self.musicSoundOwner = nil
    self.musicSoundTrack = nil
    self.musicPreviewSoundHandle = nil
    return true
end

function BBR:PlayBloodlustSound(trackID, owner)
    -- Native triggers own automatic playback whenever supported. Never layer a
    -- Lua-started song on top just because combat aura reads became available.
    if owner == "bloodlust" and self.nativeBloodlustMusicMode then return end
    local track = self:GetBloodlustMusicTrack(trackID)
    if not (track and PlaySoundFile) then return end
    if self.musicSoundHandle and self.musicSoundOwner == owner
        and self.musicSoundTrack == trackID then
        return
    end
    if not self:StopBloodlustSound() then return end

    local ok, played, handle = pcall(PlaySoundFile, MUSIC_ROOT .. track.id, "Master")
    if ok and played then
        self.musicSoundHandle = handle
        self.musicSoundOwner = owner
        self.musicSoundTrack = trackID
        if owner == "preview" then self.musicPreviewSoundHandle = handle end
    end
end

function BBR:StopBloodlustMusicPreview()
    self:StopBloodlustSound("preview")
end

function BBR:PreviewBloodlustMusic()
    if self.nativeBloodlustMusicMode and not self:CanPreviewBloodlustMusic() then
        print("BetterBeReady: Music preview is unavailable during combat or a possible active Bloodlust song.")
        return
    end
    local settings = self:GetTrackerSettings("bloodlust")
    if settings then self:PlayBloodlustSound(settings.musicTrack, "preview") end
end

function BBR:CanPreviewBloodlustMusic()
    if InCombatLockdown and InCombatLockdown() then return false end
    local tracker = self.trackers.bloodlust
    if not (tracker and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return false end
    local aura, state = self:FindFirstAuraBySpellID(C_UnitAuras.GetPlayerAuraBySpellID, tracker.lockoutSpellIDs)
    if state == "READY" then return true end
    if state ~= "LOCKED" then return false end
    local duration, durationReadable = self:GetReadableField(aura, "duration")
    local expiration, expirationReadable = self:GetReadableField(aura, "expirationTime")
    return durationReadable and expirationReadable
        and type(duration) == "number" and type(expiration) == "number"
        and GetTime() >= expiration - duration + 40
end

function BBR:RefreshBloodlustMusicAuraSounds()
    local addSound = C_UnitAuras and C_UnitAuras.AddAuraSound
    local removeSound = C_UnitAuras and C_UnitAuras.RemoveAuraSound
    local trigger = Enum and Enum.UnitAuraSoundTrigger and Enum.UnitAuraSoundTrigger.Added
    if not (addSound and removeSound and trigger ~= nil) then
        addSound = C_UnitAuras and C_UnitAuras.AddAuraAppliedSound
        removeSound = C_UnitAuras and C_UnitAuras.RemoveAuraAppliedSound
        trigger = nil
    end
    local registrations = self.bloodlustMusicRegistrations or {}
    self.bloodlustMusicRegistrations = registrations
    self.nativeBloodlustMusicMode = not not (addSound and removeSound or next(registrations))
    if not self.nativeBloodlustMusicMode then return end

    -- Stop anything we own before installing native triggers; their individual
    -- playback handles are not exposed to Lua.
    if not self:StopBloodlustSound() then
        self.bloodlustMusicRegistrationError = "Could not stop existing playback"
        self.bloodlustMusicAuraSoundRefreshPending = true
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        self.bloodlustMusicAuraSoundRefreshPending = true
        return
    end

    local settings = self:GetTrackerSettings("bloodlust")
    local track = settings and settings.musicEnabled and self:GetBloodlustMusicTrack(settings.musicTrack)
    local trackID = track and track.id
    local tracker = self.trackers.bloodlust
    local desired = {}
    if trackID and tracker then
        -- One trigger per lockout, not per haste buff: haste buffs can be
        -- refreshed/reapplied while the ten-minute lockout is already present.
        for _, spellID in ipairs(tracker.lockoutSpellIDs) do desired[spellID] = true end
    end

    local failed = false
    self.bloodlustMusicRegistrationError = nil
    for spellID, registration in pairs(registrations) do
        if not desired[spellID] or registration.trackID ~= trackID then
            local ok = pcall(registration.remove, registration.id)
            if ok then
                registrations[spellID] = nil
            else
                failed = true
            end
        end
    end
    -- Keep failed handles, and don't add replacements until all stale triggers
    -- are removed. Repeated refreshes cannot multiply registrations.
    if failed then
        self.bloodlustMusicRegistrationError = "Aura sound removal failed; retained handles for retry"
        self.bloodlustMusicAuraSoundRefreshPending = true
        return
    end
    if addSound and removeSound then
        for spellID in pairs(desired) do
            if not registrations[spellID] then
                local sound = {
                    unitToken = "player", spellID = spellID,
                    soundFileName = MUSIC_ROOT .. trackID, outputChannel = "Master",
                }
                local ok, id
                if trigger ~= nil then
                    ok, id = pcall(addSound, trigger, sound)
                else
                    ok, id = pcall(addSound, sound)
                end
                if ok and id ~= nil then
                    registrations[spellID] = { id = id, trackID = trackID, remove = removeSound }
                else
                    failed = true
                    self.bloodlustMusicRegistrationError = "Aura sound registration failed"
                end
            end
        end
    elseif next(desired) then
        failed = true
        self.bloodlustMusicRegistrationError = "Aura sound API unavailable"
    end
    self.bloodlustMusicAuraSoundRefreshPending = failed
end

function BBR:SetBloodlustMusicTrack(trackID)
    local settings = self:GetTrackerSettings("bloodlust")
    if not settings then
        return
    end

    self:StopBloodlustMusicPreview()
    settings.musicTrack = self:GetBloodlustMusicTrack(trackID) and trackID or ""
    self:RefreshBloodlustMusicAuraSounds()
    local tracker = self.trackers.bloodlust
    if tracker and tracker.OnMusicSelectionChanged then
        tracker:OnMusicSelectionChanged()
    end
    if self.RefreshConfig then
        self:RefreshConfig()
    end
end

function BBR:SetBloodlustMusicEnabled(enabled)
    local settings = self:GetTrackerSettings("bloodlust")
    if not settings then
        return
    end

    settings.musicEnabled = enabled and true or false
    self:StopBloodlustMusicPreview()
    self:RefreshBloodlustMusicAuraSounds()

    local tracker = self.trackers.bloodlust
    if tracker and tracker.OnMusicEnabledChanged then
        tracker:OnMusicEnabledChanged(settings.musicEnabled)
    end
    if self.RefreshConfig then
        self:RefreshConfig()
    end
end
