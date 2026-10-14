"""D2 icon manifest: every icon the game needs, with motif prompt and seed.
category -> list of (id, kind, motif). kind: 'badge' (round status badge, glyph inside) or 'item' (free silhouette)."""
STATUSES = [
 ("poison",     "a bubbling poison drop, toxic droplet with bubbles"),
 ("burn",       "a single flame, fire"),
 ("bleed",      "a blood drop"),
 ("stun",       "a starburst impact, dizzy stars"),
 ("steadfast",  "a heavy anchor, firm and unmoving"),
 ("break",      "a cracked broken shield with a lightning crack"),
 ("guard",      "a kite shield"),
 ("rev_up",     "a flexed muscular arm with an up arrow"),
 ("evasion",    "a winged boot with speed lines"),
 ("take_aim",   "a crosshair target reticle with a center dot"),
 ("foresight",  "an open eye, eyeball with pupil"),
 ("meditation", "a lotus flower with a small star"),
 ("solidify",   "a faceted stone block, rock slab"),
 ("bloodthirsty","a vampire fang with a blood drop"),
 ("blessing",   "a halo ring above a small sparkle"),
 ("sundered",   "a cracked armor plate, broken breastplate"),
 ("curse",      "a skull with crossed bones, hex"),
]
SKILLS = [
 ("wound",           "a short sword blade with a blood drop"),
 ("hilt_bash",       "a sword pommel and hilt with an impact star"),
 ("muscle_up",       "a shield beside a clenched fist"),
 ("rev_up",          "a flexed muscular arm with an up arrow"),
 ("horizontal_slash","a wide horizontal crescent sword slash"),
 ("power_strike",    "a big sword overhead strike with impact lines"),
 ("poison_arrow",    "an arrow with a dripping poison tip"),
 ("evasion",         "a winged boot with speed lines"),
 ("double_shot",     "two parallel arrows"),
 ("take_aim",        "a crosshair target reticle"),
 ("fireball",        "a round fireball with a flame tail"),
 ("poison_mist",     "a cloud with bubbles, toxic gas"),
 ("ice_spear",       "a diagonal icicle spear, ice crystal"),
 ("meditation",      "a lotus flower with a star"),
 ("foresight",       "an open eye, eyeball with pupil"),
]
THROWABLES = [
 ("firebomb",   "a round black bomb with a lit fuse and flames"),
 ("poison_pot", "a clay pot with green poison dripping, skull mark"),
 ("ice_flask",  "a round glass flask of ice with a snowflake"),
 ("smoke_bomb", "a round bomb with a puff of smoke cloud"),
]
PASSIVES = [
 ("attack",   "a sword with a plus sign, power up"),
 ("defense",  "a round shield with a plus sign"),
 ("vitality", "a heart"),
 ("magic",    "a magic star sparkle with a plus sign"),
 ("speed",    "a winged boot, swift"),
 ("critical", "a four leaf clover, luck"),
 ("greed",    "a coin purse bag with a coin"),
 ("recovery", "a leaf with a drop, regeneration"),
]
ACCESSORIES = [
 ("ring",  "a gold ring with a gem"),
 ("charm", "a round amulet charm pendant on a string"),
]
MISC = [
 ("gold_coin", "a round gold coin with a star mark"),
]
CATS = {
 "status": ("badge", STATUSES), "skill": ("item", SKILLS), "throwable": ("item", THROWABLES),
 "passive": ("item", PASSIVES), "accessory": ("item", ACCESSORIES), "misc": ("item", MISC),
}
def seed_for(cat, iid):
    return 100000 + sum((i+1)*ord(c) for i, c in enumerate(cat+":"+iid)) * 7919 % 900000
