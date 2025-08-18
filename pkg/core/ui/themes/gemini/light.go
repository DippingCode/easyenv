// Package gemini
package gemini

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/themes"
	"github.com/charmbracelet/lipgloss"
)

func LightTheme() themes.Theme {
	// Definição das cores para o tema claro.
	const (
		primaryLight    = lipgloss.Color("#1A73E8")
		secondaryLight  = lipgloss.Color("#D48F00")
		successLight    = lipgloss.Color("#007B57")
		errorLight      = lipgloss.Color("#C53929")
		warningLight    = lipgloss.Color("#D48F00")
		infoLight       = lipgloss.Color("#1A73E8")
		bgLight         = lipgloss.Color("#FFFFFF")
		fgLight         = lipgloss.Color("#333333")
		highlightLightBG= lipgloss.Color("#F0F0F0")
	)

	t := themes.Theme{
		// Cores da paleta principal
		PrimaryColor:   primaryLight,
		SecondaryColor: secondaryLight,
		SuccessColor:   successLight,
		ErrorColor:     errorLight,
		WarningColor:   warningLight,
		InfoColor:      infoLight,

		// Cores de fundo e primeiro plano
		BackgroundColor: bgLight,
		ForegroundColor: fgLight,
		HighlightColor:  highlightLightBG,

		// Estilos de texto
		BaseStyle:      lipgloss.NewStyle().Foreground(fgLight).Background(bgLight),
		TitleStyle:     lipgloss.NewStyle().Bold(true).Foreground(primaryLight),
		HeaderStyle:    lipgloss.NewStyle().Bold(true).Foreground(secondaryLight).Border(lipgloss.NormalBorder(), false, false, true, false),
		HighlightStyle: lipgloss.NewStyle().Background(highlightLightBG).Foreground(fgLight),
		ListItemStyle:  lipgloss.NewStyle().Foreground(lipgloss.Color("#666666")).PaddingLeft(2),
		CodeStyle:      lipgloss.NewStyle().Foreground(lipgloss.Color("#663399")).Background(lipgloss.Color("#F0F0F0")).Padding(0, 1),
	}

	// Estilos derivados
	t.SuccessStyle = lipgloss.NewStyle().Foreground(t.SuccessColor).Bold(true)
	t.ErrorStyle = lipgloss.NewStyle().Foreground(t.ErrorColor).Bold(true)
	t.WarningStyle = lipgloss.NewStyle().Foreground(t.WarningColor).Bold(true)
	t.InfoStyle = lipgloss.NewStyle().Foreground(t.InfoColor).Bold(true)

	// Estilos de UI
	t.ProgressBar = lipgloss.NewStyle().Foreground(t.PrimaryColor).Background(lipgloss.Color("#D9D9D9"))
	t.Border = lipgloss.RoundedBorder()
	t.BorderColor = lipgloss.Color("#BBBBBB")

	return t
}