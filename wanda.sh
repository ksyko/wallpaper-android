#!/data/data/com.termux/files/usr/bin/bash

source="unsplash"
query=""
home="false"
lock="false"
version=0.36
no_results="No results for '$query'. Try another source/keyword"
user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"
tmp="$PREFIX/tmp"

usage() {
  echo "wanda ($version)"
  echo "Usage:"
  echo "  wanda [-s source] [-t search term] [-o] [-l] [-h]"
  echo "  -s  source      [un]splash,[wa]llhaven,[re]ddit,[lo]cal"
  echo "                  [4c]han,[ca]nvas,[ea]rthview,[im]gur"
  echo "                  [ar]tstation"
  echo "  -t  t           search term."
  echo "  -o  homescreen  set wallpaper on homescreen"
  echo "  -l  lockscreen  set wallpaper on lockscreen"
  echo "  -h  help        this help message"
  echo "  -u  update      update wanda"
  echo "  -v  version     current version"
  echo ""
  echo "Examples:"
  echo "  wanda"
  echo "  wanda -s ea"
  echo '  wanda -s un -t eiffel tower -ol'
  echo "  wanda -s lo -t folder/path -ol"
  echo "  wanda -s wa -t stars,clouds -ol"
  echo "  wanda -s 4c -t https://boards.4chan.org/wg/thread/7812495"
  echo "  wanda -s 4c -t "
}

set_wp_url() {
  validate_url
  if [ "$home" = "false" ] && [ "$lock" = "false" ]; then
    termux-wallpaper -u "$1"
  fi
  if [ "$home" = "true" ]; then
    termux-wallpaper -u "$1"
  fi
  if [ "$lock" = "true" ]; then
    termux-wallpaper -lu "$1"
  fi
  config_set "last_wallpaper_path" "$1"
  config_set "last_wallpaper_time" "$(date)"
}

set_wp_file() {
  if [ "$home" = "false" ] && [ "$lock" = "false" ]; then
    termux-wallpaper -f "$1"
  fi
  if [ "$home" = "true" ]; then
    termux-wallpaper -f "$1"
  fi
  if [ "$lock" = "true" ]; then
    termux-wallpaper -lf "$1"
  fi
  config_set "last_wallpaper_path" "$1"
  config_set "last_wallpaper_time" "$(date)"
}

validate_url() {
  if [ -z "$url" ]; then
    echo "$no_results"
    echo "url:$url"
    exit 1
  fi
  urlstatus=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$url")
  if [ "$urlstatus" != 200 ]; then
    echo "Failed to load url: $url. Status $urlstatus"
    exit 1
  fi
}

install_package() {
  convert -version 1>/dev/null
  if [ "$?" != 0 ]; then
    echo "$1 is required. Install required package now [y/n]?"
    read agree
    if [ "$agree" = "y" ] || [ "$agree" = "Y" ]; then
      pkg in "$2"
    fi
    exit 0
  fi
}

check_connectivity() {
  curl -s "https://detectportal.firefox.com/success.txt" 1>/dev/null
  if [ "$?" != 0 ]; then
    echo "Please check your internet connection and try again."
    exit 1
  fi
}

update() {
  check_connectivity
  res=$(curl -s "https://gitlab.com/api/v4/projects/29639604/repository/files/manifest.json/raw")
  latest_version=$(echo "$res" | jq --raw-output ".version")
  if (($(echo "$latest_version $version" | awk '{print ($1 > $2)}'))); then
    res=$(curl -s "https://gitlab.com/api/v4/projects/29639604/repository/files/manifest.json/raw")
    latest_version=$(echo "$res" | jq --raw-output ".version")
    res=$(curl -s "https://gitlab.com/api/v4/projects/29639604/releases/v$latest_version/assets/links")
    link=$(echo "$res" | jq --raw-output ".[].url")
    binary=$(basename "$link")
    curl -L "$link" -o "$binary"
    pkg in "./$binary"
    rm "$binary"
    wanda -h
  else
    echo "Already latest version ($version)"
  fi
}

### config editor ###
# https://stackoverflow.com/a/60116613
# https://stackoverflow.com/a/2464883
# https://unix.stackexchange.com/a/331965/312709
# thanks to ixz in #bash on irc.freenode.net
CONFIG_FILE="$PREFIX/etc/wanda.conf"
function config_set() {
  if [[ $2 == *"<CANCEL>"* ]]; then
    exit 0
  fi
  local file=$CONFIG_FILE
  local key=$1
  local val=${*:2}
  ensureConfigFileExists "${file}"
  if ! grep -q "^${key}=" "$file"; then
    printf "\n%s=" "${key}" >>"$file"
  fi
  chc "$file" "$key" "$val"
}

