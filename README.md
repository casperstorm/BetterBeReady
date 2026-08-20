# BetterBeReady

BetterBeReady is a lightweight World of Warcraft addon that keeps personal and encounter readiness information visible without tracking other players' auras.

Made for Midnight.

## Trackers

- **Bloodlust safety** — green when the player has no Bloodlust lockout and red while Sated, Exhaustion, Temporal Displacement, Fatigued, or Insanity is active. The cooldown swipe shows the relevant remaining duration. Hunters are detected through Command Pet's live Ferocity override; other pet specializations remain gray.
- **Battle res charges** — displays the encounter's shared battle-res count and native recharge countdown using the same Rebirth charge source used by MRT.
- **Combat time** — starts on encounter start or when the player enters combat and stops after the encounter/combat ends.

Each tracker can be enabled, moved, and resized independently, including during combat while unlocked. Icon and text sizes are configured separately, and the battle-res recharge time can be hidden.

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

## Packaging

GitHub and CurseForge releases are built with BigWigsMods Packager using CurseForge project ID `1660956`. Add a `CF_API_KEY` repository secret before running the release workflow.

## License

BetterBeReady is released under the GPL-3.0 License. See [LICENSE](LICENSE).
