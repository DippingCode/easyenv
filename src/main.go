package main

import (
	"os"

	"github.com/DippingCode/easyenv/src/features"
)

func main() {
	features.Dispatch(os.Args[1:])
}