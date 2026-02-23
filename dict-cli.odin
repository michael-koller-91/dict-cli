// TODO: add a command line flag to print all hits
// TODO: does it make sense to have all single-words as key in a map for faster matching?
// TODO: should "etw. denken" be considered a one-word-hit for "denken"?
// - dict.cc displays it like that

package main

import "base:runtime"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "prepare_db"

VERSION :: "0.0.1"


match_score :: proc(haystack: []string, needles: []string) -> (count: int) {
	count = 0
	i := 0
	for needle in needles {
		for j in i ..< len(haystack) {
			if needle == haystack[j] {
				count += 1
				break
			}
		}
	}
	return
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

	hit_1 := -1
	if num_phrases <= 1 {
		for word, idx in lang1_dedup_1_word {
			if phrases[0] == word {
				hit_1 = idx
				break
			}
		}
		if hit_1 == -1 {
			toc := time.tick_since(tic)
			fmt.printfln("done. No hit (%v)", toc)
			os.exit(0)
		}
	}

	hits_2: [dynamic]int
	if num_phrases <= 2 {
		for words, idx in lang1_dedup_2_words {
			score := match_score(words, phrases)
			if score == num_phrases {
				append(&hits_2, idx)
			}
		}
	}

	hits_3: [dynamic]int
	for words, idx in lang1_dedup_3_words {
		score := match_score(words, phrases)
		if score == num_phrases {
			append(&hits_3, idx)
		}
	}

	hits_4: [dynamic]int
	for words, idx in lang1_dedup_4_words {
		score := match_score(words, phrases)
		if score == num_phrases {
			append(&hits_4, idx)
		}
	}

	hits_mult: [dynamic]int
	for words, idx in lang1_dedup_mult_words {
		score := match_score(words, phrases)
		if score >= num_phrases {
			append(&hits_mult, idx)
		}
	}

	num_hits := len(hits_2) + len(hits_3) + len(hits_4) + len(hits_mult)
	if hit_1 != -1 {num_hits += 1}

	toc := time.tick_since(tic)
	fmt.printfln("done. %v hits (%v)", num_hits, toc)

	hits_1 := hit_1 == -1 ? 0 : 1
	fmt.println("hits_1         =", hits_1)
	fmt.println("len(hits_2)    =", len(hits_2))
	fmt.println("len(hits_3)    =", len(hits_3))
	fmt.println("len(hits_4)    =", len(hits_4))
	fmt.println("len(hits_mult) =", len(hits_mult))

	//lang2_dedups_single_word
	//lang2_dedups_multiple_words

	originals: []string
	translations: []string
	//for idx, hitcount in hits_2 {
	if num_phrases <= 1 {
		originals = lang1_raw_dedups_1_word[hit_1]
		translations = trans1_dedups_1_word[hit_1]
		for translation, idx in translations {
			fmt.printfln("%v  |  %v", originals[idx], translation)
		}
		fmt.println()
	}

	lines_max :: 10

	lines_printed := 0
	if num_phrases <= 2 {
		for hit in hits_2 {
			originals = lang1_raw_dedups_2_words[hit]
			translations = trans1_dedups_2_words[hit]
			for translation, idx in translations {
				fmt.printfln("%v  |  %v", originals[idx], translation)
				lines_printed += 1
			}
			if lines_printed > lines_max {
				fmt.println("...")
				break
			}
		}
		if len(hits_2) > 0 {fmt.println()}
	}

	lines_printed = 0
	for hit in hits_3 {
		originals = lang1_raw_dedups_3_words[hit]
		translations = trans1_dedups_3_words[hit]
		for translation, idx in translations {
			fmt.printfln("%v  |  %v", originals[idx], translation)
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
		originals = lang1_raw_dedups_4_words[hit]
		translations = trans1_dedups_4_words[hit]
		for translation, idx in translations {
			fmt.printfln("%v  |  %v", originals[idx], translation)
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
		originals = lang1_raw_dedups_mult_words[hit]
		translations = trans1_dedups_mult_words[hit]
		for translation, idx in translations {
			fmt.printfln("%v  |  %v", originals[idx], translation)
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
