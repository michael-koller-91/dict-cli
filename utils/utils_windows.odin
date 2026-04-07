package main

import "core:c"
import "core:sys/windows"

/*
Syscall to get the terminal height and width.
*/
get_terminal_size :: proc() -> (height, width: uint) {
	sbi: windows.CONSOLE_SCREEN_BUFFER_INFO

	if !windows.GetConsoleScreenBufferInfo(windows.HANDLE(os.fd(os.stdout)), &sbi) {
		panic("Failed to get terminal size")
	}

	height = uint(sbi.srWindow.Bottom - sbi.srWindow.Top) + 1
	width = uint(sbi.srWindow.Right - sbi.srWindow.Left) + 1

	return
}
