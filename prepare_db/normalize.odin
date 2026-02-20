package prepare_db

import "core:encoding/entity"
import "core:fmt"
import "core:io"
import "core:strings"
import "core:unicode/utf8"

get_normalizer :: proc() -> map[rune]string {
	normalizer := make(map[rune]string)

	// '0' - '9'
	for i in 48 ..= 57 {
		key := rune(i)
		normalizer[key] = ""
	}
	// 'a' - 'z'
	for i in 97 ..= 122 {
		key := rune(i)
		normalizer[key] = utf8.runes_to_string([]rune{key})
	}
	// extra German letters
	normalizer['ä'] = "ä"
	normalizer['ö'] = "ö"
	normalizer['ü'] = "ü"
	normalizer['ß'] = "ß"
	// special runes
	normalizer[' '] = " "
	normalizer['{'] = "{"
	normalizer['}'] = "}"
	normalizer['['] = "["
	normalizer[']'] = "]"
	// replacements
	normalizer['-'] = " "
	normalizer['('] = " "
	normalizer[')'] = " "
	normalizer['.'] = " "
	normalizer[','] = " "
	normalizer[':'] = " "
	normalizer['!'] = " "
	normalizer['?'] = " "
	normalizer['£'] = " "
	normalizer['+'] = " "
	normalizer['&'] = " "
	normalizer['/'] = " "
	normalizer['®'] = " "
	normalizer['%'] = " "
	normalizer['€'] = " "
	normalizer['$'] = " "
	normalizer['§'] = " "
	normalizer['>'] = " "
	normalizer['*'] = " "
	normalizer['–'] = " "
	normalizer['—'] = " "
	normalizer['−'] = " "
	normalizer['_'] = "" // not a space on purpose
	normalizer['='] = " "
	normalizer['‎'] = " "
	normalizer['¡'] = " "
	normalizer['™'] = " "
	normalizer['′'] = " "
	normalizer['°'] = " "
	normalizer['\''] = ""
	normalizer['⅓'] = " "
	normalizer['½'] = " "
	normalizer['²'] = " "
	normalizer['„'] = " "
	normalizer['“'] = " "
	normalizer['»'] = " "
	normalizer['«'] = " "
	normalizer['ʻ'] = " "
	normalizer['ʿ'] = " "
	normalizer['’'] = " "
	normalizer['|'] = " "
	normalizer[';'] = " "
	normalizer['”'] = " "
	normalizer['æ'] = "ae"
	normalizer['œ'] = "oe"
	normalizer['@'] = "a"
	normalizer['å'] = "a"
	normalizer['ă'] = "a"
	normalizer['â'] = "a"
	normalizer['ā'] = "a"
	normalizer['ã'] = "a"
	normalizer['á'] = "a"
	normalizer['à'] = "a"
	normalizer['č'] = "c"
	normalizer['ć'] = "c"
	normalizer['ç'] = "c"
	normalizer['ễ'] = "e"
	normalizer['ê'] = "e"
	normalizer['ě'] = "e"
	normalizer['ë'] = "e"
	normalizer['ĕ'] = "e"
	normalizer['é'] = "e"
	normalizer['è'] = "e"
	normalizer['í'] = "i"
	normalizer['ï'] = "i"
	normalizer['î'] = "i"
	normalizer['ī'] = "i"
	normalizer['ı'] = "i"
	normalizer['ḷ'] = "l"
	normalizer['ł'] = "l"
	normalizer['µ'] = "m"
	normalizer['ń'] = "n"
	normalizer['ň'] = "n"
	normalizer['ñ'] = "n"
	normalizer['ṇ'] = "n"
	normalizer['ø'] = "o"
	normalizer['ő'] = "ö"
	normalizer['ơ'] = "o"
	normalizer['ō'] = "o"
	normalizer['ô'] = "o"
	normalizer['ó'] = "o"
	normalizer['ò'] = "o"
	normalizer['ř'] = "r"
	normalizer['ṛ'] = "r"
	normalizer['ş'] = "s"
	normalizer['ś'] = "s"
	normalizer['š'] = "s"
	normalizer['ú'] = "u"
	normalizer['ū'] = "u"
	normalizer['û'] = "u"
	normalizer['ú'] = "u"
	normalizer['×'] = "x"
	normalizer['ý'] = "y"
	normalizer['ž'] = "z"
	normalizer['α'] = "a"
	normalizer['β'] = "b"
	normalizer['η'] = "e"
	normalizer['γ'] = "g"
	normalizer['λ'] = "l"
	normalizer['ψ'] = "p"
	normalizer['σ'] = "s"
	normalizer['φ'] = "v"
	normalizer['ω'] = "w"
	normalizer['ζ'] = "z"

	return normalizer
}

normalize_runes :: proc(str: string, normalizer: map[rune]string) -> string {
	b: strings.Builder
	strings.builder_init(&b, 0, strings.rune_count(str), context.temp_allocator)
	w := strings.to_writer(&b)

	// convert XLM-encoded `&#946;` to `rune(946)`
	decoded_str, err := entity.decode_xml(str, allocator = context.temp_allocator)
	if err != entity.Error.None {
		panic(
			fmt.aprint("decode_xml couldn't handle the string %q with error message %v", str, err),
		)
	}

	for r, idx in decoded_str {
		n, ok := normalizer[r]
		if ok {
			io.write_string(w, n)
		} else {
			fmt.eprintfln("ERROR: Unknown rune %q (%v) in %v", r, r, decoded_str)
			panic("ERROR: Extend the normalizer.")
		}
	}
	return strings.to_string(b)
}
