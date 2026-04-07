package utils

import "core:c"
import "core:sys/linux"

/*
Syscall to get the terminal height and width.
*/
get_terminal_size :: proc() -> (height, width: uint) {
	winsize :: struct {
		ws_row, ws_col:       c.ushort,
		ws_xpixel, ws_ypixel: c.ushort,
	}

	w: winsize
	if linux.ioctl(linux.STDOUT_FILENO, linux.TIOCGWINSZ, cast(uintptr)&w) != 0 {
		panic("Failed to get terminal size")
	}

	height = uint(w.ws_row)
	width = uint(w.ws_col)

	return
}
