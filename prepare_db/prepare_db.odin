package prepare_db

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

write_string_array_to_file :: proc(file_out_path: string, array: []string, array_name: string) {
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
	os.write_string(file_out_handle, "}")
	toc := time.tick_since(tic)

	os.close(file_out_handle)
	fmt.printfln("Wrote file %v in %v", file_out_path, toc)
}

main :: proc() {
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
	lang1_lower: [dynamic]string
	lang2_lower: [dynamic]string

	it := string(file_read)
	k := 0
	for str in strings.split_lines_after_iterator(&it) {
		k += 1
		if str[0] == '#' {
			continue
		}
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

	for _, j in lang1 {
		append(&lang1_lower, strings.to_lower(lang1[j]))
		append(&lang2_lower, strings.to_lower(lang2[j]))
	}
	assert(len(lang1) == len(lang2))
	assert(len(lang1) == len(lang1_lower))
	assert(len(lang1) == len(lang2_lower))
	assert(len(lang1) == len(category))
	assert(len(lang1) == len(area))

	arrays: [][]string = {lang1[:], lang2[:], lang1_lower[:], lang2_lower[:], category[:], area[:]}
	array_names: []string = {"lang1", "lang2", "lang1_lower", "lang2_lower", "category", "area"}
	files_out: []string = {
		"../generated_lang1.odin",
		"../generated_lang2.odin",
		"../generated_lang1_lower.odin",
		"../generated_lang2_lower.odin",
		"../generated_category.odin",
		"../generated_area.odin",
	}
	for array, k in arrays {
		write_string_array_to_file(files_out[k], array, array_names[k])
	}
}
