// Package view contém os componentes de apresentação para a feature de version,
// responsável por renderizar a saída de versão no CLI.
package view

import (
	"fmt"
	"os"

	"github.com/DippingCode/easyenv/src/core/config"
	"gopkg.in/yaml.v3"
)

type devLog struct {
	Tasks []struct {
		Version string   `yaml:"version"`
		Build   string   `yaml:"build"`
		Summary []string `yaml:"summary"`
		Notes   []string `yaml:"notes"`
		Next    []string `yaml:"next_steps"`
	} `yaml:"tasks"`
}

func VersionView(detailed bool) {
	paths, err := config.ResolvePaths()
	if err != nil {
		fmt.Println("easyenv v0.0.0")
		return
	}
	raw, err := os.ReadFile(paths.DevLogYAML)
	if err != nil {
		fmt.Println("easyenv v0.0.0")
		return
	}
	var dl devLog
	if err := yaml.Unmarshal(raw, &dl); err != nil || len(dl.Tasks) == 0 {
		fmt.Println("easyenv v0.0.0")
		return
	}

	latest := dl.Tasks[0]
	v := latest.Version
	if v == "" {
		v = "0.0.0"
	}
	b := latest.Build
	if b == "" {
		b = "0"
	}

	if !detailed {
		fmt.Printf("easyenv v%s (build %s)\n", v, b)
		return
	}

	fmt.Printf("easyenv v%s (build %s)\n\n", v, b)
	if len(latest.Summary) > 0 {
		fmt.Println("• Summary:")
		for _, s := range latest.Summary {
			fmt.Printf("  - %s\n", s)
		}
	}
	if len(latest.Notes) > 0 {
		fmt.Println("\n• Notes:")
		for _, n := range latest.Notes {
			fmt.Printf("  - %s\n", n)
		}
	}
	if len(latest.Next) > 0 {
		fmt.Println("\n• Next steps:")
		for _, n := range latest.Next {
			fmt.Printf("  - %s\n", n)
		}
	}
}