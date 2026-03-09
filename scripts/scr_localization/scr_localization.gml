function Loc_DefaultData() {
    return {
        loaded: false,
        file_path: "",
        default_lang: "en",
        lang: "en",
        languages: ["en", "ko"],
        strings: {},
        revision: 0
    };
}

function Loc_GetData() {
    if (!variable_global_exists("loc") || !is_struct(global.loc)) {
        global.loc = Loc_DefaultData();
    }
    return global.loc;
}

function Loc_LoadFromPath(_path) {
    if (!file_exists(_path)) return undefined;

    var buf = buffer_load(_path);
    if (buf == -1) return undefined;

    var json = buffer_read(buf, buffer_string);
    buffer_delete(buf);

    if (!is_string(json) || string_length(json) <= 0) return undefined;

    var payload = json_parse(json);
    if (!is_struct(payload)) return undefined;
    if (!variable_struct_exists(payload, "strings") || !is_struct(payload.strings)) return undefined;

    return payload;
}

function Loc_ApplyPayload(_payload, _path = "") {
    var loc = Loc_GetData();
    loc.loaded = false;

    if (!is_struct(_payload)) {
        global.loc = loc;
        return false;
    }

    loc.strings = _payload.strings;
    if (variable_struct_exists(_payload, "default_lang")) {
        loc.default_lang = string(_payload.default_lang);
    }
    if (loc.default_lang == "") loc.default_lang = "en";

    if (variable_struct_exists(_payload, "languages") && is_array(_payload.languages) && array_length(_payload.languages) > 0) {
        loc.languages = _payload.languages;
    } else {
        loc.languages = [loc.default_lang, "ko"];
    }

    loc.loaded = true;
    loc.file_path = string(_path);

    if (loc.lang == "") loc.lang = loc.default_lang;
    loc.lang = Loc_NormalizeLanguage(loc.lang, loc.default_lang);
    global.loc = loc;
    return true;
}

function Loc_Init() {
    var loc = Loc_GetData();
    if (loc.loaded) return true;

    var candidates = [
        "localization/localization.json",
        "datafiles/localization/localization.json",
        "localization.json"
    ];

    for (var i = 0; i < array_length(candidates); i++) {
        var path = candidates[i];
        var payload = Loc_LoadFromPath(path);
        if (is_struct(payload)) {
            return Loc_ApplyPayload(payload, path);
        }
    }

    loc.loaded = false;
    loc.file_path = "";
    loc.strings = {};
    loc.default_lang = "en";
    if (!is_array(loc.languages) || array_length(loc.languages) <= 0) {
        loc.languages = ["en", "ko"];
    }
    if (loc.lang == "") loc.lang = "en";
    global.loc = loc;
    return false;
}

function Loc_NormalizeLanguage(_lang_code, _fallback = "en") {
    var code = string(_lang_code);
    if (code == "") code = string(_fallback);

    var loc = Loc_GetData();
    var langs = loc.languages;
    if (!is_array(langs) || array_length(langs) <= 0) {
        return string(_fallback);
    }

    for (var i = 0; i < array_length(langs); i++) {
        if (string(langs[i]) == code) return code;
    }

    for (var j = 0; j < array_length(langs); j++) {
        if (string(langs[j]) == string(_fallback)) return string(_fallback);
    }

    return string(langs[0]);
}

function Loc_SetLanguage(_lang_code) {
    Loc_Init();
    var loc = Loc_GetData();
    var next_lang = Loc_NormalizeLanguage(_lang_code, loc.default_lang);

    if (loc.lang != next_lang) {
        loc.lang = next_lang;
        loc.revision += 1;
    }

    global.loc = loc;
    return loc.lang;
}

function Loc_GetLanguage() {
    Loc_Init();
    var loc = Loc_GetData();
    if (loc.lang == "") return loc.default_lang;
    return loc.lang;
}

function Loc_GetRevision() {
    var loc = Loc_GetData();
    return loc.revision;
}

function Loc_GetRaw(_key, _lang_code) {
    var loc = Loc_GetData();
    if (!is_struct(loc.strings)) return "";
    if (!variable_struct_exists(loc.strings, _key)) return "";

    var entry = variable_struct_get(loc.strings, _key);
    if (!is_struct(entry)) return "";
    if (!variable_struct_exists(entry, _lang_code)) return "";

    return string(variable_struct_get(entry, _lang_code));
}

function Loc_Has(_key, _lang_code = "") {
    Loc_Init();
    var lang = string(_lang_code);
    if (lang == "") lang = Loc_GetLanguage();
    var text = Loc_GetRaw(_key, lang);
    return (text != "");
}

function Loc_FormatTemplate(_text, _vars) {
    var out = string(_text);
    if (!is_struct(_vars)) return out;

    var keys = variable_struct_get_names(_vars);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var token = "{" + key + "}";
        var value = string(variable_struct_get(_vars, key));
        out = string_replace_all(out, token, value);
    }

    return out;
}

function Loc_T(_key, _fallback = "", _vars = undefined) {
    Loc_Init();

    var loc = Loc_GetData();
    var lang = Loc_GetLanguage();
    var text = Loc_GetRaw(_key, lang);

    if (text == "" && lang != loc.default_lang) {
        text = Loc_GetRaw(_key, loc.default_lang);
    }

    if (text == "") {
        text = string(_fallback);
    }

    if (text == "") {
        if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
            text = string(_key);
        }
    }

    return Loc_FormatTemplate(text, _vars);
}

function Loc_Reload() {
    global.loc = Loc_DefaultData();
    Loc_Init();
    return Loc_GetData();
}

function Loc_LanguageDisplayName(_lang_code = "") {
    var code = string(_lang_code);
    if (code == "") code = Loc_GetLanguage();

    switch (code) {
        case "ko":
            return Loc_T("settings.lang.korean", "Korean");
        default:
            return Loc_T("settings.lang.english", "English");
    }
}
