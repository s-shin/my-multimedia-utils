#!/bin/bash
set -eu

: ${MUSIC_DIR:="${HOME}/Music/iTunes/iTunes Media/Music"}

usage() {
  cat <<EOT
Usage: $0 [options] [<filter-regex>]

Options:
  -m <music-dir>   Source music directory.
  -o <output-dir>  Output directory. Default is cwd.
  -v               <filter-regex> as exclusive filter.

Environments:
  MUSIC_DIR="${MUSIC_DIR}"
EOT
}

log() { echo -ne "$(date +"%F %T") $*"; }
log.d() { log "[DEBUG] $*"; }
log.i() { log "[INFO] $*"; }
log.w() { log "[WARN] $*"; }
log.e() { log "[ERROR] $*"; }
logln() { log "$*\n"; }
logln.d() { log.d "$*\n"; }
logln.i() { log.i "$*\n"; }
logln.w() { log.w "$*\n"; }
logln.e() { log.e "$*\n"; }

abort() { >&2 log_e "abort: $*"; exit 1; }

# shellcheck disable=SC2120
confirm() {
  local msg="${1:-Continue?}";
  if (($# > 0)); then shift; fi
  local default="${1:-n}"
  log "[CONFIRM] $msg "
  case "$default" in
    y ) echo -n "[Y/n] ";;
    n ) echo -n "[y/N] ";;
    * ) abort "confirm: invalid argument";;
  esac
  local yn
  read -r yn
  case "${yn:=$default}" in
    Y* | y* ) return 0;;
    * ) return 1;;
  esac
}

opt_nargs=0
opt_music_dir="$MUSIC_DIR"
opt_output_dir=.
opt_re=""
opt_if_or_unless=if
opt_execute=false
while (($# > 0)); do
  case "$1" in
    -h | --help ) usage; exit 1;;
    -m ) opt_music_dir="$2"; shift;;
    -o ) opt_output_dir="$2"; shift;;
    -v ) opt_if_or_unless=unless;;
    -x ) opt_execute=true;;
    * )
      case $((++opt_nargs)) in
        1 ) opt_re="$1";;
        2 ) abort "too many arguments"
      esac
      ;;
  esac
  shift
done

abs_music_dir="$(cd "$opt_music_dir"; pwd)"
abs_output_dir="$(cd "$opt_output_dir"; pwd)"

targets="$(cd "$abs_music_dir"; find . -type d -mindepth 2 \
  | perl -ne "print $opt_if_or_unless /$opt_re/")"

logln.i "Archive targets:"
echo "$targets"
confirm

IFS_BK="$IFS"
IFS=$'\n'
for dir in $targets; do
  logln.i "Processing $dir..."
  artist="$(echo "$dir" | perl -ple 's#./([^/]+)/([^/]+)#$1#')"
  album="$(echo "$dir" | perl -ple 's#./([^/]+)/([^/]+)#$2#')"
  out_artist_dir="${abs_output_dir}/${artist}"
  out_album_archive="${out_artist_dir}/${album}.tar"
  mkdir -p "$out_artist_dir"
  if [[ -f "$out_album_archive" ]]; then
    logln.i '=> skipped (already exists)'
    continue
  fi
  if $opt_execute; then
    (cd "${abs_music_dir}/${artist}"; tar cvf "$out_album_archive" "${album}")
  else
    cat <<EOT
cd "${abs_music_dir}/${artist}"; tar cvf "$out_album_archive" "${album}"
EOT
  fi
done
IFS="$IFS_BK"

logln.i 'Done!'
