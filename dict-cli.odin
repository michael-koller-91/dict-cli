package main

import "base:runtime"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

VERSION :: "0.0.1"

write_examples :: proc() {
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

	fmt.print("Searching...")
	tic := time.tick_now()
	hits: [dynamic]int
	max_len := 0
	for elem, idx in lang1_lower {
		if strings.contains(elem, phrase) {
			append(&hits, idx)
			if len(elem) > max_len {
				max_len = len(elem)
			}
		}
	}
	toc := time.tick_since(tic)
	fmt.printfln("done. %v hits in %v seconds.", len(hits), toc)

	for idx in hits {
		fmt.printfln("> %v | %v", strings.left_justify(lang1[idx], max_len, " "), lang2[idx])
	}
}
