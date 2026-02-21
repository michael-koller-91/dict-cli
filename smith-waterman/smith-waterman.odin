package smith_waterman

import "base:runtime"
import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

match :: 3
mismatch :: -3
gap :: -2

nw_word :: proc(a: string, b: string) -> int {
	// d ← Gap penalty score
	// for i = 0 to length(A)
	//     F(i,0) ← d * i
	// for j = 0 to length(B)
	//     F(0,j) ← d * j
	// for i = 1 to length(A)
	//     for j = 1 to length(B)
	//     {
	//         Match ← F(i−1, j−1) + S(Ai, Bj)
	//         Delete ← F(i−1, j) + d
	//         Insert ← F(i, j−1) + d
	//         F(i,j) ← max(Match, Insert, Delete)
	//     }
	match_score :: 1
	mismatch_score :: 0
	gap_score :: 0

	sa := strings.split(a, " ")
	defer delete(sa)
	sb := strings.split(b, " ")
	defer delete(sb)

	// for now, assume that sb is always at least as long as sa
	if len(sa) > len(sb) {
		sa, sb = sb, sa
	}

	n := len(sa) + 1
	m := len(sb) + 1
	h := make([][]int, n)
	if (n == 1) | (m == 1) {return 0}

	// init
	for i in 0 ..< n {
		h[i] = make([]int, m)
		h[i][0] = gap * i
	}
	for j in 0 ..< m {
		h[0][j] = gap * j
	}

	score := 0
	i := 1
	for ai in sa {
		defer i += 1
		j := 1
		for bj in sb {
			defer j += 1
			match := h[i - 1][j - 1]
			if ai == bj {match += match_score} else {match += mismatch_score}
			delete := h[i - 1][j] + gap_score
			insert := h[i][j - 1] + gap_score
			maximum := max(match, delete)
			h[i][j] = max(maximum, insert)
		}
	}
	return h[n - 1][m - 1]

}

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
			maximum := 0
			h1 := h[i - 1][j - 1] + s(a, i, b, j)
			if h1 > maximum {maximum = h1}
			h2 := h[i - 1][j] + gap
			if h2 > maximum {maximum = h2}
			h3 := h[i][j - 1] + gap
			if h3 > maximum {maximum = h3}
			h[i][j] = maximum
			if maximum > score {score = maximum}
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
			maximum := 0
			h1 := h[i - 1][j - 1]
			if ai == bj {h1 += match} else {h1 += mismatch}
			if h1 > maximum {maximum = h1}
			h2 := h[i - 1][j] + gap
			if h2 > maximum {maximum = h2}
			h3 := h[i][j - 1] + gap
			if h3 > maximum {maximum = h3}
			h[i][j] = maximum
			if maximum > score {score = maximum}
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
	j_maximum := 0
	for ai in a {
		defer i = 1 - i
		j := 1
		for bj in b {
			defer j += 1
			maximum := 0
			h1 := h[1 - i][j - 1]
			if ai == bj {h1 += match} else {h1 += mismatch}
			if h1 > maximum {maximum = h1}

			h2 := h[1 - i][j] + gap
			if h2 > maximum {maximum = h2}

			h3 := h[i][j - 1] + gap
			if h3 > maximum {maximum = h3}
			h[i][j] = maximum

			if maximum > score {
				score = maximum
				j_maximum = j
			}
		}
	}
	//fmt.println("j_maximum =", j_maximum)
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

sm_word :: proc(a: string, b: string) -> i16 {
	match :: 2
	mismatch :: -2
	gap :: -1

	sa := strings.split(a, " ")
	defer delete(sa)
	sb := strings.split(b, " ")
	defer delete(sb)

	// for now, assume that sb is always at least as long as sa
	if len(sa) > len(sb) {
		sa, sb = sb, sa
	}

	n := len(sa) + 1
	m := len(sb) + 1
	if (n == 1) | (m == 1) {return 0}
	h: [2][]i16
	h[0] = make([]i16, m)
	h[1] = make([]i16, m)

	// init
	for j in 0 ..< m {
		h[0][j] = 0
		h[1][j] = 0
	}

	score: i16 = 0
	i := 1
	j_maximum := 0
	for ai in sa {
		defer i = 1 - i
		j := 1
		for bj in sb {
			defer j += 1
			maximum: i16 = 0
			h1 := h[1 - i][j - 1]
			if ai == bj {h1 += match} else {h1 += mismatch}
			if h1 > maximum {maximum = h1}

			h2 := h[1 - i][j] + gap
			if h2 > maximum {maximum = h2}

			h3 := h[i][j - 1] + gap
			if h3 > maximum {maximum = h3}
			h[i][j] = maximum

			if maximum > score {
				score = maximum
				j_maximum = j
			}
		}
	}
	return score //- i16(len(sa)) + 1
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
	fmt.printfln("sm: %v | %v | sm = %v | nw = %v", a, b, sm_word(a, b), nw_word(a, b))
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

	// print_score(
	// 	"heißt",
	// 	"'die' heißt mein unterrock, und 'der' hängt im schrank. [regional] [satz, mit dem kinder gerügt werden, die von einer (anwesenden) frau mit 'die' sprechen]",
	// )
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

	// print_score("gehen", "gehen")
	// print_score("gehen", "gehn")
	// print_score("gehen", "aufgehen")
	// print_score("gehen", "zugehen")
	// print_score("gehen", "nach Hause gehen")
	// print_score("gehen", "gehen gehen")
	// print_score("gehen", "gehen Hause gehen")
	// print_score("gehen gehen", "gehen Hause gehen")
	// print_score("an gehen", "an Bord gehen")
	// print_score("an gehen", "an")
	// print_score("an gehen", "gehen")
	// print_score("Bord gehen", "an Bord gehen")
	// print_score("gehen", "gehen gehen")

	print_score("foo", "fo")
	print_score("foo", "bar")

	print_score("foo", "foo")
	print_score("foo", "foo foo")
	print_score("foo", "foo bar")
	print_score("foo", "bar baz")
	print_score("foo", "foo bar baz")
	print_score("foo", "bar foo bar baz")

	print_score("foo foo", "foo")
	print_score("foo bar", "foo")
	print_score("foo bar", "foo bar")
	print_score("foo bar", "foo bar baz")
	print_score("foo bar", "foo baz bar")

	// words: []string = {"foo", "bar", "baz"}
	// for &word in words {
	// 	hash := runtime.default_hasher_string(&word, 123456)
	// 	fmt.printfln("%v: %v %v", word, hash, size_of(hash))
	// }
}
