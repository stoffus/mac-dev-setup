#!/bin/bash

set -euo pipefail

source .env

# Text coloring and styling
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
endcolor=$(tput setaf 9)
bold=$(tput bold)
normal=$(tput sgr0)

run_command() {
  echo "${bold}Command:${normal} $@"

  if [ "$DRY_RUN" == false ]; then
    eval "$@"
  else
    echo -e "[noop] $@"
  fi
}

print_header() {
  echo "${bold}${blue}=== ${1} ===${endcolor}${normal}"
}

setup_macos() {
  print_header "Adjusting macOS defaults"
  run_command ./improved-macos-defaults.sh
}

install_java_dependencies() {
  print_header "Installing Java dependencies"

  print_header "Installing SDKMAN!"
  run_command 'curl -s "https://get.sdkman.io" | bash'
}

install_node_dependencies() {
  print_header "Installing Node dependencies"

  print_header "Installing NVM"
  run_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash"

  print_header "Installing latest Node LTS"
  run_command "nvm install --lts"

  print_header "Installing VSCode extensions"
  for extension in "${VSCODE_EXTENSIONS[@]}"; do
    run_command "code --install-extension $extension"
  done
}

install_dependencies() {
  print_header "Installing Homebrew"
  run_command "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""

  run_command "source ~/.zshrc"

  print_header "Installing Homebrew formulaes"
  run_command "brew install ${HOMEBREW_FORMULAES[@]}"

  print_header "Installing Homebrew casks"
  run_command "brew install --cask ${HOMEBREW_CASKS[@]}"
}

setup_gpg() {
  user_email=$1

  print_header "GPG keys"

  read -n1 -p "Do you want to generate a new GPG key for $user_email (y/N)?: " generate_gpg_key
  echo

  if [ "$generate_gpg_key" == "y" ]; then
    run_command 'gpg --full-generate-key'
  else
    echo "Skipping GPG key generation"
  fi
}

setup_git() {
  user_full_name=$1
  user_email=$2

  print_header "Configuring Git"

  run_command "git config --global user.name \"$user_full_name\""
  run_command "git config --global user.email \"$user_email\""
  run_command "git config --global credential.helper osxkeychain"
}

setup_ssh() {
  user_email=$1
  default_ssh_comment=$user_email

  if [ ! -f ~/.ssh/id_ed25519 ]; then
    print_header "Generating a new SSH key pair"
    read -p "Please enter email to use as SSH key comment [$default_ssh_comment]: " ssh_comment
    ssh_comment=${ssh_comment:-$user_email}
    run_command "ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C \"$ssh_comment\""
  fi
}

if [ "$DRY_RUN" == true ]; then
  echo "${bold}${red}NB: Running in dry mode - no commands will be executed${endcolor}${normal}"
fi

read -p "Enter full name: " user_full_name
read -p "Enter email address: " user_email

install_dependencies

read -n1 -p "Are you planning to use Java (y/N)?: " enable_java
echo

if [ "$enable_java" == "y" ]; then
  install_java_dependencies
fi

read -n1 -p "Are you planning to use Node (y/N)?: " enable_node
echo

if [ "$enable_node" == "y" ]; then
  install_node_dependencies
fi

print_header "Appending improved zsh config"
run_command "cp custom-zsh-config.sh ~/"

if ! grep -q custom-zsh-config.sh ~/.zshrc; then
  run_command "echo \"source ~/custom-zsh-config.sh\" >> ~/.zshrc"
fi

print_header "macOS defaults"
read -n1 -p "Do you want to apply improved defaults to macOS (y/N)?: " adjust_macos_defaults
echo

if [ "$adjust_macos_defaults" == "y" ]; then
  setup_macos
fi

setup_ssh "$user_email"
setup_gpg "$user_email"
setup_git "$user_full_name" "$user_email"
