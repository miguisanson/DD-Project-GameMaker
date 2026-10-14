# Character sprite style (read from sprites/nobody_down, knight_down, archer_down, mage_down, stranger_moving, stranger_profile)

- Canvas: 16x16 for every `*_down` / `stranger_moving` frame; `stranger_profile` is 32x32 (boss-size, not used for NPCs).
- Frames: 2 per walk strip (`nobody_down`, `knight_down`, ... `stranger_moving`), playback 8 fps (playbackSpeedType 0), origin (0,0) top-left, collisionKind 1 (rectangle), bboxMode 0 (automatic).
- Palette in the files: #071821, #86C06C, #E0F8CF plus transparent; the player-class sprites also use pure black #000000 as outline. #306850 is allowed by D10 but the characters barely use it.
- Proportions: big head, tiny body. Nobody/Knight/Archer: head ~12 wide x 10 tall on a ~5-row body, 1 px legs. Whole figure fills the full 16 px height, 12-16 px wide.
- Outline: 1 px. Nobody, Knight, Archer use black (#000000). Mage and Stranger have NO separate outline: the dark #071821 shape is the outline (cloak = outline).
- Shading: flat fills, no dithering. Pale #E0F8CF face/skin, #86C06C for one-pixel highlights or hood rim, #071821 for cloth and shadow. Light comes from the top-left.
- Faces: tiny. Nobody has two 2x1 dark eye dashes; Mage a hat-brim shadow and two dark eyes on a pale face; Stranger a pale mask with a dark vertical mouth slit and two dark dots. Eyes are dark on pale, 1-2 px.
- Animation: only 2 frames. The second frame shifts the head down 1 px (Stranger) or swaps the feet (Nobody/Knight/Archer). No in-betweens.
- Floors in the game are mostly pale #E0F8CF with dark #071821 walls: dark figures read best, `m`/`g` details are visible only against the floor.

Merchant decisions (D110): dark #071821 hooded cloak (Stranger-style: the cloak is the outline), face void with two glowing pale eyes (the reverse of the other faces: pale on dark), a wide pack drawn in #306850/#86C06C with pale strap buckles, 16x16, 2 idle frames made like the Stranger's (head and pack dip 1 px, hem fixed). The game multiplies it by (240,200,90): #E0F8CF becomes gold, #071821 stays near black, so the gold lives in the eyes and buckles.
