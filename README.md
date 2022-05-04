# wanda
Bash script to set randomly picked wallpaper using [termux](https://github.com/termux/termux-app)

## Installation
```
pip install wanda
```

## Usage
```
wanda
wanda -t mountain
wanda -s wallhaven -t japan
```
`wanda -h` for more details

## Notes
- By default the source is [unsplash](https://unsplash.com).
- Some sources may have inapt images. Use them at your own risk.

## Supported sources

- [4chan](https://boards.4chan.org)
- [500px](https://500px.com)
- [artstation](https://artstation.com)
- [canvas](https://github.com/adi1090x/canvas)
- [imgur](https://imgur.com)
- local
- [reddit](https://reddit.com)
- [unsplash](https://unsplash.com)
- [wallhaven](https://wallhaven.cc)

## Automate
* To set wallpaper at regular intervals automatically:

0. Install (for android only):
```
termux-wake-lock
pkg in cronie termux-services nano
sv-enable crond
```
1. Edit crontab
```
crontab -e
```
2. Set your desired interval. For hourly:
```
@hourly wanda -t mountains
```
[(more examples)](https://crontab.guru/examples.html)

4. ctrl+o to save, ctrl+x to exit the editor

## Build
[python](https://www.python.org/downloads/) and [poetry](https://python-poetry.org/) are needed
```
git clone https://gitlab.com/kshib/wanda.git && cd wanda
poetry build
```

## Uninstall
```
pip uninstall wanda
```

## Shell
Older versions can be found [here (android)](https://gitlab.com/kshib/wanda/-/tree/sh-android) and [here (desktop)](https://gitlab.com/kshib/wanda/-/tree/sh-desktop)
They support [canvas](https://github.com/adi1090x/canvas/blob/master/canvas) and [earthview](https://earthview.withgoogle.com/) as source which have not yet been added to python version.

## Issues
There might be issues with certain sources or platforms.
For now, the script is only tested on Manjaro+KDE and Android+Termux
Feel free to raise issues if you encounter them.

## License
MIT
