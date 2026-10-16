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

// ---- Status: ATK DEF SPD MAG VIG MND with what each does, then the statuses on the character ----
function Stat_Sentence(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return Loc_T("menu.tooltip.stat.atk.desc", "Increases physical damage (basic attacks and ATK skills).");
        case STAT_DEF: return Loc_T("menu.tooltip.stat.def.desc", "Reduces all damage you take.");
        case STAT_SPD: return Loc_T("menu.tooltip.stat.spd.desc", "Decides who acts first.");
        case STAT_MAG: return Loc_T("menu.tooltip.stat.mag.desc", "Increases spell damage.");
        case STAT_VIG: return Loc_T("menu.tooltip.stat.vig.desc", "Raises max HP. The more you add, the less each point gives.");   // D176
        case STAT_MND: return Loc_T("menu.tooltip.stat.mnd.desc", "Raises max MP. The more you add, the less each point gives.");
    }
    return Loc_T("menu.tooltip.stat.default.desc", "Affects battle performance.");
}

function TabStatus_Items(_ch) {
    var items = [];
    var sids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG, STAT_VIG, STAT_MND];
    for (var i = 0; i < array_length(sids); i++) {
        var sid = sids[i];
        var base = variable_struct_get(_ch.stats, Stat_Key(sid));
        var lines = [{ label: Loc_T("tab.lbl.base", "Base"), value: string(base) }];
        if (sid == STAT_VIG || sid == STAT_MND) {   // D176: no gear or effect touches them: the line that matters is what they make
            array_push(lines, (sid == STAT_VIG) ? { label: Loc_T("tab.lbl.max_hp", "Max HP"), value: string(_ch.max_hp) } : { label: Loc_T("tab.lbl.max_mp", "Max MP"), value: string(_ch.max_mp) });
        } else {
            var gear = Equip_GetStatBonus(_ch, sid);
            var fx = Status_ModStat(_ch, sid);
            if (gear != 0) array_push(lines, { label: Loc_T("tab.lbl.gear", "Gear"), value: TabMenu_Signed(gear) });
            if (fx != 0) array_push(lines, { label: Loc_T("tab.lbl.effects", "Effects"), value: TabMenu_Signed(fx) });
            array_push(lines, { label: Loc_T("tab.lbl.total", "Total"), value: string(Stat_Get(_ch, sid)) });
        }
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
        array_push(items, { id: "none", label: Loc_T("tab.skills.none", "No Skills Yet"), value: "", kind: "button", enabled: false, help: Loc_T("tab.skills.none_help", "Cards and chests teach skills. They appear here with the arrows to press."), lines: [], hint: "" });
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
// _in_battle: the menu opened in a fight is read-only (the battle's own ITEM command is the turn), so no row offers "Use".
function TabItems_Items(_ch, _in_battle = false) {
    var items = [];
    var groups = [0, 1, 2];   // potions, throwables, key items
    for (var g = 0; g < 3; g++) {
        for (var i = 0; i < array_length(_ch.inventory); i++) {
            var inv = _ch.inventory[i];
            var it = ItemDB_Get(inv.id);
            if (!is_struct(it) || it.id == 0) continue;
            var grp = (it.type == ITEM_KEY) ? 2 : (Item_IsThrowable(it) ? 1 : ((it.type == ITEM_CONSUMABLE) ? 0 : -1));
            if (grp != g) continue;
            var sentence = (it.type == ITEM_KEY) ? Loc_T("tab.items.key", "An item you keep for the way ahead.") : Item_Sentence(it, _ch);
            var lines = (it.type == ITEM_KEY) ? [] : Item_NumberLines(it, _ch);
            array_push(lines, { label: Loc_T("shop.lbl.have", "You Have"), value: string(inv.qty) });
            array_push(items, {
                id: "item_" + string(it.id), label: it.name, value: "x" + string(inv.qty), kind: "button", enabled: true, item_id: it.id, throwable: Item_IsThrowable(it),
                help: sentence, lines: lines, icon_item: it, hint: (grp == 0 && !_in_battle) ? Loc_T("tab.hint.use", "[k:confirm] Use") : ""
            });
        }
    }
    if (array_length(items) == 0) {
        array_push(items, { id: "none", label: Loc_T("tab.items.none", "Nothing in Your Bag"), value: "", kind: "button", enabled: false, help: Loc_T("tab.items.none_help", "Potions, throwables and keys you find show up here."), lines: [], hint: "" });
    }
    return items;
}

// Confirm on an Items row: { ok, msg, ch }. A throwable says to throw it in a battle on the map; in a fight every row says the read-only reason (hunt 6, D99).
function TabItems_Press(_ch, _it, _in_battle) {
    if (!_in_battle && variable_struct_exists(_it, "throwable") && _it.throwable) {
        return { ok: false, msg: Loc_T("item.msg.throw_in_battle", "Throw it at an enemy in battle."), ch: _ch };
    }
    return TabItems_Use(_ch, _it.item_id, _in_battle);
}

// Uses a potion or an antidote from the menu. Returns { ok, msg, ch }; the item is spent only when it did something.
// In a fight (_in_battle) nothing is used here: a potion costs the turn, and only the battle's ITEM command spends one (hunt 6, D99).
function TabItems_Use(_ch, _item_id, _in_battle = false) {
    var item = ItemDB_Get(_item_id);
    var out = { ok: false, msg: Loc_T("item.msg.cant_use", "Can't use that."), ch: _ch };
    if (_in_battle) {
        out.msg = Loc_T("menu.msg.items_in_fight", "In a battle, use Item in the battle menu.");
        return out;
    }
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
        case "weapon": return Loc_T("tab.gear.no_weapon", "No Weapon");
        case "body": return Loc_T("tab.gear.no_armor", "No Armor");
        case "accessory": return Loc_T("tab.gear.no_accessory", "No Accessory");
    }
    return Loc_T("tab.gear.empty", "Nothing Equipped");
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
    var sentence = Item_Sentence(_item, _ch);
    if (!_worn && !can.ok) sentence += " " + can.msg;
    var cur_id = _worn ? 0 : Equip_SlotGet(_ch, string(_item.equip_slot));
    if (!_worn && can.ok && cur_id != 0) sentence += " " + Loc_T("tab.gear.replaces", "Replaces {item}.", { item: Item_NameMarked(cur_id) });
    return {
        id: "gear_" + string(_item.id), label: _item.name, value: "", kind: "button", enabled: true, item_id: _item.id, slot: _slot, worn: _worn,
        dim: (!_worn && !can.ok), help: sentence, lines: _worn ? Item_NumberLines(_item, _ch) : Gear_CompareLines(_ch, _item), icon_item: _item,
        hint: _worn ? Loc_T("tab.hint.takeoff", "[k:confirm] Unequip") : (can.ok ? Loc_T("tab.hint.equip", "[k:confirm] Equip") : "")
    };
}

function TabGear_Items(_ch, _in_battle = false) {
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
    if (_in_battle) {   // read-only in a fight: no "Equip" / "Take off" hint (Gear_Toggle refuses)
        for (var h = 0; h < array_length(items); h++) items[h].hint = "";
    }
    return items;
}

// Puts a bag item on, or takes a worn one off. Returns { ok, equipped, msg, ch }. In a fight (_in_battle) gear cannot change: a swap would cost no turn (hunt 6).
function Gear_Toggle(_ch, _item_id, _in_battle = false) {
    var item = ItemDB_Get(_item_id);
    var out = { ok: false, equipped: false, msg: Loc_T("menu.msg.cant_equip", "Can't equip that."), ch: _ch };
    if (_in_battle) {
        out.msg = Loc_T("menu.msg.gear_in_fight", "You can't change gear during a battle.");
        return out;
    }
    if (!is_struct(item) || item.id == 0) return out;
    var slot = variable_struct_exists(item, "equip_slot") ? string(item.equip_slot) : "";
    if (slot != "" && Equip_SlotGet(_ch, slot) == item.id) {
        Equip_SlotSet(_ch, slot, 0);
        out.ch = RecomputeResources(_ch);
        out.ok = true;
        out.msg = Loc_T("menu.msg.unequipped", "Unequipped {item}.", { item: Item_NameMarked(item.id) });
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

// D173 (IDEA-07): a fight showed the profile this enemy's weakness (_kind "weak") or resistance ("resist"): the Codex entry keeps a flag per kind, and shows the status once it is set.
// true when it was new (the profile file should be written); false when already known or when the enemy has no entry yet.
function Codex_NoteWeakPoint(_prof, _enemy_id, _kind) {
    var e = Codex_Entry(_prof, _enemy_id);
    if (!is_struct(e)) return false;
    var f = (_kind == "resist") ? "resist_seen" : "weak_seen";
    if (variable_struct_exists(e, f) && variable_struct_get(e, f)) return false;
    variable_struct_set(e, f, true);
    return true;
}

// The weak point a skill or a throw met in a fight (its result's weak_status / resist_status): the profile of the game learns it, and the file is written when something is new.
function Codex_RecordWeakPoint(_enemy_id, _res) {
    if (!is_struct(_res)) return;
    var prof = Profile_Get();
    var fresh = false;
    if (variable_struct_exists(_res, "weak_status") && _res.weak_status >= 0 && Codex_NoteWeakPoint(prof, _enemy_id, "weak")) fresh = true;
    if (variable_struct_exists(_res, "resist_status") && _res.resist_status >= 0 && Codex_NoteWeakPoint(prof, _enemy_id, "resist")) fresh = true;
    if (fresh) Profile_Flush();
}

// The value of the Weak / Resists line: the status name once seen, "?" before.
function Codex_WeakPointValue(_ent, _flag, _status_id) {
    var seen = variable_struct_exists(_ent, _flag) && variable_struct_get(_ent, _flag);
    return (seen && _status_id >= 0) ? string(StatusDB_Get(_status_id).name) : "?";
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
            { label: Loc_T("tab.lbl.weak", "Weak"), value: Codex_WeakPointValue(ent, "weak_seen", cfg.weak) },   // D173 (IDEA-07): "?" until a fight showed it
            { label: Loc_T("tab.lbl.met", "Met"), value: string(ent.met) }
        ];
        if (cfg.resist >= 0) array_insert(lines, array_length(lines) - 1, { label: Loc_T("tab.lbl.resists", "Resists"), value: Codex_WeakPointValue(ent, "resist_seen", cfg.resist) });
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
    return Loc_T("tab.codex.notes_title", "Notes Found {n}/{max}", { n: string(Codex_NoteCount(_prof)), max: string(array_length(Note_Defs())) });
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
        if (res == "won") sentence = Loc_T("tab.hist.won", "You climbed out of the tunnel.");
        else if (res == "abandoned") sentence = Loc_T("tab.hist.abandoned", "You abandoned this run on floor {n}.", { n: string(fl) });
        else sentence = (cause != "") ? Loc_T("tab.hist.died_to", "Floor {n}: felled by {name}.", { name: cause, n: string(fl) }) : Loc_T("tab.hist.died", "You fell on floor {n}.", { n: string(fl) });
        // H13c (D156): the row is the class and level alone. The result (won / gave up / floor and killer) is the sentence in the details panel; a value column on every row
        // made the list ask for so much width that the number lines had to put each value under its label and the panel outgrew the screen.
        // G9 (D137): the six run stats made eleven lines, which do not fit the details panel at 800 x 720. The level is in the row's title, the gold is gone with the run
        // (D23), so those two lines gave way; the floor, the foes beaten and the seed stay.
        var lines = [
            { label: Loc_T("tab.lbl.floor", "Floor"), value: string(fl) },
            { label: Loc_T("tab.lbl.kills", "Enemies Beaten"), value: string(variable_struct_exists(h, "kills") ? h.kills : 0) }
        ];
        var stat_lines = RunStats_Lines(h);   // Perfect rate, crits, damage dealt / taken, fights won, run time ("-" for a run from before D137)
        for (var sl = 0; sl < array_length(stat_lines); sl++) array_push(lines, stat_lines[sl]);
        array_push(lines, { label: Loc_T("tab.lbl.seed", "Seed"), value: string(variable_struct_exists(h, "seed") ? h.seed : 0) });
        array_push(rows, {
            id: "run_" + string(i), label: Loc_T("tab.hist.row", "{cls} Lv {n}", { cls: string(cname), n: string(h.level) }), value: "", kind: "button", enabled: true, help: sentence, hint: "",
            lines: lines
        });
    }
    return rows;
}

// H13c (D156): how many columns the run history's number lines use in the details panel (1 or 2). A run has nine lines: one to a row is the look, but in a language whose
// sentences wrap more (Korean) that is taller than the body, so two to a row (the run summary's way) is used then; it is also the choice when it is the shorter of the two
// and the one-column page does not fit. Measured at the details width this page really gets.
function Codex_HistoryCols(_rows) {
    if (array_length(_rows) <= 0) return 1;
    var z = TabMenu_Zones("codex_history");
    var mt = z.mt;
    var p = mt.p;
    var m = Ui_MenuNew("fit_history", _rows, { layout: { title: Loc_T("tab.codex.history", "Run History"), anchor: "center", details: true, details_pos: "right", details_cols: 1, det_art: true, hides_below: true } });
    var lneed = Ui_MenuListNeed(Ui_MenuMeasureRowsFresh(m, mt), p);
    var hs = [0, 0];
    for (var c = 1; c <= 2; c++) {
        var det_w = TabMenu_Widths(z, lneed, Ui_MenuDetailsNeed(_rows, p, c)).det_w;
        for (var i = 0; i < array_length(_rows); i++) hs[c - 1] = max(hs[c - 1], Ui_DetailsHeight(det_w, _rows[i].help, _rows[i].lines, c));
    }
    if (hs[0] - 2 * p <= z.body_h) return 1;   // the same allowance the fit check makes: the text may use 2p of the 4p kept under the last line
    return (hs[1] < hs[0]) ? 2 : 1;
}

