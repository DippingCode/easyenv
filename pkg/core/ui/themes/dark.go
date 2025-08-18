// Package themes
package themes

import (
	themetemplate "github.com/DippingCode/easyenv/pkg/core/ui/themes/temetemplate"
	"github.com/charmbracelet/lipgloss"
)

func Dark() themetemplate.ThemeTemplate {
	// Definição das cores para o tema escuro.
	const (
		googleBlue    = lipgloss.Color("#4285F4")
		googleYellow  = lipgloss.Color("#F4B400")
		googleGreen   = lipgloss.Color("#0F9D58")
		googleRed     = lipgloss.Color("#DB4437")
		geminiBG      = lipgloss.Color("#0B0C0E")
		geminiFG      = lipgloss.Color("#E0E0E0")
		geminiAccent  = lipgloss.Color("#565656")
		geminiHighlightBG = lipgloss.Color("#252525")
	)

	t := themetemplate.ThemeTemplate{
		// Cores da paleta principal
		PrimaryColor:   googleBlue,
		SecondaryColor: googleYellow,
		SuccessColor:   googleGreen,
		ErrorColor:     googleRed,
		WarningColor:   googleYellow,
		InfoColor:      googleBlue,

		// Cores de fundo e primeiro plano
		BackgroundColor: geminiBG,
		ForegroundColor: geminiFG,
		HighlightColor:  geminiHighlightBG,

		// Estilos de texto
		BaseStyle:      lipgloss.NewStyle().Foreground(geminiFG).Background(geminiBG),
		TitleStyle:     lipgloss.NewStyle().Bold(true).Foreground(googleBlue),
		HeaderStyle:    lipgloss.NewStyle().Bold(true).Foreground(googleYellow).Border(lipgloss.NormalBorder(), false, false, true, false),
		HighlightStyle: lipgloss.NewStyle().Background(geminiHighlightBG).Foreground(geminiFG),
		ListItemStyle:  lipgloss.NewStyle().Foreground(geminiFG).PaddingLeft(2),
		CodeStyle:      lipgloss.NewStyle().Foreground(lipgloss.Color("#D8BFD8")).Background(geminiAccent).Padding(0, 1),
	}

	// Estilos derivados
	t.SuccessStyle = lipgloss.NewStyle().Foreground(t.SuccessColor).Bold(true)
	t.ErrorStyle = lipgloss.NewStyle().Foreground(t.ErrorColor).Bold(true)
	t.WarningStyle = lipgloss.NewStyle().Foreground(t.WarningColor).Bold(true)
	t.InfoStyle = lipgloss.NewStyle().Foreground(t.InfoColor).Bold(true)

	// Estilos de UI
	t.ProgressBar = lipgloss.NewStyle().Foreground(t.PrimaryColor).Background(lipgloss.Color("#444444"))
	t.Border = lipgloss.RoundedBorder()
	t.BorderColor = lipgloss.Color("#555555")

	return t
}