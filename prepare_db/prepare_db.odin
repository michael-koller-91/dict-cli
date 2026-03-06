package prepare_db

import "./../utils"
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

write_string_array_to_file :: proc(file_out_path: string, array: []string, array_name: string) {
	if os.exists(file_out_path) {
		os.remove(file_out_path)
	}
	file_out_handle, err := os.open(
		file_out_path,
		os.O_CREATE | os.O_WRONLY,
		os.Permissions_Read_All,
	)
	if err == os.ERROR_NONE {
		fmt.print("Writing file", file_out_path)
	} else {
		fmt.eprintln("ERROR: Could not create file", file_out_path, ":", err)
		os.exit(1)
	}

	tic := time.tick_now()
	os.write_string(file_out_handle, "// This is generated code!\n")
	os.write_string(file_out_handle, "package main\n")
	//os.write_string(file_out_handle, "@(rodata)\n")
	os.write_string(file_out_handle, fmt.aprintfln("%v: [%v]string = {{", array_name, len(array)))
	for elem in array {
		os.write_string(file_out_handle, fmt.aprintfln("\t%q,", elem))
	}
	os.write_string(file_out_handle, "}\n")
	toc := time.tick_since(tic)

	os.close(file_out_handle)
	fmt.printfln(" (%v)", toc)
}

write_string_arrays_to_file :: proc(
	file_out_path: string,
	arrays: [][]string,
	array_name: string,
) {
	if os.exists(file_out_path) {
		os.remove(file_out_path)
	}
	file_out_handle, err := os.open(
		file_out_path,
		os.O_CREATE | os.O_WRONLY,
		os.Permissions_Read_All,
	)
	if err == os.ERROR_NONE {
		fmt.print("Writing file", file_out_path)
	} else {
		fmt.eprintln("ERROR: Could not create file", file_out_path, ":", err)
		os.exit(1)
	}

	builder := strings.builder_make()

	tic := time.tick_now()
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package main\n")
	//strings.write_string(&builder, "@(rodata)\n")
	strings.write_string(&builder, fmt.aprintfln("%v: [%v][]string = {{", array_name, len(arrays)))
	for array in arrays {
		strings.write_string(&builder, fmt.aprint("\t{"))
		for elem, idx in array {
			strings.write_string(&builder, fmt.aprintf("%q", elem))
			if idx != len(array) - 1 {
				strings.write_string(&builder, fmt.aprint(", "))
			}
		}
		strings.write_string(&builder, fmt.aprint("},\n"))
	}
	strings.write_string(&builder, "}\n")
	os.write_string(file_out_handle, strings.to_string(builder))
	os.close(file_out_handle)

	toc := time.tick_since(tic)
	fmt.printfln(" (%v)", toc)
}

write_index_to_file :: proc(
	file_out_path: string,
	map_: map[string][dynamic]int,
	array_name: string,
) {
	if os.exists(file_out_path) {
		os.remove(file_out_path)
	}
	file_out_handle, err := os.open(
		file_out_path,
		os.O_CREATE | os.O_WRONLY,
		os.Permissions_Read_All,
	)
	if err == os.ERROR_NONE {
		fmt.print("Writing file", file_out_path)
	} else {
		fmt.eprintln("ERROR: Could not create file", file_out_path, ":", err)
		os.exit(1)
	}

	builder := strings.builder_make()

	tic := time.tick_now()
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package main\n")
	//strings.write_string(&builder, "@(rodata)\n")
	strings.write_string(&builder, fmt.aprintfln("%v: [%v][]int = {{", array_name, cap(map_)))
	capacity := uintptr(cap(map_))
	for key, val in map_ {
		keey := key
		hash := utils.hash(&keey)
		index := utils.map_hash_to_index(hash, capacity)
		strings.write_string(&builder, fmt.aprintf("\t%v = {{", index))
		for elem, idx in val {
			strings.write_string(&builder, fmt.aprintf("%v", elem))
			if idx != len(val) - 1 {
				strings.write_string(&builder, fmt.aprint(", "))
			}
		}
		strings.write_string(&builder, fmt.aprint("},\n"))
	}
	strings.write_string(&builder, "}\n")
	os.write_string(file_out_handle, strings.to_string(builder))
	os.close(file_out_handle)

	toc := time.tick_since(tic)
	fmt.printfln(" (%v)", toc)
}

