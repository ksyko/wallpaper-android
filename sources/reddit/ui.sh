#!/data/data/com.termux/files/usr/bin/bash
CONFIG_FILE=$SCRIPT_DIR/reddit/config
. "$CONFIG_FILE"
. "$SCRIPT_DIR/util.sh"

# sub
u_input=$(get_input radio "Reddit: Choose a subreddit"
"
iWallpaper,
MobileWallpaper,
Verticalwallpapers,
Amoledbackgrounds,
AnimePhoneWallpapers,
ComicWalls,
wallpaper+wallpapers
")
config_set "$CONFIG_FILE" "sub" "$u_input"

# sort
u_input=$(get_input radio "sort" "hot,new,rising,top,gilded")
config_set "$CONFIG_FILE" "sort" "$u_input"
