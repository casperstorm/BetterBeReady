# BetterBeReady

BetterBeReady is a lightweight World of Warcraft addon that keeps personal and encounter readiness information visible without tracking other players' auras.

Made for Midnight.

## Trackers

- **Bloodlust safety** — green when the player can cast Bloodlust without a lockout and red while Sated, Exhaustion, Temporal Displacement, Fatigued, or Insanity is active. Shaman Bloodlust/Heroism, Mage Time Warp, Evoker Fury of the Aspects, Hunter Primal Rage, and Marksmanship Hunter Harrier's Cry are detected as castable lusts. Every class tracks received lust effects—including drums—and its personal lockout: text mode shows a fast animated rainbow `BL ACTIVE | 00:40`, then returns to the lockout countdown when the buff ends. Bloodlust-capable characters finally show `BL | READY`; other characters show `BL | -`. Countdown times always use `mm:ss`, and text can be aligned left or right so its chosen edge stays fixed. Ferocity pets are detected through Command Pet's live Primal Rage override.

- **Battle res charges** — displays the encounter's shared battle-res count and native recharge countdown using the same Rebirth charge source used by MRT. It can be shown as the existing icon or as a compact text row (`1 | 01:02`), using `-` when no recharge is active. Text can be aligned left or right so the selected edge stays fixed.
- **Combat potion** — scans the player's bags for current Midnight combat potions and displays `POT | READY`, the shared five-minute cooldown, or `POT | -` when none are available. It is always text-only and supports configurable text size and left/right alignment.
- **Combat time** — starts on encounter start or when the player enters combat and stops after the encounter/combat ends. It uses a stable `m:ss` display (`0:00`).

Each tracker can be enabled, moved, and resized independently, including during combat while unlocked. Icon and text sizes are configured separately, and the battle-res recharge time can be hidden.
All four trackers use their text display and a 16 px font by default; Bloodlust and Battle res can still be switched to icons in settings.

Bloodlust's Show visuals and Enable music settings are independent, so music can play with the timer and icon hidden. Music defaults to Dave Rodgers - Deja Vu, with 60 tracks and a No sound option. Blizzard's native sound API watches new Exhaustion/Sated-family lockouts, so playback does not depend on Lua reading secret aura timing. Refreshes of the haste buff do not retrigger this registration. Registrations are reused for unchanged settings; failed removals retain their handles and block replacements until cleanup succeeds. The addon never starts a second automatic playback path alongside native triggers.

Tracks are capped to 40 seconds. Native playback cannot be stopped early through the registration ID; changing the selection or disabling music affects future triggers. Settings changes during combat are applied on leaving combat. Play and Stop control settings previews, which are unavailable in combat or while native music might still be playing. Clients without the native sound API use guarded, single-handle playback when aura timing is readable.

## Usage

Type `/bbr` or `/betterbeready` to open the configuration window.

Left-click any visible tracker to open the configuration window. When unlocked, dragging a tracker moves it without opening the window.

- `/bbr lock`
- `/bbr unlock`
- `/bbr reset`
- `/bbr close`
- `/bbr debug`

The settings window can always be closed with its X button, Escape, `/bbr`, or `/bbr close`, including during combat.

## Midnight API safety

The Bloodlust lockout family is currently classified as readable (`NeverSecret`) by the 12.1 client. BetterBeReady still guards every aura read and fails closed with a gray icon rather than incorrectly reporting that Bloodlust is safe.

Battle-res charge and cooldown fields may be secret during combat. BetterBeReady never compares or performs arithmetic on those values; it passes them directly to Blizzard font and cooldown widgets.

Combat-potion cooldowns use Blizzard's item cooldown API with fixed, non-secret Midnight item IDs. Returned values are checked before the addon calculates or displays the shared cooldown.

## Packaging

GitHub and CurseForge releases are built with BigWigsMods Packager using CurseForge project ID `1660956`. Add a `CF_API_KEY` repository secret before running the release workflow.

## License

BetterBeReady is released under the GPL-3.0 License. See [LICENSE](LICENSE).
