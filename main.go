package main

import (
	"os"

	"github.com/DippingCode/easyenv/features"
)

func main() {
	if len(os.Args) < 2 {
		println("Uso: easyenv <feature> <comando>")
		return
	}

	feature := os.Args[1]
	command := ""
	if len(os.Args) > 2 {
		command = os.Args[2]
	}

	features.Route(feature, command)
}