if (defeated) exit;
if (Transition_IsActive()) exit;
if (other.battle_cooldown > 0) exit;
if (encounter_pending) exit;

// Match dialogue-trigger behavior: queue encounter and let player finish
// the current grid step before starting battle/auto-resolve.
encounter_pending = true;
encounter_player = other;
