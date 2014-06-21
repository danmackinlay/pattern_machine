/*
Apocalypse

Ideas:
* Order<->chaos transitions
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* Bulk sample loading based on MIR
* the param mapping thing
* wiimote!
* feedme script too?
* ipad setup
* sync with team members
* control ableton with SC
* shared Dropbox folder
* feedback effects?
*/

// create an instance
n = NanoKontrol.new;

//assign actions
n.fader1.onChanged = {|val|
	"fader 1 changed".postln;
	val.postln;
};
n.topBt1.onPress   = {|val| "top button 1 pressed".postln; val.postln };
n.topBt1.onRelease = {|val| "top button 1 released".postln; val.postln };
n.knob1.onChanged  = {|val| "knob 1 changed".postln; val.postln };

//you can assign multiple items directly

//faders 1-9
n.faders.do{|fader, i|
	fader.onChanged= {|val| ("fader"+(i+1)).postln; val.postln }
};
