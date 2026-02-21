// TODO: add a command line flag to print all hits_2
// TODO: how would we handle searching for "an gehen" and finding "an bord gehen"
// - probably via Smith-Waterman
// TODO: is Needleman-Wunsch what we want?
// TODO: can sm_word be implement with i8? think about the largest possible match value
// TODO: does it make sense to have all single-words as key in a map for faster matching?
// TODO: in `((für) etw. [Akk.]) pauken [ugs.] [intensiv lernen]`, we'll currently split off "pauken" because it comes after `[Akk.]`
// TODO: should "etw. denken" be considered a one-word-hit for "denken"?
// - dict.cc displays it like that

package main

import "base:runtime"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"
// import "core:text/regex"
import "core:time"
import sm "smith-waterman"

VERSION :: "0.0.1"

write_examples :: proc() {
}

exact_word_match :: proc(haystack: ^string, needle: string) -> bool {
	count := 0
	for s in strings.split_iterator(haystack, " ") {
		count += 1
		if needle == s {return true}
	}
	return false
}


main :: proc() {
	Args :: struct {
		phrase:  string `args:"pos=0,phrase" usage:"The phrase to translate."`,
		version: bool `args:"name=version" usage:"Print the verison number and exit."`,
		v:       bool `args:"name=v,hidden" usage:"Print the verison number and exit."`,
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

	// pattern := fmt.aprintf("\\b%v\\b", phrase)
	// fmt.println("pattern =", pattern)
	// fpat, fpat_err := regex.create(pattern, {.No_Capture})
	// if fpat_err != nil {
	// 	fmt.eprintfln(
	// 		"ERROR: Failed to create regular expression from filename pattern \"%v\": %v. Maybe escaping is missing?",
	// 		phrase,
	// 		fpat_err,
	// 	)
	// 	os.exit(1)
	// }

	fmt.print("Searching...")
	tic := time.tick_now()
	hit_1 := -1
	for word, idx in lang1_dedup_1_word {
		if phrase == word {
			hit_1 = idx
			break
		}
	}
	if hit_1 == -1 {
		toc := time.tick_since(tic)
		fmt.printfln("done. No hit (%v)", toc)
		os.exit(0)
	}

	hits_2: [dynamic]int
	for words, idx in lang1_dedup_2_words {
		for word in words {
			if phrase == word {
				append(&hits_2, idx)
			}
		}
	}

	hits_3: [dynamic]int
	for words, idx in lang1_dedup_3_words {
		for word in words {
			if phrase == word {
				append(&hits_3, idx)
			}
		}
	}

	hits_4: [dynamic]int
	for words, idx in lang1_dedup_4_words {
		for word in words {
			if phrase == word {
				append(&hits_4, idx)
			}
		}
	}

	hits_mult: [dynamic]int
	for words, idx in lang1_dedup_mult_words {
		for word in words {
			if phrase == word {
				append(&hits_mult, idx)
			}
		}
	}

	//num_hits := hit == -1 ? len(hits_2) : len(hits_2) + 1
	num_hits := 1 + len(hits_2) + len(hits_3) + len(hits_4) + len(hits_mult)

	toc := time.tick_since(tic)
	fmt.printfln("done. %v hits (%v)", num_hits, toc)

	//lang2_dedups_single_word
	//lang2_dedups_multiple_words

	//for idx, hitcount in hits_2 {
	translations := trans1_dedups_1_word[hit_1]
	for translation in translations {
		fmt.println(translation)
	}
	fmt.println()

	lines_max :: 10

	lines_printed := 0
	for hit in hits_2 {
		translations = trans1_dedups_2_words[hit]
		for translation in translations {
			fmt.println(translation)
			lines_printed += 1
		}
		if lines_printed > lines_max {
			fmt.println("...")
			break
		}
	}
	if len(hits_2) > 0 {fmt.println()}

	lines_printed = 0
	for hit in hits_3 {
		translations = trans1_dedups_3_words[hit]
		for translation in translations {
			fmt.println(translation)
			lines_printed += 1
		}
		if lines_printed > lines_max {
			fmt.println("...")
			break
		}
	}
	if len(hits_3) > 0 {fmt.println()}

	lines_printed = 0
	for hit in hits_4 {
		translations = trans1_dedups_4_words[hit]
		for translation in translations {
			fmt.println(translation)
			lines_printed += 1
		}
		if lines_printed > lines_max {
			fmt.println("...")
			break
		}
	}
	if len(hits_4) > 0 {fmt.println()}

	lines_printed = 0
	for hit in hits_mult {
		translations = trans1_dedups_mult_words[hit]
		for translation in translations {
			fmt.println(translation)
			lines_printed += 1
		}
		if lines_printed > lines_max {
			fmt.println("...")
			break
		}
	}

	// width := 50
	// for idx, hitcount in hits_2 {
	// 	s := strings.left_justify(lang1[idx], max_len, " ")
	// 	fmt.printfln("> %v | %v | %v", category[idx], s, lang2[idx])

	// 	if hitcount > 20 {
	// 		fmt.println("Only the first 20 results were printed.")
	// 		break
	// 	}
	// }
}
