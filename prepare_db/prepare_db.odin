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
		fmt.println("Created file", file_out_path)
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
	fmt.printfln("Wrote file %v in %v", file_out_path, toc)
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

	file_read, file_read_ok := os.read_entire_file(path_dict_txt, context.allocator)
	defer delete(file_read, context.allocator)
	if !file_read_ok {
		fmt.eprintfln("ERROR: Could not open file %v.", path_dict_txt)
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

	normalizer := get_normalizer()
	for _, j in lang1 {
		normalized := extract_normalized_term(lang1[j], normalizer)
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

	// m := make(map[rune]bool)
	// defer delete(m)
	// for words in lang1_words {
	// 	for word in words {
	// 		for r in word {
	// 			m[r] = true
	// 		}
	// 	}
	// }
	// fmt.println("\nRunes:", len(m))
	// counter := 0
	// for key in m {
	// 	//fmt.printf("'%v'  ", key)
	// 	if !(key in normalizer) {
	// 		fmt.printf("'%v'  ", key)
	// 		counter += 1
	// 	}
	// 	if counter == 10 {
	// 		counter = 0
	// 		fmt.println()
	// 	}
	// }
	// fmt.println()

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

	arrays: [][]string = {lang1[:], lang2[:], lang2_lower[:], category[:], area[:]}
	array_names: []string = {"lang1", "lang2", "lang2_lower", "category", "area"}
	files_out: []string = {
		"../generated_lang1.odin",
		"../generated_lang2.odin",
		"../generated_lang2_lower.odin",
		"../generated_category.odin",
		"../generated_area.odin",
	}
	for array, k in arrays {
		write_string_array_to_file(files_out[k], array, array_names[k])
	}
	write_string_arrays_to_file("../generated_lang1_lower.odin", lang1_words[:], "lang1_words")
}
