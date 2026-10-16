Input_PreStep();
var gs = GameState_Get();

if (Notice_IsOpen()) {   // F3a: the notice pop-up owns the keys (the ui controller steps it); the title waits behind it
    title_refresh = true;   // a save may have been made or deleted meanwhile
    exit;
}
if (Transition_IsInputLocked() && state != "cutscene") return;
var step_ms = Presentation_StepMs(delta_time);   // D108 F2a: the boot logo, the cutscene holds and the credits roll run on a ms clock

if (state == "boot_logo") {
    if (Transition_IsActive()) return;

    switch (boot_logo_phase) {
        case 0: // fade in
            boot_logo_timer += step_ms;
            var in_t = clamp(boot_logo_timer / max(1, boot_logo_fade_in_ms), 0, 1);
            // smoothstep easing keeps the intro logo fade seamless and bell-curved
            boot_logo_alpha = in_t * in_t * (3 - (2 * in_t));
            if (boot_logo_timer + TRANSITION_DONE_SLACK_MS >= max(1, boot_logo_fade_in_ms)) {
                boot_logo_phase = 1;
                boot_logo_timer = 0;
                boot_logo_alpha = 1;
            }
            break;

        case 1: // hold
            boot_logo_timer += step_ms;
            boot_logo_alpha = 1;
            if (boot_logo_timer + TRANSITION_DONE_SLACK_MS >= max(0, boot_logo_hold_ms)) {
                boot_logo_phase = 2;
                boot_logo_timer = 0;
            }
            break;

        case 2: // fade out
            boot_logo_timer += step_ms;
            var out_t = clamp(boot_logo_timer / max(1, boot_logo_fade_out_ms), 0, 1);
            out_t = out_t * out_t * (3 - (2 * out_t));
            boot_logo_alpha = 1 - out_t;
            if (boot_logo_timer + TRANSITION_DONE_SLACK_MS >= max(1, boot_logo_fade_out_ms)) {
                boot_logo_phase = 3;
                boot_logo_timer = 0;
                boot_logo_alpha = 0;
            }
            break;

        default: // black hold, then reveal title menu
            boot_logo_timer += step_ms;
            boot_logo_alpha = 0;
            if (boot_logo_timer + TRANSITION_DONE_SLACK_MS >= max(0, boot_logo_black_hold_ms)) {
                state = "splash";   // D128: the title art with a blinking prompt; a key goes on to the menu (Title_SplashStep)
                title_t0 = current_time;
                Transition_RequestBlackFlash(1, TRANSITION_CUTSCENE_FADE_IN_FRAMES);
            }
            break;
    }

    return;
}

if (state == "credits") {   // C5 (D105): the credits roll after the ending's closing text; hold confirm to skip it (D48)
    Skip_Claim();
    credits_t += step_ms;
    if (credits_t >= Credits_TotalMs() || Skip_Consume()) {
        Skip_Reset();
        state = "credits_end";
        Transition_RequestCutsceneFade(rm_start);
    }
    return;
}
if (state == "credits_end") return;

if (state == "run_flow") {   // C1: run summary, new run (scr_room_state RunFlow_*)
    RunFlow_Step();
    return;
}

if (state == "splash") {   // D128: the menu takes no key until the splash is over
    Title_SplashStep(id);
    return;
}

if (state == "main" || state == "settings") {
    Title_Step(id);   // scr_menu.gml: the title menu, the settings popup
    return;
}

