# NO HOPE - release credits research (read-only; nothing in the repo was edited)

Repo checked: `E:\Github_Projects\DD-Project-GameMaker-wt\next`. Date: 2026-10-17.
Method: itch, OpenGameArt and other pages fetched with WebFetch (page text as summarised by the fetch tool, not a browser); the audio files in `sounds/` read directly for embedded tags (author, album, encoder). **I did not download any pack** (downloading needs the owner's OK), so I could not compare files against the packs.
Legend: **[page]** = read on the page this session. **[file]** = read from the file's own tags. **[repo]** = read in the repo. **[inferred]** = my guess.

---

## 0. Headline - read this first

The owner's list of four itch.io packs does **not** match the sounds in the game.

| Source | Files in game | How I know | On the owner's list? |
|---|---:|---|---|
| Universal UI/Menu Soundpack, Cyrex Studios / Nathan Gibson | **52** | **[file]** Logic Pro X tags, dated 2021-09-27; **[page]** pack has exactly 52 files: Modern, Retro, Minimalist, African, Wood Block, Coffee, Abstract. The game has Modern 16, Retro 12, Minimalist 13, African 4, Wood_Block 3, Coffee 2, Abstract 2 = 52 | **NO** |
| Fesliyan Studios (fesliyanstudios.com) | **28** tagged + 1 by name | **[file]** tags `www.fesliyanstudios.com`, some `ARTIST=Rupert_Spore`, with Fesliyan track numbers | **NO** |
| Ifness, Fantasy Vol. 3 Kingdoms | **2** (`Arrival`, `The_Twilight_of_Camelot`) | **[file]** ID3 album "Fantasy Vol 3 Kingdoms", artist Justin Allan Arnold; **[page]** both are in the track list | yes |
| Atelier Magicae (2 packs) / YourPalRob | **cannot tell** | the remaining files have their tags stripped; the pack pages list no file names | yes, but nothing matched |
| Looks ripped from YouTube / a video | **5** | **[file]** video-container tags (`dash`, `iso6mp41`, `Lavf58-60`); **[inferred]** from names like `..._Minecraft_Sound____Sound_Effect_for_editing` | no |
| CC0 monster takes (D116, OpenGameArt) | **30** | **[repo]** `art/sfx_new/README.md`; the four OGA licence fields re-read **[page]** | n/a (CC0) |

Totals: 126 original + 30 CC0 = **156** sound folders (matches `sounds/`).
Only 2 of the 126 originals are positively tied to a pack on the owner's list. 38 originals cannot be assigned to any source from what is on disk, and 5 more look ripped.

The in-game credits roll (`Credits_SoundAssets` in `scripts/scr_dialogue/scr_dialogue.gml`) still shows `(owner to supply)` for all 126 original sounds. That must be replaced before release.

---

## 1. Sound resources mapped to sources

The `.yy` files only record the resource name; the file name inside is always the same as the resource name, so the mapping below is from file tags, names and the git history (import batches 2026-02-24/25/28 and 2026-10-15).

### A. Universal UI/Menu Soundpack - Cyrex Studios / Nathan Gibson - 52 files (CC BY 4.0, credit required)
`Abstract1-2` (2), `African1-4` (4), `Coffee1-2` (2), `Minimalist1-13` (13), `Modern1-16` (16), `Retro1-12` (12), `Wood_Block1-3` (3).
Evidence: **[file]** all 52 have `encoded_by=Logic Pro X`, `date=2021-09-27`; **[page]** "52 audio files", same category names. Strong match.

### B. Fesliyan Studios - 28 tagged + 1 by name
Tagged **[file]** (artist/album/comment `www.fesliyanstudios.com` or `FesliyanStudios.com`; the "Horror" genre ones carry `ARTIST=Rupert_Spore`):
`Ambience_haunting`, `Ambience_haunting_2`, `Bite_2`, `Body_falling_wood`, `Crying_moaning_ambience`, `Crying_moaning_ambience_2`, `Dropping_keys`, `Fireball_2`, `Ghost_scream_3`, `Hiss`, `Knife_stab`, `Laugh_evil_deep_3`, `Laugh_spooky_3`, `Laugh_spooky_4`, `Liquid_slosh`, `Metal_resonance` (artist "David Fesliyan"), `Monster_Roar_5`, `Monster_Roar_9`, `Monster_chatter`, `Monster_chatter_2`, `Monster_chatter_3`, `Monster_chatter_4`, `Punch_1`, `Punch_2`, `Punch_3`, `Punch_crunchy`, `Punch_crunchy_2`, `Whip_2`.
By name only **[inferred]**: `Crying_moaning_ambience_3` (a .wav with no tags, same series, added later).
Why it matters: the owner may believe these came from YourPalRob's pack. The files say Fesliyan Studios. YourPalRob's page lists no file names, so I cannot prove the pack does not contain them, but the tags are clear about the origin.

### C. Ifness (Justin Allan Arnold) - Fantasy Vol. 3 Kingdoms - 2 files, CC BY 4.0
`Arrival`, `The_Twilight_of_Camelot`. **[file]** ID3 + **[page]** both in the nine-track list. Verified.

### D. Look like YouTube / video rips - 5 files - UNKNOWN source, HIGH RISK
`Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing`, `GooeySlime___Sound_Effect`, `Slice_Whoosh_Sound_Effect`, `spider_both_attack_and_spawn`, `snake_spaawn_and_attack`.
Evidence: **[file]** video-container tags (`major_brand dash`, `isom`/`iso6mp41`), **[inferred]** YouTube-title style names. The first is named as a Minecraft sound (Mojang/Microsoft). These are the base sounds for the Slime, Spider and Snake monsters (also the loudness reference for the CC0 takes in `art/sfx_new/README.md`).

### E. Tags stripped, no source recorded - 38 files - UNKNOWN (probably the owner's packs, not proven)
- Monster originals (11): `dire_wolf_attack`, `dire_wolf_spawn`, `final_boss_spawn`, `ghost_sword_attack`, `ghost_sword_spawn`, `killer_plant_attack`, `killer_plant_spawn`, `mad_whisp_attack`, `mad_whisp_spawn`, `mini_boss_attack`, `mini_boss_spawn`. Plausibly the Atelier Magicae beast/monster packs **[inferred]**.
- Combat / skill / world sounds (25): `Blocked`, `Bow_Attack_`, `Bow_Impact_Hit_`, `barrel_break`, `bleed`, `chest_open`, `double_shot`, `evasion_up`, `fireball`, `foresight`, `horinzotal_slash`, `horizontal_slash`, `ice_spear`, `kill_torch`, `mage_attack`, `meditation35`, `miss_effect`, `miss_effect2`, `muscle_up`, `rev_up`, `stun`, `sword_attack`, `sword_impact`, `take_aim`, `waterspray`.
- Music (2): `overall_bgm` (3.3 MB), `forest_bgm__for_everymap_with_trees` (3.7 MB; the name reads like a track title).
None of the packs on the owner's list is described as containing combat or skill sounds (Atelier = beasts/monsters, YourPalRob = horror, Ifness = fantasy music), so many of these are probably from yet another source, and the two BGMs match nothing **[inferred]**.

### F. CC0 monster takes (sfx_new, D116) - 30 files, CC0 (already imported)
rubberduck 26 files ("80 CC0 creature SFX" 11 + "80 CC0 creture SFX #2" 15), Ogrebane 2 (`mini_boss_attack_2`, `mini_boss_attack_3`), Darsycho 2 (`dire_wolf_attack_3`, `final_boss_attack_3`). Per-file table: `art/sfx_new/README.md` **[repo]**.

Counts: A 52 + B 29 + C 2 + D 5 + E 38 = 126 originals; plus F 30 = 156.
UNKNOWN by name = groups D + E (43 files, listed above).

---

## 2. Licence terms per source

### Universal UI/Menu Soundpack (Cyrex Studios / Nathan Gibson) - https://cyrex-studios.itch.io/universal-ui-soundpack
- **[page]** "Asset license: Creative Commons Attribution v4.0 International"; "Licence: CC BY 4.0 to credit 'Nathan Gibson'."
- Commercial, creator comment **[page]**: "You are free to use these sounds for your paid game!"
- Credit form, creator comments **[page]**: "Sound effects: Nathan Gibson (Link to asset used)"; also a plain username in the credits list is enough, "no need for any links".
- CC BY 4.0 itself (general knowledge, not from the page): name the creator, link the licence, say if changed. Using it inside a game is fine.
- Credit **required**. Free and paid release both OK.

### Fesliyan Studios sound effects - https://www.fesliyanstudios.com/sound-effects-policy
- **[page]** Credit is "optional" (suggested line "free sound effects from https://www.fesliyanstudios.com"). Donation encouraged, not required. "video games" listed as a proper use. Not allowed to be reposted elsewhere or put in other sound libraries.
- Caution: Fesliyan's **music** policy (https://www.fesliyanstudios.com/policy) says **[page]** "A donation is required in order to obtain a commercial-use license", and non-commercial use needs a credit link if you have not donated. `Ambience_haunting`, `Ambience_haunting_2` (track numbers 4 and 6) and `Metal_resonance` (track 5, genre "Instrumental") are low-numbered and might come from the music side **[inferred]**. If so, a paid release needs a donation; a free release needs the credit link. Safest: credit Fesliyan either way.

### Ifness - Fantasy Vol. 3 Kingdoms - https://ifness.itch.io/fantasy-vol-3-kingdoms
- **[page]** "provided under the Creative Commons Attribution license" (CC-BY 4.0); "can be used in private and commercial projects for free."; the artist must be "properly credited in each project where his tracks are used."
- Credit **required**: Justin Allan Arnold (Ifness), ifnessfreemusic.com (from the file tags). The page also offers non-attribution licences on his website.
- Free and paid release OK.

### Atelier Magicae - Beasts SFX Vol.1 - https://ateliermagicae.itch.io/beasts-sfx-vol1
- **[page]** No formal licence field. Creator comment: "You can use it and modify it for any purpose" and "not for re-distribution as-is."
- Credit: none stated. Name your own price. One file `Beasts.rar` (4.4 MB), no file names on the page. Page says "No generative AI was used".

### Atelier Magicae - Monster Sound Effects Vol.1 - https://ateliermagicae.itch.io/monster-sound-effects-vol1
- **[page]** Creator comment: "They can be used commercially, non-commercially, and for personal projects." and "Just no re-distribution c:". Credit: not stated (a commenter asked, no answer shown). One file `Monsters SFX Vol.1.rar` (7.1 MB), no file names.
- Weak spot: the terms exist only in a comment, not a licence field. Keep a screenshot.

### YourPalRob - Must Have Horror Sound Effects - https://yourpalrob.itch.io/must-have-horror-sound-effects
- **[page]** "You are granted the right to use these sound effects in any personal, commercial, or non-commercial project"; video games allowed "without further royalties or permissions"; "No credit necessary" (appreciated); "NOT permitted to resell, redistribute, or repackage these sound effects as standalone files."
- 1,120 sounds; 150 free, the rest $1+. If any sound came from the paid part, the owner should hold that purchase. No file names listed.

### CC0 - OpenGameArt (licence fields re-read this session, **[page]**)
- rubberduck, "80 CC0 creature SFX" https://opengameart.org/content/80-cc0-creature-sfx and "80 CC0 creture SFX #2" https://opengameart.org/content/80-cc0-creture-sfx-2: CC0, no credit request.
- Ogrebane, "Monster Sound Effects Pack" https://opengameart.org/content/monster-sound-effects-pack: CC0, no credit request.
- Darsycho, "Monster snarls" https://opengameart.org/content/monster-snarls: CC0; page says "credit is appreciated!" (a request, not a condition).

### Kenney 1-Bit Pack (art)
CC0, `art/sources/kenney-1bit/License.txt` **[repo]**. Credit is a courtesy.

### Candidate music and refuse sounds (`art\audio_candidates\PICK.md`, not imported) - licence field re-read this session **[page]**
| id | Title | Author | Licence | Credit asked |
|---|---|---|---|---|
| B1 | 8-Bit Battle Loop | Wolfgang_ | CC0 | welcome, not required; author suggests "Theodore Kerr" |
| B2 | 8-bit RPG Battle/Encounter Theme (top pick) | Wolfgang_ | CC0 | not required; attribution field says "Ted Kerr". Page does not state that it loops (only the file name "Loopable") |
| B3 | Battle vs Minor Gyokaijuu | Spring Spring | CC0 | notice: "Produced by Julie Damsgaard/Spring Spring/Spring Enterprises @ https://spring-enterprises.neocities.org" |
| B4 | 8 Bit Battle Theme | celestialghost8 | CC0 | "none necessary if you want, just include celestialghost in the credits" |
| K1 | Boss Battle #5 | nene | CC0 | none |
| K2 | 8bit Action Boss Battle (top pick) | MintoDog | CC0 | none; page: "This music is loopable." |
| K3 | Great Boss | Spring Spring | CC0 | same notice as B3 |
| R1/R2 | Wrong 1 / Wrong 3 (8-Bit SFX Pack 001) | Deva | CC0 | page: "just please credit me as @Shades" (https://soundcloud.com/noshades) |
All CC0, so no condition on any of them. PICK.md's licence claims are confirmed. Whichever is picked, add the author line as a courtesy.

---

## 3. Fonts

| Font | Where | Licence | Verified how | Licence text must ship? |
|---|---|---|---|---|
| **Galmuri9 / Galmuri11** (Lee Minseo, quiple.dev), the Korean UI font loaded by `font_add` in `scr_player.gml` | `datafiles/fonts/galmuri/` | SIL OFL 1.1 | **[repo]** `OFL-Galmuri.txt` sits next to the fonts and is listed in the `.yyp` as an Included File; **[file]** name table says OFL 1.1 | Yes (the OFL needs the licence text to travel with the font). It already does as an Included File. Keep it in the release zip. |
| **Retro Gaming** (English UI font, `fonts/retro_gaming/retro_gaming.yy`, baked into a texture; no .ttf in the repo) | `fonts/retro_gaming/` | **UNVERIFIED.** Author Daymarius; dafont page https://www.dafont.com/retro-gaming.font shows "100% Free" and says nothing on commercial use **[page]**. No licence file in the repo; the roll says only "Retro Gaming pixel font" | - | Unknown. Find the readme in the original download or ask the author. |
| `monogram`, `early_gameboy` (`*.old.*`) | `fonts/retro_gaming/` | monogram CC0 per `.planning/research/retro-ui.md` (not re-checked); early_gameboy unknown | **[repo]** the code does not use them | - |
| **NotoSansCJKkr-Regular.otf** (Adobe/Google) | `datafiles/fonts/` (16 MB), Included File | SIL OFL 1.1 | **[file]** name table says OFL 1.1; copyright Adobe 2014-2021 | Yes if shipped. No licence text ships with it. The code never loads it (**[repo]** grep). |
| **NanumGothic-Regular.ttf** (NHN) | `datafiles/` (2 MB), Included File | Nanum fonts are SIL OFL **[inferred; the file only holds a copyright line]** | **[file]** "Copyright 2011 NHN Corporation... Sandoll" | Yes if shipped. No licence text. The code never loads it. |

Recommendation: Noto and Nanum are unused (the only `font_add` call loads Galmuri). Remove both from Included Files in the IDE: saves about 18 MB and two licence obligations.

---

## 4. Ready-to-use credits text (in-game roll and CREDITS.txt)

Lines marked `[OWNER: ...]` need a decision. Lines marked `(pending)` credit sources that are probable but not verified; delete them if the sound turns out to come from elsewhere.

```
NO HOPE
a game by PaleRook

Made with GameMaker

ART
Game art by PaleRook
Icon bases: Kenney 1-Bit Pack (CC0) - kenney.nl
Battle backgrounds were made with AI assistance:
  Stable Diffusion XL 1.0 with the Pixel Art XL LoRA (nerijs),
  then chosen and edited by PaleRook.
[OWNER: confirm who drew the characters, tiles, maps and ending scene - see section 5, item 11]

MUSIC
"Arrival" and "The Twilight of Camelot" by Justin Allan Arnold (Ifness)
  from "Fantasy Vol. 3 Kingdoms" - ifnessfreemusic.com
  Licensed under CC BY 4.0 - creativecommons.org/licenses/by/4.0/
[OWNER: battle music pick, e.g. "<title> by <author> (CC0), opengameart.org"]
[OWNER: boss music pick]
[OWNER: overall_bgm and forest_bgm - source unknown, see section 5]

SOUND EFFECTS
UI sounds: "Universal UI/Menu Soundpack" by Nathan Gibson (Cyrex Studios)
  Licensed under CC BY 4.0 - creativecommons.org/licenses/by/4.0/
  cyrex-studios.itch.io/universal-ui-soundpack
Horror and impact sounds: Fesliyan Studios - fesliyanstudios.com
Monster sounds: Atelier Magicae - ateliermagicae.itch.io          (pending)
Horror sound effects: YourPalRob - yourpalrob.itch.io             (pending)
Monster takes: rubberduck, Ogrebane, Darsycho (CC0) - opengameart.org
[OWNER: refuse sound if picked: "Wrong 1" by Deva (@Shades), CC0]

FONTS
Galmuri by Lee Minseo - SIL Open Font License 1.1 (licence text in the game folder)
Retro Gaming font by Daymarius                                    (pending licence check)

Thank you for playing.
by PaleRook
```
Notes: today's `Credits_Lines()` prints one line per creator followed by a long list of asset names. Replace that block with the section above (the `Loc_T` keys also need Korean text). Put the OFL text, this file as `CREDITS.txt`, and the CC BY 4.0 link in the release zip.

---

## 5. What would block or complicate a free or paid itch.io release

BLOCKERS (fix or remove before release):
1. **5 files that look ripped from YouTube** (group D), one named as a Minecraft sound. No licence can be shown for them. They are the base slime, spider and snake sounds. Replace them (the 26 rubberduck CC0 takes already in the game include slime, spider and snake takes, and the code rotates takes) or find the true source. Free vs paid makes no difference.
2. **38 sounds with no source** (group E), including both background tracks `overall_bgm` and `forest_bgm__for_everymap_with_trees`. For the 11 monster sounds the Atelier Magicae packs are a plausible source, but nothing proves it. To close this: download the three packs (needs the owner's go-ahead; Atelier packs are 4-7 MB, the YourPalRob free zip is 210 MB) and compare the files. Anything that matches no pack should be replaced or dropped.
3. **Credits roll still says "(owner to supply)"** for all 126 originals. Replace with section 4.

MUST-DO (terms known):
4. **CC BY 4.0 needs credit** for the Cyrex UI pack (52 sounds) and the Ifness music (2 tracks). Both are in section 4. Neither blocks a free or paid release when the credit is present.
5. **Cyrex and Fesliyan are not on the owner's list.** The belief that the sounds come from the four listed packs is wrong for 81 of the 126 originals. Tell the owner.

CAUTIONS:
6. Fesliyan: if `Ambience_haunting`, `Ambience_haunting_2` or `Metal_resonance` come from the music side, a paid release needs a donation; free needs the credit link. SFX credit is optional.
7. Atelier Magicae terms exist only as creator comments, with no stated credit. Keep screenshots. "No re-distribution as-is": sounds inside `data.win` are fine; do not ship loose sound files or a sound-only download.
8. YourPalRob: if a sound is from the paid 970, hold the $1 purchase. No credit required.
9. **Retro Gaming font** licence is unverified. Ask the author or switch English text to a verified font (Galmuri covers Latin; Monogram is CC0).
10. Noto Sans CJK and NanumGothic ship unused (18 MB) with no licence text. Remove from Included Files.
11. **Art provenance** is recorded only for the icons (`art/strips_v2/SOURCES.txt`: 46 hand redraws, no Kenney or AI finals listed) and the AI battle backgrounds (`art/CREDITS-ART.md`). The 145 sprite folders in `sprites/` (characters, tiles, ending scene), mostly from the January 2026 import, have no source note. If the owner did not make them all, they need one.
12. AI disclosure: itch.io lets creators declare AI-generated assets on the project page; the four battle backgrounds are AI-assisted. SDXL base 1.0 is OpenRAIL++-M (from CREDITS-ART.md, not re-read); the Pixel Art XL model card says "creativeml-openrail-m" **[page]**; I did not read its commercial-use terms on the page.
13. Candidate music (B1-B4, K1-K3, R1-R3) is CC0 on every page checked: no blocker whatever is chosen. B2's "loops" claim rests on the file name, not page text.
