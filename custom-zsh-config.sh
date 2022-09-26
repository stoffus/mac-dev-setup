plugins=(
    git
    docker
)

alias ssh=ssh --apple-load-keychain
alias lg=lazygit

if [ -f ~/.ssh/agent.env ] ; then
    . ~/.ssh/agent.env > /dev/null
    if ! kill -0 $SSH_AGENT_PID > /dev/null 2>&1; then
        # Stale agent file found. Spawning new agent...
        eval `ssh-agent | tee ~/.ssh/agent.env`
        ssh-add --apple-load-keychain
    fi
else
    # Starting ssh-agent
    eval `ssh-agent | tee ~/.ssh/agent.env`
    ssh-add --apple-load-keychain
fi
