package prepare_db

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

write_string_arrays_to_file :: proc(
	file_out_path: string,
	arrays: [][]string,
	array_name: string,
) {
	if os.exists(file_out_path) {
		os.remove(file_out_path)
	}
	file_out_handle, err := os.open(file_out_path, os.O_CREATE | os.O_WRONLY, 444)
	if err == os.ERROR_NONE {
		fmt.print("Writing file", file_out_path)
	} else {
		fmt.eprintln("ERROR: Could not create file", file_out_path, ":", err)
		os.exit(1)
	}

	tic := time.tick_now()
	os.write_string(file_out_handle, "// This is generated code!\n")
	os.write_string(file_out_handle, "package main\n")
	os.write_string(
		file_out_handle,
		fmt.aprintfln("%v: [%v][]string = {{", array_name, len(arrays)),
	)
	for array in arrays {
		os.write_string(file_out_handle, fmt.aprint("\t{"))
		for elem, idx in array {
			os.write_string(file_out_handle, fmt.aprintf("%q", elem))
			if idx != len(array) - 1 {
				os.write_string(file_out_handle, fmt.aprint(", "))
			}
		}
		os.write_string(file_out_handle, fmt.aprint("},\n"))
	}
	os.write_string(file_out_handle, "}\n")
	toc := time.tick_since(tic)

	os.close(file_out_handle)
	fmt.printfln(" (%v)", toc)
}

