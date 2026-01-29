function RollD20() { return irandom_range(1, 20); }
function StatClamp(_v) { return clamp(_v, 1, 60); }
function StatMod(_stat) { return floor((_stat - 10) / 2); }