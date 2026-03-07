// TODO: add a command line flag to print all hits
// TODO: should "etw. denken" be considered a one-word-hit for "denken"?
// - dict.cc displays it like that
// TODO: write unit tests (e.g., for match_score)
// TODO: add a command line flag to specifically print all n-word hits
// TODO: put foreign import into a generated file and import that one here

package main

foreign import gen "./prepare_db/generated/generated.a"
foreign gen {
	hashes_arr: [564026]int
	lang1_dedup: [815029][]string
	lang1_index: [564026][]int
	lang1_raw_dedup: [815029][]string
	trans1_dedup: [815029][]string
}

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "printer"
import "utils"

VERSION :: "0.0.1"

NUM_ARRAYS :: 5

main :: proc() {
	program, args := os.args[0], os.args[1:]
	if len(args) == 0 {
		fmt.println("Usage: dict <word(s)>")
		os.exit(0)
	}
	if (len(args) == 1) & ((args[0] == "-v") | (args[0] == "-version")) {
		fmt.printfln("dict %v", VERSION)
		os.exit(0)
	}

	normalizer := utils.get_normalizer()
	phrases_: [dynamic]string
	for word, idx in args {
		lower := strings.to_lower(word)
		normalized := utils.normalize_runes(lower, normalizer)
		append(&phrases_, strings.clone(normalized))
	}
	phrases := phrases_[:]

	num_phrases := len(phrases)

	fmt.print("Searching...")
	tic := time.tick_now()

	hash_first_word := int(utils.hash(&phrases[0]))

	// bisection search
	hash_index := -1
	left := 0
	right := len(hashes_arr)
	for left < right {
		mid := (left + right) / 2
		hash := hashes_arr[mid]
		if hash == hash_first_word {
			hash_index = mid
			break
		} else if hash_first_word < hash {
			right = mid
		} else {
			left = mid + 1
		}
	}

	if hash_index == -1 {
		toc := time.tick_since(tic)
		fmt.printfln("done (no hit). (%v)", toc)
		os.exit(0)
	}

	indices := lang1_index[hash_index]

	hits: [NUM_ARRAYS][dynamic]int
	for idx in indices {
		words := lang1_dedup[idx]
		score := utils.match_score(words, phrases)
		if score == num_phrases {
			if (1 <= len(words)) & (len(words) <= NUM_ARRAYS - 1) {
				append(&hits[len(words) - 1], idx)
			} else {
				append(&hits[NUM_ARRAYS - 1], idx)
			}
		}
	}

	num_hits := 0
	for i in 0 ..< NUM_ARRAYS {
		num_hits += len(hits[i])
	}

	toc := time.tick_since(tic)
	fmt.printfln("done. %v hits (%v)", num_hits, toc)

	for i in 0 ..< NUM_ARRAYS {
		num_hits += len(hits[i])
		fmt.printfln("len(hits[%v]) = %v", i, len(hits[i]))
	}
	fmt.println()

	column_width :: 50
	lines_max :: 5

	tic = time.tick_now()
	builder := strings.builder_make()

	printed_topline := false
	originals: []string
	translations: []string

	print_dots := false
	first_print := true
	for i in 0 ..< NUM_ARRAYS {
		lines_printed := 0

		if len(hits[i]) > 0 {
			if (!printed_topline) {
				printer.print_topline(&builder, column_width)
				printed_topline = true
			} else {
				if print_dots {
					printer.print_dots(&builder, column_width)
				} else {
					printer.print_hline(&builder, column_width)
				}
			}
			first_print = false
		}
		print_dots = false

		l_max := lines_max
		if i == 0 {
			l_max = 100
		}

		for hit in hits[i] {
			originals = lang1_raw_dedup[hit]
			translations = trans1_dedup[hit]
			if len(originals) <= l_max - lines_printed {
				printer.print(&builder, originals, translations, column_width)
			} else {
				printer.print(
					&builder,
					originals,
					translations,
					column_width,
					l_max - lines_printed,
				)
				print_dots = true
				break
			}
			lines_printed += len(originals)
		}
	}
	if print_dots {
		printer.print_bottomline_dots(&builder, column_width)
	} else {
		printer.print_bottomline(&builder, column_width)
	}
	fmt.println(strings.to_string(builder))

	toc = time.tick_since(tic)
	fmt.printfln("Printing took %v", toc)
}
