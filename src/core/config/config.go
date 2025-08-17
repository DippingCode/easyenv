package config

import (
	"fmt"
	"os"
	"path/filepath"
)

type Paths struct {
	HomeDir    string
	ConfigDir  string
	ToolsYAML  string
	DevLogYAML string
}

func ResolvePaths() (*Paths, error) {
	home := os.Getenv("EASYENV_HOME")
	if home == "" {
		wd, err := os.Getwd()
		if err != nil {
			return nil, fmt.Errorf("getwd: %w", err)
		}
		home = wd
	}
	cfg := filepath.Join(home, "config")
	return &Paths{
		HomeDir:    home,
		ConfigDir:  cfg,
		ToolsYAML:  filepath.Join(cfg, "tools.yml"),
		DevLogYAML: filepath.Join(home, "dev_log.yml"),
	}, nil
}