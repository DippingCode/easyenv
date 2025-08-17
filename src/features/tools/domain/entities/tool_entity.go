// Package entities representa os objetos de negócio
package entities

type Tool struct {
	Name        string `yaml:"name"`
	Section     string `yaml:"section"`
	Type        string `yaml:"type"`
	Description string `yaml:"description"`
	Homepage    string `yaml:"homepage"`
	// Campos adicionais (brew/install/etc.) podem ser adicionados depois
}