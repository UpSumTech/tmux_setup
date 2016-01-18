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

Expose a sh function for loading the correct env vars per group in your ~/.bashrc or /.bash_profile or some similar file for the login shell
This is an example shell function.

```shell
set_env_vars_for_group() {
  case "$1" in
    <group-1>)
      unset AWS_ACCESS_KEY
      unset AWS_SECRET_KEY
      unset AWS_ACCESS_KEY_ID
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_DEFAULT_REGION

      export AWS_ACCESS_KEY="<aws access key for group-1>"
      export AWS_SECRET_KEY="<aws secret key for group-1>"
      export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
      export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
      export AWS_DEFAULT_REGION=us-east-1

      ;;
    <group-2>)
      unset AWS_ACCESS_KEY
      unset AWS_SECRET_KEY
      unset AWS_ACCESS_KEY_ID
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_DEFAULT_REGION

      export AWS_ACCESS_KEY="<aws access key for group-2>"
      export AWS_SECRET_KEY="<aws secret key for group-2>"
      export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
      export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
      export AWS_DEFAULT_REGION=us-west-2

      ;;
    *)
      unset AWS_ACCESS_KEY
      unset AWS_SECRET_KEY
      unset AWS_ACCESS_KEY_ID
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_DEFAULT_REGION
      ;;
  esac
}
```

### How to run
1. `tmux_setup -h # To get the help menu`
2. `tmux_setup -s <group-1> # To start the tmux sessions of the group`
3. `tmux_setup -k <group-1> # To kill the tmux sessions of the group`
4. `tmux attach-session -t <name-of-session-1> # To join the sessions`
