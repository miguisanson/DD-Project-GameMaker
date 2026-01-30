if (!variable_instance_exists(id, "transition_id")) transition_id = "";
// Direction gate: require movement into the transition direction
if (!variable_instance_exists(id, "require_dir")) require_dir = -1; // -1 = any
if (!variable_instance_exists(id, "require_move")) require_move = true;
