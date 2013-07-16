f_lustre
========

Spectrographic sound playground for the layperson

Visual component
================

Minimal speed requirements (mostly static image), so the simplest possible tool which could work is probably Processing.

Spectrogram
===========

Analyse within SC?

* [sox](http://stackoverflow.com/questions/9956815/generate-visual-waveform-from-mp3-wav-file-in-windows-2008-server/9956920#9956920)
* wouldn't it be nice to colorize this using a chromagram to indicate tonality?
SCMIR can generate chromograms, but drawing could be a total PITA. Hmm. Leave that one for later.

Touch inputs
============

* MSAremote can send touch data
* [Throng](https://code.google.com/p/throng/) can simulate, or play back recorded touch data
  * ThrongOSCDeck does recording/playback
  * Throng basic multiplexes multiple TUIO sources and aggregates IDs
* [Tongseng](https://github.com/fajran/tongseng) can do that with the trackpad
* [SETO](http://tuio.lfsaw.de/seto-details.shtml) is Till's SC implemention of TUIO 
