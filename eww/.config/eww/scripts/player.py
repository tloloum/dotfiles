#!/usr/bin/env python3
"""Flux JSON du lecteur en cours pour eww (deflisten `player`).

Suit le lecteur MPRIS actif via `playerctl --follow` et émet une ligne JSON à
chaque changement : source, titre, artiste, statut, pochette (téléchargée dans
~/.cache/eww-media si c'est une URL web), boutons disponibles.
Sans lecteur MPRIS : on retombe sur le nom de l'appli qui joue du son (pactl).
"""
import hashlib
import json
import os
import subprocess
import urllib.parse
import urllib.request

CACHE = os.path.expanduser("~/.cache/eww-media")
SEP = "\x1f"
FIELDS = ["instance", "name", "status", "title", "artist", "art_url", "url"]
FMT = SEP.join("{{%s}}" % f for f in
               ["playerInstance", "playerName", "status", "title", "artist", "mpris:artUrl", "xesam:url"])
PRETTY = {"spotify": "Spotify", "firefox": "Firefox", "chromium": "Chromium",
          "chrome": "Chrome", "vlc": "VLC", "mpv": "mpv", "brave": "Brave"}
IGNORED_APPS = {"speech-dispatcher-dummy", "speech-dispatcher"}


def emit(data):
    print(json.dumps(data), flush=True)


def can(instance, prop):
    """Capacité MPRIS (CanGoNext, CanPause…) lue sur le bus D-Bus de session."""
    res = subprocess.run(
        ["busctl", "--user", "get-property", f"org.mpris.MediaPlayer2.{instance}",
         "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", prop],
        capture_output=True, text=True)
    return res.stdout.strip() == "b true"


def art_path(url):
    """Chemin local de la pochette ('' si aucune)."""
    if not url:
        return ""
    if url.startswith("file://"):
        path = urllib.parse.unquote(url[7:])
        return path if os.path.exists(path) else ""
    if url.startswith(("http://", "https://")):
        os.makedirs(CACHE, exist_ok=True)
        path = os.path.join(CACHE, hashlib.sha1(url.encode()).hexdigest() + ".img")
        if not os.path.exists(path):
            try:
                with urllib.request.urlopen(url, timeout=4) as r, open(path + ".part", "wb") as f:
                    f.write(r.read())
                os.replace(path + ".part", path)
            except OSError:
                return ""
        return path
    return ""


def playing_app():
    """Nom de la première appli qui envoie du son (pour les sources non MPRIS)."""
    res = subprocess.run(["pactl", "-f", "json", "list", "sink-inputs"],
                         capture_output=True, text=True)
    try:
        for stream in json.loads(res.stdout or "[]"):
            app = stream.get("properties", {}).get("application.name", "")
            if app and app not in IGNORED_APPS and not stream.get("corked"):
                return app
    except json.JSONDecodeError:
        pass
    return ""


def empty():
    return {"present": False, "source": playing_app(), "title": "", "artist": "",
            "status": "", "art": "", "instance": "",
            "can_prev": False, "can_next": False, "can_play": False}


def parse(line):
    values = line.rstrip("\n").split(SEP)
    if len(values) != len(FIELDS):
        return empty()
    d = dict(zip(FIELDS, values))
    title = d["title"] or os.path.basename(urllib.parse.unquote(d["url"])) or "Unknown"
    instance = d["instance"]
    return {
        "present": True,
        "source": PRETTY.get(d["name"].lower(), d["name"].capitalize()),
        "title": title,
        "artist": d["artist"],
        "status": d["status"],
        "art": art_path(d["art_url"]),
        "instance": instance,
        "can_prev": can(instance, "CanGoPrevious"),
        "can_next": can(instance, "CanGoNext"),
        "can_play": can(instance, "CanPause") or can(instance, "CanPlay"),
    }


def main():
    emit(empty())
    proc = subprocess.Popen(["playerctl", "--follow", "metadata", "--format", FMT],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    for line in proc.stdout:
        emit(parse(line) if line.strip() else empty())


if __name__ == "__main__":
    main()
