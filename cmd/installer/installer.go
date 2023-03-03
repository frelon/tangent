package main

import (
	"fmt"
	"os"
	"os/exec"

	tea "github.com/charmbracelet/bubbletea"
	"gopkg.in/yaml.v3"
)

type installerFinishedMsg struct{ err error }

type model struct {
	choices []string
	cursor  int
}

type LsblkOutput struct {
	BlockDevices []BlockDevice `yaml:"blockdevices"`
}

type BlockDevice struct {
	Name string `yaml:"name"`
	Type string `yaml:"type"`
	Size string `yaml:"size"`
}

func initialModel() model {
	choices := []string{}

	cmd := exec.Command("lsblk", "-J")
	bytes, err := cmd.Output()
	if err != nil {
		fmt.Printf("Error listing block devices: %v\n", err.Error())
		return model{choices: choices}
	}

	var output LsblkOutput
	err = yaml.Unmarshal(bytes, &output)

	for _, dev := range output.BlockDevices {
		if dev.Type == "disk" {
			choices = append(choices, fmt.Sprintf("/dev/%v", dev.Name))
		}
	}

	return model{
		choices: choices,
	}
}

func (m model) Init() tea.Cmd {
	return tea.EnterAltScreen
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {

	case installerFinishedMsg:

		return m, tea.Quit

	case tea.KeyMsg:

		switch msg.String() {

		case "ctrl+c", "q":
			return m, tea.Quit

		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}

		case "down", "j":
			if m.cursor < len(m.choices)-1 {
				m.cursor++
			}

		case "enter":
			target := m.choices[m.cursor]

			elemental := exec.Command("elemental", "install", target, "--reboot")
			return m, tea.ExecProcess(elemental, func(err error) tea.Msg {
				return installerFinishedMsg{err}
			})
		}
	}

	return m, nil
}

func (m model) View() string {
	s := "Select installation target:\n\n"

	for i, choice := range m.choices {

		cursor := " "
		if m.cursor == i {
			cursor = ">"
		}

		s += fmt.Sprintf("%s %s\n", cursor, choice)
	}

	s += "\nPress enter to install, q to quit.\n"

	return s
}

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Alas, there's been an error: %v", err)
		os.Exit(1)
	}
}
