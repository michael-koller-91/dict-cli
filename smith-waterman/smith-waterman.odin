package smith_waterman

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

match :: 1
mismatch :: -1
gap :: -1

s :: proc(a: string, i: int, b: string, j: int) -> int {
	if a[i - 1] == b[j - 1] {
		return match
	} else {
		return mismatch
	}
}

sm1 :: proc(a: string, b: string) -> int {
	n := len(a) + 1
	m := len(b) + 1
	h := make([dynamic][dynamic]int, n)

	// init
	for i in 0 ..< n {
		h[i] = make([dynamic]int, m)
		h[i][0] = 0
	}
	for j in 0 ..< m {
		h[0][j] = 0
	}

	score := 0
	for i in 1 ..< n {
		for j in 1 ..< m {
			max := 0
			h1 := h[i - 1][j - 1] + s(a, i, b, j)
			if h1 > max {max = h1}
			h2 := h[i - 1][j] + gap
			if h2 > max {max = h2}
			h3 := h[i][j - 1] + gap
			if h3 > max {max = h3}
			h[i][j] = max
			if max > score {score = max}
		}
	}
	// for j in 0 ..< m {
	// 	for i in 0 ..< n {
	// 		fmt.printf("% 3d, ", h[i][j])
	// 	}
	// 	fmt.println()
	// }
	return score
}

sm2 :: proc(a: string, b: string) -> int {
	n := utf8.rune_count_in_string(a) + 1
	m := utf8.rune_count_in_string(b) + 1
	h := make([][]int, n)
	if (n == 1) | (m == 1) {return 0}

	// init
	for i in 0 ..< n {
		h[i] = make([]int, m)
		h[i][0] = 0
	}
	for j in 0 ..< m {
		h[0][j] = 0
	}

	score := 0
	i := 1
	for ai in a {
		defer i += 1
		j := 1
		for bj in b {
			defer j += 1
			max := 0
			h1 := h[i - 1][j - 1]
			if ai == bj {h1 += match} else {h1 += mismatch}
			if h1 > max {max = h1}
			h2 := h[i - 1][j] + gap
			if h2 > max {max = h2}
			h3 := h[i][j - 1] + gap
			if h3 > max {max = h3}
			h[i][j] = max
			if max > score {score = max}
		}
	}
	// for j in 0 ..< m {
	// 	for i in 0 ..< n {
	// 		fmt.printf("% 3d, ", h[i][j])
	// 	}
	// 	fmt.println()
	// }
	return score
}

sm3 :: proc(a: string, b: string) -> int {
	n := utf8.rune_count_in_string(a) + 1
	m := utf8.rune_count_in_string(b) + 1
	if (n == 1) | (m == 1) {return 0}
	h: [2][]int
	h[0] = make([]int, m)
	h[1] = make([]int, m)

	// init
	for j in 0 ..< m {
		h[0][j] = 0
		h[1][j] = 0
	}

	score := 0
	i := 1
	j_max := 0
	for ai in a {
		defer i = 1 - i
		j := 1
		for bj in b {
			defer j += 1
			max := 0
			h1 := h[1 - i][j - 1]
			if ai == bj {h1 += match} else {h1 += mismatch}
			if h1 > max {max = h1}

			h2 := h[1 - i][j] + gap
			if h2 > max {max = h2}

			h3 := h[i][j - 1] + gap
			if h3 > max {max = h3}
			h[i][j] = max

			if max > score {
				score = max
				j_max = j
			}
		}
	}
	//fmt.println("j_max =", j_max)
	// for j in 0 ..< m {
	// 	for i in 0 ..< n {
	// 		fmt.printf("% 3d, ", h[i][j])
	// 	}
	// 	fmt.println()
	// }
	return score
}

wordmatch :: proc(phrase: string, elem: string) -> bool {
	ss := strings.split(elem, " ")
	for s in ss {
		if phrase == s {return true}
	}
	return false
}

sm_word :: proc(a: string, b: string) -> int {
	sa := strings.split(a, " ")
	sb := strings.split(b, " ")
	if len(sa) > 2 {return 0}
	n := len(sa) + 1
	m := len(sb) + 1
	if (n == 1) | (m == 1) {return 0}
	h: [2][]int
	h[0] = make([]int, m)
	h[1] = make([]int, m)

	// init
	for j in 0 ..< m {
		h[0][j] = 0
		h[1][j] = 0
	}

	score := 0
	i := 1
	j_max := 0
	for ai in sa {
		defer i = 1 - i
		j := 1
		for bj in sb {
			defer j += 1
			max := 0
			h1 := h[1 - i][j - 1]
			if ai == bj {h1 += match} else {h1 += mismatch}
			if h1 > max {max = h1}

			h2 := h[1 - i][j] + gap
			if h2 > max {max = h2}

			h3 := h[i][j - 1] + gap
			if h3 > max {max = h3}
			h[i][j] = max

			if max > score {
				score = max
				j_max = j
			}
		}
	}
	return score
}

print_score :: proc(a: string, b: string) {
	//assert(sm1(a, b) == sm2(a, b))
	//fmt.printfln("sm1: %v | %v | %v", a, b, sm1(a, b))
	s2 := sm2(a, b)
	//fmt.printfln("sm2: %v | %v | %v", a, b, s2)
	s3 := sm3(a, b)
	//fmt.printfln("sm3: %v | %v | %v", a, b, s3)
	//fmt.printfln("le: %v | %v | %v", a, b, strings.levenshtein_distance(a, b))
	assert(s2 == s3)
	//fmt.printfln("%v | %v | %v", a, b, wordmatch(a, b))
	fmt.printfln("%v | %v | %v", a, b, sm_word(a, b))
}

main :: proc() {
	a := "TGTTACGG"
	b := "GGTTGACTA"

	s1 := sm1(a, b)
	fmt.println("score =", s1)

	s2 := sm2(a, b)
	fmt.println("score =", s2)

	s3 := sm3(a, b)
	fmt.println("score =", s3)

	print_score(
		"heißt",
		"'die' heißt mein unterrock, und 'der' hängt im schrank. [regional] [satz, mit dem kinder gerügt werden, die von einer (anwesenden) frau mit 'die' sprechen]",
	)
	// print_score("gehen", "gehen")
	// print_score("gehen", "gehn")
	// print_score("gehen", "aufgehen")
	// print_score("gehen", "zugehen")
	// print_score("gehen", "nach Hause gehen")
	// print_score("gehen", "über jds. Verstand gehen [Redewendung]")
	// print_score("gehen", "über Leichen gehen")
	// print_score("gehen", "über Leichen gehen [pej.]")
	// print_score("gehen", "über sein Versprechen hinausgehen")
	// print_score("gehen", "übers Wasser gehen")

	print_score("gehen", "gehen")
	print_score("gehen", "gehn")
	print_score("gehen", "aufgehen")
	print_score("gehen", "zugehen")
	print_score("gehen", "nach Hause gehen")
	print_score("gehen", "an Bord gehen")
}
