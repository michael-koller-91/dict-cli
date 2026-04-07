package utils

import "core:c"
import "core:sys/darwin"

/*
Syscall to get the terminal height and width.
*/
get_terminal_size :: proc() -> (height, width: uint) {
	winsize :: struct {
		ws_row, ws_col:       c.ushort,
		ws_xpixel, ws_ypixel: c.ushort,
	}

	w: winsize
	if darwin.syscall_ioctl(1, darwin.TIOCGWINSZ, &w) != 0 {
		panic("Failed to get terminal size")
	}

	height = uint(w.ws_row)
	width = uint(w.ws_col)

	return
}
