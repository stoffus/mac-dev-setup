plugins=(
    git
    docker
)

alias ssh=ssh --apple-load-keychain
alias lg=lazygit

init_ssh_agent() {
    eval `ssh-agent | tee ~/.ssh/agent.env`
    ssh-add --apple-load-keychain
}

if [ -f ~/.ssh/agent.env ] ; then
    . ~/.ssh/agent.env > /dev/null
    if ! kill -0 $SSH_AGENT_PID > /dev/null 2>&1; then
        # Stale agent file found
        init_ssh_agent
    fi
else
    init_ssh_agent
fi
