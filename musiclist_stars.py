#!/usr/bin/env python2
# -*- coding: utf-8 -*-
from __future__ import print_function
import os
import operator
import re
import mpd  # pacman -S python2-mpd
MUSIC_ROOT = '/mnt/wasteland/Audio/Rips'
RATING_FILE = 'rating.txt'
def query(c, *items, **conditions):
    if conditions:
        # turn dict into flattened list, e.g.
        # {k1: v1, k2: v2} -> [k1, v1, k2, v2]
        cond = reduce(operator.add, conditions.items())
        results = c.find(*cond)
    else:
        results = c.listallinfo()
    yielded = set()
    for r in results:
        d = []
        for i in items:
            it = r.get(i)
            if isinstance(it, list):
                it = it[0]
            d.append(it)
        d = tuple(d)
        if all(d) and d not in yielded:
            yield d
        yielded.add(d)
def get_artists(c):
    a = [r[0] for r in query(c, 'albumartist')]
    return a
def get_rating(c, artist, date, album):
    r = query(c, 'file', albumartist=artist, date=date, album=album)
    path = next(r)[0]
    path = os.path.join(MUSIC_ROOT, path)
    path = os.path.dirname(path)
    if re.search("CD ?\d", path, flags=re.IGNORECASE):
        path = os.path.dirname(path)
    path = os.path.join(path, RATING_FILE)
    try:
        with(open(path)) as f:
            rating = f.readline().strip()
            return rating
    except IOError:
        return "-"
def main():
    c = mpd.MPDClient()
    host = os.environ.get('MPD_HOST', 'localhost')
    port = os.environ.get('MPD_PORT', '6600')
    pw = None
    if "@" in host:
        pw, host = host.split("@")
    c.connect(host, port)
    if pw is not None:
        c.password(pw)
    print("<html>")
    print("<head><meta charset=\"utf-8\"/><link rel=\"stylesheet\" href=\"//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css\"><style>body{background:#eee}table{margin:5em auto; max-width:56em; background: white;}</style></head>")
    print("<body>")
    print("<div class=\"table-responsive\">")
    print("<table id=\"music\" class=\"table table-bordered\">")
    print("<thead>")
    print("<tr><th>Artist</th><th>Year</th><th>Album</th><th>Rating</th></tr></thead><tbody>")
    for artist in sorted(get_artists(c), key=lambda v: (v.upper(), v[0].islower())):
        albums = sorted(query(c, 'date', 'album', albumartist=artist))
        print('<tr class=\"newartist\"><td rowspan="{0}">{1}</td>'.format(len(albums), artist))
        for i, (date, album) in enumerate(albums):
            rating = get_rating(c, artist, date, album)
            if rating == '-':
                output = ''
            else:
                split = rating.split('/')
                rate = split[0]
                max_rate = split[1]
                black_stars = '★' * int(rate)
                white_stars = '☆' * (int(max_rate) - int(rate))
                output = black_stars + white_stars

            # templating libaries ftw
            print("<td>{}</td>".format(date))
            print("<td>{}</td>".format(album))
            print("<td><font color=\"black\">{}</td>".format(output))
            print("</tr>")
    print("</table></div>")
if __name__ == '__main__':
    main()