function ensureConfigFileExists() {
  if [ ! -e "$1" ]; then
    if [ -e "$1.example" ]; then
      cp "$1.example" "$1"
    else
      touch "$1"
    fi
  fi
}

function chc() {
  gawk -v OFS== -v FS== -e \
    'BEGIN { ARGC = 1 } $1 == ARGV[2] { print ARGV[4] ? ARGV[4] : $1, ARGV[3]; next } 1' \
    "$@" <"$1" >"$1.1"
  mv "$1"{.1,}
}

function config_get() {
  val="$(config_read_file "$CONFIG_FILE" "${1}")"
  if [ "${val}" = "__UNDEFINED__" ]; then
    val="$(config_read_file "$CONFIG_FILE".example "${1}")"
  fi
  printf -- "%s" "${val}"
}

function config_read_file() {
  (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR=__UNDEFINED__") | head -n 1 | cut -d '=' -f 2-
}
### ### ###

# main
while getopts ':s:t:huvdlo' flag; do
  case "${flag}" in
  s) source="${OPTARG}" ;;
  t) query="${OPTARG//\//%20}" ;;
  o) home="true" ;;
  l) lock="true" ;;
  h)
    usage
    exit 0
    ;;
  u)
    update
    exit 0
    ;;
  v)
    echo "wanda ($version)"
    exit 0
    ;;
  d)
    url=$(config_get "last_wallpaper_path")
    path="$HOME/Downloads/$(basename "$url")"
    curl -s "$url" -o "$path"
    echo "Saved to $path"
    ;;
  :)
    echo "The $OPTARG option requires an argument."
    usage
    exit 1
    ;;
  \?)
    echo "$OPTARG is not a valid option."
    usage
    exit 1
    ;;
  esac
done

case $source in
wallhaven | wa)
  check_connectivity
  res=$(curl -s "https://wallhaven.cc/api/v1/search?q=$query&ratios=portrait&sorting=random")
  url=$(echo "$res" | jq --raw-output ".data[0].path")
  set_wp_url "$url"
  ;;
unsplash | un)
  check_connectivity
  res="https://source.unsplash.com/random/1440x2560/?$query"
  url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$res")
  if [[ $url == *"source-404"* ]]; then
    echo "$no_results"
  fi
  set_wp_url "$url"
  ;;
local | lo)
  filepath=$(find "$HOME/storage/shared/$query" -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}' | shuf -n 1)
  set_wp_file "$filepath"
  ;;
canvas | ca)
  install_package "Imagemagick" "imagemagick"
  filepath="$tmp/canvas.png"
  . canvas
  case $query in
  1 | solid) solid ;;
  2 | linear) linear_gradient ;;
  3 | radial) radial_gradient ;;
  4 | twisted) twisted_gradient ;;
  5 | bilinear) bilinear_gradient ;;
  6 | plasma) plasma ;;
  7 | blurred) blurred_noise ;;
  *) randomize ;;
  esac
  set_wp_file "$filepath"
  rm -rf "$filepath"
  config_set "last_wallpaper_path" "canvas:$query"
  config_set "last_wallpaper_time" "$(date)"
  ;;
4chan | 4c)
  check_connectivity
  if [ -z "$query" ]; then
    echo "4chan requires a thread link."
    echo "$(wanda -h | grep 4chan)"
  fi
  board=$(echo "$query" | cut -d'/' -f4)
  image_host="https://i.4cdn.org/${board}/"
  api="${query/"boards.4chan.org"/"a.4cdn.org"}.json"
  res=$(curl -s "$api")
  posts=$(echo "$res" | jq '.[] | length')
  rand=$(shuf -i 0-$posts -n 1)
  post_image=$(echo "$res" | jq ".[][$rand].tim")
  # if post has no image, loop till post with image is found
  while [ "$post_image" = "null" ]; do
    rand=$(shuf -i 0-$posts -n 1)
    post_image=$(echo "$res" | jq ".[][$rand].tim")
  done
  post_exten=$(echo "$res" | jq --raw-output ".[][$rand].ext")
  url="${image_host}${post_image}${post_exten}"
  set_wp_url "$url"
  ;;
