// Package themetemplate defines the structure for UI themes.
package themetemplate

import "github.com/charmbracelet/lipgloss"

// ThemeTemplate define a estrutura para um tema de UI, incluindo cores e estilos.
type ThemeTemplate struct {
	// --- Cores da Paleta ---
	PrimaryColor   lipgloss.Color
	SecondaryColor lipgloss.Color
	SuccessColor   lipgloss.Color
	ErrorColor     lipgloss.Color
	WarningColor   lipgloss.Color
	InfoColor      lipgloss.Color

	// Cores de fundo e primeiro plano
	BackgroundColor lipgloss.Color
	ForegroundColor lipgloss.Color
	HighlightColor  lipgloss.Color // Cor de fundo para destaques (ex: item de menu selecionado)

	// --- Estilos de Texto ---
	BaseStyle      lipgloss.Style
	TitleStyle     lipgloss.Style
	HeaderStyle    lipgloss.Style
	HighlightStyle lipgloss.Style
	ListItemStyle  lipgloss.Style
	CodeStyle      lipgloss.Style

	// --- Estilos de Status ---
	SuccessStyle lipgloss.Style
	ErrorStyle   lipgloss.Style
	WarningStyle lipgloss.Style
	InfoStyle    lipgloss.Style

	// --- Estilos de UI ---
	ProgressBar lipgloss.Style
	Border      lipgloss.Border
	BorderColor lipgloss.Color
}
