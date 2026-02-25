package printer

import "core:fmt"
import "core:io"
import "core:strings"

str1: []string = {
	"trüben",
	"trüben",
	"trüben",
	"trüben",
	"trüben [Geist, Stimmung etc.",
	"sich trübe",
	"sich trübe",
	"sich trübe",
	"sich [Akk.] trüben [Blick",
	"etw. [Akk.] trübe",
	"etw. [Akk.] trüben [auch fig.: jds. Freude etc.",
	"etw. [Akk.] trüben [Glück, Stimmung",
	"mit trüben Auge",
	"jds. Hoffnungen trüben",
	"den Blick trübe",
}

str2: []string = {
	"to dim",
	"to dull [consciousness, vision]",
	"to roil",
	"to tarnish",
	"to obfuscate",
	"to darken [atmosphere, mood]",
	"to dull [eyes]",
	"to mist",
	"to grow dim [vision]",
	"to opacify sth.",
	"to cloud sth. [also fig.: sb.'s joy etc.]",
	"to mar sth. [happiness, mood]",
	"blearily",
	"to darken sb.'s hopes",
	"to blur the vision",
}

to_width :: proc(str: string, width: int) -> []string {
	s := make([]string, 1)
	s[0] = str
	return s
}

print_line :: proc(builder: ^strings.Builder, str1, str2: string, column_width: int) {
	strings.write_string(builder, "│ ")
	strings.write_string(builder, strings.left_justify(str1, column_width, " "))
	strings.write_string(builder, "│ ")
	strings.write_string(builder, strings.left_justify(str2, column_width, " "))
	strings.write_string(builder, "│\n")
}

print_lines :: proc(builder: ^strings.Builder, str1, str2: string, column_width: int) {
	n1 := strings.rune_count(str1)
	n2 := strings.rune_count(str2)
	if (n1 <= column_width) & (n2 <= column_width) {
		print_line(builder, str1, str2, column_width)
	} else if (n1 > column_width) & (n2 <= column_width) {
		n_lines := n1 / column_width + 1
		s1 := strings.left_justify(str1, n_lines * column_width, " ")
		s2 := strings.left_justify(str2, n_lines * column_width, " ")
		for i in 0 ..< n_lines {
			print_line(
				builder,
				s1[i * column_width:(i + 1) * column_width],
				s2[i * column_width:(i + 1) * column_width],
				column_width,
			)
		}
	}
}

print_topline :: proc(builder: ^strings.Builder, column_width: int) {
	strings.write_string(builder, "┌")
	for i in 0 ..< column_width + 1 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┬")
	for i in 0 ..< column_width + 1 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┐\n")
}

print_hline :: proc(builder: ^strings.Builder, column_width: int) {
	strings.write_string(builder, "├")
	for i in 0 ..< column_width + 1 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┼")
	for i in 0 ..< column_width + 1 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┤\n")
}

print_dots :: proc(builder: ^strings.Builder, column_width: int) {
	strings.write_string(builder, "├")
	strings.write_string(builder, "─")
	strings.write_string(builder, "···")
	for i in 0 ..< column_width - 3 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┼")
	strings.write_string(builder, "─")
	strings.write_string(builder, "···")
	for i in 0 ..< column_width - 3 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┤\n")
}

print_bottomline :: proc(builder: ^strings.Builder, column_width: int) {
	strings.write_string(builder, "└")
	for i in 0 ..< column_width + 1 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┴")
	for i in 0 ..< column_width + 1 {
		strings.write_string(builder, "─")
	}
	strings.write_string(builder, "┘\n")
}

print :: proc(
	builder: ^strings.Builder,
	str1, str2: []string,
	column_width: int,
	num_rows: int = -1,
) {
	assert(len(str1) == len(str2))
	n_rows := num_rows == -1 ? len(str1) : num_rows
	for i in 0 ..< n_rows {
		print_lines(builder, str1[i], str2[i], column_width)
	}
}

main :: proc() {
	column_width := 20
	builder := strings.builder_make()
	print_topline(&builder, column_width)
	print(&builder, str1, str2, column_width)
	print_bottomline(&builder, column_width)
	fmt.print(strings.to_string(builder))
}
