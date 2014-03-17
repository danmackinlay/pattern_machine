arpeggiate_by_numbers
=====================

machine learning harmony for fun and profit

see:

MIDI parsing:

* http://python.6.x6.nabble.com/midi-file-parser-td1066563.html
* https://groups.google.com/forum/#!msg/alt.sources/eRG2bL3Re-k/FvRLrRl0RiIJ
* http://web.mit.edu/music21/doc/index.html
* http://stackoverflow.com/a/14611850
* realtime output might even be possible thanks to http://portmedia.sourceforge.net/portmidi/doxygen/

Statistical underpinnings:

* this naive markov model still has lots of hairy bits. Questions:
  * can I get a better "base" point for my notes? e.g. choosing a "key"
  * can I somehow condition on more "control" variables?
  * can I use state transitions to estimate "consonance"?
* I'd kinda like to do this with a probabilistic graphical model, although the necessity of circular causation makes that messy. This Might work if the previous timestep were the nodes and the *next* were the leaf nodes

Practical business:

* the midi parsing is a little funky in that it separates out parts; this means that harmonic relationships are only considered between the current voice, not other voices/instruments