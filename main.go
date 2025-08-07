package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#7C3AED")).
			MarginLeft(2).
			MarginBottom(1)

	selectedStyle = lipgloss.NewStyle().
			Background(lipgloss.Color("#7C3AED")).
			Foreground(lipgloss.Color("#FFFFFF")).
			Padding(0, 1)

	unselectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#A1A1AA")).
			Padding(0, 1)

	categoryStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#10B981")).
			MarginLeft(1).
			MarginTop(1)

	descriptionStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#6B7280")).
				MarginLeft(3)

	progressStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#3B82F6")).
			Bold(true)

	errorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#EF4444")).
			Bold(true)

	successStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#10B981")).
			Bold(true)

	warningStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#F59E0B")).
			Bold(true)
)

type InstallStep struct {
	Name        string
	Description string
	Function    string
	Selected    bool
	Required    bool
}

type Category struct {
	Name  string
	Steps []InstallStep
}

type model struct {
	categories          []Category
	currentCategory     int
	currentStep         int
	installing          bool
	installProgress     string
	currentStepName     string
	installComplete     bool
	errors              []string
	warnings            []string
	selectedSteps       map[string]bool
	installationStarted bool
}

func initialModel() model {
	categories := []Category{
		{
			Name: "Graphics Drivers",
			Steps: []InstallStep{
				{Name: "NVIDIA Drivers", Description: "Install NVIDIA drivers (will prompt for DKMS, Open, or Nouveau options)", Function: "configure_nvidia", Selected: false, Required: false},
				{Name: "AMD Drivers", Description: "Install AMD open-source drivers with Vulkan support", Function: "configure_amd", Selected: false, Required: false},
				{Name: "Intel Drivers", Description: "Install Intel integrated graphics drivers with Vulkan support", Function: "configure_intel", Selected: false, Required: false},
			},
		},
		{
			Name: "Development Tools",
			Steps: []InstallStep{
				{Name: "Visual Studio Code", Description: "Microsoft's popular code editor", Function: "install_vscode", Selected: true, Required: false},
				{Name: "Neovim", Description: "Modern Vim-based text editor (included in core)", Function: "install_neovim", Selected: true, Required: false},
				{Name: "Git", Description: "Version control system (included in core)", Function: "install_git", Selected: true, Required: false},
				{Name: "Docker", Description: "Containerization platform", Function: "install_docker", Selected: false, Required: false},
				{Name: "Node.js", Description: "JavaScript runtime and npm", Function: "install_node", Selected: true, Required: false},
				{Name: "MongoDB", Description: "NoSQL database", Function: "install_mongodb", Selected: false, Required: false},
			},
		},
		{
			Name: "Web Browsers",
			Steps: []InstallStep{
				{Name: "Zen Browser", Description: "Privacy-focused Firefox-based browser", Function: "install_zen", Selected: true, Required: false},
				{Name: "Firefox", Description: "Mozilla's web browser", Function: "install_firefox", Selected: false, Required: false},
				{Name: "Chromium", Description: "Open-source web browser", Function: "install_chromium", Selected: false, Required: false},
			},
		},
		{
			Name: "Communication",
			Steps: []InstallStep{
				{Name: "Discord (Vesktop)", Description: "Discord client with better Wayland support", Function: "install_vesktop", Selected: true, Required: false},
				{Name: "Telegram", Description: "Cross-platform messaging app", Function: "install_telegram", Selected: false, Required: false},
				{Name: "Signal", Description: "Privacy-focused messaging app", Function: "install_signal", Selected: false, Required: false},
			},
		},
		{
			Name: "Media & Entertainment",
			Steps: []InstallStep{
				{Name: "Spotify (Spotube)", Description: "Open-source Spotify client", Function: "install_spotube", Selected: true, Required: false},
				{Name: "VLC", Description: "Versatile media player", Function: "install_vlc", Selected: false, Required: false},
				{Name: "GIMP", Description: "GNU Image Manipulation Program", Function: "install_gimp", Selected: false, Required: false},
				{Name: "Pinta", Description: "Simple drawing and image editing", Function: "install_pinta", Selected: true, Required: false},
				{Name: "OBS Studio", Description: "Open-source streaming and recording software", Function: "install_obs", Selected: false, Required: false},
			},
		},
		{
			Name: "Office & Productivity",
			Steps: []InstallStep{
				{Name: "LibreOffice", Description: "Full-featured office suite", Function: "install_libreoffice", Selected: false, Required: false},
				{Name: "Thunderbird", Description: "Email client from Mozilla", Function: "install_thunderbird", Selected: false, Required: false},
			},
		},
		{
			Name: "Gaming",
			Steps: []InstallStep{
				{Name: "Steam", Description: "Gaming platform with library management", Function: "install_steam", Selected: false, Required: false},
			},
		},
		{
			Name: "Virtualization",
			Steps: []InstallStep{
				{Name: "QEMU/KVM", Description: "Complete virtualization stack with virt-manager GUI", Function: "install_qemu_kvm", Selected: false, Required: false},
				{Name: "VirtualBox", Description: "Oracle VirtualBox with host modules", Function: "install_virtualbox", Selected: false, Required: false},
				{Name: "VMware Tools", Description: "Open-source VMware tools and utilities", Function: "install_vmware_tools", Selected: false, Required: false},
				{Name: "Container Runtimes", Description: "Podman, Buildah, and rootless containers", Function: "install_container_runtimes", Selected: false, Required: false},
				{Name: "Virtualization Dev Tools", Description: "Vagrant, Packer, Terraform, Ansible", Function: "install_virt_dev_tools", Selected: false, Required: false},
				{Name: "Wine", Description: "Windows application compatibility layer", Function: "install_wine", Selected: false, Required: false},
				{Name: "Check Virtualization Support", Description: "Verify hardware virtualization capabilities", Function: "check_virtualization_support", Selected: true, Required: false},
			},
		},
		{
			Name: "Terminal Applications",
			Steps: []InstallStep{
				{Name: "Terminal Emulator (Kitty)", Description: "Modern terminal emulator with GPU acceleration", Function: "install_terminal_emulator", Selected: true, Required: false},
				{Name: "System Monitor (btop)", Description: "Resource monitor with modern interface", Function: "install_system_monitor", Selected: true, Required: false},
				{Name: "bat", Description: "Better version of cat with syntax highlighting", Function: "install_bat", Selected: true, Required: false},
				{Name: "Fastfetch", Description: "System information display tool", Function: "install_fastfetch_app", Selected: true, Required: false},
				{Name: "tldr", Description: "Simplified man pages with examples", Function: "install_tldr", Selected: true, Required: false},
				{Name: "onefetch", Description: "Git repository information tool", Function: "install_onefetch", Selected: true, Required: false},
			},
		},
		{
			Name: "File Managers",
			Steps: []InstallStep{
				{Name: "Nautilus", Description: "GNOME file manager with extensions", Function: "install_nautilus", Selected: true, Required: false},
				{Name: "Superfile", Description: "Modern terminal-based file manager", Function: "install_superfile", Selected: false, Required: false},
			},
		},
		{
			Name: "System Applications",
			Steps: []InstallStep{
				{Name: "Calculator", Description: "GNOME calculator application", Function: "install_calculator", Selected: true, Required: false},
				{Name: "Software Center (Discover)", Description: "KDE application for managing software", Function: "install_discover", Selected: false, Required: false},
				{Name: "Bluetooth Manager (Blueman)", Description: "Graphical Bluetooth device manager", Function: "install_blueman", Selected: true, Required: false},
				{Name: "Text Editor (Neovim)", Description: "Modern Vim-based text editor", Function: "install_neovim_app", Selected: true, Required: false},
			},
		},
		{
			Name: "Entertainment",
			Steps: []InstallStep{
				{Name: "cmatrix", Description: "Terminal Matrix effect screensaver", Function: "install_cmatrix", Selected: false, Required: false},
				{Name: "cbonsai", Description: "ASCII art bonsai tree generator", Function: "install_cbonsai", Selected: false, Required: false},
				{Name: "pipes-rs", Description: "Terminal screensaver with animated pipes", Function: "install_pipes_rs", Selected: false, Required: false},
				{Name: "astroterm", Description: "Terminal-based astronomy application", Function: "install_astroterm", Selected: false, Required: false},
			},
		},
		{
			Name: "System Configuration",
			Steps: []InstallStep{
				{Name: "Core Packages", Description: "Essential system packages and dependencies", Function: "install_packages", Selected: true, Required: true},
				{Name: "AUR Helper (paru)", Description: "Install paru AUR helper only", Function: "install_aur_helper", Selected: true, Required: true},
				{Name: "Hyprland WM", Description: "Wayland compositor and window manager", Function: "install_hyprland_wm", Selected: true, Required: false},
				{Name: "Desktop Portals", Description: "XDG desktop portals for app integration", Function: "install_desktop_portals", Selected: true, Required: false},
				{Name: "SDDM Login Manager", Description: "Display manager with themes", Function: "install_display_manager", Selected: true, Required: false},
				{Name: "Security Tools", Description: "Keyring and credential management", Function: "install_security_tools", Selected: true, Required: false},
				{Name: "Terminal Tools", Description: "Shell utilities and modern CLI tools", Function: "install_terminal_tools", Selected: true, Required: false},
				{Name: "Network Tools", Description: "Network utilities and connection management", Function: "install_network_tools", Selected: true, Required: false},
				{Name: "File Manager Tools", Description: "System file management utilities", Function: "install_file_manager", Selected: true, Required: false},
				{Name: "Multimedia Base", Description: "Audio/video control and image processing", Function: "install_multimedia_base", Selected: true, Required: false},
				{Name: "Bluetooth Support", Description: "Core Bluetooth utilities", Function: "install_bluetooth", Selected: true, Required: false},
				{Name: "Theming Support", Description: "Icons, themes, and appearance tools", Function: "install_theming", Selected: true, Required: false},
				{Name: "Software Management", Description: "Flatpak support", Function: "install_software_management", Selected: false, Required: false},
				{Name: "Fonts", Description: "Essential and programming fonts", Function: "install_fonts", Selected: true, Required: false},
				{Name: "Zsh Shell", Description: "Z shell with plugins and configuration", Function: "setup_zsh", Selected: true, Required: false},
				{Name: "Wallpapers", Description: "Setup wallpapers and themes", Function: "setup_wallpapers", Selected: true, Required: false},
				{Name: "Fastfetch", Description: "System information display tool", Function: "setup_fastfetch", Selected: true, Required: false},
				{Name: "Dotfiles", Description: "Copy configuration files", Function: "copy_dotfiles", Selected: true, Required: true},
			},
		},
	}

	selectedSteps := make(map[string]bool)
	for _, category := range categories {
		for _, step := range category.Steps {
			selectedSteps[step.Function] = step.Selected
		}
	}

	return model{
		categories:      categories,
		currentCategory: 0,
		currentStep:     0,
		selectedSteps:   selectedSteps,
	}
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.installing {
			if msg.String() == "q" || msg.String() == "ctrl+c" {
				return m, tea.Quit
			}
			return m, nil
		}

		if m.installComplete {
			return m, tea.Quit
		}

		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "up", "k":
			if m.currentStep > 0 {
				m.currentStep--
			} else if m.currentCategory > 0 {
				m.currentCategory--
				m.currentStep = len(m.categories[m.currentCategory].Steps) - 1
			}
		case "down", "j":
			if m.currentStep < len(m.categories[m.currentCategory].Steps)-1 {
				m.currentStep++
			} else if m.currentCategory < len(m.categories)-1 {
				m.currentCategory++
				m.currentStep = 0
			}
		case "left", "h":
			if m.currentCategory > 0 {
				m.currentCategory--
				m.currentStep = 0
			}
		case "right", "l":
			if m.currentCategory < len(m.categories)-1 {
				m.currentCategory++
				m.currentStep = 0
			}
		case "space", " ":
			currentStep := m.categories[m.currentCategory].Steps[m.currentStep]
			if !currentStep.Required {
				m.selectedSteps[currentStep.Function] = !m.selectedSteps[currentStep.Function]
				m.categories[m.currentCategory].Steps[m.currentStep].Selected = m.selectedSteps[currentStep.Function]
			}
		case "enter":
			if !m.installationStarted {
				m.installing = true
				m.installationStarted = true
				return m, m.startInstallation()
			}
		}
	case installProgressMsg:
		m.installProgress = string(msg)
		return m, m.waitForInstallation()
	case installStepMsg:
		m.currentStepName = string(msg)
		return m, m.waitForInstallation()
	case installCompleteMsg:
		m.installComplete = true
		m.installing = false
		return m, nil
	case installErrorMsg:
		m.errors = append(m.errors, string(msg))
		return m, m.waitForInstallation()
	case installWarningMsg:
		m.warnings = append(m.warnings, string(msg))
		return m, m.waitForInstallation()
	}

	return m, nil
}

