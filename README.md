# tmux_setup

A tool that sets up tmux and adds tmux configurations for your projects.
Unlike similar tools, this project is written completely in bash and can be very easily setup.
It clones your projects to the directory you have provided.
The projects are opened in a tmux session with 2 windows.
The first window opens vim and the second window has a vertical split with the right split split horizontally.

### Installation

`curl -s -S -L https://raw.githubusercontent.com/sumanmukherjee03/tmux_setup/master/bootstrap.sh | bash`

Once this script runs it will create a $HOME/bin and $HOME/lib if not already present.
You will have to add $HOME/bin to you $PATH.

Add a line like this to the end of your ~/.bashrc or ~/.profile if not already there.
`export PATH=$HOME/bin:$PATH`

### Configuration
Create a $HOME/.projects.json file with your project configuration like so

```json
{
  "<group-1>": [{
    "name": "<name-of-session-1>",
    "repo": "<git-repo-url-1>",
    "dir": "<full-dir-path-where-you-want-the-repo-cloned-1>"
  }, {
    "name": "<name-of-session-2>",
    "repo": "<git-repo-url-2>",
    "dir": "<full-dir-path-where-you-want-the-repo-cloned-2>"
  }, {
    "name": "<name-of-session-3>",
    "repo": "<git-repo-url-3>",
    "dir": "<full-dir-path-where-you-want-the-repo-cloned-3>"
  }]
}
```

### How to run
1. `tmux_setup -h # To get the help menu`
2. `tmux_setup -s <group-1> # To start the tmux sessions of the group`
3. `tmux_setup -k <group-1> # To kill the tmux sessions of the group`
4. `tmux attach-session -t <name-of-session-1> # To join the sessions`
