# local.fm

#### little script to generate stats from mpdscribble's local history


# Screenshot
![local.fm](screenshot.png "local.fm in action")

# Features
* Generate Stats from mpdscribble log files
  + Most listenened Tracks
  + Most listenened Albums by Artist
  + Top Artists
* Ability to use Rockbox .scrobbler files
* Filter output by keyword

# Dependencies

* awk
* [mpdscribble](http://git.musicpd.org/cgit/master/mpdscribble.git/)
* [distribution](https://github.com/philovivero/distribution)

# Config

Configuration consists of 2 options only.

```
mpdscribble="path/to/mpdscribble-log"
rockbox="/path/to/mounted/rockbox/device"
```

