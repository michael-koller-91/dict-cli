// TODO: add a command line flag to print all hits
// TODO: does it make sense to have all single-words as key in a map for faster matching?
// TODO: should "etw. denken" be considered a one-word-hit for "denken"?
// - dict.cc displays it like that
// TODO: write unit tests (e.g., for match_score)
// TODO: add a command line flag to specifically print all n-word hits

package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "prepare_db"
import "printer"
import "utils"

VERSION :: "0.0.1"

NUM_ARRAYS :: 5

print_hits :: proc(hits: [][dynamic]int) {
	column_width :: 50
	lines_max :: 5

	tic := time.tick_now()
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

	toc := time.tick_since(tic)
	fmt.printfln("Printing took %v", toc)
}

main :: proc() {
	/*
	Args :: struct {
		phrase:  string `args:"pos=0,phrase" usage:"The phrase to translate."`,
		version: bool `args:"name=version" usage:"Print the version number and exit."`,
		v:       bool `args:"name=v,hidden" usage:"Print the version number and exit."`,
	}
	args: Args
	parse_err := flags.parse(&args, os.args[1:])
	switch e in parse_err {
	case flags.Validation_Error:
		flags.write_usage(os.stream_from_handle(os.stdout), Args, os.args[0])
		write_examples()
		fmt.eprintfln("\n[%T] %s", e, e.message)
		os.exit(1)
	case flags.Parse_Error:
		fmt.eprintfln("[%T.%v] %s", e, e.reason, e.message)
		os.exit(1)
	case flags.Open_File_Error:
		fmt.eprintfln(
			"[%T#%i] Unable to open file with perms 0o%o in mode 0x%x: %s",
			e,
			e.errno,
			e.perms,
			e.mode,
			e.filename,
		)
		os.exit(1)
	case flags.Help_Request:
		flags.write_usage(os.stream_from_handle(os.stdout), Args, os.args[0])
		write_examples()
		os.exit(0)
	}
	if args.version | args.v {
		fmt.printfln("dict %v", VERSION)
		os.exit(0)
	}
	if args.phrase == "" {
		flags.write_usage(os.stream_from_handle(os.stdout), Args, os.args[0])
		os.exit(0)
	}
	phrase := strings.to_lower(args.phrase)
	normalizer := prepare_db.get_normalizer()
	phrase_normalized := prepare_db.normalize_runes(phrase, normalizer)
	*/

	program, args := os.args[0], os.args[1:]
	if len(args) == 0 {
		fmt.println("Usage: dict <word(s)>")
		os.exit(0)
	}
	if (len(args) == 1) & ((args[0] == "-v") | (args[0] == "-version")) {
		fmt.printfln("dict %v", VERSION)
		os.exit(0)
	}

	normalizer := prepare_db.get_normalizer()
	phrases_: [dynamic]string
	for word, idx in args {
		lower := strings.to_lower(word)
		normalized := prepare_db.normalize_runes(lower, normalizer)
		append(&phrases_, strings.clone(normalized))
	}
	phrases := phrases_[:]

	num_phrases := len(phrases)

	fmt.print("Searching...")
	tic := time.tick_now()

	hash_first_word := int(utils.hash(&phrases[0]))

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
		fmt.printfln("done. (%v)", toc)
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

	print_hits(hits[:])

}