write_string_array_to_file :: proc(file_out_path: string, array: []string, array_name: string) {
	if os.exists(file_out_path) {
		os.remove(file_out_path)
	}
	file_out_handle, err := os.open(file_out_path, os.O_CREATE | os.O_WRONLY, 444)
	if err == os.ERROR_NONE {
		fmt.print("Writing file", file_out_path)
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
	fmt.printfln(" (%v)", toc)
}

extract_normalized_term :: proc(str: string, normalizer: map[rune]string) -> string {
	lower := strings.to_lower(str)
	split := strings.split(lower, "{") // split off gender
	split = strings.split(split[0], "[") // split off comments
	split = strings.split(split[0], "<") // split off abbreviations
	normalized := normalize_runes(split[0], normalizer)
	return normalized
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

	tic := time.tick_now()
	file_read, file_read_ok := os.read_entire_file(path_dict_txt, context.allocator)
	defer delete(file_read, context.allocator)
	if !file_read_ok {
		fmt.eprintfln("ERROR: Could not open file %v.", path_dict_txt)
	}

	lang1_raw: [dynamic]string
	lang2_raw: [dynamic]string
	category: [dynamic]string
	//area: [dynamic]string

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
			append(&lang1_raw, strings.clone(strings.trim_space(split[0])))
			append(&lang2_raw, strings.clone(strings.trim_space(split[1])))
		} else {
			fmt.println("------------ exception length --------------")
			fmt.println(str)
		}
		if len(split) == 2 {
			append(&category, strings.clone(""))
			// append(&area, strings.clone(""))
		}
		if len(split) == 3 {
			append(&category, strings.clone(strings.trim_space(split[2])))
			// append(&area, strings.clone(""))
		}
		if len(split) == 4 {
			append(&category, strings.clone(strings.trim_space(split[2])))
			// append(&area, strings.clone(strings.trim_space(split[3])))
		}
		if len(split) > 4 {
			fmt.eprintfln("ERROR: Exception length: %v:", len(split))
			fmt.eprintln(str)
			os.exit(1)
		}
	}
	assert(len(lang1_raw) == len(lang2_raw))
	assert(len(lang1_raw) == len(category))
	toc := time.tick_since(tic)
	fmt.printfln("Array lengths after reading file: %v (%v)", len(lang1_raw), toc)

	/*
	normalize
	- only lower case runes
	- replace (basically non-latin) runes
	- split off comments
	*/
	tic = time.tick_now()
	normalizer := get_normalizer()
	lang1_normalized: [dynamic][]string
	for _, j in lang1_raw {
		normalized := extract_normalized_term(lang1_raw[j], normalizer)
		fields := split_fields(normalized)
		append(&lang1_normalized, fields)
	}
	assert(len(lang1_raw) == len(lang2_raw))
	assert(len(lang1_raw) == len(lang1_normalized))
	assert(len(lang1_raw) == len(category))
	// assert(len(lang1_raw) == len(area))
	toc = time.tick_since(tic)
	fmt.printfln("Array lengths after normalization: %v (%v)", len(lang1_raw), toc)

	/*
	handle duplicates
	- use auxiliary maps to find duplicates
	- afterwards, convert the maps to two arrays so that we can index from one into the other (maps don't guarantee an order)
	*/
	tic = time.tick_now()
	// value: lang1's terms with duplicates removed
	lang1_aux_map := make(map[string][]string)
	// value: all translations of lang1's terms
	// if there was no duplicate in lang 1, value is a len=1 list
	// if there were duplicates in lang 1, value contains an element for every corresponding translation
	trans1_aux_map := make(map[string][dynamic]string)
	for array, idx in lang1_normalized {
		key := strings.join(array, "+")
		if !(key in lang1_aux_map) {
			lang1_aux_map[key] = array
			trans1_aux_map[key] = make([dynamic]string)
		}
		append(&trans1_aux_map[key], lang2_raw[idx])
	}
	assert(len(lang1_aux_map) == len(trans1_aux_map))
	toc = time.tick_since(tic)
	fmt.printfln("Array lengths after handling duplicates: %v (%v)", len(lang1_aux_map), toc)

	tic = time.tick_now()
	lang1_dedup_1_word: [dynamic]string
	lang1_dedup_2_words: [dynamic][]string
	lang1_dedup_3_words: [dynamic][]string
	lang1_dedup_4_words: [dynamic][]string
	lang1_dedup_mult_words: [dynamic][]string
	trans1_dedups_1_word: [dynamic][]string
	trans1_dedups_2_words: [dynamic][]string
	trans1_dedups_3_words: [dynamic][]string
	trans1_dedups_4_words: [dynamic][]string
	trans1_dedups_mult_words: [dynamic][]string
	for key, val in lang1_aux_map {
		if len(val) == 0 {
			continue
		}
		// skip single letter words
		if len(val[0]) == 1 {
			continue
		}
		if len(val) == 1 {
			append(&lang1_dedup_1_word, val[0])
			append(&trans1_dedups_1_word, trans1_aux_map[key][:])
		} else if len(val) == 2 {
			append(&lang1_dedup_2_words, val)
			append(&trans1_dedups_2_words, trans1_aux_map[key][:])
		} else if len(val) == 3 {
			append(&lang1_dedup_3_words, val)
			append(&trans1_dedups_3_words, trans1_aux_map[key][:])
		} else if len(val) == 4 {
			append(&lang1_dedup_4_words, val)
			append(&trans1_dedups_4_words, trans1_aux_map[key][:])
		} else {
			append(&lang1_dedup_mult_words, val)
			append(&trans1_dedups_mult_words, trans1_aux_map[key][:])
		}
	}
	assert(len(lang1_dedup_1_word) == len(trans1_dedups_1_word))
	assert(len(lang1_dedup_2_words) == len(trans1_dedups_2_words))
	assert(len(lang1_dedup_3_words) == len(trans1_dedups_3_words))
	assert(len(lang1_dedup_4_words) == len(trans1_dedups_4_words))
	assert(len(lang1_dedup_mult_words) == len(trans1_dedups_mult_words))
	toc = time.tick_since(tic)
	fmt.printfln(
		"Array lengths after handling empty or single-letter words: %v (%v)",
		len(lang1_dedup_1_word) +
		len(lang1_dedup_2_words) +
		len(lang1_dedup_3_words) +
		len(lang1_dedup_4_words) +
		len(lang1_dedup_mult_words),
		toc,
	)
	fmt.println("\t1 word     :", len(lang1_dedup_1_word))
	fmt.println("\t2 words    :", len(lang1_dedup_2_words))
	fmt.println("\t3 words    :", len(lang1_dedup_3_words))
	fmt.println("\t4 words    :", len(lang1_dedup_4_words))
	fmt.println("\tmult words :", len(lang1_dedup_mult_words))

	// arrays: [][]string = {lang1_raw[:], trans1_raw[:], category[:]}
	// array_names: []string = {"lang1_raw", "trans1_raw", "category"}
	// files_out: []string = {
	// 	"../generated_lang1.odin",
	// 	"../generated_trans1.odin",
	// 	"../generated_category.odin",
	// 	//"../generated_area.odin",
	// }
	// for array, k in arrays {
	// 	write_string_array_to_file(files_out[k], array, array_names[k])
	// }

	write_string_array_to_file(
		"../generated_lang1_dedup_1_word.odin",
		lang1_dedup_1_word[:],
		"lang1_dedup_1_word",
	)
	write_string_arrays_to_file(
		"../generated_lang1_dedup_2_words.odin",
		lang1_dedup_2_words[:],
		"lang1_dedup_2_words",
	)
	write_string_arrays_to_file(
		"../generated_lang1_dedup_3_words.odin",
		lang1_dedup_3_words[:],
		"lang1_dedup_3_words",
	)
	write_string_arrays_to_file(
		"../generated_lang1_dedup_4_words.odin",
		lang1_dedup_4_words[:],
		"lang1_dedup_4_words",
	)
	write_string_arrays_to_file(
		"../generated_lang1_dedup_mult_words.odin",
		lang1_dedup_mult_words[:],
		"lang1_dedup_mult_words",
	)
	write_string_arrays_to_file(
		"../generated_trans1_dedups_1_word.odin",
		trans1_dedups_1_word[:],
		"trans1_dedups_1_word",
	)
	write_string_arrays_to_file(
		"../generated_trans1_dedups_2_words.odin",
		trans1_dedups_2_words[:],
		"trans1_dedups_2_words",
	)
	write_string_arrays_to_file(
		"../generated_trans1_dedups_3_words.odin",
		trans1_dedups_3_words[:],
		"trans1_dedups_3_words",
	)
	write_string_arrays_to_file(
		"../generated_trans1_dedups_4_words.odin",
		trans1_dedups_4_words[:],
		"trans1_dedups_4_words",
	)
	write_string_arrays_to_file(
		"../generated_trans1_dedups_mult_words.odin",
		trans1_dedups_mult_words[:],
		"trans1_dedups_mult_words",
	)
}
