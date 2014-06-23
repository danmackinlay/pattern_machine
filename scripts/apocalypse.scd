/*
Apocalypse

Ideas:
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* Bulk sample loading based on MIR
* the param mapping thing
* wiimote!
* feedme script too?
* ipad setup
* sync with team members
* control ableton with SC
  * therefore, isolate MIDI output when necc
* shared Dropbox folder
* feedback effects?
* stateful algorithm to navigate through with wiimote
*/
////////
s=~serverboot.(prox:\local, device:\internal);
~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
~miditeacher = this.executeFile (~pmscripts +/+ "miditeach.scd").value;

(
fork{
	~control = Bus.control(s, 4);
	s.sync;
	~subcontrols = ~control.numChannels.collect(~control.subBus(_,1););

)

//////MIDI
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
)