#!/bin/bash

set -euo pipefail

DRY_RUN=1

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
endcolor=$(tput setaf 9)
bold=$(tput bold)
normal=$(tput sgr0)

run_command() {
  echo "${bold}Command:${normal} $@"

  if [ $DRY_RUN -eq 0 ]; then
    eval "$@"
  else
    echo -e "[noop] $@"
  fi
}

print_header() {
  echo "${bold}${blue}${1}${endcolor}${normal}"
}

setup_macos() {
  print_header "Adjusting macOS defaults"
  run_command ./improved-macos-defaults.sh
}

install_dependencies() {
  homebrew_formulaes=(
    git
    git-standup
    jesseduffield/lazygit/lazygit
    mas
    jq
    tmux
    zsh
    zsh-completions
    gnupg
  )
  homebrew_casks=(
    sequel-ace
    visual-studio-code
    google-chrome
    bitwarden
    whatsapp
    docker
    iterm2
    spotify
  )
  nvm_version="0.39.1"

  print_header "Installing Homebrew"
  run_command "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""

  print_header "Installing NVM"
  run_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${nvm_version}/install.sh | bash"

  run_command "source ~/.zshrc"

  print_header "Installing latest Node LTS"
  run_command "nvm install --lts"

  print_header "Installing Homebrew formulaes"
  run_command "brew install ${homebrew_formulaes[@]}"

  print_header "Installing Homebrew casks"
  run_command "brew install --cask ${homebrew_casks[@]}"
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

if [ $DRY_RUN -eq 1 ]; then
  echo "${bold}${red}NB: Running in dry mode - no commands will be executed${endcolor}${normal}"
fi

read -p "Enter full name: " user_full_name
read -p "Enter email address: " user_email

install_dependencies

print_header "Appending improved zsh config"
run_command "cp custom-zsh-config.sh ~/"

if ! grep -q custom-zsh-config.sh ~/.zshrc; then
  run_command "echo \"source ~/custom-zsh-config.sh\" >> ~/.zshrc"
fi

setup_macos
setup_ssh "$user_email"
setup_gpg "$user_email"
setup_git "$user_full_name" "$user_email"
