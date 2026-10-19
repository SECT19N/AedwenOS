# AedwenOS — brag plan

**What it is:** An Arch-based Linux distribution (rolling, linux-zen, Btrfs, Limine, KDE Plasma on Wayland) with its own Material 3 Expressive desktop shell and theme.
**Who it's for:** People who want Arch underneath and a desktop that looks designed, from boot menu to cursor.
**What sets it apart:** One palette (`scripts/palette_lib.py`) generates *everything*: the Limine boot menu, the Plymouth splash, the Calamares installer, KDE colours, GTK, the Plasma theme, cursors, and even system sounds. And a hand-built shell (dock, launcher, quick settings, notifications) on top of Plasma.
**Most impressive / funniest claim:** Pick one seed colour and the whole OS follows. Funniest: Arch breaks, but snapper and limine-snapper-sync put yesterday in the boot menu.
**Visual hook:** The real M3E shape-morphing boot loader (circle → burst → cookie → pentagon → pill → sunny), ported from `generate-plymouth-assets.py`.
**Real UI shown:** Boot splash, desktop shell (top bar, dock, quick settings tiles), Calamares welcome/finished pages, Limine menu.
**Tone:** `polished`, using Material 3 Expressive spring motion (`cubic-bezier(.34,1.45,.55,1)`, the shell's own easing).
**Share caption:** "AedwenOS: Arch underneath, Material 3 Expressive on top, and one seed colour restyles everything from the boot menu to the cursor."

## Angle
"Arch, designed." Every scene is a different layer of the OS, and the same palette carries through all of them. The accent swap is the centrepiece.

## Visual identity
- Violet seed, dark, expressive palette from `palette_lib.palette(295, dark=True, expressive=True)`; other seeds for the recolour scene.
- Roboto Flex (the design's font), Roboto Mono for the boot menu, and Material Symbols Rounded from `org/aedwen/ui/fonts`.
- Shapes: rWin 16, rPop 32, rCard 20, rTile 12, pills.
- Real assets: the `eagle.svg` path, the wallpaper composition, and the `.oga` system sounds (C major).

## Storyboard (22s, 30fps, 120 BPM → cuts on bar/half-bar)
| # | Time | Scene | On screen | Caption | Sound |
|---|---|---|---|---|---|
| 1 | 0.0–3.0 | Hook: boot splash | Large morphing loader on #0d0b13, which settles. The "AedwenOS" wordmark springs in. | **AedwenOS** / "Arch Linux, dressed in Material 3 Expressive." | Pad swell plus pluck arp |
| 2 | 3.0–7.0 | Reveal: desktop | The loader circle expands into a mask that reveals the desktop (wallpaper eagle, top bar, dock). The cursor clicks the status area and Quick Settings springs open with its tiles; the Wi‑Fi and Dark mode tiles are active. | "Its own desktop shell, on KDE Plasma." | `desktop-login.oga` at the reveal; kick enters |
| 3 | 7.0–12.0 | Highlight: one seed | An accent row in the panel. Each click sends a circular ripple from the cursor that recolours *everything* (wallpaper eagle, tiles, dock, panel): violet → teal → rose → blue. Then a chip cascade: Boot menu · Splash · Installer · Shell · GTK · Cursors. | "Pick one colour. Everything follows." | Soft click per swatch (`audio-volume-change.oga`) |
| 4 | 12.0–16.0 | Highlight: installer | Calamares window: step sidebar, "Welcome to AedwenOS", the 10‑minute line and requirement chips. "Install now" is pressed; the progress pill fills; the page morphs to "AedwenOS is installed". | "A graphical installer. About 10 minutes." | `completion-success.oga` |
| 5 | 16.0–19.0 | Punchline: rollback | The Limine menu card (branding #cdacff, mono entries). The highlight slides past linux-zen and fallback into Snapshots → yesterday's pre‑pacman snapshot. | "Broke it? Boot yesterday." | `message-new-instant.oga` on select |
| 6 | 19.0–22.0 | Outro | Eagle in the asymmetric "morph" shape, wordmark, facts line, repo URL. | "Arch-based · rolling · pre-alpha" / github.com/SECT19N/AedwenOS | Final chord rings out |

Durations: 3 + 4 + 5 + 4 + 3 + 3 = **22s**.

## Sound
An original 120 BPM C‑major bed (C–Am–F–G): a warm pad, a soft sine/triangle pluck arpeggio, sub bass and a soft kick from the reveal on. The project's own system sounds are already in C major, so they sit inside the mix at low gain through the same reverb.
