
/*
Python's MIDI support is bad, so we use the OSCulator conventions forward notes for it.
/midi/cc<number>/<channel>
Received when a control changed.
1 argument: the control value (0.0 to 1.0.)

/midi/note/<channel>
Received whenever a MIDI note occurs.
3 arguments: the pitch of the note (ranges from 0 to 127), its velocity (0.0 to 1.0) and a value representing the state of the note (1 when the note is on, 0 when it is off.)
*/
