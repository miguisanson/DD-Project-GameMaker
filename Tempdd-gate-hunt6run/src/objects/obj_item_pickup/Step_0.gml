var gs = GameState_Get();
var pl = gs.player_inst;
if (!instance_exists(pl)) exit;

if (pl.x == x && pl.y == y) {
    gs.player_ch.inventory = Inv_Add(gs.player_ch.inventory, item_id, qty);
    GameState_SyncLegacy();
    if (variable_instance_exists(id, "persist_id") && persist_id != "") {
        RoomState_SetRemoved(room, persist_id);
    }
    instance_destroy();
}