earthview | ea)
  install_package "xmllint" "libxml2-utils"
  check_connectivity
  slug=config_get "earthview_slug"
  if [[ -z $slug ]]; then
    slug=$(curl -s "https://earthview.withgoogle.com" | xmllint --html --xpath 'string(//a[@title="Next image"]/@href)' - 2>/dev/null)
  fi
  api="https://earthview.withgoogle.com/_api$slug.json"
  res=$(curl -s "${api}")
  url=$(echo "$res" | jq --raw-output ".photoUrl")
  slug=$(echo "$res" | jq --raw-output ".nextSlug")
  config_set "earthview_slug" "$slug"
  validate_url
  filepath="$tmp/earthview.jpg"
  curl -s "$url" -o "$filepath"
  mogrify -rotate 90 "$filepath"
  set_wp_file "$filepath"
  clean "$filepath"
  ;;
reddit | re)
  check_connectivity
  if [[ -z $query ]]; then
    api="https://old.reddit.com/r/MobileWallpaper+AMOLEDBackgrounds+VerticalWallpapers.json?limit=100"
  else
    api="https://old.reddit.com/r/MobileWallpaper+AMOLEDBackgrounds+VerticalWallpapers/search.json?q=$query&restrict_sr=on&limit=100"
  fi
  curl -s "$api" -A "$user_agent" -o "$tmp/temp.json"
  posts=$(jq --raw-output ".data.dist" < "$tmp/temp.json")
  rand=$(shuf -i 0-"$posts" -n 1)
  url=$(jq --raw-output ".data.children[$rand].data.url"< "$tmp/temp.json")
  while [[ $url == *"/gallery/"* ]]; do
    rand=$(shuf -i 0-$posts -n 1)
    url=$(cat "$tmp/temp.json" | jq --raw-output ".data.children[$rand].data.url")
  done
  set_wp_url "$url"
  ;;
imgur | im)
  check_connectivity
  if [[ -z $query ]]; then
    rand=$(($((RANDOM % 10)) % 2))
    if [ $rand -eq 1 ]; then
      api="https://old.reddit.com/r/wallpaperdump/search.json?q=mobile&restrict_sr=on&limit=100"
    else
      api="https://old.reddit.com/r/wallpaperdump/search.json?q=phone&restrict_sr=on&limit=100"
    fi
    curl -s "$api" -A $user_agent -o "$tmp/temp.json"
    posts=$(cat "$tmp/temp.json" | jq --raw-output ".data.dist")
    rand=$(shuf -i 0-"$posts" -n 1)
    url=$(cat "$tmp/temp.json" | jq --raw-output ".data.children[$rand].data.url")
    while [[ $url != *"/gallery/"* ]]; do
      rand=$(shuf -i 0-$posts -n 1)
      url=$(cat "$tmp/temp.json" | jq --raw-output ".data.children[$rand].data.url")
    done
  else
    url="https://imgur.com/gallery/$query"
  fi
  res=$(curl -A "$user_agent" -s "${url/http:/https:}" | xmllint --html --xpath 'string(//script[1])' - 2>/dev/null)
  clean=${res//\\\"/\"}
  clean=${clean/window.postDataJSON=/}
  clean=${clean/\\\'/\'}
  clean=$(sed -e 's/^"//' -e 's/"$//' <<<"$clean")
  posts=$(echo "$clean" | jq --raw-output ".image_count")
  rand=$(shuf -i 0-$posts -n 1)
  url=$(echo "$clean" | jq --raw-output ".media[$rand].url")
  set_wp_url "$url"
  ;;
artstation | ar)
  check_connectivity
  if [[ -z $query ]]; then
    artists=("huniartist" "tohad" "snatti" "aenamiart" "seventeenth" "andreasrocha" "slawekfedorczuk")
    i=0
    if [[ $(basename "$SHELL") == "zsh" ]]; then
      i=1
    fi
    query=${artists[$(($RANDOM % ${#artists[@]} + i ))]}
  fi
  api="https://www.artstation.com/users/$query/projects.json?page=1&per_page=50"
  res=$(curl -s -A "$user_agent" "${api}")
  rand=$(shuf -i 0-49 -n 1)
  id=$(echo "$res" | jq --raw-output ".data[$rand].id")
  res=$(curl -s -A "$user_agent" "https://www.artstation.com/projects/$id.json")
  url=$(echo "$res" | jq --raw-output ".assets[0].image_url")
  set_wp_url "$url"
  ;;
*)
  echo "Unknown source $source"
  usage
  ;;
esac
