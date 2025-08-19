// Package utils provides utility functions for the design system, such as text formatting.
package utils

import (
	"fmt"
	"strings"
)

// Bold applies bold formatting to a string.
func Bold(text string) string {
	return fmt.Sprintf("\033[1m%s\033[0m", text)
}

// Italic applies italic formatting to a string.
func Italic(text string) string {
	return fmt.Sprintf("\033[3m%s\033[0m", text)
}

// Underline applies underline formatting to a string.
func Underline(text string) string {
	return fmt.Sprintf("\033[4m%s\033[0m", text)
}

// PadRight pads a string with spaces on the right to reach a desired length.
func PadRight(s string, length int) string {
	if len(s) >= length {
		return s
	}
	return s + strings.Repeat(" ", length-len(s))
}

// PadLeft pads a string with spaces on the left to reach a desired length.
func PadLeft(s string, length int) string {
	if len(s) >= length {
		return s
	}
	return strings.Repeat(" ", length-len(s)) + s
}
