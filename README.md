# Pico Sound Dj

Note: go to the [lexaloffle forum post](https://www.lexaloffle.com/bbs/?tid=146440) if you want more information on what is PSDJ and how to use it. This repo is public mostly for people wanting to look at the code, as it should be easier to read with the included comments and the split in multiple files than the exported cart.

<p align="center">
  <img src="https://github.com/romainchapou/readme-files/blob/main/psdj_cover.png?raw=true" />
</p>


Pico Sound Dj, or PSDJ for short, is an alternative to the base music editor of pico8. It supports the whole pico8 music specs, uses a grid oriented layout and a simple D-pad + O/X/start control scheme inspired by [LDSJ, a game boy music sequencer](https://www.littlesounddj.com/lsd/index.php). With it you can create music on the go using any handheld which has native support for pico8, and then use this music in your pico8 games!

Features everything you can do in the base pico8 music/SFX editor, adapted to a handheld friendly control scheme with support for multi editing.

[Watch the showcase on youtube :](https://www.youtube.com/watch?v=M26vbTBIBE0)

[![Video showcase](https://img.youtube.com/vi/M26vbTBIBE0/maxresdefault.jpg)](https://www.youtube.com/watch?v=M26vbTBIBE0)

For more information and to learn how to use PDSJ, check the forum post : https://www.lexaloffle.com/bbs/?tid=146440


# How to build from this repo

I would recommend downloading the cart from the lexaloffle website (see the installation section of the forum post), but if you wish to build PSDJ from the source files, you'll need to use [shrinko8](https://github.com/thisismypassport/shrinko8). Without it, the resulting cart exceeds the limit on the number of tokens allowed.

I use this build command :

```sh
$INSERT_PATH_TO_SHRINKO8/shrinko8.py psdj.p8 psdj_min.p8.png -M --no-minify-lines --no-minify-spaces --no-minify-rename --count
```

This will build PSDJ to a pico8 cart called `psdj_min.p8.png`.


## Credits

- [@thesailor](https://mastodon.social/@thesailordev) for the cover art
- [Little Sound DJ](https://www.littlesounddj.com/lsd/index.php) by Johan Kotlinski, which was a big design inspiration for the whole structure and button mappings of PSDJ
- [shrinko8](https://github.com/thisismypassport/shrinko8) by @thisismypassword, without which I wouldn't have been able to put as many features in PSDJ
- [This post on waveform instrument encoding](https://www.lexaloffle.com/bbs/?tid=45247) by @ridgek and the [pico8 wiki page on the memory layout for the music/sfx](https://pico-8.fandom.com/wiki/Memory#Music)
- https://learnlsdj.github.io/ for the cheat sheet design inspiration
