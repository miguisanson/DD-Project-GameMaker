# Importing the new monster takes in GameMaker (owner, about 10 minutes)

The code already looks for these sounds by name (`asset_get_index`), so the game works before and after the import: a take that is not imported is just not in the rotation.
Do not edit `DD-Project.yyp` or any `.yy` by hand; the IDE writes them.

## Steps
1. Open `DD-Project.yyp` in GameMaker (runtime 2024.14.3.260).
2. In the Asset Browser open `Sounds > Entities > Monsters`. There is one folder per monster (Slime, Spider, Snake, Dire Wolf, Killer Plant, Mad Whisp, Ghost Sword, Stranger, Mini Boss, Final Boss).
3. For each monster: select its files in Windows Explorer (`art\sfx_new\` in the repo, files start with the monster name) and drag them onto that folder in the Asset Browser.
   GameMaker makes one Sound resource per file and names it after the file, which is exactly the name the code expects (e.g. `slime_attack_2`).
   (Alternative: right-click the folder > Create > Sound, name it, and use Import in the sound editor.)
4. Check each new sound against an existing one in the same folder (open `dire_wolf_attack` to compare): Audio Group `audiogroup_default`, Sample Rate 44100, Mono, 16 bit, same Compression setting, Preload off. Dragged-in files normally come out the same; change a setting only if it differs.
5. Save (Ctrl+S). Do not rename anything: a different name means the code will not find it.
6. Run the game and trigger a battle with each monster a few times; each spawn and attack should now vary in pitch and volume, and rotate through the takes. Delete any take you dislike in the IDE (the code just skips it).
7. Commit the IDE's changes (`.yyp`, `sounds/<name>/`) as one commit, e.g. "import D116 monster takes".

## Names the code looks for (30)
Monster folder to file names (the resource name is the file name without `.wav`):

| Folder | Files |
|---|---|
| Slime | `slime_spawn_2`, `slime_attack_2`, `slime_attack_3` |
| Spider | `spider_spawn_2`, `spider_attack_2`, `spider_attack_3` |
| Snake | `snake_spawn_2`, `snake_attack_2`, `snake_attack_3` |
| Dire Wolf | `dire_wolf_spawn_2`, `dire_wolf_attack_2`, `dire_wolf_attack_3` |
| Killer Plant | `killer_plant_spawn_2`, `killer_plant_attack_2`, `killer_plant_attack_3` |
| Mad Whisp | `mad_whisp_spawn_2`, `mad_whisp_attack_2`, `mad_whisp_attack_3` |
| Ghost Sword | `ghost_sword_spawn_2`, `ghost_sword_attack_2`, `ghost_sword_attack_3` |
| Stranger | `stranger_spawn_2`, `stranger_attack_2`, `stranger_attack_3` |
| Mini Boss (Palehorn) | `mini_boss_spawn_2`, `mini_boss_attack_2`, `mini_boss_attack_3` |
| Final Boss (Pale Choirbeast) | `final_boss_spawn_2`, `final_boss_attack_2`, `final_boss_attack_3` |

"spawn" plays when the enemy appears (`enemy_spawn_*`), "attack" is its special/attack sound (`enemy_special_*`).
Sources, authors and licence for every file: `README.md`. The credits roll already names rubberduck, Ogrebane and Darsycho.
