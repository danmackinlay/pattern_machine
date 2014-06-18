//////////////////////////////////////////////
// SuperCollider Workshop @ Zürich

// Introduction

// sclang vs. scsynth

Server.default.boot // (s.boot)















// Sound Test
{ WhiteNoise.ar }.play
















// Cmd+. stoppt alles

// Arbeiten mit variablen"
a = 10
b = 100

a + b





x = { Saw.ar }.play
y = { SinOsc.ar }.play
z = { Pulse.ar }.play

x.free
















// Multichannel
x = { [WhiteNoise.ar, Pulse.ar, Saw.ar] }.play














// Scope
s.scope;
s.meter;














// objects in sclang and scsynth

x = { WhiteNoise.ar.dup }
x.play
x.free // !!!!!!!!!!

// correct way to do it:
x = { WhiteNoise.ar.dup }
y = x.play;
y.free














// Proxy Space
p = ProxySpace.push(s);  // push(s.boot)




~mysound.play
~mysound = { SinOsc.ar( MouseX.kr(200,800) ) * MouseY.kr(0,1) }
~mysound.stop
















~juan.play

~juan



~mysound.play

~mysound.fadeTime = 8

~mysound = { [SinOsc.ar(200), SinOsc.ar(220), SinOsc.ar(240), SinOsc.ar(260)] }

~mysound.stop

~mysound.play

~mysound.end(10)











// What is a NodeProxy?

// What is ProxySpace?



~juan.play
~juan = { SinOsc.ar(800) }










// Node Proxy Eigenschaften:

~mysound.fadeTime = 4;
~mysound.quant = 4;


~rhythmus1.play
~rhythmus2.play

~rhythmus1.quant = 4
~rhythmus2.quant = 4

~wurst1.play
~wurst1.quant = 4

~wurst1 = { Decay2.ar(Impulse.ar(4).dup) * SinOsc.ar(80) }
~rhythmus2 = { Decay2.ar(Impulse.ar(3).dup) * SinOsc.ar(120) }



ProxyMixer(p)











// Node Proxy Methoden:

~mysound.ar(2);  // initialize for audio with 2 channels
~mysound.play;   // monitoring on
~mysound.stop;   // monitoring off
~mysound.end(2); // fade out
~mysound.clear;  // stops and deletes everything




// Multichannel Expansion

ProxyMixer(p)


~juan.clear
~matthias.clear
~rhythmus1.clear
~rhythmus2.clear
~wurst1.clear
~mysound.clear


~mysound.play

~mysound = { [Impulse.ar(3), Impulse.ar(4)] }

~mysound = { Impulse.ar([1,1.5,2,3,4.1]) }

~mysound = { SinOsc.ar([200, 300, 400, 500, 600, 700, 800, 900, 1000]) * 0.1 }

~mysound = { SinOsc.ar((200,300..1100)) * 0.1 }

~mysound.fadeTime = 8

~mysound = { Splay.ar(SinOsc.ar(Array.rand(8, 40.0, 400.0))) * 0.5 }


~mysound = { Splay.ar(SinOsc.ar(Array.rand(8, 40.0, 400.0) * MouseX.kr(1,2))) * 0.5 }


~mysound = { Splay.ar(SinOsc.ar(Array.rand(8, 40.0, 400.0) * Line.kr(1,0,30))) * 1 }

~mysound.end(4)
~mysound.stop

































// Combining UGens

~mysound.fadeTime = 1
~mysound.play
~mysound = { SinOsc.ar( 440 ) }
~mysound = { SinOsc.ar( MouseX.kr(80, 800) ) }
~mysound = { SinOsc.ar( MouseX.kr(80, 800) * SinOsc.ar(40).range(0.75,1.25) ) }


























// Sound Synthesis techniques

// Additive
~mysound = { SinOsc.ar(200) + SinOsc.ar(400) + SinOsc.ar(600) + SinOsc.ar(800) * 0.1 }
~mysound = { SinOsc.ar([200, 400, 600, 800]).sum * 0.1 }
~mysound = { SinOsc.ar((200,400..4000)).sum * 0.1 }
~mysound = { SinOsc.ar(Array.rand(50, 200.0, 800.0)).sum * 0.1 }






















// Substractive
~mysound.play

~mysound = { WhiteNoise.ar }
~mysound = { BPF.ar(WhiteNoise.ar, LFNoise2.kr(1).range(200, 1800), 0.3) * 10 }

