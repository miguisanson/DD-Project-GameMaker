# Korean glossary and style (D9, D93)

Written for packet D3 (text pass). The workbook (`datafiles/localization/game_text.xlsx`) uses these terms everywhere;
`tools/localization/text_pass_d3.py` re-applies them, and `check_missing_ko.py` flags rows without Korean.
New Korean text: use the term here, never a second word for the same thing.

## Register (one per kind of text)

| Kind of text | Register | Example |
|---|---|---|
| UI, menus, settings, tooltips, help, combat log, shop messages, tutorial | polite formal, 합니다 / 하세요 | 저장된 게임이 없습니다. / 카드를 고르세요 |
| Narration: intro and ending cutscenes, death and wake lines, lore notes, world objects (graves, signs), class blurbs, card and passive effect lines | plain written, 한다 / 했다, no subject when "you" is meant | 당신은 떨어졌다. / 영구히 ATK +{n}. |
| The hero's own words (dialogue, ending monologue) | casual, 해 / 야 | 여긴 어디지? / 돌아가야 해. |
| The merchant's lines | casual and flat, 반말 | 뭐라도 사. 제발. |
| Short labels, buttons, stat rows | noun form, no ending | 뒤로 / 필요 경험치 |

Particles after a placeholder or a name that can end in either kind of sound: write both, 이(가) 은(는) 을(를) 과(와), (으)로.

## Terms

| English | Korean | Note |
|---|---|---|
| HP, MP, ATK, DEF, SPD, MAG, EXP, Lv | HP, MP, ATK, DEF, SPD, MAG, 경험치 (EXP in short rows), Lv | Latin letters in Korean text too; allowed by `ko_allowlist.txt` |
| Mana (flavour word) | 마나 | Only in names (Mana Spring); rules text says MP |
| Stat / stat point | 능력치 / 능력치 포인트 | not 스탯 |
| Skill / Skillbook | 스킬 / 스킬북 | not 기술 |
| Class | 직업 | not 수업 |
| Knight, Mage, Archer, Nobody | 기사, 마법사, 궁수, 무명 | |
| Item, Inventory | 아이템, 소지품 | |
| Potion | 물약 | not 포션 |
| Weapon, Armor, Accessory, Key item, Consumable | 무기, 방어구, 장신구, 중요 아이템, 소모품 | |
| Gold, Merchant | 골드, 상인 | |
| Run | 도전 | "Abandon run" = 도전 포기 |
| Floor | 층 | |
| Fall(s), Echo | 추락, 메아리 | the tunnel story words |
| Tunnel | 터널 | |
| Damage, Critical hit, Miss | 피해, 치명타, 빗나감 | not 손상 / 데미지 / 크리티컬 |
| Restore (HP/MP) | 회복 | one verb for heal, restore, recover |
| Enemy | 적 | not 상대 / 반대자 |
| Allies | 아군 | |
| Grades: Perfect / Good / OK / Weak | 완벽 / 좋음 / 무난 / 약함 | not 퍼펙트; Miss = 빗나감 |
| Perfect zone | 완벽 구간 | |
| Poison / Burn / Bleed / Stun | 독 / 화상 / 출혈 / 기절 | |
| Steadfast | 버티기 | the 2 turns after a Stun |
| BREAK, Stagger | 브레이크, 경직 | |
| Guard, Braced | 방어, 방어 태세 | |
| Sundered | 분쇄 | |
| Evasion | 회피 | |
| Buff | 버프 | |
| Status (effect) | 상태 이상 (상태 in short labels) | |
| Turn / cooldown | 턴 / 재사용 대기 | |
| Confirm, Cancel, Back, Apply, Yes, No, OK | 확인, 취소, 뒤로, 적용, 예, 아니요, 확인 | |
| Load game / Save game / Continue | 게임 불러오기 / 게임 저장 / 이어하기 | |
| Raid party | 토벌대 | intro and ending, one word |
| Music, Effects, Interface (settings rows) | 음악, 효과음, 인터페이스 | English no longer says BGM / SFX / UI |

## Skill names

Bite 깨물기, Blessing 축복, Bloodthirsty 피에 굶주림, Curse 저주, Double Shot 연속 사격, Evasion 회피, Fury 격노,
Fireball 화염구, Foresight 선견, Cut 베기, Hilt Bash 자루 강타, Horizontal Slash 가로 베기, Ice Spear 얼음 창,
Meditation 명상, Muscle Up 근육 강화, Poison Arrow 독화살, Poison Fangs 독니, Poison Mist 독안개, Ramming 돌진,
Rampage 날뛰기, Rev Up 기세 상승, Scorching Touch 작열의 손길, Solidify 굳히기, Steal 훔치기, Take Aim 조준,
Vine Trap 덩굴 덫, Wound 상처 내기, Regrow 다시 자라기, Snuff 꺼뜨리기, Gore 들이받기, Pale Hymn 창백한 찬가.

## Enemy names

Slime 슬라임, Dire Wolf 다이어울프, Ghost Sword 유령검, Spider 거미, Mad Whisp 미친 도깨비불, Snake 뱀,
Killer Plant 살인 식물, Stranger 낯선 자, Palehorn 창백뿔, The Pale Choirbeast 창백한 성가대 짐승.
Proper nouns left in Latin letters: PaleRook, Galmuri credit line, "NO HOPE" (the title).

## Width

Galmuri draws Hangul full width. UI rows were checked in the `-Only shots` run; keep Korean labels at or under
the English length in characters where a row has a fixed column (settings, shop, battle menu).
