// ==========================================================================================================================
// THE ONE MENU (D90, D92, D95, D96, D97, D100, D115, D140, D141): Status · Skills · Items · Gear · Codex · Settings · System on the UI framework.
// Esc and Tab (or the pad's X / Y / Start) open this same menu on the map and in a fight; there is no separate pause menu. System holds Help, Abandon run and
// Quit to title. Settings apply at once; a window mode or scale change asks "Keep this?" for 10 s (KeepThis_*).
// Q / E (or LB / RB) switch tabs and wrap; each tab is a list on the left with icons and a details panel on the right (one plain sentence and
// the numbers from the data, a before / after comparison for gear). Back goes up ONE level (a Codex page to the Codex list, a tab to the game);
// the cursor of every tab is remembered. The rows come from pure functions (Tab*_Items, Gear_*, Codex_*), tested without a screen.
// Abandon run and Quit to title ask first through the one Yes / No pop-up (Confirm_*, D156).
// global.tab_ui = { tab, pages (one { stk } per tab), opened_ms, closed_ms, toast, toast_ms, pending } while it is open, with gs.ui.mode = UI_MENU.
// ==========================================================================================================================
// D108 F1c: the tab ids and icons never change, so they are built once (TabMenu_DataBuilds counts the builds) and read-only for callers; the
// labels are kept per language (TabMenu_LabelBuilds counts them).
function TabMenu_DataBuilds() {
    return variable_global_exists("tabmenu_data_builds") ? global.tabmenu_data_builds : 0;
}

function TabMenu_LabelBuilds() {
    return variable_global_exists("tabmenu_label_builds") ? global.tabmenu_label_builds : 0;
}

function TabMenu_Data() {
    var d = variable_global_exists("tabmenu_data") ? global.tabmenu_data : undefined;
    if (is_struct(d)) return d;
    global.tabmenu_data_builds = TabMenu_DataBuilds() + 1;
    d = {
        ids: ["status", "skills", "items", "gear", "codex", "settings", "system"],
        // One 8 x 8 icon per tab: a bust, a sparkle, a flask, a shield, a page, a cog, a power ring.
        icons: [
            ["..3333..", ".333333.", ".333333.", "..3333..", ".333333.", "33333333", "33333333", "33333333"],
            ["...33...", "...33...", "..3333..", "33333333", "33333333", "..3333..", "...33...", "...33..."],
            ["..3333..", "...33...", "...33...", "..3333..", ".333333.", "33333333", "33333333", ".333333."],
            ["33333333", "33333333", "33333333", "33333333", ".333333.", ".333333.", "..3333..", "...33..."],
            ["33333333", "3......3", "3.3333.3", "3......3", "3.3333.3", "3......3", "3.33...3", "33333333"],
            ["...33...", ".3.33.3.", "..3333..", "333..333", "333..333", "..3333..", ".3.33.3.", "...33..."],
            ["...33...", ".3.33.3.", "3..33..3", "3......3", "3......3", ".3....3.", "..3333..", "........"]
        ]
    };
    global.tabmenu_data = d;
    return d;
}

function TabMenu_Ids() {
    return TabMenu_Data().ids;
}

function TabMenu_Icons() {
    return TabMenu_Data().icons;
}

// The one place the number of tabs comes from (the open, the Q / E step and the memory all read it).
function TabMenu_Count() {
    return array_length(TabMenu_Ids());
}

function TabMenu_Labels() {
    var lang = Loc_GetLanguage();
    var c = variable_global_exists("tabmenu_labels") ? global.tabmenu_labels : undefined;
    if (is_struct(c) && c.lang == lang) return c.labels;
    global.tabmenu_label_builds = TabMenu_LabelBuilds() + 1;
    var labels = [
        Loc_T("tab.status", "Status"), Loc_T("tab.skills", "Skills"), Loc_T("tab.items", "Items"),
        Loc_T("tab.gear", "Gear"), Loc_T("tab.codex", "Codex"), Loc_T("tab.settings", "Settings"), Loc_T("tab.system", "System")
    ];
    global.tabmenu_labels = { lang: lang, labels: labels };
    return labels;
}

function Menu_IsEquipped(_ch, _item_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip")) return false;
    var eq = _ch.equip;
    if (variable_struct_exists(eq, "weapon") && eq.weapon == _item_id) return true;
    if (variable_struct_exists(eq, "body") && eq.body == _item_id) return true;
    if (variable_struct_exists(eq, "accessory") && eq.accessory == _item_id) return true;   // C3 (D92)
    return false;
}

function TabMenu_Signed(_n) {
    return ((_n > 0) ? "+" : "") + string(_n);
}

// ---- Status: ATK DEF SPD MAG with what each does, then the statuses on the character ----
function Stat_Sentence(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return Loc_T("menu.tooltip.stat.atk.desc", "Increases physical damage (basic attacks and ATK skills).");
        case STAT_DEF: return Loc_T("menu.tooltip.stat.def.desc", "Reduces all damage you take.");
        case STAT_SPD: return Loc_T("menu.tooltip.stat.spd.desc", "Decides who acts first.");
        case STAT_MAG: return Loc_T("menu.tooltip.stat.mag.desc", "Increases spell damage and max MP.");
    }
    return Loc_T("menu.tooltip.stat.default.desc", "Affects combat performance.");
}

function TabStatus_Items(_ch) {
    var items = [];
    var sids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG];
    for (var i = 0; i < 4; i++) {
        var sid = sids[i];
        var base = variable_struct_get(_ch.stats, Stat_Key(sid));
        var gear = Equip_GetStatBonus(_ch, sid);
        var fx = Status_ModStat(_ch, sid);
        var lines = [{ label: Loc_T("tab.lbl.base", "Base"), value: string(base) }];
        if (gear != 0) array_push(lines, { label: Loc_T("tab.lbl.gear", "Gear"), value: TabMenu_Signed(gear) });
        if (fx != 0) array_push(lines, { label: Loc_T("tab.lbl.effects", "Effects"), value: TabMenu_Signed(fx) });
        array_push(lines, { label: Loc_T("tab.lbl.total", "Total"), value: string(Stat_Get(_ch, sid)) });
        var row = { id: Stat_Key(sid), label: Stat_ShortName(sid), value: string(Stat_Get(_ch, sid)), kind: "button", enabled: true, help: Stat_Sentence(sid), lines: lines, hint: "" };
        if (is_struct(_ch.class_cfg) && variable_struct_exists(_ch.class_cfg, "sprites") && sprite_exists(_ch.class_cfg.sprites.down)) row.pic = { spr: _ch.class_cfg.sprites.down, sub: 0 };
        array_push(items, row);
    }
    var sl = Status_DisplayList(_ch);
    for (var s = 0; s < array_length(sl); s++) {
        var d = sl[s];
        var fr = Icon_StatusFrame(d.id);
        array_push(items, { id: "status_" + string(d.id), label: d.name, value: d.label, kind: "button", enabled: true, help: d.full, lines: [], hint: "", icon: (fr >= 0) ? { cat: "status", frame: fr } : undefined });   // D150: what it does and the turns left
    }
    return items;
}

// ---- Skills: the equipped skills (arrows, MP, numbers from the data, upgrade state), then the passives ----
function TabSkills_Items(_ch) {
    var items = [];
    var ids = is_array(_ch.skills) ? _ch.skills : [];
    for (var i = 0; i < array_length(ids); i++) {
        var sk = SkillDB_Get(ids[i]);
        var cost = Equip_PlayerSkillMPCost(_ch, sk, sk.mp_cost);
        var det = Battle_SkillDetails(sk, cost);
        var up = is_array(_ch.upgrades) && Card_ArrayHas(_ch.upgrades, ids[i]);
        array_push(det.lines, { label: Loc_T("tab.lbl.upgrade", "Upgrade"), value: up ? Loc_T("tab.val.applied", "Applied") : Loc_T("tab.val.none", "None") });
        var fr = Icon_SkillFrame(ids[i]);
        array_push(items, {
            id: "skill_" + string(ids[i]), label: sk.name, value: Loc_T("battle.menu.mp", "{mp} MP", { mp: string(cost) }), kind: "button", enabled: true,
            skill_id: ids[i], seq: Qte_SkillSequence(ids[i]), help: det.sentence, lines: det.lines, hint: "", icon: (fr >= 0) ? { cat: "skill", frame: fr } : undefined
        });
    }
    if (array_length(items) == 0) {
        array_push(items, { id: "none", label: Loc_T("tab.skills.none", "No skills yet"), value: "", kind: "button", enabled: false, help: Loc_T("tab.skills.none_help", "Cards and chests teach skills. They appear here with the arrows to press."), lines: [], hint: "" });
    }
    var ps = is_array(_ch.passives) ? _ch.passives : [];
    var passives = [];
    for (var j = 0; j < array_length(ps); j++) {
        var c = CardDB_Get(ps[j]);
        if (!is_struct(c)) continue;
        array_push(passives, { id: "passive_" + string(ps[j]), label: Card_Name(c), value: "", kind: "button", enabled: true, help: Card_Sentence(c), lines: Card_Lines(c), hint: "" });
    }
    if (array_length(passives) > 0) {
        array_push(items, { id: "head_passives", kind: "head", label: Loc_T("tab.skills.passives", "Passives"), value: "", enabled: false, help: "", lines: [], hint: "" });
        for (var q = 0; q < array_length(passives); q++) array_push(items, passives[q]);
    }
    return items;
}

// ---- Items: potions, throwables and key items with counts; equipment lives in Gear ----
function TabItems_Items(_ch) {
    var items = [];
    var groups = [0, 1, 2];   // potions, throwables, key items
    for (var g = 0; g < 3; g++) {
        for (var i = 0; i < array_length(_ch.inventory); i++) {
            var inv = _ch.inventory[i];
            var it = ItemDB_Get(inv.id);
            if (!is_struct(it) || it.id == 0) continue;
            var grp = (it.type == ITEM_KEY) ? 2 : (Item_IsThrowable(it) ? 1 : ((it.type == ITEM_CONSUMABLE) ? 0 : -1));
            if (grp != g) continue;
            var sentence = (it.type == ITEM_KEY) ? Loc_T("tab.items.key", "An item you keep for the way ahead.") : Item_Sentence(it);
            var lines = (it.type == ITEM_KEY) ? [] : Item_NumberLines(it, _ch);
            array_push(lines, { label: Loc_T("shop.lbl.have", "You have"), value: string(inv.qty) });
            array_push(items, {
                id: "item_" + string(it.id), label: it.name, value: "x" + string(inv.qty), kind: "button", enabled: true, item_id: it.id, throwable: Item_IsThrowable(it),
                help: sentence, lines: lines, icon_item: it, hint: (grp == 0) ? Loc_T("tab.hint.use", "[k:confirm] Use") : ""
            });
        }
    }
    if (array_length(items) == 0) {
        array_push(items, { id: "none", label: Loc_T("tab.items.none", "Nothing in your bag"), value: "", kind: "button", enabled: false, help: Loc_T("tab.items.none_help", "Potions, throwables and keys you find show up here."), lines: [], hint: "" });
    }
    return items;
}

// Uses a potion or an antidote from the menu. Returns { ok, msg, ch }; the item is spent only when it did something.
function TabItems_Use(_ch, _item_id) {
    var item = ItemDB_Get(_item_id);
    var out = { ok: false, msg: Loc_T("item.msg.cant_use", "Can't use that."), ch: _ch };
    if (!is_struct(item) || item.id == 0 || !Inv_Has(_ch.inventory, _item_id, 1)) return out;
    var r = Item_Use(_item_id, _ch, _ch);
    out.msg = r.msg;
    if (!r.ok) return out;
    _ch.inventory = Inv_Remove(_ch.inventory, _item_id, 1);
    out.ch = RecomputeResources(_ch);
    out.ok = true;
    return out;
}

// ---- Gear: weapon, armor and accessory slots, then the bag; equip with a before / after comparison ----
function Gear_Slots() {
    return ["weapon", "body", "accessory"];
}

function Gear_EmptyLabel(_slot) {
    switch (_slot) {
        case "weapon": return Loc_T("tab.gear.no_weapon", "No weapon");
        case "body": return Loc_T("tab.gear.no_armor", "No armor");
        case "accessory": return Loc_T("tab.gear.no_accessory", "No accessory");
    }
    return Loc_T("tab.gear.empty", "Nothing worn");
}

// The four stats as they would be with _item worn (or taken off, when it is worn) in its slot. The character is left as it was.
function Gear_StatsAfter(_ch, _item) {
    var slot = string(_item.equip_slot);
    var old = Equip_SlotGet(_ch, slot);
    Equip_SlotSet(_ch, slot, (old == _item.id) ? 0 : _item.id);
    var out = { atk: Stat_Get(_ch, STAT_ATK), def: Stat_Get(_ch, STAT_DEF), spd: Stat_Get(_ch, STAT_SPD), mag: Stat_Get(_ch, STAT_MAG) };
    Equip_SlotSet(_ch, slot, old);
    return out;
}

// [{ label, value "a > b", delta }] for putting _item on (D90): the weapon's power, then every stat that changes, then what else it does.
function Gear_CompareLines(_ch, _item) {
    var lines = [];
    var cur_id = Equip_SlotGet(_ch, string(_item.equip_slot));
    var after = Gear_StatsAfter(_ch, _item);
    if (_item.type == ITEM_WEAPON) {
        var cur_power = (cur_id != 0) ? ItemDB_Get(cur_id).power : 0;
        array_push(lines, { label: Loc_T("card.lbl.power", "Power"), value: string(cur_power) + " > " + string(_item.power), delta: sign(_item.power - cur_power) });
    }
    var sids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG];
    for (var i = 0; i < 4; i++) {
        var before = Stat_Get(_ch, sids[i]);
        var now = variable_struct_get(after, Stat_Key(sids[i]));
        if (now != before) array_push(lines, { label: Stat_ShortName(sids[i]), value: string(before) + " > " + string(now), delta: sign(now - before) });
    }
    var nl = Item_NumberLines(_item, _ch);   // what the comparison does not say (a passive's numbers); the stat and power lines are already above
    for (var n = 0; n < array_length(nl); n++) {
        var lb = nl[n].label;
        if (lb == Stat_ShortName(STAT_ATK) || lb == Stat_ShortName(STAT_DEF) || lb == Stat_ShortName(STAT_SPD) || lb == Stat_ShortName(STAT_MAG)) continue;
        if (lb == Loc_T("shop.lbl.power", "Power") || lb == Loc_T("shop.lbl.bonus", "Bonus")) continue;
        array_push(lines, nl[n]);
    }
    return lines;
}

function TabGear_Row(_ch, _item, _slot, _worn) {
    var can = _worn ? { ok: true, msg: "" } : Equip_CanEquip(_ch, _item);
    var sentence = Item_Sentence(_item);
    if (!_worn && !can.ok) sentence += " " + can.msg;
    var cur_id = _worn ? 0 : Equip_SlotGet(_ch, string(_item.equip_slot));
    if (!_worn && can.ok && cur_id != 0) sentence += " " + Loc_T("tab.gear.replaces", "Replaces {item}.", { item: ItemDB_Get(cur_id).name });
    return {
        id: "gear_" + string(_item.id), label: _item.name, value: "", kind: "button", enabled: true, item_id: _item.id, slot: _slot, worn: _worn,
        dim: (!_worn && !can.ok), help: sentence, lines: _worn ? Item_NumberLines(_item, _ch) : Gear_CompareLines(_ch, _item), icon_item: _item,
        hint: _worn ? Loc_T("tab.hint.takeoff", "[k:confirm] Take off") : (can.ok ? Loc_T("tab.hint.equip", "[k:confirm] Equip") : "")
    };
}

function TabGear_Items(_ch) {
    var items = [];
    array_push(items, { id: "head_worn", kind: "head", label: Loc_T("tab.gear.worn", "Worn"), value: "", enabled: false, help: "", lines: [], hint: "" });
    var slots = Gear_Slots();
    for (var s = 0; s < array_length(slots); s++) {
        var wid = Equip_SlotGet(_ch, slots[s]);
        var wit = (wid != 0) ? ItemDB_Get(wid) : undefined;
        if (is_struct(wit) && wit.id != 0) {
            array_push(items, TabGear_Row(_ch, wit, slots[s], true));
        } else {
            array_push(items, {
                id: "empty_" + slots[s], label: Gear_EmptyLabel(slots[s]), value: "", kind: "button", enabled: true, dim: true, slot: slots[s], worn: false, item_id: -1,
                help: Loc_T("tab.gear.empty_help", "Nothing is worn in this slot."), lines: [], hint: ""
            });
        }
    }
    var bag = [];
    for (var i = 0; i < array_length(_ch.inventory); i++) {
        var it = ItemDB_Get(_ch.inventory[i].id);
        if (!is_struct(it) || it.id == 0) continue;
        if (it.type != ITEM_WEAPON && it.type != ITEM_ARMOR && it.type != ITEM_ACCESSORY) continue;
        if (Menu_IsEquipped(_ch, it.id)) continue;
        array_push(bag, TabGear_Row(_ch, it, string(it.equip_slot), false));
    }
    if (array_length(bag) > 0) {
        array_push(items, { id: "head_bag", kind: "head", label: Loc_T("tab.gear.bag", "Bag"), value: "", enabled: false, help: "", lines: [], hint: "" });
        for (var b = 0; b < array_length(bag); b++) array_push(items, bag[b]);
    }
    return items;
}

// Puts a bag item on, or takes a worn one off. Returns { ok, equipped, msg, ch }.
function Gear_Toggle(_ch, _item_id) {
    var item = ItemDB_Get(_item_id);
    var out = { ok: false, equipped: false, msg: Loc_T("menu.msg.cant_equip", "Can't equip that."), ch: _ch };
    if (!is_struct(item) || item.id == 0) return out;
    var slot = variable_struct_exists(item, "equip_slot") ? string(item.equip_slot) : "";
    if (slot != "" && Equip_SlotGet(_ch, slot) == item.id) {
        Equip_SlotSet(_ch, slot, 0);
        out.ch = RecomputeResources(_ch);
        out.ok = true;
        out.msg = Loc_T("menu.msg.unequipped", "Unequipped {item}.", { item: item.name });
        return out;
    }
    var can = Equip_CanEquip(_ch, item);
    out.msg = can.msg;
    if (!can.ok) return out;
    if (!Equip_Item(_ch, item.id)) return out;
    out.ch = RecomputeResources(_ch);
    out.ok = true;
    out.equipped = true;
    return out;
}

// ---- Codex (D88, D107): the bestiary, the notes, the run history and the unlocks ----
function Codex_EnemyIds() {
    return [ENEMY_SLIME, ENEMY_DIREWOLF, ENEMY_GHOSTSWORD, ENEMY_SPIDER, ENEMY_MADWHISP, ENEMY_SNAKE, ENEMY_KILLER_PLANT, ENEMY_STRANGER, ENEMY_MINI_BOSS, ENEMY_FINAL_BOSS];
}

function Codex_Key(_enemy_id) {
    return "e" + string(_enemy_id);
}

// An enemy was met in a fight (or an auto-resolved one). _elite marks an elite version.
function Codex_Met(_prof, _enemy_id, _elite) {
    if (!variable_struct_exists(_prof, "bestiary") || !is_struct(_prof.bestiary)) _prof.bestiary = {};
    var k = Codex_Key(_enemy_id);
    var e = variable_struct_exists(_prof.bestiary, k) ? variable_struct_get(_prof.bestiary, k) : { met: 0, elite: false };
    e.met += 1;
    if (_elite) e.elite = true;
    variable_struct_set(_prof.bestiary, k, e);
}

// A fight with this enemy starts (or is settled without one): the Codex remembers it. The profile file is written when something new is learned
// (a first meeting, a first elite), not on every fight.
function Codex_RecordMeeting(_enemy_id, _elite) {
    var prof = Profile_Get();
    var ent = Codex_Entry(prof, _enemy_id);
    var fresh = !is_struct(ent) || (_elite && !ent.elite);
    Codex_Met(prof, _enemy_id, _elite);
    if (fresh) Profile_Flush();
}

function Codex_Entry(_prof, _enemy_id) {
    if (!variable_struct_exists(_prof, "bestiary") || !is_struct(_prof.bestiary)) return undefined;
    var k = Codex_Key(_enemy_id);
    return variable_struct_exists(_prof.bestiary, k) ? variable_struct_get(_prof.bestiary, k) : undefined;
}

function Codex_BestiaryCount(_prof) {
    var n = 0;
    var ids = Codex_EnemyIds();
    for (var i = 0; i < array_length(ids); i++) if (is_struct(Codex_Entry(_prof, ids[i]))) n++;
    return n;
}

// The enemy as a fight would make it at _level (stats do not change with level; HP does).
function Codex_EnemyAt(_enemy_id, _level) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "battle") || !is_struct(gs.battle)) return EnemyCreate(_enemy_id);
    var lv0 = gs.battle.enemy_level;
    gs.battle.enemy_level = _level;
    var e = EnemyCreate(_enemy_id);
    gs.battle.enemy_level = lv0;
    return e;
}

function Codex_BestiaryRows(_prof) {
    var rows = [];
    var ids = Codex_EnemyIds();
    for (var i = 0; i < array_length(ids); i++) {
        var eid = ids[i];
        var ent = Codex_Entry(_prof, eid);
        if (!is_struct(ent)) {
            array_push(rows, { id: "enemy_" + string(eid), label: "???", value: "", kind: "button", enabled: true, enemy_id: eid, help: Loc_T("tab.bestiary.unknown", "You have not met this one yet."), lines: [], hint: "" });
            continue;
        }
        var cfg = EnemyDB_Get(eid);
        var lo = max(1, round(cfg.species_min_level));
        var hi = max(lo, round(cfg.species_max_level));
        var e_lo = Codex_EnemyAt(eid, lo);
        var e_hi = Codex_EnemyAt(eid, hi);
        var lvl = (lo == hi) ? string(lo) : (string(lo) + "-" + string(hi));
        var hp = (e_lo.max_hp == e_hi.max_hp) ? string(e_lo.max_hp) : (string(e_lo.max_hp) + "-" + string(e_hi.max_hp));
        var moves = Loc_T("tab.bestiary.attack", "Attack");
        for (var s = 0; s < array_length(cfg.skills); s++) moves += ", " + SkillDB_Get(cfg.skills[s]).name;
        var sentence = Loc_T("tab.bestiary.moves", "Moves: {list}.", { list: moves });
        if (cfg.is_boss) sentence = Loc_T("tab.bestiary.boss", "A boss.") + " " + sentence;
        var lines = [
            { label: Loc_T("tab.lbl.level", "Level"), value: lvl },
            { label: Loc_T("tab.lbl.hp", "HP"), value: hp },
            { label: Stat_ShortName(STAT_ATK), value: string(e_lo.stats.atk) },
            { label: Stat_ShortName(STAT_DEF), value: string(e_lo.stats.def) },
            { label: Stat_ShortName(STAT_SPD), value: string(e_lo.stats.spd) },
            { label: Stat_ShortName(STAT_MAG), value: string(e_lo.stats.mag) },
            { label: Loc_T("tab.lbl.met", "Met"), value: string(ent.met) }
        ];
        if (ent.elite) array_push(lines, { label: Loc_T("tab.lbl.elite", "Elite"), value: Loc_T("tab.val.seen", "Seen") });
        array_push(rows, {
            id: "enemy_" + string(eid), label: cfg.name, value: lvl, kind: "button", enabled: true, enemy_id: eid,
            help: sentence, lines: lines, hint: "", pic: { spr: cfg.sprite, sub: 0 }
        });
    }
    return rows;
}

function Codex_NoteCount(_prof) {
    return array_length(Note_Collected(_prof));
}

// The Notes page title: how many of the notes are found.
function Codex_NotesTitle(_prof) {
    return Loc_T("tab.codex.notes_title", "Notes found {n}/{max}", { n: string(Codex_NoteCount(_prof)), max: string(array_length(Note_Defs())) });
}

// D147: a found note is a row with its title; Confirm opens the reader (note_id). One not found is ??? and opens nothing.
function Codex_NoteRows(_prof) {
    var rows = [];
    var defs = Note_Defs();
    for (var i = 0; i < array_length(defs); i++) {
        var d = defs[i];
        if (Note_IsCollected(_prof, d.id)) {
            var txt = "";
            for (var j = 0; j < array_length(d.lines); j++) txt += ((j > 0) ? "\n" : "") + d.lines[j];
            array_push(rows, { id: "note_" + d.id, note_id: d.id, label: d.title, value: "", kind: "button", enabled: true, help: txt, hint: Loc_T("tab.hint.read", "[k:confirm] Read"),
                               lines: [{ label: Loc_T("tab.lbl.floor", "Floor"), value: string(Run_FloorOfRoomName(d.room)) }] });
        } else {
            array_push(rows, { id: "note_" + d.id, label: "???", value: "", kind: "button", enabled: true, help: Loc_T("tab.notes.unknown", "A note you have not found yet. Look at the walls."), lines: [], hint: "" });
        }
    }
    return rows;
}

// Newest run first.
function Codex_HistoryRows(_prof) {
    var rows = [];
    for (var i = array_length(_prof.history) - 1; i >= 0; i--) {
        var h = _prof.history[i];
        var cname = DB_PlayerClass(h.class_id).name;
        var fl = variable_struct_exists(h, "floor") ? h.floor : 0;
        var res = variable_struct_exists(h, "result") ? string(h.result) : "died";
        var cause = variable_struct_exists(h, "cause") ? string(h.cause) : "";
        var sentence;
        var value;
        if (res == "won") {
            sentence = Loc_T("tab.hist.won", "You climbed out of the tunnel.");
            value = Loc_T("tab.val.won", "Won");
        } else if (res == "abandoned") {
            sentence = Loc_T("tab.hist.abandoned", "You gave this run up on floor {n}.", { n: string(fl) });
            value = Loc_T("tab.val.abandoned", "Gave up");
        } else {
            sentence = (cause != "") ? Loc_T("tab.hist.died_to", "Floor {n}: felled by {name}.", { name: cause, n: string(fl) }) : Loc_T("tab.hist.died", "You fell on floor {n}.", { n: string(fl) });
            value = Loc_T("tab.val.floor", "Floor {n}", { n: string(fl) });
        }
        // G9 (D137): the six run stats made eleven lines, which do not fit the details panel at 800 x 720. The level is in the row's title, the gold is gone with the run
        // (D23), so those two lines gave way; the floor, the foes beaten and the seed stay.
        var lines = [
            { label: Loc_T("tab.lbl.floor", "Floor"), value: string(fl) },
            { label: Loc_T("tab.lbl.kills", "Foes beaten"), value: string(variable_struct_exists(h, "kills") ? h.kills : 0) }
        ];
        var stat_lines = RunStats_Lines(h);   // Perfect rate, crits, damage dealt / taken, fights won, run time ("-" for a run from before D137)
        for (var sl = 0; sl < array_length(stat_lines); sl++) array_push(lines, stat_lines[sl]);
        array_push(lines, { label: Loc_T("tab.lbl.seed", "Seed"), value: string(variable_struct_exists(h, "seed") ? h.seed : 0) });
        array_push(rows, {
            id: "run_" + string(i), label: Loc_T("tab.hist.row", "{cls} Lv {n}", { cls: string(cname), n: string(h.level) }), value: value, kind: "button", enabled: true, help: sentence, hint: "",
            lines: lines
        });
    }
    return rows;
}

function Codex_UnlockRows(_prof) {
    var rows = [];
    var on = Profile_IsUnlocked(_prof, "nobody_class");
    array_push(rows, {
        id: "unlock_nobody", label: Loc_T("tab.unlock.nobody", "Nobody"), value: on ? Loc_T("tab.val.unlocked", "Unlocked") : Loc_T("tab.val.locked", "Locked"), kind: "button", enabled: true, dim: !on, hint: "",
        help: on ? Loc_T("tab.unlock.nobody_on", "A fighter with no class. Throws {m}x as hard and carries {cap} of each throwable.", { m: string_format(THROW_NOBODY_MULT, 1, 1), cap: string(THROW_CAP_NOBODY) })
                 : Loc_T("tab.unlock.nobody_off", "Win a run to unlock a fighter with no class."),
        lines: []
    });
    return rows;
}

// The Codex list: one row per page, with how much of it you have.
function TabCodex_Items(_prof) {
    var ids = Codex_EnemyIds();
    var runs = array_length(_prof.history);
    return [
        { id: "bestiary", label: Loc_T("tab.codex.bestiary", "Bestiary"), value: string(Codex_BestiaryCount(_prof)) + "/" + string(array_length(ids)), kind: "button", enabled: true,
          help: Loc_T("tab.codex.bestiary_help", "The enemies you have met: their numbers and their moves."), lines: [], hint: Loc_T("tab.hint.open", "[k:confirm] Open") },
        { id: "notes", label: Loc_T("tab.codex.notes", "Notes"), value: string(Codex_NoteCount(_prof)) + "/" + string(array_length(Note_Defs())), kind: "button", enabled: true,
          help: Loc_T("tab.codex.notes_help", "The notes you have read in the tunnel."), lines: [], hint: Loc_T("tab.hint.open", "[k:confirm] Open") },
        { id: "history", label: Loc_T("tab.codex.history", "Run history"), value: string(runs), kind: "button", enabled: (runs > 0), dim: (runs <= 0),
          help: Loc_T("tab.codex.history_help", "Every run you have finished, newest first."),
          lines: [{ label: Loc_T("tab.lbl.wins", "Wins"), value: string(_prof.wins) }, { label: Loc_T("tab.lbl.falls", "Falls"), value: string(_prof.deaths) }, { label: Loc_T("tab.lbl.best_floor", "Best floor"), value: string(_prof.best_floor) }],
          hint: Loc_T("tab.hint.open", "[k:confirm] Open") },
        { id: "unlocks", label: Loc_T("tab.codex.unlocks", "Unlocks"), value: string(Profile_IsUnlocked(_prof, "nobody_class") ? 1 : 0) + "/1", kind: "button", enabled: true,
          help: Loc_T("tab.codex.unlocks_help", "What winning has opened up for later runs."), lines: [], hint: Loc_T("tab.hint.open", "[k:confirm] Open") }
    ];
}

// ---- the screen: state, input, drawing ----
#macro TAB_TOAST_MS 1800

function TabMenu_Get() {
    return (variable_global_exists("tab_ui") && is_struct(global.tab_ui)) ? global.tab_ui : undefined;
}

// Where everything stands on the GUI grid: tabs header on top, the body (list left, details right), a footer line for prompts and gold.
function TabMenu_ListShare(_tid) {
    switch (_tid) {
        case "codex_bestiary": return 0.4;   // the page on the right has the long text and the numbers
        case "codex_notes": return 0.5;      // D147: room for the note titles and "Notes found 2/8" (the details text of a note must still fit at 800 x 720 too)
        case "codex_history": return 0.58;
        case "gear": case "items": case "skills": return 0.55;   // long names with icons
        case "settings": return 0.6;                              // a name and a value on every row
        case "system": return 0.5;
        case "status": return 0.48;
    }
    return 0.52;
}

function TabMenu_Zones(_tid = "") {
    var mt = Ui_Metrics();
    var p = mt.p;
    var z = { mt: mt };
    z.x = mt.margin;
    z.w = mt.gw - 2 * mt.margin;
    z.tabs_y = mt.margin;
    z.tabs_h = mt.line_h + 2 * p;
    z.body_y = z.tabs_y + z.tabs_h + 2 * p;
    z.foot_h = max(Prompt_GlyphH(), mt.line_h);
    z.foot_y = mt.gh - mt.margin - z.foot_h;
    z.body_h = z.foot_y - 2 * p - z.body_y;
    z.list_w = floor((z.w - mt.margin) * TabMenu_ListShare(_tid) / p) * p;
    z.det_w = z.w - mt.margin - z.list_w;
    return z;
}

