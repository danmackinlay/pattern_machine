FLustre
========

Spectrographic sound playground for the layperson

Sound output
============

I'm gonna use supercollider to do some synthesis, either granular time domain, or spectral domain if I get overexcited.

TODO:

* filter!
  * to harmonic multiples
  * or bandpass
* output compressor (this clips when there are any, many voices.)
* panning (right now in glorious mono)

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

Other questions
===============

* How to parameterise *height* of speaker
* on that note, what if children too short to access high frequencies use the system?
