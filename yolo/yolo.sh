#!/usr/bin/env bash

set -e
LC_CTYPE=C

check_bash_version() {
  local target_version=${1:-3} current_version=${BASH_VERSINFO:-0} err=0
  [ $current_version -ge $target_version ] || err=$?
  [ ${err:-0} -gt 0 ] && \
    printf "Requires bash version >=%s. Your current bash major version is %s.\n" "$target_version" "${current_version:-0}"
  return $err
}

check_bash_version

YOLO_LOADED=${YOLO_LOADED:-false}
YOLO_PROFILE_NAME="${1:-yolo}"
YOLO_FLAVOR="${2:-ubuntu}"
YOLO_VOLUME_NAME="${3:-containerfy-${YOLO_PROFILE_NAME}-home}"

if [ -f "$0" ]; then
  SCRIPT_FILENAME="$0"
  SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
else
  SCRIPT_FILENAME="${YOLO_PROFILE_NAME}.${YOLO_FLAVOR}.sh"
  SCRIPT_DIR="$(pwd)"
fi

# To persist value without specifying '--platform', the following can be exported
DOCKER_DEFAULT_PLATFORM=linux/amd64

# IMPORTANT - If you don't intend to override the defaults, make sure YOLO_DATA_TARGET and YOLO_PROFILE_TARGET are not set

# Basic example:
#     $ sh yolo.sh
# Example using YOLO_DATA_TARGET override:
#     $ YOLO_DATA_TARGET="$PWD/../mount/data/" sh yolo.sh
# Example using multiple overrides:
#     $ YOLO_DATA_TARGET="$PWD/../mount/data/" PORT_EIGHT_THOUSAND=9000 PORT_EIGHTY_EIGHTY=9080 RANDOM=$RANDOM ENTRYPOINT_NAME=yolo.docker-entrypoint.$RANDOM.sh sh yolo.sh

