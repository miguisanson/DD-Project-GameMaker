event_inherited();
sprite_id = spr_red;
interact_name = Loc_T("interact.name.obj_grave", "Grave");
dialogue_id = "";

grave_interactable = true;
ghost_spawn_chance = 0.60;
ghost_marker_id = "";
ghost_duration_frames = game_get_speed(gamespeed_fps);
grave_lines = [
    Loc_T("interact.grave.line.obj_grave.0", "A worn grave marker sinks into the soil."),
    Loc_T("interact.grave.line.obj_grave.1", "An old grave rests here, quiet and cold."),
    Loc_T("interact.grave.line.obj_grave.2", "The stone is cracked, but the name is long gone."),
    Loc_T("interact.grave.line.obj_grave.3", "You brush away dust from a weathered grave."),
    Loc_T("interact.grave.line.obj_grave.4", "A faded grave stands in the silence."),
    Loc_T("interact.grave.line.obj_grave.5", "Moss creeps over the edge of this grave."),
    Loc_T("interact.grave.line.obj_grave.6", "The earth around this grave feels recently disturbed."),
    Loc_T("interact.grave.line.obj_grave.7", "A neglected grave marker leans to one side."),
    Loc_T("interact.grave.line.obj_grave.8", "This grave has been here for a long, long time."),
    Loc_T("interact.grave.line.obj_grave.9", "Only silence answers from this old grave.")
];
