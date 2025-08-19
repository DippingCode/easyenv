// Package scaffold provides a basic UI layout structure for the application.
package scaffold

import (
	"github.com/charmbracelet/lipgloss"

	themetemplate "github.com/DippingCode/easyenv/pkg/core/ui/themes/temetemplate"
)

// Widget é uma interface para qualquer componente visual declarativo.
// Qualquer struct que implementa um método View() pode ser um Widget.
type Widget interface {
	View() string
}

// Scaffold é o widget raiz que define o layout básico da tela.
type Scaffold struct {
	Theme themetemplate.ThemeTemplate
	Child Widget
}

// NewScaffold cria um novo Scaffold com um tema e um widget filho.
func NewScaffold(t themetemplate.ThemeTemplate, child Widget) Scaffold {
	return Scaffold{
		Theme: t,
		Child: child,
	}
}

// View renderiza a representação visual do Scaffold, incluindo o filho.
func (s Scaffold) View() string {
	// Define a largura da tela. Vamos usar uma largura fixa por simplicidade.
	// Em um aplicativo real, você usaria lipgloss.Width() ou um valor dinâmico.
	const fullWidth = 80

	// A barra de status, usando o estilo do tema.
	statusBar := lipgloss.NewStyle().
		Background(s.Theme.HeaderStyle.GetBackground()).
		Foreground(s.Theme.HeaderStyle.GetForeground()).
		Width(fullWidth).
		Padding(0, 2).
		Render("Status Bar: OK")

	// O corpo principal, que contém o widget filho.
	// A magia da composição acontece aqui.
	body := lipgloss.NewStyle().
		Width(fullWidth).
		Render(s.Child.View())

	// Usa JoinVertical para montar o layout final.
	return lipgloss.JoinVertical(lipgloss.Top, body, statusBar)
}
