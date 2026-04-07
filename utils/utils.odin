package utils

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

SEED :: 123456789

/*
Convert the input string to lower case, remove all terms in brackets, normalize its runes.

*Allocates Using Provided Allocator*
*/
extract_normalized_term :: proc(
	s: string,
	normalizer: map[rune]string,
	allocator := context.allocator,
) -> string {
	lower := strings.to_lower(s)
	no_brackets := remove_bracket_terms(lower, allocator)
	normalized := normalize_runes(no_brackets, normalizer, allocator)
	return normalized
}

/*
Find the positions of a pair of runes (typically a pair of brackets).
*/
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

/*
Compute the default hash for the given string.
*/
hash :: proc(s: ^string) -> uintptr {
	return runtime.default_hasher_string(s, SEED)
}

/*
Compute the index to which the provided `hash` would be mapped in a map.
*/
map_hash_to_index :: proc(hash: uintptr, capacity: uintptr) -> uintptr {
	return uintptr(hash & uintptr(capacity - 1))
}

/*
Open a file specified by `path` after removing the previous version.
*/
open_file :: proc(path: string) -> ^os.File {
	if os.exists(path) {
		remove_err := os.remove(path)
		if remove_err != os.ERROR_NONE {
			fmt.panicf("Could not remove file", path, ":", remove_err)
		}
	}
	file_handle, open_err := os.open(path, os.O_CREATE | os.O_WRONLY, os.Permissions_Read_All)
	if open_err != os.ERROR_NONE {
		fmt.panicf("Could not create file", path, ":", open_err)
	}
	return file_handle
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

/*
Remove all pairs of brackets as well as all runes within them.

*Allocates Using Provided Allocator*
*/
remove_pairs_of_brackets :: proc(
	s: string,
	openbr: rune,
	closebr: rune,
	allocator := context.allocator,
) -> string {
	output := s
	match, begin, end := find_pair_of_brackets(s, openbr, closebr)
	pairs_counter := 0
	for match {
		pairs_counter += 1
		output, _ = strings.remove(output, output[begin:end + 1], 1, allocator)
		match, begin, end = find_pair_of_brackets(output, openbr, closebr)
		if pairs_counter > 100 {
			fmt.println(s)
			panic("How could there be so many pairs of brackets?!")
		}
	}
	return output
}

/*
Split a string by whitespaces into a list of (non-empty) strings.

*Allocates Using Provided Allocator*
*/
split_fields :: proc(s: string, allocator := context.allocator) -> []string {
	fields := strings.fields(s, allocator) // split by white space
	r: [dynamic]string
	for field, j in fields {
		lstr := trim(field)
		if len(lstr) > 0 {append(&r, lstr)}
	}
	return r[:]
}

/*
Trim all whitespaces as well as the following runes: ",", "!", "...".

*Allocates Using Provided Allocator*
*/
trim :: proc(s: string, allocator := context.allocator) -> string {
	lstr := strings.to_lower(s, allocator)
	lstr = strings.trim_space(lstr)
	lstr = strings.trim(lstr, ",")
	lstr = strings.trim(lstr, "!")
	lstr = strings.trim(lstr, "...")
	return lstr
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

/*
Sort an array of `uintptr` by the provided indices and write it to a file.

*Allocates Using Provided Allocator*
*/
write_hash_arr_to_file :: proc(
	file_out_path: string,
	hashes_arr: []uintptr,
	array_name: string,
	sort_indices: []int,
	allocator := context.allocator,
) {
	tic := time.tick_now()

	file_out_handle := open_file(file_out_path)
	fmt.print("Writing file", file_out_path)

	builder := strings.builder_make(allocator)
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package gen\n")
	strings.write_string(&builder, "@(export = true)\n")
	strings.write_string(&builder, fmt.aprintfln("%v: [%v]int = {{", array_name, len(hashes_arr)))
	for idx in sort_indices {
		strings.write_string(&builder, fmt.aprintf("\t%v,\n", hashes_arr[idx]))
	}
	strings.write_string(&builder, "}\n")
	os.write_string(file_out_handle, strings.to_string(builder))
	os.close(file_out_handle)

	toc := time.tick_since(tic)
	fmt.printfln(" (%v)", toc)
}

/*
Sort an array of arrays of `int` by the provided indices and write it to a file.

*Allocates Using Provided Allocator*
*/
write_index_arr_to_file :: proc(
	file_out_path: string,
	index_arr: [][dynamic]int,
	array_name: string,
	sort_indices: []int,
	allocator := context.allocator,
) {
	tic := time.tick_now()

	file_out_handle := open_file(file_out_path)
	fmt.print("Writing file", file_out_path)

	builder := strings.builder_make(allocator)
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package gen\n")
	strings.write_string(&builder, "@(export = true)\n")
	strings.write_string(&builder, fmt.aprintfln("%v: [%v][]int = {{", array_name, len(index_arr)))
	for idx in sort_indices {
		strings.write_string(&builder, fmt.aprint("\t{"))
		for elem, i in index_arr[idx] {
			strings.write_string(&builder, fmt.aprintf("%v", elem))
			if i != len(index_arr[idx]) - 1 {
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

/*
Write an array of string arrays to a file.

*Allocates Using Provided Allocator*
*/
write_string_arrays_to_file :: proc(
	file_out_path: string,
	arrays: [][]string,
	array_name: string,
	allocator := context.allocator,
) {
	tic := time.tick_now()

	file_out_handle := open_file(file_out_path)
	fmt.print("Writing file", file_out_path)

	builder := strings.builder_make(allocator)
	strings.write_string(&builder, "// This is generated code!\n")
	strings.write_string(&builder, "package gen\n")
	strings.write_string(&builder, "@(export = true)\n")
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