extract_normalized_term :: proc(str: string, normalizer: map[rune]string) -> string {
	lower := strings.to_lower(str)
	no_brackets := remove_bracket_terms(lower)
	normalized := normalize_runes(no_brackets, normalizer)
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

find_pair_of_brackets :: proc(
	s: string,
	openbr: rune,
	closebr: rune,
) -> (
	found_match: bool,
	begin: int,
	end: int,
) {
	found_match = false
	begin = -1
	end = -1

	found_begin := false
	for r, off in s {
		if r == openbr {
			found_begin = true
			begin = off
		}
		if found_begin == true {
			if r == closebr {
				found_match = true
				end = off
				return
			}
		}
	}

	return
}

remove_pairs_of_brackets :: proc(
	s: string,
	openbr: rune,
	closebr: rune,
	allocator := context.allocator,
) -> string {
	output := s
	match, begin, end := find_pair_of_brackets(s, openbr, closebr)
	collisions_counter := 0
	for match {
		collisions_counter += 1
		output, _ = strings.remove(output, output[begin:end + 1], 1, allocator)
		match, begin, end = find_pair_of_brackets(output, openbr, closebr)
		if collisions_counter > 100 {
			fmt.println(s)
			panic("wtf")
		}
	}
	return output
}

/*
Remove terms in angle, curly, or square brackets.

*Allocates Using Provided Allocator*

Inputs:
- s: The input string
- allocator: (default: context.allocator)

Returns:
- output: The modified string
*/
remove_bracket_terms :: proc(s: string, allocator := context.allocator) -> string {
	output := remove_pairs_of_brackets(s, '<', '>', allocator)
	output = remove_pairs_of_brackets(output, '{', '}', allocator)
	output = remove_pairs_of_brackets(output, '[', ']', allocator)
	return output
}

quick_test_remove_bracket_terms :: proc() {
	ex1 := "((für) etw. [Akk.]) pauken [ugs.] [intensiv lernen]"
	ex1_noc := remove_bracket_terms(ex1)
	fmt.println(ex1)
	fmt.println(ex1_noc)

	ex2 := "(älles) Heer {n} {m} des Himmels [Luther]"
	ex2_noc := remove_bracket_terms(ex2)
	fmt.println(ex2)
	fmt.println(ex2_noc)

	ex3 := "asdf <abbrev.> test"
	ex3_noc := remove_bracket_terms(ex3)
	fmt.println(ex3)
	fmt.println(ex3_noc)

	ex4 := "asdf bbrev.> test"
	ex4_noc := remove_bracket_terms(ex4)
	fmt.println(ex4)
	fmt.println(ex4_noc)

	ex5 := "asdf <bbrev test"
	ex5_noc := remove_bracket_terms(ex5)
	fmt.println(ex5)
	fmt.println(ex5_noc)
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
	if file_read_ok != os.ERROR_NONE {
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
	lang1_raw_aux_map := make(map[string][dynamic]string)
	// value: all translations of lang1's terms
	// if there was no duplicate in lang 1, value is a len=1 list
	// if there were duplicates in lang 1, value contains an element for every corresponding translation
	trans1_aux_map := make(map[string][dynamic]string)
	for array, idx in lang1_normalized {
		key := strings.join(array, "+")
		if !(key in lang1_aux_map) {
			lang1_aux_map[key] = array
			lang1_raw_aux_map[key] = make([dynamic]string)
			trans1_aux_map[key] = make([dynamic]string)
		}
		append(&lang1_raw_aux_map[key], lang1_raw[idx])
		append(&trans1_aux_map[key], lang2_raw[idx])
	}
	assert(len(lang1_aux_map) == len(trans1_aux_map))

	lang1_dedup: [dynamic][]string
	lang1_raw_dedup: [dynamic][]string
	trans1_dedup: [dynamic][]string
	for key, val in lang1_aux_map {
		if len(val) == 0 {
			continue
		}
		// skip single letter words
		if len(val[0]) == 1 {
			continue
		}
		append(&lang1_dedup, val)
		append(&lang1_raw_dedup, lang1_raw_aux_map[key][:])
		append(&trans1_dedup, trans1_aux_map[key][:])
	}
	assert(len(lang1_dedup) == len(lang1_raw_dedup))
	assert(len(lang1_dedup) == len(trans1_dedup))

	toc = time.tick_since(tic)
	fmt.printfln("Array lengths after handling duplicates: %v (%v)", len(lang1_aux_map), toc)
	fmt.printfln("\tDedup array lengths: %v", len(lang1_dedup))

	write_string_arrays_to_file("../generated_lang1_dedup.odin", lang1_dedup[:], "lang1_dedup")
	write_string_arrays_to_file(
		"../generated_lang1_raw_dedup.odin",
		lang1_raw_dedup[:],
		"lang1_raw_dedup",
	)
	write_string_arrays_to_file("../generated_trans1_dedup.odin", trans1_dedup[:], "trans1_dedup")

	tic = time.tick_now()
	lang1_index: [dynamic][dynamic]int
	hashes_arr := make([dynamic]uintptr)
	hashes_map := make(map[uintptr]string)
	unique_words := make(map[string]int)
	collisions_counter := 0
	unique_word_idx := -1
	for array, idx in lang1_dedup {
		for word in array {
			pword := word
			hash := utils.hash(&pword)
			if !(word in unique_words) {
				unique_word_idx += 1
				unique_words[word] = unique_word_idx

				dyn_arr := make([dynamic]int)
				append(&lang1_index, dyn_arr)

				append(&hashes_arr, hash)

				// We're only here if `word` is a not yet encountered word.
				if hash in hashes_map { 	// So, if we have a new word but the hash is already known, we have a collision.
					fmt.printfln(
						"Collision: `%v` maps to hash `%v` but `%v` also maps there",
						word,
						hash,
						hashes_map[hash],
					)
					collisions_counter += 1
				} else {
					hashes_map[hash] = word
				}
			}
			index := unique_words[word]
			append(&lang1_index[index], idx)
		}
	}
	assert(len(lang1_index) == len(unique_words))
	assert(len(lang1_index) == len(hashes_arr))
	assert(len(lang1_index) == len(hashes_map))
	assert(collisions_counter == 0, "There were hash collisions.")

	hashes_arr_clone := slice.clone(hashes_arr[:])
	sort_indices := slice.sort_with_indices(hashes_arr_clone)

	toc = time.tick_since(tic)
	fmt.printfln("Number of unique words: %v (%v)", len(unique_words), toc)

	utils.write_hash_arr_to_file(
		"../generated_hash_arr.odin",
		hashes_arr[:],
		"hashes_arr",
		sort_indices,
	)

	utils.write_index_arr_to_file(
		"../generated_lang1_index.odin",
		lang1_index[:],
		"lang1_index",
		sort_indices,
	)
}