if (state == "cutscene") {
    // D48 / I-055 / D146: holding confirm for 2 s skips the whole cutscene (the prompt shows from 1 s) (it still counts as seen: the end block below runs as usual).
    // A tap only advances text. Not counted while the cutscene is not running, nor once it is already ending.
    if (!variable_instance_exists(id, "cutscene_skip")) cutscene_skip = false;
    if (cutscene_started && !cutscene_skip) {
        Skip_Claim();
        if (Skip_Consume()) cutscene_skip = true;
    }

    // Allow first cutscene segment to initialize under the entry fade so the
    // first image reveals with fade-in (instead of popping after fade ends).
    // Still block processing while transitioning out of rm_cutscene.
    var allow_entry_bootstrap = false;
    if (!cutscene_started && Transition_IsInputLocked() && variable_struct_exists(gs, "transition_fx") && is_struct(gs.transition_fx)) {
        var tr_boot = gs.transition_fx;
        if (tr_boot.active && tr_boot.type == TRANSITION_TYPE_CUTSCENE && tr_boot.target_room == room) {
            allow_entry_bootstrap = true;
        }
    }
    if (Transition_IsInputLocked() && !cutscene_wait_transition && !allow_entry_bootstrap) return;

    if (!cutscene_started) {
        cutscene_id = "";
        if (variable_struct_exists(gs, "pending_cutscene_id")) {
            cutscene_id = string(gs.pending_cutscene_id);
        }
        if (cutscene_id == "") cutscene_id = "intro";
        cutscene_sequence = [];
        if (variable_struct_exists(cutscene_definitions, cutscene_id)) {
            var seq = variable_struct_get(cutscene_definitions, cutscene_id);
            if (is_array(seq)) cutscene_sequence = seq;
        }

        if (is_array(cutscene_sequence)) {
            for (var segi = 0; segi < array_length(cutscene_sequence); segi++) {
                var seg_loc = cutscene_sequence[segi];
                if (!is_struct(seg_loc)) continue;
                if (!variable_struct_exists(seg_loc, "lines") || !is_array(seg_loc.lines)) continue;
                for (var li_loc = 0; li_loc < array_length(seg_loc.lines); li_loc++) {
                    var fallback_loc = string(seg_loc.lines[li_loc]);
                    seg_loc.lines[li_loc] = Loc_T("cutscene." + cutscene_id + "." + string(segi) + "." + string(li_loc), fallback_loc);
                }
                cutscene_sequence[segi] = seg_loc;
            }
        }

        if (!is_array(cutscene_sequence) || array_length(cutscene_sequence) <= 0) {
            Transition_RequestCutsceneFade(rm_start);
            return;
        }

        cutscene_started = true;
        cutscene_segment_index = 0;
        cutscene_segment_hold_timer = 0;
        cutscene_wait_transition = false;
        cutscene_transition_next_index = -1;
        cutscene_transition_switched = false;

        gs.ui.cutscene_active = true;
        gs.ui.dialogue_box_half = false;
        gs.ui.cutscene_logo_sprite = noone;
        gs.ui.cutscene_logo_alpha = 0;

        var seg0 = cutscene_sequence[cutscene_segment_index];
        cutscene_segment_hold_timer = Cutscene_SegmentApply(seg0);
        return;
    }

    if (cutscene_wait_transition) {
        if (Transition_IsActive()) {
            if (!cutscene_transition_switched
            && variable_struct_exists(gs, "transition_fx")
            && is_struct(gs.transition_fx)
            && gs.transition_fx.type == TRANSITION_TYPE_FLASH
            && gs.transition_fx.alpha >= 0.999) {
                cutscene_segment_index = cutscene_transition_next_index;
                cutscene_segment_hold_timer = 0;
                var seg_sw = cutscene_sequence[cutscene_segment_index];
                cutscene_segment_hold_timer = Cutscene_SegmentApply(seg_sw);

                cutscene_transition_switched = true;
            }
            return;
        }

        if (!cutscene_transition_switched && cutscene_transition_next_index >= 0 && cutscene_transition_next_index < array_length(cutscene_sequence)) {
            cutscene_segment_index = cutscene_transition_next_index;
            cutscene_segment_hold_timer = 0;
            var seg_fallback = cutscene_sequence[cutscene_segment_index];
            cutscene_segment_hold_timer = Cutscene_SegmentApply(seg_fallback);
        }

        cutscene_wait_transition = false;
        cutscene_transition_next_index = -1;
        cutscene_transition_switched = false;
        return;
    }

    var seg_cur = cutscene_sequence[cutscene_segment_index];
    var seg_cur_lines = variable_struct_exists(seg_cur, "lines") ? seg_cur.lines : [];
    var segment_done = false;

    if (cutscene_skip) {
        // Skipped: close the line that is on screen and go straight to the end below (the same end block as watching to the last line).
        Dialogue_CloseNow();
        gs.ui.lines = [];
        gs.ui.lines_raw = [];
        seg_cur_lines = [];
        cutscene_segment_hold_timer = 0;
    }

    if (is_array(seg_cur_lines) && array_length(seg_cur_lines) > 0) {
        segment_done = (gs.ui.mode != UI_DIALOGUE && array_length(gs.ui.lines) <= 0);
    } else {
        if (cutscene_segment_hold_timer > 0) cutscene_segment_hold_timer -= step_ms;
        segment_done = (cutscene_segment_hold_timer <= TRANSITION_DONE_SLACK_MS);
    }

    if (!variable_struct_exists(gs.ui, "cutscene_logo_sprite")) gs.ui.cutscene_logo_sprite = noone;
    if (!variable_struct_exists(gs.ui, "cutscene_logo_alpha")) gs.ui.cutscene_logo_alpha = 0;
    var logo_target = 0;
    var logo_sprite = noone;
    if (string(cutscene_id) == "ending" && cutscene_segment_index == 4) {
        logo_sprite = pale_rook_1;
        var logo_line_idx = variable_struct_exists(gs.ui, "index") ? max(0, round(real(gs.ui.index))) : 0;
        if (logo_line_idx >= 3) logo_target = 1;
    }
    var logo_step = step_ms / CUTSCENE_LOGO_FADE_MS;   // a full fade takes CUTSCENE_LOGO_FADE_MS (300 ms) at any frame rate
    if (gs.ui.cutscene_logo_alpha < logo_target) {
        gs.ui.cutscene_logo_alpha = min(logo_target, gs.ui.cutscene_logo_alpha + logo_step);
    } else {
        gs.ui.cutscene_logo_alpha = max(logo_target, gs.ui.cutscene_logo_alpha - logo_step);
    }
    if (gs.ui.cutscene_logo_alpha > 0.001 || logo_target > 0) gs.ui.cutscene_logo_sprite = logo_sprite;
    else gs.ui.cutscene_logo_sprite = noone;

    if (!segment_done) return;

    var next_index = cutscene_segment_index + 1;
    if (cutscene_skip) next_index = array_length(cutscene_sequence);
    if (next_index < array_length(cutscene_sequence)) {
        var seg_next = cutscene_sequence[next_index];
        var use_slow_segment_fade = false;
        if (variable_struct_exists(seg_cur, "transition_speed") && string(seg_cur.transition_speed) == "slow") use_slow_segment_fade = true;
        if (variable_struct_exists(seg_next, "transition_speed") && string(seg_next.transition_speed) == "slow") use_slow_segment_fade = true;

        var segment_fade_out = use_slow_segment_fade ? TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_OUT_FRAMES : TRANSITION_CUTSCENE_SEGMENT_FADE_OUT_FRAMES;
        var segment_fade_in = use_slow_segment_fade ? TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_IN_FRAMES : TRANSITION_CUTSCENE_SEGMENT_FADE_IN_FRAMES;
        var flash_ok = Transition_RequestBlackFlash(segment_fade_out, segment_fade_in);

        if (flash_ok) {
            cutscene_wait_transition = true;
            cutscene_transition_next_index = next_index;
            cutscene_transition_switched = false;
            return;
        }

        cutscene_segment_index = next_index;
        cutscene_segment_hold_timer = 0;
        cutscene_segment_hold_timer = Cutscene_SegmentApply(seg_next);
        return;
    }

    // I-051 / H2: cutscene_active, the picture, the text mode and the logo stay set while the exit transition fades to black, so the
    // last image fades out with the screen instead of vanishing first. Transition_PreRoomChange (Cutscene_ClearUiState) clears them.
    gs.ui.cutscene_chars_per_sec = -1;
    gs.pending_cutscene_id = "";

    cutscene_started = false;
    cutscene_sequence = [];
    cutscene_segment_index = -1;
    cutscene_segment_hold_timer = 0;
    cutscene_wait_transition = false;
    cutscene_transition_next_index = -1;
    cutscene_transition_switched = false;
    cutscene_skip = false;
    Skip_Reset();

    switch (cutscene_id) {
        case "intro":
            // C1: the intro is story (D26): marked seen, then the first run starts (the reset of core state moved into Run_StartNew)
            Story_Mark(Story_CutsceneKey("intro"));
            Run_StartNew(true);
            break;
        case "ending":
            Run_OnWin();   // C1: wins + 1; the first win unlocks the Nobody class
            gs.in_main_menu = true;
            Cutscene_ClearUiState();
            Skip_Reset();
            credits_t = 0;
            state = "credits";   // C5 (D105): the credits roll, then the title
            break;
        case "game_over":
            // C1 (D46, D103): no reload after a death. The run is already over in the profile; show the summary, then a new run (the echo comes after its class pick, D130).
            gs.in_main_menu = false;
            RunFlow_Begin();
            state = "run_flow";
            break;
        default:
            Transition_RequestRoomFade(rm_start);
            break;
    }
    return;
}
