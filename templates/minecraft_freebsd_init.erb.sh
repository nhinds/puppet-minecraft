#!/bin/sh
#
# PROVIDE: <%= @instance %>
# REQUIRE: LOGIN DAEMON NETWORKING mountcritlocal
# KEYWORD: shutdown
#
# This file is managed by Puppet
#
# Add the following lines to /etc/rc.conf.local to enable the minecraft server:
#
#<%= @instance %>_enable="YES"
#<%= @instance %>_chdir="<%= @install_dir %>"
#<%= @instance %>_jar="<%= @install_dir %>/<%= @jar %>"
#<%= @instance %>_args="<%= @java_args %>"
#<%= @instance %>_xmx="<%= @xmx %>"
#<%= @instance %>_xms="<%= @xms %>"
#<%= @instance %>_user="<%= @user %>"

# See <%= @install_dir %>/<%= @jar %> for flags

. /etc/rc.subr

name=<%= @instance %>
rcvar=<%= @instance %>_enable

load_rc_config ${name}

pidfile=/var/run/<%= @instance %>.pid

extra_commands="console status kill"
start_cmd="minecraft_start"
stop_cmd="minecraft_stop"
console_cmd="minecraft_console"
status_cmd="minecraft_status"
kill_cmd="minecraft_kill"

: ${<%= @instance %>_enable="NO"}
: ${<%= @instance %>_session="<%= @instance %>"}
: ${<%= @instance %>_user="<%= @user %>"}
: ${<%= @instance %>_chdir="<%= @install_dir %>"}
: ${<%= @instance %>_jar="<%= @install_dir %>/<%= @jar %>"}
: ${<%= @instance %>_args="-XX:+UseConcMarkSweepGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=4 -XX:+AggressiveOpts"}
: ${<%= @instance %>_xmx="<%= @xmx %>"}
: ${<%= @instance %>_xms="<%= @xms %>"}

minecraft_start() {
  unset "${rc_arg}_cmd"
  if minecraft_running; then
    echo "minecraft already running?"
  elif [ ${<%= @instance %>_xms%?} -gt ${<%= @instance %>_xmx%?} ]; then
    echo "ERROR: ${name}_xms is set greater than ${name}_xmx."
  else
    cd $<%= @instance %>_chdir
    su -m $<%= @instance %>_user -c "/usr/bin/env tmux -L ${name} new-session -s ${name} -d '/usr/local/bin/java -Xmx${<%= @instance %>_xmx} -Xms${<%= @instance %>_xms} ${<%= @instance %>_args} -jar ${<%= @instance %>_jar} nogui'"
  fi
}

minecraft_stop() {
  if minecraft_running; then
    echo "Stopping minecraft."
    su -m ${<%= @instance %>_user} -c "/usr/bin/env tmux -L ${name} send-keys -t ${name} \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\" ENTER"
    su -m ${<%= @instance %>_user} -c "/usr/bin/env tmux -L ${name} send-keys -t ${name} \"save-all\" ENTER"
    sleep 10
    su -m ${<%= @instance %>_user} -c "/usr/bin/env tmux -L ${name} send-keys -t ${name} \"stop\" ENTER"
    i=0
    while [ $i -lt 10 ]; do
      i=$(($i + 1))
      if minecraft_running; then
        sleep 1
      else
        echo "${name} has been stopped."
        return
      fi
    done
    echo "WARN: ${name} could not be stopped or is taking longer than expected."
    echo "WARN: To view the console, type 'service ${name} console'"
    echo "WARN: To kill ${name}, type 'service ${name} kill'"
  else
    echo "${name} is not running."
  fi
}

minecraft_status() {
  if minecraft_running; then
    echo "minecraft is running."
  else
    echo "minecraft is not running."
  fi
}

minecraft_running() {
  pgrep -qu ${<%= @instance %>_user} java
  return $?
}

minecraft_console() {
  if ! minecraft_running; then
    echo "${name} is not running."
  else
    export TERM=xterm
    su -m ${<%= @instance %>_user} -c "/usr/bin/env tmux -L ${name} attach-session -t ${name}"
  fi
}

minecraft_kill() {
  if ! minecraft_running; then
    echo "${name} is not running."
  else
    #pkill -KILL -u mcserver java
    echo "${name} has been killed."
  fi
}

run_rc_command "$1"
