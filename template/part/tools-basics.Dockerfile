###################################################
## Basic tools
###################################################
RUN apk add --no-cache vim nano bash htop
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
ADD <<EOF ~/.bashrc
alias ls='ls --color=auto'
alias ll='ls --color=auto -alF'
alias la='ls --color=auto -A'
alias l='ls --color=auto -CF'
EOF
RUN mkdir ~/.ssh && touch ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts && eval "$(ssh-agent -s)"
# FIXME est-ce que nous devons installer symfony par défaut ?
RUN echo 'eval "$(symfony-autocomplete)"' > ~/.bash_profile