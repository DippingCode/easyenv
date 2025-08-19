// Package themepreference provides the UI logic and Cobra command definitions for user preferences.
package themepreference

import (
	"fmt"
	"log"
	"os"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"

	"github.com/DippingCode/easyenv/pkg/core/ui/help"
	"github.com/DippingCode/easyenv/pkg/core/ui/themes"
	"github.com/DippingCode/easyenv/pkg/modules/preferences/domain/usecases"
)

// ShowHelp é uma função utilitária para exibir o help do command preferences.
func ShowHelp(cmd *cobra.Command) {
	currentTheme := themes.Dark()
	p := tea.NewProgram(help.NewModel(helpData, currentTheme))
	if _, err := p.Run(); err != nil {
		fmt.Printf("Ocorreu um erro ao exibir a ajuda: %v", err)
		os.Exit(1)
	}
}

// item representa um item de menu
type item struct {
	title, desc, value string
}

// Title retorna o título do item de menu.
func (i item) Title() string       { return i.title }
// Description retorna a descrição do item de menu.
func (i item) Description() string { return i.desc }
// FilterValue retorna o valor de filtro do item de menu.
func (i item) FilterValue() string { return i.title }

// menuModel para o menu de temas
type menuModel struct {
	list     list.Model
	usecase  *usecases.PreferencesUsecase
	quitting bool
}

// Init inicializa o modelo do menu.
func (m menuModel) Init() tea.Cmd {
	return nil
}

// Update lida com as mensagens e atualiza o modelo do menu.
func (m menuModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.String() == "ctrl+c" {
			m.quitting = true
			return m, tea.Quit
		}
		if msg.String() == "enter" {
			if selected := m.list.SelectedItem(); selected != nil {
				selectedItem := selected.(item)
				if selectedItem.value != "" {
					err := m.usecase.UpdateTheme(selectedItem.value)
					if err != nil {
						log.Printf("Erro ao salvar o tema: %v", err)
						// Exibir erro na UI
					} else {
						log.Println("Tema salvo com sucesso!")
						// Exibir mensagem de sucesso
					}
					m.quitting = true
					return m, tea.Quit
				}
			}
		}
	}
	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

// View renderiza a visualização do menu.
func (m menuModel) View() string {
	if m.quitting {
		return ""
	}
	return m.list.View()
}

// ShowThemeMenu exibe o menu interativo para seleção de tema.
func ShowThemeMenu(usecase *usecases.PreferencesUsecase) {
	items := []list.Item{
		item{title: "Tema Escuro (Padrão)", desc: "Aplica o tema escuro padrão.", value: "dark"},
		item{title: "Tema Claro", desc: "Aplica o tema claro.", value: "light"},
		item{title: "Resetar", desc: "Remove a preferência de tema, usando o padrão do sistema.", value: "default"},
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Selecione um tema para o CLI"
	l.SetSize(40, 10)

	m := menuModel{list: l, usecase: usecase}
	if _, err := tea.NewProgram(m).Run(); err != nil {
		fmt.Println("Erro ao exibir o menu de temas:", err)
		os.Exit(1)
	}
}

// ShowError exibe uma mensagem de erro formatada.
func ShowError(message string, err error) {
	// A lógica de formatação do tema será adicionada aqui.
	fmt.Printf("❌ %s: %v\n", message, err)
}

// ShowSuccess exibe uma mensagem de sucesso formatada.
func ShowSuccess(message string) {
	// A lógica de formatação do tema será adicionada aqui.
	fmt.Printf("✅ %s\n", message)
}
