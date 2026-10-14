"""v2 prompts, built from the conventions in art/REFERENCES.md.
key -> [promptA, promptB]; each prompt makes 2 images (4 candidates per icon)."""
SKEL = "pixel art, game icon, {conv}, single object, centered, plain background, bold outline, high contrast"
P = {
 # ---- status: debuffs (round badge family) ----
 "status/poison":   ["a green poison droplet with three bubbles rising off it", "a toxic drop with a small skull on it and bubbles"],
 "status/burn":     ["a single red-orange flame, teardrop fire with a light inner flame", "a small campfire flame, two tongues of fire"],
 "status/bleed":    ["a red blood drop with a splash streak underneath", "a blood drop with a slash cut across it"],
 "status/stun":     ["three yellow stars orbiting in a circle, dizzy stars", "a starburst with small stars circling above"],
 "status/break":    ["a shield split in two by a lightning crack, broken shield", "a cracked shield with fragments flying off"],
 "status/sundered": ["a cracked breastplate armor with a jagged crack, broken armor", "a broken chest armor plate with pieces falling"],
 "status/curse":    ["a skull with glowing eyes and a hex mark, cursed skull", "a purple skull with swirling dark aura"],
 # ---- status: buffs (square badge family) ----
 "status/steadfast":["a heavy iron anchor, firm and unmoving", "a stone castle tower rook chess piece, solid and unmoving"],
 "status/guard":    ["a kite shield with a cross emblem, defence up", "a round heater shield with a rivet boss and up arrow"],
 "status/rev_up":   ["a red sword with a green up arrow, attack up", "a flexed bicep muscle arm with an up arrow"],
 "status/evasion":  ["a winged boot with speed lines, dodge", "a white feather with swoosh lines, evade"],
 "status/take_aim": ["a crosshair target reticle with a center dot", "a bullseye target with an arrow stuck in the middle"],
 "status/foresight":["an open eye, eyeball with large iris and pupil and eyelashes", "a mystic all-seeing eye with sparkle"],
 "status/meditation":["a lotus flower in bloom with a small sparkle", "a meditating monk silhouette sitting cross-legged with a glow"],
 "status/solidify": ["a faceted gray stone block, rock slab, hard as stone", "a diamond crystal gem, solid and faceted"],
 "status/bloodthirsty":["vampire fangs dripping a drop of blood", "a bared fanged mouth with a blood drop"],
 "status/blessing": ["a golden halo ring above a white sparkle star", "a pair of white angel wings with a halo"],
 # ---- skills ----
 "skill/wound":     ["a short sword with a blood drop falling from the blade", "a dagger dripping blood"],
 "skill/hilt_bash": ["a sword pommel and crossguard hilt striking with an impact star", "a fist gripping a sword hilt with impact burst"],
 "skill/muscle_up": ["a flexed bicep arm muscle with a shield, power up", "a clenched fist raised with up arrow"],
 "skill/rev_up":    ["a flexed bicep muscle with a flame and up arrow", "a red fist with fire aura, rage"],
 "skill/horizontal_slash":["a wide white crescent sword slash across the icon, horizontal", "a sword swinging horizontally with a curved motion trail"],
 "skill/power_strike":["a large sword raised overhead with impact burst lines, heavy strike", "a sword smashing down with a shockwave star"],
 "skill/poison_arrow":["an arrow with a green dripping poison tip", "an arrow with a green skull drop"],
 "skill/evasion":   ["a winged boot with speed lines", "a boot with a white wing, swift"],
 "skill/double_shot":["two arrows flying side by side, diagonal", "a bow with two arrows nocked"],
 "skill/take_aim":  ["a crosshair target reticle", "a bow with an arrow aimed at a bullseye"],
 "skill/fireball":  ["a round fireball with a blazing flame tail, flying diagonally", "a flaming orb meteor with a trailing fire"],
 "skill/poison_mist":["a green poison gas cloud with bubbles and a skull", "a swirling toxic fog cloud"],
 "skill/ice_spear": ["a diagonal ice spear icicle, blue ice crystal lance", "a sharp icicle shard with a frost sparkle"],
 "skill/meditation":["a lotus flower in bloom with a small sparkle", "a meditating monk silhouette with a glow"],
 "skill/foresight": ["an open eye, eyeball with large iris and pupil", "a mystic all-seeing eye with sparkle"],
 # ---- throwables ----
 "throwable/firebomb":["a round black bomb with a lit fuse and flames", "a red bomb with a burning sparking fuse"],
 "throwable/poison_pot":["a clay pot with green poison dripping and a skull mark", "a green potion flask with a skull label and cork"],
 "throwable/ice_flask":["a round glass flask filled with blue ice and a snowflake", "a corked potion bottle of icy blue liquid with a snowflake"],
 "throwable/smoke_bomb":["a round bomb with a puff of gray smoke cloud", "a small smoke grenade with a billowing smoke puff"],
 # ---- passives ----
 "passive/attack":  ["a sword with a plus sign, power up", "a crossed pair of swords"],
 "passive/defense": ["a round shield with a plus sign", "a heater shield with a metal rim"],
 "passive/vitality":["a red heart", "a heart with a plus cross"],
 "passive/magic":   ["a magic star sparkle with a plus sign", "a glowing blue magic orb with sparkles"],
 "passive/speed":   ["a winged boot, swift", "double chevron arrows pointing right, speed lines"],
 "passive/critical":["a four leaf clover, luck", "a starburst critical hit explosion"],
 "passive/greed":   ["a coin purse bag tied at the top with a coin", "a pile of gold coins"],
 "passive/recovery":["a green leaf with a drop of dew, regeneration", "a green herb sprout with a healing plus"],
 # ---- accessories / misc ----
 "accessory/ring":  ["a gold ring with a large round gem", "a signet ring with a jewel seen from the front"],
 "accessory/charm": ["a round amulet charm pendant on a string", "a lucky charm pendant on a chain with a gem"],
 "misc/gold_coin":  ["a round gold coin with an embossed star mark", "a gold coin seen face-on with a dollar mark"],
}
