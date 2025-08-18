// Package interactiveshell
package interactiveshell

import (
	"fmt"
	"strings"

	themetemplate "github.com/DippingCode/easyenv/pkg/core/ui/themes/temetemplate"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Msg representa uma mensagem genérica para o loop de Bubble Tea.
type Msg string

const banner = `
 ██████████                              ██████████                                 
░░███░░░░░█                             ░░███░░░░░█                                 
 ░███  █ ░   ██████    █████  █████ ████ ░███  █ ░  ████████   █████ █████          
 ░██████    ░░░░░███  ███░░  ░░███ ░███  ░██████   ░░███░░███ ░░███ ░░███           
 ░███░░█     ███████ ░░█████  ░███ ░███  ░███░░█    ░███ ░███  ░███  ░███           
 ░███ ░   █ ███░░███  ░░░░███ ░███ ░███  ░███ ░   █ ░███ ░███  ░░███ ███            
 ██████████░░████████ ██████  ░░███████  ██████████ ████ █████  ░░█████    █████████
░░░░░░░░░░  ░░░░░░░░ ░░░░░░    ░░░░░███ ░░░░░░░░░░ ░░░░ ░░░░░    ░░░░░    ░░░░░░░░░ 
                               ███ ░███                                             
                              ░░██████                                              
                               ░░░░░░                                               
`

// welcomeMessage provides tips for getting started.
const welcomeMessage = `
Tips for getting started:
1. Ask questions, edit files, or run commands.
2. Type 'help' for more information.
3. Type 'exit' to quit.
`

// model representa o estado do shell interativo.
type model struct {
	prompt         string
	history        []string
	input          string
	initialCommand string
	theme          themetemplate.ThemeTemplate
}

// New cria uma nova instância do modelo.
func New(initialCommand string, currentTheme themetemplate.ThemeTemplate) tea.Model {
	return model{
		prompt:         "eye> ",
		history:        []string{},
		input:          "",
		initialCommand: initialCommand,
		theme:          currentTheme, 
	}
}

// Init inicializa a sessão interativa.
func (m model) Init() tea.Cmd {
	if m.initialCommand != "" {
		return func() tea.Msg {
			return Msg(m.initialCommand)
		}
	}
	return nil
}

// Update processa as mensagens (eventos) do loop.
func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case Msg:
		command := string(msg)
		m.history = append(m.history, fmt.Sprintf("%s%s", m.prompt, command))
		
		output := processCommand(command)
		m.history = append(m.history, output)

		m.input = ""
		return m, nil

	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			return m, tea.Quit
		case tea.KeyEnter:
			command := strings.TrimSpace(m.input)
			m.history = append(m.history, fmt.Sprintf("%s%s", m.prompt, command))

			if command == "exit" {
				return m, tea.Quit
			}

			output := processCommand(command)
			m.history = append(m.history, output)

			m.input = ""
			return m, nil
		case tea.KeyBackspace:
			if len(m.input) > 0 {
				m.input = m.input[:len(m.input)-1]
			}
		default:
			m.input += msg.String()
		}
	}
	return m, nil
}

// View renderiza a interface no terminal.
func (m model) View() string {
	var s strings.Builder

	// Renderiza o banner com a cor do tema.
	s.WriteString(m.theme.TitleStyle.Render(banner))
	s.WriteString("\n")

	// Renderiza a mensagem de boas-vindas.
	s.WriteString(m.theme.BaseStyle.Render(welcomeMessage))
	s.WriteString("\n")

	// Renderiza o histórico de comandos e saídas.
	for _, line := range m.history {
		s.WriteString(line)
		s.WriteString("\n")
	}

	// Renderiza o campo de entrada do usuário com a borda.
	inputStyle := lipgloss.NewStyle().
		Border(lipgloss.NormalBorder(), true).
		BorderForeground(m.theme.PrimaryColor).
		Padding(0, 1)

	// O prompt e o input são renderizados dentro do campo de entrada.
	inputContent := m.theme.BaseStyle.Render(m.prompt) + m.theme.BaseStyle.Render(m.input)
	
	// Ajusta a largura para que o input se encaixe bem na tela.
	width := lipgloss.Width(m.theme.TitleStyle.Render(banner))
	if width < 80 {
		width = 80 // Largura mínima
	}

	s.WriteString(lipgloss.NewStyle().Width(width).Render(inputStyle.Render(inputContent)))
	s.WriteString("\n")

	// Renderiza a barra de status.
	statusBar := lipgloss.NewStyle().
		Background(m.theme.HeaderStyle.GetBackground()).
		Foreground(m.theme.HeaderStyle.GetForeground()).
		Width(width).
		Padding(0, 2).
		Render(fmt.Sprintf("Using: easyenv.io | Current path: %s", "/home/user"))

	s.WriteString(statusBar)

	return s.String()
}

// processCommand é um placeholder para a lógica do roteador.
func processCommand(cmd string) string {
	if cmd == "" {
		return ""
	}
	return "Comando processado: " + cmd
}

// Run é o ponto de entrada principal para o shell interativo.
func Run(args []string, currentTheme themetemplate.ThemeTemplate) error {
    initialCommand := strings.Join(args, " ")
	p := tea.NewProgram(New(initialCommand, currentTheme))
	if _, err := p.Run(); err != nil {
		return err
	}
	return nil
}