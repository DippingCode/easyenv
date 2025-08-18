//Package themes
package themes

import "github.com/charmbracelet/lipgloss"

// Theme é a estrutura que armazena todos os estilos e cores do tema do CLI.
// Ela atua como um contrato para qualquer implementação de tema.
type Theme struct {
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
	ProgressBar  lipgloss.Style
	Border       lipgloss.Border
	BorderColor  lipgloss.Color
}