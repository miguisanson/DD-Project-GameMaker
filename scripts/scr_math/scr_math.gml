function StatClamp(_v) { return clamp(_v, STAT_MIN, STAT_MAX); }

// Spec section 4: round half up with a tiny epsilon so values like 3.4999999999 from float error round the way the spec says.
function RoundHalfUp(_x) { return floor(_x + 0.5 + ROUND_HALF_UP_EPS); }
