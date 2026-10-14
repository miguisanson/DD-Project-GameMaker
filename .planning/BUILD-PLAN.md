# Big build plan (D71: build everything, then one big playtest)

Spec = `research/DECISIONS.md` (D1-D94). Work lands on branch `next`; at the end, one full gate + one playtest build.
Max 2-3 implementer agents at once, only on non-overlapping files. Every drawing change runs `-Only shots`
and the main session opens the PNGs before merging. Data stays in the GML DB scripts (`scr_db_*`); the
game exports JSON with `-exportdata` for the Python simulator (no Included File needed).

| # | Packet | Decisions / issues | Status |
|---|---|---|---|
| A1 | Draw-space bugs: sight ring + prompt drawn top-left, ring gone after battle; arrow outline; run animation; effects ≥ target size | I-056, I-058, I-059, I-060, I-063 | todo |
| A2 | Window modes (windowed sizes / borderless / exclusive), resize, rm_floor6_5 clamp, hold-to-skip intro & scenes | D91, D48, I-054, I-055, DISP-10/11 | todo |
| B1 | Stats ATK/DEF/SPD/MAG + HP/MP, ratio damage, level-up (class growth + 1 free point), `-exportdata` JSON | D22, D76, D77 | todo |
| B2 | Statuses (poison stacks, burn, bleed), no dice anywhere, Evasion/Solidify, Foresight | D78, D79, D80, D21 | todo |
| B3 | Turn timeline (next 5), stun push-back + Steadfast, stagger meter + BREAK, damage numbers | D74, D75, D92 | todo |
| B4 | Battle AI rule lists, telegraphed big attacks, boss phases | D68, D7 | todo |
| C1 | Run loop: run/profile save split, seeded RNG streams, death → entrance, echo gift, abandon run, auto-save + continue, story seen once, run history, unlocks | D25-D27, D30-D33, D36, D46, D87, D88, D92 | todo |
| C2 | Chests (class first, then cards), class pick (Nobody locked), cards 1-of-3 at chests + level-ups, upgrades, passives (shared + class), max 3 skills equipped | D73, D81, D82, D34, D83 | todo |
| C3 | Gold, merchant after floors 2/5/8, throwables (all classes, Nobody stronger), accessory slot, elites, per-run shuffles | D23, D33, D84, D85, D86, D92 | todo |
| C4 | Beds (heal or upgrade), tutorial prompts + Help page, settings (QTE assist, key rebinding, text speed, shake), device button prompts | D45, D47, D49, D92 | todo |
| D1 | UI kit (modern retro, 4 colours), Tab menu (Status/Skills/Items/Gear/Codex/Settings), battle HUD, card pick, shop, run start/end, codex, settings screen | D89, D90, I-061, I-062 | todo |
| D2 | Art: ComfyUI icons (status, skills, items, throwables, passives) + card frame, PNG strips + owner import checklist; code fallbacks until imported | D10, D43, D44, D94 | todo |
| D3 | Text: cards, passives, death lines, merchant, tutorial, codex (EN + KO draft); credits screen (sound creators from owner) | D93, D40 | todo |
| E1 | Simulator on `-exportdata` JSON, target bands, balance proposals for the owner | D13, D14 | todo |
| E2 | Full gate, regression list run, playtest build + one big PLAYTEST-QUEUE | D71 | todo |

Order: A1+A2 → B1 → (B2 ∥ C1) → B3 → (B4 ∥ C2) → C3 → C4 → D1 (∥ D2 art) → D3 → E1 → E2.
