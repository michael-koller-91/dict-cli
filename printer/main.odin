package printer

import "core:fmt"
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

print :: proc(str1, str2: []string, width_per_str: int) {
	assert(len(str1) == len(str2))
	for i in 0 ..< len(str1) {
		fmt.printfln("%v | %v", to_width(str1[i], width_per_str), to_width(str2[i], width_per_str))
	}
}

main :: proc() {
	print(str1, str2, 20)
}
