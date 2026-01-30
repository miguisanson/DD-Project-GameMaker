var w = display_get_gui_width();
var h = display_get_gui_height();

var title = "Select Class";
var tx = (w - string_width(title)) * 0.5;
var ty = h * 0.25;

draw_set_color(c_white);
draw_text(tx, ty, title);

var start_y = h * 0.45;
for (var i = 0; i < array_length(choices); i++) {
    var label = choices[i];
    var yy = start_y + i * 18;
    if (i == choice_index) {
        draw_set_color(c_white);
        draw_rectangle(w * 0.35, yy - 2, w * 0.65, yy + 14, false);
        draw_set_color(c_black);
        draw_rectangle(w * 0.35, yy - 2, w * 0.65, yy + 14, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    draw_text(w * 0.4, yy, label);
}
