function StatClamp(_v) { return clamp(_v, STAT_MIN, STAT_MAX); }

// Spec section 4: round half up with a tiny epsilon so values like 3.4999999999 from float error round the way the spec says.
function RoundHalfUp(_x) { return floor(_x + 0.5 + ROUND_HALF_UP_EPS); }

// ---------------------------------------------------------------------------------------------------------
// Seeded RNG streams (D33, research/roguelike-cases.md section 4). Pure functions: no globals, no bit operations.
// A stream is { state, calls }. state is a whole number 1..RNG_MOD-1, so a save stores two integers per stream.
// Generator: Park-Miller "minstd" (state = state * 48271 mod 2147483647). The product stays below 2^53, so it is exact.
// A stream is started from the run seed and a label: state = first 8 hex digits of md5("<seed>:<label>") mod (RNG_MOD - 1) + 1.
// Gameplay randomness that belongs to a run uses these (through RunRng_* in scr_room_state); random() stays for cosmetics.
// ---------------------------------------------------------------------------------------------------------
#macro RNG_MOD 2147483647
#macro RNG_MUL 48271

function Rng_HexVal(_ch) {
    var _o = ord(_ch);
    if (_o >= 48 && _o <= 57) return _o - 48;
    if (_o >= 97 && _o <= 102) return _o - 87;
    if (_o >= 65 && _o <= 70) return _o - 55;
    return 0;
}

function Rng_Derive(_seed, _label) {
    var _h = md5_string_utf8(string(floor(_seed)) + ":" + string(_label));
    var _v = 0;
    for (var _i = 1; _i <= 8; _i++) _v = _v * 16 + Rng_HexVal(string_char_at(_h, _i));
    return (_v mod (RNG_MOD - 1)) + 1;
}

function Rng_NewRaw(_state) {
    var _s = is_real(_state) ? floor(_state) : 1;
    if (_s < 1 || _s > RNG_MOD - 1) _s = 1;
    return { state: _s, calls: 0 };
}

function Rng_New(_seed, _label) {
    return { state: Rng_Derive(_seed, _label), calls: 0 };
}

function Rng_Next(_r) {
    _r.state = (_r.state * RNG_MUL) mod RNG_MOD;
    _r.calls += 1;
    return _r.state;
}

// 0 <= value < 1
function Rng_Float(_r) {
    return (Rng_Next(_r) - 1) / (RNG_MOD - 1);
}

// whole number 0 .. _n-1 (0 when _n < 1; nothing is drawn then)
function Rng_Int(_r, _n) {
    if (_n < 1) return 0;
    return min(_n - 1, floor(Rng_Float(_r) * _n));
}

// whole number _lo .. _hi, both included
function Rng_Range(_r, _lo, _hi) {
    var _a = min(_lo, _hi);
    var _b = max(_lo, _hi);
    return _a + Rng_Int(_r, _b - _a + 1);
}

// true with probability _p (one value is always drawn, so the sequence does not depend on _p)
function Rng_Chance(_r, _p) {
    return Rng_Float(_r) < _p;
}

function Rng_Pick(_r, _arr) {
    var _n = array_length(_arr);
    if (_n <= 0) return undefined;
    return _arr[Rng_Int(_r, _n)];
}

// a shuffled copy (Fisher-Yates); the input is not changed
function Rng_Shuffle(_r, _arr) {
    var _out = [];
    for (var _i = 0; _i < array_length(_arr); _i++) array_push(_out, _arr[_i]);
    for (var _k = array_length(_out) - 1; _k >= 1; _k--) {
        var _j = Rng_Int(_r, _k + 1);
        var _t = _out[_k];
        _out[_k] = _out[_j];
        _out[_j] = _t;
    }
    return _out;
}

function Rng_Save(_r) {
    return { state: _r.state, calls: _r.calls };
}

function Rng_Load(_d) {
    var _r = Rng_NewRaw((is_struct(_d) && variable_struct_exists(_d, "state") && is_real(_d.state)) ? _d.state : 1);
    if (is_struct(_d) && variable_struct_exists(_d, "calls") && is_real(_d.calls)) _r.calls = max(0, floor(_d.calls));
    return _r;
}
