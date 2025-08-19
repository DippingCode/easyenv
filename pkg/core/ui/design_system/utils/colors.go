// Package utils provides utility functions for the design system, such as color manipulation.
package utils

// ANSI escape codes for colors
const (
	Reset  = "\033[0m"
	Black  = "\033[30m"
	Red    = "\033[31m"
	Green  = "\033[32m"
	Yellow = "\033[33m"
	Blue   = "\033[34m"
	Purple = "\033[35m"
	Cyan   = "\033[36m"
	White  = "\033[37m"

	BrightBlack  = "\033[90m"
	BrightRed    = "\033[91m"
	BrightGreen  = "\033[92m"
	BrightYellow = "\033[93m"
	BrightBlue   = "\033[94m"
	BrightPurple = "\033[95m"
	BrightCyan   = "\033[96m"
	BrightWhite  = "\033[97m"

	BgBlack  = "\033[40m"
	BgRed    = "\033[41m"
	BgGreen  = "\033[42m"
	BgYellow = "\033[43m"
	BgBlue   = "\033[44m"
	BgPurple = "\033[45m"
	BgCyan   = "\033[46m"
	BgWhite  = "\033[47m"
)

// Colorize applies a foreground color to a string.
func Colorize(text, color string) string {
	return color + text + Reset
}

// BackgroundColorize applies a background color to a string.
func BackgroundColorize(text, bgColor string) string {
	return bgColor + text + Reset
}
