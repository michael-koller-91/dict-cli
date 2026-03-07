package prepare_db

import "./../utils"
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

quick_test_remove_bracket_terms :: proc() {
	ex1 := "((für) etw. [Akk.]) pauken [ugs.] [intensiv lernen]"
	ex1_noc := utils.remove_bracket_terms(ex1)
	fmt.println(ex1)
	fmt.println(ex1_noc)

	ex2 := "(älles) Heer {n} {m} des Himmels [Luther]"
	ex2_noc := utils.remove_bracket_terms(ex2)
	fmt.println(ex2)
	fmt.println(ex2_noc)

	ex3 := "asdf <abbrev.> test"
	ex3_noc := utils.remove_bracket_terms(ex3)
	fmt.println(ex3)
	fmt.println(ex3_noc)

	ex4 := "asdf bbrev.> test"
	ex4_noc := utils.remove_bracket_terms(ex4)
	fmt.println(ex4)
	fmt.println(ex4_noc)

	ex5 := "asdf <bbrev test"
	ex5_noc := utils.remove_bracket_terms(ex5)
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

	dir := "generated"
	if os.exists(dir) {
		remove_ok := os.remove_all(dir)
		if remove_ok != os.ERROR_NONE {
			fmt.eprintfln("ERROR: Could not remove directory %v.", dir)
		}
	}
	mkdir_ok := os.mkdir(dir)
	if mkdir_ok != os.ERROR_NONE {
		fmt.eprintfln("ERROR: Could not make directory %v.", dir)
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
	normalizer := utils.get_normalizer()
	lang1_normalized: [dynamic][]string
	for _, j in lang1_raw {
		normalized := utils.extract_normalized_term(lang1_raw[j], normalizer)
		fields := utils.split_fields(normalized)
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

	utils.write_string_arrays_to_file(
		fmt.aprintf("%v/generated_lang1_dedup.odin", dir),
		lang1_dedup[:],
		"lang1_dedup",
	)
	utils.write_string_arrays_to_file(
		fmt.aprintf("%v/generated_lang1_raw_dedup.odin", dir),
		lang1_raw_dedup[:],
		"lang1_raw_dedup",
	)
	utils.write_string_arrays_to_file(
		fmt.aprintf("%v/generated_trans1_dedup.odin", dir),
		trans1_dedup[:],
		"trans1_dedup",
	)

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
		fmt.aprintf("%v/generated_hash_arr.odin", dir),
		hashes_arr[:],
		"hashes_arr",
		sort_indices,
	)

	utils.write_index_arr_to_file(
		fmt.aprintf("%v/generated_lang1_index.odin", dir),
		lang1_index[:],
		"lang1_index",
		sort_indices,
	)
}