// Fits a list menu into the Tab menu's body; _top_extra is room kept above the list (the Status card).
function TabMenu_FitMenu(_m, _z, _top_extra = 0) {
    var L = _m.layout;
    L.x_anchor = "left";
    L.panel_w = _z.list_w;
    L.y_top = _z.body_y + _top_extra;
    L.max_h = _z.body_h - _top_extra;
    L.details = true;
    L.details_pos = "right";
    L.det_w = _z.det_w;
    L.det_top = _z.body_y;
    L.det_h = _z.body_h;
    L.det_art = true;
    L.hides_below = true;
}

function TabMenu_Title(_id, _ch) {
    switch (_id) {
        case "status": return Loc_T("tab.title.status", "Stats");
        case "skills": return Loc_T("tab.title.skills", "Skills {n}/{max}", { n: string(array_length(_ch.skills)), max: string(CARD_MAX_SKILLS) });
        case "items": return Loc_T("tab.title.items", "Items");
        case "gear": return Loc_T("tab.title.gear", "Gear");
        case "codex": return Loc_T("tab.title.codex", "Codex");
        case "system": return Loc_T("tab.title.system", "System");
    }
    return "";
}

function TabMenu_ItemsFor(_id, _ch) {
    switch (_id) {
        case "status": return TabStatus_Items(_ch);
        case "skills": return TabSkills_Items(_ch);
        case "items": return TabItems_Items(_ch);
        case "gear": return TabGear_Items(_ch);
        case "codex": return TabCodex_Items(Profile_Get());
        case "system": return TabSystem_Items(room == rm_battle);
    }
    return [];
}

function TabMenu_RootMenu(_id) {
    var ch = GameState_Get().player_ch;
    var m = Ui_MenuNew("tab_" + _id, TabMenu_ItemsFor(_id, ch), {
        on_confirm: TabMenu_OnConfirm, on_back: TabMenu_OnBack, data: { tab: _id },
        layout: { title: TabMenu_Title(_id, ch), anchor: "center", details: true, details_pos: "right", det_art: true, hides_below: true }
    });
    Ui_MenuFixCursor(m, m.cursor);
    return m;
}

function TabMenu_BuildPage(_id) {
    var pg = { stk: Ui_StackNew() };
    Ui_StackPush(pg.stk, TabMenu_RootMenu(_id));
    return pg;
}

// ---- the System tab (D140, D141): Help, Abandon run, Quit to title; all on in a fight too. The last two ask first (D156) ----
function TabSystem_Items(_in_battle = false) {
    return [
        { id: "help", label: Loc_T("pause.option.help", "Help"), value: "", kind: "button", enabled: true, lines: [], help: Loc_T("pause.help.help", "Every hint the game has: the ones you have seen and the ones still to come.") },
        { id: "abandon", value: "", kind: "button", enabled: true, lines: [],
          label: Loc_T("pause.option.abandon", "Abandon run"),
          help: Loc_T("pause.help.abandon", "Ends this run now. It counts as a death, but you keep the echo.") },
        { id: "quit", label: Loc_T("pause.option.quit", "Quit to title"), value: "", kind: "button", enabled: true, lines: [],
          help: _in_battle ? Loc_T("tab.system.quit_battle_help", "Goes back to the title. Continue puts you back just before this fight.")
                           : Loc_T("pause.help.quit", "Saves the run and goes to the title. Continue picks it up again.") }
    ];
}

// D156: the question a System row asks before it acts (a fight says what Continue will do).
function TabSystem_Question(_id, _in_battle = false) {
    switch (_id) {
        case "abandon": return Loc_T("confirm.abandon", "Abandon this run? It counts as a death, but you keep the echo.");
        case "quit": return _in_battle ? Loc_T("confirm.quit_battle", "Quit to title? Continue puts you back just before this fight.")
                                       : Loc_T("confirm.quit", "Quit to title? The run is saved and Continue picks it up again.");
    }
    return "";
}

// Yes: the menu fades out and Menu_CloseFinalize does it (_d.id = "abandon" | "quit").
function TabSystem_Yes(_d) {
    var u = TabMenu_Get();
    if (!is_struct(u)) return;
    u.pending = _d.id;
    Menu_Close();
}

// D156: the three bars differ without a colour of their own: HP solid, MP striped, XP thin and in segments in the brightest green.
function Ui_BarStyle(_kind) {
    switch (_kind) {
        case "mp": return { kind: _kind, fill: UI_C_LIGHT, pattern: "stripe", thin: false };
        case "xp": return { kind: _kind, fill: UI_C_LIGHTEST, pattern: "segments", thin: true };
    }
    return { kind: "hp", fill: UI_C_LIGHT, pattern: "solid", thin: false };
}

// The bar's height for a text line of _line_h with pixel _p: HP and MP are a whole number of 2p steps tall, XP half as tall (never under 2p).
function Ui_BarHeight(_kind, _line_h, _p) {
    var full = max(3 * _p, (_line_h div (2 * _p)) * 2 * _p);
    if (!Ui_BarStyle(_kind).thin) return full;
    return max(2 * _p, (full div (2 * _p)) * _p);
}

// D156: one row of the "Stats & terms" page: the term as the label, one short line in the details panel.
function Help_Term(_id, _label, _help) {
    return { id: _id, label: _label, value: "", kind: "button", enabled: true, help: _help, lines: [], hint: "" };
}

// D156: the rows of the Help "Stats & terms" page. The numbers in the lines come from the game's own constants; each status is explained by the
// same sentence the Status tab and the chips use.
function Help_StatsItems() {
    var out = [];
    array_push(out, Help_Term("power", Loc_T("card.lbl.power", "Power"), Loc_T("help.line.power", "How hard a weapon or skill hits. More Power means more damage.")));
    var stat_ids = [STAT_ATK, STAT_DEF, STAT_MAG, STAT_SPD];
    var stat_keys = ["atk", "def", "mag", "spd"];
    for (var i = 0; i < 4; i++) array_push(out, Help_Term(stat_keys[i], Stat_ShortName(stat_ids[i]), Stat_Sentence(stat_ids[i])));
    array_push(out, Help_Term("hp", Loc_T("battle.hud.hp", "HP"), Loc_T("help.line.hp", "Health. At 0 HP you fall.")));
    array_push(out, Help_Term("mp", Loc_T("battle.hud.mp", "MP"), Loc_T("help.line.mp", "Magic points. Skills spend them; potions and rest restore them.")));
    array_push(out, Help_Term("crit", Loc_T("help.term.crit", "Crit"), Loc_T("help.line.crit", "A critical hit deals {mult} times the damage. Take Aim and some gear raise the odds.", { mult: string(COMBAT_CRIT_MULT) })));
    array_push(out, Help_Term("perfect", Loc_T("battle.det.perfect", "Perfect"), Loc_T("help.line.perfect", "Press in the bright zone of the bar for +{pct}% damage.", { pct: string(round((Qte_GradeMult(QTE_PERFECT) - 1) * 100)) })));
    array_push(out, Help_Term("good", Loc_T("help.term.good", "Good"), Loc_T("help.line.good", "Press near the middle for +{pct}% damage.", { pct: string(round((Qte_GradeMult(QTE_GOOD) - 1) * 100)) })));
    array_push(out, Help_Term("ok", Loc_T("help.term.ok", "OK"), Loc_T("help.line.ok", "Press on the bar but off the middle for normal damage.")));
    array_push(out, Help_Term("weak", Loc_T("help.term.weak", "Weak"), Loc_T("help.line.weak", "Miss the zone and the hit deals {pct}% less damage.", { pct: string(round((1 - Qte_GradeMult(QTE_WEAK)) * 100)) })));
    array_push(out, Help_Term("break", Loc_T("help.term.break", "BREAK"), Loc_T("help.line.break", "Good hits fill the stagger meter. When it is full the enemy loses a turn and takes +{pct}% damage.", { pct: string(round((BREAK_DAMAGE_MULT - 1) * 100)) })));
    array_push(out, Help_Term("steadfast", Loc_T("battle.chip.steadfast", "Steadfast"), Loc_T("battle.chip.steadfast.line", "Cannot be stunned.")));
    array_push(out, Help_Term("elite", Loc_T("tab.lbl.elite", "Elite"), Loc_T("help.line.elite", "A marked, tougher enemy with a special trait. Its rewards are better.")));
    var sids = Status_AllIds();
    for (var s = 0; s < array_length(sids); s++) array_push(out, Help_Term("status_" + string(sids[s]), StatusDB_Get(sids[s]).name, Status_Description(sids[s])));
    return out;
}

// The Help list: every tutorial, then the stats page.
function TabHelp_Items() {
    var out = Tutorial_HelpItems();
    array_push(out, { id: "stats_terms", label: Loc_T("help.stats.title", "Stats & terms"), value: "", kind: "button", enabled: true, lines: [], hint: "",
                      help: Loc_T("help.stats.help", "What Power, ATK, DEF, MAG, SPD, Crit, the grades, BREAK and every status mean.") });
    return out;
}

// The Help page: every tutorial, seen or not, as a page on top of the System list.
function TabHelp_Open() {
    var u = TabMenu_Get();
    var pg = u.pages[u.tab];
    var m = Ui_MenuNew("help", TabHelp_Items(), {
        data: { tab: "help_page" }, on_confirm: TabMenu_OnConfirm,
        layout: { title: Loc_T("help.title", "Help"), anchor: "center", details: true, details_pos: "right", hides_below: true }
    });
    Ui_MenuFixCursor(m, m.cursor);
    Ui_StackPush(pg.stk, m);
}

// D156: the Stats & terms page on top of the Help list (scrolls with the cursor; Back returns to the list).
function TabHelpStats_Open() {
    var u = TabMenu_Get();
    var pg = u.pages[u.tab];
    var m = Ui_MenuNew("help_stats", Help_StatsItems(), {
        data: { tab: "help_stats" },
        layout: { title: Loc_T("help.stats.title", "Stats & terms"), anchor: "center", details: true, details_pos: "right", hides_below: true }
    });
    Ui_MenuFixCursor(m, m.cursor);
    Ui_StackPush(pg.stk, m);
}

// The settings are the existing screen (D0), opened as a tab: the same list, rows and Controls page, fitted to the body.
function TabSettings_Popup() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open || sp.owner != "tab") {
        SettingsPopup_Open("tab", true);
        sp = GameState_Get().ui.settings_popup;
        sp.menu.on_back = TabSettings_OnBack;
    }
    return sp;
}

// Leaving the menu closes the settings page. A window change nobody confirmed is put back first (D140). Every other change is already live.
function TabSettings_Discard() {
    if (KeepThis_Active()) KeepThis_Revert();
    if (!SettingsPopup_IsOpen("tab")) return;
    var sp = GameState_Get().ui.settings_popup;
    sp.controls = undefined;
    SettingsPopup_Close(true);
}

function TabSettings_OnBack(_m, _res) {
    Menu_Close();
}

function TabMenu_OnBack(_m, _res) {
    Menu_Close();
}

function TabMenu_Toast(_text) {
    var u = TabMenu_Get();
    if (!is_struct(u)) return;
    u.toast = _text;
    u.toast_ms = current_time;
}

// New items for the page on screen (after a potion, an equip): the cursor stays where it was, or on the nearest row.
function TabMenu_Refresh() {
    var u = TabMenu_Get();
    if (!is_struct(u)) return;
    var tid = TabMenu_Ids()[u.tab];
    if (tid == "settings" || !is_struct(u.pages[u.tab])) return;
    var root = u.pages[u.tab].stk.menus[0];
    var ch = GameState_Get().player_ch;
    var keep = root.cursor;
    root.items = TabMenu_ItemsFor(tid, ch);
    root.layout.title = TabMenu_Title(tid, ch);
    Ui_MenuFixCursor(root, min(keep, array_length(root.items) - 1));
}

function TabMenu_Switch(_u, _tab) {
    _u.tab = _tab;
    Ui_MemSet(Ui_MemGlobal(), "tab_menu_active", _tab);
    var tid = TabMenu_Ids()[_tab];
    if (tid == "settings") TabSettings_Popup();
    else _u.pages[_tab] = TabMenu_BuildPage(tid);
}

// Opens the Tab menu on the tab you used last (or _tab).
function Menu_Open(_tab = -1) {
    var gs = GameState_Get();
    var tab = (_tab >= 0) ? _tab : Ui_MemGet(Ui_MemGlobal(), "tab_menu_active", TabMenu_Count());
    var u = { tab: tab, pages: array_create(TabMenu_Count(), undefined), opened_ms: current_time, opened_frame: Input_Frame(), closed_ms: -1, toast: "", toast_ms: -100000, pending: "" };
    global.tab_ui = u;
    gs.ui.mode = UI_MENU;
    TabMenu_Switch(u, tab);
    SFX_PlayUI("ui_openclose");
}

function Menu_Close(_immediate = false) {
    var u = TabMenu_Get();
    if (!is_struct(u)) return;
    var gs = GameState_Get();
    if (_immediate) {
        TabSettings_Discard();
        global.tab_ui = undefined;
        if (gs.ui.mode == UI_MENU) gs.ui.mode = UI_NONE;
        SFX_PlayUI("ui_openclose");
        return;
    }
    if (u.closed_ms >= 0) return;
    TabSettings_Discard();
    u.closed_ms = current_time;
    SFX_PlayUI("ui_openclose");
}

// Once the fade is over: Abandon run ends the run (a fall that keeps the echo); Quit to title leaves for the title (Menu_QuitToTitle).
function Menu_CloseFinalize() {
    var gs = GameState_Get();
    var u = TabMenu_Get();
    var pending = (is_struct(u) && variable_struct_exists(u, "pending")) ? u.pending : "";
    global.tab_ui = undefined;
    if (gs.ui.mode == UI_MENU) gs.ui.mode = UI_NONE;
    if (pending == "abandon") {
        Run_Abandon();   // C1 (D92): counts as a death, keeps the echo; the death scene and the echo pick follow. Also in a fight (D141)
    } else if (pending == "quit") {
        Menu_QuitToTitle();
    }
}

// D46 / D141: on the map the run is saved as it is; in a fight there is no save of the fight: the run goes back to the snapshot taken when the
// fight began (the enemy back on the map, HP, MP and items as they were). Then the title.
function Menu_QuitToTitle() {
    var gs = GameState_Get();
    if (room == rm_battle) {
        EnemyPersist_WriteSnapshot();   // no snapshot (a fight that did not start from the map) leaves the last autosave as the run
        GameState_SetJustReturned(false);
    } else {
        Run_AutoSave();   // C1 (D46): leaving to the title keeps the run; Continue picks it up
    }
    gs.in_main_menu = true;
    gs.player_inst = noone;
    if (variable_struct_exists(gs, "ui")) {
        gs.ui.lines = [];
        gs.ui.index = 0;
        gs.ui.speaker = "";
        gs.ui.confirm_action = "";
    }
    if (room != rm_start) {
        RoomState_OnRoomExit();
        Transition_RequestLoadingRoomFade(rm_start);
    }
}

// Where the menu may open in a fight: in any list or message, never while a bar is running (the QTE timing is never interrupted).
// Esc is Back inside a list, so only the fight itself opens the menu on Esc, at the root command menu (obj_battle_controller Step).
function Menu_BattleAllowed(_battle_state, _qte_busy, _over) {
    if (_qte_busy || _over) return false;
    return (_battle_state == BSTATE_MENU || _battle_state == BSTATE_SKILL_MENU || _battle_state == BSTATE_ITEM_MENU || _battle_state == BSTATE_MESSAGE);
}

function Menu_BattleOpenNow() {
    if (room != rm_battle || !instance_exists(obj_battle_controller)) return false;
    var bc = instance_find(obj_battle_controller, 0);
    return Menu_BattleAllowed(bc.battle_state, Battle_QteBusy(bc), bc.battle_over);
}

// The map: when the player is settled. A fight: Menu_BattleOpenNow.
function Menu_CanOpen() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_NONE || gs.in_main_menu) return false;
    if (room == rm_battle) return Menu_BattleOpenNow();
    var pl = gs.player_inst;
    return instance_exists(pl) && Player_IsSettled(pl);
}

// True while the one menu is up (opening, open or fading out).
function Menu_IsOpen() {
    return GameState_Get().ui.mode == UI_MENU && is_struct(TabMenu_Get());
}

// 0..1 for the whole screen's fade (in while opening, out once closing).
function Menu_Alpha() {
    var u = TabMenu_Get();
    if (!is_struct(u)) return 0;
    return (u.closed_ms >= 0) ? (1 - Ui_AnimT(u.closed_ms, current_time)) : Ui_AnimT(u.opened_ms, current_time);
}

// True while the Controls page waits for a key or the "Keep this?" prompt is up: Q, E and the menu key belong to them then.
function Menu_CaptureActive() {
    if (KeepThis_Active()) return true;
    if (!SettingsPopup_IsOpen("tab")) return false;
    var sp = GameState_Get().ui.settings_popup;
    return is_struct(sp.controls) && sp.controls.capture != "";
}

// The menu on top of the page that is on screen (the settings list or the Controls page, a Codex page, a tab's list).
function TabMenu_TopMenu() {
    var u = TabMenu_Get();
    if (!is_struct(u)) return undefined;
    if (TabMenu_Ids()[u.tab] == "settings") {
        var sp = GameState_Get().ui.settings_popup;
        return is_struct(sp.controls) ? sp.controls.menu : sp.menu;
    }
    return is_struct(u.pages[u.tab]) ? Ui_StackTop(u.pages[u.tab].stk) : undefined;
}

// How many levels deep the page is (1 = a tab's own list).
function TabMenu_Depth() {
    var u = TabMenu_Get();
    if (!is_struct(u)) return 0;
    if (TabMenu_Ids()[u.tab] == "settings") return is_struct(GameState_Get().ui.settings_popup.controls) ? 2 : 1;
    return is_struct(u.pages[u.tab]) ? Ui_StackDepth(u.pages[u.tab].stk) : 1;
}

function TabCodex_Open(_kind) {
    var u = TabMenu_Get();
    var pg = u.pages[u.tab];
    var prof = Profile_Get();
    var rows;
    var title;
    var cols = 1;
    switch (_kind) {
        case "bestiary":
            rows = Codex_BestiaryRows(prof);
            title = Loc_T("tab.codex.bestiary_title", "Bestiary {n}/{max}", { n: string(Codex_BestiaryCount(prof)), max: string(array_length(rows)) });
            cols = 2;
            break;
        case "notes":
            rows = Codex_NoteRows(prof);
            title = Codex_NotesTitle(prof);
            break;
        case "history":
            rows = Codex_HistoryRows(prof);
            title = Loc_T("tab.codex.history", "Run history");
            break;
        default:
            rows = Codex_UnlockRows(prof);
            title = Loc_T("tab.codex.unlocks", "Unlocks");
            break;
    }
    if (array_length(rows) <= 0) return;
    var m = Ui_MenuNew("codex_" + _kind, rows, {
        data: { tab: "codex_page" },
        layout: { title: title, anchor: "center", details: true, details_pos: "right", details_cols: cols, det_art: true, hides_below: true }
    });
    if (_kind == "notes") m.on_confirm = TabNote_OnConfirm;
    Ui_MenuFixCursor(m, m.cursor);
    Ui_StackPush(pg.stk, m);
}

// ---- the note reader (D147) ----
// A found note opened from the Notes page: its whole text on one panel over the page, title on top. A long text scrolls with Up / Down (or the wheel);
// Back goes up one level. The text is wrapped at draw time to the panel's width and only the lines that fit are drawn, so nothing needs clipping.
function NoteReader_Join(_lines) {
    var txt = "";
    for (var j = 0; j < array_length(_lines); j++) txt += ((j > 0) ? "\n\n" : "") + _lines[j];   // a gap between the note's lines
    return txt;
}

function NoteReader_Text(_def) {
    return NoteReader_Join(_def.lines);
}

function NoteReader_Lines(_text, _w) {
    return Dialogue_WrapToLines(_text, _w);
}

// How far a text of _n lines scrolls in a window of _vis lines.
function NoteReader_MaxScroll(_n, _vis) {
    return max(0, _n - _vis);
}

// The first shown line after moving _dir (+1 down, -1 up) from _cur; it stays between the first line and the last full window.
function NoteReader_Scroll(_cur, _dir, _n, _vis) {
    return clamp(_cur + _dir, 0, NoteReader_MaxScroll(_n, _vis));
}

// D147 + D154: the reader shows Note_ReaderLines. While the note's question is open (data.ask) its two replies stand under the text, in a strip of their own;
// they can be used once the text has been read to its end (NoteReader_Armed). The answer is stored and flushed at once, then the reply's line is read.
function NoteReader_New(_def) {
    var ask = Note_AsksQuestion(_def);
    return Ui_MenuNew("codex_note_read", [], {
        data: { tab: "codex_page", reader: true, note_id: _def.id, text: NoteReader_Join(Note_ReaderLines(_def)), scroll: 0, wrapped: [], wrap_w: -1, visible: 8,
                ask: ask, labels: ask ? Choice_Lines(_def.id, "label") : [], pick: 0, reply_rects: [] },
        layout: { title: _def.title, anchor: "center", hides_below: true }
    });
}

// True while the replies can be used: the question is open and the whole text has been drawn and scrolled to its end.
function NoteReader_Armed(_m) {
    if (!TabNote_IsReader(_m) || !_m.data.ask || _m.data.wrap_w < 0) return false;
    return _m.data.scroll >= NoteReader_MaxScroll(array_length(_m.data.wrapped), _m.data.visible);
}

// Reply _i (0 or 1) is chosen: remembered in the profile and written to the file, the question is over, the reader goes on with that reply's line.
function NoteReader_Pick(_m, _i) {
    var d = _m.data;
    var def = Note_Find(d.note_id);
    if (!d.ask || !is_struct(def)) return false;
    var k = clamp(_i, 0, 1);
    if (!Choice_Remember(def.id, k + 1)) return false;
    SFX_PlayUI("ui_confirm");
    d.ask = false;
    d.pick = k;
    d.text = NoteReader_Join(Note_ReplyLines(def, k));
    d.wrap_w = -1;       // wrapped again at the next draw
    d.scroll = 1000000;  // and shown from its end (the draw keeps it inside the text)
    d.reply_rects = [];
    return true;
}

function TabNote_OpenReader(_def) {
    var u = TabMenu_Get();
    if (!is_struct(u) || !is_struct(_def)) return;
    Ui_StackPush(u.pages[u.tab].stk, NoteReader_New(_def));
}

function TabNote_OnConfirm(_m, _i) {
    var it = _m.items[_i];
    if (!variable_struct_exists(it, "note_id")) return;   // a ??? row
    var d = Note_Find(it.note_id);
    if (is_struct(d) && Note_IsCollected(Profile_Get(), d.id)) TabNote_OpenReader(d);
}

function TabNote_IsReader(_m) {
    return is_struct(_m) && is_struct(_m.data) && variable_struct_exists(_m.data, "reader") && _m.data.reader;
}

// Up / Down (held keys repeat) and the wheel move the text; called after the menu's own step. With the question open and the text read to its end, Up / Down
// move between the two replies instead (Up on the first one scrolls the text back), Confirm or a click picks the one under the cursor, the mouse moves it.
function TabNote_ReaderInput(_m) {
    if (!TabNote_IsReader(_m) || !variable_global_exists("ui_snap")) return;
    var sn = global.ui_snap;
    var d = _m.data;
    var armed = NoteReader_Armed(_m);
    if (armed) {
        var rr = d.reply_rects;
        var hv = Ui_HoverIndex(rr, sn.mx, sn.my);
        if (sn.mouse_moved && hv >= 0 && hv != d.pick) { d.pick = hv; SFX_PlayUI("ui_move"); }
        if (current_time - _m.lock_ms >= UI_INPUT_LOCK_MS) {   // the press that opened the reader must not answer it
            if (sn.click && hv >= 0) { NoteReader_Pick(_m, hv); return; }
            if (sn.confirm) { NoteReader_Pick(_m, d.pick); return; }
        }
    }
    var dv = (sn.down ? 1 : 0) - (sn.up ? 1 : 0);
    var step = 0;
    if (Ui_RepeatStep(_m.rep_v, dv, sn.up_p || sn.down_p, current_time) > 0) step = dv;
    if (armed && step != 0) {
        var to_pick = clamp(d.pick + step, 0, array_length(d.labels) - 1);
        if (step < 0 && d.pick == 0) {
            // Up on the first reply: the text scrolls back (the next draw no longer arms the replies)
        } else {
            if (to_pick != d.pick) { d.pick = to_pick; SFX_PlayUI("ui_move"); }
            step = 0;
        }
    }
    if (sn.wheel != 0) step = -sn.wheel;   // wheel up = towards the top
    if (step == 0) return;
    var to = NoteReader_Scroll(d.scroll, step, array_length(d.wrapped), d.visible);
    if (to != d.scroll) {
        d.scroll = to;
        SFX_PlayUI("ui_move");
    }
}

