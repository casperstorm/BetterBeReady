local _, BBR = ...

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

function BBR:StopBloodlustMusicPreview()
    if self.musicPreviewSoundHandle and StopSound then
        pcall(StopSound, self.musicPreviewSoundHandle)
    end
    self.musicPreviewSoundHandle = nil
end

function BBR:PreviewBloodlustMusic()
    self:StopBloodlustMusicPreview()

    local settings = self:GetTrackerSettings("bloodlust")
    local track = settings and self:GetBloodlustMusicTrack(settings.musicTrack)
    if not (track and PlaySoundFile) then
        return
    end

    local soundPath = "Interface\\AddOns\\BetterBeReady\\Media\\BloodlustMusic\\" .. track.id
    local callOK, played, soundHandle = pcall(PlaySoundFile, soundPath, "Master")
    if callOK and played then
        self.musicPreviewSoundHandle = soundHandle
    end
end

function BBR:SetBloodlustMusicTrack(trackID)
    local settings = self:GetTrackerSettings("bloodlust")
    if not settings then
        return
    end

    self:StopBloodlustMusicPreview()
    settings.musicTrack = self:GetBloodlustMusicTrack(trackID) and trackID or ""
    local tracker = self.trackers.bloodlust
    if tracker and tracker.OnMusicSelectionChanged then
        tracker:OnMusicSelectionChanged()
    end
    if self.RefreshConfig then
        self:RefreshConfig()
    end
end