~mysound = { BPF.ar(WhiteNoise.ar, 300, 0.1) * 10 * LFPulse.kr(4) }

~mysound = { BPF.ar(WhiteNoise.ar, 800, 0.001) * 10 }


~mysound.fadeTime = 0
~mysound = { BPF.ar(Saw.ar(40), SinOsc.kr(2).range(80, 1400), 0.1) * 10 }

~mysound.stop




























// FM (Frequency Modulation)
~mysound = { SinOsc.ar( SinOsc.ar(MouseX.kr(2, 200)) * 100 + 880 ) }

~mysound.play





~mysound = { PMOsc.ar(880, MouseX.kr(2, 200), 10) }























// Ring Modulation
~mysound = { Saw.ar(220) * SinOsc.ar( MouseX.kr(20, 150) ) }

s.record
s.stopRecording






























// Tour of UGens











// Envelopes
// Linear envelope:
~mysound.play

~mysound = { SinOsc.ar( Line.ar(80, 800, 1) ) * Line.ar(1,0,1) }
































// EnvGen + Env
~mysound = { SinOsc.ar((60,120..1200).scramble) * EnvGen.ar(Env.perc(0.005,0.05), Impulse.kr((1,1.25..3))) }

































// wie ein modular synth:
~tempo.fadeTime = 8
~tempo = 4
~tempo = 4

~trigger = { Impulse.kr(~tempo.kr) }

~myfreq = { Line.kr(200, 1200, 60) }

~myfreq = { LFNoise2.kr(8).range(800, 1000) }

~myfreq = 200
~myfreq.fadeTime = 1

~mysound = { Pulse.ar(~myfreq.kr, MouseX.kr(0.1,0.5)).dup * EnvGen.ar(Env.perc(0.001, 0.1), ~trigger.kr) }

p.end(8)


~myfreq.end




























// external control
~mysound.play
~mysound = { SinOsc.ar(\freq.kr(440, 0)).dup }

~mysound.set(\freq, 200)


~mysound.gui


~mysound = { SinOsc.ar(\freq.kr(440, 0)).dup * EnvGen.ar(Env.perc(0.001, 0.1), ~trigger.kr) }




























// setting the control parameters
~mysound.set(\freq, 400)

// control from GUI
~mysound.gui




















// The big ProxyMixer
ProxyMixer(p);

























// Proxy Mapping
~random = { LFNoise0.kr(4).range(100, 1000) }
~triangle = { LFTri.kr(1/4).range(100, 1000) }




























~mysound = { SinOsc.ar(\freq.kr(400)) }
~mysound.gui

~mysound.map(\freq, ~random)
~mysound.map(\freq, ~triangle)
~mysound.unmap(\freq)



















// Mapping with ProxyMixer
ProxyMixer(p);























// Set parameters from a sequence
~mysound[0] = { MoogFF.ar(Pulse.ar(\freq.kr(440) * [1,1.5], 0.3), \freq.kr * 8, 3) }





~mysound[1] = \set -> Pbind(\freq, Pseq([200, 400, 800], inf), \dur, 1/4)

~mysound[2] = \set -> Pbind(\freq, Pseq([200, 400, 800]*2, inf), \dur, 1/3)

~mysound[2] = nil


//////////////////////////////////////////////////////////////



// Setter:
~mysound[1] = \set -> Pbind(\freq, Pseq([100, 150, 200], inf), \dur, 3/4)

// Filter:
~mysound[10] = \filter -> { |in| in + CombC.ar(in, 1, 1/2, 4) }






////////////////////////////////////////////////////////////////

~mysound[0] = { MoogFF.ar(Saw.ar(\freq.kr(440) * [1,2]), \freq.kr * 8, 3) * 2 * EnvGen.ar(Env.perc(0.001, 0.5), \t_trig.kr) }


~mysound[1] = \set -> Pbind(\t_trig, 1, \midinote, Place([60,[65,67,65],[70,72]] - 24, inf), \dur, 1/4)



~mysound[2] = \filter -> { arg in; FreeVerb.ar(in, 0.5, 0.5) }


~mysound[3] = \filter -> { arg in; in + CombC.ar(in, 1, 1/3, 2) }


~mysound[5] = \filter -> { arg in; GVerb.ar(in, 300, 30) }

~mysound[5] = nil
~mysound[2] = nil
~mysound[3] = nil

~mysound.end(5)
























// Further infos:
// supercollider.sf.net
// sccode.org
// rukano@gmail.com










