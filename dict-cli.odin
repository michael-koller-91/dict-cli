// TODO: add a command line flag to print all hits
// TODO: normalize database: replace all white spaces with " " so that exact_word_match works
// TODO: how would we handle searching for "an gehen" and finding "an bord gehen"
// TODO: can sm_word be implement with i8? think about the largest possible match value
// TODO: does it make sense to have all single-words as key in a map for faster matching?
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
	hits: [dynamic]int
	max_len := 0
	for &array, idx in lang1_words {
		//if exact_word_match(&elem, phrase) {
		//_, fmatch := regex.match(fpat, elem)
		//if fmatch {
		if len(array) == 1 {
			for &elem in array {
				//if sm.sm_word(phrase, elem) == 1 {
				if phrase == elem {
					append(&hits, idx)
					if len(elem) > max_len {
						max_len = len(elem)
					}
				}
			}
		}
	}
	toc := time.tick_since(tic)
	fmt.printfln("done. %v hits in %v seconds.", len(hits), toc)

	width := 50
	for idx, hitcount in hits {
		s := strings.left_justify(lang1[idx], max_len, " ")
		fmt.printfln("> %v | %v | %v", category[idx], s, lang2[idx])

		if hitcount > 20 {
			fmt.println("Only the first 20 results were printed.")
			break
		}
	}
}
