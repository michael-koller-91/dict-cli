package prepare_db

import "base:runtime"
import "core:encoding/entity"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

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
			fmt.eprintfln("ERROR: Unexpected rune %q (%v) in %q", r, r, decoded_str)
			//os.exit(1)
		}
	}
	return strings.to_string(b)
}

write_string_array_to_file :: proc(file_out_path: string, array: []string, array_name: string) {
	if os.exists(file_out_path) {
		os.remove(file_out_path)
	}
	file_out_handle, err := os.open(file_out_path, os.O_CREATE | os.O_WRONLY, 444)
	if err == os.ERROR_NONE {
		fmt.println("Created file", file_out_path)
	} else {
		fmt.eprintln("ERROR: Could not create file", file_out_path, ":", err)
		os.exit(1)
	}

	tic := time.tick_now()
	os.write_string(file_out_handle, "// This is generated code!\n")
	os.write_string(file_out_handle, "package main\n")
	os.write_string(file_out_handle, fmt.aprintfln("%v: [%v]string = {{", array_name, len(array)))
	for elem in array {
		os.write_string(file_out_handle, fmt.aprintfln("\t%q,", elem))
	}
	os.write_string(file_out_handle, "}\n")
	toc := time.tick_since(tic)

	os.close(file_out_handle)
	fmt.printfln("Wrote file %v in %v", file_out_path, toc)
}

trim :: proc(str: string) -> string {
	lstr := strings.to_lower(str, context.temp_allocator)
	lstr = strings.trim_space(lstr)
	lstr = strings.trim(lstr, ",")
	lstr = strings.trim(lstr, "!")
	lstr = strings.trim(lstr, "...")
	return lstr
}

split_fields :: proc(str: string) -> []string {
	fields := strings.fields(str, context.temp_allocator) // split by white space
	r: [dynamic]string
	for field, j in fields {
		lstr := trim(field)
		if len(lstr) > 0 {append(&r, lstr)}
	}
	return r[:]
}

main :: proc() {
	nstr := -1
	if len(os.args) == 2 {
		nstr, _ = strconv.parse_int(os.args[1])
	}

	path_dict_txt := "dict-de-en.txt"

	file_read, file_read_ok := os.read_entire_file(path_dict_txt, context.allocator)
	defer delete(file_read, context.allocator)
	if !file_read_ok {
		fmt.eprintfln("ERROR: Could not open file %v. %v", path_dict_txt, file_read_ok)
	}

	lang1: [dynamic]string
	lang2: [dynamic]string
	category: [dynamic]string
	area: [dynamic]string
	lang1_words: [dynamic][]string
	lang2_lower: [dynamic]string

	it := string(file_read)
	k := 0
	for str in strings.split_lines_after_iterator(&it) {
		if str[0] == '#' {
			continue
		}

		if (nstr != -1) & (k > nstr) {
			break
		}
		k += 1

		split := strings.split(str, "\t", context.temp_allocator)
		if len(split) < 2 {continue}
		if (len(split) == 2) | (len(split) == 3) | (len(split) == 4) {
			append(&lang1, strings.clone(strings.trim_space(split[0])))
			append(&lang2, strings.clone(strings.trim_space(split[1])))
		} else {
			fmt.println("------------ exception length --------------")
			fmt.println(str)
		}
		if len(split) == 2 {
			append(&category, strings.clone(""))
			append(&area, strings.clone(""))
		}
		if len(split) == 3 {
			append(&category, strings.clone(strings.trim_space(split[2])))
			append(&area, strings.clone(""))
		}
		if len(split) == 4 {
			append(&category, strings.clone(strings.trim_space(split[2])))
			append(&area, strings.clone(strings.trim_space(split[3])))
		}
		if len(split) > 4 {
			fmt.eprintfln("ERROR: Exception length: %v:", len(split))
			fmt.eprintln(str)
			os.exit(1)
		}
	}

	normalizer := make(map[rune]string)

	// '0' - '9'
	for i in 48 ..= 57 {
		key := rune(i)
		normalizer[key] = utf8.runes_to_string([]rune{key})
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
	normalizer['-'] = "-"
	// replacements
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
	normalizer['_'] = ""
	normalizer['='] = " "
	normalizer['‎'] = " "
	normalizer['¡'] = " "
	normalizer['™'] = " "
	normalizer['′'] = " "
	normalizer['°'] = " "
	normalizer['\''] = " "
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

	for _, j in lang1 {
		lower := strings.to_lower(lang1[j])
		split := strings.split(lower, "{") // split off gender
		split = strings.split(split[0], "[") // split off comments
		split = strings.split(split[0], "<") // split off abbreviations
		normalized := normalize_runes(split[0], normalizer)
		fields := split_fields(normalized)
		append(&lang1_words, fields)
		append(&lang2_lower, strings.to_lower(lang2[j]))
	}
	assert(len(lang1) == len(lang2))
	assert(len(lang1) == len(lang1_words))
	assert(len(lang1) == len(lang2_lower))
	assert(len(lang1) == len(category))
	assert(len(lang1) == len(area))
	fmt.println("Array lengths:", len(lang1))
	//for elem in lang1_words {
	//	fmt.println(elem)
	//}

	m := make(map[rune]bool)
	defer delete(m)
	for words in lang1_words {
		for word in words {
			for r in word {
				m[r] = true
			}
		}
	}
	fmt.println("\nRunes:", len(m))
	counter := 0
	for key in m {
		//fmt.printf("'%v'  ", key)
		if !(key in normalizer) {
			fmt.printf("'%v'  ", key)
			counter += 1
		}
		if counter == 10 {
			counter = 0
			fmt.println()
		}
	}
	fmt.println()

	// m1 := make(map[string]bool)
	// defer delete(m1)
	// for elem in lang1_words {
	// 	m1[elem] = true
	// }
	// fmt.println("Without duplicates:", len(m1))

	// m2 := make(map[string]bool)
	// defer delete(m2)
	// for elem in lang2_lower {
	// 	m2[elem] = true
	// }
	// fmt.println("Without duplicates:", len(m2))

	// arrays: [][]string = {lang1[:], lang2[:], lang1_words[:], lang2_lower[:], category[:], area[:]}
	// array_names: []string = {"lang1", "lang2", "lang1_words", "lang2_lower", "category", "area"}
	// files_out: []string = {
	// 	"../generated_lang1.odin",
	// 	"../generated_lang2.odin",
	// 	"../generated_lang1_lower.odin",
	// 	"../generated_lang2_lower.odin",
	// 	"../generated_category.odin",
	// 	"../generated_area.odin",
	// }
	// for array, k in arrays {
	// 	write_string_array_to_file(files_out[k], array, array_names[k])
	// }
}
