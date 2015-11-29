# tmux_setup
A tool that sets up tmux and adds tmux configurations for your projects

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
From within the directory where you have cloned this project you can run the following

1. `make install # To install tmux and the dependencies`
2. `make GROUP=<group-1> # To start the tmux sessions. Run is default goal in the Makefile`
3. `make run GROUP=<group-1> # To start the tmux sessions`
4. `make stop GROUP=<group-1> # To kill the tmux sessions`
5. `tmux attach-session -t <name-of-session-1> # To join the sessions`
