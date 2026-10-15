event_inherited();
sprite_id = spr_red;
interact_name = Loc_T("interact.name.obj_grave", "Grave");
dialogue_id = "";

grave_interactable = true;
ghost_spawn_chance = 0.15;
ghost_marker_id = "";
ghost_duration_frames = game_get_speed(gamespeed_fps);
grave_lines = [
    { key: "interact.grave.line.obj_grave.0", text: "A worn grave marker sinks into the soil." },
    { key: "interact.grave.line.obj_grave.1", text: "An old grave rests here, quiet and cold." },
    { key: "interact.grave.line.obj_grave.2", text: "The stone is cracked, but the name is long gone." },
    { key: "interact.grave.line.obj_grave.3", text: "You brush away dust from a weathered grave." },
    { key: "interact.grave.line.obj_grave.4", text: "A faded grave stands in the silence." },
    { key: "interact.grave.line.obj_grave.5", text: "Moss creeps over the edge of this grave." },
    { key: "interact.grave.line.obj_grave.6", text: "The earth around this grave feels recently disturbed." },
    { key: "interact.grave.line.obj_grave.7", text: "A neglected grave marker leans to one side." },
    { key: "interact.grave.line.obj_grave.8", text: "This grave has been here for a long, long time." },
    { key: "interact.grave.line.obj_grave.9", text: "Only silence answers from this old grave." }
];