yolo_mount_path() { local path="$(dirname $SCRIPT_DIR)/.dockermount/${1}"; path=${path%/}; echo "$path"; }; \
volume_create() { local target="$(yolo_mount_path $2)"; [ -d "$target" ] || mkdir -p "$target"; docker volume create "$1"; }; \
volume_create "${YOLO_VOLUME_NAME}" "${YOLO_PROFILE_NAME}" >/dev/null; \
[ ! -f "${SCRIPT_DIR}/${YOLO_FLAVOR}.env" ] || . "${SCRIPT_DIR}/${YOLO_FLAVOR}.env"; \
GIT_CONFIG_FULL_NAME="${GIT_CONFIG_FULL_NAME:-Full Name}"; \
GIT_CONFIG_EMAIL="${GIT_CONFIG_EMAIL:-full.name@example.com}"; \
GIT_CONFIG_USERNAME="${GIT_CONFIG_USERNAME:-fullname}"; \
YOLO_DOMAIN_DEFAULT="$(echo $GIT_CONFIG_EMAIL | awk -F '@' '{print $2}')"; \
YOLO_DOMAIN="${YOLO_DOMAIN:-$YOLO_DOMAIN_DEFAULT}"; \
YOLO_MOUNT_CONTEXT="$(yolo_mount_path)"; \
YOLO_DATA_TARGET="${YOLO_DATA_TARGET:-$YOLO_MOUNT_CONTEXT/data}" && ([ -d $YOLO_DATA_TARGET ] || mkdir -p $YOLO_DATA_TARGET); \
YOLO_PROFILE_TARGET="${YOLO_PROFILE_TARGET:-$YOLO_MOUNT_CONTEXT/$YOLO_PROFILE_NAME}" && ([ -d $YOLO_PROFILE_TARGET ] || mkdir -p $YOLO_PROFILE_TARGET); \
PORT_EIGHT_THOUSAND="${PORT_EIGHT_THOUSAND:-9000}"; \
PORT_EIGHTY_EIGHTY=${PORT_EIGHTY_EIGHTY:-9080}; \
SEED="${RANDOM:-$SEED}"; \
DATA_MOUNT_SRC="/${DATA_MOUNT_SRC:-$(basename $YOLO_DATA_TARGET)}"; \
YOLO_WHEEL=sudo YOLO_DEBUG=true; \
SSH_CONFIG_PREFIX="~/.ssh/github"; \
ENTRYPOINT_PATH_PREFIX="$YOLO_PROFILE_TARGET/$YOLO_FLAVOR/bin"; \
[ -r "$ENTRYPOINT_PATH_PREFIX" ] || mkdir -p $ENTRYPOINT_PATH_PREFIX; \
set -- \
  "$SCRIPT_FILENAME" "$SEED" "$DATA_MOUNT_SRC" \
  "$(uname -s | tr '[:upper:]' '[:lower:]')/$(uname -m)" "$(date -u +%Y-%m-%dT%TZ)" \
  "${TAILSCALED_IN_FOREGROUND:-false}" "$YOLO_PROFILE_NAME" "$YOLO_FLAVOR" "$YOLO_WHEEL"; \
  CONTAINER_NAME="$7-$8-$2" && \
  printf "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n" \
    "YOLO_DOMAIN" "$YOLO_DOMAIN" "GIT_CONFIG_FULL_NAME" "$GIT_CONFIG_FULL_NAME" \
    "GIT_CONFIG_EMAIL" "$GIT_CONFIG_EMAIL" "GIT_CONFIG_USERNAME" "$GIT_CONFIG_USERNAME" \
    "YOLO_DATA_TARGET" "$YOLO_DATA_TARGET" "DATA_MOUNT_SRC" "$3" \
    "YOLO_PROFILE_TARGET" "$YOLO_PROFILE_TARGET" "PROFILE_NAME" "$7" "YOLO_FLAVOR" "$8" \
    "SEED" "$2" "CONTAINER_NAME" "$CONTAINER_NAME" "YOLO_DEBUG" "$YOLO_DEBUG" && \
  printf "%s: %s\n" "Port mappings" "$PORT_EIGHT_THOUSAND:8000, $PORT_EIGHTY_EIGHTY:8080" && \
  printf "\n" && read -n 1 -r -s -p $'\033[7m'"Press any key to continue ... "$'\033[0m' && printf "\n%s\n" "And away we go!" && \
  ENTRYPOINT_NAME="${ENTRYPOINT_NAME:-$7.docker-entrypoint.$8.sh}" && \
  __overwrite_entrypoint() { local input=""; read -r -p $'\033[32;1m'"? "$'\033[0m'$'\033[1m'"Overwrite?"$'\033[0m'" [Y/n] " input; [ -n "$input" ] || input="Y"; \
    expr $input : '[ynYN]' >/dev/null 2>&1 && echo $input || __overwrite_entrypoint; } && \
    ([ ! -f "$ENTRYPOINT_PATH_PREFIX/$ENTRYPOINT_NAME" ] || \
    (printf "\nFile '%s' already exists.\n%s '%s' %s ...\n" "$ENTRYPOINT_PATH_PREFIX/$ENTRYPOINT_NAME" \
    "Overwrite it, or" "$7.docker-entrypoint.$8.$SEED.sh" "will be created" && \
    ENTRYPOINT_NAME_OVERWRITE=$(__overwrite_entrypoint) && \
    printf "%s: %s\n" "ENTRYPOINT_NAME_OVERWRITE" "$ENTRYPOINT_NAME_OVERWRITE" && \
    [ "$ENTRYPOINT_NAME_OVERWRITE" = "y" -o "$ENTRYPOINT_NAME_OVERWRITE" = "Y" ] && \
    (cp "$ENTRYPOINT_PATH_PREFIX/$ENTRYPOINT_NAME" "${ENTRYPOINT_PATH_PREFIX}/${ENTRYPOINT_NAME}.old"; exit 0) || exit 1) ) || \
  ENTRYPOINT_NAME="$7.docker-entrypoint.$8.$SEED.sh" && \
  ENTRYPOINT_PATH="$ENTRYPOINT_PATH_PREFIX/$ENTRYPOINT_NAME" && \
  ENTRYPOINT_CONTAINER_PATH="/root/bin/$ENTRYPOINT_NAME" && \
  printf "%s: %s\n" "ENTRYPOINT_PATH" "$ENTRYPOINT_PATH" && \
  show_processing() { sleep 1 && printf "Processing " && (for i in {1..2}; do sleep 1; printf "."; done; sleep 1; echo); } && \
  show_processing && (cat >"$ENTRYPOINT_PATH" <<EOF
# https://docs.docker.com/reference/dockerfile/#automatic-platform-args-in-the-global-scope
SCRIPT_FILENAME="$1" SEED=$2 DATA_SRC="$3" \\
HOST_PLATFORM="$4" BUILDSTART="$5" TAILSCALED_IN_FOREGROUND="$6" \\
PROFILE_NAME="$7" TARGET_OS_FLAVOR="$8" WHEEL="$9" CONTAINER_NAME="$CONTAINER_NAME" \\
TARGET_OS="\$(uname -s | tr '[:upper:]' '[:lower:]')" TARGETARCH="\$(uname -m)" TARGET_PLATFORM="\${TARGET_OS}/\$TARGETARCH" \\
OS_RELEASE=\$(. /etc/os-release; echo \$(echo "\$NAME" | awk '{print \$1}') "\$ID" "\$VERSION_ID" "\$VERSION_CODENAME") \\
#!/bin/sh
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#index-set
# https://sipb.mit.edu/doc/safe-shell/
set -eu

sanity_check() {
  printf "%s\n" "Open the pod bay doors HAL."
  local err=0
  [ -f /.dockerenv -a -f "$ENTRYPOINT_CONTAINER_PATH" ] || err=\$?
  [ "\$err" -eq 0 ] || (sleep 2; printf "%s\n" "I'm sorry Dave, I'm afraid I can't do that."; sleep 1)
  return \$err
}
sanity_check

# Debug
str_pad() {
  local begin="\${1:-""}" end="\${2:-""}" prefix="\${3:-x}" pad="\${4:-20}" delim="\${5:- }"
  printf "[%s] %-\${pad}s@%s\n" \${prefix} \${begin}@ \${end} | sed -e "s/ /\${delim}/g" -e "s/\${delim}@/ /" -e "s/@\${delim}/ /"
}
export YOLO_DEBUG="\${YOLO_DEBUG:-$YOLO_DEBUG}"
print_debug() {
  local first="" second=""
  if [ "\${YOLO_DEBUG}" = "true" ]; then
    while [ \$# -gt 0 ]; do first="\$1"; second="\$2"; shift; shift; (set -- "\$first" "\$second" "DEBUG"; str_pad "\$@"); done
  fi
}
print_debug "HOST_PLATFORM:" "\${HOST_PLATFORM}"
print_debug "TARGET_PLATFORM:" "\${TARGET_PLATFORM}"
print_debug "TARGET_OS_FLAVOR:" "\${TARGET_OS_FLAVOR}"
print_debug "BUILDSTART:" "\${BUILDSTART}"
print_debug "SEED:" "\${SEED}"

set -x

cat <<EOT >/etc/profile.d/01-environment.sh
has() { command -v "\\\${1:-""}" >/dev/null; }
is() { [ "\\\${1:-false}" = "true" -o "\\\${1:-0}" = "1" ] || return \\\$?; }
exists() { [ -e "\\\${1:-""}" ] || return \\\$?; }
value() { [ "\\\${1:-""}x" != "x" ] || return \\\$?; }
equals() { ! value "\\\${1:-""}" || ! value "\\\${2:-""}" || [ "\\\$1" = "\\\$2" ] || return \\\$?; }
upper() { ! value "\\\${1:-""}" || echo "\\\$1" | tr '[:lower:]' '[:upper:]'; }
lower() { ! value "\\\${1:-""}" || echo "\\\$1" | tr '[:upper:]' '[:lower:]'; }

pss() { ps -xf --sort -tty; }
has() { command -v "\\\$1" 1>/dev/null 2>&1; }
is() { [ "\\\${1:-false}" = "true" ] || return \\\$?; }
exists() { [ -e "\\\$1" ] || return \\\$?; }
value() { [ "\\\${1:-""}x" != "x" ] || return \\\$?; }
gh_login() { gh auth status 2>/dev/null || gh auth login -p https -w; }

OS_RELEASE="\$OS_RELEASE"
export OS_NAME="\\\$(echo "\\\$OS_RELEASE" | awk '{print \\\$1}')"
export OS_ID="\\\$(echo "\\\$OS_RELEASE" | awk '{print \\\$2}')"
export OS_VERSION_ID="\\\$(echo "\\\$OS_RELEASE" | awk '{print \\\$3}')"
export OS_VERSION_CODENAME="\\\$(echo "\\\$OS_RELEASE" | awk '{print \\\$4}')"
export OS_RELEASE="\\\$(echo "\\\${OS_ID}\\\${1:--}\\\${OS_VERSION_CODENAME}")"

export DISTRO="\\\$OS_ID"
export DISTRO_VERSION="\\\$OS_VERSION_ID"
export VERSION_CODENAME="\\\$OS_VERSION_CODENAME"
export PROFILE_DIR="/etc/profile.$7.d/\\\$OS_RELEASE"
EOT

. /etc/profile.d/01-environment.sh

# For apt
export DEBIAN_FRONTEND=noninteractive
# For Homebrew
export NONINTERACTIVE=1

flavor_check() {
  value "\$DISTRO" && value "\$TARGET_OS_FLAVOR" && return 0
  equals "$8" "\$DISTRO" && equals "$8" "\$TARGET_OS_FLAVOR" && return 0
  print_debug "You have chosen poorly." "(Yay movie references)"
  return 1
}
flavor_check

apt_updated="false"
__apt_update() {
  if is "\${1:-false}"; then
    if is "\$apt_updated"; then
        apt-get update
        apt_updated=true
    fi
  else
    apt-get update -qq >/dev/null
  fi
}

create_wheel_user() {
  local wheel=$9
  local comment="\${1:-""}"
  local user=\$(echo "\${2:-""}" | awk -F':' '{print \$1}')
  local uid=\$(echo "\${2:-""}" | awk -F':' '{print \$2}')
  uid="\${uid:-1000}"
  local group=\$(echo "\${3:-\${user}:\${uid}}" | awk -F':' '{print \$1}')
  group="\${group:-\$user}"
  local gid=\$(echo "\${3:-""}" | awk -F':' '{print \$2}')
  gid="\${gid:-\$uid}"
  local home="/home/\$user"
  groups \$user 2>/dev/null || (groupadd --gid \$gid \$user && \\
    adduser -disabled-password --shell /bin/bash \\
      --uid \$uid --home "\$home" --ingroup "\$group" \\
      --comment "\$comment" "\$user" && \\
    usermod -a -G "\$wheel" "\$user" && \\
    passwd -d "\$user")
}

create_system_user() {
  local wheel=$9
  local user=\$(echo "\$1" | awk -F':' '{print \$1}')
  local uid=\$(echo "\$1" | awk -F':' '{print \$2}')
  uid="\${uid:-1000}"
  local group=\$(echo "\$2" | awk -F':' '{print \$1}')
  group="\${group:-\$user}"
  local gid=\$(echo "\$2" | awk -F':' '{print \$2}')
  gid="\${gid:-\$uid}"
  local home="/home/\$user"
  groups \$user 2>/dev/null || (groupadd --gid \$gid \$user && \\
    adduser --shell /bin/bash --uid \$uid --system --home "\$home" \\
      --ingroup "\$group" "\$user" && \\
    usermod -a -G "\$wheel" "\$user")
}

quick_links() {
  local src="\$1" target="\$2"
  exists \$target || ln -s "\$src" \$target
  exists ~/data || ln -s "\$src" ~/data
}

__init() {
  rm -f /dev/stdout /dev/stderr
  ln -s /proc/1/fd/1 /dev/stdout
  ln -s /proc/1/fd/2 /dev/stderr
  exists /data || ln -s \$DATA_SRC /data
  exists \$DATA_SRC || mkdir \$DATA_SRC
  exists ~/.local/$7 || mkdir -p ~/.local/$7
  # quick_links \$DATA_SRC ~\$DATA_SRC
  \$(cat /etc/passwd | grep "^\$TARGET_OS_FLAVOR:x:1000" >/dev/null) || \
    create_wheel_user "\$(echo \$OS_NAME | awk '{print \$1}')" "\$OS_ID"
  exists "/home/\$OS_ID/.local" || mkdir -p "/home/\$OS_ID/.local/$7"
  quick_links \$DATA_SRC "/home/\${OS_ID}\${DATA_SRC}"

  __tailscaled_pid
  __apt_update true
}

# Because 'sh'
__file_list_count() { echo \$#; }

# TODO: generate from profile?
__init_gpg() {
  local file_list=0
  local user=\$(whoami)
  file_list_count=\$(__file_list_count \$(ls ~/.gnupg/ 2>/dev/null))
  if [ \$file_list_count -lt 9 ]; then \\
    printf "\033[93m>\033[0m Generating gpg key with empty passphrase ...\n\033[96;1m%s\033[0m\n" "gpg --quick-gen-key ..."
    # /usr/bin/gpg --no-tty --with-colons --fingerprint -K
    gpg --quick-gen-key --homedir ~/.gnupg --yes --always-trust --batch --passphrase '' aws-vault

    ### *Fixes* gpg: WARNING: unsafe permissions on homedir '~/.gnupg'
    #chown -R \$user ~/.gnupg
    chmod 700 ~/.gnupg
    #chmod 600 ~/.gnupg/*
  fi
}

# TODO: generate from profile?
__init_pass() {
  # THIS IS WHERE pass IS INITIALIZED
  local user=\$(whoami)

  mkdir -p ~/.password-store
  chown -R \$user:\$user ~/.password-store
  chmod -R 700 ~/.password-store

  local file_list=0
  file_list_count=\$(__file_list_count \$(ls ~/.password-store/ 2>/dev/null))
  if [ \$file_list_count -lt 2 ]; then \\
    [ -f ~/.password-store/.gpg-id ] || pass init --path= aws-vault
  fi
}

__configure_motd() {
  mkdir -p /etc/motd.d && echo "" >/etc/motd.d/newline
  grep --color=never -E -q '(^#?\s*account\s*requisite\s*pam_time\.so$)(\s*)' /etc/pam.d/su && \\
  sed -z -E -i "s@(#?\s*account\s*requisite\s*pam_time\.so)(\s*)@\1\2\\
# Enable MOTD - Added dynamically by "$ENTRYPOINT_CONTAINER_PATH" via $SCRIPT_FILENAME\\\\
###\\\\
# Prints the message of the day upon successful login.\\\\
# (Replaces the 'MOTD_FILE' option in login.defs)\\\\
# This includes a dynamically generated part from /run/motd.dynamic\\\\
# and a static (admin-editable) part from /etc/motd.\\\\
session    optional   pam_motd.so motd=/run/motd.dynamic\\\\
session    optional   pam_motd.so noupdate\2@" /etc/pam.d/su
}

__configure_wheel_su() {
  # https://administratosphere.wordpress.com/2011/07/22/the-wheel-group-updated/
  pattern="#?\s*(auth\s*sufficient\s*pam_wheel\.so\s*[a-z]*)\s(\s*)"
  replace="\1 group=$9\2\2"
  grep --color=never -E -q "\$pattern" /etc/pam.d/su && \\
  sed -E -z -i "s@\${pattern}@\${replace}@g" /etc/pam.d/su
}

__configure_pam() {
  __configure_motd
  __configure_wheel_su
}

__configure_nanorc() {
  grep --color=never -E -q '#?\s*(set\s*casesensitive)' /etc/nanorc && \\
  sed -E -z -i "s@#?\s*(set\s*casesensitive)@\1@g" /etc/nanorc

  cat <<EOT >/root/.nanorc
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

# Full reference and default configuration file found at '/etc/nanorc'

set atblanks
set autoindent
# unset casesensitive
set constantshow
set cutfromcursor
set indicator
set linenumbers
# set minibar
set mouse
set positionlog
set smarthome
set softwrap
set tabsize 4
set tabstospaces
set zap

set titlecolor bold,white,magenta
set promptcolor black,yellow
set statuscolor bold,white,magenta
set errorcolor bold,white,red
set spotlightcolor black,orange
set selectedcolor lightwhite,cyan
set stripecolor ,yellow
set scrollercolor magenta
set numbercolor magenta
set keycolor lightmagenta
set functioncolor magenta

extendsyntax python tabgives "    "
extendsyntax makefile tabgives "	"

# bind ^X cut main
bind ^C copy main
bind ^V paste all
# bind ^Q exit all
bind ^S savefile main
# bind ^W writeout main
bind ^N insert main
bind ^H help all
bind ^H exit help
bind ^F whereis all
bind ^G findnext all
bind ^B wherewas all
bind ^D findprevious all
bind ^R replace main
bind ^Z undo main
bind ^Y redo main

bind ^T gotoline main
EOT
}

__configure_profile() {
  __configure_nanorc
  cp /etc/skel/.profile /root/.profile
  cp /etc/skel/.bashrc /root/.bashrc
  exists "\$PROFILE_DIR" || mkdir -p "\$PROFILE_DIR"

  cat <<EOT > /etc/profile.d/02-reload.sh
__get_os_codename() { . /etc/os-release; echo "\\\${ID:-""}-\\\${VERSION_CODENAME:-""}"; }
__profile_dir() { echo "\$(dirname \$PROFILE_DIR)/\\\$(__get_os_codename)"; }
reload() {
  local profile_dir="\\\$(__profile_dir)"
  printf "Loading '%s' ...\n" "\\\$profile_dir"
  if [ -d "\\\$profile_dir" ]; then
    i=0
    for i in \\\${profile_dir}/*.sh; do
      if [ -r \\\$i ]; then
        . \\\$i
      fi
    done
    unset i
  fi
}
reload
EOT

cat <<EOT >>/root/.profile

if [ -d "\\\$HOME/.local/$7/bin" ] ; then
  PATH="\\\$HOME/.local/$7/bin:\\\$PATH"
fi
EOT

  if equals "\$TARGET_OS_FLAVOR" "debian" ; then
    cat <<EOT >"\$PROFILE_DIR/01-ls-colors.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

export SHELL
export LS_OPTIONS='--color=auto'
eval "\\\$(dircolors)"
alias ls='ls \\\$LS_OPTIONS'
alias ll='ls \\\$LS_OPTIONS -alhF'
alias la='ls \\\$LS_OPTIONS -hA'
alias l='ls \\\$LS_OPTIONS -lhA'
EOT

  cat <<EOT >"\$PROFILE_DIR/01-grep-colors.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
EOT
  fi
}

__cleanup_deps_caches() {
  # Clean caches
  apt-get clean
  rm -rf /var/lib/apt/lists/*
  __apt_update
}

__configure_xdgutils() {
  # Install helper tools (xdg-utils will install tzdata as a dependency)
  apt-get install -y --upgrade xdg-utils
  ln -fs "/usr/share/zoneinfo/\${TZ}" /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata
  __cleanup_deps_caches
}

__configure_locale() {
  apt-get install -y --upgrade locales
  sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \\
  touch /usr/share/locale/locale.alias && \\
  locale-gen en_US.UTF-8 en_CA.UTF-8 && \\
  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
  update-locale LANG=en_US.UTF-8
  # Export locale env vars
  # Do this if no using update-locale, in order to configure locale only for the user
  cat <<EOT >>/etc/profile.d/01-locale-fix.sh

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
EOT
}

__install_brew_docker() {
  if has brew; then
    # Brew packages
    brew install docker docker-compose
  else
    print_debug "Homebrew is not configured."
  fi
}

__install_brew_pkgs() {
  if has brew; then
    # Brew packages
    brew install tfenv k9s kube-ps1 pre-commit aws-vault
    # brew install gh vault awscli
  fi
  if has tfenv; then
    # Configure latest version of terraform
    tfenv use
    # Configure terraform bash completions
    terraform -install-autocomplete 2>/dev/null || (terraform -uninstall-autocomplete && terraform -install-autocomplete)
  fi
  if has mdless; then
    mdless --syntax 2>/dev/null
  fi
}

__install_extra_pkgs() {
  if has brew; then
    # Brew packages
    brew install mdless pygments
  fi
  if has mdless; then
    mdless --syntax 2>/dev/null
  fi
}

__configure_homebrew() {
  if has curl ; then
    # Install Homebrew
    bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Update path
    eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  __install_brew_pkgs
  # __install_extra_pkgs
}

__install_crypto() {
  apt-get install -y --upgrade gpg pass
  __cleanup_deps_caches
}

__configure_crypto() {
  __install_crypto
  __init_gpg
  __init_pass
  cat <<EOT >"\$PROFILE_DIR/01-aws-vault.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

export AWS_VAULT_BACKEND=pass
EOT
}

detect_docker() { has dockerd >/dev/null || return \$?; }
detect_docker_compose() { has docker-compose >/dev/null || return \$?; }
detect_docker_compose_cmd() {
  detect_docker_compose && echo "docker-compose" && return 0
  docker help | grep -w compose >/dev/null && echo "docker compose" && return 0
  echo >&2 "failed to detect docker compose / docker-compose command"
  return 1
}

__install_docker_apt_repo_old() {
  curl -fsSL "https://download.docker.com/linux/\$DISTRO/gpg" | apt-key add -
  add-apt-repository \\
    "deb [arch=\$(dpkg --print-architecture)] https://download.docker.com/linux/\$DISTRO \\
    \$(lsb_release -cs) stable"
}

__install_docker_apt_repo_new() {
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/\$DISTRO/gpg" | gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \\
    "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/\$DISTRO \\
    \$VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
}

__install_docker_debian_like() {
  apt-get remove -y docker docker-engine docker.io containerd runc || true
  __apt_update true
  apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  local major=""
  if equals "\$DISTRO" "ubuntu"; then
    major="\$(echo "\$DISTRO_VERSION" | awk -F. '{print \$1}')"
    if [ "\$major" -ge "22" ]; then
      __install_docker_apt_repo_new
    else
      __install_docker_apt_repo_old
    fi
  elif equals "\$DISTRO" "debian"; then
    if [ "\$DISTRO_VERSION" -ge "12" ]; then
      __install_docker_apt_repo_new
    else
      __install_docker_apt_repo_old
    fi
  else
    __install_docker_apt_repo_old
  fi
  apt-get update # dont use __apt_update since we must update the newly added apt repo
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

__install_docker() {
  if equals "\$DISTRO" "ubuntu" || equals "\$DISTRO" "debian"; then
    __install_docker_debian_like
  else
    printf "%s\n%s\n" \\
      "Warning: Distribution \$DISTRO not yet supported for Docker-in-Yolo." \\
      "Will attempt to treat like Debian." >&2
    __install_docker_debian_like
  fi
}

__install_docker_compose() {
  if value "\$DISTRO" && equals "\$DISTRO" "$8" ; then
    if value "\$TARGETARCH" && value "\$TARGET_OS"; then
      printf "%s %s\n" "Detected architecture is" "\$TARGETARCH"
      curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\${TARGET_OS}-\${TARGETARCH}" -o /usr/local/bin/docker-compose
    fi
  fi
  chmod +x /usr/local/bin/docker-compose
}

__install_apt_docker() {
  if ! detect_docker; then
    printf "%s. %s.\n" "Docker Engine is missing" "Attempting to install"
    __install_docker && dockerd --version
  fi
  if ! detect_docker_compose_cmd; then
    printf "%s. %s.\n" "Docker Compose Plugin is missing" "Attempting to install"
    __install_docker_compose && docker compose version
  fi
  __cleanup_deps_caches

  if detect_docker_compose_cmd; then
    cat <<EOT >"\$PROFILE_DIR/01-docker-compose.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

alias docker-compose='docker compose'
EOT
  fi
}

__configure_docker() {
  # __install_brew_docker
  __install_apt_docker
}

__install_gh() {
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --yes --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo \\
    "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages \\
    stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  __apt_update
  apt-get install -y --upgrade gh
  __cleanup_deps_caches
}

__install_vault() {
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --yes --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
  ! gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
  echo \\
    "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main" | \\
    tee /etc/apt/sources.list.d/hashicorp.list
  __apt_update
  apt-get install -y --upgrade vault
  # Reinstall fixes "/usr/bin/vault: Operation not permitted"
  apt-get install -y --reinstall vault
  # Configure vault bash compeletions
  vault -autocomplete-install 2>/dev/null || (vault -autocomplete-uninstall && vault -autocomplete-install)
  __cleanup_deps_caches
}

__install_awscli() {
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \\
    unzip -o awscliv2.zip && \\
    ./aws/install --update && \\
    rm -rf ./aws
}

__configure_aws() {
  __install_awscli
  cat <<EOT >"\$PROFILE_DIR/01-aws.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

export AWS_CONFIG_FILE="\\\${AWS_CONFIG_FILE:-\\\$HOME/.aws/\\\$YOLO_DOMAIN/config}"
EOT
}

__configure_python_tools() {
  if has pipx; then
    pipx install virtualenv
  fi
}

__install_devel_pkgs() {
  apt-get install -y --upgrade lsb-release python3-pip python3-venv npm yq miller telnet iputils-ping vim sudo dateutils
  __cleanup_deps_caches
}

__configure_dev_tools() {
  __install_devel_pkgs
  __configure_homebrew
  __configure_python_tools
  __configure_crypto
  __install_gh
  __configure_docker
  __install_vault
  __configure_aws
  __cleanup_deps_caches
}

__install_base_pkgs() {
  # Install basic tools
  # apt-get install -y --upgrade curl git nano
  apt-get install -y --upgrade build-essential apt-utils curl wget file git gh nano make jq bash-completion ca-certificates procps openssl zip gosu
  __cleanup_deps_caches
}

configure_deps() {
  __cleanup_deps_caches
  __install_base_pkgs
  __configure_xdgutils
  __configure_locale
  __configure_profile
  __configure_dev_tools
  __configure_pam
  __cleanup_deps_caches
}

__git_config() {
  cat <<EOT >"\$PROFILE_DIR/01-git-config.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

export GIT_CONFIG_FULL_NAME="\\\${GIT_CONFIG_FULL_NAME:-$GIT_CONFIG_FULL_NAME}"
export GIT_CONFIG_EMAIL="\\\${GIT_CONFIG_EMAIL:-$GIT_CONFIG_EMAIL}"
export GIT_CONFIG_USERNAME="\\\${GIT_CONFIG_USERNAME:-$GIT_CONFIG_USERNAME}"

git config --global user.name "\\\${GIT_CONFIG_FULL_NAME}"
git config --global user.email "\\\${GIT_CONFIG_EMAIL}"
git config --global user.username "\\\${GIT_CONFIG_USERNAME}"
git config --global core.pager "less -S"
git config --global core.editor "\\\${EDITOR}"
git config --global color.diff auto
git config --global init.defaultBranch main
git config --global pull.rebase true
EOT
}

__ssh_config() {
  exists $SSH_CONFIG_PREFIX/\$YOLO_DOMAIN || mkdir -p $SSH_CONFIG_PREFIX/\$YOLO_DOMAIN
  ! exists $SSH_CONFIG_PREFIX/\$YOLO_DOMAIN/config || cp $SSH_CONFIG_PREFIX/\$YOLO_DOMAIN/config $SSH_CONFIG_PREFIX/\$YOLO_DOMAIN/config.old
  ! exists ~/.ssh/config || cp ~/.ssh/config ~/.ssh/config.old

  cat <<EOT >"\$PROFILE_DIR/01-ssh-config.sh"
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

if [ -d $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN ]; then
  mkdir -p $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN
  key_count=0
  key_count=\\\$(ls -1 $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN | grep --color=never -o id_ed25519.fingerprint | wc -l)
  if [ "\\\${key_count}" -lt 1 ]; then
    printf "\033[93m>\033[0m Generating ssh ed25519 keypair with empty password ...\n\033[96;1m%s\033[0m\n" "ssh-keygen -t ed25519 -C '\\\${EMAIL}' -f $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_ed25519 -N ''"
    ssh-keygen -t ed25519 -C "\\\${EMAIL}" -f $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_ed25519 -N "" > $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_ed25519.fingerprint && cat $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_ed25519.pub
  fi
  key_count=0
  key_count=\\\$(ls -1 $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN | grep --color=never -o id_rsa.fingerprint | wc -l)
  if [ "\\\${key_count}" -lt 1 ]; then
    printf "\033[93m>\033[0m Generating ssh rsa keypair with empty password ...\n\033[96;1m%s\033[0m\n" "ssh-keygen -t rsa -b 4096 -C '\\\${EMAIL}' -f $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_rsa -N ''"
    ssh-keygen -t rsa -b 4096 -C "\\\${EMAIL}" -f $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_rsa -N "" > $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_rsa.fingerprint && cat $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_rsa.pub
  fi
  unset key_count
fi

  cat <<EOS >$SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/config
Host github.com
  HostName github.com
  User git
  AddKeysToAgent yes
  IgnoreUnknown UseKeychain
  IdentityFile $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/id_ed25519
EOS

  cat <<EOS >~/.ssh/config
Include $SSH_CONFIG_PREFIX/\\\$YOLO_DOMAIN/config
EOS
EOT
}

__tailscaled_daemon() {
  # Start tailscaled daemon in background
  if ! tailscaled_pid 2>/dev/null; then
    ! exists ~/.local/$7/tailscaled.log || mv ~/.local/$7/tailscaled.log ~/.local/$7/tailscaled.log.bak
    tailscaled --state=mem: >~/.local/$7/tailscaled.log 2>&1 &
  fi
}

__require_tailscale() {
  if ! has tailscale; then
    # Install tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
}

generate_profile() {
  __git_config
  __ssh_config

  cat <<EOT >"\$PROFILE_DIR/42-profile.$7.sh"
# This file was generated by $SCRIPT_FILENAME
# YOU MAY EDIT THIS FILE BY HAND -- CHANGES WILL BE PERSISTED
# IF THE FILE IS DELETED IT WILL BE AUTOMATICALLY REGENERATED

C_DEFAULT=\\\$'\033[00m'; C_BOLD=\\\$'\033[01m'; C_REVERSE=\\\$'\033[07m'
C_RED=\\\$'\033[00;31m'; C_GREEN=\\\$'\033[00;32m'; C_YELLOW=\\\$'\033[00;33m'
C_BLUE=\\\$'\033[00;34m'; C_PURPLE=\\\$'\033[00;35m'; C_CYAN=\\\$'\033[00;36m'
C_RED_BOLD=\\\$'\033[01;31m'; C_GREEN_BOLD=\\\$'\033[01;32m'; C_YELLOW_BOLD=\\\$'\033[01;33m'
C_BLUE_BOLD=\\\$'\033[01;34m'; C_PURPLE_BOLD=\\\$'\033[01;35m'; C_CYAN_BOLD=\\\$'\033[01;36m'

# Requires 'FiraCode Nerd Font Mono' ... https://github.com/ryanoasis/nerd-fonts/releases
# https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
UNI_LINUX_LOGO=; UNI_UBUNTU_LOGO=; UNI_UBUNTU_DARK_LOGO=; UNI_DEBIAN_LOGO= UNI_APPLE_LOGO=; UNI_WINDOWS_LOGO=
UNI_AWS=; UNI_TERRAFORM=; UNI_GIT=; UNI_GIT_ALT=; UNI_REPOSITORY=󰳏; UNI_CHEVRON_RIGHT=󰅂

export EDITOR="\$VISUAL"
export GIT_EDITOR="\$VISUAL"
export TERM="\$TERM"

if [ -n "$7" -a -d "~/.local/$7" ]; then
  HISTFILE="~/.local/$7/.bash_history"
fi

quit() { printf "🤖 %s 🤖\n" "Klaatu barada nikto"; }
trap quit EXIT

# 🚨
control_c() {
  local err="\\\$?"
  printf "\n⛔ \\\$C_RED_BOLD✗\\\$C_DEFAULT \\\$C_RED(%s)\\\$C_DEFAULT \\\$C_BOLD%s\\\$C_DEFAULT ⛔" "\\\$err" "Operation cancelled by user"
  # To fully exit the script, use 'exit' instead of 'return'
  return \\\$err;
}
trap control_c SIGINT SIGTERM SIGHUP

__ps1_color() {
  local _PS1_OPEN_ESC=\$'\001'
  local _PS1_CLOSE_ESC=\$'\002'
  local _PS1_FG="\\\${1:-\\\$C_DEFAULT}"
  echo "\\\${_PS1_OPEN_ESC}\\\${_PS1_FG}\\\${_PS1_CLOSE_ESC}"
}

load_env() {
  ! exists ~/.local/$7/.env || . ~/.local/$7/.env
  ! exists ~/.env || . ~/.env
}

configure_platform_deps() {
  if [ ! -f ~/.$7.platform ]; then
    if ! exists ~/.local/$7/kpv3; then
      if has git ; then
        exists ~/.local/$7 || mkdir -p ~/.local/$7 && cd ~/.local/$7
        (! gh_login || git clone https://github.com/liatrio/k8s-platform-v3-monorepo.git ~/.local/$7/kpv3)
      fi
    fi
    if ! exists ~/kpv3 && exists ~/.local/$7/kpv3 ; then
      exists ~/kpv3 || ln -s ~/.local/$7/kpv3 ~/kpv3
    fi
    if exists ~/kpv3 ; then
      if has make ; then
        if ! exists  ~/.kpv3-cli/bin/kpv3-cli || ! exists ~/.kube/k8s-platform-v3 ; then
          echo
          (cd ~/.local/$7/kpv3 && make && (echo; echo "Dependency configuration complete!"))
        fi
      fi
    fi
    echo "\$(date -u +%Y-%m-%dT%T)" > ~/.$7.platform
  fi
}

connect_tailscale() {
  # Connect to Tailscale if not already logged in
  if ! tailscale status > /dev/null; then
    printf "%s\n" "Connecting Tailscale VPN (sign in via Liatrio Google SSO)"
    (tailscale up --accept-routes)
  fi
}

configure_platform() {
  if [ -z "\\\$1" -o "\\\$1" != "$7" ]; then
    connect_tailscale
    (! is \\\$YOLO_PLATFORM_GH_CONNECT || gh_login)
    configure_platform_deps
    if exists ~/.kpv3-cli/bin/kpv3-cli ; then
      # Set up platform config if not already done
      has kpv3-cli || source <(~/.kpv3-cli/bin/kpv3-cli source)
    fi
    if has kpv3-cli ; then
      if ! exists ~/.kube/k8s-platform-v3 ; then
        printf "\n%s\n\n" "Configuring Kubernetes (sign in via Liatrio GitHub)"
        (kpv3-cli --headless kubeconfig -w)
      fi
      if exists ~/.kube/k8s-platform-v3 ; then
        printf "\n🏁 %s 🏁\n" "Platform setup complete"
        printf "• %s\n" "Run 'k9s' (or 'kubectl' etc.) to interact with platform resources."
        printf "\n🎉 %s 🎉\n" "Happy Platforming"
      fi
    fi
  fi
}

# Show current git branch for ps1 display
# https://www.baeldung.com/linux/bash-prompt-git
parse_git_branch() {
  local result=\\\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/')
  [ -z "\\\$result" ] || echo \\\$result
}

# aws_ps1 -- to let me know if I have any overriding AWS Env variables Set
aws_ps1() {
  local aws_prompt="\\\${AWS_DEFAULT_PROFILE:-read-only}"
  local aws_text="aws"
  ! is "\\\$PS1_NERD" || aws_text="\\\$UNI_AWS"
  [ -z "\\\$AWS_REGION" ] || aws_prompt+=": AWS_REGION: \\\$AWS_REGION "
  [ -z "\\\$AWS_ACCESS_KEY_ID" ] || aws_prompt+=": AWS_ACCESS_KEY_ID is set"
  echo "(\\\$(__ps1_color \\\$C_BOLD)\\\${aws_text}\\\$(__ps1_color)|\\\$(__ps1_color \\\$C_YELLOW)\\\${aws_prompt}\\\$(__ps1_color))"
}

cloud_ps1() {
  local cloud_prompt="" _cloud_prompt=""
  if is "\\\$PS1_CLOUD_PROMPT"; then
    if has aws_ps1 ; then
      _cloud_prompt="\\\$(aws_ps1)"
      cloud_prompt+="\\\$_cloud_prompt"
    fi
    if has kube_ps1 ; then
      _cloud_prompt="\\\$(kube_ps1)"
      [ -z "\\\$_cloud_prompt" ] || cloud_prompt+=":"
      cloud_prompt+="\\\$_cloud_prompt"
    fi
    [ -z "\\\$cloud_prompt" ] || cloud_prompt="[\\\${cloud_prompt}]:"
  fi
  echo "\\\$cloud_prompt"
}

git_ps1() {
  local git_prompt="" _git_prompt="\\\$(parse_git_branch)" git_brand="" git_prefix=""
  if is \\\$PS1_GIT_PROMPT ; then
    ! is "\\\$PS1_NERD" || git_brand="\\\$UNI_GIT "
    ! is "\\\$PS1_GIT_PREFIX" || git_prefix="git:"
    git_prompt="\\\$(__ps1_color)\\\$(__ps1_color \\\$C_PURPLE)\\\$git_prefix(\\\$(__ps1_color \\\$C_BOLD)\\\$git_brand\\\$(__ps1_color)\\\$(__ps1_color \\\$C_PURPLE)\\\$_git_prompt)\\\$(__ps1_color)"
    [ -z "\\\$_git_prompt" ] && git_prompt="\\\$_git_prompt" || git_prompt=" \\\$git_prompt"
    echo "\\\$git_prompt"
  fi
}

__ps1_prompt_status() {
  local last_err="\\\$1" ps1_prompt_status=""
  if is "\\\$PS1_COMMAND_EXIT_STATUS"; then
    [ -z "\\\$last_err" -o "\\\$last_err" = "0" ] && \\\\
      ps1_prompt_status=" \\\$(__ps1_color \\\$C_GREEN)\\\${checkmark_bold}\\\$(__ps1_color)" || \\\\
      ps1_prompt_status=" \\\$(__ps1_color \\\$C_RED_BOLD)\\\${xmark_bold}\\\$(__ps1_color) \\\$(__ps1_color \\\$C_RED)(\\\$last_err)\\\$(__ps1_color)"
      echo "\\\$ps1_prompt_status"
  fi
}

__venv_prefix() {
  if value "\\\$VIRTUAL_ENV" && exists \\\$VIRTUAL_ENV ; then
    printf "(\\\$(basename \\\$VIRTUAL_ENV)) "
  fi
}

__ps1_prefix() {
  local ps1_prefix="" ps1_branding="" _ps1_branding_logo="\\\${PS1_NERD_BRANDING_LOGO:-""}"
  if is "\\\$PS1_NERD"; then
    if [ -n "\\\$_ps1_branding_logo" ]; then
      _ps1_branding_logo="\\\${PS1_NERD_BRANDING_LOGO}_LOGO"
      [ -z "\\\${!_ps1_branding_logo}" ] || \\\\
        ps1_branding="\\\$(__ps1_color \\\$C_CYAN)\\\${!_ps1_branding_logo}\\\$(__ps1_color) "
    fi
  fi
  printf "\\\${ps1_branding}\\\$(__venv_prefix)"
}

__ps1_update() {
  local last_err="\\\$1" checkmark=✓ xkmark=✗ checkmark_bold=✔ xmark_bold=✘ arrow_right=➜
  local ps1_prompt=' \\\\$ ' ps1_prompt_status="\\\$(__ps1_prompt_status \\\$last_err)"
  ps1_prompt="\\\$ps1_prompt_status\\\$ps1_prompt"
  if is "\\\$PS1_NERD"; then
    if is "\\\$PS1_NERD_CHEVRON_PROMPT" ; then
      ps1_prompt="\\\$ps1_prompt_status \\\$(__ps1_color \\\$C_GREEN_BOLD)\\\$UNI_CHEVRON_RIGHT\\\$(__ps1_color) "
    fi
  fi
  if ! is "\\\$PS1_NERD_CHEVRON_PROMPT" && is "\\\${PS1_ARROW_PROMPT:-true}"; then
    ps1_prompt="\\\$ps1_prompt_status \\\$(__ps1_color \\\$C_CYAN_BOLD)\\\$arrow_right\\\$(__ps1_color) "
  fi
  # Assumes color_prompt
  local ps1_line_1='\\\$(__ps1_prefix)\\\$(cloud_ps1)\\\${debian_chroot:+(\\\$debian_chroot)}\\\$(__ps1_color \\\$C_CYAN_BOLD)\u\\\$(__ps1_color)@\\\$(__ps1_color \\\$C_GREEN_BOLD)\h\\\$(__ps1_color)'
  local ps1_line_2='\\\$(__ps1_color \\\$C_BLUE_BOLD)\w\\\$(__ps1_color)\\\$(git_ps1)'\\\$ps1_prompt
  is "\\\$PS1_MULTILINE" && \\\\
    PS1=\\\$ps1_line_1'\n'\\\$ps1_line_2 || \\\\
    PS1=\\\$ps1_line_1':'\\\$ps1_line_2
  ! is "\\\$PS1_NEWLINE" || PS1='\n'\\\$PS1
}

__prompt_command() {
  local last_err=\\\$?
  set -a
  load_env
  set +a >/dev/null
  __ps1_update \\\$last_err
  ! has _kube_ps1_prompt_update || _kube_ps1_prompt_update
}

__mygit() {
  local git_dir="\\\$1"
  shift
  GIT_DIR="\\\${GIT_DIR:-\\\${git_dir}}" git "\\\$@"
}

local_versioning() {
  local git_dir=~/.local/$7/.git
  alias mygit='GIT_DIR='"\\\${GIT_DIR:-\\\${git_dir}}"' __mygit '"\\\$git_dir"
  exists "\\\$git_dir/config" || (__mygit "\\\$git_dir" init)
}

profile_main() {
  # Load .env files
  load_env

  # Configure local version control
  local_versioning

  # Configure Homebrew in PATH
  eval "\\\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  # Configure Platform
  ! is \\\$YOLO_PLATFORM || configure_platform "\\\$1"

  # Configure kube-ps1 dependency
  . "\\\$(brew --cellar kube-ps1)/\\\$(ls -1 \\\$(brew --cellar kube-ps1) | tail -1)/share/kube-ps1.sh"

  # Configure aws bash compeletions
  complete -C /usr/local/bin/aws_completer aws

  # Configure git bash compeletions
  ! exists ~/.git-completion.bash || . /usr/share/bash-completion/completions/git

  cd ~
}

profile_main "\\\$@"

# Configure PROMPT_COMMAND
_PROMPT_COMMAND_DEFAULT=\\\$PROMPT_COMMAND
PROMPT_COMMAND=__prompt_command
_PROMPT_COMMAND=\\\$PROMPT_COMMAND

# Configure PS1
_PS1_DEFAULT=\\\$PS1
__ps1_update
_PS1=\\\$PS1
EOT

  exists ~/.local/$7/.env || cat <<EOT >~/.local/$7/.env
# This file was generated by $SCRIPT_FILENAME
# YOU MAY EDIT THIS FILE BY HAND -- CHANGES WILL BE PERSISTED
# IF THE FILE IS DELETED IT WILL BE AUTOMATICALLY REGENERATED

# All YOLO_PLATFORM options require:
# 1. YOLO_PLATFORM is enabled

# Configure tailscale, platform dependencies, and platform environment (default: false)
# YOLO_PLATFORM=true

# Prompt for Github login
# YOLO_PLATFORM_GH_CONNECT=true

# Enable the 'parse_git_branch' git prompt (default: false)
# PS1_GIT_PROMPT=true

# Enable aws_ps1 and kube_ps1 (default: false)
# PS1_CLOUD_PROMPT=true

# Prefix the 'parse_git_branch' section with 'git:' (default: false), e.g. git:(main)
# PS1_GIT_PREFIX=true

# Show the exit code status of the last command (default: false)
# PS1_COMMAND_EXIT_STATUS=true

# Splits the PS1 into 2 lines (default: false)
# PS1_MULTILINE=true

# Put an additional line break before the PS1 prompt (default: false)
# PS1_NEWLINE=true

# If PS1_NERD (see below) is not enabled, disable this setting to use standard PS1 ending ($ or # for root)
# PS1_ARROW_PROMPT=false

# All PS1_NERD options require:
# 1. PS1_NERD is enabled
# 2. A "nerd font" called 'FiraCode Nerd Font Mono' be enabled in terminal
# https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip

# Enable/Disable PS1_NERD (default: false)
# PS1_NERD=true

# Use a large chevron style cursor prompt (default: false)
# PS1_NERD_CHEVRON_PROMPT=true

# Prefix the prompt with a small branding logo (see font requirements)
# options: UNI_LINUX|UNI_UBUNTU|UNI_UBUNTU_DARK|UNI_DEBIAN|UNI_APPLE|UNI_WINDOWS
# PS1_NERD_BRANDING_LOGO=UNI_LINUX

# Example vault address using docker hostname (needs to be on the same docker network)
# export VAULT_ADDR='http://vault-server-dev:8200'
EOT

  if equals "\$TARGET_OS_FLAVOR" "debian" ; then
    cat ~/.env | grep PS1_NERD_BRANDING_LOGO || echo "PS1_NERD_BRANDING_LOGO=UNI_DEBIAN" >> ~/.local/$7/.env
  fi

  bash -l -s $7
  echo "\$(date -u +%Y-%m-%dT%TZ)" > /.$7.initialized
}

__tailscaled_pid() {
  cat <<EOT >/usr/local/bin/tailscaled_pid
#!/bin/sh
# This file was generated by $SCRIPT_FILENAME
# DO NOT EDIT THIS FILE BY HAND -- CHANGES WILL BE OVERWRITTEN

tailscaled_pid() {
  (
    local pid=0 uid="\\\${1:-""}" last_err=0 proc="" pgrep_opts=""
    [ -z "\\\$uid" ] || pgrep_opts="-U \\\$uid"
    pgrep_opts="\\\${pgrep_opts} -ar S tailscaled"
    set -- "\\\$pgrep_opts"
    proc=\\\$(pgrep \\\$@) || last_err=\\\$?
    if [ \\\$last_err -ne 0 ]; then echo \\\$pid; return \\\$last_err; fi
    pid=\\\$(echo "\\\$proc" | awk '{print \\\$1}') || return \\\$?
    echo \\\$pid
  ) >&2 # redirect all output to stderr
}

tailscaled_pid "\\\$@" 2>/dev/null
EOT
chmod +x /usr/local/bin/tailscaled_pid
}

client_message() {
  printf "\n🏄 \033[1m%s\033[0m 🏄\n\n\033[4m%s\033[0m\n\033[4m%s\033[0m\n%s    \033[1m%s\033[0m\n%s  \033[1m%s\033[0m\n\n%s\n\n\t%s\n\n%s\n\n\t%s\n\t%s\n\t%s\n\n%s\n\n\t%s\n\n%s\n(%s)\n\n\t%s\n\n%s\n(%s)\n\n\t%s\n\n%s\n\n\t%s\n\n%s '%s'\n\n\033[1m%s\033[0m\n\033[1m%s\033[0m\n\n\t%s\n\n\n%s\n%s '%s'\n" \\
    "Container initialized!" \\
    "With most docker commands, you may use either the container id, or container name ..." \\
    "For brevity, the examples below will only use the container name." \\
    "ID:" \\
    "\$(uname -n)" \\
    "Name:" \\
    "\$CONTAINER_NAME" \\
    "To \"exec\" into the container, run:" \\
    "docker exec -ti \$CONTAINER_NAME bash -l" \\
    "To stop, start, or restart the container, use the following syntax:" \\
    "docker stop \$CONTAINER_NAME" \\
    "docker start \$CONTAINER_NAME" \\
    "docker restart \$CONTAINER_NAME" \\
    "To view the container logs (this screen), simply run:" \\
    "docker logs -f \$CONTAINER_NAME" \\
    "To create a bridge network to which you can connect multiple containers, run:" \\
    "If the network exists, use a different name" \\
    "docker network create --driver bridge ${7}-net" \\
    "To connect or disconnect containers to (or from) the network, use the following syntax:" \\
    "After connecting, you will need to stop and then start your container" \\
    "\\$ docker network <connect|disconnect> <network> <container>" \\
    "For example:" \\
    "docker network connect \$CONTAINER_NAME ${7}-net" \\
    "For additional commands, please refer to" \\
    "https://docs.docker.com/reference/cli/docker/" \\
    "Local versioning has been configured using a custom GIT_DIR (~/.local/$7/.git) ..." \\
    "To interact with local versioning, use the following alias like the 'git' command:" \\
    "mygit" \\
    "[\$(build_time)]" \\
    "Press" \\
    "Ctrl+c"
}

build_time() {
  # ddiff hh:mm:ss format: -f%0H:%0M:%0S
  dateutils.ddiff \$(date -d \$BUILDSTART +'%Y-%m-%dT%T') \$(date -d \$(cat /.$7.initialized) +'%Y-%m-%dT%T')
}

__keep_alive() { while tailscaled_pid 2>/dev/null; do sleep 0; done; }
__spawn() {
  if ! tailscaled_pid 2>/dev/null; then
    # ! exists ~/.local/$7/tailscaled.log || mv ~/.local/$7/tailscaled.log ~/.local/$7/tailscaled.log.bak
    if ! is "\$TAILSCALED_IN_FOREGROUND" ; then
      printf "%s\n" "Spawning tailscaled"
      tailscaled --state=mem: >~/.local/$7/tailscaled.log 2>&1 &
    else
      set -- tailscaled --state=mem: >~/.local/$7/tailscaled.log 2>&1
      exec "\$@"
    fi
  fi
  if ! is "\$TAILSCALED_IN_FOREGROUND" ; then
    __keep_alive
    __spawn
  fi
}

main() {
  if ! exists /.$7.initialized ; then
    __init
    configure_deps
    generate_profile
    __require_tailscale

    if ! is "\$TAILSCALED_IN_FOREGROUND" ; then
      __tailscaled_daemon
    fi
  fi

  set +x
  client_message
  __spawn

  if ! is "\$TAILSCALED_IN_FOREGROUND" ; then
    wait -n
    exit \$?
  fi
}

main "\$@"

# We shouldn't reach this point
exec tail -f /dev/null
EOF

  chmod +x "$ENTRYPOINT_PATH") && \
  docker logs -f $(volume_mounts=(--mount type=volume,source="$YOLO_VOLUME_NAME",target=/root)
    bind_mounts=(-v "$ENTRYPOINT_PATH_PREFIX":"$(dirname $ENTRYPOINT_CONTAINER_PATH)")
    bind_mounts+=(-v "$YOLO_DATA_TARGET:$DATA_MOUNT_SRC")
    if test "${YOLO_VOLUME_MOUNT_LOCAL:-true}" = "true" ; then
      bind_mounts+=(-v "$YOLO_PROFILE_TARGET/$8/.local:/root/.local/$7")
    fi
    if test "${YOLO_VOLUME_MOUNT_PROFILE:-true}" = "true" ; then
      bind_mounts+=(-v "$YOLO_PROFILE_TARGET/$8/profile.$7.d:/etc/profile.$7.d")
    fi
    if test "${YOLO_VOLUME_MOUNT_SSH:-false}" = "true" ; then
      bind_mounts+=(-v "$YOLO_PROFILE_TARGET/.ssh:/root/.ssh")
    fi
    if test "${YOLO_VOLUME_MOUNT_PLATFORM:-false}" = "true" ; then
      bind_mounts+=(-v "$YOLO_PROFILE_TARGET/.kube:/root/.kube")
      bind_mounts+=(-v "$YOLO_PROFILE_TARGET/.aws:/root/.aws")
    fi
    if test "${YOLO_VOLUME_MOUNT_DOCKER_SOCK:-false}" = "true" ; then
      bind_mounts+=(-v /var/run/docker.sock:/var/run/docker.sock)
    fi
    if test "${YOLO_PRIVELEGED_CAPS:-true}" = "true" ; then
      priveleged_caps=(--cap-add=NET_ADMIN --device /dev/net/tun)
    fi
    set -x; docker run -d --name="$CONTAINER_NAME" --platform="$DOCKER_DEFAULT_PLATFORM" \
    -e "TZ=America/Chicago" -e "VISUAL=nano" -e "TERM=${TERM//256/}" \
    -e "GIT_CONFIG_USERNAME=${GIT_CONFIG_USERNAME}" -e "GIT_CONFIG_FULL_NAME=${GIT_CONFIG_FULL_NAME}" \
    -e "GIT_CONFIG_EMAIL=${GIT_CONFIG_EMAIL}" -e "YOLO_DOMAIN=${YOLO_DOMAIN}" \
    "${bind_mounts[@]}" "${volume_mounts[@]}" "${priveleged_caps[@]}" \
    -p "$PORT_EIGHT_THOUSAND:8000" -p "$PORT_EIGHTY_EIGHTY:8080" \
    --init --entrypoint "$ENTRYPOINT_CONTAINER_PATH" "$8:latest"
) | tee -a "$SCRIPT_DIR/${CONTAINER_NAME}.log" 2>&1

# Update port mappings of existing container
# https://www.baeldung.com/ops/assign-port-docker-container
# For the above guide to work on macOs,
# run the following image and navigate to '/var/lib/docker/containers/'
# docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh

# Quick stats
# docker ps --size --format \"table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Size}}\"

# Quick command
# YOLO_DATA_TARGET=~/Data/Liatrio sh ~/Tools/containerfy/yolo.sh