// The reader panel: fills the Tab menu's body (the list's top edge and height from TabMenu_FitMenu), title, a rule, the text, a scroll bar when it is long.
function TabNote_ReaderDraw(_m, _alpha) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var L = _m.layout;
    var rx = mt.margin;
    var rw = mt.gw - 2 * mt.margin;
    var slide = p * round((1 - _alpha) * 3);
    var ry = ((L.y_top >= 0) ? L.y_top : mt.margin) - slide;
    var rh = (L.max_h > 0) ? L.max_h : (mt.gh - 2 * mt.margin);
    _m.rect = { x: rx, y: ry, w: rw, h: rh };
    _m.det_rect = { x: 0, y: 0, w: 0, h: 0 };
    Ui_DrawFrame(rx, ry, rw, rh, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var x0 = rx + 4 * p;
    var x1 = rx + rw - 4 * p - 3 * p;   // the right 3p keep the scroll bar
    var ty = ry + 4 * p;
    Ui_Text(x0, ty, Ui_FitText(L.title, x1 - x0), UI_C_LIGHTEST);
    Ui_Box(rx + 3 * p, ty + mt.line_h + p, rx + rw - 3 * p, ty + mt.line_h + 2 * p, UI_C_DARK);
    ty += mt.line_h + 3 * p;
    var pitch = mt.line_h + p;
    var bottom = ry + rh - 4 * p;
    var d = _m.data;
    var text_bottom = bottom;
    var rows_y0 = bottom - 2 * mt.row_h;   // D154: while the note's question is open, its two replies stand in a strip under the text
    if (d.ask) text_bottom = rows_y0 - 3 * p;
    var vis = max(1, floor((text_bottom - ty) / pitch));
    if (d.wrap_w != x1 - x0 || d.visible != vis) {
        d.wrap_w = x1 - x0;
        d.wrapped = NoteReader_Lines(d.text, d.wrap_w);
        d.visible = vis;
    }
    var n = array_length(d.wrapped);
    d.scroll = clamp(d.scroll, 0, NoteReader_MaxScroll(n, vis));
    for (var i = d.scroll; i < min(n, d.scroll + vis); i++) {
        Ui_Text(x0, ty + (i - d.scroll) * pitch, d.wrapped[i], UI_C_LIGHTEST);
    }
    if (n > vis) {   // the bar: a dark track the height of the text window and a light thumb as long as the share that is shown
        var bx = rx + rw - 4 * p - p;
        var track_h = vis * pitch - p;
        Ui_Box(bx, ty, bx + p, ty + track_h, UI_C_DARK);
        var thumb_h = max(2 * p, round(track_h * vis / n / p) * p);
        var max_s = NoteReader_MaxScroll(n, vis);
        var thumb_y = ty + round((track_h - thumb_h) * d.scroll / max_s / p) * p;
        Ui_Box(bx, thumb_y, bx + p, thumb_y + thumb_h, UI_C_LIGHT);
    }
    if (d.ask) {   // the replies: pale until the text is read to its end, then the row under the cursor gets the menu's band and marker
        var armed = NoteReader_Armed(_m);
        Ui_Box(rx + 3 * p, rows_y0 - 2 * p, rx + rw - 3 * p, rows_y0 - p, UI_C_DARK);
        var rects = [];
        for (var r = 0; r < array_length(d.labels); r++) {
            var row_y = rows_y0 + r * mt.row_h;
            var sel = armed && (r == d.pick);
            if (sel) Ui_Box(rx + 3 * p, row_y, rx + rw - 3 * p, row_y + mt.row_h, UI_C_DARK);
            Ui_Text(x0 + 5 * p, row_y + (mt.row_h - mt.line_h) div 2, Ui_FitText(d.labels[r], x1 - x0 - 5 * p), Ui_RowColor(sel, true, !armed));
            if (sel) Ui_Arrow(x0 + Ui_Bob(current_time) * p, row_y + (mt.row_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
            array_push(rects, { x: rx + 2 * p, y: row_y, w: rw - 4 * p, h: mt.row_h });
        }
        d.reply_rects = armed ? rects : [];
    }
    draw_set_alpha(a0);
}

function TabMenu_OnConfirm(_m, _i) {
    var gs = GameState_Get();
    var ch = gs.player_ch;
    var it = _m.items[_i];
    switch (_m.data.tab) {
        case "items":
            if (variable_struct_exists(it, "throwable") && it.throwable) {
                SFX_PlayUI("ui_back");
                TabMenu_Toast(Loc_T("item.msg.throw_in_battle", "Throw it at an enemy in battle."));
                break;
            }
            var r = TabItems_Use(ch, it.item_id);
            if (r.ok) CardsUi_Commit(r.ch); else SFX_PlayUI("ui_back");
            TabMenu_Toast(r.msg);
            TabMenu_Refresh();
            break;
        case "gear":
            if (it.item_id < 0) break;
            var g = Gear_Toggle(ch, it.item_id);
            if (g.ok) CardsUi_Commit(g.ch); else SFX_PlayUI("ui_back");
            TabMenu_Toast(g.msg);
            TabMenu_Refresh();
            break;
        case "codex":
            TabCodex_Open(it.id);
            break;
        case "help_page":
            if (it.id == "stats_terms") TabHelpStats_Open();
            break;
        case "system":
            switch (it.id) {
                case "help":
                    TabHelp_Open();
                    break;
                case "abandon":
                case "quit":
                    Confirm_Open(TabSystem_Question(it.id, room == rm_battle), TabSystem_Yes, { id: it.id });   // D156
                    break;
            }
            break;
    }
}

function Menu_HandleInput() {
    var gs = GameState_Get();
    var u = TabMenu_Get();
    if (!is_struct(u)) {
        if (gs.ui.mode == UI_MENU) gs.ui.mode = UI_NONE;
        return;
    }
    if (u.closed_ms >= 0) {
        if (current_time - u.closed_ms >= UI_PANEL_MS) Menu_CloseFinalize();
        return;
    }
    var tid = TabMenu_Ids()[u.tab];
    // Q / E (or the shoulder buttons) change the tab and wrap; a click on a label goes straight to it
    if (!Menu_CaptureActive() && current_time - u.opened_ms >= UI_INPUT_LOCK_MS) {
        var d = (Input_Pressed("tab_next") ? 1 : 0) - (Input_Pressed("tab_prev") ? 1 : 0);
        var to = (d != 0) ? Ui_TabStep(u.tab, TabMenu_Count(), d) : u.tab;
        if (d == 0 && mouse_check_button_pressed(mb_left) && variable_global_exists("ui_tabs_rects")) {
            var mp = Ui_MousePos();
            var hi = Ui_HoverIndex(global.ui_tabs_rects, mp.x, mp.y);
            if (hi >= 0) to = hi;
        }
        if (to != u.tab) {
            SFX_PlayUI("ui_move");
            TabMenu_Switch(u, to);
            return;
        }
    }
    if (tid == "settings") {
        SettingsPage_Handle(TabSettings_Popup());
        return;
    }
    var pg = u.pages[u.tab];
    var top = Ui_StackTop(pg.stk);
    var ev = Ui_MenuUpdate(top, pg.stk);
    if (TabNote_IsReader(top) && !ev.back) TabNote_ReaderInput(top);
}

// The prompts for the footer: what Confirm does on the row under the cursor, then what Back does.
function TabMenu_Hint() {
    var m = TabMenu_TopMenu();
    var txt = "";
    if (KeepThis_Active()) return "";   // the prompt box carries its own keys
    if (is_struct(m) && array_length(m.items) > 0) {
        var it = m.items[clamp(m.cursor, 0, array_length(m.items) - 1)];
        if (variable_struct_exists(it, "hint")) txt = it.hint;
        else if (variable_struct_exists(it, "kind") && (it.kind == "choice" || it.kind == "slider")) txt = Loc_T("tab.hint.change", "{left}{right} Change");
        else if (TabMenu_Ids()[TabMenu_Get().tab] == "settings") txt = Loc_T("tab.hint.select", "[k:confirm] Select");
    }
    if (TabNote_IsReader(m) && NoteReader_MaxScroll(array_length(m.data.wrapped), m.data.visible) > 0) txt = Loc_T("tab.hint.scroll", "[k:up][k:down] Scroll");
    if (NoteReader_Armed(m)) txt = Loc_T("tab.hint.select", "[k:confirm] Select");   // D154: the note's question is open and its replies can be used
    if (txt != "") txt += "    ";
    return txt + ((TabMenu_Depth() > 1) ? Loc_T("tab.hint.back", "[k:back] Back") : Loc_T("tab.hint.close", "[k:back] Close"));
}

// The Status card (class, level, HP, MP, XP, gold, the run's seed small).
function TabMenu_StatusCardH(_z) {
    return 12 * _z.mt.p + 6 * _z.mt.line_h;
}

// D108 F1c: the Status card's texts that only change with the language, and their widths (which also change with the metrics), kept per
// (language, Ui_Metrics struct). The width of the biggest "cur/max" text is kept for the character's three maxima. Counted (TabMenu_CardBuilds).
function TabMenu_CardBuilds() {
    return variable_global_exists("tabmenu_card_builds") ? global.tabmenu_card_builds : 0;
}

function TabMenu_CardData(_mt) {
    var lang = Loc_GetLanguage();
    var c = variable_global_exists("tabmenu_card") ? global.tabmenu_card : undefined;
    if (is_struct(c) && c.lang == lang && c.mt == _mt) return c;
    global.tabmenu_card_builds = TabMenu_CardBuilds() + 1;
    c = {
        lang: lang, mt: _mt,
        hp: Loc_T("battle.hud.hp", "HP"), mp: Loc_T("battle.hud.mp", "MP"), xp: Loc_T("tab.lbl.xp", "XP"), xp_max: Loc_T("tab.val.max", "MAX"),
        level_tpl: Loc_T("battle.hud.level", "Lv {n}"), seed_tpl: Loc_T("tab.lbl.seed_small", "Seed: {n}"),
        lab_w: 0, k_hp: -999, k_mp: -999, k_xp: -999, val_w: 0
    };
    c.lab_w = max(UI_TextWidth(c.hp), max(UI_TextWidth(c.mp), UI_TextWidth(c.xp)));
    global.tabmenu_card = c;
    return c;
}

// One bar row of the card: label, bar, "cur/max".
function TabMenu_DrawCardBar(_x0, _x1, _yy, _bx, _bw, _lab, _ratio, _txt, _kind) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var lh = mt.line_h;
    var st = Ui_BarStyle(_kind);   // D156: HP solid, MP striped, XP thin and in segments
    var bh = Ui_BarHeight(_kind, lh, p);
    Ui_Text(_x0, _yy, _lab, UI_C_LIGHT);
    Battle_DrawBar(_bx, _yy + (lh - bh) div 2, _bw, bh, p, _ratio, _ratio, st.fill, UI_C_LIGHTEST, st.pattern == "stripe", st.pattern == "segments");
    Ui_Text(_x1, _yy, _txt, UI_C_LIGHT, fa_right);
}

function TabMenu_DrawStatusCard(_x, _y, _w, _h, _ch, _alpha) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var lh = mt.line_h;
    var cd = TabMenu_CardData(mt);
    Ui_DrawFrame(_x, _y, _w, _h, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var x0 = _x + 4 * p;
    var x1 = _x + _w - 4 * p;
    var yy = _y + 4 * p;
    var nm = (is_struct(_ch.class_cfg) && variable_struct_exists(_ch.class_cfg, "name")) ? _ch.class_cfg.name : "";
    Ui_Text(x0, yy, nm, UI_C_LIGHTEST);
    Ui_Text(x1, yy, string_replace_all(cd.level_tpl, "{n}", string(_ch.level)), UI_C_LIGHT, fa_right);   // what Loc_T(.., { n }) makes
    yy += lh + p;
    if (cd.k_hp != _ch.max_hp || cd.k_mp != _ch.max_mp || cd.k_xp != _ch.exp_next) {   // the widest "cur/max" text only changes with the maxima
        var vw = UI_TextWidth(string(_ch.max_hp) + "/" + string(_ch.max_hp));
        vw = max(vw, UI_TextWidth(string(_ch.max_mp) + "/" + string(_ch.max_mp)));
        vw = max(vw, UI_TextWidth(string(_ch.exp_next) + "/" + string(_ch.exp_next)));
        cd.val_w = vw;
        cd.k_hp = _ch.max_hp;
        cd.k_mp = _ch.max_mp;
        cd.k_xp = _ch.exp_next;
    }
    var bx = x0 + cd.lab_w + 2 * p;
    var bw = x1 - cd.val_w - 2 * p - bx;
    TabMenu_DrawCardBar(x0, x1, yy, bx, bw, cd.hp, (_ch.max_hp > 0) ? clamp(_ch.hp / _ch.max_hp, 0, 1) : 1, string(_ch.hp) + "/" + string(_ch.max_hp), "hp");
    yy += lh + p;
    TabMenu_DrawCardBar(x0, x1, yy, bx, bw, cd.mp, (_ch.max_mp > 0) ? clamp(_ch.mp / _ch.max_mp, 0, 1) : 1, string(_ch.mp) + "/" + string(_ch.max_mp), "mp");
    yy += lh + p;
    TabMenu_DrawCardBar(x0, x1, yy, bx, bw, cd.xp, (_ch.exp_next > 0) ? clamp(_ch.exp / _ch.exp_next, 0, 1) : 1, (_ch.exp_next > 0) ? (string(_ch.exp) + "/" + string(_ch.exp_next)) : cd.xp_max, "xp");
    yy += lh + p;
    Hud_DrawCoin(x0, yy + (lh - 6 * p) div 2, p);
    Ui_Text(x0 + 8 * p, yy, string(Gold_Get()), UI_C_LIGHTEST);
    yy += lh + p;
    var run = Run_Get();
    if (is_struct(run)) Ui_Text(x0, yy, string_replace_all(cd.seed_tpl, "{n}", string(run.seed)), UI_C_LIGHT);
    draw_set_alpha(a0);
}

function TabMenu_DrawFooter(_z, _alpha) {
    var mt = _z.mt;
    var p = mt.p;
    var gold = string(Gold_Get());
    var gw = 8 * p + UI_TextWidth(gold);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Prompt_RichDraw(_z.x, _z.foot_y + (_z.foot_h - mt.line_h) div 2, TabMenu_Hint(), _z.w - gw - 4 * p, UI_C_LIGHT, fa_left, _alpha);
    var gx = _z.x + _z.w - gw;
    Hud_DrawCoin(gx, _z.foot_y + (_z.foot_h - 6 * p) div 2, p);
    Ui_Text(gx + 8 * p, _z.foot_y + (_z.foot_h - mt.line_h) div 2, gold, UI_C_LIGHTEST);
    draw_set_alpha(a0);
}

function Menu_Draw() {
    var u = TabMenu_Get();
    if (!is_struct(u)) return;
    var now = current_time;
    var a = Menu_Alpha();
    var tid = TabMenu_Ids()[u.tab];
    var topm = TabMenu_TopMenu();
    var z = TabMenu_Zones((is_struct(topm) && string_pos("codex_", topm.id) == 1) ? topm.id : tid);
    var mt = z.mt;
    var p = mt.p;
    var gs = GameState_Get();
    var ch = gs.player_ch;
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.9 * a);
    Ui_DrawTabs(z.x, z.tabs_y, z.w, TabMenu_Labels(), u.tab, a, TabMenu_Icons());
    var extra = 0;
    if (tid == "status") {
        var ch_h = TabMenu_StatusCardH(z);
        TabMenu_DrawStatusCard(z.x, z.body_y, z.list_w, ch_h, ch, a);
        extra = ch_h + 2 * p;
    }
    if (tid == "settings") {
        if (SettingsPopup_IsOpen("tab")) {   // (closed already while the screen fades out)
            var sp = GameState_Get().ui.settings_popup;
            var sm = is_struct(sp.controls) ? sp.controls.menu : sp.menu;
            TabMenu_FitMenu(sm, z);
            Ui_MenuDraw(sm, a * Ui_MenuAlpha(sm, now));
        }
    } else {
        var stk = u.pages[u.tab].stk;
        if (is_struct(stk.leaving) && Ui_MenuAlpha(stk.leaving, now) <= 0) stk.leaving = undefined;
        var top = Ui_StackTop(stk);
        TabMenu_FitMenu(top, z, (Ui_StackDepth(stk) == 1) ? extra : 0);
        Ui_MenuDraw(top, a * Ui_MenuAlpha(top, now));
        if (is_struct(stk.leaving)) {
            TabMenu_FitMenu(stk.leaving, z, 0);
            Ui_MenuDraw(stk.leaving, a * Ui_MenuAlpha(stk.leaving, now));
        }
    }
    TabMenu_DrawFooter(z, a);
    KeepThis_Draw(a);
    Confirm_Draw();   // D156: Abandon run and Quit to title ask over the whole menu
    if (u.toast != "" && now - u.toast_ms < TAB_TOAST_MS) {
        var tw = UI_TextWidth(u.toast) + 8 * p;
        var th = mt.line_h + 6 * p;
        var tx = round((mt.gw - tw) / 2);
        var ty = z.foot_y - 2 * p - th;
        Ui_DrawFrame(tx, ty, tw, th, a, p);
        draw_set_alpha(a);
        Ui_Text(tx + 4 * p, ty + 3 * p, u.toast, UI_C_LIGHTEST);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ==========================================================================================================================
// C2: the card screens, on the shared UI framework (D0, D95-D100): class choice (D73, D83), free stat point (D76), 1-of-3 card pick (D81),
// replace a skill (D82). What a character owes is kept on the character (Cards_NextOwed, scr_levelup), so a save, a reload or an interrupted
// screen loses nothing; CardsUi_Step (obj_ui_controller Step) opens the next owed screen when nothing else is on screen.
// global.cards_ui = { kind, stk, pick, lock, opened_ms } while a screen is open, with gs.ui.mode = UI_CARDS. Class, stat and replace
// are Ui menus on a Ui stack (list + details panel); the pick is three cards side by side, drawn with the same frame and text kit.
// ==========================================================================================================================
#macro CARDS_UI_INPUT_DELAY_MS (10000 / 60)   // keys are ignored this long after a screen opens (the press that opened it must not answer it); D108 F2b-2: ms, was 10 frames

function CardsUi_IsOpen() {
    return variable_global_exists("cards_ui") && is_struct(global.cards_ui);
}

function CardsUi_Kind() {
    return CardsUi_IsOpen() ? global.cards_ui.kind : "";
}

function CardsUi_Close() {
    var gs = GameState_Get();
    global.cards_ui = undefined;
    if (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_CARDS) gs.ui.mode = UI_NONE;
}

// A room change or a battle closes whatever is open; what is owed stays owed and opens again.
function CardsUi_Interrupt() {
    if (CardsUi_IsOpen()) CardsUi_Close();
}

// A changed copy of the character becomes the player (the world object keeps pointing at the live one).
function CardsUi_Commit(_ch) {
    GameState_SetPlayer(_ch);
    if (instance_exists(obj_player)) obj_player.character = GameState_Get().player_ch;
    GameState_SyncLegacy();
}

// Opens the next owed screen when nothing else is going on. Returns true when a screen is open this frame (the caller stops there).
function CardsUi_Step() {
    var gs = GameState_Get();
    if (CardsUi_IsOpen()) {
        CardsUi_HandleInput();
        return CardsUi_IsOpen();
    }
    if (!Run_IsActive()) return false;
    if (Transition_IsActive() || Transition_IsInputLocked()) return false;
    if (gs.ui.mode != UI_NONE || array_length(gs.ui.lines) > 0) return false;
    if (room == rm_battle || room == rm_start || room == rm_cutscene) return false;
    if (!is_struct(gs.player_ch)) return false;
    if (instance_exists(gs.player_inst) && !Player_IsSettled(gs.player_inst)) return false;
    var owed = Cards_NextOwed(gs.player_ch);
    if (owed == "") return false;
    CardsUi_Open(owed);
    return CardsUi_IsOpen();
}

function CardsUi_Open(_kind) {
    var gs = GameState_Get();
    var u = { kind: _kind, stk: Ui_StackNew(), pick: undefined, lock: InputLock_New(CARDS_UI_INPUT_DELAY_MS), opened_ms: current_time };
    switch (_kind) {
        case "class": Ui_StackPush(u.stk, CardsUi_ClassMenu()); break;
        case "echo": Ui_StackPush(u.stk, CardsUi_EchoMenu()); break;
        case "stat": Ui_StackPush(u.stk, CardsUi_StatMenu()); break;
        case "replace": Ui_StackPush(u.stk, CardsUi_ReplaceMenu()); break;
        case "cards": u.pick = CardsUi_PickNew(); break;
        default: return false;
    }
    global.cards_ui = u;
    gs.ui.mode = UI_CARDS;
    SFX_PlayUI("ui_openclose");
    if (_kind == "cards") Tutorial_Trigger("cards");   // D45
    return true;
}

function CardsUi_HandleInput() {
    var u = global.cards_ui;
    if (InputLock_Active(u.lock)) return;
    if (u.kind == "cards") {
        CardsUi_PickUpdate(u);
    } else {
        var top = Ui_StackTop(u.stk);
        if (is_struct(top)) Ui_MenuUpdate(top, u.stk);
    }
}

// Back does nothing on a screen that must be answered.
function CardsUi_NoBack(_m, _res) {
}

// ---- class choice -------------------------------------------------------------------------------------------------------------
// D148: the class screen. Beside the list stands a panel with the class's idle sprite, its lore and playstyle, the starting numbers and the five skills of the
// class: "???" until the profile has had that skill in some run (skill memory), then the name and its MP. A locked Nobody is greyed (the sprite too), says what unlocks it
// and cannot be picked. _prof is the profile to read (tests); the game reads its own.
function CardsUi_ClassMenu(_prof = undefined) {
    var prof = is_undefined(_prof) ? Profile_Get() : _prof;
    var choices = Card_ClassChoices(prof);
    var items = [];
    for (var i = 0; i < array_length(choices); i++) {
        var cid = choices[i].class_id;
        var cfg = DB_PlayerClass(cid);
        var locked = choices[i].locked;
        var skills = Class_SkillRows(prof, cid);
        var lines = [];
        if (!locked) {
            lines = [   // the four numbers as two lines, so the five skills below still fit the panel at the biggest text size
                { label: Stat_ShortName(STAT_ATK) + " / " + Stat_ShortName(STAT_DEF), value: string(cfg.stats.atk) + " / " + string(cfg.stats.def) },
                { label: Stat_ShortName(STAT_SPD) + " / " + Stat_ShortName(STAT_MAG), value: string(cfg.stats.spd) + " / " + string(cfg.stats.mag) }
            ];
            if (array_length(skills) == 0) {
                array_push(lines, { label: Loc_T("card.lbl.skills", "Skills"), value: Loc_T("class.lbl.none", "None") });
            } else {
                for (var s = 0; s < array_length(skills); s++) {
                    array_push(lines, { label: skills[s].label, value: skills[s].known ? Loc_T("card.mp_short", "{mp} MP", { mp: string(round(SkillDB_GetBase(skills[s].id).mp_cost)) }) : "" });
                }
            }
        }
        var spr = cfg.sprites.down;
        array_push(items, {
            label: cfg.name, value: locked ? Loc_T("class.nobody.locked", "Locked") : "",
            help: locked ? choices[i].hint : Card_ClassSentence(cid), lines: lines, class_id: cid, locked: locked, dim: locked, skills: skills,
            pic: { spr: spr, sub: 0, anim_ms: 450, tint: locked ? c_gray : c_white }   // the idle sprite: its two frames take turns
        });
    }
    var m = Ui_MenuNew("cards_class", items, {
        on_confirm: CardsUi_ClassConfirm, on_back: CardsUi_NoBack,
        layout: { title: Loc_T("class.select.title", "Select Class"), anchor: "center", details: true }
    });
    CardsUi_ClassFit(m);
    Ui_MenuFixCursor(m, 0);
    return m;
}

// The list stands on the left, the details panel (picture, text, numbers) beside it, both as tall as the screen allows.
function CardsUi_ClassFit(_m) {
    var mt = Ui_Metrics();
    var L = _m.layout;
    var avail_h = mt.gh - 2 * mt.margin;
    L.x_anchor = "left";
    var need = UI_TextWidth(L.title);
    for (var i = 0; i < array_length(_m.items); i++) need = max(need, UI_TextWidth(_m.items[i].label) + 4 * mt.p + UI_TextWidth(_m.items[i].value));   // a row's name and its Locked mark in full
    L.panel_w = max(floor((mt.gw - 3 * mt.margin) * 0.4 / mt.p) * mt.p, need + 21 * mt.p);
    L.y_top = mt.margin;
    L.max_h = avail_h;
    L.details = true;
    L.details_pos = "right";
    L.det_w = mt.gw - 3 * mt.margin - L.panel_w;
    L.det_top = mt.margin;
    L.det_h = avail_h;
    L.det_art = true;
}

function CardsUi_ClassConfirm(_m, _i) {
    var it = _m.items[_i];
    if (it.locked) {
        SFX_PlayUI("ui_back");
        return;
    }
    Confirm_Open(Loc_T("class.select.become", "Become {cls}?", { cls: it.label }), CardsUi_ClassYes, { class_id: it.class_id });   // D156: the shared pop-up, No first
}

function CardsUi_ClassYes(_d) {
    var cid = _d.class_id;
    CardsUi_Close();
    // the black flash covers the swap of the character, as it did with the old popup
    var queued = Transition_RequestBlackFlash(TRANSITION_CLASS_SELECT_FADE_OUT_FRAMES, TRANSITION_CLASS_SELECT_FADE_IN_FRAMES, cid);
    if (!queued) ClassSelect_ApplyClass(cid);
}

// Makes the chosen class the player (called mid-flash by the transition, or at once when no flash could start).
function ClassSelect_ApplyClass(_class_id) {
    var gs = GameState_Get();
    var ch = Card_ClassCharacter(gs.player_ch, _class_id);
    Skills_DiscoverAll(ch.skills);   // D148: skills carried over or given by the class itself are remembered too

    // FUN-FIRST: grant and auto-equip class starter weapon (no duplicates).
    ch = Equip_GrantStarterWeapon(ch, _class_id, true);
    var hp0 = ch.hp;
    var mp0 = ch.mp;
    ch = Player_NormalizeProgression(ch, true);
    ch.hp = clamp(hp0, 1, ch.max_hp);
    ch.mp = clamp(mp0, 0, ch.max_mp);
    ch = Run_EchoGrant(ch);   // D144: the discovered skills of this class are owed as the echo pick (CardsUi_Step opens it); none discovered, no pick

    GameState_SetSelectedClass(_class_id);
    GameState_SetPlayer(ch);

    if (instance_exists(obj_player)) {
        with (obj_player) {
            character = GameState_Get().player_ch;
            Player_ApplyClassSprites(GameState_Get().selected_class);
            sprite_index = sprite[face];
            image_index = 0;
            mask_index = sprite[DOWN];
        }
    }

    GameState_SyncLegacy();
    Dialogue_TryStartClassChestReaction(_class_id);
}

// ---- the echo (D144, amends D130 / D87): up to 3 skills of the picked class that an earlier run discovered (skill memory, D148); one is kept ----------------------------------------
// What an echo option does, in the details panel's terms (D100): one plain sentence and the numbers from the data.
function CardsUi_EchoDetails(_o) {
    if (_o.kind == "skill") return Battle_SkillDetails(SkillDB_Get(_o.id));
    var it = ItemDB_Get(_o.id);
    return { sentence: Item_Sentence(it), lines: Item_NumberLines(it, GameState_Get().player_ch) };
}

function CardsUi_EchoMenu() {
    var offer = GameState_Get().player_ch.echo_offer;
    var items = [];
    for (var i = 0; i < array_length(offer); i++) {
        var o = offer[i];
        var det = CardsUi_EchoDetails(o);
        var row = { label: Run_EchoLabel(o), help: det.sentence, lines: det.lines, echo_index: i };
        if (o.kind == "skill") row.seq = Qte_SkillSequence(o.id);
        array_push(items, row);
    }
    var m = Ui_MenuNew("run_echo", items, {
        on_confirm: CardsUi_EchoConfirm, on_back: CardsUi_NoBack,   // it must be answered
        layout: { title: Loc_T("echo.pick.title", "Keep one skill you remember"), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);   // the remembered cursor of an earlier screen does not count
    return m;
}

// The name of what an echo option gives (a skill's or an item's), for the question.
function CardsUi_EchoName(_o) {
    return (_o.kind == "skill") ? SkillDB_Get(_o.id).name : ItemDB_Get(_o.id).name;
}

function CardsUi_EchoConfirm(_m, _i) {
    var idx = _m.items[_i].echo_index;
    var o = GameState_Get().player_ch.echo_offer[idx];
    Confirm_Open(Loc_T("confirm.echo", "Keep {name} as your echo?", { name: CardsUi_EchoName(o) }), CardsUi_EchoYes, { echo_index: idx });   // D156
}

function CardsUi_EchoYes(_d) {
    var gs = GameState_Get();
    CardsUi_Commit(Run_EchoTake(gs.player_ch, _d.echo_index));
    Run_EchoDone();
    CardsUi_Close();
}

// ---- free stat point (D76) ------------------------------------------------------------------------------------------------------
function CardsUi_StatHelp(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return Loc_T("menu.tooltip.stat.atk.desc", "Increases physical damage (basic attacks and ATK skills).");
        case STAT_DEF: return Loc_T("menu.tooltip.stat.def.desc", "Reduces all damage you take.");
        case STAT_SPD: return Loc_T("menu.tooltip.stat.spd.desc", "Decides who acts first.");
        case STAT_MAG: return Loc_T("menu.tooltip.stat.mag.desc", "Increases spell damage and max MP.");
        case FREE_POINT_MAX_HP: return Loc_T("cards.stat.maxhp.desc", "Raises your max HP by {n} and heals {n} HP.", { n: FREE_POINT_HP_GAIN });   // D143
        case FREE_POINT_MAX_MP: return Loc_T("cards.stat.maxmp.desc", "Raises your max MP by {n} and restores {n} MP.", { n: FREE_POINT_MP_GAIN });
    }
    return "";
}

function CardsUi_StatMenu() {
    var ch = GameState_Get().player_ch;
    var opts = Cards_FreePointOptions(ch);   // D143: the four stats, Max HP, Max MP
    var items = [];
    for (var i = 0; i < array_length(opts); i++) {
        var o = opts[i];
        array_push(items, {
            label: o.label, value: string(o.from) + " > " + string(o.to), help: CardsUi_StatHelp(o.stat),
            lines: [ { label: Loc_T("cards.stat.now", "Now"), value: string(o.from) }, { label: Loc_T("cards.stat.after", "After"), value: string(o.to) } ],
            stat: o.stat
        });
    }
    var m = Ui_MenuNew("cards_stat", items, {
        on_confirm: CardsUi_StatConfirm, on_back: CardsUi_NoBack,
        layout: { title: Loc_T("cards.stat.title", "Level {lvl}: place 1 point", { lvl: string(ch.level) }), note: LevelUp_GrowthText(ch.class_id, ch.level), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, clamp(DB_PlayerClass(ch.class_id).free_default, 0, 3));   // the class's usual stat first
    return m;
}

function CardsUi_StatConfirm(_m, _i) {
    var gs = GameState_Get();
    CardsUi_Commit(Cards_PlaceStat(gs.player_ch, _m.items[_i].stat));
    CardsUi_Close();
}

// ---- replace a skill (D82) ------------------------------------------------------------------------------------------------------
function CardsUi_CompareLines(_old_id, _new_id) {
    var a = SkillDB_Get(_old_id);
    var b = SkillDB_GetBase(_new_id);
    var lines = [];
    if (a.effect == "damage" || b.effect == "damage") array_push(lines, Card_NumLine(Loc_T("card.lbl.power", "Power"), round(a.power), round(b.power)));
    array_push(lines, Card_NumLine(Loc_T("card.lbl.mp", "MP"), round(a.mp_cost), round(b.mp_cost)));
    array_push(lines, Card_NumLine(Loc_T("card.lbl.arrows", "Arrows"), array_length(Qte_SkillSequence(_old_id)), array_length(Qte_SkillSequenceBase(_new_id))));
    return lines;
}

function CardsUi_ReplaceMenu() {
    var ch = GameState_Get().player_ch;
    var new_id = ch.skill_pending;
    var items = [];
    for (var i = 0; i < array_length(ch.skills); i++) {
        var sk = SkillDB_Get(ch.skills[i]);
        array_push(items, { label: sk.name, value: Loc_T("card.mp_short", "{mp} MP", { mp: string(round(sk.mp_cost)) }), help: Loc_T("cards.replace.lose", "Gives up: {line}", { line: Card_SkillSentence(sk) }), lines: CardsUi_CompareLines(ch.skills[i], new_id), skill_id: ch.skills[i] });
    }
    array_push(items, { label: Loc_T("cards.replace.keep", "Keep my skills"), value: "", help: Loc_T("cards.replace.keep_help", "Go back to the cards and choose again."), lines: [], skill_id: -1 });
    var m = Ui_MenuNew("cards_replace", items, {
        on_confirm: CardsUi_ReplaceConfirm, on_back: CardsUi_ReplaceBack,
        layout: { title: Loc_T("cards.replace.title", "Learn {skill}: replace which?", { skill: SkillDB_GetBase(new_id).name }), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

function CardsUi_ReplaceConfirm(_m, _i) {
    var gs = GameState_Get();
    var ch = gs.player_ch;
    var old_id = _m.items[_i].skill_id;
    if (old_id < 0) {
        CardsUi_ReplaceBack(_m, "root");
        return;
    }
    Confirm_Open(Loc_T("confirm.replace", "Forget {forget} and learn {learn}?", { forget: SkillDB_Get(old_id).name, learn: SkillDB_GetBase(ch.skill_pending).name }), CardsUi_ReplaceYes, { old_id: old_id });   // D156
}

function CardsUi_ReplaceYes(_d) {
    var ch = GameState_Get().player_ch;
    var out = Card_ReplaceSkill(ch, _d.old_id, ch.skill_pending);
    out = Cards_ConsumePick(out);
    CardsUi_Commit(out);
    CardsUi_Close();
}

// Keeping the skills puts the card back: the pick is still owed and the same offer comes up again.
function CardsUi_ReplaceBack(_m, _res) {
    var gs = GameState_Get();
    gs.player_ch.skill_pending = -1;
    CardsUi_Close();
}

// ---- the card pick (D81) --------------------------------------------------------------------------------------------------------
function CardsUi_PickNew() {
    var ch = GameState_Get().player_ch;
    if (!is_array(ch.offer) || array_length(ch.offer) != CARD_OFFER_SIZE) ch.offer = Card_OfferFromRun(ch).cards;
    return { ids: ch.offer, cursor: 0, last: 0, rects: [] };
}

function CardsUi_Take(_card_id) {
    var gs = GameState_Get();
    var r = Card_Take(gs.player_ch, _card_id);
    if (r.needs_replace) {
        // every slot is full: ask which skill goes; the pick stays owed until it is answered
        gs.player_ch.skill_pending = r.card.skill_id;
        CardsUi_Close();
        return;
    }
    var run = Run_Get();
    if (r.gold > 0 && is_struct(run)) run.gold += r.gold;
    CardsUi_Commit(Cards_ConsumePick(r.ch));
    CardsUi_Close();
}

function CardsUi_SkipPick() {
    var gs = GameState_Get();
    Card_SkipOffer();
    CardsUi_Commit(Cards_ConsumePick(gs.player_ch));
    CardsUi_Close();
}

function CardsUi_PickUpdate(_u) {
    var pk = _u.pick;
    var snap = Ui_ReadInput();
    var n = array_length(pk.ids);
    var dx = (snap.right_p ? 1 : 0) - (snap.left_p ? 1 : 0);
    var dy = (snap.down_p ? 1 : 0) - (snap.up_p ? 1 : 0);
    var hover = Ui_HoverIndex(pk.rects, snap.mx, snap.my);
    var cur = pk.cursor;
    if (snap.mouse_moved && hover >= 0) cur = hover;
    if (dx != 0 || dy != 0) cur = Cards_PickMove(cur, n, dx, dy, pk.last);
    if (cur != pk.cursor) {
        pk.cursor = cur;
        if (cur < n) pk.last = cur;
        SFX_PlayUI("ui_move");
    }
    var go = snap.confirm || (snap.click && hover == pk.cursor);
    if (go) {
        SFX_PlayUI("ui_confirm");
        if (pk.cursor < n) CardsUi_Take(pk.ids[pk.cursor]);
        else CardsUi_SkipPick();
    }
}

// ---- drawing -----------------------------------------------------------------------------------------------------------------
// The arrows of a skill or upgrade card, centred in a dark box, width _w. Returns the height used.
function CardsUi_DrawArrows(_x, _y, _w, _seq, _unit) {
    var n = array_length(_seq);
    if (n <= 0) return 0;
    var u = max(1, _unit);
    var cell = 11 * u;
    var h = 13 * u;
    var total = n * cell;
    Ui_Box(_x, _y, _x + _w, _y + h, UI_C_DARK);
    var x0 = _x + round((_w - total) / 2);
    for (var i = 0; i < n; i++) Qte_DrawArrowGlyph(x0 + i * cell + u, _y + 2 * u, _seq[i], u, UI_C_LIGHTEST, UI_C_DARKEST);
    return h;
}

// A number line whose label and value do not fit side by side: the value goes on the row below.
function CardsUi_LineStacked(_line, _iw, _mt) {
    return UI_TextWidth(_line.label) + 3 * _mt.p + UI_TextWidth(_line.value) > _iw;
}

function CardsUi_CardHeight(_c, _w, _mt) {
    var p = _mt.p;
    var iw = _w - 8 * p;
    var h = 8 * p;
    h += max(Ui_TextBlockH(Card_Name(_c), iw - 5 * p), _mt.line_h) + 2 * p;
    h += _mt.line_h + 3 * p;
    h += Ui_TextBlockH(Card_Sentence(_c), iw) + 2 * p;
    var seq = Card_Sequence(_c);
    if (array_length(seq) > 0) h += 13 * clamp(floor(iw / 60), 1, 3) + 2 * p;
    var lines = Card_Lines(_c);
    for (var i = 0; i < array_length(lines); i++) h += (CardsUi_LineStacked(lines[i], iw, _mt) ? 2 : 1) * (_mt.line_h + p);
    return h;
}

function CardsUi_DrawCard(_x, _y, _w, _h, _c, _sel, _a) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var iw = _w - 8 * p;
    if (_sel) {   // a bright halo outside the frame
        Ui_Box(_x + p, _y - p, _x + _w - p, _y, UI_C_LIGHT);
        Ui_Box(_x + p, _y + _h, _x + _w - p, _y + _h + p, UI_C_LIGHT);
        Ui_Box(_x - p, _y + p, _x, _y + _h - p, UI_C_LIGHT);
        Ui_Box(_x + _w, _y + p, _x + _w + p, _y + _h - p, UI_C_LIGHT);
    }
    Ui_DrawFrame(_x, _y, _w, _h, _a, p);
    var x0 = _x + 4 * p;
    var ty = _y + 4 * p;
    var name = Card_Name(_c);
    var nh = max(Ui_TextBlockH(name, iw - 5 * p), mt.line_h);
    if (_sel) {
        Ui_Box(_x + 3 * p, ty - p, _x + _w - 3 * p, ty + nh + p, UI_C_DARK);
        Ui_Arrow(x0 + Ui_Bob(current_time) * p, ty + (mt.line_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    }
    Ui_TextBlock(x0 + 5 * p, ty, name, iw - 5 * p, UI_C_TEXT);
    ty += nh + 2 * p;
    Ui_Text(x0 + 5 * p, ty, Card_TypeTag(_c), UI_C_LIGHT);
    ty += mt.line_h + p;
    Ui_Box(_x + 3 * p, ty, _x + _w - 3 * p, ty + p, UI_C_DARK);
    ty += 2 * p;
    var sentence = Card_Sentence(_c);
    Ui_TextBlock(x0, ty, sentence, iw, UI_C_LIGHTEST);
    ty += Ui_TextBlockH(sentence, iw) + 2 * p;
    var seq = Card_Sequence(_c);
    if (array_length(seq) > 0) {
        var u = clamp(floor(iw / 60), 1, 3);
        ty += CardsUi_DrawArrows(x0, ty, iw, seq, u) + 2 * p;
    }
    var lines = Card_Lines(_c);
    for (var i = 0; i < array_length(lines); i++) {
        Ui_Text(x0, ty, lines[i].label, UI_C_LIGHT);
        if (CardsUi_LineStacked(lines[i], iw, mt)) ty += mt.line_h + p;
        Ui_Text(x0 + iw, ty, lines[i].value, UI_C_LIGHTEST, fa_right);
        ty += mt.line_h + p;
    }
}

function CardsUi_DrawPick(_u, _a) {
    var pk = _u.pick;
    var mt = Ui_Metrics();
    var p = mt.p;
    var n = array_length(pk.ids);
    var gap = 4 * p;
    var margin = mt.margin;
    var cw = floor((mt.gw - 2 * margin - (n - 1) * gap) / n);
    var cards = [];
    var ch_max = 0;
    for (var i = 0; i < n; i++) {
        var c = CardDB_Get(pk.ids[i]);
        array_push(cards, c);
        ch_max = max(ch_max, CardsUi_CardHeight(c, cw, mt));
    }
    var picks = GameState_Get().player_ch.card_picks;
    var title = Loc_T("cards.pick.title", "Choose a card");
    if (picks > 1) title += "  " + Loc_T("cards.pick.left", "({n} picks left)", { n: string(picks) });
    var skip_label = Loc_T("cards.pick.skip", "Skip: +{gold} gold", { gold: string(Card_SkipGold()) });
    var skip_w = UI_TextWidth(skip_label) + 24 * p;
    var skip_h = mt.row_h + 4 * p;
    var hint = Loc_T("cards.pick.hint", "[k:left][k:right] Choose   [k:confirm] Take");
    var total = mt.line_h + 3 * p + ch_max + 3 * p + skip_h + 2 * p + mt.line_h;
    var y0 = max(margin, round((mt.gh - total) / 2));
    var slide = p * round((1 - _a) * 3);
    Ui_Text(mt.gw / 2, y0 - slide, title, UI_C_LIGHTEST, fa_center);
    var cy = y0 + mt.line_h + 3 * p - slide;
    var rects = [];
    for (var k = 0; k < n; k++) {
        var cx = margin + k * (cw + gap);
        CardsUi_DrawCard(cx, cy, cw, ch_max, cards[k], k == pk.cursor, _a);
        array_push(rects, { x: cx, y: cy, w: cw, h: ch_max });
    }
    var sx = round((mt.gw - skip_w) / 2);
    var sy = cy + ch_max + 3 * p;
    var skip_sel = (pk.cursor >= n);
    if (skip_sel) {
        Ui_Box(sx - p, sy - p, sx + skip_w + p, sy + skip_h + p, UI_C_LIGHT);
    }
    Ui_DrawFrame(sx, sy, skip_w, skip_h, _a, p);
    if (skip_sel) Ui_Arrow(sx + 5 * p + Ui_Bob(current_time) * p, sy + (skip_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    Ui_Text(sx + skip_w / 2, sy + (skip_h - mt.line_h) div 2, skip_label, skip_sel ? UI_C_LIGHTEST : UI_C_LIGHT, fa_center);
    array_push(rects, { x: sx, y: sy, w: skip_w, h: skip_h });
    pk.rects = rects;
    Prompt_RichDraw(round(mt.gw * 0.1), sy + skip_h + 2 * p, hint, round(mt.gw * 0.8), UI_C_LIGHT, fa_center, _a);
}

function CardsUi_Draw() {
    if (!CardsUi_IsOpen()) return;
    var u = global.cards_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.8 * a);
    if (u.kind == "cards") CardsUi_DrawPick(u, a);
    else Ui_StackDraw(u.stk, 0.5);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ==========================================================================================================================
// C4: the bed menu (D47), the tutorial pop-up and the Help page (D45), the Controls page of the settings (D49). All on the UI framework
// (Ui_Menu*, Ui_DrawFrame, Prompt_Rich*). The rules live in pure functions elsewhere: Bed_* (scr_levelup), Tutorial_* (scr_dialogue),
// Binds_* / Prompt_* (scr_input).
// ===================================================================================================================
// ---- the bed: Rest / Upgrade a skill / Leave, once per run per bed -----------------------------------------------------------------
// global.bed_ui = { stk, lock, opened_ms, key } while it is open, with gs.ui.mode = UI_BED. Back leaves without using the bed.
function BedUi_IsOpen() {
    return variable_global_exists("bed_ui") && is_struct(global.bed_ui);
}

function BedUi_Close() {
    var gs = GameState_Get();
    global.bed_ui = undefined;
    if (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_BED) gs.ui.mode = UI_NONE;
}

// A room change closes it (the bed stays free).
function BedUi_Interrupt() {
    if (BedUi_IsOpen()) BedUi_Close();
}

// The player used the bed (interact). A bed already used this run says so; a free one opens the menu. Returns true when the menu opened.
function BedUi_Open(_inst) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    var key = Bed_Key(room_get_name(room), _inst.x, _inst.y);
    if (!Bed_CanUse(gs.flags, key)) {
        Dialogue_StartLines([Loc_T("bed.used", "You have rested here already. The bed is still warm.")]);
        return false;
    }
    var u = { stk: Ui_StackNew(), lock: InputLock_New(CARDS_UI_INPUT_DELAY_MS), opened_ms: current_time, key: key };
    Ui_StackPush(u.stk, BedUi_MainMenu());
    global.bed_ui = u;
    gs.ui.mode = UI_BED;
    SFX_PlayUI("ui_openclose");
    Tutorial_Trigger("bed");
    return true;
}

function BedUi_MainMenu() {
    var m = Ui_MenuNew("bed_main", Bed_MenuItems(GameState_Get().player_ch), {
        on_confirm: BedUi_MainConfirm, on_back: BedUi_OnBack,
        layout: { title: Loc_T("bed.title", "Bed"), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

function BedUi_UpgradeMenu() {
    var m = Ui_MenuNew("bed_upgrade", Bed_UpgradeItems(GameState_Get().player_ch), {
        on_confirm: BedUi_UpgradeConfirm, on_back: BedUi_OnBack,
        layout: { title: Loc_T("bed.upgrade_title", "Upgrade which skill?"), anchor: "center", details: true, hides_below: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

// Back on the first menu leaves; Ui_StackBack already took the second menu off.
function BedUi_OnBack(_m, _res) {
    if (_res == "root") BedUi_Close();
}

function BedUi_MainConfirm(_m, _i) {
    var rid = _m.items[_i].id;
    if (rid == "heal") BedUi_Choose("heal", -1);
    else if (rid == "upgrade") Ui_StackPush(global.bed_ui.stk, BedUi_UpgradeMenu());
    else BedUi_Close();
}

function BedUi_UpgradeConfirm(_m, _i) {
    var sid = _m.items[_i].skill_id;
    if (sid < 0) {
        Ui_StackBack(global.bed_ui.stk);
        return;
    }
    BedUi_Choose("upgrade", sid);
}

function BedUi_Choose(_choice, _skill_id) {
    var gs = GameState_Get();
    var r = Bed_Choose(gs.player_ch, gs.flags, global.bed_ui.key, _choice, _skill_id);
    BedUi_Close();
    if (!r.ok) {   // D156: a refused choice (already rested, nothing to upgrade) says so; the bed stays free
        if (r.msg != "") Dialogue_StartLines([r.msg]);
        return;
    }
    CardsUi_Commit(r.ch);
    if (_choice == "heal") Dialogue_StartLines([Loc_T("bed.msg.heal", "You sleep a while. HP and MP are full again.")]);
    else Dialogue_StartLines([Loc_T("bed.msg.upgrade", "{skill} is better now.", { skill: SkillDB_Get(_skill_id).name })]);
}

// Called by obj_ui_controller Step while gs.ui.mode == UI_BED.
function BedUi_Handle() {
    var gs = GameState_Get();
    if (!BedUi_IsOpen()) {
        if (gs.ui.mode == UI_BED) gs.ui.mode = UI_NONE;
        return;
    }
    var u = global.bed_ui;
    if (InputLock_Active(u.lock)) return;
    var top = Ui_StackTop(u.stk);
    if (is_struct(top)) Ui_MenuUpdate(top, u.stk);
}

function BedUi_Draw() {
    if (!BedUi_IsOpen()) return;
    var u = global.bed_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.6 * a);
    Ui_StackDraw(u.stk, 0.5);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the tutorial pop-up --------------------------------------------------------------------------------------------------------------
// global.tutorial_ui = { id, queue, lock, opened_ms } (Tutorial_Trigger, scr_dialogue). It is drawn over everything the ui controller
// draws and, while it is up, nothing else gets input: the controller's Step calls Tutorial_Step first and the battle controller waits.
function Tutorial_Step() {
    if (!Tutorial_IsOpen()) return false;
    var t = global.tutorial_ui;
    if (!InputLock_Active(t.lock)) {
        if (Input_UIConfirm() || Input_UIBack() || mouse_check_button_pressed(mb_left)) {
            SFX_PlayUI("ui_confirm");
            Tutorial_Dismiss();
        }
    }
    return true;
}

// The box of a tutorial entry: { x, y, w, h, iw, body_h } centred on the GUI grid.
function Tutorial_Box(_e, _slide) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = min(mt.gw - 2 * mt.margin, round(mt.gw * 0.8));
    var iw = w - 8 * p;
    var body_h = Ui_TextBlockH(_e.body, iw);
    var h = 8 * p + (mt.line_h + 3 * p) + body_h + 3 * p + mt.line_h;
    return { x: round((mt.gw - w) / 2), y: max(mt.margin, round((mt.gh - h) / 2)) - _slide, w: w, h: h, iw: iw, body_h: body_h };
}

function Tutorial_Draw() {
    if (!Tutorial_IsOpen()) return;
    var t = global.tutorial_ui;
    var e = Tutorial_Get(t.id);
    if (!is_struct(e)) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var a = Ui_AnimT(t.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.55 * a);
    var slide = p * round((1 - a) * 3);
    var b = Tutorial_Box(e, slide);
    Ui_DrawFrame(b.x, b.y, b.w, b.h, a, p);
    draw_set_alpha(a);
    var x0 = b.x + 4 * p;
    var ty = b.y + 4 * p;
    Ui_Text(x0, ty, e.title, UI_C_LIGHTEST);
    Ui_Box(b.x + 3 * p, ty + mt.line_h + p, b.x + b.w - 3 * p, ty + mt.line_h + 2 * p, UI_C_DARK);
    ty += mt.line_h + 3 * p;
    Ui_TextBlock(x0, ty, e.body, b.iw, UI_C_TEXT);
    ty += b.body_h + 3 * p;
    var more = array_length(t.queue);
    Prompt_RichDraw(x0, ty, Tutorial_Footer(), b.iw, UI_C_LIGHTEST, fa_left, a);
    if (more > 0) Ui_Text(x0 + b.iw, ty, Loc_T("tutorial.more", "+{n} more", { n: string(more) }), UI_C_LIGHT, fa_right);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the notice pop-up (D96, D108 F3a) ---------------------------------------------------------------------------------------------------
// One message and Confirm to dismiss it: why Continue failed, why an old save cannot be loaded. global.notice_ui = { text, opened_ms, closed_ms }
// (closed_ms is -1 while it is up). It is laid out and drawn like the tutorial pop-up (frame, text block, prompt footer). Its clock is milliseconds
// only: Confirm and Back are ignored for UI_INPUT_LOCK_MS after it opens (the press that caused it must not close it), it fades in over UI_PANEL_MS
// and fades out over UI_PANEL_MS after a dismissal. gs.ui.mode stays UI_NOTICE for as long as it is up, fade-out included, so the title and the
// world behind it take no key and the dismissing press cannot answer them either. Notice_Update is the whole model; the live Step and the checks
// both go through it.
function Notice_IsOpen() {
    return variable_global_exists("notice_ui") && is_struct(global.notice_ui);
}

function Notice_Closing() {
    return Notice_IsOpen() && global.notice_ui.closed_ms >= 0;
}

function Notice_Text() {
    return Notice_IsOpen() ? global.notice_ui.text : "";
}

function Notice_Footer() {
    return "[k:confirm] " + Loc_T("common.ok", "OK");
}

// Opens the pop-up with _text (a notice that is up is replaced and starts its own lock). _now is the clock, current_time in the game.
function Notice_Open(_text, _now = current_time) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    global.notice_ui = { text: string(_text), opened_ms: _now, closed_ms: -1 };
    gs.ui.mode = UI_NOTICE;
}

// Removes it at once (a room change, a battle) and gives the UI mode back.
function Notice_Interrupt() {
    global.notice_ui = undefined;
    var gs = GameState_Get();
    if (is_struct(gs) && variable_struct_exists(gs, "ui") && is_struct(gs.ui) && gs.ui.mode == UI_NOTICE) gs.ui.mode = UI_NONE;
}

// True while it is up and past the input lock (and not on its way out).
function Notice_CanAnswer(_now = current_time) {
    return Notice_IsOpen() && global.notice_ui.closed_ms < 0 && _now - global.notice_ui.opened_ms >= UI_INPUT_LOCK_MS;
}

// 0..1: in over UI_PANEL_MS after it opens, out over UI_PANEL_MS after it is dismissed (from wherever the fade-in had got to).
function Notice_Alpha(_now = current_time) {
    if (!Notice_IsOpen()) return 0;
    var n = global.notice_ui;
    var a = Ui_AnimT(n.opened_ms, _now);
    if (n.closed_ms >= 0) a = min(a, 1 - Ui_AnimT(n.closed_ms, _now));
    return a;
}

// One step at clock _now. _pressed: Confirm or Back was pressed this step. Returns true while the pop-up is still up.
function Notice_Update(_now = current_time, _pressed = false) {
    if (!Notice_IsOpen()) return false;
    var n = global.notice_ui;
    if (n.closed_ms < 0) {
        if (_pressed && _now - n.opened_ms >= UI_INPUT_LOCK_MS) n.closed_ms = _now;
    } else if (_now - n.closed_ms >= UI_PANEL_MS) {
        Notice_Interrupt();
        return false;
    }
    return true;
}

// The ui controller's Step (and the title's) calls this while Notice_IsOpen: true while it is up.
function Notice_Step() {
    if (!Notice_IsOpen()) return false;
    var was_closing = Notice_Closing();
    var pressed = Notice_CanAnswer() && (Input_UIConfirm() || Input_UIBack());
    var up = Notice_Update(current_time, pressed);
    if (!was_closing && Notice_Closing()) SFX_PlayUI("ui_confirm");
    return up;
}

// The box of a text: { x, y, w, h, iw, body_h } centred on the GUI grid (no title row: the text is the whole message).
function Notice_Box(_text, _slide = 0) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = min(mt.gw - 2 * mt.margin, round(mt.gw * 0.7));
    var iw = w - 8 * p;
    var body_h = Ui_TextBlockH(_text, iw);
    var h = 8 * p + body_h + 3 * p + mt.line_h;
    return { x: round((mt.gw - w) / 2), y: max(mt.margin, round((mt.gh - h) / 2)) - _slide, w: w, h: h, iw: iw, body_h: body_h };
}

// Drawn by the ui controller over everything it draws except the fade (like the tutorial pop-up).
function Notice_Draw() {
    if (!Notice_IsOpen()) return;
    var n = global.notice_ui;
    var mt = Ui_Metrics();
    var p = mt.p;
    var a = Notice_Alpha(current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.55 * a);
    var slide = p * round((1 - a) * 3);
    var b = Notice_Box(n.text, slide);
    Ui_DrawFrame(b.x, b.y, b.w, b.h, a, p);
    draw_set_alpha(a);
    var x0 = b.x + 4 * p;
    var ty = b.y + 4 * p;
    Ui_TextBlock(x0, ty, n.text, b.iw, UI_C_TEXT);
    ty += b.body_h + 3 * p;
    Prompt_RichDraw(x0, ty, Notice_Footer(), b.iw, UI_C_LIGHTEST, fa_center, a);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the Controls page of the settings (D49) ---------------------------------------------------------------------------------------------
// The rows are the rebindable actions; confirming one waits for a key (Esc or right click cancels). A new key is live and saved at once (D140).
function Controls_RowHelp(_id) {
    if (_id == "reset") return Loc_T("controls.help.reset", "Puts every keyboard key back to how it was. The controller is never changed.");
    return Loc_T("controls.help.row", "Confirm, then press the new key. If another action already uses it, the two swap. Esc cancels.");
}

// The page's menu items for a key table. _capture_row is the row waiting for a key ("" = none); _msg_row / _msg replace that row's help.
function Controls_Items(_keys, _capture_row, _msg_row = "", _msg = "") {
    var items = [];
    var ids = Binds_RowIds();
    for (var i = 0; i < array_length(ids); i++) {
        var rid = ids[i];
        var waiting = (rid == _capture_row);
        array_push(items, {
            id: rid, label: Binds_RowLabel(rid), kind: "button", enabled: true, lines: [],
            value: waiting ? Loc_T("controls.press_key", "Press a key...") : Binds_KeysText(variable_struct_get(_keys, rid)),
            help: (rid == _msg_row && _msg != "") ? _msg : Controls_RowHelp(rid)
        });
    }
    array_push(items, {
        id: "reset", label: Loc_T("controls.reset", "Reset to defaults"), kind: "button", enabled: true, lines: [], value: "", help: Controls_RowHelp("reset")
    });
    return items;
}

// A key was pressed for a row: { ok, keys, message }. Pure: the caller stores the keys.
function Controls_Capture(_keys, _row, _key) {
    var r = Binds_Assign(_keys, _row, _key);
    var msg = "";
    if (!r.ok) {
        msg = (r.reason == "reserved") ? Loc_T("controls.reserved", "That key is reserved.") : Loc_T("controls.unusable", "That key cannot be used.");
    } else if (r.swapped != "") {
        msg = Loc_T("controls.swapped", "{other} had that key, so the two swapped.", { other: Binds_RowLabel(r.swapped) });
    } else {
        msg = Loc_T("controls.set", "Key changed.");
    }
    return { ok: r.ok, keys: r.keys, message: msg };
}

// A keyboard press this frame as a bindable code, or -1. Left / right shift and control count as the plain ones.
function Controls_PollKey() {
    if (!keyboard_check_pressed(vk_anykey)) return -1;
    var k = keyboard_lastkey;
    if (k == vk_lshift || k == vk_rshift) k = vk_shift;
    if (k == vk_lcontrol || k == vk_rcontrol) k = vk_control;
    return k;
}

function ControlsPage_Open(_sp) {
    _sp.controls = { menu: undefined, capture: "", msg_row: "", msg: "", lock: undefined };
    var c = _sp.controls;
    c.menu = Ui_MenuNew("controls", Controls_Items(GameSettings_Ensure().keys, ""), {
        on_confirm: ControlsPage_OnConfirm, on_back: ControlsPage_OnBack,
        layout: { title: Loc_T("controls.title", "Controls"), anchor: "center", details: true }
    });
}

function ControlsPage_Refresh(_sp) {
    var c = _sp.controls;
    if (!is_struct(c)) return;
    c.menu.items = Controls_Items(GameSettings_Ensure().keys, c.capture, c.msg_row, c.msg);
}

function ControlsPage_OnConfirm(_m, _i) {
    var sp = GameState_Get().ui.settings_popup;
    var c = sp.controls;
    var rid = _m.items[_i].id;
    if (rid == "reset") {
        Settings_SetKeys(Binds_Defaults());
        c.msg_row = "reset";
        c.msg = Loc_T("controls.reset_done", "Keys are back to the defaults.");
        SettingsPopup_Refresh();
        ControlsPage_Refresh(sp);
        return;
    }
    c.capture = rid;
    c.lock = InputLock_New(CONTROLS_CAPTURE_DELAY_MS);   // the press that chose the row must not be taken as the new key
    c.msg_row = rid;
    c.msg = Loc_T("controls.waiting", "Press the new key for {action}. Esc cancels.", { action: Binds_RowLabel(rid) });
    ControlsPage_Refresh(sp);
}

// Back leaves the Controls page for the settings list.
function ControlsPage_OnBack(_m, _res) {
    var sp = GameState_Get().ui.settings_popup;
    sp.controls = undefined;
    if (is_struct(sp.menu)) sp.menu.lock_ms = current_time;
}

// A key for the row being captured (also the entry point the smoke run uses in place of a real key press).
function ControlsPage_OnKey(_sp, _key) {
    var c = _sp.controls;
    if (!is_struct(c) || c.capture == "") return false;
    if (_key == vk_escape) {
        c.capture = "";
        c.msg = "";
        c.msg_row = "";
        ControlsPage_Refresh(_sp);
        SFX_PlayUI("ui_back");
        return true;
    }
    var r = Controls_Capture(GameSettings_Ensure().keys, c.capture, _key);
    c.msg_row = c.capture;
    c.msg = r.message;
    if (r.ok) {
        Settings_SetKeys(r.keys);
        c.capture = "";
        SFX_PlayUI("ui_confirm");
        SettingsPopup_Refresh();
    } else {
        SFX_PlayUI("ui_back");
    }
    ControlsPage_Refresh(_sp);
    return true;
}

function ControlsPage_Handle(_sp) {
    var c = _sp.controls;
    if (c.capture != "") {
        if (InputLock_Active(c.lock)) return;
        if (mouse_check_button_pressed(mb_right)) { ControlsPage_OnKey(_sp, vk_escape); return; }
        var k = Controls_PollKey();
        if (k >= 0) ControlsPage_OnKey(_sp, k);
        return;
    }
    Ui_MenuUpdate(c.menu);
}

// ==========================================================================================================================
// C3 (D85, D23, D100): the merchant's shop, on the UI framework. global.shop_ui = { stk, shop_index, msg, msg_ms, lock } while it is open,
// with gs.ui.mode = UI_SHOP. Root: Buy / Sell / Leave. Buy and Sell are Ui menus with the details panel: one plain sentence and the numbers,
// generated from the item and card data. A row you cannot pay for stays selectable (dimmed) so you can still read it; Confirm then says why not.
// ==========================================================================================================================
#macro SHOP_UI_INPUT_DELAY_MS (10000 / 60)   // D108 F2b-2: ms, was 10 frames
#macro SHOP_MSG_MS 1800

function ShopUi_IsOpen() {
    return variable_global_exists("shop_ui") && is_struct(global.shop_ui);
}

function ShopUi_Close() {
    var gs = GameState_Get();
    global.shop_ui = undefined;
    if (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_SHOP) gs.ui.mode = UI_NONE;
}

function ShopUi_Interrupt() {
    if (ShopUi_IsOpen()) ShopUi_Close();
}

// The merchant's own lines (merchant.<kind>.<n>, casual and flat): greet on arrival, buy, sell, leave. Each kind rotates through its lines in order.
function Merchant_Count(_kind) {
    return (_kind == "greet") ? 4 : 3;
}

// The next line of this kind (0, 1, 2 ... and round again), so the same one never comes twice in a row.
function Merchant_NextIndex(_kind) {
    if (!variable_global_exists("merchant_rot") || !is_struct(global.merchant_rot)) global.merchant_rot = {};
    var cur = variable_struct_exists(global.merchant_rot, _kind) ? variable_struct_get(global.merchant_rot, _kind) : -1;
    cur = (cur + 1) mod Merchant_Count(_kind);
    variable_struct_set(global.merchant_rot, _kind, cur);
    return cur;
}

// Read at draw time, so the line follows the language.
function Merchant_Line(_kind, _idx) {
    var i = clamp(_idx, 0, Merchant_Count(_kind) - 1);
    switch (_kind) {
        case "greet":
            switch (i) {
                case 0:
                    var later = Choice_AgainLines("merchant");   // D154: once he has been answered, his first greeting remembers it
                    if (array_length(later) > 0) return later[0];
                    return Loc_T("merchant.greet.0", "You came a long way down. Brave. Or lost.");
                case 1: return Loc_T("merchant.greet.1", "Coins keep the dark away. Mostly.");
                case 2: return Loc_T("merchant.greet.2", "Don't ask where I sleep.");
                default: return Loc_T("merchant.greet.3", "Buy something. Please.");
            }
        case "buy":
            switch (i) {
                case 0: return Loc_T("merchant.buy.0", "Good choice. You will need it.");
                case 1: return Loc_T("merchant.buy.1", "It belonged to someone once.");
                default: return Loc_T("merchant.buy.2", "Spend it while you can.");
            }
        case "sell":
            switch (i) {
                case 0: return Loc_T("merchant.sell.0", "I'll take it. No questions.");
                case 1: return Loc_T("merchant.sell.1", "It will find its way to someone else.");
                default: return Loc_T("merchant.sell.2", "Used. Like everything down here.");
            }
    }
    switch (i) {
        case 0: return Loc_T("merchant.leave.0", "Come back. They always do.");
        case 1: return Loc_T("merchant.leave.1", "Mind the dark. It minds you.");
        default: return Loc_T("merchant.leave.2", "I'll be here. I'm always here.");
    }
}

// What the shop says: a message kept as its kind ("bought", "sold" or a refusal reason) and its numbers, so it is read again in the language of the
// moment, and with _quote_kind the merchant's next line of that kind under it.
function ShopUi_MsgText(_ref) {
    switch (_ref.kind) {
        case "bought": return Loc_T("shop.msg.bought", "Bought {name} for {price}.", _ref.params);
        case "sold": return Loc_T("shop.msg.sold", "Sold {name} for {price}.", _ref.params);
    }
    return ShopUi_ReasonText(_ref.kind);
}

function ShopUi_Say(_kind, _params = {}, _quote_kind = "") {
    var u = global.shop_ui;
    u.msg_ref = { kind: _kind, params: _params };
    u.msg = ShopUi_MsgText(u.msg_ref);
    u.msg_ms = current_time;
    u.quote_kind = _quote_kind;
    u.quote_idx = (_quote_kind != "") ? Merchant_NextIndex(_quote_kind) : -1;
}

// The merchant alone, without an information line (arrival).
function ShopUi_Quote(_kind) {
    var u = global.shop_ui;
    u.msg_ref = undefined;
    u.msg = "";
    u.msg_ms = current_time;
    u.quote_kind = _kind;
    u.quote_idx = Merchant_NextIndex(_kind);
}

// One Buy row from a stock row: name, price (or sold out), the sentence and the number lines. can_buy says whether Confirm would work now.
function ShopUi_ItemFor(_row, _ch, _gold) {
    var sold = (_row.qty <= 0);
    var out = { enabled: true, row: _row, can_buy: (!sold && _gold >= _row.price), label: "", value: "", help: "", lines: [] };
    out.dim = !out.can_buy;
    out.value = sold ? Loc_T("shop.sold_out", "Sold out") : string(_row.price);
    if (_row.kind == "card") {
        var c = CardDB_Get(_row.id);
        out.label = Card_Name(c);
        out.help = Card_Sentence(c);
        out.lines = Card_Lines(c);
    } else {
        var it = ItemDB_Get(_row.id);
        out.label = it.name;
        out.help = Item_Sentence(it);
        out.lines = Item_NumberLines(it, _ch);
        out.icon_item = it;
        if (it.type != ITEM_WEAPON && it.type != ITEM_ARMOR && it.type != ITEM_ACCESSORY) array_push(out.lines, { label: Loc_T("shop.lbl.have", "You have"), value: string(Inv_Count(_ch.inventory, it.id)) });
    }
    array_push(out.lines, { label: Loc_T("shop.lbl.in_stock", "In stock"), value: string(max(0, _row.qty)) });
    return out;
}

function ShopUi_BuyItems() {
    var u = global.shop_ui;
    var gs = GameState_Get();
    var run = Run_Get();
    var rows = Shop_RunStock(run, u.shop_index, gs.player_ch);
    var items = [];
    for (var i = 0; i < array_length(rows); i++) array_push(items, ShopUi_ItemFor(rows[i], gs.player_ch, run.gold));
    return items;
}

// What the player can sell: one row per distinct item (not key items). Worn gear is listed but dimmed: sell it after taking it off.
function ShopUi_SellItems() {
    var gs = GameState_Get();
    var ch = gs.player_ch;
    var items = [];
    var seen = {};
    for (var i = 0; i < array_length(ch.inventory); i++) {
        var iid = ch.inventory[i].id;
        if (variable_struct_exists(seen, string(iid))) continue;
        variable_struct_set(seen, string(iid), true);
        var it = ItemDB_Get(iid);
        if (it.id == 0 || it.type == ITEM_KEY) continue;
        var worn = Menu_IsEquipped(ch, iid);
        var n = Inv_Count(ch.inventory, iid);
        var lines = Item_NumberLines(it, ch);
        array_push(lines, { label: Loc_T("shop.lbl.sells_for", "Sells for"), value: string(Shop_SellPrice(iid)) });
        array_push(lines, { label: Loc_T("shop.lbl.have", "You have"), value: string(n) });
        array_push(items, {
            enabled: true, dim: worn, label: it.name + ((n > 1) ? " x" + string(n) : ""), value: worn ? Loc_T("shop.worn", "Worn") : string(Shop_SellPrice(iid)),
            help: Item_Sentence(it), lines: lines, icon_item: it, item_id: iid
        });
    }
    if (array_length(items) <= 0) array_push(items, { enabled: false, label: Loc_T("shop.nothing_to_sell", "Nothing to sell"), value: "", help: "", lines: [], item_id: -1 });
    return items;
}

function ShopUi_Refresh(_m, _which) {
    var keep = _m.cursor;
    _m.items = (_which == "buy") ? ShopUi_BuyItems() : ShopUi_SellItems();
    Ui_MenuFixCursor(_m, min(keep, array_length(_m.items) - 1));
}

function ShopUi_Title(_name) {
    return _name + "  " + Loc_T("shop.gold", "Gold {n}", { n: string(Gold_Get()) });
}

function ShopUi_RootMenu() {
    var items = [
        { label: Loc_T("shop.buy", "Buy"), value: "" },
        { label: Loc_T("shop.sell", "Sell"), value: "" },
        { label: Loc_T("shop.leave", "Leave"), value: "" }
    ];
    var m = Ui_MenuNew("shop_root", items, {
        on_confirm: ShopUi_RootConfirm, on_back: ShopUi_RootBack,
        layout: { title: ShopUi_Title(Loc_T("shop.title", "Merchant")), anchor: "center", center: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

function ShopUi_RootConfirm(_m, _i) {
    var u = global.shop_ui;
    if (_i == 2) {
        ShopUi_Leave();
        return;
    }
    var sell = (_i == 1);
    var m = Ui_MenuNew(sell ? "shop_sell" : "shop_buy", sell ? ShopUi_SellItems() : ShopUi_BuyItems(), {
        on_confirm: sell ? ShopUi_SellConfirm : ShopUi_BuyConfirm, on_back: ShopUi_ListBack,
        layout: { title: ShopUi_Title(sell ? Loc_T("shop.sell", "Sell") : Loc_T("shop.buy", "Buy")), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);
    Ui_StackPush(u.stk, m);
}

function ShopUi_RootBack(_m, _res) {
    ShopUi_Leave();
}

// Leaving: the shop closes and the merchant's parting line stays on screen a moment (it is not a dialogue: nothing waits for it).
function ShopUi_Leave() {
    global.shop_farewell = { idx: Merchant_NextIndex("leave"), ms: current_time };
    ShopUi_Close();
}

function ShopUi_ListBack(_m, _res) {
}

function ShopUi_ReasonText(_reason) {
    switch (_reason) {
        case "gold": return Loc_T("shop.msg.gold", "Not enough gold.");
        case "sold_out": return Loc_T("shop.msg.sold_out", "Sold out.");
        case "full": return Loc_T("shop.msg.full", "You cannot carry more of those.");
        case "owned": return Loc_T("shop.msg.owned", "You already have that.");
        case "slots": return Loc_T("shop.msg.slots", "All your skill slots are full.");
        case "equipped": return Loc_T("shop.msg.equipped", "Take it off first.");
    }
    return Loc_T("shop.msg.cant", "Cannot do that.");
}

function ShopUi_BuyConfirm(_m, _i) {
    var gs = GameState_Get();
    var it = _m.items[_i];
    var r = Shop_Buy(gs.player_ch, Run_Get(), it.row);
    if (!r.ok) {
        SFX_PlayUI("ui_back");
        ShopUi_Say(r.reason);
        return;
    }
    CardsUi_Commit(r.ch);
    ShopUi_Say("bought", { name: it.label, price: string(r.price) }, "buy");
    ShopUi_Refresh(_m, "buy");
}

// D156: gear is sold only after Yes; a worn piece is refused by the sale itself ("Take it off first"), and the rest sells at once.
function ShopUi_SellConfirm(_m, _i) {
    var gs = GameState_Get();
    var it = _m.items[_i];
    if (it.item_id < 0) return;
    var def = ItemDB_Get(it.item_id);
    var gear = (def.type == ITEM_WEAPON || def.type == ITEM_ARMOR || def.type == ITEM_ACCESSORY);
    if (gear && !Menu_IsEquipped(gs.player_ch, it.item_id)) {
        Confirm_Open(Loc_T("confirm.sell", "Sell {name} for {price}?", { name: def.name, price: string(Shop_SellPrice(it.item_id)) }), ShopUi_SellYes, { menu: _m, item_id: it.item_id });
        return;
    }
    ShopUi_SellNow(_m, it.item_id);
}

function ShopUi_SellYes(_d) {
    if (ShopUi_IsOpen()) ShopUi_SellNow(_d.menu, _d.item_id);
}

function ShopUi_SellNow(_m, _item_id) {
    var gs = GameState_Get();
    var r = Shop_Sell(gs.player_ch, Run_Get(), _item_id);
    if (!r.ok) {
        SFX_PlayUI("ui_back");
        ShopUi_Say(r.reason);
        return;
    }
    CardsUi_Commit(r.ch);
    ShopUi_Say("sold", { name: ItemDB_Get(_item_id).name, price: string(r.gold) }, "sell");
    ShopUi_Refresh(_m, "sell");
}

function ShopUi_Open(_shop_index) {
    var gs = GameState_Get();
    if (!is_struct(Run_Get()) || !is_struct(gs.player_ch)) return false;
    Shop_RunStock(Run_Get(), _shop_index, gs.player_ch);   // made now, from the seed, if this is the first visit
    var u = { stk: Ui_StackNew(), shop_index: _shop_index, msg: "", msg_ref: undefined, quote_kind: "", quote_idx: -1, msg_ms: -100000, lock: InputLock_New(SHOP_UI_INPUT_DELAY_MS), opened_ms: current_time };
    global.shop_ui = u;
    Ui_StackPush(u.stk, ShopUi_RootMenu());
    gs.ui.mode = UI_SHOP;
    ShopUi_Quote("greet");
    SFX_PlayUI("ui_openclose");
    Tutorial_Trigger("shop");   // C4 (D45)
    return true;
}

// Called every frame by obj_ui_controller. Returns true while the shop is open (the caller stops there).
function ShopUi_Step() {
    if (!ShopUi_IsOpen()) return false;
    var u = global.shop_ui;
    if (!InputLock_Active(u.lock)) {
        var top = Ui_StackTop(u.stk);
        if (is_struct(top)) {
            Ui_MenuUpdate(top, u.stk);
            if (ShopUi_IsOpen()) {
                for (var i = 0; i < array_length(u.stk.menus); i++) {
                    var mm = u.stk.menus[i];
                    var nm0 = (mm.id == "shop_buy") ? Loc_T("shop.buy", "Buy") : ((mm.id == "shop_sell") ? Loc_T("shop.sell", "Sell") : Loc_T("shop.title", "Merchant"));
                    mm.layout.title = ShopUi_Title(nm0);
                }
            }
        }
    }
    return ShopUi_IsOpen();
}

// A framed plate at the bottom: one or two lines.
function ShopUi_DrawPlate(_line1, _line2, _alpha = 1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var lines = [];
    if (_line1 != "") array_push(lines, _line1);
    if (_line2 != "") array_push(lines, _line2);
    if (array_length(lines) == 0) return;
    var tw = 0;
    for (var i = 0; i < array_length(lines); i++) tw = max(tw, UI_TextWidth(lines[i]));
    tw = min(tw + 8 * p, mt.gw - 2 * mt.margin);
    var th = array_length(lines) * mt.line_h + (array_length(lines) - 1) * p + 6 * p;
    var mx0 = round((mt.gw - tw) / 2);
    var my0 = mt.gh - mt.margin - th;
    Ui_DrawFrame(mx0, my0, tw, th, _alpha, p);
    for (var j = 0; j < array_length(lines); j++) {
        var col = (j == 0 || array_length(lines) == 1) ? UI_C_LIGHTEST : UI_C_LIGHT;   // the information first, the merchant's line under it in the accent colour
        Ui_Text(mx0 + 4 * p, my0 + 3 * p + j * (mt.line_h + p), Ui_FitText(lines[j], tw - 8 * p), col);
    }
}

function ShopUi_Draw() {
    if (!ShopUi_IsOpen()) {   // the merchant's parting line, after the shop has closed
        if (variable_global_exists("shop_farewell") && is_struct(global.shop_farewell)) {
            if (current_time - global.shop_farewell.ms < SHOP_MSG_MS) {
                UI_SetFont();
                ShopUi_DrawPlate(Merchant_Line("leave", global.shop_farewell.idx), "");
                draw_set_alpha(1);
                draw_set_color(c_white);
            } else {
                global.shop_farewell = undefined;
            }
        }
        return;
    }
    var u = global.shop_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.8 * a);
    Ui_StackDraw(u.stk, 0.5);
    // the last thing the shop said, and the merchant's line, at the bottom, for a moment
    if (current_time - u.msg_ms < SHOP_MSG_MS) {
        var info = is_struct(u.msg_ref) ? ShopUi_MsgText(u.msg_ref) : "";   // read now: the language may have changed since it was said
        var quote = (u.quote_kind != "") ? Merchant_Line(u.quote_kind, u.quote_idx) : "";
        ShopUi_DrawPlate(info, quote);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the gold counter (D23): a coin and the number, top left in the world and in battle (under the status icons) ----
function Hud_DrawCoin(_x, _y, _p) {
    Ui_Box(_x + _p, _y, _x + 5 * _p, _y + 6 * _p, UI_C_DARKEST);
    Ui_Box(_x, _y + _p, _x + 6 * _p, _y + 5 * _p, UI_C_DARKEST);
    Ui_Box(_x + _p, _y + _p, _x + 5 * _p, _y + 5 * _p, UI_C_LIGHT);
    Ui_Box(_x + 2 * _p, _y + 2 * _p, _x + 3 * _p, _y + 4 * _p, UI_C_LIGHTEST);
}

function Hud_DrawGold() {
    if (!Run_IsActive()) return;
    var gs = GameState_Get();
    if (room == rm_start || room == rm_cutscene) return;
    if (gs.ui.mode != UI_NONE && gs.ui.mode != UI_DIALOGUE) return;
    if (variable_struct_exists(gs.ui, "cutscene_active") && gs.ui.cutscene_active) return;
    if (room != rm_battle && (room_width < DISPLAY_BASE_W || room_height < DISPLAY_BASE_H)) return;   // a room smaller than the view is centred with black round it (DISP-10): nothing may be drawn there
    var mt = Ui_Metrics();
    var p = mt.p;
    var gold = Gold_Get();
    var gst = Feel_GoldState();
    var txt = string(Feel_GoldStep(gst, gold, MapFx_Now()));   // D138 (G6): the number counts up to the real gold over 400 ms; the real value is already `gold`
    var lift = (gst.to > gst.from) ? Feel_GoldBounce(MapFx_Now() - gst.start, Settings_ShakeOn()) * p : 0;   // 1 px up at the start and as it lands (off with Screen shake off, D49)
    var gx = mt.margin;
    var gy = mt.margin;
    var w = 6 * p + 2 * p + UI_TextWidth(string(gold)) + 6 * p;   // the frame is as wide as the final number, so it does not grow while counting
    var h = mt.line_h + 4 * p;
    var a0 = draw_get_alpha();
    draw_set_alpha(1);
    Ui_DrawFrame(gx, gy, w, h, 1, p);
    Hud_DrawCoin(gx + 3 * p, gy + (h - 6 * p) div 2 - lift, p);
    Ui_Text(gx + 3 * p + 8 * p, gy + 2 * p - lift, txt, UI_C_LIGHTEST);
    draw_set_alpha(a0);
}

// ---- item icons (D94): the strip sprite when the owner has imported it (looked up by name), else a small pixel glyph drawn in code ----
function Item_IconSprite(_item) {
    if (!is_struct(_item)) return { spr: noone, sub: 0 };
    if (variable_struct_exists(_item, "sprite") && _item.sprite != noone && _item.sprite != -1) return { spr: _item.sprite, sub: 0 };
    var sub = variable_struct_exists(_item, "icon_sub") ? _item.icon_sub : 0;
    var spr = -1;
    if (variable_struct_exists(_item, "icon_kind")) spr = Icon_StripSprite(string(_item.icon_kind));
    if (spr == -1 || !sprite_exists(spr)) return { spr: noone, sub: sub };
    return { spr: spr, sub: clamp(sub, 0, max(0, sprite_get_number(spr) - 1)) };
}

// 8 x 8 glyphs: '1' dark, '2' light, '3' lightest.
function Item_GlyphRows(_item) {
    var kind = variable_struct_exists(_item, "icon_kind") ? _item.icon_kind : "";
    var sub = variable_struct_exists(_item, "icon_sub") ? _item.icon_sub : 0;
    if (kind == "throwable") {
        switch (sub) {
            case 0: return [".....33.", "....3.2.", "...1221.", "..122221", ".1222221", ".1233221", ".1222221", "..11111."];   // firebomb: a round bomb with a lit fuse
            case 1: return ["..1111..", ".111111.", "12222221", "12322321", "12222221", "12233221", ".122221.", "..1111.."];   // poison pot
            case 2: return ["...11...", "...33...", "..3223..", "..3223..", ".322223.", ".322223.", "32222223", ".333333."];   // ice flask
            default: return ["..333...", ".3333333", "33333333", "33333333", ".333333.", "..3333..", "........", "........"];   // smoke bomb: a puff
        }
    }
    if (kind == "accessory") {
        if (sub == 0) return ["...33...", "..3223..", ".3....3.", ".3....3.", ".3....3.", ".3....3.", "..3333..", "........"];   // ring
        return [".3....3.", "..3..3..", "...33...", "..3223..", ".322223.", ".322223.", "..3223..", "...33..."];   // charm
    }
    return [];
}

// Draws the icon of an item in a square of _size pixels (GUI units) at (_x, _y).
function Item_DrawIcon(_item, _x, _y, _size, _alpha = 1) {
    var ic = Item_IconSprite(_item);
    if (ic.spr != noone) {
        var sc = _size / max(1, max(sprite_get_width(ic.spr), sprite_get_height(ic.spr)));
        draw_sprite_ext(ic.spr, ic.sub, _x, _y, sc, sc, 0, c_white, _alpha);
        return;
    }
    var rows = Item_GlyphRows(_item);
    if (array_length(rows) <= 0) return;
    var u = max(1, floor(_size / 8));
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    for (var r = 0; r < array_length(rows); r++) {
        for (var c = 1; c <= 8; c++) {
            var ch = string_char_at(rows[r], c);
            if (ch == "." || ch == "") continue;
            var col = (ch == "1") ? UI_C_DARK : ((ch == "2") ? UI_C_LIGHT : UI_C_LIGHTEST);
            Ui_Box(_x + (c - 1) * u, _y + r * u, _x + c * u, _y + (r + 1) * u, col);
        }
    }
    draw_set_alpha(a0);
}

// --------------------
// SETTINGS SCREEN (D0 pilot on the UI framework; opened from the title and as the Settings tab of the one menu)
// --------------------
// D140: every row changes the live settings at once (Settings_Change) and saves; the window mode and scale rows then ask "Keep this?" for 10 s and
// go back by themselves (KeepThis_*). The window rows keep D91's logic
// (Display_WindowedMaxScaleNow decides the largest windowed scale; scale only matters while windowed).
function Settings_TextSpeedMul(_idx) {
    switch (clamp(round(_idx), 0, SETTINGS_TEXT_SPEED_MAX)) {
        case 0: return 0.6;
        case 2: return 1.6;
    }
    return 1;
}

function Settings_ShakeOn() {
    return GameSettings_Ensure().screen_shake != 0;
}

// G8 (D136): the Rumble setting (Rumble_Fire / Rumble_Step in scr_input read it).
function Settings_RumbleOn() {
    return GameSettings_Ensure().rumble != 0;
}

// One change to the pending settings struct by row id. Returns true when something changed. The language row only flips the code;
// the caller applies the preview (Loc_SetLanguage).
function Settings_Adjust(_p, _id, _dir, _scale_max) {
    var d = (_dir < 0) ? -1 : 1;
    switch (_id) {
        case "vol_ui":
        case "vol_sfx":
        case "vol_bgm":
            var field = (_id == "vol_ui") ? "audio_ui" : ((_id == "vol_sfx") ? "audio_sfx" : "audio_bgm");
            var old = variable_struct_get(_p, field);
            var nv = clamp(round((old + d * SETTINGS_VOLUME_STEP) * 100) / 100, 0, 1);
            variable_struct_set(_p, field, nv);
            return nv != old;
        case "text_speed":
            var ts = clamp(_p.text_speed + d, 0, SETTINGS_TEXT_SPEED_MAX);
            var ts_changed = (ts != _p.text_speed);
            _p.text_speed = ts;
            return ts_changed;
        case "shake":
            _p.screen_shake = (_p.screen_shake != 0) ? 0 : 1;
            return true;
        case "rumble":
            _p.rumble = (_p.rumble != 0) ? 0 : 1;
            return true;
        case "qte_assist":
            _p.qte_assist = (_p.qte_assist != 0) ? 0 : 1;
            return true;
        case "window":
            _p.window_mode = (_p.window_mode + ((d > 0) ? 1 : WINDOW_MODE_COUNT - 1)) mod WINDOW_MODE_COUNT;
            return true;
        case "scale":
            if (_p.window_mode != WINDOW_MODE_WINDOWED) return false;
            var sc = clamp(_p.display_scale + d, min(DISPLAY_SCALE_MIN, _scale_max), _scale_max);
            var sc_changed = (sc != _p.display_scale);
            _p.display_scale = sc;
            return sc_changed;
        case "language":
            _p.language = (_p.language == "ko") ? "en" : "ko";
            return true;
    }
    return false;
}

// ---- D140: a change is live at once; the window rows ask "Keep this?" ----
#macro KEEP_THIS_MS 10000   // the countdown of the "Keep this?" prompt

function KeepThis_Active() {
    return variable_global_exists("keep_this") && is_struct(global.keep_this);
}

// A window change was just made: remember what it was before. _now is the clock the countdown runs on (a check passes its own).
function KeepThis_Begin(_prev_mode, _prev_scale, _now = current_time) {
    global.keep_this = { prev_mode: _prev_mode, prev_scale: _prev_scale, start_ms: _now, lock_ms: current_time };
}

function KeepThis_Remaining(_now = current_time) {
    if (!KeepThis_Active()) return 0;
    return clamp(KEEP_THIS_MS - (_now - global.keep_this.start_ms), 0, KEEP_THIS_MS);
}

// Keep: the new window state stays and is saved.
function KeepThis_Confirm() {
    if (!KeepThis_Active()) return false;
    global.keep_this = undefined;
    Save_WriteSettingsConfig(GameSettings_Ensure());
    return true;
}

// Back, or no answer: the window goes back to what it was.
function KeepThis_Revert() {
    if (!KeepThis_Active()) return false;
    var k = global.keep_this;
    global.keep_this = undefined;
    var s = GameSettings_Copy(GameSettings_Ensure());
    s.window_mode = k.prev_mode;
    s.display_scale = k.prev_scale;
    GameSettings_Commit(s, true);
    return true;
}

// True when the time ran out this call and the change was put back.
function KeepThis_Tick(_now = current_time) {
    if (!KeepThis_Active()) return false;
    if (_now - global.keep_this.start_ms < KEEP_THIS_MS) return false;
    KeepThis_Revert();
    return true;
}

// One row change on the live settings. Returns true when something changed. Volume, text, language and the rest are live and saved at once;
// the window rows are live at once and saved when kept.
function Settings_Change(_id, _dir, _scale_max = DISPLAY_SCALE_MAX, _now = current_time) {
    var live = GameSettings_Ensure();
    var s = GameSettings_Copy(live);
    if (!Settings_Adjust(s, _id, _dir, _scale_max)) return false;
    var display = (_id == "window" || _id == "scale");
    if (display) {
        if (!KeepThis_Active()) {
            KeepThis_Begin(live.window_mode, live.display_scale, _now);
        } else {
            global.keep_this.start_ms = _now;
            global.keep_this.lock_ms = current_time;
        }
    }
    GameSettings_Commit(s, !display, display);
    return true;
}

// New keys (the Controls page): live and saved at once.
function Settings_SetKeys(_keys) {
    var s = GameSettings_Copy(GameSettings_Ensure());
    s.keys = _keys;
    GameSettings_Commit(s, true, false);
}

// The "Keep this?" box over the settings page: what happened, the seconds left, the two keys.
function KeepThis_Draw(_a = 1) {
    if (!KeepThis_Active()) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var iw = min(mt.gw - 2 * mt.margin - 8 * p, 130 * p);
    var t1 = Loc_T("settings.keep.title", "Keep this setting?");
    var t2 = Loc_T("settings.keep.body", "It goes back by itself in {n} s.", { n: string(ceil(KeepThis_Remaining() / 1000)) });
    var t3 = Loc_T("settings.keep.hint", "[k:confirm] Keep   [k:back] Revert");
    var l1 = Prompt_RichLayout(t1, iw);
    var l2 = Prompt_RichLayout(t2, iw);
    var l3 = Prompt_RichLayout(t3, iw);
    var bh = 8 * p + l1.h + l2.h + l3.h + 4 * p;
    var bw = iw + 8 * p;
    var bx = round((mt.gw - bw) / 2);
    var by = round((mt.gh - bh) / 2);
    global.keep_this_rect = { x: bx, y: by, w: bw, h: bh };
    Ui_DimBackdrop(0.5 * _a);
    Ui_DrawFrame(bx, by, bw, bh, _a, p);
    var yy = by + 4 * p;
    Prompt_RichDraw(bx + 4 * p, yy, t1, iw, UI_C_LIGHTEST, fa_center, _a);
    yy += l1.h + 2 * p;
    Prompt_RichDraw(bx + 4 * p, yy, t2, iw, UI_C_TEXT, fa_center, _a);
    yy += l2.h + 2 * p;
    Prompt_RichDraw(bx + 4 * p, yy, t3, iw, UI_C_LIGHT, fa_center, _a);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// While the prompt is up the page answers only to it: Confirm keeps, Back (or the menu key, a right click) puts the window back, time does the same.
function KeepThis_Step(_sp) {
    if (KeepThis_Tick()) { SettingsPopup_Refresh(); return; }
    if (current_time - global.keep_this.lock_ms < UI_INPUT_LOCK_MS) return;   // the press that made the change
    if (Input_UIConfirm() || mouse_check_button_pressed(mb_left)) {
        SFX_PlayUI("ui_confirm");
        KeepThis_Confirm();
        SettingsPopup_Refresh();
    } else if (Input_UIBack() || Input_UIPressed("menu") || mouse_check_button_pressed(mb_right)) {
        SFX_PlayUI("ui_back");
        KeepThis_Revert();
        SettingsPopup_Refresh();
    }
}

function Settings_WindowModeText(_mode) {
    if (_mode == WINDOW_MODE_WINDOWED) return Loc_T("settings.value.window_windowed", "Windowed");
    if (_mode == WINDOW_MODE_BORDERLESS) return Loc_T("settings.value.window_borderless", "Borderless");
    return Loc_T("settings.value.window_exclusive", "Exclusive");
}

function Settings_TextSpeedText(_idx) {
    if (_idx <= 0) return Loc_T("settings.value.speed_slow", "Slow");
    if (_idx >= SETTINGS_TEXT_SPEED_MAX) return Loc_T("settings.value.speed_fast", "Fast");
    return Loc_T("settings.value.speed_normal", "Normal");
}

function Settings_Row(_id, _label, _kind, _value, _help) {
    return { id: _id, label: _label, kind: _kind, enabled: true, value: _value, amount: 0, help: _help, lines: [] };
}

function Settings_VolumeRow(_id, _label, _v, _help) {
    var r = Settings_Row(_id, _label, "slider", string(clamp(round(_v * 100), 0, 100)) + "%", _help);
    r.amount = _v;
    return r;
}

// The menu items for a settings struct: labels, values, slider fills, help sentences and number lines (D100: the numbers
// come from the real data, never typed in twice).
function SettingsMenu_Items(_p, _scale_max) {
    var ts = clamp(_p.text_speed, 0, SETTINGS_TEXT_SPEED_MAX);
    var windowed = (_p.window_mode == WINDOW_MODE_WINDOWED);
    var items = [];
    array_push(items, Settings_VolumeRow("vol_ui", Loc_T("settings.row.ui", "UI"), _p.audio_ui,
        Loc_T("settings.help.vol_ui", "How loud menu clicks and other interface sounds are.")));
    array_push(items, Settings_VolumeRow("vol_sfx", Loc_T("settings.row.sfx", "SFX"), _p.audio_sfx,
        Loc_T("settings.help.vol_sfx", "How loud hits, footsteps and other game sounds are.")));
    array_push(items, Settings_VolumeRow("vol_bgm", Loc_T("settings.row.bgm", "BGM"), _p.audio_bgm,
        Loc_T("settings.help.vol_bgm", "How loud the music is.")));

    var r_ts = Settings_Row("text_speed", Loc_T("settings.row.text_speed", "Text speed"), "choice",
        Settings_TextSpeedText(ts), Loc_T("settings.help.text_speed", "How fast dialogue text appears."));
    r_ts.measure = [Settings_TextSpeedText(0), Settings_TextSpeedText(1), Settings_TextSpeedText(2)];
    array_push(r_ts.lines, { label: Loc_T("settings.line.cps", "Chars per sec"), value: string(round(UI_DIALOGUE_CHARS_PER_SEC * Settings_TextSpeedMul(ts))) });
    array_push(items, r_ts);

    var r_sh = Settings_Row("shake", Loc_T("settings.row.shake", "Screen shake"), "choice",
        (_p.screen_shake != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.shake", "Turns the screen shake on hits on or off."));
    r_sh.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_sh);

    var r_rm = Settings_Row("rumble", Loc_T("settings.row.rumble", "Rumble"), "choice",
        (_p.rumble != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.rumble", "Short controller vibration on Perfect hits, BREAK, big hits and defeat."));
    r_rm.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_rm);

    var r_qa = Settings_Row("qte_assist", Loc_T("settings.row.qte_assist", "QTE assist"), "choice",
        (_p.qte_assist != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.qte_assist", "Wider bar zones and more time on arrow skills."));
    r_qa.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_qa);

    var r_wm = Settings_Row("window", Loc_T("settings.row.window_mode", "Window"), "choice", Settings_WindowModeText(_p.window_mode),
        Loc_T("settings.help.window", "Windowed, borderless fullscreen, or exclusive fullscreen."));
    r_wm.measure = [Settings_WindowModeText(WINDOW_MODE_WINDOWED), Settings_WindowModeText(WINDOW_MODE_BORDERLESS), Settings_WindowModeText(WINDOW_MODE_EXCLUSIVE)];
    array_push(r_wm.lines, { label: Loc_T("settings.line.monitor", "Monitor"), value: string(Display_MonitorW()) + " x " + string(Display_MonitorH()) });
    array_push(items, r_wm);

    var r_sc = Settings_Row("scale", Loc_T("settings.row.scale", "Scale"), "choice",
        windowed ? (string(_p.display_scale) + "x") : Loc_T("settings.value.auto", "Auto"),
        Loc_T("settings.help.scale", "How many times the picture is enlarged in a window. Only used when windowed."));
    r_sc.enabled = windowed;
    r_sc.measure = [string(DISPLAY_SCALE_MAX) + "x", Loc_T("settings.value.auto", "Auto")];
    var wsz = Display_WindowSizeForScale(_p.display_scale);
    array_push(r_sc.lines, { label: Loc_T("settings.line.window_size", "Window size"), value: string(wsz.w) + " x " + string(wsz.h) });
    array_push(items, r_sc);

    var r_lg = Settings_Row("language", Loc_T("settings.row.language", "Language"), "choice", Loc_LanguageDisplayName(_p.language),
        Loc_T("settings.help.language", "Language of all text in the game."));
    r_lg.measure = [Loc_LanguageDisplayName("en"), Loc_LanguageDisplayName("ko")];
    array_push(items, r_lg);

    var r_ct = Settings_Row("controls", Loc_T("settings.row.controls", "Controls"), "button", "",
        Loc_T("settings.help.controls", "Change the keyboard keys. The controller stays as it is."));
    array_push(items, r_ct);

    return items;
}

function SettingsPopup_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "settings_popup")) {
        gs.ui.settings_popup = {
            open: false, owner: "", menu: undefined,
            closing: false, closed_ms: -1, scale_max: DISPLAY_SCALE_MAX, controls: undefined
        };
    }
}

function SettingsPopup_IsOpen(_owner = "") {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open) return false;
    if (_owner != "" && string(sp.owner) != string(_owner)) return false;
    return true;
}

// Rebuilds the rows from the live settings (after any change; the cursor stays where it is).
function SettingsPopup_Refresh() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open || !is_struct(sp.menu)) return;
    sp.menu.items = SettingsMenu_Items(GameSettings_Ensure(), sp.scale_max);
}

function SettingsPopup_Open(_owner = "", _quiet = false) {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    sp.open = true;
    sp.owner = string(_owner);
    sp.controls = undefined;
    sp.closing = false;
    sp.closed_ms = -1;
    sp.scale_max = clamp(Display_WindowedMaxScaleNow(), 1, DISPLAY_SCALE_MAX);
    sp.menu = Ui_MenuNew("settings", SettingsMenu_Items(GameSettings_Ensure(), sp.scale_max), {
        on_confirm: SettingsMenu_OnConfirm, on_adjust: SettingsMenu_OnAdjust, on_back: SettingsMenu_OnBack,
        layout: { title: Loc_T("settings.title", "Settings"), anchor: "center", details: true, hides_below: true }
    });
    if (!_quiet) SFX_PlayUI("ui_openclose");
}

function SettingsPopup_Close(_immediate = false) {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open) return;
    if (_immediate) {
        SettingsPopup_CloseFinalize();
        return;
    }
    if (sp.closing) return;
    sp.closing = true;
    sp.closed_ms = current_time;
    if (is_struct(sp.menu)) Ui_MenuClose(sp.menu);
}

function SettingsPopup_CloseFinalize() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (is_struct(sp.menu)) Ui_MemSet(Ui_MemGlobal(), sp.menu.id, sp.menu.cursor);
    sp.open = false;
    sp.owner = "";
    sp.closing = false;
    sp.closed_ms = -1;
    sp.menu = undefined;
    sp.controls = undefined;
}

// Applies one change to the live settings and refreshes the rows; the language row changes every text at once.
function SettingsPopup_Change(_id, _dir) {
    var sp = GameState_Get().ui.settings_popup;
    var changed = Settings_Change(_id, _dir, sp.scale_max);
    if (changed) {
        SettingsPopup_Refresh();
        if (_id == "language") sp.menu.layout.title = Loc_T("settings.title", "Settings");
    }
    return changed;
}

function SettingsMenu_OnAdjust(_m, _i, _dir) {
    return SettingsPopup_Change(_m.items[_i].id, _dir);
}

// Confirm: Controls opens its page; a choice row steps forward (so a toggle flips with the confirm key too).
function SettingsMenu_OnConfirm(_m, _i) {
    var rid = _m.items[_i].id;
    var sp = GameState_Get().ui.settings_popup;
    if (rid == "controls") {
        ControlsPage_Open(sp);
        return;
    }
    if (_m.items[_i].kind == "choice") SettingsPopup_Change(rid, 1);
}

// Back: leave (everything is already saved).
function SettingsMenu_OnBack(_m, _res) {
    var sp = GameState_Get().ui.settings_popup;
    sp.controls = undefined;
    SettingsPopup_Close(false);
}

// One frame of the settings page (the title's popup and the Settings tab): the "Keep this?" prompt first, then the Controls page, then the list.
function SettingsPage_Handle(_sp) {
    if (KeepThis_Active()) {
        KeepThis_Step(_sp);
        return;
    }
    if (is_struct(_sp.controls)) ControlsPage_Handle(_sp);
    else Ui_MenuUpdate(_sp.menu);
}

function SettingsPopup_HandleInput() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open) return;
    if (sp.closing) {
        if (current_time - sp.closed_ms >= UI_PANEL_MS) SettingsPopup_CloseFinalize();
        return;
    }
    SettingsPage_Handle(sp);
}

function SettingsPopup_Draw(_draw_backdrop = true) {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open || !is_struct(sp.menu)) return;
    var a = Ui_MenuAlpha(sp.menu, current_time);
    if (_draw_backdrop) Ui_DimBackdrop(0.6 * a);
    if (is_struct(sp.controls)) Ui_MenuDraw(sp.controls.menu, a);
    else Ui_MenuDraw(sp.menu, a);
    KeepThis_Draw(a);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// --------------------
// TITLE MENU (D0 pilot on the UI framework)
// --------------------
// obj_start_controller keeps `state` ("main" | "settings" | "boot_logo" | "splash" | "cutscene") and holds the menu stack in title_stk: [title].
// Settings is the popup above. New Game starts the run at once on Normal (D35: one difficulty only); over a saved run it asks first (D156).
function Title_MainItems(_can_load) {
    return [
        { id: "new", label: Loc_T("menu.main.option.0", "New Game"), kind: "button", enabled: true },
        { id: "load", label: Loc_T("menu.main.option.continue", "Continue"), kind: "button", enabled: _can_load },   // C1 (D46): Continue run
        { id: "settings", label: Loc_T("menu.main.option.2", "Settings"), kind: "button", enabled: true },
        { id: "exit", label: Loc_T("menu.main.option.3", "Exit Game"), kind: "button", enabled: true }
    ];
}

function Title_Build(_c) {
    _c.title_stk = Ui_StackNew();
    var has_run = RunSave_HasSave();
    var m = Ui_MenuNew("title", Title_MainItems(has_run), {
        owner: _c, on_confirm: Title_OnConfirm,
        layout: { anchor: "bottom", y_frac: 0.62, center: true }
    });
    if (has_run) Ui_MenuFixCursor(m, 1);   // review 1: with a run saved the cursor starts on Continue, not on New Game
    Ui_StackPush(_c.title_stk, m);
    _c.title_refresh = false;
    _c.title_seed = undefined;   // D152: the seed entry screen (a SeedEntry struct while it is open)
    _c.title_card = has_run ? Title_CardLoad() : Title_CardNone();   // D128: read, never applied
}

// Language or save files may have changed since the labels were made.
function Title_Refresh(_c) {
    var m = _c.title_stk.menus[0];
    var has_run = RunSave_HasSave();
    m.items = Title_MainItems(has_run);
    Ui_MenuFixCursor(m, m.cursor);
    _c.title_refresh = false;
    _c.title_card = has_run ? Title_CardLoad() : Title_CardNone();
}

// D35: no difficulty menu. D152: New Game goes on to the seed pick (Random seed first, or Enter seed); the title fades out after that pick (Title_NewGameGo),
// then the run (or the intro cutscene) is requested.
function Title_NewGo(_c, _m) {
    Title_SeedChoiceOpen(_c);
}

function Title_NewYes(_d) {
    Title_NewGo(_d.c, _d.m);
}

// New Game: a saved run is abandoned by it (review 1), so with one saved the shared Yes / No pop-up asks first (D156); otherwise it starts at once.
function Title_NewPress(_c, _m, _has_run) {
    if (_has_run) {
        Confirm_Open(Loc_T("confirm.new_game", "Start a new game? The saved run will be abandoned."), Title_NewYes, { c: _c, m: _m });
        return;
    }
    Title_NewGo(_c, _m);
}

function Title_OnConfirm(_m, _i) {
    var c = _m.owner;
    var rid = _m.items[_i].id;
    switch (rid) {
        case "new":
            Title_NewPress(c, _m, RunSave_HasSave());
            break;
        case "load":   // C1 (D46): Continue run
            var cont = Run_Continue();
            if (!cont.ok) Notice_Open(Run_ContinueFailText(cont.status));
            break;
        case "settings":
            SettingsPopup_Open("title");
            c.state = "settings";
            break;
        case "exit": game_end(); break;
    }
}

// ---- D152: the seed pick after New Game ----
// A small menu above the title: "Random seed" (first and highlighted every time) or "Enter seed" (the number entry below). Either way the title then
// fades out and the run starts (Title_Step -> Run_BeginNewGame); a picked seed waits in global.run_next_seed for Run_StartNew (after the intro cutscene
// of a first run). Back goes back to the title menu.
function Title_SeedChoiceOpen(_c) {
    var m = Ui_MenuNew("seed_choice", [
        { id: "random", label: Loc_T("seed.choice.random", "Random seed"), kind: "button", enabled: true },
        { id: "enter", label: Loc_T("seed.choice.enter", "Enter seed"), kind: "button", enabled: true }
    ], {
        owner: _c, on_confirm: Title_SeedChoiceConfirm,
        layout: { title: Loc_T("seed.choice.title", "Choose a seed"), anchor: "center", center: true }
    });
    Ui_MenuFixCursor(m, 0);   // not the remembered row: Random is the default
    Ui_StackPush(_c.title_stk, m);
}

function Title_SeedChoiceConfirm(_m, _i) {
    var c = _m.owner;
    if (_m.items[_i].id == "enter") {
        c.title_seed = SeedEntry_New();
        c.title_seed_t = current_time;
        c.title_seed_msg = false;
        c.title_seed_rep = { v: Ui_RepeatNew(), h: Ui_RepeatNew() };
        return;
    }
    global.run_next_seed = undefined;
    Title_NewGameGo(c);
}

// The title fades out; Title_Step starts the run when the fade is over.
function Title_NewGameGo(_c) {
    _c.title_exit = { at: current_time + UI_PANEL_MS };
    for (var i = 0; i < array_length(_c.title_stk.menus); i++) Ui_MenuClose(_c.title_stk.menus[i]);
}

function Title_SeedEntryOf(_c) {
    return (variable_instance_exists(_c, "title_seed") && is_struct(_c.title_seed)) ? _c.title_seed : undefined;
}

// The entry screen's keys: digits type at the cursor, Backspace (or Q / pad LB) deletes, up / down change the digit, left / right move; Confirm starts
// (not while the entry is empty or all zeros: a line says why), Back returns to the pick. The press that opened the screen does not answer it.
function Title_SeedEntryStep(_c) {
    var e = _c.title_seed;
    var snap = Ui_ReadInput();
    var now = current_time;
    var changed = false;
    for (var d = 0; d < 10; d++) {
        if (Input_Pressed("seed_d" + string(d))) { SeedEntry_Type(e, d); changed = true; }
    }
    if (Input_Pressed("seed_back") || snap.tab < 0) { SeedEntry_Backspace(e); changed = true; }
    var dv = (snap.up ? 1 : 0) - (snap.down ? 1 : 0);
    if (Ui_RepeatStep(_c.title_seed_rep.v, dv, snap.up_p || snap.down_p, now) > 0) { SeedEntry_Cycle(e, dv); changed = true; }
    var dh = (snap.right ? 1 : 0) - (snap.left ? 1 : 0);
    if (Ui_RepeatStep(_c.title_seed_rep.h, dh, snap.left_p || snap.right_p, now) > 0) {
        var was = e.cur;
        SeedEntry_Move(e, dh);
        if (e.cur != was) changed = true;
    }
    if (changed) {
        _c.title_seed_msg = false;
        SFX_PlayUI("ui_move");
    }
    if (now - _c.title_seed_t < UI_INPUT_LOCK_MS) return;
    if (snap.confirm) {
        if (SeedEntry_CanConfirm(e)) {
            SFX_PlayUI("ui_confirm");
            global.run_next_seed = SeedEntry_Value(e);
            _c.title_seed = undefined;
            Title_NewGameGo(_c);
        } else {
            SFX_PlayUI("ui_back");
            _c.title_seed_msg = true;
        }
    } else if (snap.back || snap.rclick) {
        SFX_PlayUI("ui_back");
        _c.title_seed = undefined;
        Ui_StackTop(_c.title_stk).lock_ms = now;
    }
}

// A small arrow: 5p wide, 3p tall, pointing up (_dir -1) or down (+1); (_x, _y) is its top-left.
function Title_SeedArrow(_x, _y, _dir, _p, _col) {
    for (var i = 0; i < 3; i++) {
        var row = (_dir < 0) ? i : (2 - i);
        Ui_Box(_x + (2 - i) * _p, _y + row * _p, _x + (3 + i) * _p, _y + (row + 1) * _p, _col);
    }
}

// The entry screen: a framed panel with nine digit cells (the cursor's cell lit, an arrow above and below it), a line of help (or why Confirm said no) and
// the keys. Everything is measured from Ui_Metrics, so it fits the 480 x 432 window and larger ones. The rectangles are kept in _c.title_seed_rects for -shots.
function Title_SeedEntryDraw(_c) {
    var e = _c.title_seed;
    var mt = Ui_Metrics();
    var p = mt.p;
    var lh = mt.line_h;
    var a = Ui_AnimT(_c.title_seed_t, current_time);
    var n = SEED_DIGITS_MAX;
    var gap = p;
    var cw = UI_TextWidth("0") + 4 * p;
    var pw = min(mt.gw - 2 * mt.margin, n * cw + (n - 1) * gap + 12 * p);
    cw = min(cw, floor((pw - 12 * p - (n - 1) * gap) / n));
    var row_w = n * cw + (n - 1) * gap;
    var ch = lh + 4 * p;
    var inner_w = pw - 8 * p;
    var info = _c.title_seed_msg ? Loc_T("seed.entry.need", "Enter a seed above zero.") : Loc_T("seed.entry.info", "Up to 9 digits. Same seed, same run.");
    var hints = [Loc_T("seed.entry.hint", "[k:up][k:down] Digit   [k:left][k:right] Move"), Loc_T("seed.entry.hint2", "[k:confirm] Start"), Loc_T("seed.entry.hint3", "[k:back] Back   [k:tab_prev] Delete")];   // one group per row: a key never wraps away from its word
    var info_h = Ui_TextBlockH(info, inner_w);
    var hint_h = 0;
    for (var h = 0; h < array_length(hints); h++) hint_h += Ui_TextBlockH(hints[h], inner_w) + ((h > 0) ? p : 0);
    var ph = 4 * p + (lh + 3 * p) + 5 * p + ch + 5 * p + 3 * p + info_h + 3 * p + hint_h + 4 * p;
    var px = round((mt.gw - pw) / 2);
    var py = max(mt.margin, round((mt.gh - ph) / 2)) - p * round((1 - a) * 3);
    Ui_DimBackdrop(0.6 * a);
    Ui_DrawFrame(px, py, pw, ph, a, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(a);
    var x0 = px + 4 * p;
    var yy = py + 4 * p;
    Ui_Text(x0, yy, Loc_T("seed.entry.title", "Enter seed"), UI_C_LIGHTEST);
    Ui_Box(px + 3 * p, yy + lh + p, px + pw - 3 * p, yy + lh + 2 * p, UI_C_DARK);
    yy += lh + 3 * p + 5 * p;
    var rx = px + round((pw - row_w) / 2);
    var cells = [];
    for (var i = 0; i < n; i++) {
        var cx = rx + i * (cw + gap);
        var on = (i == e.cur);
        Ui_Box(cx, yy, cx + cw, yy + ch, on ? UI_C_LIGHTEST : UI_C_DARK);
        Ui_Box(cx + p, yy + p, cx + cw - p, yy + ch - p, on ? UI_C_DARK : UI_C_DARKEST);
        if (i < array_length(e.digits)) Ui_Text(cx + cw / 2, yy + (ch - lh) div 2, string(e.digits[i]), UI_C_TEXT, fa_center);
        if (on) {
            Title_SeedArrow(cx + (cw - 5 * p) div 2, yy - 4 * p, -1, p, UI_C_LIGHTEST);
            Title_SeedArrow(cx + (cw - 5 * p) div 2, yy + ch + p, 1, p, UI_C_LIGHTEST);
        }
        array_push(cells, { x: cx, y: yy, w: cw, h: ch });
    }
    yy += ch + 5 * p + 3 * p;
    Ui_TextBlock(x0, yy, info, inner_w, _c.title_seed_msg ? UI_C_LIGHTEST : UI_C_LIGHT);
    yy += info_h + 3 * p;
    var hint_y = yy;
    for (var r = 0; r < array_length(hints); r++) {
        Prompt_RichDraw(x0, yy, hints[r], inner_w, UI_C_LIGHT, fa_left, a);
        yy += Ui_TextBlockH(hints[r], inner_w) + p;
    }
    _c.title_seed_rects = { panel: { x: px, y: py, w: pw, h: ph }, cells: cells, hint_y: hint_y, hint_h: hint_h };
    draw_set_alpha(a0);
}

// One Step for the title in states main / settings.
function Title_Step(_c) {
    var gs = GameState_Get();
    if (!is_struct(_c.title_stk)) Title_Build(_c);
    if (!variable_instance_exists(_c, "legacy_notice_checked")) {   // C1 (D16): once per launch, say why old saves are not loaded / that the profile file was not usable
        _c.legacy_notice_checked = true;
        var notice_text = Profile_NoticeText();
        var notice_prof = Profile_Get();
        if (notice_text == "" && Save_LegacyFilesExist() && !notice_prof.legacy_notice_seen) {
            notice_prof.legacy_notice_seen = true;
            Profile_Flush();
            notice_text = Save_LegacyNotice();
        }
        if (notice_text != "") {
            Notice_Open(notice_text);
            return;
        }
    }
    if (is_struct(_c.title_exit)) {
        if (current_time >= _c.title_exit.at) {
            _c.title_exit = undefined;
            Difficulty_SetCurrent(DIFFICULTY_NORMAL);   // D35: the one difficulty
            gs.in_main_menu = false;
            Run_BeginNewGame();   // C1: the intro plays once per profile, later runs start at once
        }
        return;
    }
    if (Confirm_Step()) return;   // D156: New Game over a saved run asks; nothing else on the title answers until it is answered
    if (_c.state == "settings") {
        SettingsPopup_HandleInput();
        if (!SettingsPopup_IsOpen("title")) {
            _c.state = "main";
            _c.title_refresh = true;
        }
        return;
    }
    if (is_struct(Title_SeedEntryOf(_c))) {   // D152: the entry screen is above the seed pick
        Title_SeedEntryStep(_c);
        return;
    }
    if (_c.title_refresh) Title_Refresh(_c);
    Ui_MenuUpdate(Ui_StackTop(_c.title_stk), _c.title_stk);
}

function Title_Draw(_c) {
    if (!is_struct(_c.title_stk) || _c.state == "settings") return;
    if (is_struct(Title_SeedEntryOf(_c))) {   // D152: the entry screen stands alone over the dimmed picture
        Title_SeedEntryDraw(_c);
    } else {
        Ui_StackDraw(_c.title_stk);
        if (Ui_StackDepth(_c.title_stk) <= 1) Title_DrawCard(_c);   // the Continue card makes way for the seed pick
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
    Confirm_Draw();   // D156
}

// --------------------
// TITLE SCREEN (D128): press-any-key splash, living background, Continue card
// --------------------
// The menu itself stays the shared framework's (frame, highlight, cursor, fonts): the owner wants every screen in one style. What is new is
// around it: obj_start_controller.state "splash" (after the logo of a fresh launch: art + a blinking prompt, any key / button / click goes on and the
// menu slides in), the art that breathes and a little dust, and a card with the saved run next to the menu. All code-drawn, four palette colours.
// Everything time-based is a pure function of milliseconds, so it is deterministic and checked by Test_Suite_Title.
#macro TITLE_ART_W 160          // the title picture (sprite main_menu) in art pixels
#macro TITLE_ART_H 144
#macro TITLE_SEAM_Y 116         // art rows above this breathe (the boss ends at row 112); the little hero below (rows 120..139) stands still
#macro TITLE_BREATH_MS 3000     // one breath
#macro TITLE_BREATH_PX 2        // the boss rises and falls by 0..2 art pixels
#macro TITLE_DUST_N 32          // "a few dozen" dots of dust
#macro TITLE_BLINK_MS 1000      // the prompt: on 600 ms, off 400 ms
#macro TITLE_BLINK_ON_MS 600
#macro TITLE_FADE_MS 1200       // the slow fade-in of a launch
#macro TITLE_SPLASH_LOCK_MS 200 // a key this soon after the splash appears is ignored (a press at the end of the logo must not skip it)

// 0..TITLE_BREATH_PX whole art pixels: a sine over 3 s, at rest (0) at t = 0. _calm (screen shake off) holds it still.
function Title_BreathOffset(_now_ms, _calm) {
    if (_calm) return 0;
    var ph = (max(0, _now_ms) mod TITLE_BREATH_MS) / TITLE_BREATH_MS;
    return floor((1 - cos(ph * 2 * pi)) * 0.5 * TITLE_BREATH_PX + 0.5);
}

function Title_DustCount() {
    return TITLE_DUST_N;
}

// Whole art pixels per second the dot rises: 2..8 (slow).
function Title_DustSpeed(_i) {
    return 2 + ((_i * 5 + 3) mod 7);
}

// Dot _i at _now_ms: { x, y, size (1 or 2 art pixels), col (0 dark, 1 light, 2 lightest) } inside the picture, drifting up and wrapping from the
// top to the bottom, with a one-pixel sway. _calm freezes it at t = 0. Integers only, no randomness: the same time gives the same dot.
function Title_DustAt(_i, _now_ms, _calm) {
    var t = _calm ? 0 : max(0, _now_ms);
    var w = TITLE_ART_W - 1;   // one less than the picture, so a 2 px dot at the last position still ends inside it
    var h = TITLE_ART_H - 1;
    var x0 = (_i * 53 + _i * _i * 7 + 11) mod w;
    var y0 = (_i * 29 + _i * _i * 13 + 5) mod h;
    var sw = sin(t / 1400 + _i);
    var sx = (sw > 0.5) ? 1 : ((sw < -0.5) ? -1 : 0);
    var size = (_i mod 4 == 3) ? 2 : 1;
    var dx = (((x0 + sx) mod w) + w) mod w;
    var dy = (((y0 - floor(Title_DustSpeed(_i) * t / 1000)) mod h) + h) mod h;
    return { x: dx, y: dy, size: size, col: _i mod 3 };
}

function Title_BlinkOn(_t_ms) {
    return (max(0, _t_ms) mod TITLE_BLINK_MS) < TITLE_BLINK_ON_MS;
}

// 0..1, easing out: how much of the picture shows _t_ms after the launch.
function Title_FadeIn(_t_ms) {
    var t = clamp(_t_ms / TITLE_FADE_MS, 0, 1);
    return 1 - (1 - t) * (1 - t);
}

function Title_SplashAccepts(_age_ms) {
    return _age_ms >= TITLE_SPLASH_LOCK_MS;
}

// The prompt for the device used last (the glyph system has no "any" key, so it is two sentences).
function Title_SplashPrompt(_device) {
    if (_device == "gamepad") return Loc_T("title.splash.press_button", "Press any button");
    return Loc_T("title.splash.press_key", "Press any key");
}

// Any key, mouse button, pad button or stick, or one of the game's own actions (the scripted runs press by writing those).
function Title_AnyInput() {
    if (Prompt_KeyboardActivity()) return true;
    if (Prompt_PadActivity(Input_GamepadDevice(), 0.6)) return true;
    return Input_UIConfirm() || Input_UIBack() || Input_Pressed("menu_up") || Input_Pressed("menu_down") || Input_Pressed("menu_left") || Input_Pressed("menu_right");
}

// The splash is over: the menu is built (or kept) and slides in from now; its own input lock keeps the ending press from answering it.
function Title_SplashEnd(_c) {
    _c.state = "main";
    if (!is_struct(_c.title_stk)) Title_Build(_c);
    var m = _c.title_stk.menus[0];
    m.opened_ms = current_time;
    m.lock_ms = current_time;
    m.cur_y = -1;
    SFX_PlayUI("ui_confirm");
}

function Title_SplashStep(_c) {
    if (!Title_SplashAccepts(current_time - _c.title_t0)) return;
    if (Title_AnyInput()) Title_SplashEnd(_c);
}

// ---- the Continue card -------------------------------------------------------------------------------------------------------
function Title_CardNone() {
    return { kind: "none", status: "missing", class_name: "", floor: 0, gold: 0, time_ms: -1 };
}

// _load = a RunSave_LoadFrom result { status, run }. "run" (a good save: class, floor, gold, and a play time when the save has one),
// "cant" (an old / newer / damaged file), "none" (no file). Reads only: nothing is applied to the game.
function Title_CardModel(_load) {
    var st = (is_struct(_load) && variable_struct_exists(_load, "status")) ? string(_load.status) : "missing";
    if (st == "missing") return Title_CardNone();
    if (st != "ok" || !is_struct(_load.run)) return { kind: "cant", status: st, class_name: "", floor: 0, gold: 0, time_ms: -1 };
    var r = _load.run;
    var cls = (variable_struct_exists(r, "statData") && is_struct(r.statData) && variable_struct_exists(r.statData, "selected_class")) ? r.statData.selected_class : -1;
    return {
        kind: "run", status: "ok",
        class_name: DB_PlayerClass(cls).name,
        floor: variable_struct_exists(r, "floor") ? floor(Save_ToReal(r.floor, 0)) : 0,
        gold: variable_struct_exists(r, "gold") ? round(Save_ToReal(r.gold, 0)) : 0,
        time_ms: (variable_struct_exists(r, "stats") && is_struct(r.stats) && variable_struct_exists(r.stats, "play_ms")) ? Save_ToReal(r.stats.play_ms, -1) : -1   // the time played is stats.play_ms (D137); a save from before that has none, so no Time row
    };
}

function Title_CardLoad(_path = undefined) {
    return Title_CardModel(RunSave_LoadFrom(_path));
}

function Title_FormatTime(_ms) {
    var s = max(0, floor(_ms / 1000));
    var h = s div 3600;
    var m = (s mod 3600) div 60;
    var sec = s mod 60;
    var mm = (h > 0 && m < 10) ? "0" + string(m) : string(m);
    return ((h > 0) ? string(h) + ":" : "") + mm + ":" + ((sec < 10) ? "0" : "") + string(sec);
}

// { title, rows [{ label, value }] } as the details panel takes them (a sentence and number lines).
function Title_CardText(_model) {
    if (_model.kind == "cant") return { title: Loc_T("title.card.cant", "Can't continue"), rows: [] };
    if (_model.kind != "run") return { title: "", rows: [] };
    var rows = [];
    if (_model.floor > 0) array_push(rows, { label: Loc_T("tab.lbl.floor", "Floor"), value: string(_model.floor) });
    array_push(rows, { label: Loc_T("tab.lbl.gold", "Gold"), value: string(_model.gold) });
    if (_model.time_ms >= 0) array_push(rows, { label: Loc_T("title.card.time", "Time"), value: Title_FormatTime(_model.time_ms) });
    return { title: _model.class_name, rows: rows };
}

// Where the card goes: right of the menu when it fits beside it, else under it, else above it. { x, y }.
function Title_CardPlace(_menu_rect, _gw, _gh, _margin, _cw, _ch) {
    var side_x = _menu_rect.x + _menu_rect.w + _margin;
    if (side_x + _cw <= _gw - _margin) return { x: side_x, y: _menu_rect.y };
    var cx = clamp(_menu_rect.x + (_menu_rect.w - _cw) div 2, _margin, max(_margin, _gw - _margin - _cw));
    var below = _menu_rect.y + _menu_rect.h + _margin;
    if (below + _ch <= _gh - _margin) return { x: cx, y: below };
    return { x: cx, y: max(_margin, _menu_rect.y - _margin - _ch) };
}

// Drawn after the menu, with the menu's own fade and slide. The card is the framework's details panel (same frame, same label / value rows).
function Title_DrawCard(_c) {
    _c.title_card_rect = { x: 0, y: 0, w: 0, h: 0 };
    var cd = _c.title_card;
    if (!is_struct(cd) || cd.kind == "none") return;
    var m = _c.title_stk.menus[0];
    var a = Ui_MenuAlpha(m, current_time);
    if (a <= 0 || m.rect.w <= 0) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var tx = Title_CardText(cd);
    var w = UI_TextWidth(tx.title);
    for (var i = 0; i < array_length(tx.rows); i++) w = max(w, UI_TextWidth(tx.rows[i].label) + 4 * p + UI_TextWidth(tx.rows[i].value));
    w = max(w + 8 * p, 36 * p);
    var h = Ui_DetailsHeight(w, tx.title, tx.rows);
    var pos = Title_CardPlace(m.rect, mt.gw, mt.gh, mt.margin, w, h);
    var slide = p * round((1 - a) * 3);   // slides in with the menu
    _c.title_card_rect = { x: pos.x, y: pos.y - slide, w: w, h: h };
    Ui_DrawDetails(pos.x, pos.y - slide, w, h, tx.title, tx.rows, a);
    draw_set_alpha(1);
}

// ---- the picture ---------------------------------------------------------------------------------------------------------------
// The boss (everything above TITLE_SEAM_Y) rises and falls by whole art pixels, the hero below stands still, the dust drifts over both, and a launch
// fades in from black. Breathing and dust stop with the screen shake setting (the one motion setting there is).
function Title_DrawBackground(_c) {
    var w = Display_GuiW();
    var h = Display_GuiH();
    var spr = _c.title_bg_sprite;
    var now = current_time;
    var calm = !Settings_ShakeOn();
    var sx = w / TITLE_ART_W;
    var sy = h / TITLE_ART_H;
    var a0 = draw_get_alpha();
    draw_set_alpha(1);
    Ui_Box(0, 0, w, h, UI_C_DARKEST);
    var yseam = round(TITLE_SEAM_Y * sy);
    draw_sprite_part_ext(spr, 0, 0, TITLE_SEAM_Y, TITLE_ART_W, TITLE_ART_H - TITLE_SEAM_Y, 0, yseam, sx, sy, c_white, 1);
    draw_sprite_part_ext(spr, 0, 0, 0, TITLE_ART_W, TITLE_SEAM_Y, 0, round(Title_BreathOffset(now, calm) * sy), sx, sy, c_white, 1);
    var cols = [UI_C_DARK, UI_C_LIGHT, UI_C_LIGHTEST];
    for (var i = 0; i < Title_DustCount(); i++) {
        var d = Title_DustAt(i, now, calm);
        var x1 = round(d.x * sx);
        var y1 = round(d.y * sy);
        Ui_Box(x1, y1, round((d.x + d.size) * sx), round((d.y + d.size) * sy), cols[d.col]);
    }
    var fade = Title_FadeIn(now - _c.title_t0);
    if (fade < 1) {
        draw_set_alpha(1 - fade);
        Ui_Box(0, 0, w, h, UI_C_DARKEST);
    }
    draw_set_alpha(a0);
}

// The splash's prompt, under the NO HOPE plate where the picture is empty. Blinks; the rectangle is kept for the checks.
function Title_DrawSplash(_c) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var txt = Title_SplashPrompt(Prompt_Device());
    var tw = UI_TextWidth(txt);
    var cx = mt.gw div 2;
    var ty = round(102 * mt.gh / TITLE_ART_H) - mt.line_h div 2;
    _c.title_prompt_rect = { x: cx - tw div 2, y: ty, w: tw, h: mt.line_h };
    if (Title_FadeIn(current_time - _c.title_t0) < 1 || !Title_BlinkOn(current_time - _c.title_t0)) return;
    Ui_Text(cx + p, ty + p, txt, UI_C_DARKEST, fa_center);   // a one-pixel shadow keeps it readable over the picture
    Ui_Text(cx, ty, txt, UI_C_TEXT, fa_center);
    draw_set_alpha(1);
}

// --------------------
// FOCUS LOSS (R1b, D122, D140): the window loses focus -> the one menu opens (in a fight too, but never over a running bar) and the music is lowered
// --------------------
#macro FOCUS_MUSIC_DUCK 0.25   // the music's share of its normal volume while the window is not in front

// True only when the window is unfocused, we are not on the title, not in a room change, and nothing else owns the screen (ui mode NONE).
function Focus_ShouldPause(_has_focus, _ui_mode, _in_main_menu, _in_battle, _in_transition) {
    if (_has_focus || _in_main_menu || _in_transition) return false;
    return _ui_mode == UI_NONE;
}

// Review 1: the menu opens on the focused -> unfocused EDGE only (the first frame counts as focused). Closing it while the window is still
// in the background must stay closed, not reopen next frame. The loss is remembered (global.focus_pending) until the pause could open
// (a dialogue, a room change or a QTE bar may be in the way) or the window comes back.
function Focus_Edge(_has_focus) {
    var prev = variable_global_exists("focus_prev") ? global.focus_prev : true;
    global.focus_prev = _has_focus;
    return prev && !_has_focus;
}

// Called by the UI controller every Step with window_has_focus(). Coming back does not close the menu: the player closes it.
function Focus_Step(_has_focus) {
    Rumble_FocusStep(_has_focus);   // G8 (D136): no vibration while the window is out of focus
    BGM_SetDuck(_has_focus ? 1 : FOCUS_MUSIC_DUCK);   // the music follows the current state, not the edge
    if (Focus_Edge(_has_focus)) global.focus_pending = true;
    if (_has_focus) global.focus_pending = false;
    if (!variable_global_exists("focus_pending") || !global.focus_pending) return;
    var gs = GameState_Get();
    if (!is_struct(gs) || !variable_struct_exists(gs, "ui")) return;
    if (gs.ui.mode == UI_MENU) { global.focus_pending = false; return; }   // already in the menu (by this loss or by hand)
    var in_battle = (room == rm_battle);
    if (!Focus_ShouldPause(_has_focus, gs.ui.mode, gs.in_main_menu, in_battle, Transition_IsActive())) return;
    if (Tutorial_IsOpen()) return;   // a pop-up owns the keys; the battle waits for it already
    if (in_battle) {
        if (Menu_BattleOpenNow()) { Menu_Open(); global.focus_pending = false; }   // a running bar is never interrupted: the loss stays pending until it is over
    } else if (instance_exists(gs.player_inst) && Player_IsSettled(gs.player_inst)) {
        Menu_Open();
        global.focus_pending = false;
    }
}


// ==========================================================================================================================
// UI FRAMEWORK (D0: D95 menu controls, D96 one shared component, D97 motion, D98 fonts, D100 details panel, D101 name tab)
// One menu = a struct { id, items[], cursor, on_confirm, on_back, on_adjust, layout }. The pure model (cursor, hold-to-scroll,
// stack, remembered cursor, hover, scroll window, motion curves) has no draw or input calls and is tested by Test_Suite_UI.
// The drawing kit sits on the GUI grid (Display_GuiW/H) and uses only the four palette colours (D10). Time is milliseconds
// (current_time), never frames. A screen builds a menu, pushes it on a stack, calls Ui_MenuUpdate in Step and Ui_StackDraw in
// Draw GUI. Screens that exist today: Title_* and SettingsPopup_* below. The rest of D96 moves over one screen at a time.
// ==========================================================================================================================
#macro UI_C_DARKEST $211807      // #071821 (GameMaker colours are BGR)
#macro UI_C_DARK $506830         // #306850
#macro UI_C_LIGHT $6CC086        // #86C06C
#macro UI_C_LIGHTEST $CFF8E0     // #E0F8CF
#macro UI_C_TERM $6CC086        // #86C06C (D149): a game term in a sentence ([t]..[/t]): the palette's bright green, drawn as asked on the white main text
#macro UI_C_ACCENT $47C5E8      // #E8C547 (D149): the one accent ([a]..[/a]): BREAK, Perfect and a newly received item only (the merchant gold of D113)
#macro UI_C_TEXT $FFFFFF         // #FFFFFF (D115): item names and list / name text are white; frames, bars and accents keep the four palette colours
#macro UI_REPEAT_DELAY_MS 300    // D95: hold this long before the list starts to scroll
#macro UI_REPEAT_START_MS 140    // the first repeat gap; each next one is 20 percent shorter ...
#macro UI_REPEAT_MIN_MS 45       // ... down to this
#macro UI_PANEL_MS 120           // D97: panels slide and fade in this long
#macro UI_INPUT_LOCK_MS 60       // C4: a menu ignores confirm and back this long after it opens or becomes the top one again (a key seen on two frames cannot answer two menus)
#macro SETTINGS_TEXT_SPEED_MAX 2

// ---- D108 F2b-2: "keys are ignored for a while after a screen opens", on a ms clock ---------------------------------------------------------------
// The screens used to compare Input_Frame() with the frame they opened in (10 / 12 / 4 / 2 frames). An input lock counts ms instead: it loses one step
// (Presentation_StepMs(delta_time), capped at 50 ms) per game frame that has passed since it was last asked, so a lock nobody asked about for a few frames
// is still the right length, and asking twice in a frame costs nothing. Two guarantees are kept at any frame rate: the frame it was made in and the next
// one (min_frames, 2) always refuse a key, because the press that opened the screen is seen by a controller that steps before the UI controller one frame
// late, so a slow frame can never skip the "not the same press" guard.
#macro INPUT_LOCK_MIN_FRAMES 2
#macro INPUT_LOCK_FLOOR_MS 1000                    // a spent lock keeps counting down to here (the margin InputLock_Settled reads)
#macro HELP_UI_INPUT_DELAY_MS (4000 / 60)          // the Help page ignores keys this long after it opens (4 frames)
#macro CONTROLS_CAPTURE_DELAY_MS (2000 / 60)       // the Controls page ignores keys this long after "press the new key" starts (2 frames)

// { ms (left, below 0 once spent), tick (the frame it last lost a step in), frame0, min_frames }. _frame is for tests; it defaults to the game frame.
function InputLock_New(_ms, _min_frames = INPUT_LOCK_MIN_FRAMES, _frame = undefined) {
    if (is_undefined(_frame)) _frame = Input_Frame();
    return { ms: _ms, tick: _frame, frame0: _frame, min_frames: _min_frames };
}

// The pure step: true while the lock still refuses keys. _frame is the game frame now, _step_ms what one frame adds (Presentation_StepMs).
function InputLock_Tick(_lk, _frame, _step_ms) {
    if (!is_struct(_lk)) return false;
    var _passed = _frame - _lk.tick;
    if (_passed > 0) {
        _lk.tick = _frame;
        _lk.ms = max(-INPUT_LOCK_FLOOR_MS, _lk.ms - _passed * _step_ms);
    }
    return (_frame - _lk.frame0) < _lk.min_frames || _lk.ms > TRANSITION_DONE_SLACK_MS;
}

// The live one: true while the lock refuses keys this frame (a lock that is not there refuses nothing).
function InputLock_Active(_lk) {
    if (!is_struct(_lk)) return false;
    return InputLock_Tick(_lk, Input_Frame(), Presentation_StepMs(delta_time));
}

// The scripted runs press keys only once a screen has settled: its lock is spent by _pad_ms (the old "+ 2 / + 4 frames" margin, in ms).
function InputLock_Settled(_lk, _pad_ms, _frame = undefined, _step_ms = undefined) {
    if (!is_struct(_lk)) return true;
    if (is_undefined(_frame)) _frame = Input_Frame();
    if (is_undefined(_step_ms)) _step_ms = Presentation_StepMs(delta_time);
    if (InputLock_Tick(_lk, _frame, _step_ms)) return false;
    return _lk.ms <= -_pad_ms;
}

// ---- pure model ------------------------------------------------------------------------------------------------------------
// Next enabled index from _cur in direction _dir (+1/-1). _enabled is one bool per item. Wraps (D95) unless _wrap is false.
// Nothing enabled (or no move possible without wrapping): the cursor stays.
function Ui_CursorMove(_cur, _dir, _enabled, _wrap = true) {
    var n = array_length(_enabled);
    if (n <= 0) return 0;
    var cur = clamp(_cur, 0, n - 1);
    if (_dir == 0) return cur;
    var dir = (_dir < 0) ? -1 : 1;
    var idx = cur;
    repeat (n) {
        idx += dir;
        if (idx < 0 || idx >= n) {
            if (!_wrap) return cur;
            idx = (idx + n) mod n;
        }
        if (_enabled[idx]) return idx;
    }
    return cur;
}

function Ui_ItemEnabled(_it) {
    return !variable_struct_exists(_it, "enabled") || _it.enabled;
}

function Ui_ItemsEnabled(_items) {
    var out = array_create(array_length(_items), true);
    for (var i = 0; i < array_length(_items); i++) out[i] = Ui_ItemEnabled(_items[i]);
    return out;
}

// Hold-to-scroll (D95): one step on the press, none for UI_REPEAT_DELAY_MS, then repeats that get shorter. Returns 1 when it fires.
// _dir is -1/0/+1 (what is held), _pressed is a fresh press this frame. Call once per frame per axis.
function Ui_RepeatNew() {
    return { dir: 0, next: 0, interval: UI_REPEAT_START_MS };
}

function Ui_RepeatStep(_st, _dir, _pressed, _now) {
    if (_dir == 0) {
        _st.dir = 0;
        return 0;
    }
    if (_dir != _st.dir || _pressed) {
        _st.dir = _dir;
        _st.next = _now + UI_REPEAT_DELAY_MS;
        _st.interval = UI_REPEAT_START_MS;
        return 1;
    }
    if (_now >= _st.next) {
        _st.interval = max(UI_REPEAT_MIN_MS, _st.interval * 0.8);
        _st.next = _now + _st.interval;
        return 1;
    }
    return 0;
}

// Remembered cursor per menu id (D95).
function Ui_MemNew() {
    return {};
}

function Ui_MemSet(_mem, _id, _idx) {
    variable_struct_set(_mem, string(_id), _idx);
}

function Ui_MemGet(_mem, _id, _count) {
    if (_count <= 0 || !variable_struct_exists(_mem, string(_id))) return 0;
    return clamp(variable_struct_get(_mem, string(_id)), 0, _count - 1);
}

function Ui_MemGlobal() {
    if (!variable_global_exists("ui_mem") || !is_struct(global.ui_mem)) global.ui_mem = Ui_MemNew();
    return global.ui_mem;
}

// Which rectangle {x, y, w, h} holds the point: the top and left edges are inside, the bottom and right edges are not, so stacked
// rows have no gaps and no overlaps. A disabled row (per _enabled) is not hovered. -1 = none.
function Ui_HoverIndex(_rects, _mx, _my, _enabled = undefined) {
    for (var i = 0; i < array_length(_rects); i++) {
        var r = _rects[i];
        if (_mx >= r.x && _mx < r.x + r.w && _my >= r.y && _my < r.y + r.h) {
            if (is_array(_enabled) && i < array_length(_enabled) && !_enabled[i]) return -1;
            return i;
        }
    }
    return -1;
}

// First visible row of a list longer than its panel: keep the cursor inside the window, moving it as little as possible.
function Ui_ScrollTop(_cur, _top, _visible, _count) {
    if (_count <= _visible) return 0;
    var top = clamp(_top, 0, _count - _visible);
    if (_cur < top) top = _cur;
    if (_cur >= top + _visible) top = _cur - _visible + 1;
    return clamp(top, 0, _count - _visible);
}

function Ui_TabStep(_active, _count, _dir) {
    if (_count <= 0) return 0;
    if (_dir == 0) return clamp(_active, 0, _count - 1);
    return (_active + ((_dir < 0) ? -1 : 1) + _count) mod _count;
}

// Motion (D97). Time based. Ui_AnimT: 0..1 over _dur ms, easing out. Ui_Glide: a value that eases toward its target (frame-rate
// independent) and snaps on arrival. Ui_Bob: 0 or _amp whole UI pixels, a gentle two-state bob about every 0.4 s.
function Ui_AnimT(_start, _now, _dur = UI_PANEL_MS) {
    var t = clamp((_now - _start) / max(1, _dur), 0, 1);
    return 1 - (1 - t) * (1 - t);
}

function Ui_Glide(_cur, _target, _dt, _tau = 55) {
    var d = _target - _cur;
    if (abs(d) < 0.5) return _target;
    var v = _cur + d * (1 - exp(-max(0, _dt) / _tau));
    if (abs(_target - v) < 0.5) return _target;
    return v;
}

function Ui_Bob(_now, _amp = 1) {
    return floor(((sin(_now * pi * 2 / 800) + 1) * 0.5) * _amp + 0.5);
}

// The Korean pixel font (D98). Galmuri9 / Galmuri11 are drawn crisp only at whole multiples of their native 9 / 11 px.
// Returns { face (9 or 11), k (multiple), px (face * k) }: the multiple closest to _target_px (window pixels of line height).
function Ui_KoFontChoice(_target_px) {
    var best = undefined;
    var faces = [9, 11];
    for (var i = 0; i < 2; i++) {
        var k = max(1, round(_target_px / faces[i]));
        var px = faces[i] * k;
        var err = abs(px - _target_px);
        if (is_undefined(best) || err < best.err - 0.0001) best = { face: faces[i], k: k, px: px, err: err };
    }
    return best;
}

// ---- input snapshot: everything a menu reads in one frame ---------------------------------------------------------------------
function Ui_SnapNew() {
    return {
        up: false, down: false, left: false, right: false,
        up_p: false, down_p: false, left_p: false, right_p: false,
        confirm: false, back: false, tab: 0,
        wheel: 0, mx: -1, my: -1, mouse_moved: false, click: false, rclick: false
    };
}

// The mouse in GUI units from our own layout (window pixels minus the picture's corner, over the integer UI scale).
function Ui_MousePos() {
    var lay = Display_Layout();
    return { x: (window_mouse_get_x() - lay.gui_x) / lay.ui_scale, y: (window_mouse_get_y() - lay.gui_y) / lay.ui_scale };
}

// From the game's own input actions, so the keyboard, the pad and the bot all drive menus the same way. Confirm / back are
// Input_UIConfirm / Input_UIBack (today Space / Esc and pad A / B: see the report on D95's Z, Enter, X).
function Ui_ReadInput() {
    var s = variable_global_exists("ui_snap") ? global.ui_snap : undefined;   // D108 F1c: one snapshot struct, every field set again each frame (callers only read it within the frame)
    if (!is_struct(s)) {
        s = Ui_SnapNew();
        global.ui_snap = s;
    }
    s.up_p = Input_Pressed("menu_up");
    s.down_p = Input_Pressed("menu_down");
    s.left_p = Input_Pressed("menu_left");
    s.right_p = Input_Pressed("menu_right");
    s.up = s.up_p || Input_Held("menu_up");
    s.down = s.down_p || Input_Held("menu_down");
    s.left = s.left_p || Input_Held("menu_left");
    s.right = s.right_p || Input_Held("menu_right");
    s.confirm = Input_UIConfirm();
    s.back = Input_UIBack();
    s.tab = (Input_Pressed("tab_next") ? 1 : 0) - (Input_Pressed("tab_prev") ? 1 : 0);   // bound by the screens that have tabs
    var lay = Display_Layout();   // the mouse as Ui_MousePos works it out, without its struct
    s.mx = (window_mouse_get_x() - lay.gui_x) / lay.ui_scale;
    s.my = (window_mouse_get_y() - lay.gui_y) / lay.ui_scale;
    if (!variable_global_exists("ui_mouse") || !is_struct(global.ui_mouse)) global.ui_mouse = { x: s.mx, y: s.my };
    s.mouse_moved = (s.mx != global.ui_mouse.x || s.my != global.ui_mouse.y);
    global.ui_mouse.x = s.mx;
    global.ui_mouse.y = s.my;
    s.click = mouse_check_button_pressed(mb_left);
    s.rclick = mouse_check_button_pressed(mb_right);
    s.wheel = mouse_wheel_up() ? 1 : (mouse_wheel_down() ? -1 : 0);
    return s;
}

// ---- menus and the stack ----------------------------------------------------------------------------------------------------
// _opts may set on_confirm(menu, index), on_adjust(menu, index, dir) -> changed, on_back(menu, "pop"|"root"), owner, data and layout
// fields: title, anchor ("center" | "bottom"), y_frac, center (centre the labels), details (D100 panel under the list), hides_below.
// Battle (D99) fields: x_anchor ("center" | "left" | "right"), panel_w (fixed width), y_bottom (the block's bottom edge), max_h (most height it may
// take), details_pos ("below" | "above"), details_cols (number lines side by side), rows_max (most rows shown).
// Item fields besides label / value / help / lines / enabled / kind: icon { cat, frame } (an Icon_Get picture) or { spr, sub }, seq (arrow
// directions drawn in the details panel under the sentence), dim (greyed but still selectable), kind "head" (a section title: light green, never selected).
// Tab menu (D90) fields: y_top (the list's top edge), details_pos "right" (the details panel stands beside the list, det_w wide (0 = the rest of the
// width), from det_top (default: the list's top) and det_h tall (default: as tall as the list)), det_art (the details panel starts with the item's or enemy's picture: item field pic { spr, sub } or icon_item).
// Number lines may carry delta (-1 / 0 / +1): a small arrow shows before the value (a better or worse number).
// After a draw m.rect and m.det_rect hold the panel and details rectangles.
function Ui_MenuNew(_id, _items, _opts) {
    var m = {
        id: _id, items: _items, cursor: 0, top: 0, rects: [],
        rep_v: Ui_RepeatNew(), rep_h: Ui_RepeatNew(),
        on_confirm: undefined, on_back: undefined, on_adjust: undefined,
        owner: noone, data: {}, lock_ms: current_time,
        layout: { title: "", note: "", anchor: "center", y_frac: 0.5, center: false, details: false, hides_below: false,
                  x_anchor: "center", panel_w: 0, y_bottom: -1, max_h: 0, details_pos: "below", details_cols: 1, rows_max: 0,
                  y_top: -1, det_w: 0, det_art: false, det_top: -1, det_h: -1 },
        rect: { x: 0, y: 0, w: 0, h: 0 }, det_rect: { x: 0, y: 0, w: 0, h: 0 },
        opened_ms: current_time, closed_ms: -1, cur_y: -1, last_draw_ms: current_time
    };
    if (is_struct(_opts)) {
        var names = variable_struct_get_names(_opts);
        for (var i = 0; i < array_length(names); i++) {
            if (names[i] == "layout") {
                var lnames = variable_struct_get_names(_opts.layout);
                for (var j = 0; j < array_length(lnames); j++) variable_struct_set(m.layout, lnames[j], variable_struct_get(_opts.layout, lnames[j]));
            } else {
                variable_struct_set(m, names[i], variable_struct_get(_opts, names[i]));
            }
        }
    }
    Ui_MenuFixCursor(m, Ui_MemGet(Ui_MemGlobal(), _id, array_length(_items)));
    return m;
}

// Puts the cursor on _want, or the next enabled item when that one is disabled.
function Ui_MenuFixCursor(_m, _want) {
    var en = Ui_ItemsEnabled(_m.items);
    var n = array_length(en);
    if (n <= 0) { _m.cursor = 0; return; }
    _want = clamp(_want, 0, n - 1);
    _m.cursor = en[_want] ? _want : Ui_CursorMove(_want, 1, en);
}

function Ui_MenuClose(_m) {
    if (_m.closed_ms < 0) _m.closed_ms = current_time;
}

// 0..1 for the panel's slide and fade: in while opening, out once closed.
function Ui_MenuAlpha(_m, _now) {
    if (_m.closed_ms >= 0) return 1 - Ui_AnimT(_m.closed_ms, _now);
    return Ui_AnimT(_m.opened_ms, _now);
}

// One frame of one menu from a snapshot. Moves the cursor and reports what happened; the caller plays sounds and calls back.
// { moved, confirm (an enabled item), back, adjust (-1/0/+1 for left/right), index (cursor after the step) }
function Ui_MenuStep(_m, _snap, _now) {
    var ev = { moved: false, confirm: false, back: false, adjust: 0, index: _m.cursor };
    var en = Ui_ItemsEnabled(_m.items);
    var n = array_length(en);
    if (n > 0) {
        _m.cursor = clamp(_m.cursor, 0, n - 1);
        var dv = (_snap.down ? 1 : 0) - (_snap.up ? 1 : 0);
        if (Ui_RepeatStep(_m.rep_v, dv, _snap.up_p || _snap.down_p, _now) > 0) {
            var c = Ui_CursorMove(_m.cursor, dv, en);
            if (c != _m.cursor) { _m.cursor = c; ev.moved = true; }
        }
        if (_snap.wheel != 0) {
            var cw = Ui_CursorMove(_m.cursor, (_snap.wheel > 0) ? -1 : 1, en, false);   // wheel up = the item above; the ends do not wrap
            if (cw != _m.cursor) { _m.cursor = cw; ev.moved = true; }
        }
        var hover = Ui_HoverIndex(_m.rects, _snap.mx, _snap.my, en);
        if (_snap.mouse_moved && hover >= 0 && hover != _m.cursor) { _m.cursor = hover; ev.moved = true; }
        if (_snap.click && hover >= 0) {
            if (hover != _m.cursor) { _m.cursor = hover; ev.moved = true; }
            ev.confirm = true;
        }
        if (_snap.confirm && en[_m.cursor]) ev.confirm = true;
        var dh = (_snap.right ? 1 : 0) - (_snap.left ? 1 : 0);
        if (Ui_RepeatStep(_m.rep_h, dh, _snap.left_p || _snap.right_p, _now) > 0) ev.adjust = dh;
    }
    if (_snap.back || _snap.rclick) ev.back = true;
    ev.index = _m.cursor;
    return ev;
}

function Ui_StackNew() {
    return { menus: [], leaving: undefined };
}

function Ui_StackPush(_stk, _menu) {
    _menu.opened_ms = current_time;
    _menu.lock_ms = current_time;
    array_push(_stk.menus, _menu);
    return _menu;
}

function Ui_StackDepth(_stk) {
    return array_length(_stk.menus);
}

function Ui_StackTop(_stk) {
    return (array_length(_stk.menus) > 0) ? _stk.menus[array_length(_stk.menus) - 1] : undefined;
}

// Back always goes up ONE level (D95): "pop" when a child was removed, "root" when the root is all that is left.
function Ui_StackBack(_stk) {
    if (array_length(_stk.menus) <= 1) return "root";
    var m = array_pop(_stk.menus);
    Ui_MemSet(Ui_MemGlobal(), m.id, m.cursor);
    m.closed_ms = current_time;
    _stk.leaving = m;
    _stk.menus[array_length(_stk.menus) - 1].lock_ms = current_time;
    return "pop";
}

// Step + sounds + callbacks for the top menu of a stack (or a lone menu when _stk is undefined). Returns the event.
function Ui_MenuUpdate(_m, _stk = undefined) {
    var ev = Ui_MenuStep(_m, Ui_ReadInput(), current_time);
    if (current_time - _m.lock_ms < UI_INPUT_LOCK_MS) {   // the press that opened (or came back to) this menu must not answer it
        ev.confirm = false;
        ev.back = false;
    }
    if (ev.moved) {
        SFX_PlayUI("ui_move");
        Ui_MemSet(Ui_MemGlobal(), _m.id, _m.cursor);
    }
    var it = (array_length(_m.items) > 0) ? _m.items[clamp(_m.cursor, 0, array_length(_m.items) - 1)] : undefined;
    if (ev.adjust != 0 && is_struct(it) && Ui_ItemEnabled(it) && is_callable(_m.on_adjust)) {
        if (_m.on_adjust(_m, _m.cursor, ev.adjust)) SFX_PlayUI("ui_move");
    }
    if (ev.confirm && is_struct(it) && variable_struct_exists(it, "kind") && it.kind == "slider") ev.confirm = false;   // a slider moves with left/right only
    if (ev.confirm) {
        SFX_PlayUI("ui_confirm");
        if (is_callable(_m.on_confirm)) _m.on_confirm(_m, ev.index);
    } else if (ev.back) {
        if (is_struct(_stk)) {
            var res = Ui_StackBack(_stk);
            if (res == "pop" || is_callable(_m.on_back)) SFX_PlayUI("ui_back");
            if (is_callable(_m.on_back)) _m.on_back(_m, res);
        } else {
            SFX_PlayUI("ui_back");
            if (is_callable(_m.on_back)) _m.on_back(_m, "root");
        }
    }
    return ev;
}

// ---- drawing kit (GUI grid, 4 colours) --------------------------------------------------------------------------------------
// One font pixel in GUI units (2 at window scale 3, 3 at scale 4, 4 at scale 5 ...): borders, gaps and arrows are whole multiples of it,
// so every edge lands on whole window pixels at every size.
function Ui_Px() {
    return max(1, round(UI_GetTextScale() * DISPLAY_FONT_PX));
}

// Cached per (layout struct, language); the SAME struct comes back until one changes, so callers must treat it as read-only (none writes to it).
// The font is still set on every call (callers rely on it), from the font the build ended with.
function Ui_Metrics() {
    var _l = Display_Layout();
    var _lang = Loc_GetLanguage();
    var _c = variable_global_exists("ui_mt_cache") ? global.ui_mt_cache : undefined;
    if (is_struct(_c) && _c.layout == _l && _c.lang == _lang) {
        draw_set_font(_c.font);
        return _c.mt;
    }
    var _mt = Ui_MetricsBuild();
    global.ui_mt_cache = { layout: _l, lang: _lang, font: draw_get_font(), mt: _mt };
    return _mt;
}

// The uncached computation of Ui_Metrics (sets the UI font). Counted (Ui_MetricsBuilds) so a check can see how often it runs.
function Ui_MetricsBuild() {
    if (!variable_global_exists("ui_mt_builds")) global.ui_mt_builds = 0;
    global.ui_mt_builds++;
    UI_SetFont();
    var p = Ui_Px();
    var lh = UI_TextHeight("A");
    return { p: p, line_h: lh, row_h: lh + 2 * p, pad: 2 * p, margin: 3 * p, gw: Display_GuiW(), gh: Display_GuiH() };
}

function Ui_MetricsBuilds() {
    return variable_global_exists("ui_mt_builds") ? global.ui_mt_builds : 0;
}

// Filled box, _x2/_y2 exclusive.
function Ui_Box(_x1, _y1, _x2, _y2, _col) {
    if (_x2 <= _x1 || _y2 <= _y1) return;
    draw_set_color(_col);
    draw_rectangle(_x1, _y1, _x2 - 1, _y2 - 1, false);
}

// D115: THE text style, in one place. The palette's pale colour is the "main text" role and is drawn white (readability); every other colour
// (the light green accents and labels, the dark green of a greyed row, the dark text on a light plate) is drawn as asked.
function Ui_TextColor(_col) {
    return (_col == UI_C_LIGHTEST) ? UI_C_TEXT : _col;
}

// The colour of a list row's text: white (selected or not); the light green when it cannot be afforded but may be read; the dark green when it is greyed.
function Ui_RowColor(_sel, _enabled, _dim) {
    if (!_enabled) return UI_C_DARK;
    if (_dim) return UI_C_LIGHT;
    return UI_C_TEXT;
}

function Ui_Text(_x, _y, _txt, _col, _halign = fa_left) {
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_color(Ui_TextColor(_col));
    if (is_string(_txt) && string_pos("[", _txt) > 0) _txt = Markup_Strip(_txt);   // D149: markup never reaches a plain draw as brackets
    UI_DrawText(round(_x), round(_y), _txt);
    draw_set_halign(fa_left);
}

// 3p wide, 5p tall pointing right (+1) or left (-1); (_x, _y) is the top-left.
function Ui_Arrow(_x, _y, _dir, _p, _col) {
    for (var i = 0; i < 3; i++) {
        var cx = (_dir > 0) ? (_x + i * _p) : (_x + (2 - i) * _p);
        Ui_Box(cx, _y + i * _p, cx + _p, _y + (5 - i) * _p, _col);
    }
}

// The frame (D89, D96): a 1p light outline with notched corners, a 1p dark band, a dark-green fill. Border + band = 2p on every side.
function Ui_DrawFrame(_x, _y, _w, _h, _alpha = 1, _p = -1) {
    if (_p < 0) _p = Ui_Px();
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var p = _p;
    Ui_Box(_x + p, _y, _x + _w - p, _y + p, UI_C_LIGHTEST);
    Ui_Box(_x + p, _y + _h - p, _x + _w - p, _y + _h, UI_C_LIGHTEST);
    Ui_Box(_x, _y + p, _x + p, _y + _h - p, UI_C_LIGHTEST);
    Ui_Box(_x + _w - p, _y + p, _x + _w, _y + _h - p, UI_C_LIGHTEST);
    Ui_Box(_x + p, _y + p, _x + _w - p, _y + 2 * p, UI_C_DARK);
    Ui_Box(_x + p, _y + _h - 2 * p, _x + _w - p, _y + _h - p, UI_C_DARK);
    Ui_Box(_x + p, _y + 2 * p, _x + 2 * p, _y + _h - 2 * p, UI_C_DARK);
    Ui_Box(_x + _w - 2 * p, _y + 2 * p, _x + _w - p, _y + _h - 2 * p, UI_C_DARK);
    Ui_Box(_x + 2 * p, _y + 2 * p, _x + _w - 2 * p, _y + _h - 2 * p, UI_C_DARKEST);
    draw_set_alpha(a0);
}

// D101 speaker tab: a small box that sits on the top-left of a dialogue frame and opens into it (no bottom edge). (_x, _y) = the
// frame's top-left; the tab stands above it. Returns its { x, y, w, h }.
function Ui_DrawNameTab(_x, _y, _name, _alpha = 1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = UI_TextWidth(_name) + 2 * (2 * p + p);
    var h = mt.line_h + 2 * p + 2 * p;
    var tx = _x + 2 * p;
    var ty = _y - h + 2 * p;   // the lower 2p overlap the frame's own border and band
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Ui_Box(tx + p, ty, tx + w - p, ty + p, UI_C_LIGHTEST);
    Ui_Box(tx, ty + p, tx + p, ty + h, UI_C_LIGHTEST);
    Ui_Box(tx + w - p, ty + p, tx + w, ty + h, UI_C_LIGHTEST);
    Ui_Box(tx + p, ty + p, tx + w - p, ty + 2 * p, UI_C_DARK);
    Ui_Box(tx + p, ty + 2 * p, tx + 2 * p, ty + h, UI_C_DARK);
    Ui_Box(tx + w - 2 * p, ty + 2 * p, tx + w - p, ty + h, UI_C_DARK);
    Ui_Box(tx + 2 * p, ty + 2 * p, tx + w - 2 * p, ty + h, UI_C_DARKEST);
    draw_set_alpha(_alpha);
    Ui_Text(tx + 3 * p, ty + 2 * p + p, _name, UI_C_LIGHTEST);
    draw_set_alpha(a0);
    return { x: tx, y: ty, w: w, h: h };
}

// An 8 x 8 pixel mask ('.' clear, anything else set) drawn in one colour, _p GUI units per pixel.
function Ui_DrawMask(_x, _y, _rows, _p, _col) {
    for (var r = 0; r < array_length(_rows); r++) {
        var row = _rows[r];
        var c = 1;
        var n = string_length(row);
        while (c <= n) {
            if (string_char_at(row, c) == ".") { c++; continue; }
            var c1 = c;
            while (c1 < n && string_char_at(row, c1 + 1) != ".") c1++;
            Ui_Box(_x + (c - 1) * _p, _y + r * _p, _x + c1 * _p, _y + (r + 1) * _p, _col);
            c = c1 + 1;
        }
    }
}

// Tabs header (Q / E, or the shoulder buttons with a pad), the active tab filled light. Returns its height. The rectangle of each tab is kept in
// global.ui_tabs_rects for the mouse. With _icons (one 8 x 8 mask per tab) only the active tab shows its name and every other tab is its icon, so
// the row fits at every text size; without them every label is drawn (white on the dark ones, D115).
function Ui_DrawTabs(_x, _y, _w, _labels, _active, _alpha = 1, _icons = undefined) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var info_l = Prompt_Info("tab_prev");   // D92: Q / E, or LB / RB with a pad in hand
    var info_r = Prompt_Info("tab_next");
    var th = mt.line_h + 2 * p;
    var n = array_length(_labels);
    var use_icons = is_array(_icons);
    var gl = Prompt_GlyphW(info_l);
    var gr = Prompt_GlyphW(info_r);
    var avail = _w - gl - gr - 4 * p;
    var pad = 2 * p;   // each side of a tab's content
    var widths = array_create(n);
    var total = 0;
    for (var i = 0; i < n; i++) {
        widths[i] = use_icons ? (8 * p + 2 * pad + ((i == _active) ? 2 * p + UI_TextWidth(_labels[i]) : 0)) : (UI_TextWidth(_labels[i]) + 2 * pad);
        total += widths[i] + ((i > 0) ? p : 0);
    }
    if (!use_icons && total > avail) {   // text tabs: thinner padding first, then it is what it is
        pad = p;
        total = 0;
        for (var i2 = 0; i2 < n; i2++) { widths[i2] = UI_TextWidth(_labels[i2]) + 2 * pad; total += widths[i2] + ((i2 > 0) ? p : 0); }
    }
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Prompt_DrawGlyph(_x, _y + (th - Prompt_GlyphH()) div 2, info_l, _alpha);
    var tx = _x + gl + 2 * p + max(0, floor((avail - total) / 2 / p) * p);
    var rects = array_create(n);
    for (var j = 0; j < n; j++) {
        var on = (j == _active);
        Ui_Box(tx, _y, tx + widths[j], _y + th, on ? UI_C_LIGHTEST : UI_C_DARK);
        if (use_icons) {
            Ui_DrawMask(tx + pad, _y + (th - 8 * p) div 2, _icons[j], p, on ? UI_C_DARKEST : UI_C_TEXT);
            if (on) Ui_Text(tx + pad + 10 * p, _y + p, _labels[j], UI_C_DARKEST);
        } else {
            Ui_Text(tx + pad, _y + p, _labels[j], on ? UI_C_DARKEST : UI_C_TEXT);
        }
        rects[j] = { x: tx, y: _y, w: widths[j], h: th };
        tx += widths[j] + p;
    }
    global.ui_tabs_rects = rects;
    Prompt_DrawGlyph(_x + _w - gr, _y + (th - Prompt_GlyphH()) div 2, info_r, _alpha);
    draw_set_alpha(a0);
    return th;
}

// Height of wrapped text _w GUI units wide.
function Ui_TextBlockH(_txt, _w) {
    if (Prompt_HasTokens(_txt)) return Prompt_RichLayout(string(_txt), _w).h;   // a sentence with {confirm}-style prompts (D92)
    var s = max(0.0001, UI_GetFontScale());
    return round(string_height_ext(string(_txt), -1, max(1, round(_w / s))) * s);
}

function Ui_TextBlock(_x, _y, _txt, _w, _col) {
    if (Prompt_HasTokens(_txt)) { Prompt_RichDraw(_x, _y, string(_txt), _w, _col); return; }
    var s = max(0.0001, UI_GetFontScale());
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(Ui_TextColor(_col));
    draw_text_ext_transformed(round(_x), round(_y), string(_txt), -1, max(1, round(_w / s)), s, s, 0);
}

// D100 details panel: one plain sentence, then number lines [{ label, value }] (generated from the real game data by the caller).
// The text of _txt, cut with ".." so it is no wider than _max_w GUI units.
function Ui_FitText(_txt, _max_w) {
    var t = string(_txt);
    if (string_pos("[", t) > 0) t = Markup_Strip(t);   // D149: the width of what is drawn, not of the tags
    if (UI_TextWidth(t) <= _max_w) return t;
    while (string_length(t) > 1 && UI_TextWidth(t + "..") > _max_w) t = string_copy(t, 1, string_length(t) - 1);
    return t + "..";
}

// The picture a menu item brings to a details panel (D90): an enemy portrait { spr, sub } in item.pic, or an item's icon in item.icon_item.
function Ui_ArtKind(_it) {
    if (!is_struct(_it)) return "";
    if (variable_struct_exists(_it, "pic") && is_struct(_it.pic) && sprite_exists(_it.pic.spr)) return "pic";
    if (variable_struct_exists(_it, "icon_item") && is_struct(_it.icon_item)) {
        var ic = Item_IconSprite(_it.icon_item);
        if (ic.spr != noone || array_length(Item_GlyphRows(_it.icon_item)) > 0) return "item";
    }
    return "";
}

// Side of the square picture box, in GUI units (32 font pixels).
function Ui_ArtSize() {
    return 32 * Ui_Px();
}

// Draws the item's picture in a dark box centred on _cx with its top at _y. Returns the height used.
function Ui_DrawArt(_cx, _y, _it, _alpha = 1) {
    var kind = Ui_ArtKind(_it);
    if (kind == "") return 0;
    var p = Ui_Px();
    var side = Ui_ArtSize();
    var bx = round(_cx - side / 2);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Ui_Box(bx, _y, bx + side, _y + side, UI_C_DARK);
    Ui_Box(bx + p, _y + p, bx + side - p, _y + side - p, UI_C_DARKEST);
    if (kind == "pic") {
        var spr = _it.pic.spr;
        var sub = _it.pic.sub;
        if (variable_struct_exists(_it.pic, "anim_ms") && _it.pic.anim_ms > 0) sub = (current_time div _it.pic.anim_ms) mod max(1, sprite_get_number(spr));   // an idle animation: the frames take turns
        var tint = variable_struct_exists(_it.pic, "tint") ? _it.pic.tint : c_white;
        var dim = max(1, max(sprite_get_width(spr), sprite_get_height(spr)));
        var sc = max(1, floor((side - 4 * p) / dim));   // whole multiples only: the pixels stay square
        var dw = sprite_get_width(spr) * sc;
        var dh = sprite_get_height(spr) * sc;
        draw_sprite_ext(spr, sub, bx + round((side - dw) / 2) + sprite_get_xoffset(spr) * sc, _y + round((side - dh) / 2) + sprite_get_yoffset(spr) * sc, sc, sc, 0, tint, _alpha);   // the origin is where the picture is placed
    } else {
        var isz = side - 8 * p;
        Item_DrawIcon(_it.icon_item, bx + round((side - isz) / 2), _y + round((side - isz) / 2), isz, _alpha);
    }
    draw_set_alpha(a0);
    return side;
}

// A small arrow before a number: up when the number gets better, down when it gets worse. 5p wide, 3p tall.
function Ui_DeltaMark(_x, _y, _dir, _p, _col) {
    for (var i = 0; i < 3; i++) {
        var row = (_dir > 0) ? i : (2 - i);
        Ui_Box(_x + (2 - row) * _p, _y + i * _p, _x + (3 + row) * _p, _y + (i + 1) * _p, _col);
    }
}

function Ui_DetailsHeight(_w, _sentence, _lines, _cols = 1, _seq_n = 0, _art = undefined) {
    var mt = Ui_Metrics();
    var inner = _w - 2 * (4 * mt.p);
    var h = 2 * (2 * mt.p + mt.pad) + Ui_TextBlockH(_sentence, inner);
    if (Ui_ArtKind(_art) != "") h += Ui_ArtSize() + 2 * mt.p;
    if (_seq_n > 0) h += 13 * max(1, round(mt.p / 2)) + mt.p;
    if (array_length(_lines) > 0) h += mt.p * 2 + ceil(array_length(_lines) / max(1, _cols)) * (mt.line_h + mt.p);
    return h;
}

function Ui_DrawDetails(_x, _y, _w, _h, _sentence, _lines, _alpha = 1, _cols = 1, _seq = [], _art = undefined) {
    var mt = Ui_Metrics();
    var p = mt.p;
    Ui_DrawFrame(_x, _y, _w, _h, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var x0 = _x + 4 * p;
    var x1 = _x + _w - 4 * p;
    var ty0 = _y + 4 * p;
    if (Ui_ArtKind(_art) != "") ty0 += Ui_DrawArt((x0 + x1) / 2, ty0, _art, _alpha) + 2 * p;
    Ui_TextBlock(x0, ty0, _sentence, x1 - x0, UI_C_LIGHTEST);
    ty0 += Ui_TextBlockH(_sentence, x1 - x0);
    if (array_length(_seq) > 0) {   // the arrows to press (D100), in a dark strip like the card's
        ty0 += p;
        ty0 += CardsUi_DrawArrows(x0, ty0, x1 - x0, _seq, max(1, round(p / 2)));
    }
    if (array_length(_lines) > 0) {
        ty0 += p;
        Ui_Box(x0, ty0, x1, ty0 + p, UI_C_DARK);
        ty0 += p;
        var cols = max(1, _cols);
        var col_w = (x1 - x0 - (cols - 1) * 3 * p) / cols;
        for (var i = 0; i < array_length(_lines); i++) {
            var cx0 = x0 + (i mod cols) * (col_w + 3 * p);
            var vtxt = string(_lines[i].value);
            Ui_Text(cx0, ty0, Ui_FitText(_lines[i].label, col_w - UI_TextWidth(vtxt) - 4 * p), UI_C_LIGHT);   // a long label gives way to the number
            Ui_Text(cx0 + col_w, ty0, _lines[i].value, UI_C_LIGHTEST, fa_right);
            if (variable_struct_exists(_lines[i], "delta") && _lines[i].delta != 0) {
                Ui_DeltaMark(cx0 + col_w - UI_TextWidth(_lines[i].value) - 7 * p, ty0 + (mt.line_h - 3 * p) div 2, _lines[i].delta, p, (_lines[i].delta > 0) ? UI_C_LIGHTEST : UI_C_LIGHT);
            }
            if ((i mod cols) == cols - 1 || i == array_length(_lines) - 1) ty0 += mt.line_h + p;
        }
    }
    draw_set_alpha(a0);
}

// ---- menu measuring (D108 F1c) -----------------------------------------------------------------------------------------------
// What Ui_MenuDraw needs to size a menu: the widest label and value, the icon column, the list panel's width and the details panel's
// height. Measured once and kept on the menu (m.mc); it is measured again only when something it depends on changes:
//   rows (level 1): the m.items array (a new reference), the row count, Ui_Metrics' struct (it changes with the layout and the language), the
//     language, the title, and a signature of every row's label, value, help and its number-line and arrow counts (a row changed in place);
//   sizes (level 2): the width the caller fixes (layout.panel_w), layout.details / details_pos / details_cols, and for a panel above the list
//     the highlighted row.
// Counted (Ui_MenuMeasureBuilds, Ui_MenuDetailsBuilds) so a check can see how often each runs. The result is read-only for callers.
function Ui_MenuMeasureBuilds() {
    return variable_global_exists("ui_mm_builds") ? global.ui_mm_builds : 0;
}

function Ui_MenuDetailsBuilds() {
    return variable_global_exists("ui_md_builds") ? global.ui_md_builds : 0;
}

// Five entries per row: label, value, help (as they are: a missing field is undefined), number-line count, arrow count. This runs every
// frame for every row, so it reads the struct directly and calls nothing of ours.
function Ui_MenuSigBuild(_items, _n) {
    var sig = array_create(_n * 5, 0);
    for (var i = 0; i < _n; i++) {
        var it = _items[i];
        var b = i * 5;
        sig[b] = variable_struct_get(it, "label");
        sig[b + 1] = variable_struct_get(it, "value");
        sig[b + 2] = variable_struct_get(it, "help");
        var nl_ = variable_struct_get(it, "lines");
        sig[b + 3] = is_array(nl_) ? array_length(nl_) : 0;
        var ns_ = variable_struct_get(it, "seq");
        sig[b + 4] = is_array(ns_) ? array_length(ns_) : 0;
    }
    return sig;
}

function Ui_MenuSigSame(_items, _sig, _n) {
    for (var i = 0; i < _n; i++) {
        var it = _items[i];
        var b = i * 5;
        if (variable_struct_get(it, "label") != _sig[b]) return false;
        if (variable_struct_get(it, "value") != _sig[b + 1]) return false;
        if (variable_struct_get(it, "help") != _sig[b + 2]) return false;
        var nl_ = variable_struct_get(it, "lines");
        if ((is_array(nl_) ? array_length(nl_) : 0) != _sig[b + 3]) return false;
        var ns_ = variable_struct_get(it, "seq");
        if ((is_array(ns_) ? array_length(ns_) : 0) != _sig[b + 4]) return false;
    }
    return true;
}

// Level 1: the widths of the rows (uncached).
function Ui_MenuMeasureRows(_m, _mt, _lang) {
    if (!variable_global_exists("ui_mm_builds")) global.ui_mm_builds = 0;
    global.ui_mm_builds++;
    var p = _mt.p;
    var n = array_length(_m.items);
    var bar_w = 14 * p;
    var label_w = 0;
    var val_w = 0;
    var icon_px = 0;
    for (var i = 0; i < n; i++) {
        var it = _m.items[i];
        label_w = max(label_w, UI_TextWidth(it.label) + (variable_struct_exists(it, "icon_item") ? 10 * p : 0));   // C3: a row can carry an item icon
        if (variable_struct_exists(it, "icon") && is_struct(it.icon)) icon_px = 16 * max(1, floor(_mt.row_h / 16));
        var kind = variable_struct_exists(it, "kind") ? it.kind : "button";
        var vw = 0;
        if (kind == "slider") {
            vw = bar_w + 2 * p + UI_TextWidth("100%");
        } else if (variable_struct_exists(it, "value") && it.value != "") {
            var texts = variable_struct_exists(it, "measure") ? it.measure : [it.value];
            for (var t = 0; t < array_length(texts); t++) vw = max(vw, UI_TextWidth(texts[t]));
            if (kind == "choice") vw += 10 * p;
        }
        val_w = max(val_w, vw);
    }
    var title = _m.layout.title;
    var note = _m.layout.note;
    return {
        items: _m.items, n: n, mt: _mt, lang: _lang, title: title, note: note, sig: Ui_MenuSigBuild(_m.items, n),
        label_w: label_w, val_w: val_w, icon_px: icon_px, title_w: (title != "") ? UI_TextWidth(title) : 0, note_w: (note != "") ? UI_TextWidth(note) : 0,
        l2: false, l2_pw: 0, l2_details: false, l2_pos: "", l2_cols: 0, l2_cur: -1,
        panel_w: 0, det_h: 0
    };
}

// Level 2: the list panel's width and the details panel's height from the measured rows (uncached).
function Ui_MenuMeasureSizes(_m, _mt, _mc, _cur) {
    if (!variable_global_exists("ui_md_builds")) global.ui_md_builds = 0;
    global.ui_md_builds++;
    var p = _mt.p;
    var L = _m.layout;
    var n = _mc.n;
    var icon_col = (_mc.icon_px > 0) ? _mc.icon_px + 2 * p : 0;
    var inner_w = max(5 * p + icon_col + _mc.label_w + ((_mc.val_w > 0) ? 4 * p + _mc.val_w : 0), _mc.title_w, _mc.note_w);
    var chrome_x = 2 * (4 * p);
    var panel_w = min(inner_w + chrome_x, _mt.gw - 2 * _mt.margin);
    if (L.details && L.panel_w <= 0) panel_w = min(max(panel_w, round(_mt.gw * 0.78)), _mt.gw - 2 * _mt.margin);
    if (L.panel_w > 0) panel_w = min(L.panel_w, _mt.gw - 2 * _mt.margin);
    // the details panel's height is the tallest sentence, so the list does not jump between items
    var det_h = 0;
    if (L.details && L.details_pos == "right") {   // D90: beside the list, as tall as the list (the Tab menu)
        det_h = 0;
    } else if (L.details && L.details_pos == "above" && n > 0) {   // a panel above the list (battle) is as tall as the highlighted item needs: it grows upward
        var dc = _m.items[_cur];
        if (variable_struct_exists(dc, "help")) det_h = Ui_DetailsHeight(panel_w, dc.help, variable_struct_exists(dc, "lines") ? dc.lines : [], L.details_cols, variable_struct_exists(dc, "seq") ? array_length(dc.seq) : 0);
    } else if (L.details) {
        for (var d = 0; d < n; d++) {
            var di = _m.items[d];
            if (variable_struct_exists(di, "help")) det_h = max(det_h, Ui_DetailsHeight(panel_w, di.help, variable_struct_exists(di, "lines") ? di.lines : [], L.details_cols, variable_struct_exists(di, "seq") ? array_length(di.seq) : 0));
        }
    }
    _mc.panel_w = panel_w;
    _mc.det_h = det_h;
}

// The measured struct of a menu (fields label_w, val_w, icon_px, title_w, panel_w, det_h), rebuilt only when its keys changed.
function Ui_MenuMeasure(_m, _mt) {
    var L = _m.layout;
    var n = array_length(_m.items);
    var lang = Loc_GetLanguage();
    var mc = variable_struct_get(_m, "mc");
    var fresh = is_struct(mc) && mc.items == _m.items && mc.n == n && mc.mt == _mt && mc.lang == lang && mc.title == L.title && mc.note == L.note && Ui_MenuSigSame(_m.items, mc.sig, n);
    if (!fresh) {
        mc = Ui_MenuMeasureRows(_m, _mt, lang);
        _m.mc = mc;
    }
    var cur = (L.details && L.details_pos == "above" && n > 0) ? clamp(_m.cursor, 0, n - 1) : -1;
    var fresh2 = mc.l2 && mc.l2_pw == L.panel_w && mc.l2_details == L.details && mc.l2_pos == L.details_pos && mc.l2_cols == L.details_cols && mc.l2_cur == cur;
    if (!fresh2) {
        Ui_MenuMeasureSizes(_m, _mt, mc, cur);
        mc.l2 = true;
        mc.l2_pw = L.panel_w;
        mc.l2_details = L.details;
        mc.l2_pos = L.details_pos;
        mc.l2_cols = L.details_cols;
        mc.l2_cur = cur;
    }
    return mc;
}

// Draws one menu: frame, optional title, rows (label left, value / slider right), the gliding highlight with a bobbing marker, and
// the details panel of the highlighted item when layout.details is set. _alpha 0..1 fades and slides the panel (D97).
// Stores each row's rectangle in m.rects for the mouse. Needs UI_SetFont-compatible state; sets and restores the draw state.
function Ui_MenuDraw(_m, _alpha = 1) {
    if (_alpha <= 0) return;
    if (TabNote_IsReader(_m)) { TabNote_ReaderDraw(_m, _alpha); return; }   // D147: the note reader is a text panel, not a list
    var mt = Ui_Metrics();
    var p = mt.p;
    var L = _m.layout;
    var n = array_length(_m.items);
    var now = current_time;
    var a0 = draw_get_alpha();
    var c0 = draw_get_color();
    var bar_w = 14 * p;

    // widths and the details panel's height: measured once per change (Ui_MenuMeasure), not every frame
    var mm = Ui_MenuMeasure(_m, mt);
    var icon_px = mm.icon_px;     // the icon column (battle lists): one icon pixel is k GUI units, k = whole units that fit a row
    var panel_w = mm.panel_w;
    var header_h = (L.title != "") ? (mt.line_h + 3 * p) : 0;
    var note_h = (L.note != "") ? (mt.line_h + 2 * p) : 0;   // D143: one line under the title (the level-up screen's class growth)
    var chrome_y = 2 * (4 * p) + header_h + note_h;
    var det_h = mm.det_h;         // the tallest sentence (so the list does not jump between items); the highlighted item's own when the panel is above
    var det_right = (L.details && L.details_pos == "right");   // D90: beside the list, as tall as the list (the Tab menu)
    var avail_h = ((L.max_h > 0) ? L.max_h : (mt.gh - 2 * mt.margin)) - ((det_h > 0) ? det_h + mt.margin : 0);
    var rows_vis = clamp(floor((avail_h - chrome_y) / mt.row_h), 1, max(1, n));
    if (det_right) rows_vis = max(1, floor((avail_h - chrome_y) / mt.row_h));   // the panel keeps its size whatever the row count
    if (L.rows_max > 0) rows_vis = min(rows_vis, L.rows_max);
    var panel_h = det_right ? avail_h : (chrome_y + rows_vis * mt.row_h);
    var total_h = panel_h + ((det_h > 0) ? mt.margin + det_h : 0);
    var px = round((mt.gw - panel_w) / 2);
    if (L.x_anchor == "right") px = mt.gw - mt.margin - panel_w;
    else if (L.x_anchor == "left") px = mt.margin;
    var py;
    if (L.y_top >= 0) py = L.y_top;
    else if (L.y_bottom >= 0) py = max(mt.margin, round(L.y_bottom - total_h));
    else if (L.anchor == "bottom") py = clamp(round(mt.gh * L.y_frac), mt.margin, max(mt.margin, mt.gh - mt.margin - total_h));
    else py = max(mt.margin, round((mt.gh - total_h) / 2));
    var slide = p * round((1 - _alpha) * 3);   // slides down into place in three pixel steps
    py += -slide;
    var det_above = (det_h > 0 && L.details_pos == "above");
    var list_y = det_above ? (py + det_h + mt.margin) : py;     // the list panel's top; the details panel is above or below it
    var det_y = det_above ? py : (py + panel_h + mt.margin);
    _m.rect = { x: px, y: list_y, w: panel_w, h: panel_h };
    _m.det_rect = (det_h > 0) ? { x: px, y: det_y, w: panel_w, h: det_h } : { x: 0, y: 0, w: 0, h: 0 };
    if (det_right) {
        var dx = px + panel_w + mt.margin;
        _m.det_rect = { x: dx, y: ((L.det_top >= 0) ? L.det_top - slide : list_y), w: (L.det_w > 0) ? L.det_w : max(0, mt.gw - mt.margin - dx), h: (L.det_h >= 0) ? L.det_h : panel_h };
    }

    _m.top = Ui_ScrollTop(_m.cursor, _m.top, rows_vis, n);
    Ui_DrawFrame(px, list_y, panel_w, panel_h, _alpha, p);
    draw_set_alpha(_alpha);

    var x0 = px + 4 * p;
    var x1 = px + panel_w - 4 * p;
    var ty0 = list_y + 4 * p;
    if (L.title != "") {
        Ui_Text(x0, ty0, L.title, UI_C_LIGHTEST);
        Ui_Box(px + 3 * p, ty0 + mt.line_h + p, px + panel_w - 3 * p, ty0 + mt.line_h + 2 * p, UI_C_DARK);
        ty0 += header_h;
    }
    if (L.note != "") {
        Ui_Text(x0, ty0, Ui_FitText(L.note, x1 - x0), UI_C_LIGHT);
        ty0 += note_h;
    }
    var rows_y0 = ty0;

    // rectangles for the mouse (rows outside the window can't be hit)
    var rects = array_create(n);
    for (var r = 0; r < n; r++) {
        var vis = (r >= _m.top && r < _m.top + rows_vis);
        rects[r] = { x: px + 2 * p, y: rows_y0 + (r - _m.top) * mt.row_h, w: vis ? (panel_w - 4 * p) : 0, h: vis ? mt.row_h : 0 };
    }
    _m.rects = rects;

    // gliding highlight band
    var target_y = rows_y0 + (_m.cursor - _m.top) * mt.row_h;
    if (_m.cur_y < 0) _m.cur_y = target_y;
    _m.cur_y = Ui_Glide(_m.cur_y, target_y, now - _m.last_draw_ms);
    _m.last_draw_ms = now;
    var band_y = round(_m.cur_y);
    if (n > 0) Ui_Box(px + 2 * p + p, band_y, px + panel_w - 2 * p - p, band_y + mt.row_h, UI_C_DARK);

    for (var k = _m.top; k < min(n, _m.top + rows_vis); k++) {
        var row = _m.items[k];
        var ry = rows_y0 + (k - _m.top) * mt.row_h;
        var ty = ry + (mt.row_h - mt.line_h) div 2;
        var sel = (k == _m.cursor);
        var en = Ui_ItemEnabled(row);
        var kd = variable_struct_exists(row, "kind") ? row.kind : "button";
        var dim = variable_struct_exists(row, "dim") && row.dim;   // looks unavailable but can be selected (a shop row you cannot pay for, a skill you lack the MP for)
        var col = (kd == "head") ? UI_C_LIGHT : Ui_RowColor(sel, en, dim);   // D115: names are white, selected or not
        var label_x = x0 + 5 * p;
        if (icon_px > 0) {   // { cat, frame }: an Icon_Get picture (skills, statuses)
            if (variable_struct_exists(row, "icon") && is_struct(row.icon)) {
                var ic = Icon_Get(row.icon.cat, row.icon.frame);
                if (is_struct(ic)) draw_sprite_ext(ic.spr, ic.sub, label_x, ry + (mt.row_h - icon_px) div 2, icon_px / 16, icon_px / 16, 0, c_white, (dim && !sel) ? _alpha * 0.55 : _alpha);
            }
            label_x += icon_px + 2 * p;
        }
        if (variable_struct_exists(row, "icon_item")) {   // C3: an item's picture
            Item_DrawIcon(row.icon_item, label_x, ry + (mt.row_h - 8 * p) div 2, 8 * p, dim ? 0.6 : 1);
            label_x += 10 * p;
        }
        var shown_label = row.label;
        if (!L.center) {   // a fixed-width panel (battle): a long name gives way to ".." before it reaches the value
            var vroom = x1 - label_x - ((variable_struct_exists(row, "value") && row.value != "") ? UI_TextWidth(row.value) + 3 * p : 0);
            shown_label = Ui_FitText(row.label, vroom);
        }
        if (L.center) Ui_Text((x0 + x1) / 2, ty, row.label, col, fa_center);
        else Ui_Text(label_x, ty, shown_label, col);
        var vx = x1;
        if (kd == "choice" && variable_struct_exists(row, "value")) {
            if (sel && en) {
                Ui_Arrow(x1 - 3 * p, ry + (mt.row_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
            }
            vx = x1 - 5 * p;
            Ui_Text(vx, ty, row.value, col, fa_right);
            if (sel && en) {
                Ui_Arrow(vx - UI_TextWidth(row.value) - 5 * p, ry + (mt.row_h - 5 * p) div 2, -1, p, UI_C_LIGHTEST);
            }
        } else if (kd == "slider") {
            Ui_Text(x1, ty, row.value, col, fa_right);
            var bx = x1 - UI_TextWidth("100%") - 2 * p - bar_w;
            var by = ry + (mt.row_h - 2 * p) div 2;
            Ui_Box(bx, by, bx + bar_w, by + 2 * p, sel ? UI_C_DARKEST : UI_C_DARK);
            var fill = floor(clamp(row.amount, 0, 1) * (bar_w / p) + 0.5) * p;
            Ui_Box(bx, by, bx + fill, by + 2 * p, sel ? UI_C_LIGHTEST : UI_C_LIGHT);
        } else if (variable_struct_exists(row, "value") && row.value != "") {
            Ui_Text(x1, ty, row.value, col, fa_right);
        }
    }
    // marker: follows the glide, bobs one pixel
    if (n > 0) {
        Ui_Arrow(x0 + Ui_Bob(now) * p, band_y + (mt.row_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    }
    // a scroll hint when the list is longer than its window
    if (n > rows_vis) {
        if (_m.top > 0) Ui_Box(px + panel_w - 4 * p, rows_y0 - p, px + panel_w - 3 * p, rows_y0, UI_C_LIGHT);
        if (_m.top + rows_vis < n) Ui_Box(px + panel_w - 4 * p, rows_y0 + rows_vis * mt.row_h, px + panel_w - 3 * p, rows_y0 + rows_vis * mt.row_h + p, UI_C_LIGHT);
    }

    if (det_h > 0 && n > 0) {
        var cur = _m.items[_m.cursor];
        if (variable_struct_exists(cur, "help")) {
            Ui_DrawDetails(px, det_y, panel_w, det_h, cur.help, variable_struct_exists(cur, "lines") ? cur.lines : [], _alpha, L.details_cols, variable_struct_exists(cur, "seq") ? cur.seq : []);
        }
    }
    if (det_right && n > 0 && _m.det_rect.w > 0) {
        var rc = _m.items[clamp(_m.cursor, 0, n - 1)];
        if (variable_struct_exists(rc, "help")) {
            var dr = _m.det_rect;
            Ui_DrawDetails(dr.x, dr.y, dr.w, dr.h, rc.help, variable_struct_exists(rc, "lines") ? rc.lines : [], _alpha, L.details_cols, variable_struct_exists(rc, "seq") ? rc.seq : [], L.det_art ? rc : undefined);
        }
    }
    draw_set_alpha(a0);
    draw_set_color(c0);
}

// Draws a stack bottom to top from the last menu that hides what is below it, plus a menu that is on its way out. Each menu above
// the first dims what is under it. Menus alpha-fade with Ui_MenuAlpha.
function Ui_StackDraw(_stk, _dim_alpha = 0.6) {
    var n = array_length(_stk.menus);
    var from = 0;
    for (var i = 0; i < n; i++) if (_stk.menus[i].layout.hides_below) from = i;
    var now = current_time;
    if (is_struct(_stk.leaving) && Ui_MenuAlpha(_stk.leaving, now) <= 0) _stk.leaving = undefined;
    var gw = Display_GuiW();
    var gh = Display_GuiH();
    for (var j = from; j < n; j++) {
        var m = _stk.menus[j];
        var a = Ui_MenuAlpha(m, now);
        if (j > from) Ui_DimBackdrop(_dim_alpha * a);
        Ui_MenuDraw(m, a);
    }
    if (is_struct(_stk.leaving)) {
        var lv = _stk.leaving;
        var la = Ui_MenuAlpha(lv, now);
        if (n > 0) Ui_DimBackdrop(_dim_alpha * la);
        Ui_MenuDraw(lv, la);
    }
}

function Ui_DimBackdrop(_a) {
    if (_a <= 0) return;
    var a0 = draw_get_alpha();
    draw_set_alpha(_a);
    Ui_Box(0, 0, Display_GuiW(), Display_GuiH(), UI_C_DARKEST);
    draw_set_alpha(a0);
}

// ==========================================================================================================================
// THE ONE YES / NO POP-UP (D156). Every important action asks through this one pop-up: Abandon run, Quit to title, New Game over a saved run,
// picking a class, keeping an echo, swapping a skill, selling gear. Confirm_Open(question, on_yes, data) shows the question in the shared frame, centred
// on the GUI grid, with Yes and No under it and the cursor on No. No, Back (Esc, the pad's B, a right click) close it and run nothing; Yes closes it
// and then runs on_yes(data) exactly once. It answers to the same keys, pad and mouse as every menu and takes all input while it is up.
// global.confirm_ui = { question, on_yes, data, menu, opened_ms } while it is open; the screen under it keeps its own state until the answer.
// Whoever steps a screen calls Confirm_Step first and stops when it returns true (obj_ui_controller Step, Title_Step); whoever draws a screen draws
// Confirm_Draw last (Menu_Draw, Title_Draw, obj_ui_controller Draw GUI). UI_InterruptCloseAll closes it.
// ==========================================================================================================================
function Confirm_IsOpen() {
    return variable_global_exists("confirm_ui") && is_struct(global.confirm_ui);
}

function Confirm_Menu() {
    return Confirm_IsOpen() ? global.confirm_ui.menu : undefined;
}

function Confirm_Question() {
    return Confirm_IsOpen() ? global.confirm_ui.question : "";
}

function Confirm_YesAction() {
    return Confirm_IsOpen() ? global.confirm_ui.on_yes : undefined;
}

function Confirm_Data() {
    return Confirm_IsOpen() ? global.confirm_ui.data : undefined;
}

// Opens the pop-up (one that is already up is replaced and its Yes can no longer run). on_yes is called with data once, after the pop-up is gone.
function Confirm_Open(_question, _on_yes, _data = undefined) {
    var m = Ui_MenuNew("confirm", [
        { label: Loc_T("menu.common.yes", "Yes"), yes: true },
        { label: Loc_T("menu.common.no", "No"), yes: false }
    ], { layout: { title: "", anchor: "center", center: true } });
    Ui_MenuFixCursor(m, 1);   // No first, for safety (the remembered cursor of an earlier pop-up does not count); Ui_MenuNew set lock_ms: the press that opened it cannot answer it
    global.confirm_ui = { question: string(_question), on_yes: _on_yes, data: _data, menu: m, opened_ms: current_time };
    SFX_PlayUI("ui_openclose");
    return true;
}

// Drops the pop-up without an answer (a room change, a test). Runs nothing.
function Confirm_Close() {
    global.confirm_ui = undefined;
}

// The answer: closes the pop-up, then runs the Yes action if Yes was meant. Returns true when it ran it.
function Confirm_Resolve(_yes) {
    if (!Confirm_IsOpen()) return false;
    var c = global.confirm_ui;
    global.confirm_ui = undefined;
    global.confirm_last_frame = Input_Frame();   // the screen under it must not see this frame's press
    if (_yes && is_callable(c.on_yes)) {
        c.on_yes(c.data);
        return true;
    }
    return false;
}

// Confirm on the row under the cursor: Yes runs the action, No closes it. Returns true when the action ran.
function Confirm_Choose() {
    if (!Confirm_IsOpen()) return false;
    var m = global.confirm_ui.menu;
    return Confirm_Resolve(m.items[clamp(m.cursor, 0, array_length(m.items) - 1)].yes);
}

// Back is No.
function Confirm_Back() {
    Confirm_Resolve(false);
}

// One frame. Returns true while the pop-up owns the input: it is open, or it was answered earlier in this very frame (so the same press
// cannot reach the screen under it, whichever controller steps first). The live keys are read once per frame however often it is called.
// _snap and _now are injectable for a check (a given snapshot is always stepped).
function Confirm_Step(_snap = undefined, _now = current_time) {
    if (!Confirm_IsOpen()) return variable_global_exists("confirm_last_frame") && global.confirm_last_frame == Input_Frame();
    var m = global.confirm_ui.menu;
    if (is_undefined(_snap)) {   // the live path: two controllers may both call this in one frame (the title room has two); the keys count once
        var frame = Input_Frame();
        if (variable_global_exists("confirm_step_frame") && global.confirm_step_frame == frame) return true;
        global.confirm_step_frame = frame;
        _snap = Ui_ReadInput();
    }
    var ev = Ui_MenuStep(m, _snap, _now);
    if (ev.moved) SFX_PlayUI("ui_move");
    if (_now - m.lock_ms >= UI_INPUT_LOCK_MS) {   // the press that opened it (or that came back to it) must not answer it
        if (ev.confirm) {
            SFX_PlayUI("ui_confirm");
            Confirm_Choose();
        } else if (ev.back) {
            SFX_PlayUI("ui_back");
            Confirm_Back();
        }
    }
    return true;
}

// The pop-up in the shared frame, centred: the question (wrapped to the box), a rule, Yes and No with the gliding band and the marker. Drawn over
// everything the screen under it draws. global.confirm_rect = the box (for the pictures).
function Confirm_Draw(_a = 1) {
    if (!Confirm_IsOpen()) return;
    var c = global.confirm_ui;
    var m = c.menu;
    var mt = Ui_Metrics();
    var p = mt.p;
    var now = current_time;
    var a = Ui_AnimT(c.opened_ms, now) * _a;
    var w = min(mt.gw - 2 * mt.margin, max(round(mt.gw * 0.6), 80 * p));
    var iw = w - 8 * p;
    var qh = Ui_TextBlockH(c.question, iw);
    var h = 11 * p + qh + 2 * mt.row_h;   // 4p above, the question, 3p with the rule, two rows, 4p below
    var bx = round((mt.gw - w) / 2);
    var by = max(mt.margin, round((mt.gh - h) / 2));
    var slide = p * round((1 - a) * 3);   // slides down into place in three pixel steps, like the other panels
    global.confirm_rect = { x: bx, y: by, w: w, h: h };
    var y0 = by - slide;
    var x0 = bx + 4 * p;
    var x1 = bx + w - 4 * p;
    var rows_y0 = y0 + 4 * p + qh + 3 * p;
    var n = array_length(m.items);
    var rects = array_create(n);
    for (var r = 0; r < n; r++) rects[r] = { x: bx + 2 * p, y: by + 4 * p + qh + 3 * p + r * mt.row_h, w: w - 4 * p, h: mt.row_h };
    m.rects = rects;
    draw_set_alpha(1);
    Ui_DimBackdrop(0.55 * a);
    Ui_DrawFrame(bx, y0, w, h, a, p);
    draw_set_alpha(a);
    Ui_TextBlock(x0, y0 + 4 * p, c.question, iw, UI_C_TEXT);
    Ui_Box(bx + 3 * p, y0 + 4 * p + qh + p, bx + w - 3 * p, y0 + 4 * p + qh + 2 * p, UI_C_DARK);
    var target_y = rows_y0 + m.cursor * mt.row_h;
    if (m.cur_y < 0) m.cur_y = target_y;
    m.cur_y = Ui_Glide(m.cur_y, target_y, now - m.last_draw_ms);
    m.last_draw_ms = now;
    var band_y = round(m.cur_y);
    Ui_Box(bx + 3 * p, band_y, bx + w - 3 * p, band_y + mt.row_h, UI_C_DARK);
    for (var k = 0; k < n; k++) {
        var ty = rows_y0 + k * mt.row_h + (mt.row_h - mt.line_h) div 2;
        Ui_Text((x0 + x1) / 2, ty, m.items[k].label, UI_C_TEXT, fa_center);
    }
    Ui_Arrow(x0 + Ui_Bob(now) * p, band_y + (mt.row_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