// D173 (IDEA-07): the Weak and Resists lines make the bestiary's details panel taller than the body at the largest window (p = 4), where the page was already nearly full. Then every
// portrait is drawn in the smaller box (pic.small, 20 font pixels instead of 32), which gives back about 50 units; at the smaller windows the page fits with the full box and nothing changes.
// Measured at the details width the page really gets; the rows are changed in place (and set back when the window gets smaller again, see TabCodex_HistoryRefit).
function Codex_BestiaryFitArt(_rows) {
    if (array_length(_rows) <= 0) return;
    var z = TabMenu_Zones("codex_bestiary");
    var p = z.mt.p;
    for (var i = 0; i < array_length(_rows); i++) if (variable_struct_exists(_rows[i], "pic") && is_struct(_rows[i].pic)) _rows[i].pic.small = false;
    var m = Ui_MenuNew("fit_bestiary", _rows, { layout: { title: "", anchor: "center", details: true, details_pos: "right", details_cols: 2, det_art: true, hides_below: true } });
    var lneed = Ui_MenuListNeed(Ui_MenuMeasureRowsFresh(m, z.mt), p);
    var det_w = TabMenu_Widths(z, lneed, Ui_MenuDetailsNeed(_rows, p, 2)).det_w;
    var worst = 0;
    for (var j = 0; j < array_length(_rows); j++) worst = max(worst, Ui_DetailsHeight(det_w, _rows[j].help, _rows[j].lines, 2, 0, _rows[j]));
    if (worst - 2 * p <= z.body_h) return;   // the same allowance the fit check makes: the text may use 2p of the 4p kept under the last line
    for (var k = 0; k < array_length(_rows); k++) if (variable_struct_exists(_rows[k], "pic") && is_struct(_rows[k].pic)) _rows[k].pic.small = true;
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
        { id: "history", label: Loc_T("tab.codex.history", "Run History"), value: string(runs), kind: "button", enabled: (runs > 0), dim: (runs <= 0),
          help: Loc_T("tab.codex.history_help", "Every run you have finished, newest first."),
          lines: [{ label: Loc_T("tab.lbl.wins", "Wins"), value: string(_prof.wins) }, { label: Loc_T("tab.lbl.falls", "Falls"), value: string(_prof.deaths) }, { label: Loc_T("tab.lbl.best_floor", "Best Floor"), value: string(_prof.best_floor) }],
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
        case "codex_history": return 0.4;    // H13c: rows are the class and level alone now (no value column), so the details panel gets the width
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

// H13b (D156): the widths of the list and of the details panel of one Tab page: { list_w, det_w }. _z is TabMenu_Zones (the share the page starts from),
// _list_need and _det_need what the rows and the number lines ask for (Ui_MenuListNeed, Ui_MenuDetailsNeed). Pure.
// The page keeps its share when the share holds both; when a row's label or a number line asks for more, the other panel gives way (the list never takes more than
// two thirds of the body; the rows that still do not fit are for the text side).
function TabMenu_Widths(_z, _list_need, _det_need) {
    var p = _z.mt.p;
    var total = _z.list_w + _z.det_w;
    var lneed = ceil(_list_need / p) * p;
    var dneed = ceil(_det_need / p) * p;
    var cap = total - ceil(round(total / 3) / p) * p;
    var w = clamp(_z.list_w, lneed, max(lneed, total - dneed));
    w = min(w, cap);
    return { list_w: w, det_w: total - w };
}

// Fits a list menu into the Tab menu's body; _top_extra is room kept above the list (the Status card).
function TabMenu_FitMenu(_m, _z, _top_extra = 0) {
    TabCodex_HistoryRefit(_m, _z);
    var L = _m.layout;
    var mc = Ui_MenuMeasureRowsFresh(_m, _z.mt);
    var wd = TabMenu_Widths(_z, Ui_MenuListNeed(mc, _z.mt.p), mc.det_need);
    L.x_anchor = "left";
    L.panel_w = wd.list_w;
    L.y_top = _z.body_y + _top_extra;
    L.max_h = _z.body_h - _top_extra;
    L.details = true;
    L.details_pos = "right";
    L.det_w = wd.det_w;
    L.det_top = _z.body_y;
    L.det_h = _z.body_h;
    L.det_art = true;
    L.hides_below = true;
}

function TabMenu_Title(_id, _ch) {
    switch (_id) {
        case "status": return Loc_T("tab.title.status", "Status");
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
        case "items": return TabItems_Items(_ch, room == rm_battle);
        case "gear": return TabGear_Items(_ch, room == rm_battle);
        case "codex": return TabCodex_Items(Profile_Get());
        case "system": return TabSystem_Items(room == rm_battle, Menu_SaveReason());
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

// ---- the System tab (D140, D141, I-112): Help, Save, Save & Quit to Title, Abandon run, Quit to title. Abandon and the quits ask first (D156); Save and Save & Quit are greyed, with the reason
// as their help line, in a fight, in a cutscene and when there is no run (_save_block: Menu_SaveBlock's answer, "" = allowed) ----
function TabSystem_Items(_in_battle = false, _save_block = "") {
    var save_on = (_save_block == "");
    var save_help = Loc_T("pause.help.save", "Saves your run now. Continue picks it up from here.");
    var sq_help = Loc_T("pause.help.save_quit", "Saves your run, then goes to the title. Continue picks it up from here.");
    return [
        { id: "help", label: Loc_T("pause.option.help", "Help"), value: "", kind: "button", enabled: true, lines: [], help: Loc_T("pause.help.help", "Every hint the game has: the ones you have seen and the ones still to come.") },
        { id: "save", label: Loc_T("pause.option.save", "Save"), value: "", kind: "button", enabled: save_on, lines: [], help: save_on ? save_help : Menu_SaveReasonText(_save_block) },
        { id: "save_quit", label: Loc_T("pause.option.save_quit", "Save & Quit to Title"), value: "", kind: "button", enabled: save_on, lines: [], help: save_on ? sq_help : Menu_SaveReasonText(_save_block) },
        { id: "abandon", value: "", kind: "button", enabled: true, lines: [],
          label: Loc_T("pause.option.abandon", "Abandon Run"),
          help: Loc_T("pause.help.abandon", "Ends this run now. It counts as a death, but you keep the echo.") },
        { id: "quit", label: Loc_T("pause.option.quit", "Quit to Title"), value: "", kind: "button", enabled: true, lines: [],
          help: _in_battle ? Loc_T("tab.system.quit_battle_help", "Goes back to the title. Continue puts you back just before this battle.")
                           : Loc_T("pause.help.quit", "Saves the run and goes to the title. Continue picks it up again.") }
    ];
}

// I-112: why saving is not possible now ("" = it is): no run going ("none"), a fight ("battle"), a cutscene or the title ("cutscene"). Pure: the room and whether a run is going.
function Menu_SaveBlock(_room, _run_active) {
    if (!_run_active) return "none";
    if (_room == rm_battle) return "battle";
    if (_room == rm_cutscene || _room == rm_start) return "cutscene";
    return "";
}

// The same for the game as it is now: also "busy" where the autosave itself would refuse (the player is down, a room is still being set up).
function Menu_SaveReason() {
    var why = Menu_SaveBlock(room, Run_IsActive());
    if (why == "" && !Run_AutosaveAllowed()) why = "busy";
    return why;
}

function Menu_SaveReasonText(_why) {
    switch (_why) {
        case "battle": return Loc_T("tab.system.save_battle", "You cannot save during a battle.");
        case "cutscene": return Loc_T("tab.system.save_cutscene", "You cannot save during a cutscene.");
        case "none": return Loc_T("tab.system.save_none", "There is no run to save.");
    }
    return Loc_T("tab.system.save_busy", "You cannot save right now.");
}

// I-112: saves the run now, the autosave's own write (the active profile's active save file, Save_WriteFileAtomic). _block: a test passes the answer of Menu_SaveBlock; undefined = the game now.
// Returns { ok, why, text }: text is what the notice says ("Game saved.", or why it could not be).
function Menu_SaveNow(_block = undefined) {
    var why = is_undefined(_block) ? Menu_SaveReason() : _block;
    if (why != "") return { ok: false, why: why, text: Menu_SaveReasonText(why) };
    var ok = Run_SaveNow();
    return { ok: ok, why: ok ? "" : "failed", text: ok ? Loc_T("save.done", "Game saved.") : Loc_T("save.failed", "The game could not be saved.") };
}

// The Save row: saves, then a notice over the menu (the menu stays open under it).
function TabSystem_SaveRow() {
    var r = Menu_SaveNow();
    SFX_PlayUI(r.ok ? "ui_confirm" : "ui_deny");
    Notice_Open(r.text);
}

// Yes to "Save and quit to title?": it saves first; only when that worked does the menu fade out and Menu_CloseFinalize take the player to the title (a failed save says so and stays).
function TabSystem_SaveQuitYes(_d) {
    var r = Menu_SaveNow();
    if (!r.ok) {
        SFX_PlayUI("ui_deny");
        Notice_Open(r.text);
        return;
    }
    TabSystem_Yes({ id: "quit" });
}

// D156: the question a System row asks before it acts (a fight says what Continue will do).
function TabSystem_Question(_id, _in_battle = false) {
    switch (_id) {
        case "abandon": return Loc_T("confirm.abandon", "Abandon this run? It counts as a death, but you keep the echo.");
        case "quit": return _in_battle ? Loc_T("confirm.quit_battle", "Quit to title? Continue puts you back just before this battle.")
                                       : Loc_T("confirm.quit", "Quit to title? The run is saved and Continue picks it up again.");
        case "save_quit": return Loc_T("confirm.save_quit", "Save and quit to title? Continue picks it up from here.");
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
    var stat_ids = [STAT_ATK, STAT_DEF, STAT_MAG, STAT_SPD, STAT_VIG, STAT_MND];
    var stat_keys = ["atk", "def", "mag", "spd", "vig", "mnd"];
    for (var i = 0; i < array_length(stat_ids); i++) array_push(out, Help_Term(stat_keys[i], Stat_ShortName(stat_ids[i]), Stat_Sentence(stat_ids[i])));
    array_push(out, Help_Term("hp", Loc_T("battle.hud.hp", "HP"), Loc_T("help.line.hp", "Health. At 0 HP you fall.")));
    array_push(out, Help_Term("mp", Loc_T("battle.hud.mp", "MP"), Loc_T("help.line.mp", "Magic points. Skills spend them; potions and rest restore them.")));
    array_push(out, Help_Term("crit", Loc_T("help.term.crit", "Crit"), Loc_T("help.line.crit", "A critical hit deals {mult} times the damage. [t]Take Aim[/t] and some gear raise the odds.", { mult: string(COMBAT_CRIT_MULT) })));
    array_push(out, Help_Term("perfect", Loc_T("battle.det.perfect", "Perfect"), Loc_T("help.line.perfect", "Press in the bright zone of the bar for +{pct}% damage.", { pct: string(round((Qte_GradeMult(QTE_PERFECT) - 1) * 100)) })));
    array_push(out, Help_Term("good", Loc_T("help.term.good", "Good"), Loc_T("help.line.good", "Press near the middle for +{pct}% damage.", { pct: string(round((Qte_GradeMult(QTE_GOOD) - 1) * 100)) })));
    array_push(out, Help_Term("ok", Loc_T("help.term.ok", "OK"), Loc_T("help.line.ok", "Press on the bar, off the middle, for normal damage.")));
    array_push(out, Help_Term("weak", Loc_T("help.term.weak", "Weak"), Loc_T("help.line.weak", "Miss the zone and the hit deals {pct}% less damage.", { pct: string(round((1 - Qte_GradeMult(QTE_WEAK)) * 100)) })));
    array_push(out, Help_Term("break", Loc_T("help.term.break", "BREAK"), Loc_T("help.line.break", "Good hits fill the [t]stagger[/t] meter. When it is full the enemy loses a turn and takes +{pct}% damage.", { pct: string(round((BREAK_DAMAGE_MULT - 1) * 100)) })));
    array_push(out, Help_Term("steadfast", Loc_T("battle.chip.steadfast", "Steadfast"), Loc_T("battle.chip.steadfast.line", "Cannot be stunned.")));
    array_push(out, Help_Term("elite", Loc_T("tab.lbl.elite", "Elite"), Loc_T("help.line.elite", "A marked, tougher enemy with a special trait. Its rewards are better.")));
    var sids = Status_AllIds();
    for (var s = 0; s < array_length(sids); s++) array_push(out, Help_Term("status_" + string(sids[s]), StatusDB_Get(sids[s]).name, Status_Description(sids[s])));
    return out;
}

// The Help list: every tutorial, then the stats page.
function TabHelp_Items() {
    var out = Tutorial_HelpItems();
    array_push(out, { id: "stats_terms", label: Loc_T("help.stats.title", "Stats & Terms"), value: "", kind: "button", enabled: true, lines: [], hint: "",
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
        layout: { title: Loc_T("help.stats.title", "Stats & Terms"), anchor: "center", details: true, details_pos: "right", hides_below: true }
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

// Hunt 6 UI (D140): the player is settled for one frame per tile while walking, so a menu press during a step is kept for a short window and the menu opens on the
// first settled frame (single use). 300 ms is a little more than one walking step (16 frames, 267 ms), so the next end of a step always falls inside it.
#macro MENU_OPEN_BUFFER_MS 300

function MenuOpenBuf_New() {
    return { until: 0, frame: -1 };
}

function MenuOpenBuf_Get() {
    if (!variable_global_exists("menu_open_buf") || !is_struct(global.menu_open_buf)) global.menu_open_buf = MenuOpenBuf_New();
    return global.menu_open_buf;
}

// Called by the UI controller on the frames it reaches the open test, with a frame number that counts every Step of that controller (any frame it leaves early, for a
// transition, a pop-up or a dialogue, breaks the run of frames and drops the request). _pressed: Esc / Tab / Start this frame; _free: the map is free (no menu, dialogue or fight) so a refused press may wait;
// _can_open: Menu_CanOpen() now. Returns true on the frame the menu should open.
function MenuOpenBuf_Step(_b, _now, _frame, _pressed, _free, _can_open) {
    var live = (_b.until > 0 && _frame == _b.frame + 1 && _now < _b.until && _free);
    _b.frame = _frame;
    if (!live) _b.until = 0;
    if (_pressed) {
        if (_can_open) {
            _b.until = 0;
            return true;
        }
        if (_free) _b.until = _now + MENU_OPEN_BUFFER_MS;
        return false;
    }
    if (live && _can_open) {
        _b.until = 0;
        return true;
    }
    return false;
}

// The map with nothing on top of it: a menu press that cannot open yet (the player is mid-step) may be kept.
function Menu_MapFree() {
    var gs = GameState_Get();
    return gs.ui.mode == UI_NONE && !gs.in_main_menu && room != rm_battle && instance_exists(gs.player_inst);
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

// H13b (D156): one Codex page: { rows, title, cols } (cols = the number lines' columns in the details panel). The suite builds the same pages.
function TabCodex_Page(_kind, _prof) {
    switch (_kind) {
        case "bestiary":
            var brows = Codex_BestiaryRows(_prof);
            Codex_BestiaryFitArt(brows);   // D173 (IDEA-07): the portrait box that lets the page fit
            return { rows: brows, title: Loc_T("tab.codex.bestiary_title", "Bestiary {n}/{max}", { n: string(Codex_BestiaryCount(_prof)), max: string(array_length(brows)) }), cols: 2 };
        case "notes": return { rows: Codex_NoteRows(_prof), title: Codex_NotesTitle(_prof), cols: 1 };
        case "history":
            var hrows = Codex_HistoryRows(_prof);
            return { rows: hrows, title: Loc_T("tab.codex.history", "Run History"), cols: Codex_HistoryCols(hrows) };
    }
    return { rows: Codex_UnlockRows(_prof), title: Loc_T("tab.codex.unlocks", "Unlocks"), cols: 1 };
}

// The menu of one Codex page (TabCodex_Page's rows, title and columns). The history page remembers the metrics its columns were picked for (R-088).
function TabCodex_MakeMenu(_kind, _page) {
    return Ui_MenuNew("codex_" + _kind, _page.rows, {
        data: { tab: "codex_page", cols_mt: Ui_Metrics() },
        layout: { title: _page.title, anchor: "center", details: true, details_pos: "right", details_cols: _page.cols, det_art: true, hides_below: true }
    });
}

// R-088: the Run History page picks its number-line columns for the window it is in. The window or the text scale changing while the page is open (Ui_Metrics
// hands out a new struct then) picks again, like the widths TabMenu_FitMenu re-fits every frame. Cheap while nothing changed: one compare.
function TabCodex_HistoryRefit(_m, _z) {
    if ((_m.id != "codex_history" && _m.id != "codex_bestiary") || !is_struct(_m.data)) return;
    if (variable_struct_exists(_m.data, "cols_mt") && _m.data.cols_mt == _z.mt) return;
    _m.data.cols_mt = _z.mt;
    if (_m.id == "codex_bestiary") Codex_BestiaryFitArt(_m.items);   // D173: the portrait box follows the window
    else _m.layout.details_cols = Codex_HistoryCols(_m.items);
}

function TabCodex_Open(_kind) {
    var u = TabMenu_Get();
    var pg = u.pages[u.tab];
    var page = TabCodex_Page(_kind, Profile_Get());
    var rows = page.rows;
    if (array_length(rows) <= 0) return;
    var m = TabCodex_MakeMenu(_kind, page);
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
            var r = TabItems_Press(ch, it, room == rm_battle);
            if (r.ok) CardsUi_Commit(r.ch); else SFX_PlayUI("ui_deny");
            TabMenu_Toast(r.msg);
            TabMenu_Refresh();
            break;
        case "gear":
            if (it.item_id < 0) break;
            var g = Gear_Toggle(ch, it.item_id, room == rm_battle);
            if (g.ok) CardsUi_Commit(g.ch); else SFX_PlayUI("ui_deny");
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
                case "save":   // I-112
                    TabSystem_SaveRow();
                    break;
                case "save_quit":   // I-112: asks, then saves, then leaves (a failed save stays)
                    Confirm_Open(TabSystem_Question("save_quit", false), TabSystem_SaveQuitYes, { id: "save_quit" });
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
        if (d == 0 && Mouse_Pressed(mb_left) && variable_global_exists("ui_tabs_rects")) {
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
        else if (TabMenu_Ids()[TabMenu_Get().tab] == "settings") txt = Loc_T("tab.hint.select", "[k:confirm] Choose");
    }
    if (TabNote_IsReader(m) && NoteReader_MaxScroll(array_length(m.data.wrapped), m.data.visible) > 0) txt = Loc_T("tab.hint.scroll", "[k:up][k:down] Scroll");
    if (NoteReader_Armed(m)) txt = Loc_T("tab.hint.select", "[k:confirm] Choose");   // D154: the note's question is open and its replies can be used
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
        hp: Loc_T("battle.hud.hp", "HP"), mp: Loc_T("battle.hud.mp", "MP"), xp: Loc_T("tab.lbl.xp", "EXP"), xp_max: Loc_T("tab.val.max", "MAX"), xp_ready: Loc_T("tab.val.level_up", "Level Up"),
        level_tpl: Loc_T("battle.hud.level", "Lv {n}"), seed_tpl: Loc_T("tab.lbl.seed_small", "Seed: {n}"),
        lab_w: 0, k_hp: -999, k_mp: -999, k_xp: -999, k_owed: -1, val_w: 0
    };
    c.lab_w = max(UI_TextWidth(c.hp), max(UI_TextWidth(c.mp), UI_TextWidth(c.xp)));
    global.tabmenu_card = c;
    return c;
}

// D177: the status card's EXP bar: full and "Level Up" while a level is owed (won, the screen not yet confirmed), else EXP over the bar, "MAX" at the cap. { ratio, text }
function TabMenu_XpBar(_ch, _max_txt = undefined, _ready_txt = undefined) {
    if (LevelUp_Owed(_ch) > 0) return { ratio: 1, text: is_undefined(_ready_txt) ? Loc_T("tab.val.level_up", "Level Up") : _ready_txt };
    if (_ch.exp_next > 0) return { ratio: clamp(_ch.exp / _ch.exp_next, 0, 1), text: string(_ch.exp) + "/" + string(_ch.exp_next) };
    return { ratio: 1, text: is_undefined(_max_txt) ? Loc_T("tab.val.max", "MAX") : _max_txt };
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
    var owed_now = (LevelUp_Owed(_ch) > 0) ? 1 : 0;
    if (cd.k_hp != _ch.max_hp || cd.k_mp != _ch.max_mp || cd.k_xp != _ch.exp_next || cd.k_owed != owed_now) {   // the widest "cur/max" text only changes with the maxima
        var vw = UI_TextWidth(string(_ch.max_hp) + "/" + string(_ch.max_hp));
        vw = max(vw, UI_TextWidth(string(_ch.max_mp) + "/" + string(_ch.max_mp)));
        vw = max(vw, UI_TextWidth(string(_ch.exp_next) + "/" + string(_ch.exp_next)));
        if (owed_now == 1) vw = max(vw, UI_TextWidth(cd.xp_ready));   // D177: "Level Up" in place of the numbers
        cd.val_w = vw;
        cd.k_hp = _ch.max_hp;
        cd.k_mp = _ch.max_mp;
        cd.k_xp = _ch.exp_next;
        cd.k_owed = owed_now;
    }
    var bx = x0 + cd.lab_w + 2 * p;
    var bw = x1 - cd.val_w - 2 * p - bx;
    TabMenu_DrawCardBar(x0, x1, yy, bx, bw, cd.hp, (_ch.max_hp > 0) ? clamp(_ch.hp / _ch.max_hp, 0, 1) : 1, string(_ch.hp) + "/" + string(_ch.max_hp), "hp");
    yy += lh + p;
    TabMenu_DrawCardBar(x0, x1, yy, bx, bw, cd.mp, (_ch.max_mp > 0) ? clamp(_ch.mp / _ch.max_mp, 0, 1) : 1, string(_ch.mp) + "/" + string(_ch.max_mp), "mp");
    yy += lh + p;
    var xb = TabMenu_XpBar(_ch, cd.xp_max, cd.xp_ready);
    TabMenu_DrawCardBar(x0, x1, yy, bx, bw, cd.xp, xb.ratio, xb.text, "xp");
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
    Ui_DimBackdrop(UI_DIM_SCREEN * a);
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
    Notice_Draw();   // R3 note 25: the notice after a Controls reset, over the menu (the controller's own Notice_Draw is not reached while the menu is up)
    if (u.toast != "" && now - u.toast_ms < TAB_TOAST_MS) {
        var tw = Ui_LineWidth(u.toast) + 8 * p;
        var th = mt.line_h + 6 * p;
        var tx = round((mt.gw - tw) / 2);
        var ty = z.foot_y - 2 * p - th;
        Ui_DrawFrame(tx, ty, tw, th, a, p);
        draw_set_alpha(a);
        Ui_LineDraw(tx + 4 * p, ty + 3 * p, u.toast, tw - 8 * p, UI_C_LIGHTEST);
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
        layout: { title: Loc_T("class.select.title", "Choose Class"), anchor: "center", details: true }
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
        SFX_PlayUI("ui_deny");
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
    return { sentence: Item_Sentence(it, GameState_Get().player_ch), lines: Item_NumberLines(it, GameState_Get().player_ch) };
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
        layout: { title: Loc_T("echo.pick.title", "Keep One Skill You Remember"), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);   // the remembered cursor of an earlier screen does not count
    return m;
}

// The name of what an echo option gives (a skill's or an item's), for the question.
function CardsUi_EchoName(_o) {
    return (_o.kind == "skill") ? SkillDB_Get(_o.id).name : Item_NameMarked(_o.id);   // D178: an item's name in its rarity colour (the question is drawn with markup)
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
        case STAT_MAG: return Loc_T("menu.tooltip.stat.mag.desc", "Increases spell damage.");
        case STAT_VIG: return Loc_T("menu.tooltip.stat.vig.desc", "Raises max HP. The more you add, the less each point gives.");   // D176
        case STAT_MND: return Loc_T("menu.tooltip.stat.mnd.desc", "Raises max MP. The more you add, the less each point gives.");
    }
    return "";
}

// D177 (amended I-109): the level-up screen. Rows ATK DEF SPD MAG VIG MND. The rows the class grows read "now > now + growth" with only the NEW number gold (the label and the old number
// are white); the others read only the number; the row under the cursor adds its "+1" (its new number gold too; CardsUi_StatRefresh, every frame). The details say what the stat does and Now / After (VIG: Max HP, MND: Max MP), with the class growth and the
// point both counted. "Now" is the character as he is, "After" the preview of the level the screen is for (LevelUp_PreviewCharacter).
function CardsUi_StatMenu() {
    var ch = GameState_Get().player_ch;
    var pv = LevelUp_PreviewCharacter(ch);   // the level the screen is for, class growth in, the point not placed
    var plvl = LevelUp_PromptLevel(ch);   // hunt 7: a fight that gave several levels steps through each level's growth, oldest first
    var ids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG, STAT_VIG, STAT_MND];
    var items = [];
    var any_growth = false;
    for (var i = 0; i < array_length(ids); i++) {
        var sid = ids[i];
        var key = Stat_Key(sid);
        var now = variable_struct_get(ch.stats, key);
        var grow = max(0, variable_struct_get(pv.stats, key) - now);
        var after = StatClamp(variable_struct_get(pv.stats, key) + 1);   // growth and the point
        var lines = [];
        if (sid == STAT_VIG) lines = [ { label: Loc_T("cards.stat.hp_now", "Max HP Now"), value: string(ch.max_hp) }, { label: Loc_T("cards.stat.hp_after", "Max HP After"), value: string(Resource_MaxHpOfVig(after)) } ];
        else if (sid == STAT_MND) lines = [ { label: Loc_T("cards.stat.mp_now", "Max MP Now"), value: string(ch.max_mp) }, { label: Loc_T("cards.stat.mp_after", "Max MP After"), value: string(Resource_MaxMpOfMnd(after)) } ];
        else lines = [ { label: Loc_T("cards.stat.now", "Now"), value: string(now) }, { label: Loc_T("cards.stat.after", "After"), value: string(after) } ];
        var row = { label: Stat_ShortName(sid), value: "", help: CardsUi_StatHelp(sid), lines: lines, stat: sid, now: now, grow: grow, new_col: UI_C_MERCHANT_GOLD };   // I-109: only the NEW number (after ">") is gold; the label and the old number are white
        if (grow > 0) any_growth = true;
        array_push(items, row);
    }
    var m = Ui_MenuNew("cards_stat", items, {
        on_confirm: CardsUi_StatConfirm, on_back: CardsUi_NoBack,
        layout: { title: Loc_T("cards.stat.title", "Level {lvl}: Place 1 Point", { lvl: string(plvl) }), note: any_growth ? Loc_T("levelup.legend", "Gold = your class grows these") : "", note_col: UI_C_MERCHANT_GOLD, anchor: "center", details: true, snap_band: true }   // I-109: the bar sits on the cursor row in the same frame as the +1 and the details (no glide)
    });
    Ui_MenuFixCursor(m, clamp(DB_PlayerClass(ch.class_id).free_default, 0, 5));   // the class's usual stat first
    CardsUi_StatRefresh(m);
    return m;
}

// The rows' values follow the cursor: the row under it shows its +1. Called when the menu is made and every frame it is drawn.
function CardsUi_StatRefresh(_m) {
    for (var i = 0; i < array_length(_m.items); i++) {
        var it = _m.items[i];
        it.value = Cards_StatRowValue(it.now, it.grow, i == _m.cursor);
    }
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
        array_push(items, { label: sk.name, value: Loc_T("card.mp_short", "{mp} MP", { mp: string(round(sk.mp_cost)) }), help: Loc_T("cards.replace.lose", "Loses: {line}", { line: Card_SkillSentence(sk) }), lines: CardsUi_CompareLines(ch.skills[i], new_id), skill_id: ch.skills[i] });
    }
    array_push(items, { label: Loc_T("cards.replace.keep", "Keep My Skills"), value: "", help: Loc_T("cards.replace.keep_help", "Go back to the cards and choose again."), lines: [], skill_id: -1 });
    var m = Ui_MenuNew("cards_replace", items, {
        on_confirm: CardsUi_ReplaceConfirm, on_back: CardsUi_ReplaceBack,
        layout: { title: Loc_T("cards.replace.title", "Learn {skill}: Replace Which?", { skill: SkillDB_GetBase(new_id).name }), anchor: "center", details: true }
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

// R3: the pick has no Skip. With no card on offer there is nothing to choose: confirm answers the pick and closes (it used to be Skip, without the gold).
function CardsUi_PickEmpty() {
    var gs = GameState_Get();
    CardsUi_Commit(Cards_ConsumePick(gs.player_ch));
    CardsUi_Close();
}

function CardsUi_PickUpdate(_u) {
    var pk = _u.pick;
    var snap = Ui_ReadInput();
    var n = array_length(pk.ids);
    var dx = (snap.right_p ? 1 : 0) - (snap.left_p ? 1 : 0);
    var hover = Ui_HoverIndex(pk.rects, snap.mx, snap.my);
    var cur = pk.cursor;
    if (snap.mouse_moved && hover >= 0) cur = hover;
    if (dx != 0) cur = Cards_PickMove(cur, n, dx, 0, pk.last);
    if (cur != pk.cursor) {
        pk.cursor = cur;
        pk.last = cur;
        SFX_PlayUI("ui_move");
    }
    var go = snap.confirm || (snap.click && hover == pk.cursor);
    if (go) {
        SFX_PlayUI("ui_confirm");
        if (n <= 0) CardsUi_PickEmpty();
        else CardsUi_Take(pk.ids[clamp(pk.cursor, 0, n - 1)]);
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

// H13b (D156): the height of a number line's label on a card: one line, or more when the label is wider than the card (it wraps, nothing is cut). A wrapped
// label always has its value on the row below.
function CardsUi_LabelH(_line, _iw, _mt) {
    return max(_mt.line_h, Ui_TextBlockH(_line.label, _iw));
}

// R3 (D168, owner notes 10 and 28): where the pick screen's three cards stand: { margin, gap, cw }. The cards take the room first: a 2p margin at the sides and a
// 3p gap (the selected card's halo is p wide, so the halos never touch), which leaves every card wider than the old 3p / 4p did.
function CardsUi_PickColumns(_mt, _n = 3) {
    var p = _mt.p;
    var margin = 2 * p;
    var gap = 3 * p;
    var cw = floor((_mt.gw - 2 * margin - (_n - 1) * gap) / max(1, _n));
    return { margin: margin, gap: gap, cw: cw };
}

// The room a card's text has inside its frame: the frame is 2p thick and the text keeps p from it (it kept 2p).
function CardsUi_InnerW(_w, _mt) {
    return _w - 6 * _mt.p;
}

// R3 (D168): how a card's name is laid out in a column _w wide (the arrow of the selected card is outside it): { step, w, h, lines, y_off }. Names keep their
// wording and wrap by words at the UI's size (step 0); when one word is wider than the column the whole name takes the next smaller size the UI has
// (UI_FontStep, step 1) so it still fits. h is at least one normal line; y_off centres a name that is lower than that. Pure.
function CardsUi_NameFit(_name, _w, _mt) {
    var m = Ui_TextBlockMeasureStep(_name, _w, 0);
    var step = 0;
    if (m.w > _w) {
        var m1 = Ui_TextBlockMeasureStep(_name, _w, 1);
        if (m1.step > 0 && m1.w < m.w) { m = m1; step = 1; }
    }
    return { step: step, w: m.w, h: max(m.h, _mt.line_h), lines: m.lines, y_off: max(0, (_mt.line_h - m.h) div 2) };
}

// _g: the space between a card's blocks (2p; p on a screen that is tight, CardsUi_PickPlan).
function CardsUi_CardHeight(_c, _w, _mt, _g = -1) {
    var p = _mt.p;
    var g = (_g < 0) ? 2 * p : _g;
    var iw = CardsUi_InnerW(_w, _mt);
    var h = 8 * p;
    h += CardsUi_NameFit(Card_Name(_c), iw - 5 * p, _mt).h + g;
    h += max(Ui_TextBlockH(Card_TypeTag(_c), iw - 5 * p), _mt.line_h) + p + p + g;   // the tag (it wraps), the rule
    h += Ui_TextBlockH(Card_Sentence(_c), iw) + g;
    var seq = Card_Sequence(_c);
    if (array_length(seq) > 0) h += 13 * clamp(floor(iw / 60), 1, 3) + g;
    var lines = Card_Lines(_c);
    for (var i = 0; i < array_length(lines); i++) {
        var lh = CardsUi_LabelH(lines[i], iw, _mt);
        if (lh > _mt.line_h) h += lh + p + _mt.line_h + p;
        else h += (CardsUi_LineStacked(lines[i], iw, _mt) ? 2 : 1) * (_mt.line_h + p);
    }
    return h;
}

function CardsUi_DrawCard(_x, _y, _w, _h, _c, _sel, _a, _g = -1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var g = (_g < 0) ? 2 * p : _g;
    var iw = CardsUi_InnerW(_w, mt);
    if (_sel) {   // a bright halo outside the frame
        Ui_Box(_x + p, _y - p, _x + _w - p, _y, UI_C_LIGHT);
        Ui_Box(_x + p, _y + _h, _x + _w - p, _y + _h + p, UI_C_LIGHT);
        Ui_Box(_x - p, _y + p, _x, _y + _h - p, UI_C_LIGHT);
        Ui_Box(_x + _w, _y + p, _x + _w + p, _y + _h - p, UI_C_LIGHT);
    }
    Ui_DrawFrame(_x, _y, _w, _h, _a, p);
    var x0 = _x + 3 * p;
    var ty = _y + 4 * p;
    var nf = CardsUi_NameFit(Card_Name(_c), iw - 5 * p, mt);
    if (_sel) {
        Ui_Box(_x + 3 * p, ty - p, _x + _w - 3 * p, ty + nf.h + p, UI_C_DARK);
        Ui_Arrow(x0 + Ui_Bob(current_time) * p, ty + (mt.line_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    }
    Ui_TextBlockStep(x0 + 5 * p, ty + nf.y_off, Card_Name(_c), iw - 5 * p, UI_C_TEXT, nf.step);
    ty += nf.h + g;
    var tag = Card_TypeTag(_c);
    Ui_TextBlock(x0 + 5 * p, ty, tag, iw - 5 * p, UI_C_LIGHT);
    ty += max(Ui_TextBlockH(tag, iw - 5 * p), mt.line_h) + p;
    Ui_Box(_x + 3 * p, ty, _x + _w - 3 * p, ty + p, UI_C_DARK);
    ty += p + g;
    var sentence = Card_Sentence(_c);
    Ui_TextBlock(x0, ty, sentence, iw, UI_C_LIGHTEST);
    ty += Ui_TextBlockH(sentence, iw) + g;
    var seq = Card_Sequence(_c);
    if (array_length(seq) > 0) {
        var u = clamp(floor(iw / 60), 1, 3);
        ty += CardsUi_DrawArrows(x0, ty, iw, seq, u) + g;
    }
    var lines = Card_Lines(_c);
    for (var i = 0; i < array_length(lines); i++) {
        var lab_h = CardsUi_LabelH(lines[i], iw, mt);
        if (lab_h > mt.line_h) {   // a label wider than the card wraps; its value goes under it
            Ui_TextBlock(x0, ty, lines[i].label, iw, UI_C_LIGHT);
            ty += lab_h + p;
        } else {
            Ui_Text(x0, ty, lines[i].label, UI_C_LIGHT);
            if (CardsUi_LineStacked(lines[i], iw, mt)) ty += mt.line_h + p;
        }
        Ui_Text(x0 + iw, ty, lines[i].value, UI_C_LIGHTEST, fa_right);
        ty += mt.line_h + p;
    }
}

// H13b (D156), R3: where the pick screen's parts stand, from the tallest card's height (_ch_max): { total, y0, cards_y, hint_x, hint_y, hint_w, hint_h, bottom }.
// The title, the cards and the hint line, centred on the screen (the Skip box that shared the bottom row is gone, so the cards get its room).
// _slide moves the title and the cards up while the screen slides in. Pure; `bottom` is where the hint line ends and must stay on the screen.
function CardsUi_PickLayout(_ch_max, _hint, _mt, _slide = 0, _tight = false) {
    var p = _mt.p;
    var gap = _tight ? 2 * p : 3 * p;   // between the title, the cards and the hint
    var hint_w = _mt.gw - 2 * _mt.margin;
    var hint_h = UiFit_Measure(_hint, hint_w, true).h;
    var total = _mt.line_h + gap + _ch_max + gap + hint_h;
    var y0 = max(_tight ? _mt.pad : _mt.margin, round((_mt.gh - total) / 2));
    var cy = y0 + _mt.line_h + gap - _slide;
    var hy = cy + _ch_max + gap;
    return { total: total, tight: _tight, y0: y0 - _slide, cards_y: cy, hint_x: _mt.margin, hint_y: hy, hint_w: hint_w, hint_h: hint_h, bottom: hy + hint_h };
}

// H13b (D156), R3: the plan of the pick screen for the cards _cards, each _cw wide: { tight, g, ch_max, lay }. The roomy spacing (2p between a card's blocks,
// 3p between the parts of the screen) when the whole screen ends a margin above the bottom with it; the tight spacing (p and 2p) when it does not. Pure.
function CardsUi_PickPlan(_cards, _cw, _hint, _mt, _slide = 0) {
    var p = _mt.p;
    var plan = undefined;
    for (var pass = 0; pass < 2; pass++) {
        var tight = (pass == 1);
        var g = tight ? p : 2 * p;
        var chm = 0;
        for (var i = 0; i < array_length(_cards); i++) chm = max(chm, CardsUi_CardHeight(_cards[i], _cw, _mt, g));
        var lay = CardsUi_PickLayout(chm, _hint, _mt, _slide, tight);
        plan = { tight: tight, g: g, ch_max: chm, lay: lay };
        if (lay.bottom <= _mt.gh - _mt.margin) break;
    }
    return plan;
}

function CardsUi_DrawPick(_u, _a) {
    var pk = _u.pick;
    var mt = Ui_Metrics();
    var p = mt.p;
    var n = array_length(pk.ids);
    var col = CardsUi_PickColumns(mt, max(1, n));
    var cw = col.cw;
    var cards = [];
    for (var i = 0; i < n; i++) array_push(cards, CardDB_Get(pk.ids[i]));
    var picks = GameState_Get().player_ch.card_picks;
    var title = Loc_T("cards.pick.title", "Choose a Card");
    if (picks > 1) title += "  " + Loc_T("cards.pick.left", "({n} picks left)", { n: string(picks) });
    var hint = Loc_T("cards.pick.hint", "[k:left][k:right] Choose   [k:confirm] Take");
    var slide = p * round((1 - _a) * 3);
    var plan = CardsUi_PickPlan(cards, cw, hint, mt, slide);
    var ch_max = plan.ch_max;
    var pl = plan.lay;
    Ui_Text(mt.gw / 2, pl.y0, title, UI_C_LIGHTEST, fa_center);
    var cy = pl.cards_y;
    var rects = [];
    var x_start = round((mt.gw - (n * cw + (n - 1) * col.gap)) / 2);   // the row of cards is centred (the few units left over are split evenly)
    for (var k = 0; k < n; k++) {
        var cx = x_start + k * (cw + col.gap);
        CardsUi_DrawCard(cx, cy, cw, ch_max, cards[k], k == pk.cursor, _a, plan.g);
        array_push(rects, { x: cx, y: cy, w: cw, h: ch_max });
    }
    pk.rects = rects;
    Prompt_RichDraw(pl.hint_x, pl.hint_y, hint, pl.hint_w, UI_C_LIGHT, fa_center, _a);
}

function CardsUi_Draw() {
    if (!CardsUi_IsOpen()) return;
    var u = global.cards_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(UI_DIM_SCREEN * a);
    if (u.kind == "stat" && is_struct(Ui_StackTop(u.stk)) && Ui_StackTop(u.stk).id == "cards_stat") CardsUi_StatRefresh(Ui_StackTop(u.stk));   // D177: the row under the cursor shows its +1
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
        layout: { title: Loc_T("bed.upgrade_title", "Upgrade Which Skill?"), anchor: "center", details: true, hides_below: true }
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
    Ui_DimBackdrop(UI_DIM_POPUP * a);
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
        if (Input_UIConfirm() || Input_UIBack() || Mouse_Pressed(mb_left) || Mouse_Pressed(mb_right)) {   // D182: a click of either button
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
    Ui_DimBackdrop(UI_DIM_POPUP * a);
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
    if (gs.ui.mode != UI_MENU) gs.ui.mode = UI_NOTICE;   // R3 note 25: over the open menu (the Controls reset) the menu stays the mode, so it is still there, drawn and paused, when the notice is gone
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
    var pressed = Notice_CanAnswer() && (Input_UIConfirm() || Input_UIBack() || Input_ClickConfirm() || Input_ClickBack());   // D182: a click of either button closes it
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
    Ui_DimBackdrop(UI_DIM_POPUP * a);
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
function Controls_Items(_keys, _capture_row, _msg_row = "", _msg = "", _flash_rows = [], _flash_at = -1) {
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
        if (_flash_at >= 0 && array_contains(_flash_rows, rid)) items[array_length(items) - 1].flash_at = _flash_at;   // R3 note 25: the rows a reset changed blink from this time
    }
    array_push(items, {
        id: "reset", label: Loc_T("controls.reset", "Reset to Defaults"), kind: "button", enabled: true, lines: [], value: "", help: Controls_RowHelp("reset")
    });
    return items;
}

// R3 note 25 (R-097): the ids of the rows whose keys differ between two key tables, in page order. Pure.
function Controls_ChangedRows(_old, _new) {
    var out = [];
    var ids = Binds_RowIds();
    for (var i = 0; i < array_length(ids); i++) {
        var a = (is_struct(_old) && variable_struct_exists(_old, ids[i])) ? variable_struct_get(_old, ids[i]) : [];
        var b = (is_struct(_new) && variable_struct_exists(_new, ids[i])) ? variable_struct_get(_new, ids[i]) : [];
        if (string(a) != string(b)) array_push(out, ids[i]);
    }
    return out;
}

// What the notice after a reset says: keys changed, or nothing to change.
function Controls_ResetText(_changed_count) {
    if (_changed_count > 0) return Loc_T("controls.reset_done", "Keys are back to the defaults.");
    return Loc_T("controls.reset_same", "Keys were already the defaults.");
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

// Hunt 6 UI (D95): "Press a key..." takes every keyboard key, so a pad needs its own way out. With the pad as the last device its Back, Start / X and Y cancel the capture;
// with the keyboard none of them does (the key X is Back's second key and a fine key to bind). Esc and a right click cancel on either.
function Controls_CaptureCancel(_device, _back, _menu, _pause) {
    return _device == "gamepad" && (_back || _menu || _pause);
}

// The row's help line while it waits for a key; the pad's line names the pad's Back button.
function Controls_WaitingText(_label, _device) {
    if (_device == "gamepad") return Loc_T("controls.waiting_pad", "Press the new key for {action}. [k:back] cancels.", { action: _label });
    return Loc_T("controls.waiting", "Press the new key for {action}. Esc cancels.", { action: _label });
}

function ControlsPage_Open(_sp) {
    _sp.controls = { menu: undefined, capture: "", msg_row: "", msg: "", lock: undefined, flash_rows: [], flash_at: -1 };
    var c = _sp.controls;
    c.menu = Ui_MenuNew("controls", Controls_Items(GameSettings_Ensure().keys, ""), {
        on_confirm: ControlsPage_OnConfirm, on_back: ControlsPage_OnBack,
        layout: { title: Loc_T("controls.title", "Controls"), anchor: "center", details: true }
    });
}

function ControlsPage_Refresh(_sp) {
    var c = _sp.controls;
    if (!is_struct(c)) return;
    c.menu.items = Controls_Items(GameSettings_Ensure().keys, c.capture, c.msg_row, c.msg, c.flash_rows, c.flash_at);
}

function ControlsPage_OnConfirm(_m, _i) {
    var sp = GameState_Get().ui.settings_popup;
    var c = sp.controls;
    var rid = _m.items[_i].id;
    if (rid == "reset") {   // R3 note 25 (R-097): ask first (the cursor on No); Yes resets, a notice says what changed and the changed rows blink
        Confirm_Open(Loc_T("controls.reset_ask", "Reset every key to its default?"), ControlsPage_ResetYes, undefined);
        return;
    }
    c.capture = rid;
    c.lock = InputLock_New(CONTROLS_CAPTURE_DELAY_MS);   // the press that chose the row must not be taken as the new key
    c.msg_row = rid;
    c.msg = Controls_WaitingText(Binds_RowLabel(rid), Prompt_Device());
    ControlsPage_Refresh(sp);
}

// Yes to "Reset every key to its default?": the defaults are saved, the notice names the result and the rows that changed are kept to blink once the notice is gone.
function ControlsPage_ResetYes(_data) {
    var sp = GameState_Get().ui.settings_popup;
    var c = is_struct(sp) ? sp.controls : undefined;
    if (!is_struct(c)) return;
    var defaults = Binds_Defaults();
    var changed = Controls_ChangedRows(GameSettings_Ensure().keys, defaults);
    Settings_SetKeys(defaults);
    c.capture = "";
    c.msg_row = "reset";
    c.msg = Controls_ResetText(array_length(changed));
    c.flash_rows = changed;
    c.flash_at = -1;
    SettingsPopup_Refresh();
    ControlsPage_Refresh(sp);
    SFX_PlayUI("ui_confirm");
    Notice_Open(c.msg);
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
        SFX_PlayUI("ui_deny");
    }
    ControlsPage_Refresh(_sp);
    return true;
}

function ControlsPage_Handle(_sp) {
    var c = _sp.controls;
    if (c.flash_at < 0 && array_length(c.flash_rows) > 0 && !Notice_IsOpen()) {   // the notice after a reset is gone: now the changed rows blink
        c.flash_at = current_time;
        ControlsPage_Refresh(_sp);
    }
    if (c.capture != "") {
        if (InputLock_Active(c.lock)) return;
        if (Mouse_Pressed(mb_right) || Controls_CaptureCancel(Prompt_Device(), Input_UIBack(), Input_UIPressed("menu"), Input_UIPressed("pause"))) { ControlsPage_OnKey(_sp, vk_escape); return; }
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
    var bag = sold ? "" : Shop_CarryRefusal(_ch, _row);   // R-104: a row the bag would refuse is dimmed too, and the details say why
    var out = { enabled: true, row: _row, can_buy: (!sold && _gold >= _row.price && bag == ""), label: "", value: "", help: "", lines: [] };
    out.dim = !out.can_buy;
    out.value = sold ? Loc_T("shop.sold_out", "Sold Out") : string(_row.price);
    if (_row.kind == "card") {
        var c = CardDB_Get(_row.id);
        out.label = Card_Name(c);
        out.help = Card_Sentence(c);
        out.lines = Card_Lines(c);
    } else {
        var it = ItemDB_Get(_row.id);
        out.label = it.name;
        out.help = Item_Sentence(it, _ch);
        out.lines = Item_NumberLines(it, _ch);
        out.icon_item = it;
        if (it.type != ITEM_WEAPON && it.type != ITEM_ARMOR && it.type != ITEM_ACCESSORY) array_push(out.lines, { label: Loc_T("shop.lbl.have", "You Have"), value: string(Inv_Count(_ch.inventory, it.id)) });
    }
    array_push(out.lines, { label: Loc_T("shop.lbl.in_stock", "In Stock"), value: string(max(0, _row.qty)) });
    if (bag != "") out.help = ((bag == "owned") ? Loc_T("shop.reason.owned", "Already owned") : Loc_T("shop.reason.full", "Bag full for this item")) + ". " + out.help;
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
        array_push(lines, { label: Loc_T("shop.lbl.sells_for", "Sells For"), value: string(Shop_SellPrice(iid)) });
        array_push(lines, { label: Loc_T("shop.lbl.have", "You Have"), value: string(n) });
        array_push(items, {
            enabled: true, dim: worn, label: it.name + ((n > 1) ? " x" + string(n) : ""), value: worn ? Loc_T("shop.worn", "Worn") : string(Shop_SellPrice(iid)),
            help: Item_Sentence(it, ch), lines: lines, icon_item: it, item_id: iid
        });
    }
    if (array_length(items) <= 0) array_push(items, { enabled: false, label: Loc_T("shop.nothing_to_sell", "Nothing to Sell"), value: "", help: "", lines: [], item_id: -1 });
    return items;
}

function ShopUi_Refresh(_m, _which) {
    var keep = _m.cursor;
    _m.items = (_which == "buy") ? ShopUi_BuyItems() : ShopUi_SellItems();
    Ui_MenuFixCursor(_m, min(keep, array_length(_m.items) - 1));
}

function ShopUi_Title(_name) {
    return _name + "  " + Loc_T("shop.gold", "Gold: {n}", { n: string(Gold_Get()) });
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
        case "equipped": return Loc_T("shop.msg.equipped", "Unequip it first.");
    }
    return Loc_T("shop.msg.cant", "Cannot do that.");
}

function ShopUi_BuyConfirm(_m, _i) {
    var gs = GameState_Get();
    var it = _m.items[_i];
    var r = Shop_Buy(gs.player_ch, Run_Get(), it.row);
    if (!r.ok) {
        SFX_PlayUI("ui_deny");
        ShopUi_Say(r.reason);
        return;
    }
    CardsUi_Commit(r.ch);
    ShopUi_Say("bought", { name: (it.row.kind == "item") ? Item_NameMarked(it.row.id) : it.label, price: string(r.price) }, "buy");   // D178: an item's name in its rarity colour
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
        Confirm_Open(Loc_T("confirm.sell", "Sell {name} for {price}?", { name: Item_NameMarked(def.id), price: string(Shop_SellPrice(it.item_id)) }), ShopUi_SellYes, { menu: _m, item_id: it.item_id });
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
        SFX_PlayUI("ui_deny");
        ShopUi_Say(r.reason);
        return;
    }
    CardsUi_Commit(r.ch);
    ShopUi_Say("sold", { name: Item_NameMarked(_item_id), price: string(r.gold) }, "sell");
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
    for (var i = 0; i < array_length(lines); i++) tw = max(tw, Ui_LineWidth(lines[i]));
    tw = min(tw + 8 * p, mt.gw - 2 * mt.margin);
    var th = array_length(lines) * mt.line_h + (array_length(lines) - 1) * p + 6 * p;
    var mx0 = round((mt.gw - tw) / 2);
    var my0 = mt.gh - mt.margin - th;
    Ui_DrawFrame(mx0, my0, tw, th, _alpha, p);
    for (var j = 0; j < array_length(lines); j++) {
        var col = (j == 0 || array_length(lines) == 1) ? UI_C_LIGHTEST : UI_C_LIGHT;   // the information first, the merchant's line under it in the accent colour
        Ui_LineDraw(mx0 + 4 * p, my0 + 3 * p + j * (mt.line_h + p), lines[j], tw - 8 * p, col);
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
    Ui_DimBackdrop(UI_DIM_SCREEN * a);
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

// R-109: when the gold box is drawn, by the screen state alone: only over the bare map (or a dialogue), never under a menu, a level-up or card screen (their panels cover the corner it stands in).
function Hud_GoldShown(_mode, _room, _cutscene) {
    if (_room == rm_start || _room == rm_cutscene) return false;
    if (_mode != UI_NONE && _mode != UI_DIALOGUE) return false;
    return !_cutscene;
}

function Hud_DrawGold() {
    if (!Run_IsActive()) return;
    var gs = GameState_Get();
    if (!Hud_GoldShown(gs.ui.mode, room, variable_struct_exists(gs.ui, "cutscene_active") && gs.ui.cutscene_active)) return;
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

// ---- the rarity gem (D178): a 3 x 3 diamond at the top-right corner of a Rare or Epic item's icon. 'g' gold, 'd' dark (the corners, so the gold reads on any picture), 'l' the
// lightest gold. Rare: a gold plus on dark corners. Epic: the same, then (the second frame, every 300 ms) a pale star: the whole 3 x 3 in the light gold with the centre gold.
function Rarity_GemFrame(_now = undefined) {
    var t = is_undefined(_now) ? Rarity_Clock() : _now;
    return (t div 300) mod 2;
}

// The gem's 3 rows of 3 characters for the rarity and frame (0 or 1); no rows for Common.
function Rarity_GemRows(_r, _frame) {
    if (_r < 2) return [];
    if (_r >= 3 && _frame == 1) return ["lll", "lgl", "lll"];
    return ["dgd", "ggg", "dgd"];
}

function Rarity_GemColor(_ch) {
    if (_ch == "g") return UI_C_MERCHANT_GOLD;
    if (_ch == "l") return UI_C_RARITY_EPIC;
    return UI_C_DARKEST;
}

// Draws the gem of a _size pixel icon whose top-left is (_x, _y): its top-right corner sits on the icon's top-right corner; one gem cell is one pixel of the 16 x 16 icon picture
// (a whole number of GUI units, at least 1), so the gem is about a fifth of the icon wide.
function Rarity_DrawGem(_x, _y, _size, _r, _alpha = 1) {
    var rows = Rarity_GemRows(_r, Rarity_GemFrame());
    if (array_length(rows) <= 0) return;
    var u = max(1, floor((_size + 8) / 16));
    var gx = _x + _size - 3 * u;
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) Ui_Box(gx + c * u, _y + r * u, gx + (c + 1) * u, _y + (r + 1) * u, Rarity_GemColor(string_char_at(rows[r], c + 1)));
    }
    draw_set_alpha(a0);
}

// Draws the icon of an item in a square of _size pixels (GUI units) at (_x, _y), with its rarity gem on the top-right corner (Rare and Epic).
function Item_DrawIcon(_item, _x, _y, _size, _alpha = 1) {
    var ic = Item_IconSprite(_item);
    var rar = (is_struct(_item) && variable_struct_exists(_item, "id")) ? Item_Rarity(_item.id) : 1;
    if (ic.spr != noone) {
        var sc = _size / max(1, max(sprite_get_width(ic.spr), sprite_get_height(ic.spr)));
        draw_sprite_ext(ic.spr, ic.sub, _x, _y, sc, sc, 0, c_white, _alpha);
        Rarity_DrawGem(_x, _y, _size, rar, _alpha);
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
    Rarity_DrawGem(_x, _y, _size, rar, _alpha);
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

// D182: sets a volume row to _v (0..1, clamped) in the settings struct _p; true when it changed. Any other row is refused.
function Settings_SetValue(_p, _id, _v) {
    var field = "";
    switch (_id) {
        case "vol_ui": field = "audio_ui"; break;
        case "vol_sfx": field = "audio_sfx"; break;
        case "vol_bgm": field = "audio_bgm"; break;
        default: return false;
    }
    var nv = clamp(round(_v * 100) / 100, 0, 1);
    var old = variable_struct_get(_p, field);
    variable_struct_set(_p, field, nv);
    return abs(nv - old) > 0.0001;
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
    var t1 = Loc_T("settings.keep.title", "Keep This Setting?");
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
    Ui_DimBackdrop(UI_DIM_POPUP * _a);
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

// Hunt 6 UI (D140): the prompt takes an answer only once the last change is KEEP_THIS_ANSWER_LOCK_MS old and the window request has finished, so the second
// press or click of a double click (which made the change) never keeps a window that has not even changed yet. Back / revert is always quick.
#macro KEEP_THIS_ANSWER_LOCK_MS 400

function KeepThis_DisplayBusy() {
    return variable_global_exists("display") && is_struct(global.display) && is_struct(global.display.req);
}

function KeepThis_AnswerReady(_since_ms, _now, _display_busy) {
    return !_display_busy && _now - _since_ms >= KEEP_THIS_ANSWER_LOCK_MS;
}

// A click answers only inside the prompt's box (_rect: where it was last drawn; w = 0 means not drawn yet).
function KeepThis_ClickOk(_rect, _mx, _my) {
    return _rect.w > 0 && _mx >= _rect.x && _mx < _rect.x + _rect.w && _my >= _rect.y && _my < _rect.y + _rect.h;
}

// While the prompt is up the page answers only to it: Confirm (or a click on the box) keeps, Back (or the menu key, a right click) puts the window back, time does the same.
function KeepThis_Step(_sp) {
    if (KeepThis_Tick()) { SettingsPopup_Refresh(); return; }
    if (current_time - global.keep_this.lock_ms < UI_INPUT_LOCK_MS) return;   // the press that made the change
    var ready = KeepThis_AnswerReady(global.keep_this.lock_ms, current_time, KeepThis_DisplayBusy());
    var click = false;
    if (ready && Mouse_Pressed(mb_left)) {
        var mp = Ui_MousePos();
        click = KeepThis_ClickOk(variable_global_exists("keep_this_rect") ? global.keep_this_rect : { x: -1, y: -1, w: 0, h: 0 }, mp.x, mp.y);
    }
    if (ready && (Input_UIConfirm() || click)) {
        SFX_PlayUI("ui_confirm");
        KeepThis_Confirm();
        SettingsPopup_Refresh();
    } else if (Input_UIBack() || Input_UIPressed("menu") || Input_UIPressed("pause") || Mouse_Pressed(mb_right)) {
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

    var r_ts = Settings_Row("text_speed", Loc_T("settings.row.text_speed", "Text Speed"), "choice",
        Settings_TextSpeedText(ts), Loc_T("settings.help.text_speed", "How fast dialogue text appears."));
    r_ts.measure = [Settings_TextSpeedText(0), Settings_TextSpeedText(1), Settings_TextSpeedText(2)];
    array_push(r_ts.lines, { label: Loc_T("settings.line.cps", "Chars per Sec"), value: string(round(UI_DIALOGUE_CHARS_PER_SEC * Settings_TextSpeedMul(ts))) });
    array_push(items, r_ts);

    var r_sh = Settings_Row("shake", Loc_T("settings.row.shake", "Screen Shake"), "choice",
        (_p.screen_shake != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.shake", "Screen shake when a hit lands: on or off."));
    r_sh.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_sh);

    var r_rm = Settings_Row("rumble", Loc_T("settings.row.rumble", "Rumble"), "choice",
        (_p.rumble != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.rumble", "Short controller vibration on Perfect hits, BREAK, big hits and defeat."));
    r_rm.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_rm);

    var r_qa = Settings_Row("qte_assist", Loc_T("settings.row.qte_assist", "Timing Assist"), "choice",
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
        Loc_T("settings.help.scale", "How many times the picture is enlarged. Windowed mode only. You are asked to keep a change."));
    r_sc.enabled = windowed;
    r_sc.measure = [string(DISPLAY_SCALE_MAX) + "x", Loc_T("settings.value.auto", "Auto")];
    var wsz = Display_WindowSizeForScale(_p.display_scale);
    array_push(r_sc.lines, { label: Loc_T("settings.line.window_size", "Window Size"), value: string(wsz.w) + " x " + string(wsz.h) });
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
        on_confirm: SettingsMenu_OnConfirm, on_adjust: SettingsMenu_OnAdjust, on_slide: SettingsMenu_OnSlide, on_back: SettingsMenu_OnBack,
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

// D182: the mouse set a volume slider to _v (0..1): live and saved at once, like a left / right step.
function SettingsMenu_OnSlide(_m, _i, _v) {
    var s = GameSettings_Copy(GameSettings_Ensure());
    if (!Settings_SetValue(s, _m.items[_i].id, _v)) return false;
    GameSettings_Commit(s, true, false);
    SettingsPopup_Refresh();
    return true;
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
    if (_draw_backdrop) Ui_DimBackdrop(UI_DIM_POPUP * a);
    if (is_struct(sp.controls)) Ui_MenuDraw(sp.controls.menu, a);
    else Ui_MenuDraw(sp.menu, a);
    KeepThis_Draw(a);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// --------------------
// TITLE MENU (D0 pilot on the UI framework; D175: profiles and three save files)
// --------------------
// obj_start_controller keeps `state` ("main" | "settings" | "boot_logo" | "splash" | "cutscene") and holds the menu stack in title_stk: [title].
// The rows (D175): Continue (the active profile's last played save file), New Game (the first empty save file, or a picker "Overwrite which save file?" when all
// three are used), Load Game (a picker of the three save files), Settings, Quit. New Game starts the run on Normal (D35: one difficulty only) after the seed pick.
function Title_Pad2(_n) {
    return ((_n < 10) ? "0" : "") + string(_n);
}

// "Save 1" .. "Save 3".
function Title_SlotName(_slot) {
    return Loc_T("save.slot.name", "Save {n}", { n: string(_slot + 1) });
}

// A save's stamp as "2026-10-16 14:05"; "-" when the file has none (a datetime of a run file is a real, -1 when missing).
function Title_FormatSaved(_dt) {
    if (!is_real(_dt) || _dt <= 0) return "-";
    return string(date_get_year(_dt)) + "-" + Title_Pad2(date_get_month(_dt)) + "-" + Title_Pad2(date_get_day(_dt)) + " " + Title_Pad2(date_get_hour(_dt)) + ":" + Title_Pad2(date_get_minute(_dt));
}

// What the title needs to know about a profile's save files (the active one by default): { pid, cont (the Continue target, -1 = none), first_empty (-1 = all used),
// any (some file exists, even a damaged one: Load Game is on), slots (Slots_Summary) }. Reads the files.
function Title_State(_pid = undefined) {
    var pid = is_undefined(_pid) ? Profiles_Active() : _pid;
    var sl = Slots_Summary(pid);
    var any = false;
    var first = -1;
    for (var i = 0; i < array_length(sl); i++) {
        if (sl[i].exists) any = true;
        else if (first < 0) first = sl[i].slot;
    }
    return { pid: pid, cont: Slots_ContinueTarget(pid), first_empty: first, any: any, slots: sl };
}

function Title_MainItems(_can_continue, _can_load) {
    return [
        { id: "continue", label: Loc_T("menu.main.option.continue", "Continue"), kind: "button", enabled: _can_continue },   // C1 (D46): Continue run; D175: the last played save file
        { id: "new", label: Loc_T("menu.main.option.0", "New Game"), kind: "button", enabled: true },
        { id: "load", label: Loc_T("menu.main.option.1", "Load Game"), kind: "button", enabled: _can_load },
        { id: "settings", label: Loc_T("menu.main.option.2", "Settings"), kind: "button", enabled: true },
        { id: "exit", label: Loc_T("menu.main.option.3", "Quit Game"), kind: "button", enabled: true }
    ];
}

// New Game's plan from the first empty save file (-1 = none): { kind: "start", slot } or { kind: "overwrite", slot: -1 } (the picker asks which file to give up).
function Title_NewPlan(_first_empty) {
    if (_first_empty >= 0) return { kind: "start", slot: _first_empty };
    return { kind: "overwrite", slot: -1 };
}

// The card of the Continue target's run (D128: read, never applied).
function Title_CardOf(_st) {
    return (_st.cont >= 0) ? Title_CardLoad(Slots_PathOf(_st.pid, _st.cont)) : Title_CardNone();
}

function Title_Build(_c) {
    _c.title_stk = Ui_StackNew();
    var st = Title_State();
    var m = Ui_MenuNew("title", Title_MainItems(st.cont >= 0, st.any), {
        owner: _c, on_confirm: Title_OnConfirm,
        layout: { anchor: "bottom", y_frac: 0.62, center: true }
    });
    Ui_MenuFixCursor(m, (st.cont >= 0) ? 0 : 1);   // review 1: with a run saved the cursor starts on Continue, else on New Game
    Ui_StackPush(_c.title_stk, m);
    _c.title_refresh = false;
    _c.title_seed = undefined;   // D152: the seed entry screen (a SeedEntry struct while it is open)
    _c.title_card = Title_CardOf(st);   // D128: read, never applied
}

// Language or save files may have changed since the labels were made.
function Title_Refresh(_c) {
    var m = _c.title_stk.menus[0];
    var st = Title_State();
    m.items = Title_MainItems(st.cont >= 0, st.any);
    if (variable_instance_exists(_c, "title_cursor_reset") && _c.title_cursor_reset) {   // another profile: the cursor starts where a fresh title would put it
        Ui_MenuFixCursor(m, (st.cont >= 0) ? 0 : 1);
        _c.title_cursor_reset = false;
    } else {
        Ui_MenuFixCursor(m, m.cursor);
    }
    _c.title_refresh = false;
    _c.title_card = Title_CardOf(st);
}

// ---- save files: the Load Game picker and the overwrite picker (D175) ----
// The rows of a picker from Slots_Summary entries. _mode "load": an empty file is greyed; "overwrite": every file is a row you can pick. A file this build cannot read
// (newer, old, damaged) reads "Cannot load" and can still be selected, so it can be deleted. { id, slot, label, value, status, enabled, dim, help, lines }.
function Title_SlotRows(_sums, _mode) {
    var rows = [];
    for (var i = 0; i < array_length(_sums); i++) {
        var sm = _sums[i];
        var row = { id: "slot_" + string(sm.slot), slot: sm.slot, label: Title_SlotName(sm.slot), value: "", status: sm.status, kind: "button", enabled: true, dim: false, help: "", lines: [], hint: "" };
        if (sm.status == "empty") {
            row.value = Loc_T("save.slot.empty", "Empty");
            row.enabled = (_mode != "load");
            row.dim = true;
            row.help = Loc_T("save.slot.help_empty", "No run is saved in this file.");
        } else if (sm.status == "ok") {
            var cname = DB_PlayerClass(sm.class_id).name;
            row.value = (sm.level >= 0) ? Loc_T("tab.hist.row", "{cls} Lv {n}", { cls: string(cname), n: string(floor(sm.level)) }) : string(cname);
            row.help = (_mode == "overwrite") ? Loc_T("save.slot.help_over", "A new game here replaces this run.") : Loc_T("save.slot.help_load", "Pick up this run where you left it.");
            if (sm.floor >= 0) array_push(row.lines, { label: Loc_T("tab.lbl.floor", "Floor"), value: string(floor(sm.floor)) });
            if (sm.run_time_ms >= 0) array_push(row.lines, { label: Loc_T("title.card.time", "Time"), value: Title_FormatTime(sm.run_time_ms) });
            array_push(row.lines, { label: Loc_T("save.lbl.saved", "Last Saved"), value: Title_FormatSaved(sm.saved_at) });
        } else {
            row.value = Loc_T("save.slot.cant", "Cannot load");
            row.dim = true;
            row.help = Run_ContinueFailText(sm.status);
        }
        array_push(rows, row);
    }
    return rows;
}

// Opens a picker above the title menu: "load" (Load Game) or "overwrite" (New Game with all three files used). The cursor starts on the first row you can pick.
function Title_PickerOpen(_c, _mode) {
    var st = Title_State();
    var m = Ui_MenuNew("slots_" + _mode, Title_SlotRows(st.slots, _mode), {
        owner: _c, on_confirm: Title_PickerConfirm, data: { mode: _mode },
        layout: { title: (_mode == "overwrite") ? Loc_T("save.overwrite.title", "Overwrite which save file?") : Loc_T("menu.main.option.1", "Load Game"), anchor: "center", details: true, hides_below: true }
    });
    Ui_MenuFixCursor(m, 0);
    Ui_StackPush(_c.title_stk, m);
    return m;
}

// The screens above the title with their own key line: the two save file pickers and the profile screen.
function Title_IsPicker(_m) {
    return is_struct(_m) && is_struct(_m.data) && variable_struct_exists(_m.data, "mode") && (_m.id == "slots_load" || _m.id == "slots_overwrite" || _m.id == "profiles");
}

// Loads a save file: it becomes the active one (what autosaves write to) and the run is entered. A file this build cannot read says why. Returns true when the load began.
function Title_LoadSlot(_slot) {
    Slot_SetActive(_slot);
    var cont = Run_Continue();
    if (!cont.ok) Notice_Open(Run_ContinueFailText(cont.status));
    return cont.ok;
}

function Title_PickerConfirm(_m, _i) {
    var c = _m.owner;
    var row = _m.items[_i];
    if (_m.data.mode == "overwrite") {
        Confirm_Open(Loc_T("save.overwrite.ask", "Overwrite Save {n}? The run in it will be lost.", { n: string(row.slot + 1) }), Title_OverwriteYes, { c: c, slot: row.slot });
        return;
    }
    if (row.status != "ok") {
        Notice_Open(Run_ContinueFailText(row.status));
        return;
    }
    Title_LoadSlot(row.slot);
}

// Yes to "Overwrite Save n?": the file is given up when the run really starts (Title_NewGameGo), so Back from the seed pick loses nothing.
function Title_OverwriteYes(_d) {
    _d.c.title_new_slot = _d.slot;
    _d.c.title_new_wipe = true;
    Title_SeedChoiceOpen(_d.c);
}

// The delete key on a Load Game row: asks Yes / No (D175). An empty file has nothing to delete. Returns true when it asked.
function Title_PickerDeleteAsk(_c, _m) {
    if (!Title_IsPicker(_m) || _m.data.mode != "load" || array_length(_m.items) <= 0) return false;
    var row = _m.items[clamp(_m.cursor, 0, array_length(_m.items) - 1)];
    if (row.status == "empty") {
        SFX_PlayUI("ui_deny");
        return false;
    }
    Confirm_Open(Loc_T("save.delete.ask", "Delete Save {n}? The run in it will be lost.", { n: string(row.slot + 1) }), Title_DeleteYes, { c: _c, m: _m, slot: row.slot });
    return true;
}

// Yes: the file goes (a run in it counts as abandoned in the history); the picker shows the new state, or closes when nothing is left to load.
function Title_DeleteYes(_d) {
    Slot_Delete(Profiles_Active(), _d.slot);
    var st = Title_State();
    _d.c.title_refresh = true;
    if (!st.any) {
        Ui_StackBack(_d.c.title_stk);
        return;
    }
    _d.m.items = Title_SlotRows(st.slots, _d.m.data.mode);
    Ui_MenuFixCursor(_d.m, _d.m.cursor);
}

// The keys only the pickers have, before the menu steps: the delete key (Q / the pad's LB), or a right click on a row (a right click elsewhere is Back); on Load Game and on the
// profile screen. True when it was used.
function Title_PickerKeys(_c, _m) {
    if (!Title_IsPicker(_m) || (_m.data.mode != "load" && _m.data.mode != "profiles") || current_time - _m.lock_ms < UI_INPUT_LOCK_MS) return false;
    var prof = (_m.data.mode == "profiles");
    if (Input_Pressed("tab_prev")) return prof ? Title_ProfileDeleteAsk(_c, _m) : Title_PickerDeleteAsk(_c, _m);
    if (Mouse_Pressed(mb_right)) {
        var mp = Ui_MousePos();
        var hv = Ui_HoverIndex(_m.rects, mp.x, mp.y);
        if (hv >= 0) {
            _m.cursor = hv;
            return prof ? Title_ProfileDeleteAsk(_c, _m) : Title_PickerDeleteAsk(_c, _m);
        }
    }
    return false;
}

// New Game: the first empty save file takes the run, with no question; with all three used the overwrite picker asks which one to give up (and then Yes / No). D152: the
// seed pick follows; the title fades out after it (Title_NewGameGo), then the run (or the intro cutscene) is requested.
function Title_NewPress(_c, _m) {
    var plan = Title_NewPlan(Title_State().first_empty);
    _c.title_new_slot = -1;
    _c.title_new_wipe = false;
    if (plan.kind == "start") {
        _c.title_new_slot = plan.slot;
        Title_SeedChoiceOpen(_c);
    } else {
        Title_PickerOpen(_c, "overwrite");
    }
}

// Continue: the last played save file of the active profile.
function Title_ContinuePress(_c) {
    var t = Slots_ContinueTarget();
    if (t < 0) {
        SFX_PlayUI("ui_deny");
        return false;
    }
    return Title_LoadSlot(t);
}

function Title_OnConfirm(_m, _i) {
    var c = _m.owner;
    var rid = _m.items[_i].id;
    switch (rid) {
        case "continue":   // C1 (D46): Continue run
            Title_ContinuePress(c);
            break;
        case "new":
            Title_NewPress(c, _m);
            break;
        case "load":
            Title_PickerOpen(c, "load");
            break;
        case "settings":
            SettingsPopup_Open("title");
            c.state = "settings";
            break;
        case "exit": game_end(); break;
    }
}

// The keys of the screen on top of the title, as groups ("[k:confirm] Load"): one framed line in the lower left corner (clear of the build id in the lower right) when they
// fit side by side, else one group to a row, so a key never wraps away from its word. Load Game also names the delete key.
function Title_HintGroups(_m) {
    if (!is_struct(_m)) return [];
    var back = Loc_T("tab.hint.back", "[k:back] Back");
    if (_m.id == "slots_load") return [Loc_T("save.hint.load", "[k:confirm] Load"), Loc_T("save.hint.delete", "[k:tab_prev] Delete"), back];
    if (_m.id == "slots_overwrite") return [Loc_T("save.hint.overwrite", "[k:confirm] Overwrite"), back];
    if (_m.id == "profiles") {
        var row = (array_length(_m.items) > 0) ? _m.items[clamp(_m.cursor, 0, array_length(_m.items) - 1)] : undefined;
        if (is_struct(row) && row.pid < 0) return [Loc_T("profile.hint.create", "[k:confirm] Create"), back];
        return [Loc_T("profile.hint.switch", "[k:confirm] Switch"), Loc_T("save.hint.delete", "[k:tab_prev] Delete"), back];
    }
    return [];
}

function Title_HintJoin(_groups, _sep) {
    var out = "";
    for (var i = 0; i < array_length(_groups); i++) out += ((i > 0) ? _sep : "") + _groups[i];
    return out;
}

// The key line for a list of groups: { txt, lay, inner_w, rect } (rect.w = 0 and no text without groups).
function Title_HintPlanOf(_groups) {
    var plan = { txt: "", lay: undefined, inner_w: 0, rect: { x: 0, y: 0, w: 0, h: 0 } };
    if (array_length(_groups) <= 0) return plan;
    var mt = Ui_Metrics();
    var p = mt.p;
    var idr = Build_IdRect();
    plan.inner_w = max(8 * p, idr.x - 2 * mt.margin - 4 * p - 8 * p);
    plan.txt = Title_HintJoin(_groups, "    ");
    plan.lay = Prompt_RichLayout(plan.txt, plan.inner_w);
    if (plan.lay.lines > 1) {
        plan.txt = Title_HintJoin(_groups, chr(10));
        plan.lay = Prompt_RichLayout(plan.txt, plan.inner_w);
    }
    var lw = 0;
    for (var i = 0; i < array_length(plan.lay.line_w); i++) lw = max(lw, plan.lay.line_w[i]);
    var w = lw + 8 * p;
    var h = plan.lay.h + 8 * p;
    plan.rect = { x: mt.margin, y: mt.gh - mt.margin - h, w: w, h: h };
    return plan;
}

// The key line of the screen on top of the title.
function Title_HintPlan(_c, _m) {
    return Title_HintPlanOf(Title_HintGroups(_m));
}

// A picker keeps clear of the key line and of the build id: the list with its details below it, centred between the top margin and the key line, when that fits; else (a big
// text size) the details stand beside the list, in the same band. Called before the draw; the layout it sets is what the draw uses.
function Title_PickerFit(_c, _m) {
    if (!Title_IsPicker(_m)) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var L = _m.layout;
    var hp = Title_HintPlan(_c, _m);
    var top_y = mt.margin;
    var bot_y = ((hp.rect.w > 0) ? hp.rect.y : mt.gh - mt.margin) - mt.margin;
    var avail = bot_y - top_y;
    L.details_pos = "below";   // measured first as the stacked layout
    L.x_anchor = "center";
    L.panel_w = 0;
    L.y_top = -1;
    L.det_w = 0;
    L.det_top = -1;
    L.det_h = -1;
    L.max_h = 0;
    var mm = Ui_MenuMeasure(_m, mt);
    var n = array_length(_m.items);
    var chrome = 8 * p + ((L.title != "") ? (mt.line_h + 3 * p) : 0);
    var below_h = chrome + n * mt.row_h + ((mm.det_h > 0) ? mt.margin + mm.det_h : 0);
    if (below_h <= avail) {
        L.y_top = top_y + round((avail - below_h) / 2);
        return;
    }
    var mc = Ui_MenuMeasureRowsFresh(_m, mt);
    var total_w = mt.gw - 3 * mt.margin;
    var half_w = floor(total_w * 0.5 / p) * p;
    var z = { mt: mt, list_w: half_w, det_w: total_w - half_w };
    var wd = TabMenu_Widths(z, Ui_MenuListNeed(mc, p), mc.det_need);
    var det_need_h = 0;   // the tallest details text at the narrower width it has beside the list
    for (var di = 0; di < n; di++) det_need_h = max(det_need_h, Ui_DetailsHeight(wd.det_w, _m.items[di].help, variable_struct_exists(_m.items[di], "lines") ? _m.items[di].lines : [], 1));
    var need_h = max(chrome + n * mt.row_h, det_need_h);
    var h = min(avail, need_h);
    L.details_pos = "right";
    L.x_anchor = "left";
    L.panel_w = wd.list_w;
    L.y_top = top_y + round((avail - h) / 2);
    L.max_h = h;
    L.det_w = wd.det_w;
    L.det_top = L.y_top;
    L.det_h = h;
}

// Draws that line; the rectangle is kept in _c.title_hint_rect for -shots.
function Title_DrawKeyPlan(_hp, _a) {
    var p = Ui_Metrics().p;
    var r = _hp.rect;
    Ui_DrawFrame(r.x, r.y, r.w, r.h, _a, p);
    Prompt_RichDraw(r.x + 4 * p, r.y + 4 * p, _hp.txt, _hp.inner_w, UI_C_LIGHT, fa_left, _a);
    draw_set_alpha(1);
}

function Title_DrawHints(_c) {
    _c.title_hint_rect = { x: 0, y: 0, w: 0, h: 0 };
    var top = Ui_StackTop(_c.title_stk);
    var hp = Title_HintPlan(_c, top);
    if (hp.txt == "") return;
    var a = Ui_MenuAlpha(top, current_time);
    if (a <= 0) return;
    _c.title_hint_rect = hp.rect;
    Title_DrawKeyPlan(hp, a);
}

// ---- D175: the name entry (a new profile's name) ----
// A name is 1..PROFILE_NAME_MAX characters from A-Z, 0-9 and space (no space first, none twice in a row); the entry starts on a suggestion ("Profile 2") that the first typed
// character or Backspace replaces. Keys: the letter and digit keys type, Backspace (or LB) deletes, Enter finishes, Esc cancels; an on-screen grid (9 columns of letters and digits,
// then Space / Delete / OK) is for the pad and the mouse: the d-pad moves, Confirm presses the cell. This model is pure; the screen is Title_NameStep / Title_NameDraw.
#macro NAME_GRID_COLS 9
#macro NAME_GRID_ROWS 4   // rows of letters and digits; one more row holds the three buttons

// The letters and digits of the grid, in order (built once).
function NameEntry_Chars() {
    if (!variable_global_exists("name_chars")) {
        var t = "";
        for (var i = 0; i < 26; i++) t += chr(65 + i);
        for (var d = 0; d < 10; d++) t += string(d);
        global.name_chars = t;
    }
    return global.name_chars;
}

function NameEntry_New(_text) {
    return { text: string(_text), fresh: (string(_text) != ""), cx: 0, cy: 0 };
}

function NameEntry_CharOk(_ch) {
    if (!is_string(_ch) || string_length(_ch) != 1) return false;
    var o = ord(_ch);
    return (o >= 65 && o <= 90) || (o >= 48 && o <= 57) || o == 32;
}

// Adds one character; false when it is not allowed (not a letter, digit or space, a space first or doubled, the name already full).
function NameEntry_Type(_e, _ch) {
    if (!NameEntry_CharOk(_ch)) return false;
    if (_e.fresh) {
        _e.text = "";
        _e.fresh = false;
    }
    var n = string_length(_e.text);
    if (n >= PROFILE_NAME_MAX) return false;
    if (_ch == " " && (n == 0 || string_char_at(_e.text, n) == " ")) return false;
    _e.text += _ch;
    return true;
}

// Takes the last character away (the whole suggestion, while it is still the suggestion). false when there was nothing to take.
function NameEntry_Backspace(_e) {
    if (_e.fresh) {
        _e.text = "";
        _e.fresh = false;
        return true;
    }
    var n = string_length(_e.text);
    if (n <= 0) return false;
    _e.text = string_delete(_e.text, n, 1);
    return true;
}

// The name that would be made: trimmed, at most 12 characters (Profiles_CleanName).
function NameEntry_Value(_e) {
    return Profiles_CleanName(_e.text);
}

function NameEntry_CanConfirm(_e) {
    return NameEntry_Value(_e) != "";
}

// The letter or digit of a grid cell ("" outside the letter rows).
function NameEntry_CellChar(_cx, _cy) {
    if (_cy < 0 || _cy >= NAME_GRID_ROWS || _cx < 0 || _cx >= NAME_GRID_COLS) return "";
    return string_char_at(NameEntry_Chars(), _cy * NAME_GRID_COLS + _cx + 1);
}

// The last row's three buttons each take a third of the columns.
function NameEntry_ButtonAt(_cx) {
    var b = clamp(_cx div 3, 0, 2);
    return (b == 0) ? "space" : ((b == 1) ? "delete" : "ok");
}

// The grid cursor moves and wraps (columns 0..8, rows 0..4).
function NameEntry_Move(_e, _dx, _dy) {
    _e.cx = (_e.cx + _dx + NAME_GRID_COLS) mod NAME_GRID_COLS;
    _e.cy = (_e.cy + _dy + NAME_GRID_ROWS + 1) mod (NAME_GRID_ROWS + 1);
}

// What pressing the cell under the cursor does: { kind: "char" (ch), "space", "delete" or "ok", ch }.
function NameEntry_Press(_e) {
    if (_e.cy >= NAME_GRID_ROWS) return { kind: NameEntry_ButtonAt(_e.cx), ch: "" };
    return { kind: "char", ch: NameEntry_CellChar(_e.cx, _e.cy) };
}

function Title_NameOf(_c) {
    return (variable_instance_exists(_c, "title_name") && is_struct(_c.title_name)) ? _c.title_name : undefined;
}

// Opens the entry above the profile screen, on the suggestion "Profile N" (N = the id the new profile will get, plus one).
function Title_NameOpen(_c) {
    var pid = 0;
    while (is_struct(Profiles_FindEntry(pid))) pid++;
    _c.title_name = { e: NameEntry_New(Profiles_DefaultName(pid)), t: current_time, msg: false, rep: { v: Ui_RepeatNew(), h: Ui_RepeatNew() }, cells: [] };
}

// Makes the profile and switches to it (a new profile starts fresh: no Codex, no history, the story from the beginning); the entry and the profile screen close. An empty name
// is refused with a line saying why. true when it made one.
function Title_NameConfirm(_c) {
    var n = Title_NameOf(_c);
    if (!is_struct(n)) return false;
    if (!NameEntry_CanConfirm(n.e)) {
        n.msg = true;
        SFX_PlayUI("ui_deny");
        return false;
    }
    var pid = Profiles_Create(NameEntry_Value(n.e));
    if (pid < 0) {
        n.msg = true;
        SFX_PlayUI("ui_deny");
        return false;
    }
    Profiles_Switch(pid);
    _c.title_name = undefined;
    _c.title_refresh = true;
    _c.title_cursor_reset = true;
    Ui_StackBack(_c.title_stk);   // the profile screen
    SFX_PlayUI("ui_confirm");
    return true;
}

// Esc: back to the profile screen, nothing made. The profile screen is told its press must not answer it.
function Title_NameCancel(_c) {
    _c.title_name = undefined;
    var top = Ui_StackTop(_c.title_stk);
    if (is_struct(top)) top.lock_ms = current_time;
}

// The character typed this frame by a key (letters through name_a..name_z, digits through the seed digits' keys, Space), "" when none. They are separate actions, so a
// letter that is also a menu key (W A S D Q E Z X I) types its letter here.
function Title_NameTyped() {
    for (var i = 0; i < 26; i++) {
        if (Input_Pressed("name_" + chr(97 + i))) return chr(65 + i);
    }
    for (var d = 0; d < 10; d++) {
        if (Input_Pressed("seed_d" + string(d))) return string(d);
    }
    if (Input_Pressed("name_space")) return " ";
    return "";
}

// One frame of the entry. A typed character wins over everything else that frame (Z, X, Space, W A S D Q are letters here, not Confirm, Back or moves); Enter finishes; Esc, Back
// or a right click cancels; the grid answers the d-pad / arrows (moves), Confirm (presses) and the mouse (hover moves, click presses). The press that opened the entry is ignored.
function Title_NameStep(_c) {
    var n = _c.title_name;
    var e = n.e;
    var snap = Ui_ReadInput();
    var now = current_time;
    var typed = Title_NameTyped();
    var changed = false;
    if (typed != "") {
        if (NameEntry_Type(e, typed)) changed = true;
        else SFX_PlayUI("ui_deny");
    } else {
        if (Input_Pressed("seed_back") || snap.tab < 0) {
            if (NameEntry_Backspace(e)) changed = true;
        }
        var dv = (snap.down ? 1 : 0) - (snap.up ? 1 : 0);
        if (Ui_RepeatStep(n.rep.v, dv, snap.up_p || snap.down_p, now) > 0) { NameEntry_Move(e, 0, dv); changed = true; }
        var dh = (snap.right ? 1 : 0) - (snap.left ? 1 : 0);
        if (Ui_RepeatStep(n.rep.h, dh, snap.left_p || snap.right_p, now) > 0) { NameEntry_Move(e, dh, 0); changed = true; }
        var hv = Ui_HoverIndex(n.cells, snap.mx, snap.my);
        if (snap.mouse_moved && hv >= 0 && (n.cells[hv].cx != e.cx || n.cells[hv].cy != e.cy)) {
            e.cx = n.cells[hv].cx;
            e.cy = n.cells[hv].cy;
            changed = true;
        }
    }
    if (changed) {
        n.msg = false;
        SFX_PlayUI("ui_move");
    }
    if (now - n.t < UI_INPUT_LOCK_MS) return;
    if (Input_Pressed("name_ok")) {
        Title_NameConfirm(_c);
        return;
    }
    if (typed != "") return;
    if (snap.back || snap.rclick) {
        SFX_PlayUI("ui_back");
        Title_NameCancel(_c);
        return;
    }
    var press = snap.confirm;
    if (snap.click) {
        var hc = Ui_HoverIndex(n.cells, snap.mx, snap.my);
        if (hc >= 0) {
            e.cx = n.cells[hc].cx;
            e.cy = n.cells[hc].cy;
            press = true;
        }
    }
    if (!press) return;
    var act = NameEntry_Press(e);
    SFX_PlayUI("ui_confirm");
    switch (act.kind) {
        case "char":
            if (NameEntry_Type(e, act.ch)) n.msg = false;
            break;
        case "space":
            if (NameEntry_Type(e, " ")) n.msg = false;
            break;
        case "delete":
            NameEntry_Backspace(e);
            n.msg = false;
            break;
        case "ok":
            Title_NameConfirm(_c);
            break;
    }
}

// The entry screen: a framed panel with the title, the name field (the suggestion pale, a block after typed text), a line of help (or why Confirm said no) and the grid (the
// cursor's cell lit); the keys stand in a framed line in the lower left corner, as on the other title screens. Measured from Ui_Metrics, so it fits 480 x 432 and the larger
// windows. The rectangles are kept in _c.title_name_rects for -shots.
function Title_NameDraw(_c) {
    var n = _c.title_name;
    var e = n.e;
    var mt = Ui_Metrics();
    var p = mt.p;
    var lh = mt.line_h;
    var a = Ui_AnimT(n.t, current_time);
    var cols = NAME_GRID_COLS;
    var gap = p;
    var cw0 = UI_TextWidth("W") + 4 * p;
    var pw = min(mt.gw - 2 * mt.margin, max(cols * cw0 + (cols - 1) * gap + 12 * p, round(mt.gw * 0.7)));
    var cw = floor((pw - 12 * p - (cols - 1) * gap) / cols);
    var grid_w = cols * cw + (cols - 1) * gap;
    var ch = lh + 2 * p;
    var inner_w = pw - 8 * p;
    var pad = (Prompt_Device() == "gamepad");   // a keyboard types (so its Space, Z, Q are letters here) and has no Pick key; a pad picks cells on the grid
    var info = n.msg ? Loc_T("profile.name.need", "Enter a name.") : (pad ? Loc_T("profile.name.info_pad", "Up to 12 letters. Pick them on the grid.") : Loc_T("profile.name.info_kb", "Up to 12 letters. Backspace deletes, Enter finishes."));
    var info_h = Ui_TextBlockH(info, inner_w);
    var groups = pad ? [Loc_T("profile.name.hint_pick", "[k:confirm] Pick"), Loc_T("save.hint.delete", "[k:tab_prev] Delete"), Loc_T("profile.name.hint_cancel", "[k:back] Cancel")] : [Loc_T("profile.name.hint_cancel", "[k:back] Cancel")];
    var hp = Title_HintPlanOf(groups);
    var field_h = lh + 3 * p;
    var ph = 4 * p + (lh + 3 * p) + 3 * p + field_h + 3 * p + info_h + 3 * p + (NAME_GRID_ROWS + 1) * (ch + gap) + 3 * p;
    var px = round((mt.gw - pw) / 2);
    var avail = hp.rect.y - 2 * mt.margin;
    var py = mt.margin + max(0, round((avail - ph) / 2)) - p * round((1 - a) * 3);
    Ui_DimBackdrop(UI_DIM_POPUP * a);
    Ui_DrawFrame(px, py, pw, ph, a, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(a);
    var x0 = px + 4 * p;
    var yy = py + 4 * p;
    Ui_Text(x0, yy, Loc_T("profile.row.new", "New Profile"), UI_C_LIGHTEST);
    Ui_Box(px + 3 * p, yy + lh + p, px + pw - 3 * p, yy + lh + 2 * p, UI_C_DARK);
    yy += lh + 3 * p + 3 * p;
    var field = { x: x0, y: yy, w: inner_w, h: field_h };
    Ui_Box(field.x, field.y, field.x + field.w, field.y + field.h, UI_C_LIGHTEST);
    Ui_Box(field.x + p, field.y + p, field.x + field.w - p, field.y + field.h - p, UI_C_DARKEST);
    var shown = Ui_FitText(e.text, inner_w - 4 * p - UI_TextWidth("W"));
    var ty = field.y + (field.h - lh) div 2;
    Ui_Text(field.x + 2 * p, ty, shown, e.fresh ? UI_C_LIGHT : UI_C_LIGHTEST);
    if (!e.fresh && string_length(e.text) < PROFILE_NAME_MAX && Title_BlinkOn(current_time - n.t)) {   // the block after typed text: where the next letter goes
        var bx = field.x + 2 * p + UI_TextWidth(shown);
        Ui_Box(bx + p, ty + lh - 2 * p, bx + p + UI_TextWidth("W") - p, ty + lh, UI_C_LIGHTEST);
    }
    yy += field_h + 3 * p;
    Ui_TextBlock(x0, yy, info, inner_w, n.msg ? UI_C_LIGHTEST : UI_C_LIGHT);
    yy += info_h + 3 * p;
    var gx = px + round((pw - grid_w) / 2);
    var cells = [];
    for (var r = 0; r < NAME_GRID_ROWS; r++) {
        for (var c = 0; c < cols; c++) {
            var gcx = gx + c * (cw + gap);
            var gcy = yy + r * (ch + gap);
            var on = (e.cy == r && e.cx == c);
            Ui_Box(gcx, gcy, gcx + cw, gcy + ch, on ? UI_C_LIGHTEST : UI_C_DARK);
            Ui_Box(gcx + p, gcy + p, gcx + cw - p, gcy + ch - p, on ? UI_C_DARK : UI_C_DARKEST);
            Ui_Text(gcx + cw / 2, gcy + (ch - lh) div 2, NameEntry_CellChar(c, r), UI_C_LIGHTEST, fa_center);
            array_push(cells, { x: gcx, y: gcy, w: cw, h: ch, cx: c, cy: r });
        }
    }
    var by = yy + NAME_GRID_ROWS * (ch + gap);
    var bw = floor((grid_w - 2 * gap) / 3);
    var blabels = [Loc_T("profile.name.key_space", "Space"), Loc_T("profile.name.key_delete", "Delete"), Loc_T("profile.name.key_ok", "OK")];
    for (var b = 0; b < 3; b++) {
        var bcx = gx + b * (bw + gap);
        var bon = (e.cy == NAME_GRID_ROWS && NameEntry_ButtonAt(e.cx) == NameEntry_ButtonAt(b * 3));
        Ui_Box(bcx, by, bcx + bw, by + ch, bon ? UI_C_LIGHTEST : UI_C_DARK);
        Ui_Box(bcx + p, by + p, bcx + bw - p, by + ch - p, bon ? UI_C_DARK : UI_C_DARKEST);
        Ui_Text(bcx + bw / 2, by + (ch - lh) div 2, Ui_FitText(blabels[b], bw - 2 * p), UI_C_LIGHTEST, fa_center);
        array_push(cells, { x: bcx, y: by, w: bw, h: ch, cx: b * 3 + 1, cy: NAME_GRID_ROWS });
    }
    n.cells = cells;
    draw_set_alpha(a0);
    Title_DrawKeyPlan(hp, a);
    _c.title_hint_rect = hp.rect;
    _c.title_name_rects = { panel: { x: px, y: py, w: pw, h: ph }, field: field, cells: cells, hint: hp.rect };
}

// ---- D175: the profile screen (switch, create, delete) ----
// A profile's numbers for its row: the active one from memory, any other from its own file (read, never applied). { runs, wins, best_floor }
function Title_ProfileStats(_pid) {
    var pr = (_pid == Profiles_Active()) ? Profile_Get() : Profile_Load(Profiles_PathOf(_pid)).profile;
    return { runs: floor(Save_ToReal(pr.runs_started, 0)), wins: floor(Save_ToReal(pr.wins, 0)), best_floor: floor(Save_ToReal(pr.best_floor, 0)) };
}

// One row per profile (name; "Active" on the one in use; Runs / Wins / Best Floor in the details) and a "New Profile" row while there are fewer than PROFILES_MAX.
function Title_ProfileRows() {
    var list = Profiles_List();
    var act = Profiles_Active();
    var rows = [];
    for (var i = 0; i < array_length(list); i++) {
        var st = Title_ProfileStats(list[i].id);
        array_push(rows, {
            id: "prof_" + string(list[i].id), pid: list[i].id, label: list[i].name, value: (list[i].id == act) ? Loc_T("profile.val.active", "Active") : "",
            status: "profile", kind: "button", enabled: true, dim: false, hint: "",
            help: (list[i].id == act) ? Loc_T("profile.help.active", "The profile in use. Its Codex, run history and story are the ones you see.") : Loc_T("profile.help.other", "Switch to this profile. Its Codex, run history, story and save files come with it."),
            lines: [
                { label: Loc_T("profile.lbl.runs", "Runs"), value: string(st.runs) },
                { label: Loc_T("tab.lbl.wins", "Wins"), value: string(st.wins) },
                { label: Loc_T("tab.lbl.best_floor", "Best Floor"), value: string(st.best_floor) }
            ]
        });
    }
    if (array_length(list) < PROFILES_MAX) {
        array_push(rows, {
            id: "prof_new", pid: -1, label: Loc_T("profile.row.new", "New Profile"), value: "", status: "new", kind: "button", enabled: true, dim: false, hint: "",
            help: Loc_T("profile.help.new", "Start a new profile. Its Codex and run history are empty and the story begins again."), lines: []
        });
    }
    return rows;
}

// The row of the active profile (where the cursor starts).
function Title_ProfileActiveRow(_rows) {
    for (var i = 0; i < array_length(_rows); i++) if (_rows[i].pid == Profiles_Active()) return i;
    return 0;
}

function Title_ProfileOpen(_c) {
    var rows = Title_ProfileRows();
    var m = Ui_MenuNew("profiles", rows, {
        owner: _c, on_confirm: Title_ProfileConfirm, data: { mode: "profiles" },
        layout: { title: Loc_T("profile.title", "Profiles"), anchor: "center", details: true, hides_below: true }
    });
    Ui_MenuFixCursor(m, Title_ProfileActiveRow(rows));
    Ui_StackPush(_c.title_stk, m);
    return m;
}

// Confirm: New Profile opens the name entry; another profile becomes the active one (the title refreshes: its name, what Continue and Load Game can do) and the screen closes.
function Title_ProfileConfirm(_m, _i) {
    var c = _m.owner;
    var row = _m.items[_i];
    if (row.pid < 0) {
        Title_NameOpen(c);
        return;
    }
    if (row.pid != Profiles_Active()) {
        Profiles_Switch(row.pid);
        c.title_cursor_reset = true;
    }
    c.title_refresh = true;
    Ui_StackBack(c.title_stk);
}

// The delete key on a profile row: asks Yes / No. New Profile has nothing to delete. Returns true when it asked.
function Title_ProfileDeleteAsk(_c, _m) {
    if (!is_struct(_m) || _m.id != "profiles" || array_length(_m.items) <= 0) return false;
    var row = _m.items[clamp(_m.cursor, 0, array_length(_m.items) - 1)];
    if (row.pid < 0) {
        SFX_PlayUI("ui_deny");
        return false;
    }
    Confirm_Open(Loc_T("profile.delete.ask", "Delete profile {name}? Its Codex, history and save files are lost.", { name: row.label }), Title_ProfileDeleteYes, { c: _c, m: _m, pid: row.pid });
    return true;
}

// Yes: the profile and its three save files go (deleting the active one makes the first remaining one active, the last one a fresh "Profile 1": the data layer's rules).
function Title_ProfileDeleteYes(_d) {
    Profiles_Delete(_d.pid);
    _d.c.title_refresh = true;
    _d.c.title_cursor_reset = true;
    var rows = Title_ProfileRows();
    _d.m.items = rows;
    Ui_MenuFixCursor(_d.m, Title_ProfileActiveRow(rows));
}

// ---- D175: the Codex and Run History from the title ----
// The Codex pages of the ACTIVE profile (Bestiary, Notes, Run History, Unlocks), read-only, with the Tab menu's own rows, pages and layout (TabCodex_Items / TabCodex_Page /
// TabMenu_FitMenu). A found note does not open its reader here (the reader can answer a note's question, which would write to the profile). Back goes up one level; Back at the
// list closes the screen. c.title_codex = { stk, t } while it is open.
function Title_CodexOf(_c) {
    return (variable_instance_exists(_c, "title_codex") && is_struct(_c.title_codex)) ? _c.title_codex : undefined;
}

function Title_CodexOpen(_c) {
    var stk = Ui_StackNew();
    var m = Ui_MenuNew("title_codex", TabCodex_Items(Profile_Get()), {
        owner: _c, on_confirm: Title_CodexOnConfirm, on_back: Title_CodexOnBack, data: { tab: "title_codex" },
        layout: { title: Loc_T("tab.title.codex", "Codex"), anchor: "center", details: true, details_pos: "right", det_art: true, hides_below: true }
    });
    Ui_MenuFixCursor(m, m.cursor);
    Ui_StackPush(stk, m);
    _c.title_codex = { stk: stk, t: current_time };
}

function Title_CodexOnConfirm(_m, _i) {
    Title_CodexPage(_m.owner, _m.items[_i].id);
}

// Opens one page ("bestiary", "notes", "history", "unlocks") above the list; false when it has no rows (Run History before the first run).
function Title_CodexPage(_c, _kind) {
    var cx = Title_CodexOf(_c);
    if (!is_struct(cx)) return false;
    var page = TabCodex_Page(_kind, Profile_Get());
    if (array_length(page.rows) <= 0) return false;
    var m = TabCodex_MakeMenu(_kind, page);
    m.owner = _c;
    Ui_MenuFixCursor(m, m.cursor);
    Ui_StackPush(cx.stk, m);
    return true;
}

function Title_CodexOnBack(_m, _res) {
    if (_res == "root") Title_CodexClose(_m.owner);
}

function Title_CodexClose(_c) {
    _c.title_codex = undefined;
    _c.title_hint_rect = { x: 0, y: 0, w: 0, h: 0 };
    if (is_struct(_c.title_stk) && array_length(_c.title_stk.menus) > 0) _c.title_stk.menus[0].lock_ms = current_time;   // the press that closed it must not answer the title
}

function Title_CodexStep(_c) {
    var cx = Title_CodexOf(_c);
    Ui_MenuUpdate(Ui_StackTop(cx.stk), cx.stk);
}

// The screen: the dimmed picture, the list or page (fitted into the whole body, as the Tab menu fits it), and the keys in the title's framed line at the lower left.
function Title_CodexDraw(_c) {
    var cx = Title_CodexOf(_c);
    var stk = cx.stk;
    var now = current_time;
    var a = Ui_AnimT(cx.t, now);
    var top = Ui_StackTop(stk);
    var mt = Ui_Metrics();
    var p = mt.p;
    var row = (array_length(top.items) > 0) ? top.items[clamp(top.cursor, 0, array_length(top.items) - 1)] : undefined;
    var groups = [];
    if (is_struct(row) && variable_struct_exists(row, "hint") && row.hint != "") array_push(groups, row.hint);
    array_push(groups, (Ui_StackDepth(stk) > 1) ? Loc_T("tab.hint.back", "[k:back] Back") : Loc_T("tab.hint.close", "[k:back] Close"));
    var hp = Title_HintPlanOf(groups);
    var z = TabMenu_Zones((string_pos("codex_", top.id) == 1) ? top.id : "codex");
    z.body_y = z.tabs_y;   // no tabs header here: the body starts at the top margin and ends above the key line
    z.body_h = hp.rect.y - mt.margin - z.body_y;
    Ui_DimBackdrop(UI_DIM_SCREEN * a);
    if (is_struct(stk.leaving) && Ui_MenuAlpha(stk.leaving, now) <= 0) stk.leaving = undefined;
    TabMenu_FitMenu(top, z, 0);
    Ui_MenuDraw(top, a * Ui_MenuAlpha(top, now));
    if (is_struct(stk.leaving)) {
        TabMenu_FitMenu(stk.leaving, z, 0);
        Ui_MenuDraw(stk.leaving, a * Ui_MenuAlpha(stk.leaving, now));
    }
    Title_DrawKeyPlan(hp, a);
    _c.title_hint_rect = hp.rect;
    draw_set_alpha(1);
}

// Which corner button a point is on ("profile", "codex" or ""), from the rectangles the draw keeps in title_btn; the right and bottom edges are outside, a button that was not
// drawn (width 0) is never hit.
function Title_ButtonHit(_c, _x, _y) {
    var names = ["profile", "codex"];
    for (var i = 0; i < array_length(names); i++) {
        var r = variable_struct_get(_c.title_btn, names[i]);
        if (r.w > 0 && _x >= r.x && _x < r.x + r.w && _y >= r.y && _y < r.y + r.h) return names[i];
    }
    return "";
}

// ---- D175: the corner buttons of the title ----
// Two small framed buttons in the lower left corner, one above the other, clear of the menu column (the name is cut to the room beside it) and of the build id in the lower
// right: Profile (its key "[Q]", the active profile's name under it) and Codex above it (its key "[E]"). A click or the key opens the profile screen / the Codex. The rectangles are
// kept in _c.title_btn for the mouse and -shots.
function Title_DrawButtons(_c) {
    _c.title_btn = { profile: { x: 0, y: 0, w: 0, h: 0 }, codex: { x: 0, y: 0, w: 0, h: 0 } };
    var m = _c.title_stk.menus[0];
    var a = Ui_MenuAlpha(m, current_time);
    if (a <= 0 || m.rect.w <= 0) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var lh = mt.line_h;
    var mp = Ui_MousePos();
    var plabel = Loc_T("profile.btn", "[k:tab_prev] Profile");
    var clabel = Loc_T("codex.btn", "[k:tab_next] Codex");
    var room_w = max(12 * p, m.rect.x - 2 * mt.margin - 8 * p);
    var name = Ui_FitText(Profiles_ActiveName(), room_w);
    var pw = max(Prompt_RichLayout(plabel, 100000).line_w[0], UI_TextWidth(name)) + 8 * p;
    var ph = 2 * lh + p + 8 * p;
    var px = mt.margin;
    var py = mt.gh - mt.margin - ph;
    var cw = Prompt_RichLayout(clabel, 100000).line_w[0] + 8 * p;
    var chh = lh + 8 * p;
    var cx = mt.margin;
    var cy = py - p * 2 - chh;
    _c.title_btn = { profile: { x: px, y: py, w: pw, h: ph }, codex: { x: cx, y: cy, w: cw, h: chh } };
    var hot = Title_ButtonHit(_c, mp.x, mp.y);
    var a0 = draw_get_alpha();
    Ui_DrawFrame(px, py, pw, ph, a, p);
    Ui_DrawFrame(cx, cy, cw, chh, a, p);
    draw_set_alpha(a);
    if (hot == "profile") Ui_Box(px + 2 * p, py + 2 * p, px + pw - 2 * p, py + ph - 2 * p, UI_C_DARK);
    if (hot == "codex") Ui_Box(cx + 2 * p, cy + 2 * p, cx + cw - 2 * p, cy + chh - 2 * p, UI_C_DARK);
    Prompt_RichDraw(px + 4 * p, py + 4 * p, plabel, pw - 8 * p, UI_C_LIGHT, fa_left, a);
    Ui_Text(px + 4 * p, py + 4 * p + lh + p, name, UI_C_LIGHTEST);
    Prompt_RichDraw(cx + 4 * p, cy + 4 * p, clabel, cw - 8 * p, UI_C_LIGHT, fa_left, a);
    draw_set_alpha(a0);
}

// The title's own keys: the Profile button's key (Q, the pad's LB), the Codex button's key (E, RB) or a click on either button. Only on the title menu itself, once it takes input.
// True when one was used.
function Title_ButtonKeys(_c) {
    var m = _c.title_stk.menus[0];
    if (current_time - m.lock_ms < UI_INPUT_LOCK_MS || Ui_MenuAlpha(m, current_time) < 1) return false;
    var which = "";
    if (Input_Pressed("tab_prev")) which = "profile";
    else if (Input_Pressed("tab_next")) which = "codex";
    else if (Mouse_Pressed(mb_left)) {
        var mp = Ui_MousePos();
        which = Title_ButtonHit(_c, mp.x, mp.y);
    }
    if (which == "") return false;
    SFX_PlayUI("ui_confirm");
    if (which == "profile") Title_ProfileOpen(_c);
    else Title_CodexOpen(_c);
    return true;
}

// ---- D152: the seed pick after New Game ----
// A small menu above the title: "Random seed" (first and highlighted every time) or "Enter seed" (the number entry below). Either way the title then
// fades out and the run starts (Title_Step -> Run_BeginNewGame); a picked seed waits in global.run_next_seed for Run_StartNew (after the intro cutscene
// of a first run). Back goes back to the title menu.
function Title_SeedChoiceOpen(_c) {
    var m = Ui_MenuNew("seed_choice", [
        { id: "random", label: Loc_T("seed.choice.random", "Random Seed"), kind: "button", enabled: true },
        { id: "enter", label: Loc_T("seed.choice.enter", "Enter Seed"), kind: "button", enabled: true }
    ], {
        owner: _c, on_confirm: Title_SeedChoiceConfirm,
        layout: { title: Loc_T("seed.choice.title", "Choose a Seed"), anchor: "center", center: true }
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

// The title fades out; Title_Step starts the run when the fade is over. D175: this is where the save file is committed: the chosen one is emptied first when the
// overwrite picker asked for it (the run in it counts as abandoned), then it becomes the active file the run saves to.
function Title_NewGameGo(_c) {
    var slot = variable_instance_exists(_c, "title_new_slot") ? _c.title_new_slot : -1;
    if (slot >= 0) {
        if (variable_instance_exists(_c, "title_new_wipe") && _c.title_new_wipe) Slot_Delete(Profiles_Active(), slot);
        Slot_SetActive(slot);
    }
    _c.title_new_slot = -1;
    _c.title_new_wipe = false;
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
    var mouse_start = false;
    if (snap.wheel != 0) { SeedEntry_Cycle(e, snap.wheel); changed = true; }   // D182: the wheel turns the digit under the cursor (up = up)
    if (snap.click && variable_instance_exists(_c, "title_seed_rects") && now - _c.title_seed_t >= UI_INPUT_LOCK_MS) {   // D182: a click on a cell, an arrow or the Start line
        var hit = Title_SeedHit(_c.title_seed_rects, e, snap.mx, snap.my);
        if (Title_SeedApply(e, hit)) changed = true;
        if (hit.kind == "start") mouse_start = true;
    }
    if (changed) {
        _c.title_seed_msg = false;
        SFX_PlayUI("ui_move");
    }
    if (now - _c.title_seed_t < UI_INPUT_LOCK_MS) return;
    if (snap.confirm || mouse_start) {
        if (SeedEntry_CanConfirm(e)) {
            SFX_PlayUI("ui_confirm");
            global.run_next_seed = SeedEntry_Value(e);
            _c.title_seed = undefined;
            Title_NewGameGo(_c);
        } else {
            SFX_PlayUI("ui_deny");
            _c.title_seed_msg = true;
        }
    } else if (snap.back || snap.rclick) {
        SFX_PlayUI("ui_back");
        _c.title_seed = undefined;
        Ui_StackTop(_c.title_stk).lock_ms = now;
    }
}

// D182: what a click at (_mx, _my) hits on the entry screen, from the rectangles the draw kept (_r: cells, up, down, start): { kind: "cell" (idx = the slot, only slots the cursor can
// reach), "up" / "down" (the arrows beside the cursor's digit), "start" (the Start line) or "" }. Pure.
function Title_SeedHit(_r, _e, _mx, _my) {
    var names = ["up", "down", "start"];
    for (var n = 0; n < 3; n++) {
        var rr = variable_struct_get(_r, names[n]);
        if (rr.w > 0 && _mx >= rr.x && _mx < rr.x + rr.w && _my >= rr.y && _my < rr.y + rr.h) return { kind: names[n], idx: -1 };
    }
    var cmax = SeedEntry_CursorMax(_e);
    for (var i = 0; i < array_length(_r.cells) && i <= cmax; i++) {
        var c = _r.cells[i];
        if (_mx >= c.x && _mx < c.x + c.w && _my >= c.y && _my < c.y + c.h) return { kind: "cell", idx: i };
    }
    return { kind: "", idx: -1 };
}

// The effect of a hit on the entry: a cell moves the cursor, an arrow turns the digit; true when something changed (Start is the caller's).
function Title_SeedApply(_e, _hit) {
    switch (_hit.kind) {
        case "cell":
            var was = _e.cur;
            _e.cur = clamp(_hit.idx, 0, SeedEntry_CursorMax(_e));
            return _e.cur != was;
        case "up": SeedEntry_Cycle(_e, 1); return true;
        case "down": SeedEntry_Cycle(_e, -1); return true;
    }
    return false;
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
    Ui_DimBackdrop(UI_DIM_POPUP * a);
    Ui_DrawFrame(px, py, pw, ph, a, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(a);
    var x0 = px + 4 * p;
    var yy = py + 4 * p;
    Ui_Text(x0, yy, Loc_T("seed.entry.title", "Enter Seed"), UI_C_LIGHTEST);
    Ui_Box(px + 3 * p, yy + lh + p, px + pw - 3 * p, yy + lh + 2 * p, UI_C_DARK);
    yy += lh + 3 * p + 5 * p;
    var rx = px + round((pw - row_w) / 2);
    var cells = [];
    var up_r = { x: 0, y: 0, w: 0, h: 0 };
    var down_r = { x: 0, y: 0, w: 0, h: 0 };
    var start_r = { x: 0, y: 0, w: 0, h: 0 };
    for (var i = 0; i < n; i++) {
        var cx = rx + i * (cw + gap);
        var on = (i == e.cur);
        Ui_Box(cx, yy, cx + cw, yy + ch, on ? UI_C_LIGHTEST : UI_C_DARK);
        Ui_Box(cx + p, yy + p, cx + cw - p, yy + ch - p, on ? UI_C_DARK : UI_C_DARKEST);
        if (i < array_length(e.digits)) Ui_Text(cx + cw / 2, yy + (ch - lh) div 2, string(e.digits[i]), UI_C_TEXT, fa_center);
        if (on) {
            Title_SeedArrow(cx + (cw - 5 * p) div 2, yy - 4 * p, -1, p, UI_C_LIGHTEST);
            Title_SeedArrow(cx + (cw - 5 * p) div 2, yy + ch + p, 1, p, UI_C_LIGHTEST);
            up_r = { x: cx, y: yy - 5 * p, w: cw, h: 5 * p };   // D182: where a click raises / lowers the digit
            down_r = { x: cx, y: yy + ch, w: cw, h: 5 * p };
        }
        array_push(cells, { x: cx, y: yy, w: cw, h: ch });
    }
    yy += ch + 5 * p + 3 * p;
    Ui_TextBlock(x0, yy, info, inner_w, _c.title_seed_msg ? UI_C_LIGHTEST : UI_C_LIGHT);
    yy += info_h + 3 * p;
    var hint_y = yy;
    for (var r = 0; r < array_length(hints); r++) {
        Prompt_RichDraw(x0, yy, hints[r], inner_w, UI_C_LIGHT, fa_left, a);
        if (r == 1) start_r = { x: x0, y: yy, w: inner_w, h: Ui_TextBlockH(hints[r], inner_w) };   // D182: a click on the Start line starts
        yy += Ui_TextBlockH(hints[r], inner_w) + p;
    }
    _c.title_seed_rects = { panel: { x: px, y: py, w: pw, h: ph }, cells: cells, hint_y: hint_y, hint_h: hint_h, up: up_r, down: down_r, start: start_r };
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
    if (is_struct(Title_NameOf(_c))) {   // D175: the name entry is above the profile screen
        Title_NameStep(_c);
        return;
    }
    if (is_struct(Title_CodexOf(_c))) {   // D175: the Codex of the active profile
        Title_CodexStep(_c);
        return;
    }
    if (_c.title_refresh) Title_Refresh(_c);
    if (Ui_StackDepth(_c.title_stk) == 1 && Title_ButtonKeys(_c)) return;   // D175: the profile button's key, or a click on it
    var top = Ui_StackTop(_c.title_stk);
    if (Title_PickerKeys(_c, top)) return;   // D175: the delete key on a Load Game row
    var depth0 = Ui_StackDepth(_c.title_stk);
    Ui_MenuUpdate(top, _c.title_stk);
    if (depth0 > 1 && Ui_StackDepth(_c.title_stk) == 1) _c.title_refresh = true;   // back on the title: save files may have changed (a delete)
}

function Title_Draw(_c) {
    if (!is_struct(_c.title_stk) || _c.state == "settings") return;
    if (is_struct(Title_SeedEntryOf(_c))) {   // D152: the entry screen stands alone over the dimmed picture
        Title_SeedEntryDraw(_c);
    } else if (is_struct(Title_NameOf(_c))) {   // D175: so does the name entry
        Title_NameDraw(_c);
    } else if (is_struct(Title_CodexOf(_c))) {   // D175: and the Codex
        Title_CodexDraw(_c);
    } else {
        var pk = (Ui_StackDepth(_c.title_stk) >= 2 && Title_IsPicker(_c.title_stk.menus[1])) ? _c.title_stk.menus[1] : undefined;
        if (is_struct(pk)) {   // D175: a save file picker stands alone over the dimmed picture (the title menu is not drawn under it), clear of its key line
            if (Ui_StackTop(_c.title_stk) == pk) Title_PickerFit(_c, pk);
            Ui_DimBackdrop(UI_DIM_POPUP * Ui_MenuAlpha(pk, current_time));
        }
        Ui_StackDraw(_c.title_stk);
        if (Ui_StackDepth(_c.title_stk) <= 1) {
            Title_DrawCard(_c);   // the Continue card makes way for the seed pick
            Title_DrawButtons(_c);   // D175: the profile button
        } else {
            Title_DrawHints(_c);   // D175: the keys of a save file picker or of the profile screen
        }
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
    if (_device == "gamepad") return Loc_T("title.splash.press_button", "Press Any Button");
    return Loc_T("title.splash.press_key", "Press Any Key");
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
    if (_model.kind == "cant") return { title: Loc_T("title.card.cant", "Can't Continue"), rows: [] };
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
#macro UI_C_ACCENT $47C5E8      // #E8C547 (D149): the one accent ([a]..[/a]): BREAK and Perfect only (the merchant gold of D113)
#macro UI_C_RARITY_EPIC $A0E6F6  // #F6E6A0 (D178): the lightest gold an Epic item's name and gem pulse to (the Rare gold is UI_C_MERCHANT_GOLD)
#macro UI_C_TEXT $FFFFFF         // #FFFFFF (D115): item names and list / name text are white; frames, bars and accents keep the four palette colours
#macro UI_REPEAT_DELAY_MS 300    // D95: hold this long before the list starts to scroll
#macro UI_REPEAT_START_MS 140    // the first repeat gap; each next one is 20 percent shorter ...
#macro UI_REPEAT_MIN_MS 45       // ... down to this
#macro UI_PANEL_MS 120           // D97: panels slide and fade in this long
#macro UI_DIM_POPUP 0.6          // G10 (D129, D133): how far a pop-up or a menu above another dims what is under it ...
#macro UI_DIM_SCREEN 0.8         // ... and how far a whole-screen page (the Tab menu, the card pick, the shop) dims the world. Two strengths, nothing else.
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
        wheel: 0, mx: -1, my: -1, mouse_moved: false, click: false, rclick: false, held: false
    };
}

// The mouse in GUI units from our own layout (window pixels minus the picture's corner, over the integer UI scale).
function Ui_MousePos() {
    var lay = Display_Layout();
    return { x: (Mouse_WinX() - lay.gui_x) / lay.ui_scale, y: (Mouse_WinY() - lay.gui_y) / lay.ui_scale };   // D182: Mouse_* (a scripted run drives a fake)
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
    s.back = Input_UIBack() || (Menu_IsOpen() && Input_UIPressed("pause"));   // Hunt 6 UI (D140): the pad's Y opens the one menu, so inside it Y is Back (Esc is both keys already)
    s.tab = (Input_Pressed("tab_next") ? 1 : 0) - (Input_Pressed("tab_prev") ? 1 : 0);   // bound by the screens that have tabs
    var lay = Display_Layout();   // the mouse as Ui_MousePos works it out, without its struct
    s.mx = (Mouse_WinX() - lay.gui_x) / lay.ui_scale;
    s.my = (Mouse_WinY() - lay.gui_y) / lay.ui_scale;
    if (!variable_global_exists("ui_mouse") || !is_struct(global.ui_mouse)) global.ui_mouse = { x: s.mx, y: s.my };
    s.mouse_moved = (s.mx != global.ui_mouse.x || s.my != global.ui_mouse.y);
    global.ui_mouse.x = s.mx;
    global.ui_mouse.y = s.my;
    s.click = Mouse_Pressed(mb_left);
    s.rclick = Mouse_Pressed(mb_right);
    s.held = Mouse_Held(mb_left);   // D182: a slider follows the mouse while the button stays down
    s.wheel = Mouse_WheelDir();
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
// G10 (D129): det_floor_y (for details_pos "above"; -1 = none) is the highest line the details panel may reach (the battle sets it to just below the enemy): when the panel
// and the list would not fit under it (R-108), in this order: the details drop every number line not marked keep: true (all but the first when none is marked); then the arrow strip;
// then the list shows two rows, then one (the gap between the panels shrinks to one pixel unit); then the prompt line is left out (det_floor_alt is the floor without it; -1 = same as
// det_floor_y); then the details' last-resort lines go (dup: true, the MP the list row shows; an item keeps none), then the sentence takes the next smaller type step, then the two panels
// share a border and the details have one pixel unit of air inside instead of two. The sentence is never dropped.
// Number lines may carry delta (-1 / 0 / +1): a small arrow shows before the value (a better or worse number).
// After a draw m.rect and m.det_rect hold the panel and details rectangles.
function Ui_MenuNew(_id, _items, _opts) {
    var m = {
        id: _id, items: _items, cursor: 0, top: 0, rects: [], bars: [], drag: -1,   // D182: bars = each slider row's bar rectangle (the draw keeps them), drag = the slider row a held click is moving (-1 none)
        rep_v: Ui_RepeatNew(), rep_h: Ui_RepeatNew(),
        on_confirm: undefined, on_back: undefined, on_adjust: undefined, on_slide: undefined, refuse: undefined,
        owner: noone, data: {}, lock_ms: current_time,
        layout: { title: "", note: "", anchor: "center", y_frac: 0.5, center: false, details: false, hides_below: false,
                  x_anchor: "center", panel_w: 0, y_bottom: -1, max_h: 0, details_pos: "below", details_cols: 1, rows_max: 0,
                  y_top: -1, det_w: 0, det_art: false, det_top: -1, det_h: -1, det_floor_y: -1, det_floor_alt: -1, snap_band: false },
        rect: { x: 0, y: 0, w: 0, h: 0 }, det_rect: { x: 0, y: 0, w: 0, h: 0 }, hint_hidden: false,
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

// Where the highlight band is this frame: it glides toward _target_y (Ui_Glide), except on a menu that sets layout.snap_band (the level-up screen, I-109), where it is at the
// target at once, so the band, the "+1" and the details panel always show the same row. Pure.
function Ui_MenuBandY(_m, _target_y, _dt) {
    if (variable_struct_exists(_m.layout, "snap_band") && _m.layout.snap_band) return _target_y;
    return Ui_Glide(_m.cur_y, _target_y, _dt);
}

// I-109: how a row's value is drawn: { old, new, old_col, new_col }. A row with new_col whose value reads "12 > 13" draws "12 > " in the row colour and "13" in new_col (right
// aligned together); any other row (or a plain number) is one colour: old = the whole value, new = "". Pure.
function Ui_RowValueSpec(_row, _sel = false) {
    var v = variable_struct_exists(_row, "value") ? string(_row.value) : "";
    var base = Ui_RowStyle(_row, _sel).text;
    var spec = { old: v, new: "", old_col: base, new_col: base };
    if (variable_struct_exists(_row, "new_col") && Ui_ItemEnabled(_row)) {
        var at = string_pos(" > ", v);
        if (at > 0) {
            spec.old = string_copy(v, 1, at + 2);
            spec.new = string_copy(v, at + 3, string_length(v));
            spec.new_col = _row.new_col;
        }
    }
    return spec;
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
    var ev = { moved: false, confirm: false, back: false, adjust: 0, index: _m.cursor, slide: undefined };
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
        // D182: a click on a slider's bar sets that point and, while the button stays down, the slider follows the mouse (even off the bar); { index, value 0..1 } in ev.slide
        if (_m.drag >= 0 && !_snap.held) _m.drag = -1;
        if (_snap.click) {
            _m.drag = -1;
            var sb = Ui_HoverIndex(_m.bars, _snap.mx, _snap.my, en);
            if (sb >= 0 && variable_struct_exists(_m.items[sb], "kind") && _m.items[sb].kind == "slider") _m.drag = sb;
        }
        if (_m.drag >= 0 && _m.drag < array_length(_m.bars)) {
            var br = _m.bars[_m.drag];
            ev.slide = { index: _m.drag, value: Slider_ValueAt(_snap.mx, br.x, br.w, SETTINGS_VOLUME_STEP) };
        }
        var dh = (_snap.right ? 1 : 0) - (_snap.left ? 1 : 0);
        if (Ui_RepeatStep(_m.rep_h, dh, _snap.left_p || _snap.right_p, _now) > 0) ev.adjust = dh;
    }
    if (_snap.back || _snap.rclick) ev.back = true;
    ev.index = _m.cursor;
    return ev;
}

// D182: where a click at _mx on a slider bar (left edge _bx, width _bw) puts the slider: 0..1, snapped to _step (the 5 % of the volume rows); left of the bar is 0, right of it 1.
function Slider_ValueAt(_mx, _bx, _bw, _step) {
    var f = clamp((_mx - _bx) / max(1, _bw), 0, 1);
    var st = max(0.001, _step);
    return clamp(round(round(f / st) * st * 1000) / 1000, 0, 1);
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

// The sound a Confirm on row _i of menu _m makes: the bright "confirm" ding, or the refusal when the row cannot be used.
// A menu opts in with a "refuse" callback (_m, _i) -> bool.
function Ui_ConfirmSound(_m, _i) {
    if (variable_struct_exists(_m, "refuse") && is_callable(_m.refuse) && _m.refuse(_m, _i)) return "ui_deny";
    return "ui_confirm";
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
    if (is_struct(ev.slide) && is_callable(_m.on_slide)) {   // D182: the mouse set a slider
        if (_m.on_slide(_m, ev.slide.index, ev.slide.value)) SFX_PlayUI("ui_move");
    }
    if (ev.confirm && is_struct(it) && variable_struct_exists(it, "kind") && it.kind == "slider") ev.confirm = false;   // a slider moves with left/right (or the mouse on its bar), a click does not confirm
    if (ev.confirm) {
        SFX_PlayUI(Ui_ConfirmSound(_m, ev.index));
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

// ---- D182: the mouse cursor ------------------------------------------------------------------------------------------------------------------------------
// The OS cursor is hidden while the game has focus, so the game draws its own arrow, in the GUI layer on top of everything: 8 x 10 art pixels (one art pixel = one UI pixel, Ui_Px),
// the lightest palette colour with a 1-px darkest outline, its tip (the hot spot) at the mouse. While a button is down it is the pressed variant: one art pixel down and to the right
// with the dimmer fill. MouseCursor_Visible (scr_input) says when it is shown: after a move or a click in the last 3 s, never after a key or pad press until the mouse moves.
// The arrow as filled boxes [{ x, y, w, h, col }]: runs of one colour per row, the tip at (_x, _y), _p GUI units per art pixel. Pure.
function MouseCursor_Boxes(_x, _y, _p, _pressed) {
    var mask = MouseCursor_Mask();
    var out = [];
    var ox = _pressed ? _p : 0;
    var fill = _pressed ? UI_C_LIGHT : UI_C_LIGHTEST;
    for (var r = 0; r < array_length(mask); r++) {
        var row = mask[r];
        var c = 1;
        var n = string_length(row);
        while (c <= n) {
            var ch = string_char_at(row, c);
            if (ch == ".") { c++; continue; }
            var c2 = c;
            while (c2 < n && string_char_at(row, c2 + 1) == ch) c2++;
            array_push(out, { x: _x + ox + (c - 1) * _p, y: _y + ox + r * _p, w: (c2 - c + 1) * _p, h: _p, col: (ch == "F") ? fill : UI_C_DARKEST });
            c = c2 + 1;
        }
    }
    return out;
}

// Called last in the Draw GUI of the controllers (obj_ui_controller, obj_battle_controller), so nothing covers it.
function MouseCursor_Draw() {
    if (!MouseCursor_Visible(MouseCursor_Get(), current_time, MouseCursor_Focused())) return;
    var lay = Display_Layout();
    var mp = Ui_MousePos();
    var p = Ui_Px();
    var gx = floor(clamp(mp.x, 0, lay.gui_w - 1));
    var gy = floor(clamp(mp.y, 0, lay.gui_h - 1));
    var boxes = MouseCursor_Boxes(gx, gy, p, Mouse_Held(mb_left) || Mouse_Held(mb_right) || Mouse_Pressed(mb_left) || Mouse_Pressed(mb_right));
    var a0 = draw_get_alpha();
    var c0 = draw_get_color();
    draw_set_alpha(1);
    for (var i = 0; i < array_length(boxes); i++) {
        var b = boxes[i];
        Ui_Box(b.x, b.y, b.x + b.w, b.y + b.h, b.col);
    }
    draw_set_alpha(a0);
    draw_set_color(c0);
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

// R3 note 21 (R-096, D171): how a list row is drawn, in one place. A section header (kind "head": Equipped, Bag, Passives, any other) is the palette's lightest text with
// a thin light rule after it, from the end of the text to the right edge of the list (no fill: the cursor band is the dark green, and a filled header read as a selected
// row); every other row has no rule and the colour Ui_RowColor gives (an empty slot is a dim row: the light green). Returns { text, strip, rule } (strip = the fill
// colour, -1 = none: no row has one; rule = the colour of the line after the text, -1 = none).
function Ui_RowStyle(_row, _sel = false) {
    var kd = variable_struct_exists(_row, "kind") ? _row.kind : "button";
    if (kd == "head") return { text: UI_C_LIGHTEST, strip: -1, rule: UI_C_LIGHT };
    var dim = variable_struct_exists(_row, "dim") && _row.dim;
    var txt = Ui_RowColor(_sel, Ui_ItemEnabled(_row), dim);
    if (variable_struct_exists(_row, "col") && Ui_ItemEnabled(_row)) txt = _row.col;   // D177: a row with a colour of its own (the level-up screen's gold growth rows), selected or not
    return { text: txt, strip: -1, rule: -1 };
}

// D178: the colour of a row's NAME. An item row (it carries icon_item) shows its name in the item's rarity colour (Common white, Rare gold, Epic pulsing gold) unless the row is
// dim (cannot use / empty / too expensive: the light green) or disabled (the dark green); every other row is as Ui_RowStyle says. The value column keeps the row colour.
function Ui_RowLabelColor(_row, _sel = false) {
    var st = Ui_RowStyle(_row, _sel);
    if (st.text != UI_C_TEXT) return st.text;
    if (variable_struct_exists(_row, "icon_item") && is_struct(_row.icon_item) && variable_struct_exists(_row.icon_item, "id")) return Rarity_Color(Item_Rarity(_row.icon_item.id));
    return st.text;
}

// The header's place inside its row: the whole width, a gap of one pixel unit above it unless it is the first row of the list. Pure. { x, y, w, h }
function Ui_HeadRect(_x1, _x2, _ry, _row_h, _p, _first) {
    var gap = _first ? 0 : _p;
    return { x: _x1, y: _ry + gap, w: _x2 - _x1, h: _row_h - gap };
}

// R3 note 25 (R-097): a row that flashes blinks twice in CONTROLS_FLASH_MS (pale with dark text, then as it was); _t = ms since the flash began. Pure.
#macro CONTROLS_FLASH_MS 600
function Ui_FlashOn(_t) {
    if (_t < 0 || _t >= CONTROLS_FLASH_MS) return false;
    return _t < 200 || (_t >= 300 && _t < 500);
}

function Ui_Text(_x, _y, _txt, _col, _halign = fa_left) {
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_color(Ui_TextColor(_col));
    if (is_string(_txt) && string_pos("[", _txt) > 0) _txt = Markup_Strip(_txt);   // D149: markup never reaches a plain draw as brackets
    if (UiFit_On()) UiFit_TextDrawn(_x, _y, _txt, _halign);   // H13b (D156): a scripted run records text that leaves its frame or the screen
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
    if (UiFit_On()) UiFit_FramePush(_x, _y, _w, _h, _p);
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
    if (UiFit_On()) UiFit_BlockDrawn(_x, _y, _txt, _w);
    var s = max(0.0001, UI_GetFontScale());
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(Ui_TextColor(_col));
    draw_text_ext_transformed(round(_x), round(_y), string(_txt), -1, max(1, round(_w / s)), s, s, 0);
}

// R3 (D168): the measure and the draw of a wrapped plain block at a type step (UI_FontStep: 0 = the UI size, 1 = the next smaller one). { w: the widest line,
// h: the height, lines }. Plain text only (no prompts or markup); the font that was set is put back.
function Ui_TextBlockMeasureStep(_txt, _w, _step) {
    var fs = UI_FontStep(_step);
    var f0 = draw_get_font();
    draw_set_font(fs.font);
    var s = max(0.0001, fs.scale);
    var sep_w = max(1, round(_w / s));
    var h = round(string_height_ext(string(_txt), -1, sep_w) * s);
    var w = round(string_width_ext(string(_txt), -1, sep_w) * s);
    var lh = max(1, round(string_height("A") * s));
    draw_set_font(f0);
    return { w: w, h: h, lines: max(1, round(h / lh)), line_h: lh, step: fs.step };
}

function Ui_TextBlockStep(_x, _y, _txt, _w, _col, _step) {
    if (_step <= 0) { Ui_TextBlock(_x, _y, _txt, _w, _col); return; }
    var fs = UI_FontStep(_step);
    var f0 = draw_get_font();
    draw_set_font(fs.font);
    var s = max(0.0001, fs.scale);
    if (UiFit_On()) {
        var m = Ui_TextBlockMeasureStep(_txt, _w, _step);
        draw_set_font(fs.font);
        UiFit_BoxDrawn(string(_txt), _x, _y, _x + m.w, _y + m.h, _x, _y);
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(Ui_TextColor(_col));
    draw_text_ext_transformed(round(_x), round(_y), string(_txt), -1, max(1, round(_w / s)), s, s, 0);
    draw_set_font(f0);
}

// D100 details panel: one plain sentence, then number lines [{ label, value }] (generated from the real game data by the caller).
// The text of _txt, cut with ".." so it is no wider than _max_w GUI units.
function Ui_FitText(_txt, _max_w) {
    var t = string(_txt);
    if (string_pos("[", t) > 0) t = Markup_Strip(t);   // D149: the width of what is drawn, not of the tags
    if (UI_TextWidth(t) <= _max_w) return t;
    if (UiFit_On()) UiFit_Fail("cut", t, _max_w, UI_TextWidth(t));   // H13b (D156): a cut is a fit failure
    while (string_length(t) > 1 && UI_TextWidth(t + "..") > _max_w) t = string_copy(t, 1, string_length(t) - 1);
    return t + "..";
}

// D178: the width of one line of text as it is drawn: a line with markup (an item's name in its rarity colour) by its words, a plain line by the font.
function Ui_LineWidth(_txt) {
    var t = string(_txt);
    if (Prompt_HasTokens(t)) return Markup_Width(t);
    return UI_TextWidth(t);
}

// One line at (_x, _y) in _w, in _col; with markup the item names keep their colour (Markup_DrawLine). _halign fa_left or fa_center (centred on _x). A line wider than _w is cut
// plain with ".." as before (Ui_FitText). Returns the width drawn.
function Ui_LineDraw(_x, _y, _txt, _w, _col, _halign = fa_left) {
    var t = string(_txt);
    if (!Prompt_HasTokens(t) || Markup_Width(t) > _w) {
        var ft = Ui_FitText(t, _w);
        Ui_Text(_x, _y, ft, _col, _halign);
        return UI_TextWidth(ft);
    }
    var w = Markup_Width(t);
    var x0 = (_halign == fa_center) ? round(_x - w / 2) : _x;
    Markup_DrawLine(x0, _y, t, Ui_TextColor(_col), draw_get_alpha());
    return w;
}

// ---- H13b (D156): THE "text fits" check ---------------------------------------------------------------------------------------
// One question, asked the same way everywhere: does this text, wrapped the way the draw wraps it, fit this box? The measuring uses the draw's own
// functions (Prompt_RichLayout for a sentence with prompts or styled words, string_width_ext for a plain block, UI_TextWidth for a line), so the
// answer is what the player sees. Two users:
//   * the unit suite (Test_Suite_TextFit) feeds every workbook row of the known card / plate / list types through UiFit_Check at 480 x 432 and 800 x 720;
//   * the scripted runs switch the recorder on (UiFit_Enable): Ui_DrawFrame remembers each frame drawn this frame, and Ui_Text / Ui_TextBlock note any
//     text that starts inside a frame and ends outside its inner edge (or leaves the screen); Ui_FitText notes every cut ("..").
//     Each note is a "fit failure" { kind, panel, text, size, lang, have, need }; every -shots picture asserts that none arrived since the last one.
// Ellipsis (Ui_FitText) is never meant to fire on a workbook row: the layout widens, wraps or lowers instead. Nothing may cut a row silently.

// The measure of _txt in a column _w units wide (_wrap) or on one line: { w: the widest line, h: the height, lines }.
function UiFit_Measure(_txt, _w, _wrap = true) {
    var t = string(_txt);
    var mt = Ui_Metrics();
    if (Prompt_HasTokens(t)) {
        if (_wrap) {
            var lay = Prompt_RichLayout(t, _w);
            var ww = 0;
            for (var i = 0; i < array_length(lay.items); i++) ww = max(ww, lay.items[i].x + lay.items[i].w);   // the right edge of the last word (line_w counts the space after it)
            return { w: ww, h: lay.h, lines: lay.lines };
        }
        return { w: Markup_Width(t), h: mt.line_h, lines: 1 };
    }
    if (string_pos("[", t) > 0) t = Markup_Strip(t);
    if (!_wrap) return { w: UI_TextWidth(t), h: UI_TextHeight(t), lines: 1 + string_count("\n", t) };
    var s = max(0.0001, UI_GetFontScale());
    var sep_w = max(1, round(_w / s));
    var h = round(string_height_ext(t, -1, sep_w) * s);
    return { w: round(string_width_ext(t, -1, sep_w) * s), h: h, lines: max(1, round(h / max(1, mt.line_h))) };
}

// Does _txt fit a box _w wide (and _h tall when _h >= 0)? { ok, w, h, lines }: what it needs. _wrap false = one line.
function UiFit_Check(_txt, _w, _h = -1, _wrap = true) {
    var m = UiFit_Measure(_txt, _w, _wrap);
    m.ok = (m.w <= _w) && (_h < 0 || m.h <= _h);
    return m;
}

function UiFit_Enable(_on) {
    if (!variable_global_exists("uifit") || !is_struct(global.uifit)) global.uifit = { frames: [], fails: [], seen: {}, logged: {}, total: 0 };
    global.uifit_on = _on;
}

function UiFit_On() {
    return variable_global_exists("uifit_on") && global.uifit_on;
}

// Called once at the start of a frame's Draw GUI (Display_DrawFrame): the frames of the last frame are gone.
function UiFit_FrameBegin() {
    if (UiFit_On()) global.uifit.frames = [];
}

function UiFit_FramePush(_x, _y, _w, _h, _p) {
    var f = global.uifit.frames;
    if (array_length(f) >= 48) array_delete(f, 0, 1);
    array_push(f, { x: _x, y: _y, w: _w, h: _h, p: _p });
}

// The drawing function that asked for the text: the first frame of the call stack that is not one of the text helpers.
function UiFit_PanelName() {
    var cs = debug_get_callstack();
    for (var i = 0; i < array_length(cs); i++) {
        var n = string(cs[i]);
        n = string_replace(n, "gml_Script_", "");
        n = string_replace(n, "gml_Object_", "");
        var sp = string_pos(" (", n);
        if (sp > 0) n = string_copy(n, 1, sp - 1);
        if (string_copy(n, 1, 6) == "UiFit_" || string_copy(n, 1, 3) == "Ui_" || string_copy(n, 1, 7) == "Markup_" || string_copy(n, 1, 12) == "Prompt_Rich" || string_copy(n, 1, 3) == "UI_") continue;
        if (n == "" || n == "0") continue;
        return n;
    }
    return "?";
}

// Notes one failure (once per kind / panel / text / window size / language until the next UiFit_Take).
function UiFit_Fail(_kind, _txt, _have, _need) {
    var u = global.uifit;
    var l = Display_Layout();
    var size = string(l.win_w) + "x" + string(l.win_h);
    var lang = Loc_GetLanguage();
    var panel = UiFit_PanelName();
    var txt = string_copy(string(_txt), 1, 48);
    var key = _kind + "|" + panel + "|" + txt + "|" + size + "|" + lang;
    var fr = UiFit_Frame();
    if (variable_struct_exists(u.seen, key)) {   // the same failure again: it is still on the screen
        variable_struct_get(u.seen, key).frame = fr;
        return;
    }
    var rec = { kind: _kind, panel: panel, text: txt, size: size, lang: lang, have: _have, need: _need, frame: fr };
    variable_struct_set(u.seen, key, rec);
    array_push(u.fails, rec);
    u.total++;
    if (!variable_struct_exists(u.logged, key)) {
        variable_struct_set(u.logged, key, true);
        show_debug_message("[FIT] " + _kind + " panel=" + panel + " size=" + size + " lang=" + lang + " have=" + string(_have) + " need=" + string(_need) + " text=" + txt);
    }
}

// The game frame counter (Display_Update's), the clock a failure is stamped with.
function UiFit_Frame() {
    return (variable_global_exists("display") && is_struct(global.display)) ? global.display.frame : 0;
}

// The failures that are on the screen now: those noted in the last two frames, since the last call. A panel that was still sliding in, or a layout the
// window change had not reached yet, is not the picture; whatever is still wrong when the picture is taken is.
function UiFit_Take() {
    if (!UiFit_On()) return [];
    var u = global.uifit;
    var now = UiFit_Frame();
    var out = [];
    for (var i = 0; i < array_length(u.fails); i++) {
        if (u.fails[i].frame >= now - 2) array_push(out, u.fails[i]);
    }
    u.fails = [];
    u.seen = {};
    return out;
}

function UiFit_Describe(_fails) {
    var s = "";
    for (var i = 0; i < min(4, array_length(_fails)); i++) {
        var f = _fails[i];
        s += ((i > 0) ? "; " : "") + f.kind + " " + f.panel + " '" + f.text + "' " + string(f.need) + ">" + string(f.have);
    }
    if (array_length(_fails) > 4) s += "; +" + string(array_length(_fails) - 4) + "x";
    return s;
}

// The newest frame (drawn this frame) that holds the point; undefined when none does.
function UiFit_FrameAt(_ax, _ay) {
    var f = global.uifit.frames;
    for (var i = array_length(f) - 1; i >= 0; i--) {
        var fr = f[i];
        if (_ax >= fr.x && _ax <= fr.x + fr.w && _ay >= fr.y && _ay < fr.y + fr.h) return fr;
    }
    return undefined;
}

// A box of text [_l, _r] x [_t, _b] drawn with its anchor at (_ax, _ay): outside the screen, or starting in a frame and ending outside its inner edge (the border and
// the dark band are 2p) is a failure.
function UiFit_BoxDrawn(_txt, _l, _t, _r, _b, _ax, _ay) {
    var l = Display_Layout();
    if (variable_global_exists("uifit_skip") && global.uifit_skip) return;   // the build stamp (Build_DrawId) is a corner mark over whatever is there, not a panel's text
    if (_l < -0.5 || _r > l.gui_w + 0.5) {
        UiFit_Fail("screen_w", _txt, l.gui_w, (_l < -0.5) ? -_l : _r);
        return;
    }
    var scroll = variable_global_exists("uifit_scroll") && global.uifit_scroll;   // a roll that scrolls through the top and the bottom (the credits)
    if (_b > l.gui_h + 0.5 && !scroll) {
        UiFit_Fail("screen_h", _txt, l.gui_h, _b);
        return;
    }
    var fr = UiFit_FrameAt(_ax, _ay);
    if (!is_struct(fr)) return;
    var inset = 2 * fr.p;
    if (_l < fr.x + inset - 0.5 || _r > fr.x + fr.w - inset + 0.5) UiFit_Fail("frame_w", _txt, fr.w - 2 * inset, _r - _l);
    else if (_b > fr.y + fr.h - inset + 0.5 && !scroll) UiFit_Fail("frame_h", _txt, fr.h - 2 * inset, _b - fr.y - inset);
}

function UiFit_TextDrawn(_x, _y, _txt, _halign) {
    var t = string(_txt);
    if (t == "") return;
    var tw = UI_TextWidth(t);
    var th = UI_TextHeight(t);
    var lx = (_halign == fa_center) ? _x - tw / 2 : ((_halign == fa_right) ? _x - tw : _x);
    UiFit_BoxDrawn(t, lx, _y, lx + tw, _y + th, _x, _y);
}

function UiFit_BlockDrawn(_x, _y, _txt, _w) {
    var t = string(_txt);
    if (t == "") return;
    var m = UiFit_Measure(t, _w, true);
    UiFit_BoxDrawn(t, _x, _y, _x + m.w, _y + m.h, _x, _y);
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

// Side of the square picture box, in GUI units (32 font pixels; 20 for a picture marked `small`, D173: the bestiary at the largest window).
function Ui_ArtSize(_it = undefined) {
    var small = is_struct(_it) && variable_struct_exists(_it, "pic") && is_struct(_it.pic) && variable_struct_exists(_it.pic, "small") && _it.pic.small;
    return (small ? 20 : 32) * Ui_Px();
}

// Draws the item's picture in a dark box centred on _cx with its top at _y. Returns the height used.
function Ui_DrawArt(_cx, _y, _it, _alpha = 1) {
    var kind = Ui_ArtKind(_it);
    if (kind == "") return 0;
    var p = Ui_Px();
    var side = Ui_ArtSize(_it);
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

// R-108: _step > 0 sets the sentence one type step smaller (the battle's last resort under the enemy; a sentence with prompt tokens keeps its size).
function Ui_DetailsSentenceH(_sentence, _w, _step) {
    if (_step > 0 && !Prompt_HasTokens(_sentence)) return Ui_TextBlockMeasureStep(_sentence, _w, _step).h;
    return Ui_TextBlockH(_sentence, _w);
}

// _tight: one pixel unit of air inside the frame instead of two, top and bottom (the battle's last resort).
function Ui_DetailsHeight(_w, _sentence, _lines, _cols = 1, _seq_n = 0, _art = undefined, _step = 0, _tight = false) {
    var mt = Ui_Metrics();
    var inner = _w - 2 * (4 * mt.p);
    var h = 2 * (2 * mt.p + (_tight ? mt.p : mt.pad)) + Ui_DetailsSentenceH(_sentence, inner, _step);
    if (Ui_ArtKind(_art) != "") h += Ui_ArtSize(_art) + 2 * mt.p;
    if (_seq_n > 0) h += 13 * max(1, round(mt.p / 2)) + mt.p;
    if (array_length(_lines) > 0) h += mt.p * 2 + Ui_DetailsLinesH(_lines, inner, _cols, mt);
    return h;
}

function Ui_DrawDetails(_x, _y, _w, _h, _sentence, _lines, _alpha = 1, _cols = 1, _seq = [], _art = undefined, _step = 0, _tight = false) {
    var mt = Ui_Metrics();
    var p = mt.p;
    Ui_DrawFrame(_x, _y, _w, _h, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var x0 = _x + 4 * p;
    var x1 = _x + _w - 4 * p;
    var ty0 = _y + (_tight ? 3 : 4) * p;
    if (Ui_ArtKind(_art) != "") ty0 += Ui_DrawArt((x0 + x1) / 2, ty0, _art, _alpha) + 2 * p;
    if (_step > 0 && !Prompt_HasTokens(_sentence)) Ui_TextBlockStep(x0, ty0, _sentence, x1 - x0, UI_C_LIGHTEST, _step);
    else Ui_TextBlock(x0, ty0, _sentence, x1 - x0, UI_C_LIGHTEST);
    ty0 += Ui_DetailsSentenceH(_sentence, x1 - x0, _step);
    if (array_length(_seq) > 0) {   // the arrows to press (D100), in a dark strip like the card's
        ty0 += p;
        ty0 += CardsUi_DrawArrows(x0, ty0, x1 - x0, _seq, max(1, round(p / 2)));
    }
    if (array_length(_lines) > 0) {
        ty0 += p;
        Ui_Box(x0, ty0, x1, ty0 + p, UI_C_DARK);
        ty0 += p;
        var plan = Ui_DetailsPlan(_lines, x1 - x0, _cols, mt);   // H13b (D156): a number line that does not fit one row puts its value on the row below; a label wider than the column wraps
        for (var r = 0; r < array_length(plan.rows); r++) {
            var prow = plan.rows[r];
            for (var c = 0; c < array_length(prow.cells); c++) {
                var cell = prow.cells[c];
                var i = cell.i;
                var cx0 = x0 + cell.x;
                var vtxt = string(_lines[i].value);
                var has_delta = variable_struct_exists(_lines[i], "delta") && _lines[i].delta != 0;
                var lh_i = Ui_DetailsLineH(_lines[i].label, vtxt, cell.w, p, has_delta, mt);
                var vy = ty0 + lh_i - (mt.line_h + p);   // the value is on the line's last row
                if (UI_TextWidth(_lines[i].label) > cell.w) Ui_TextBlock(cx0, ty0, _lines[i].label, cell.w, UI_C_LIGHT);
                else Ui_Text(cx0, ty0, _lines[i].label, UI_C_LIGHT);
                Ui_Text(cx0 + cell.w, vy, _lines[i].value, UI_C_LIGHTEST, fa_right);
                if (has_delta) {
                    Ui_DeltaMark(cx0 + cell.w - UI_TextWidth(_lines[i].value) - 7 * p, vy + (mt.line_h - 3 * p) div 2, _lines[i].delta, p, (_lines[i].delta > 0) ? UI_C_LIGHTEST : UI_C_LIGHT);
                }
            }
            ty0 += prow.h;
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

// H13b (D156): the width a row's label may take in a panel _panel_w wide (a list with the label on the left and an optional value on the right): the
// inner width, less the marker column (5p), the icon column (a skill / status icon, or an item's picture) and the value with its 3p gap.
function Ui_MenuLabelRoom(_panel_w, _p, _icon_px, _icon_item, _value) {
    var lx = 4 * _p + 5 * _p + ((_icon_px > 0) ? _icon_px + 2 * _p : 0) + (_icon_item ? 10 * _p : 0);
    var vtxt = is_undefined(_value) ? "" : string(_value);
    var vw = (vtxt != "") ? UI_TextWidth(vtxt) + 3 * _p : 0;
    return (_panel_w - 4 * _p) - lx - vw;
}

// R-106 (D168): how one list row lays out its label. Names keep their wording and their type size where they can: a label that fits beside its value stays on one line
// ("one"); one that does not wraps by words into at most two lines in the room it has ("wrap"); a button row whose label does not fit that way puts the value on a line of
// its own under the label, right-aligned ("stack"); only when no word can be made to fit at the UI's size does the label take the next smaller type step (one too-wide word,
// CardsUi_NameFit), wrapped the same way, then stacked. "cut" (ok = false) is a row no layout can fit; the draw then falls back to Ui_FitText.
// { mode, ok, step, lines, w (the widest label line), h (the label's height), y_off, room (the width the label may take), row_h (the row's height: a normal row, or taller
// for the extra lines), value_y (stack: where the value's line starts in the row) }. Pure.
function Ui_RowFit(_label, _value, _panel_w, _p, _icon_px, _icon_item, _stackable, _mt) {
    var t = string(_label);
    if (string_pos("[", t) > 0) t = Markup_Strip(t);
    var vtxt = is_undefined(_value) ? "" : string(_value);
    var avail = Ui_MenuLabelRoom(_panel_w, _p, _icon_px, _icon_item, vtxt);
    var w1 = UI_TextWidth(t);
    var fit = { mode: "one", ok: true, step: 0, lines: 1, w: w1, h: _mt.line_h, y_off: 0, room: avail, row_h: _mt.row_h, value_y: 0 };
    if (w1 <= avail) return fit;
    var stack = _stackable && vtxt != "";
    var avail2 = stack ? Ui_MenuLabelRoom(_panel_w, _p, _icon_px, _icon_item, "") : 0;   // the room the label has when the value is on a line of its own
    var steps = [0, 1];
    for (var st = 0; st < 2; st++) {
        for (var sk = 0; sk < (stack ? 2 : 1); sk++) {
            var rm = (sk == 0) ? avail : avail2;
            var m = Ui_TextBlockMeasureStep(t, rm, steps[st]);
            if (steps[st] > 0 && m.step <= 0) continue;   // there is no smaller size to take
            if (m.w <= 0 || m.w > rm || m.lines > 2) continue;
            var lh = max(m.h, _mt.line_h);
            fit.mode = (sk == 0) ? "wrap" : "stack";
            fit.step = m.step;
            fit.lines = m.lines;
            fit.w = m.w;
            fit.h = lh;
            fit.y_off = max(0, (_mt.line_h - m.h) div 2);
            fit.room = rm;
            fit.row_h = (sk == 0) ? max(_mt.row_h, lh + 2 * _p) : (lh + _mt.line_h + 2 * _p);
            fit.value_y = (sk == 0) ? 0 : (_p + lh);
            return fit;
        }
    }
    fit.mode = "cut";
    fit.ok = false;
    return fit;
}

// R-106: a menu title in a panel's inner width _room: one line, or wrapped by words (smaller type only for a single too-wide word). { step, w, h, lines, y_off }. Pure.
function Ui_TitleFit(_title, _room, _mt) {
    var w1 = UI_TextWidth(_title);
    if (w1 <= _room) return { step: 0, w: w1, h: _mt.line_h, lines: 1, y_off: 0 };
    return CardsUi_NameFit(string(_title), _room, _mt);
}

// The summed height of rows _a .. _b (inclusive) of a list whose rows have their own heights.
function Ui_RowsH(_rhs, _a, _b) {
    var h = 0;
    for (var i = _a; i <= _b; i++) h += _rhs[i];
    return h;
}

// R-106: Ui_ScrollTop for rows of different heights: the first visible row in a window _room tall. The cursor's row is whole inside, the window moves as little as possible,
// and it does not stop short of the end of the list when the end fits. With equal rows it is Ui_ScrollTop.
function Ui_ScrollTopH(_cur, _top, _rhs, _room) {
    var n = array_length(_rhs);
    if (n <= 0) return 0;
    var top = clamp(_top, 0, n - 1);
    if (_cur < top) top = _cur;
    while (top < _cur && Ui_RowsH(_rhs, top, _cur) > _room) top++;
    while (top > 0 && Ui_RowsH(_rhs, top - 1, n - 1) <= _room) top--;
    return top;
}

// The most height _k rows of the list can add to _k normal rows: the sum of the _k biggest extras (a row's extra is its height less a normal row's).
function Ui_ExtraSum(_rhs, _row_h, _k) {
    var ex = [];
    for (var i = 0; i < array_length(_rhs); i++) if (_rhs[i] > _row_h) array_push(ex, _rhs[i] - _row_h);
    array_sort(ex, false);
    var sum = 0;
    for (var j = 0; j < min(_k, array_length(ex)); j++) sum += ex[j];
    return sum;
}

// The last row (its index) that is whole inside a window _room tall that starts at row _top (at least _top itself).
function Ui_RowsEnd(_rhs, _top, _room) {
    var n = array_length(_rhs);
    var h = 0;
    var last = _top;
    for (var i = _top; i < n; i++) {
        h += _rhs[i];
        if (h > _room && i > _top) break;
        last = i;
    }
    return last;
}

// The panel width a list needs so that no label is cut: the widest row (marker column, icon column, label, value) or the title or the note, plus the
// 4p inset each side. _mc is the measured struct of Ui_MenuMeasure.
function Ui_MenuListNeed(_mc, _p) {
    var icon_col = (_mc.icon_px > 0) ? _mc.icon_px + 2 * _p : 0;
    return max(_mc.row_w + icon_col, _mc.title_w, _mc.note_w) + 8 * _p;
}

// The width one number line (label on the left, value on the right) needs on a single row: 3p of air between the two (the cards' rule); a line with a change mark keeps 7p for it.
function Ui_DetailsLineNeed(_label, _value, _p, _delta = false) {
    return UI_TextWidth(_label) + UI_TextWidth(string(_value)) + (_delta ? 7 * _p : 3 * _p);
}

// The details panel width a menu's number lines need so that each stays on one row: the widest label + value, plus the 4p inset each side. 0 without lines.
function Ui_MenuDetailsNeed(_items, _p, _cols = 1) {
    var w = 0;
    for (var i = 0; i < array_length(_items); i++) {
        var ls = variable_struct_get(_items[i], "lines");
        if (!is_array(ls)) continue;
        for (var j = 0; j < array_length(ls); j++) {
            w = max(w, Ui_DetailsLineNeed(ls[j].label, ls[j].value, _p, variable_struct_exists(ls[j], "delta") && ls[j].delta != 0));
        }
    }
    var cols = max(1, _cols);
    return (w > 0) ? cols * w + (cols - 1) * 3 * _p + 8 * _p : 0;
}

// Does a number line not fit one row of a column _col_w wide? Then the label keeps its row and the value goes right-aligned on the row below (the cards
// do the same, CardsUi_LineStacked): nothing is cut.
function Ui_DetailsLineStacked(_label, _value, _col_w, _p, _delta = false) {
    return Ui_DetailsLineNeed(_label, _value, _p, _delta) > _col_w;
}

// The height of one number line in a column _col_w wide: a row; two rows when the value goes under the label; the label's own wrapped lines plus the value's row
// when the label alone is wider than the column (it wraps, nothing is cut).
function Ui_DetailsLineH(_label, _value, _col_w, _p, _delta, _mt) {
    if (UI_TextWidth(_label) > _col_w) return max(_mt.line_h, Ui_TextBlockH(_label, _col_w)) + _p + _mt.line_h + _p;
    return (Ui_DetailsLineStacked(_label, _value, _col_w, _p, _delta) ? 2 : 1) * (_mt.line_h + _p);
}

// How the number lines of a details panel are laid out, _inner wide, _cols to a row: { rows: [{ h, cells: [{ i (the line), x (from the inner left edge), w (the cell's width) }] }], h }.
// R-108: a row of line cells that are not all one text row tall in their column (a value that would stack under its label, a label that wraps) is not laid out side by side:
// each of its lines takes a row of its own, the whole width ("Damage 17" over "Perfect 22", never a value alone on the row under its label).
function Ui_DetailsPlan(_lines, _inner, _cols, _mt) {
    var p = _mt.p;
    var cols = max(1, _cols);
    var col_w = (_inner - (cols - 1) * 3 * p) / cols;
    var n = array_length(_lines);
    var one = _mt.line_h + p;
    var rows = [];
    var h = 0;
    for (var i = 0; i < n; i += cols) {
        var rh = 0;
        var cells = [];
        var tall = false;
        for (var c = 0; c < cols && i + c < n; c++) {
            var dl = _lines[i + c];
            var ch = Ui_DetailsLineH(dl.label, dl.value, col_w, p, variable_struct_exists(dl, "delta") && dl.delta != 0, _mt);
            if (ch > one) tall = true;
            rh = max(rh, ch);
            array_push(cells, { i: i + c, x: c * (col_w + 3 * p), w: col_w });
        }
        var need_sum = 0;
        for (var c3 = 0; c3 < array_length(cells); c3++) {
            var dl3 = _lines[cells[c3].i];
            need_sum += Ui_DetailsLineNeed(dl3.label, dl3.value, p, variable_struct_exists(dl3, "delta") && dl3.delta != 0);
        }
        if (tall && cols > 1 && array_length(cells) > 1 && need_sum + (array_length(cells) - 1) * 3 * p <= _inner) {
            // the equal columns are too narrow for one of them but the lines fit one row at their own width: first at the left edge, last at the right edge, each as wide as it needs
            var cx = 0;
            for (var c4 = 0; c4 < array_length(cells); c4++) {
                var dl4 = _lines[cells[c4].i];
                var nw = Ui_DetailsLineNeed(dl4.label, dl4.value, p, variable_struct_exists(dl4, "delta") && dl4.delta != 0);
                cells[c4].w = nw;
                cells[c4].x = (c4 == array_length(cells) - 1) ? (_inner - nw) : cx;
                cx += nw + 3 * p;
            }
            array_push(rows, { h: one, cells: cells });
            h += one;
        } else if (tall && cols > 1) {
            for (var c2 = 0; c2 < array_length(cells); c2++) {
                var dl2 = _lines[cells[c2].i];
                var fh = Ui_DetailsLineH(dl2.label, dl2.value, _inner, p, variable_struct_exists(dl2, "delta") && dl2.delta != 0, _mt);
                array_push(rows, { h: fh, cells: [{ i: cells[c2].i, x: 0, w: _inner }] });
                h += fh;
            }
        } else {
            array_push(rows, { h: rh, cells: cells });
            h += rh;
        }
    }
    return { rows: rows, h: h };
}

// The number lines' height in a details panel whose inner width is _inner, _cols to a row.
function Ui_DetailsLinesH(_lines, _inner, _cols, _mt) {
    return Ui_DetailsPlan(_lines, _inner, _cols, _mt).h;
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
    var row_w = 0;   // H13b: the widest single row (marker column, label, value), not the widest label plus the widest value of other rows
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
        row_w = max(row_w, 5 * p + UI_TextWidth(it.label) + (variable_struct_exists(it, "icon_item") ? 10 * p : 0) + ((vw > 0) ? 3 * p + vw : 0));   // the 3p of Ui_MenuLabelRoom
    }
    var title = _m.layout.title;
    var note = _m.layout.note;
    return {
        items: _m.items, n: n, mt: _mt, lang: _lang, title: title, note: note, sig: Ui_MenuSigBuild(_m.items, n), det_need: Ui_MenuDetailsNeed(_m.items, p, _m.layout.details_cols),
        rhs: [], fits: [], extra_h: 0,   // R-106: each row's height and layout in the panel width (Ui_MenuMeasureSizes)
        label_w: label_w, val_w: val_w, row_w: row_w, icon_px: icon_px, title_w: (title != "") ? UI_TextWidth(title) : 0, note_w: (note != "") ? UI_TextWidth(note) : 0,
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
    // R-106 (D168): a label that does not fit beside its value wraps (a taller row) or stacks its value under it; the rows' heights follow
    var rhs = array_create(n, _mt.row_h);
    var fits = array_create(n, undefined);
    var extra = 0;
    if (!L.center) {
        for (var r = 0; r < n; r++) {
            var rw = _m.items[r];
            var rk = variable_struct_exists(rw, "kind") ? rw.kind : "button";
            if (rk == "head") continue;
            var rf = Ui_RowFit(rw.label, variable_struct_exists(rw, "value") ? rw.value : "", panel_w, p, _mc.icon_px, variable_struct_exists(rw, "icon_item"), rk == "button", _mt);
            fits[r] = rf;
            rhs[r] = rf.row_h;
            extra = max(extra, rf.row_h - _mt.row_h);
        }
    }
    _mc.rhs = rhs;
    _mc.fits = fits;
    _mc.extra_h = extra;
}

// Level 1 only (the rows' widths), rebuilt only when its keys changed: what TabMenu_FitMenu reads before it fixes the panel widths.
function Ui_MenuMeasureRowsFresh(_m, _mt) {
    var L = _m.layout;
    var n = array_length(_m.items);
    var lang = Loc_GetLanguage();
    var mc = variable_struct_get(_m, "mc");
    var fresh = is_struct(mc) && mc.items == _m.items && mc.n == n && mc.mt == _mt && mc.lang == lang && mc.title == L.title && mc.note == L.note && Ui_MenuSigSame(_m.items, mc.sig, n);
    if (!fresh) {
        mc = Ui_MenuMeasureRows(_m, _mt, lang);
        _m.mc = mc;
    }
    return mc;
}

// The measured struct of a menu (fields label_w, val_w, icon_px, title_w, panel_w, det_h), rebuilt only when its keys changed.
function Ui_MenuMeasure(_m, _mt) {
    var L = _m.layout;
    var n = array_length(_m.items);
    var mc = Ui_MenuMeasureRowsFresh(_m, _mt);
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

// R-108: the number lines a details panel keeps when it has to give way (the battle panel under the enemy). Level 1: the lines the row marks keep: true (a skill's Damage, Perfect and MP); a
// row that marks none keeps its first line (an item's main effect); the rest (Power, Hits, Turns, Chance, Carry Limit...) go first. Level 2 (the last resort): of those, the lines the list row
// already shows (dup: true, a skill's MP) go too, and a row that marks none keeps no line. Order as given.
function Ui_DetailsKeepLines(_lines, _level = 1) {
    var n = array_length(_lines);
    var out = [];
    if (_level >= 3) return out;   // I-107: the very last resort before the list goes below two rows: no number line at all (the sentence stays)
    var marked = false;
    for (var i = 0; i < n; i++) if (variable_struct_exists(_lines[i], "keep") && _lines[i].keep) marked = true;
    for (var j = 0; j < n; j++) {
        var kept = marked ? (variable_struct_exists(_lines[j], "keep") && _lines[j].keep) : (j == 0);
        if (kept && _level >= 2 && (!marked || (variable_struct_exists(_lines[j], "dup") && _lines[j].dup))) kept = false;
        if (kept) array_push(out, _lines[j]);
    }
    return out;
}

// The height a panel above its list takes under a floor: details _det_h, the gap, the list's chrome and _rows rows (tall rows counted at the most any rows can add; one row is the highlighted row's own).
function Ui_AboveNeed(_det_h, _gap, _chrome_y, _rows, _rhs, _mt, _cur) {
    return _det_h + _gap + _chrome_y + ((_rows <= 1) ? _rhs[_cur] : (_rows * _mt.row_h + Ui_ExtraSum(_rhs, _mt.row_h, _rows)));
}

// The geometry of a menu for one draw: the list panel, the details panel, the rows' window, from the measured struct _mm (Ui_MenuMeasure) and the menu's layout. Pure: it draws and
// stores nothing (Ui_MenuDraw draws from it; the fit checks read it without a draw). _alpha slides the panel in (D97).
function Ui_MenuGeom(_m, _mt, _mm, _alpha = 1) {
    var mt = _mt;
    var p = mt.p;
    var L = _m.layout;
    var n = array_length(_m.items);
    var mm = _mm;
    var icon_px = mm.icon_px;     // the icon column (battle lists): one icon pixel is k GUI units, k = whole units that fit a row
    var panel_w = mm.panel_w;
    var title_fit = (L.title != "") ? Ui_TitleFit(L.title, panel_w - 8 * p, mt) : undefined;   // R-106: a title wider than the panel wraps (a long skill name in "Learn X: Replace Which?")
    var header_h = (L.title != "") ? (title_fit.h + 3 * p) : 0;
    var note_h = (L.note != "") ? (mt.line_h + 2 * p) : 0;   // D143: one line under the title (the level-up screen's class growth)
    var chrome_y = 2 * (4 * p) + header_h + note_h;
    var rhs = mm.rhs;             // R-106: each row's height (a label that wraps makes a taller row) and how its label is laid out
    var extra = mm.extra_h;       // the most any row is taller than a normal one (0: every row is a normal row)
    var all_h = (n > 0) ? Ui_RowsH(rhs, 0, n - 1) : 0;
    var det_h = mm.det_h;         // the tallest sentence (so the list does not jump between items); the highlighted item's own when the panel is above
    var rows_lim = n;             // G10: fewest rows the details panel's floor may force
    var seq_drop = false;         // G10: the arrow strip is left out of the details when nothing else makes room
    var gap = mt.margin;          // the space between the list and its details panel
    var one_row = false;          // R-106: the list is a window of one row, as tall as the highlighted row
    var lines_level = 0;          // R-108: 0 = every number line is shown, 1 = the kept lines, 2 = the last resort, 3 = none (I-107) (Ui_DetailsKeepLines)
    var det_tight = false;        // R-108: the last resort: the panels share a border (gap -2p) and the details have one pixel unit of air inside the frame, not two
    var det_step = 0;             // R-108: the sentence is set one type step smaller (the last resort)
    var hint_hidden = false;      // R-108: the prompt line over the details panel is left out when nothing else makes room
    var cur_it = (n > 0) ? _m.items[clamp(_m.cursor, 0, n - 1)] : undefined;
    var lines_shown = (is_struct(cur_it) && variable_struct_exists(cur_it, "lines")) ? cur_it.lines : [];   // the number lines the details panel draws
    if (L.details && L.details_pos == "above" && det_h > 0 && n > 0 && L.det_floor_y >= 0) {
        // G10 (D129) / R-108: the panel and the list stand under the floor (the enemy). When they do not fit: the details drop their least important lines first (every line that is
        // not kept, then the arrow strip), then the list shows fewer rows (two, then one); last, the gap between the panels shrinks to one pixel unit.
        var fit_bottom = (L.y_bottom >= 0) ? L.y_bottom : (mt.gh - mt.margin);
        var fit_room = fit_bottom - L.det_floor_y;
        var fit_rows = (L.rows_max > 0) ? min(n, L.rows_max) : n;
        var ci = clamp(_m.cursor, 0, n - 1);
        if (Ui_AboveNeed(det_h, mt.margin, chrome_y, fit_rows, rhs, mt, ci) > fit_room) {
            var seq_n = (is_struct(cur_it) && variable_struct_exists(cur_it, "seq")) ? array_length(cur_it.seq) : 0;
            var keeps = [lines_shown, Ui_DetailsKeepLines(lines_shown, 1), Ui_DetailsKeepLines(lines_shown, 2), Ui_DetailsKeepLines(lines_shown, 3)];   // by level: 0 all, 1 kept, 2 last resort, 3 none (I-107)
            var cols = L.details_cols;
            var sent = is_struct(cur_it) ? cur_it.help : "";
            // [lines level, keep the arrow strip, rows, hide the hint, the sentence's type step, tight: the panels share a border and the details have less air]
            // I-107: a list of 2+ entries never goes below two rows until everything else has given way (rows2: two, or one when there is one entry to show); the one-row steps come last.
            var rows2 = min(2, fit_rows);
            var steps = [[1, true, fit_rows, false, 0, false], [1, false, fit_rows, false, 0, false], [1, false, rows2, false, 0, false], [1, false, rows2, true, 0, false],
                         [2, false, rows2, true, 0, false], [2, false, rows2, true, 1, false], [2, false, rows2, true, 1, true],
                         [3, false, rows2, true, 0, false], [3, false, rows2, true, 1, false], [3, false, rows2, true, 1, true],
                         [1, false, 1, false, 0, false], [1, false, 1, true, 0, false], [2, false, 1, true, 0, false], [2, false, 1, true, 1, false], [2, false, 1, true, 1, true]];
            var pick = array_length(steps) - 1;
            var picked_h = -1;
            var picked_room = fit_room;
            for (var st = 0; st < array_length(steps); st++) {
                var st_room = (steps[st][3] && L.det_floor_alt >= 0) ? (fit_bottom - L.det_floor_alt) : fit_room;
                var sh = Ui_DetailsHeight(panel_w, sent, keeps[steps[st][0]], cols, steps[st][1] ? seq_n : 0, undefined, steps[st][4], steps[st][5]);
                var st_gap = steps[st][5] ? -2 * p : ((steps[st][2] == 1) ? p : mt.margin);   // a window of one row may shrink the gap to one pixel unit
                if (Ui_AboveNeed(sh, st_gap, chrome_y, steps[st][2], rhs, mt, ci) <= st_room || st == array_length(steps) - 1) { pick = st; picked_h = sh; picked_room = st_room; break; }
            }
            lines_shown = keeps[steps[pick][0]];
            lines_level = steps[pick][0];
            if (!steps[pick][1] && seq_n > 0) seq_drop = true;
            hint_hidden = steps[pick][3];
            det_step = steps[pick][4];
            det_tight = steps[pick][5];
            det_h = picked_h;
            rows_lim = steps[pick][2];
            if (det_tight) gap = -2 * p;
            if (rows_lim == 1) {   // R-106: a window of one row is as tall as the highlighted row (not the tallest); still too tall for the room: the gap between the panels shrinks to one pixel unit
                one_row = true;
                if (!det_tight && Ui_AboveNeed(det_h, gap, chrome_y, 1, rhs, mt, ci) > picked_room) gap = p;
            }
        }
    }
    var det_right = (L.details && L.details_pos == "right");   // D90: beside the list, as tall as the list (the Tab menu)
    var avail_h = ((L.max_h > 0) ? L.max_h : (mt.gh - 2 * mt.margin)) - ((det_h > 0) ? det_h + gap : 0);
    var rows_vis = clamp(floor((avail_h - chrome_y) / mt.row_h), 1, max(1, n));
    while (rows_vis > 1 && rows_vis * mt.row_h + Ui_ExtraSum(rhs, mt.row_h, rows_vis) > avail_h - chrome_y) rows_vis--;   // R-106: rows that wrap are taller
    if (det_right) rows_vis = max(1, floor((avail_h - chrome_y) / mt.row_h));   // the panel keeps its size whatever the row count
    if (L.rows_max > 0) rows_vis = min(rows_vis, L.rows_max);
    rows_vis = min(rows_vis, max(1, rows_lim));
    // the room the rows have: rows_vis rows, each as tall as the tallest rows are (so any window of that many rows is whole); the panel beside the list uses all it has
    var list_room = (n <= 0) ? rows_vis * mt.row_h : (one_row ? rhs[clamp(_m.cursor, 0, n - 1)] : (det_right ? ((extra > 0) ? (avail_h - chrome_y) : rows_vis * mt.row_h) : min(all_h, rows_vis * mt.row_h + Ui_ExtraSum(rhs, mt.row_h, rows_vis))));
    var panel_h = det_right ? avail_h : (chrome_y + list_room);
    var total_h = panel_h + ((det_h > 0) ? gap + det_h : 0);
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
    var list_y = det_above ? (py + det_h + gap) : py;     // the list panel's top; the details panel is above or below it
    var det_y = det_above ? py : (py + panel_h + gap);
    var rect = { x: px, y: list_y, w: panel_w, h: panel_h };
    var det_rect = (det_h > 0) ? { x: px, y: det_y, w: panel_w, h: det_h } : { x: 0, y: 0, w: 0, h: 0 };
    if (det_right) {
        var dx = px + panel_w + mt.margin;
        det_rect = { x: dx, y: ((L.det_top >= 0) ? L.det_top - slide : list_y), w: (L.det_w > 0) ? L.det_w : max(0, mt.gw - mt.margin - dx), h: (L.det_h >= 0) ? L.det_h : panel_h };
    }
    return { rect: rect, det_rect: det_rect, icon_px: icon_px, panel_w: panel_w, title_fit: title_fit, header_h: header_h, note_h: note_h, chrome_y: chrome_y, rhs: rhs, extra: extra, all_h: all_h, det_h: det_h, seq_drop: seq_drop,
             gap: gap, det_right: det_right, list_room: list_room, panel_h: panel_h, total_h: total_h, px: px, py: py, slide: slide, det_above: det_above, list_y: list_y, det_y: det_y, one_row: one_row, rows_lim: rows_lim, rows_vis: rows_vis, lines_shown: lines_shown, lines_level: lines_level, hint_hidden: hint_hidden, det_step: det_step, det_tight: det_tight, cue_on: (n > 0 && variable_struct_exists(L, "scroll_cue") && L.scroll_cue) };
}

// I-107: the scroll cue of a list (layout.scroll_cue, the battle Skill and Item lists): an up triangle at the top edge of the frame when rows are hidden above, a down triangle at
// the bottom edge when rows are hidden below (both in the middle of the frame, 5p wide and 3p tall), and a "3/7" counter on a small plate at the bottom right corner (the plate sits
// on the frame's bottom edge, 2p of it below the frame, 7p tall). _top = the list's first visible row. Rectangles { x, y, w, h }; w = 0 for an arrow that is not shown. Pure.
function Ui_MenuCue(_m, _mt, _g, _top) {
    var p = _mt.p;
    var n = array_length(_m.items);
    var none = { x: 0, y: 0, w: 0, h: 0 };
    if (n <= 0) return { counter: "", counter_rect: none, up: none, down: none, digits_x: 0, digits_y: 0 };
    var r = _g.rect;
    var end_row = Ui_RowsEnd(_g.rhs, _top, _g.list_room);
    var ax = r.x + (r.w - 5 * p) div 2;
    var cur = clamp(_m.cursor, 0, n - 1);
    var txt = string(cur + 1) + "/" + string(n);
    var pw = Battle_DigitsWidth(txt, p) + 4 * p;
    var plate = { x: r.x + r.w - p - pw, y: r.y + r.h - 5 * p, w: pw, h: 7 * p };
    return { counter: txt, counter_rect: plate, digits_x: plate.x + 2 * p, digits_y: plate.y + p,
             up: (_top > 0) ? { x: ax, y: r.y + p, w: 5 * p, h: 3 * p } : none,
             down: (end_row < n - 1) ? { x: ax, y: r.y + r.h - 4 * p, w: 5 * p, h: 3 * p } : none };
}

// A triangle _dir -1 (apex up, widths 1 3 5 from the top) or +1 (apex down) in a 5p x 3p box at (_x, _y).
function Ui_DrawTri(_x, _y, _dir, _p, _col) {
    for (var i = 0; i < 3; i++) {
        var wc = (_dir < 0) ? (1 + 2 * i) : (5 - 2 * i);
        Ui_Box(_x + ((5 - wc) div 2) * _p, _y + i * _p, _x + ((5 - wc) div 2 + wc) * _p, _y + (i + 1) * _p, _col);
    }
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
    var g = Ui_MenuGeom(_m, mt, mm, _alpha);
    var icon_px = g.icon_px;      // the icon column (battle lists): one icon pixel is k GUI units, k = whole units that fit a row
    var panel_w = g.panel_w;
    var title_fit = g.title_fit;
    var header_h = g.header_h;
    var note_h = g.note_h;
    var rhs = g.rhs;              // R-106: each row's height (a label that wraps makes a taller row) and how its label is laid out
    var extra = g.extra;          // the most any row is taller than a normal one (0: every row is a normal row)
    var det_h = g.det_h;          // the highlighted item's own when the panel is above (the tallest sentence otherwise)
    var seq_drop = g.seq_drop;    // G10: the arrow strip is left out of the details when nothing else makes room
    var det_right = g.det_right;
    var list_room = g.list_room;
    var panel_h = g.panel_h;
    var px = g.px;
    var slide = g.slide;
    var det_above = g.det_above;
    var list_y = g.list_y;
    var det_y = g.det_y;
    _m.rect = g.rect;
    _m.det_rect = g.det_rect;
    _m.hint_hidden = g.hint_hidden;

    _m.top = Ui_ScrollTopH(_m.cursor, _m.top, rhs, list_room);
    var vis_end = (n > 0) ? Ui_RowsEnd(rhs, _m.top, list_room) : -1;
    var offs = array_create(n + 1, 0);   // where each row starts, from the first row
    for (var o = 0; o < n; o++) offs[o + 1] = offs[o] + rhs[o];
    var top_off = offs[_m.top];
    Ui_DrawFrame(px, list_y, panel_w, panel_h, _alpha, p);
    draw_set_alpha(_alpha);

    var x0 = px + 4 * p;
    var x1 = px + panel_w - 4 * p;
    var ty0 = list_y + 4 * p;
    if (L.title != "") {
        if (title_fit.lines > 1 || title_fit.step > 0) Ui_TextBlockStep(x0, ty0 + title_fit.y_off, L.title, panel_w - 8 * p, UI_C_LIGHTEST, title_fit.step);
        else Ui_Text(x0, ty0, L.title, UI_C_LIGHTEST);
        Ui_Box(px + 3 * p, ty0 + title_fit.h + p, px + panel_w - 3 * p, ty0 + title_fit.h + 2 * p, UI_C_DARK);
        ty0 += header_h;
    }
    if (L.note != "") {
        Ui_Text(x0, ty0, Ui_FitText(L.note, x1 - x0), variable_struct_exists(L, "note_col") ? L.note_col : UI_C_LIGHT);
        ty0 += note_h;
    }
    var rows_y0 = ty0;

    // rectangles for the mouse (rows outside the window can't be hit)
    var rects = array_create(n);
    for (var r = 0; r < n; r++) {
        var vis = (r >= _m.top && r <= vis_end);
        rects[r] = { x: px + 2 * p, y: rows_y0 + offs[r] - top_off, w: vis ? (panel_w - 4 * p) : 0, h: vis ? rhs[r] : 0 };
    }
    _m.rects = rects;
    var bars = array_create(n);   // D182: each slider row's bar, for a click and a drag
    for (var br0 = 0; br0 < n; br0++) bars[br0] = { x: 0, y: 0, w: 0, h: 0 };
    _m.bars = bars;

    // gliding highlight band
    var cur_i = clamp(_m.cursor, 0, max(0, n - 1));
    var target_y = rows_y0 + offs[cur_i] - top_off;
    if (_m.cur_y < 0) _m.cur_y = target_y;
    _m.cur_y = Ui_MenuBandY(_m, target_y, now - _m.last_draw_ms);
    _m.last_draw_ms = now;
    var band_y = round(_m.cur_y);
    var band_h = (n > 0) ? rhs[cur_i] : mt.row_h;
    if (n > 0) Ui_Box(px + 2 * p + p, band_y, px + panel_w - 2 * p - p, band_y + band_h, UI_C_DARK);

    for (var k = _m.top; k <= vis_end; k++) {
        var row = _m.items[k];
        var ry = rows_y0 + offs[k] - top_off;
        var rh = rhs[k];
        var ty = ry + (rh - mt.line_h) div 2;
        var sel = (k == _m.cursor);
        var en = Ui_ItemEnabled(row);
        var kd = variable_struct_exists(row, "kind") ? row.kind : "button";
        var dim = variable_struct_exists(row, "dim") && row.dim;   // looks unavailable but can be selected (a shop row you cannot pay for, a skill you lack the MP for)
        var style = Ui_RowStyle(row, sel);   // D115: names are white, selected or not; R3: a header is a dark strip with pale text
        var col = style.text;
        var lcol = Ui_RowLabelColor(row, sel);   // D178: an item's name in its rarity colour (not on a dim row)
        var hr = undefined;
        if (kd == "head") {   // R-106 follow-up: no fill (the cursor band is the dark green); the text, then a thin rule to the right edge of the list (below)
            hr = Ui_HeadRect(px + 3 * p, px + panel_w - 3 * p, ry, mt.row_h, p, k == 0);
            ty = hr.y + (hr.h - mt.line_h) div 2;
        } else if (variable_struct_exists(row, "flash_at") && Ui_FlashOn(now - row.flash_at)) {   // R3 note 25: the Controls rows a reset changed blink
            Ui_Box(px + 3 * p, ry, px + panel_w - 3 * p, ry + rh, UI_C_LIGHTEST);
            col = UI_C_DARKEST;
            lcol = col;
        }
        var label_x = x0 + 5 * p;
        if (icon_px > 0) {   // { cat, frame }: an Icon_Get picture (skills, statuses)
            if (variable_struct_exists(row, "icon") && is_struct(row.icon)) {
                var ic = Icon_Get(row.icon.cat, row.icon.frame);
                if (is_struct(ic)) draw_sprite_ext(ic.spr, ic.sub, label_x, ry + (rh - icon_px) div 2, icon_px / 16, icon_px / 16, 0, c_white, (dim && !sel) ? _alpha * 0.55 : _alpha);
            }
            label_x += icon_px + 2 * p;
        }
        if (variable_struct_exists(row, "icon_item")) {   // C3: an item's picture
            Item_DrawIcon(row.icon_item, label_x, ry + (rh - 8 * p) div 2, 8 * p, dim ? 0.6 : 1);
            label_x += 10 * p;
        }
        var fit = (!L.center && kd != "head") ? mm.fits[k] : undefined;   // R-106 (D168): how this row's label is laid out in the panel
        var stacked = false;
        var vty = ty;   // where the value's line is drawn
        var shown_label = row.label;
        if (L.center) {
            Ui_Text((x0 + x1) / 2, ty, row.label, col, fa_center);
        } else if (is_struct(fit) && fit.ok && fit.mode != "one") {   // wrapped over two lines or a step smaller; a stacked row has its value on a line under the label
            stacked = (fit.mode == "stack");
            var lby = stacked ? (ry + p + fit.y_off) : (ry + (rh - fit.h) div 2 + fit.y_off);
            Ui_TextBlockStep(label_x, lby, row.label, fit.room, lcol, fit.step);
            if (stacked) vty = ry + fit.value_y;
        } else {
            if (!is_struct(fit) || !fit.ok) {   // a row no layout fits (a head row, or the last resort): ".." before it reaches the value
                var vroom = Ui_MenuLabelRoom(panel_w, p, icon_px, variable_struct_exists(row, "icon_item"), variable_struct_exists(row, "value") ? row.value : "");
                shown_label = Ui_FitText(row.label, vroom);
            }
            Ui_Text(label_x, ty, shown_label, lcol);
        }
        if (is_struct(hr) && style.rule != -1 && !L.center) {   // the header's rule: 1 px, from the end of the text to the right edge of the list, level with the middle of the text
            var rule_x = label_x + UI_TextWidth(row.label) + 2 * p;
            var rule_y = ty + (mt.line_h - p) div 2;
            Ui_Box(rule_x, rule_y, hr.x + hr.w, rule_y + p, style.rule);
        }
        var vx = x1;
        if (kd == "choice" && variable_struct_exists(row, "value")) {
            if (sel && en) {
                Ui_Arrow(x1 - 3 * p, ry + (rh - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
            }
            vx = x1 - 5 * p;
            Ui_Text(vx, ty, row.value, col, fa_right);
            if (sel && en) {
                Ui_Arrow(vx - UI_TextWidth(row.value) - 5 * p, ry + (rh - 5 * p) div 2, -1, p, UI_C_LIGHTEST);
            }
        } else if (kd == "slider") {
            Ui_Text(x1, ty, row.value, col, fa_right);
            var bx = x1 - UI_TextWidth("100%") - 2 * p - bar_w;
            var by = ry + (rh - 2 * p) div 2;
            Ui_Box(bx, by, bx + bar_w, by + 2 * p, sel ? UI_C_DARKEST : UI_C_DARK);
            var fill = floor(clamp(row.amount, 0, 1) * (bar_w / p) + 0.5) * p;
            Ui_Box(bx, by, bx + fill, by + 2 * p, sel ? UI_C_LIGHTEST : UI_C_LIGHT);
            bars[k] = { x: bx, y: ry, w: bar_w, h: rh };
        } else if (variable_struct_exists(row, "value") && row.value != "") {
            var vspec = Ui_RowValueSpec(row, sel);
            if (vspec.new != "") {   // I-109: "12 > " in the row colour, the new number in its own (gold)
                Ui_Text(x1, vty, vspec.new, vspec.new_col, fa_right);
                Ui_Text(x1 - UI_TextWidth(vspec.new), vty, vspec.old, vspec.old_col, fa_right);
            } else {
                Ui_Text(x1, vty, row.value, col, fa_right);
            }
        }
    }
    // marker: follows the glide, bobs one pixel
    if (n > 0) {
        Ui_Arrow(x0 + Ui_Bob(now) * p, band_y + (band_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    }
    if (g.cue_on) {   // I-107: the triangles and the counter (the one-pixel marks below are for the other lists)
        var cue = Ui_MenuCue(_m, mt, g, _m.top);
        if (cue.up.w > 0) Ui_DrawTri(cue.up.x, cue.up.y, -1, p, UI_C_LIGHTEST);
        if (cue.down.w > 0) Ui_DrawTri(cue.down.x, cue.down.y, 1, p, UI_C_LIGHTEST);
        var pl = cue.counter_rect;
        Ui_Box(pl.x, pl.y, pl.x + pl.w, pl.y + pl.h, UI_C_LIGHTEST);
        Ui_Box(pl.x + p, pl.y, pl.x + pl.w - p, pl.y + pl.h - p, UI_C_DARKEST);
        Battle_DrawDigits(cue.digits_x, cue.digits_y, cue.counter, p, UI_C_LIGHTEST);
    } else if (n > 0 && (_m.top > 0 || vis_end < n - 1)) {   // a scroll hint when the list is longer than its window
        if (_m.top > 0) Ui_Box(px + panel_w - 4 * p, rows_y0 - p, px + panel_w - 3 * p, rows_y0, UI_C_LIGHT);
        if (vis_end < n - 1) Ui_Box(px + panel_w - 4 * p, rows_y0 + list_room, px + panel_w - 3 * p, rows_y0 + list_room + p, UI_C_LIGHT);
    }

    if (det_h > 0 && n > 0) {
        var cur = _m.items[_m.cursor];
        if (variable_struct_exists(cur, "help")) {
            Ui_DrawDetails(px, det_y, panel_w, det_h, cur.help, g.lines_shown, _alpha, L.details_cols, (variable_struct_exists(cur, "seq") && !seq_drop) ? cur.seq : [], undefined, g.det_step, g.det_tight);
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
function Ui_StackDraw(_stk, _dim_alpha = UI_DIM_POPUP) {
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
    if (UiFit_On()) global.uifit.frames = [];   // H13b: a full-screen dim starts a new layer; text after it is not measured against the panels under it
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
// H13b (D156): the box of the confirm pop-up for _question: { x, y, w, h, iw, qh }, centred on the GUI grid. Pure.
function Confirm_Box(_question, _mt) {
    var p = _mt.p;
    var w = min(_mt.gw - 2 * _mt.margin, max(round(_mt.gw * 0.6), 80 * p));
    var iw = w - 8 * p;
    var qh = Ui_TextBlockH(_question, iw);
    var h = 11 * p + qh + 2 * _mt.row_h;   // 4p above, the question, 3p with the rule, two rows, 4p below
    return { x: round((_mt.gw - w) / 2), y: max(_mt.margin, round((_mt.gh - h) / 2)), w: w, h: h, iw: iw, qh: qh };
}

function Confirm_Draw(_a = 1) {
    if (!Confirm_IsOpen()) return;
    var c = global.confirm_ui;
    var m = c.menu;
    var mt = Ui_Metrics();
    var p = mt.p;
    var now = current_time;
    var a = Ui_AnimT(c.opened_ms, now) * _a;
    var cb = Confirm_Box(c.question, mt);
    var w = cb.w;
    var iw = cb.iw;
    var qh = cb.qh;
    var h = cb.h;
    var bx = cb.x;
    var by = cb.y;
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
    Ui_DimBackdrop(UI_DIM_POPUP * a);
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
