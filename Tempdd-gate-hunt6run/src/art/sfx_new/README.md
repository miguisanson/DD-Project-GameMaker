# New monster sound takes (D116)

30 extra takes for the 10 monsters: 1 more spawn take and 2 more attack ("special") takes each, so every monster key has 2-4 takes to rotate through.
All come from four CC0 packs on OpenGameArt. The licence line on each pack page was read on 2026-10-15 and says **CC0** (public domain dedication,
https://creativecommons.org/publicdomain/zero/1.0/). Credit is not required; the authors are named in the credits roll anyway (`Credits_NewSfxAssets` in `scripts/scr_dialogue/scr_dialogue.gml`).

| Pack (author) | Page | Licence | Files used |
|---|---|---|---|
| 80 CC0 creature SFX (rubberduck) | https://opengameart.org/content/80-cc0-creature-sfx | CC0 1.0 | 11 |
| 80 CC0 creture SFX #2 (rubberduck) | https://opengameart.org/content/80-cc0-creture-sfx-2 | CC0 1.0 | 15 |
| Monster Sound Effects Pack (Ogrebane) | https://opengameart.org/content/monster-sound-effects-pack | CC0 1.0 | 2 |
| Monster snarls (Darsycho) | https://opengameart.org/content/monster-snarls | CC0 1.0 | 2 (cut from long files with several snarls) |

## How they were made
`art/tools/build_sfx_new.py` (Python + numpy + the GameMaker runtime's ffmpeg). Each take: cut, silence trimmed, 3 ms fade in and 15 ms fade out,
mono, 44.1 kHz, 16-bit WAV (the same sample rate and channel format as the existing monster sounds, which are a mix of ogg, wav and mp3).
Loudness: the RMS of the active part is matched to the existing take of that monster and event (the "reference" column), and the peak is capped at -1 dBFS.
Where the cap bites (marked below) the take ends up 1-3 dB under its reference. `killer_plant_spawn_2` aims at -30 dB RMS, not at the existing spawn
sound, because that sound is extremely quiet (-46 dB RMS, peak -31 dB); the owner may want to look at `killer_plant_spawn` itself.

**Picked from the pack category names (slime, bug, howl, roar, alien, ...) plus length and brightness against the existing take. Nobody has listened to them yet.**
Audition them in the game; any take that does not fit can simply be left out of the import (the code skips names that are not imported) or deleted later.

## Files

| New file | Author | Pack | Original file | Loudness reference (existing sound) |
|---|---|---|---|---|
| `slime_spawn_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `slime_08.ogg` | `Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing` |
| `slime_attack_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `slime_01.ogg` | `Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing` |
| `slime_attack_3.wav` | rubberduck | 80 CC0 creture SFX #2 | `slime_04.ogg` | `Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing` |
| `spider_spawn_2.wav` | rubberduck | 80 CC0 creature SFX | `bug_01.ogg` | `spider_both_attack_and_spawn` |
| `spider_attack_2.wav` | rubberduck | 80 CC0 creature SFX | `bug_02.ogg` | `Hiss` |
| `spider_attack_3.wav` | rubberduck | 80 CC0 creture SFX #2 | `bug_12.ogg` | `Hiss` |
| `snake_spawn_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `misc_14.ogg` | `snake_spaawn_and_attack` |
| `snake_attack_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `attack_02.ogg` | `snake_spaawn_and_attack` |
| `snake_attack_3.wav` | rubberduck | 80 CC0 creture SFX #2 | `attack_03.ogg` | `snake_spaawn_and_attack` |
| `dire_wolf_spawn_2.wav` | rubberduck | 80 CC0 creature SFX | `howl.ogg` | `dire_wolf_spawn` |
| `dire_wolf_attack_2.wav` | rubberduck | 80 CC0 creature SFX | `barking_02.ogg` | `dire_wolf_attack` |
| `dire_wolf_attack_3.wav` | Darsycho | Monster snarls | `monster-snarl-attack.ogg` (cut 1.61-2.91 s) | `dire_wolf_attack` |
| `killer_plant_spawn_2.wav` | rubberduck | 80 CC0 creature SFX | `burble_01.ogg` | `killer_plant_spawn` |
| `killer_plant_attack_2.wav` | rubberduck | 80 CC0 creature SFX | `eat_04.ogg` | `killer_plant_attack` |
| `killer_plant_attack_3.wav` | rubberduck | 80 CC0 creature SFX | `eat_03.ogg` | `killer_plant_attack` |
| `mad_whisp_spawn_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `alien_08.ogg` | `mad_whisp_spawn` |
| `mad_whisp_attack_2.wav` | rubberduck | 80 CC0 creature SFX | `alien_02.ogg` | `mad_whisp_attack` |
| `mad_whisp_attack_3.wav` | rubberduck | 80 CC0 creture SFX #2 | `alien_10.ogg` | `mad_whisp_attack` |
| `ghost_sword_spawn_2.wav` | rubberduck | 80 CC0 creature SFX | `ooh.ogg` | `ghost_sword_spawn` |
| `ghost_sword_attack_2.wav` | rubberduck | 80 CC0 creature SFX | `alien_05.ogg` | `ghost_sword_attack` |
| `ghost_sword_attack_3.wav` | rubberduck | 80 CC0 creture SFX #2 | `alien_11.ogg` | `ghost_sword_attack` |
| `stranger_spawn_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `human_03.ogg` | `Laugh_spooky_3` |
| `stranger_attack_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `human_07.ogg` | `Monster_chatter` |
| `stranger_attack_3.wav` | rubberduck | 80 CC0 creture SFX #2 | `human_05.ogg` | `Monster_chatter` |
| `mini_boss_spawn_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `roar_04.ogg` | `mini_boss_spawn` |
| `mini_boss_attack_2.wav` | Ogrebane | Monster Sound Effects Pack | `monster-6.wav` | `mini_boss_attack` |
| `mini_boss_attack_3.wav` | Ogrebane | Monster Sound Effects Pack | `monster-8.wav` | `mini_boss_attack` |
| `final_boss_spawn_2.wav` | rubberduck | 80 CC0 creature SFX | `roar_02.ogg` | `final_boss_spawn` |
| `final_boss_attack_2.wav` | rubberduck | 80 CC0 creture SFX #2 | `stomp_01.ogg` | `Punch_1` |
| `final_boss_attack_3.wav` | Darsycho | Monster snarls | `monster-snarl-5.ogg` (cut 2.02-3.49 s) | `Punch_1` |

The resource name is the file name without `.wav`; the code finds `<monster>_spawn_2..4` and `<monster>_attack_2..4` by name (`SFX_RegisterEnemyVariants`).
Import steps: `IMPORT.md`.
