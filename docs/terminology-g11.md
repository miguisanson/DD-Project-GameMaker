# Terminology (G11, D133)

One word per meaning across every UI row of `datafiles/localization/game_text.xlsx`, and the same word in the Korean column (`.planning/research/ko-glossary.md`).
The table below was built by scanning every `en` and `ko` row and the GML fallbacks (`Loc_T("key", "fallback")`) before the pass; the "variants found" column lists the row keys that used another word.
`python tools/localization/lint_terms.py` holds the same table as data (banned variants, label keys), runs in the gate next to the hard-coded text lint and flags a variant coming back.

| Concept | Chosen English | Chosen Korean | Variants found (row keys) | Replaced |
|---|---|---|---|---|
| Enemy | enemy / enemies | 적 | runflow.cause.enemy `상대`; runflow.sum.kills `Foes`; combat.msg.player_cant_escape_this `상대`; tab.lbl.kills `Foes` | foe, monster, opponent; 상대, 몬스터 |
| Fight (the encounter) | battle | 전투 | menu.tooltip.stat.default.desc `combat`; card.lbl.after_fight `fight`; card.pas.field_medic.line `fight`; card.pas.opening_blow.line `fight`; card.pas.a_second_wind.line `fight`; card.pas.n_scrounger.line `fight`; tutorial.throwables.body `fights`; tutorial.throwables.body `싸움`; stat.fights_won `Fights`; tab.system.quit_battle_help `fight`; confirm.quit_battle `fight`; menu.msg.items_in_fight `fight`; menu.msg.gear_in_fight `fight` | fight, combat; 싸움 |
| Hit / magic points | HP, MP | HP, MP | none (already one word) | health, hit points, magic points; 체력, 마력 (help.line.hp / help.line.mp keep them: they define the letters) |
| Give back HP / MP | Restore | 회복 | status.desc.status_meditation `Recover`; elite.line.regenerating `heals`; cards.stat.maxhp.desc `heals` | heal, recover |
| End the game / leave to the title | Quit (Quit Game, Quit to Title) | 종료 / 나가기 | menu.main.option.3 `Exit`; pause.option.exit_main `Exit`; pause.option.exit_main `main menu` | Exit, main menu |
| Leave a screen one step | Back | 뒤로 | none | Return (not used). Cancel stays for aborting a pending change (rebinding a key): `common.cancel`, `menu.common.cancel` |
| Put gear on / take it off | Equip, Equipped, Unequip | 장착, 장착 중, 해제 | item.sent.accessory_stat `착용`; item.sent.accessory_passive `착용`; item.sent.accessory `착용`; shop.worn `착용`; tab.gear.empty `착용`; tab.gear.empty_help `착용`; tab.gear.worn `착용`; tab.hint.equip `착용`; shop.msg.equipped `Take it off`; tab.hint.takeoff `Take off` | Worn, Take off, Take it off; 착용 |
| Pick from a list | Choose | 선택 (labels) / 고르세요 (sentences) | class.select.title `Select`; menu.difficulty.title `Select`; runflow.echo.hint `고르기`; cards.pick.hint `고르기`; tab.hint.select `Select` | Select; 고르기 |
| Accept a reward | Take | 받기 | runflow.echo.hint `가져가기` | Take it; 가져가기 |
| Quit a run on purpose | Abandon | 포기 | runflow.cause.abandoned `gave up`; cards.replace.lose `Gives up`; tab.hist.abandoned `gave`; tab.val.abandoned `Gave up` | gave up, give up, Gave up |
| Experience | EXP | 경험치 | tab.lbl.xp `XP` | XP |
| The dodge status / skill | Evasion | 회피 | shop.lbl.evade `Dodge` | Dodge as a label (the verb stays in sentences: "Dodges the next attack.") |
| Nothing left to buy | Sold Out | 품절 | shop.sold_out (case only) | Sold out |
| Character page / conditions / numbers | Status (tab, conditions), Stats (ATK, DEF ...) | 상태 / 능력치 | tab.title.status was `Stats` | the Status tab was titled Stats |
| Where items are kept | Bag | 소지품 | menu.msg.not_in_inventory `inventory`; menu.tab.inventory `Inventory`; tab.gear.bag `가방` | Inventory; 가방 (the glossary's 소지품 stays) |
| Walk away from a shop / bed | Leave | 나가기 | bed.option.leave `떠나기` | 떠나기 |
| Sleep at a bed | Rest | 휴식 | bed.option.heal `쉬기` | 쉬기 |
| Remove a digit / save | Delete | 삭제 | seed.entry.hint3 `지우기` | 지우기 |
| One go in a fight | turn | 턴 | status.desc.status_stun `차례`; combat.msg.pushed_back `차례`; combat.msg.pushed_back_you `차례`; tutorial.timeline.body `차례`; battle.chip.break.line `차례` | 차례 |
| Continue | Continue | 이어하기 (title) / 계속 (next page) | runflow.continue `go on` | go on |
| Enemies defeated (summary) | Enemies Beaten | 처치한 적 | runflow.sum.kills `쓰러뜨린 적` | Foes beaten; 쓰러뜨린 적 |
| A playthrough | run | 도전 | seed.entry.info `모험` | 모험 |
| Bag, potion, damage, crit, class, stat words | see the glossary | 물약, 피해, 치명타, 직업, 능력치, 완벽 | menu.msg.not_in_inventory `inventory`; menu.tab.inventory `Inventory`; tab.gear.bag `가방` | 포션, 데미지, 크리티컬, 수업, 스탯, 퍼펙트 |

## Title Case (labels) and sentence case (sentences)

Title Case: tabs, menu rows, buttons, headers and titles, row and stat labels, names (class, skill, status, enemy, item), the words next to a button glyph (`[k:confirm] Choose`), empty-slot labels (`No Weapon`), pop-up titles and questions used as titles (`Keep This Setting?`).
Lower-case small words inside a label (`a an the of to in on at for and or but by with into from as vs per`) unless first or last; hyphenated words and placeholders (`{n}`) are left alone; ALL CAPS stays only for 3-letter abbreviations (HP, MP, EXP, ATK, OK), the BREAK term and the status chip codes (`SOLID`, `STEADY`).
Sentence case: messages, help lines, descriptions, confirm questions, tutorial bodies, story text. The key list that counts as a label is `LABEL_KEYS` in `tools/localization/lint_terms.py`.

## Known leftovers (same English word, two meanings)

- `Run`: the battle command (flee, 도망), the control (sprint, 달리기) and a playthrough (도전). Kept; the lint allows the two Korean words.
- `OK`: a confirm button (확인) and the timing grade (무난).
- `Effects`: the settings row for sound effects (효과음) and the Codex label for status effects (효과).
- `Continue`: the title row that loads a run (이어하기) and the tutorial footer that closes a pop-up (계속).
- `Damage Taken`: the run-summary total (받은 피해) and the shop line for what a potion or armour reduces (받는 피해).
- `Brace`: a passive (대비) and the chip of the Braced status (태세).
- `Weak`: the hit grade for a poor timing press (약함) and the Codex line for the status an enemy takes better (약점, D173). Kept; the lint allows the two Korean words.
- `Health.` / `Magic points.` in `help.line.hp` / `help.line.mp` are the definitions of HP and MP, not labels, so they stay.
- Glossary note: Inventory (소지품) is now `Bag` in English; the Korean word is unchanged. The glossary file lives outside the committed folders, so this line is the record.


## One sound per action (G11, D133)

Every UI sound is `SFX_PlayUI(key)` (scr_sfx); no screen calls `audio_play_sound`. The dialogue box keeps its own muted keys (`dialogue_open`, `dialogue_advance`, `dialogue_close`) by design.

| Action | Key | Asset | Called from |
|---|---|---|---|
| Move the cursor / change a value | `ui_move` | Modern2 | `Ui_MenuUpdate`, tab switch, seed digits, note scroll, QTE arrow press |
| Confirm / pick / close a notice | `ui_confirm` | Modern5 | `Ui_MenuUpdate`, pick screens, tutorial and notice close, Keep (settings) |
| Back / leave a page / revert | `ui_back` | Modern6 | `Ui_MenuUpdate`, controls capture cancel, Keep revert |
| Open or close a screen | `ui_openclose` | Modern14 | Tab menu, cards, bed, shop, settings, tutorial, choices |
| Refuse (a buy that fails, a locked row, a bad key, an item that cannot be used, a wrong arrow, an empty seed) | `ui_deny` (new) | Modern6 for now | `SFX_PlayUI("ui_deny")` at the 9 refusal sites in scr_menu and scr_combat |

Finding: G10 noted that a refusal plays `ui_confirm`; in fact the generic menu step plays `ui_confirm` when the row is activated and the refusing handler then plays the back sound on top. Refusals now have their own key, so one line in `SFX_RegisterDefaults` changes the refuse sound everywhere. No existing asset was a clean fit by name or use: `Blocked` is already the wall-bump and the Knight's block, and the Modern, Minimalist and Retro packs cannot be auditioned from a script. Until the owner picks one by ear (L5), `ui_deny` plays Modern6, so nothing sounds different yet.

Dim: every backdrop goes through `Ui_DimBackdrop(UI_DIM_POPUP * a)` or `Ui_DimBackdrop(UI_DIM_SCREEN * a)` (G10's two named strengths); no other caller exists.