func (m model) View() string {
	if m.installComplete {
		var result strings.Builder
		result.WriteString(titleStyle.Render("🎉 Installation Complete!"))
		result.WriteString("\n\n")

		if len(m.errors) == 0 {
			result.WriteString(successStyle.Render("All selected components have been installed successfully!"))
		} else {
			result.WriteString(warningStyle.Render("Installation completed with some issues."))
		}

		result.WriteString("\n\n")
		result.WriteString("Please restart your system for all changes to take effect.\n")
		result.WriteString("Enjoy your new setup!\n\n")

		if len(m.warnings) > 0 {
			result.WriteString(warningStyle.Render("⚠️  Warnings:"))
			result.WriteString("\n")
			for _, warning := range m.warnings {
				result.WriteString(warningStyle.Render("  • " + warning))
				result.WriteString("\n")
			}
			result.WriteString("\n")
		}

		if len(m.errors) > 0 {
			result.WriteString(errorStyle.Render("❌ Errors:"))
			result.WriteString("\n")
			for _, err := range m.errors {
				result.WriteString(errorStyle.Render("  • " + err))
				result.WriteString("\n")
			}
			result.WriteString("\nCheck ~/install.log for details.\n")
		}

		result.WriteString("\nPress any key to exit...")
		return result.String()
	}

	if m.installing {
		var result strings.Builder
		result.WriteString(titleStyle.Render("📦 Installing Dotfiles..."))
		result.WriteString("\n\n")

		if m.currentStepName != "" {
			result.WriteString(progressStyle.Render("Current: " + m.currentStepName))
			result.WriteString("\n")
		}

		if m.installProgress != "" {
			result.WriteString(m.installProgress)
			result.WriteString("\n")
		}

		result.WriteString("\n")
		result.WriteString("Please wait while the installation completes...\n")
		result.WriteString("This may take several minutes depending on your internet connection.\n\n")

		if len(m.errors) > 0 {
			result.WriteString(errorStyle.Render("Recent errors:"))
			result.WriteString("\n")
			// Show only the last 3 errors to avoid cluttering
			start := len(m.errors) - 3
			if start < 0 {
				start = 0
			}
			for i := start; i < len(m.errors); i++ {
				result.WriteString(errorStyle.Render("  • " + m.errors[i]))
				result.WriteString("\n")
			}
			result.WriteString("\n")
		}

		result.WriteString("Press 'q' to quit after installation completes")
		return result.String()
	}

	var result strings.Builder

	result.WriteString(titleStyle.Render("🚀 Dotfiles Installer"))
	result.WriteString("\n")
	result.WriteString("Use ←→ to navigate categories, ↑↓ to navigate options, SPACE to toggle, ENTER to install\n\n")

	for catIndex, category := range m.categories {
		if catIndex == m.currentCategory {
			result.WriteString(selectedStyle.Render("▶ " + category.Name))
		} else {
			result.WriteString(categoryStyle.Render("  " + category.Name))
		}
		result.WriteString("\n")

		if catIndex == m.currentCategory {
			for stepIndex, step := range category.Steps {
				var prefix, checkbox string

				if step.Required {
					checkbox = "[●]"
				} else if m.selectedSteps[step.Function] {
					checkbox = "[✓]"
				} else {
					checkbox = "[ ]"
				}

				if stepIndex == m.currentStep {
					prefix = "  ▶ "
					result.WriteString(selectedStyle.Render(prefix + checkbox + " " + step.Name))
				} else {
					prefix = "    "
					if step.Required {
						result.WriteString(successStyle.Render(prefix + checkbox + " " + step.Name))
					} else if m.selectedSteps[step.Function] {
						result.WriteString(successStyle.Render(prefix + checkbox + " " + step.Name))
					} else {
						result.WriteString(unselectedStyle.Render(prefix + checkbox + " " + step.Name))
					}
				}
				result.WriteString("\n")

				if stepIndex == m.currentStep {
					result.WriteString(descriptionStyle.Render(step.Description))
					result.WriteString("\n")
				}
			}
			result.WriteString("\n")
		}
	}

	result.WriteString("\n")
	selectedCount := 0
	totalCount := 0
	for _, category := range m.categories {
		for _, step := range category.Steps {
			totalCount++
			if step.Required || m.selectedSteps[step.Function] {
				selectedCount++
			}
		}
	}
	result.WriteString(fmt.Sprintf("Selected: %d/%d components\n", selectedCount, totalCount))
	result.WriteString("Press ENTER to start installation, 'q' to quit")

	return result.String()
}

