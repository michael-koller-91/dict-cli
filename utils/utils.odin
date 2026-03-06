package utils

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

SEED :: 123456789

hash :: proc(s: ^string) -> uintptr {
	return runtime.default_hasher_string(s, SEED)
}

map_hash_to_index :: proc(hash: uintptr, capacity: uintptr) -> uintptr {
	return uintptr(hash & uintptr(capacity - 1))
}

/*
Match the `needles` with optional gaps against the `haystack`.

Inputs:
- haystack: An array of strings to be matched against
- needles: An array of strings to match against the `haystack`

Returns:
- score: The number of matches

Example:

	import "core:fmt"
	fmt.println(match_score([]string{"foo", "bar", "baz"}, []string{"foo", "baz"})) // 2 matches with one gap
	fmt.println(match_score([]string{"foo", "bar", "baz"}, []string{"bar", "baz"})) // 2 matches without a gap
	fmt.println(match_score([]string{"foo", "bar", "baz"}, []string{"bar", "foo"})) // 1 match, order matters

Output:

	2
	2
	1

*/
match_score :: proc(haystack, needles: []string) -> (score: int) {
	score = 0
	i := 0
	for needle in needles {
		for j in i ..< len(haystack) {
			if needle == haystack[j] {
				score += 1
				break
			}
		}
		i += 1
	}
	return
}

write_hash_arr_to_file :: proc(
	file_out_path: string,
	hashes_arr: []uintptr,
	array_name: string,
	sort_indices: []int,
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

	builder := strings.builder_make()

	tic := time.tick_now()
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package main\n")
	strings.write_string(&builder, "@(rodata)\n")
	strings.write_string(&builder, fmt.aprintfln("%v: [%v]int = {{", array_name, len(hashes_arr)))
	for idx in 0 ..< len(hashes_arr) {
		index := sort_indices[idx]
		strings.write_string(&builder, fmt.aprintf("\t%v = %v,\n", index, hashes_arr[index]))
	}
	strings.write_string(&builder, "}\n")
	os.write_string(file_out_handle, strings.to_string(builder))
	os.close(file_out_handle)

	toc := time.tick_since(tic)
	fmt.printfln(" (%v)", toc)
}

write_index_arr_to_file :: proc(
	file_out_path: string,
	index_arr: [][dynamic]int,
	array_name: string,
	sort_indices: []int,
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

	builder := strings.builder_make()

	tic := time.tick_now()
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package main\n")
	strings.write_string(&builder, "@(rodata)\n")
	strings.write_string(&builder, fmt.aprintfln("%v: [%v][]int = {{", array_name, len(index_arr)))
	for idx in 0 ..< len(index_arr) {
		index := sort_indices[idx]
		strings.write_string(&builder, fmt.aprintf("\t%v = {{", index))
		for elem, i in index_arr[index] {
			strings.write_string(&builder, fmt.aprintf("%v", elem))
			if i != len(index_arr[index]) - 1 {
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