type installProgressMsg string
type installStepMsg string
type installCompleteMsg struct{}
type installErrorMsg string
type installWarningMsg string

func (m model) startInstallation() tea.Cmd {
	return func() tea.Msg {
		// Start the installation process
		go m.runInstallation()
		return installProgressMsg("Starting installation...")
	}
}

func (m model) waitForInstallation() tea.Cmd {
	return tea.Tick(time.Millisecond*100, func(time.Time) tea.Msg {
		return nil
	})
}

func (m model) runInstallation() {
	// Create install script content
	var scriptContent strings.Builder
	scriptContent.WriteString("#!/bin/bash\n\n")
	scriptContent.WriteString("exec > >(tee -a \"$HOME/install.log\") 2>&1\n\n")
	scriptContent.WriteString("FAILED_STEPS=()\n\n")

	// Add source statements for required libraries
	scriptContent.WriteString("# Load utilities and sub-scripts\n")
	scriptContent.WriteString("source \"$(pwd)/lib/utils.sh\"\n")
	scriptContent.WriteString("init_utils\n\n")
	scriptContent.WriteString("source \"$(pwd)/lib/packages.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/aur.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/nvidia.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/apps.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/wallpapers.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/sddm.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/zsh.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/fastfetch.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/dotfiles.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/node.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/mongodb.sh\"\n")
	scriptContent.WriteString("source \"$(pwd)/lib/virtualization.sh\"\n\n")

	scriptContent.WriteString("# Execute selected installation steps\n")

	// Add selected installation steps
	for _, category := range m.categories {
		for _, step := range category.Steps {
			if step.Required || m.selectedSteps[step.Function] {
				scriptContent.WriteString(fmt.Sprintf("echo \"=== Installing: %s ===\"\n", step.Name))
				scriptContent.WriteString(fmt.Sprintf("%s\n", step.Function))
				scriptContent.WriteString("echo\n")
			}
		}
	}

	scriptContent.WriteString("\n# Installation complete\n")
	scriptContent.WriteString("echo ''\n")
	scriptContent.WriteString("echo '🎉 ================================'\n")
	scriptContent.WriteString("echo '🎉  SETUP COMPLETE!'\n")
	scriptContent.WriteString("echo '🎉 ================================'\n")
	scriptContent.WriteString("echo ''\n")
	scriptContent.WriteString("report_installation_summary\n")

	scriptContent.WriteString("# Exit with appropriate code (summary already handled)\n")
	scriptContent.WriteString("if [ ${#FAILED_STEPS[@]} -gt 0 ]; then\n")
	scriptContent.WriteString("    exit 1\n")
	scriptContent.WriteString("else\n")
	scriptContent.WriteString("    exit 0\n")
	scriptContent.WriteString("fi\n")

	// Write the install script
	scriptPath := "/tmp/install_selected.sh"
	err := os.WriteFile(scriptPath, []byte(scriptContent.String()), 0755)
	if err != nil {
		fmt.Printf("Failed to create install script: %v\n", err)
		return
	}

	// Execute the install script
	cmd := exec.Command("bash", scriptPath)
	cmd.Dir, _ = os.Getwd()

	// Get stdout pipe to read output in real-time
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Printf("Failed to get stdout pipe: %v\n", err)
		return
	}

	// Start the command
	if err := cmd.Start(); err != nil {
		fmt.Printf("Failed to start installation: %v\n", err)
		return
	}

	// Read output line by line
	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		line := scanner.Text()
		// Parse different types of output
		if strings.Contains(line, "=== Installing:") {
			// Extract step name
			stepName := strings.TrimSpace(strings.Replace(line, "=== Installing:", "", 1))
			stepName = strings.TrimSpace(strings.Replace(stepName, "===", "", 1))
			fmt.Printf("STEP: %s\n", stepName)
		} else if strings.Contains(line, "ERROR") || strings.Contains(line, "error") {
			fmt.Printf("ERROR: %s\n", line)
		} else if strings.Contains(line, "WARNING") || strings.Contains(line, "warning") {
			fmt.Printf("WARNING: %s\n", line)
		} else {
			fmt.Printf("OUTPUT: %s\n", line)
		}
	}

	// Wait for command to finish
	err = cmd.Wait()

	// Clean up
	os.Remove(scriptPath)

	if err != nil {
		fmt.Printf("Installation completed with errors: %v\n", err)
	} else {
		fmt.Printf("Installation completed successfully\n")
	}
}

func main() {
	// Check if we're in the right directory
	if _, err := os.Stat("lib/packages.sh"); os.IsNotExist(err) {
		fmt.Println("Error: Please run this installer from the dotfiles directory.")
		fmt.Println("The lib/packages.sh file was not found.")
		os.Exit(1)
	}

	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error running program: %v", err)
		os.Exit(1)
	}
}
