/*
stochastic cellular automata implementing harmonies
The model in this case comes from lasso regression on conditional note transitions in a corpus of midi files

TODO:
* swap note model
* multiple simultaneous onsets (actual cellular automata)
* dynamic default start note distribution
* handle multiple voices with shared note list
* favour central or distant notes
* have a bag of "virtual" notes here that constrain which other notes play
*/

Noteomata {
	var <>defA;
	var <>defB;
	var <>maxJump;
	var <>defaultNote;
	var <heldNotes;
	var <allNotes;
	var <maxAge=2;
	var <featureWidth=0.125;
	var <featureData;
	var <featureFns;
	var <nFeatures;
	
	*new {|a=1,b=0,maxJump=12,defaultNote|
		^super.newCopyArgs(a,b,maxJump,defaultNote?{60.rrand(72)}).init;
	}
	init {
		heldNotes = IdentityDictionary.new(128);
		allNotes = (0..127);
		featureFns = [
			this.square(_,0),
			this.square(_,1),
			this.square(_,2),
			this.square(_,4)];
		this.updateFeatures;
	}
	square {|x,center=0,width|
		width=width?featureWidth;
		^x.isCollection.if(
			{((x-center).abs<width).collect(_.binaryValue).asFloatArray},
			{((x-center).abs<width).binaryValue.asFloat}
		)
	}
	updateFeatures {
		featureData = featureFns.collect({|fn| fn.value(this.heldNotesArray)})
	}
	heldNotesArray {
		var arr = FloatArray.fill(128,0);
		heldNotes.keysValuesDo({|note, newness|
			arr[note]=newness;
		});
		^arr;
	}
	add {|i|
		heldNotes[i]=maxAge;
	}
	remove {|i|
		heldNotes.removeAt(i);
	}
	lowest{
		^heldNotes.keys.minItem ? 64;
	}
	highest{
		^heldNotes.keys.maxItem ? 64;
	}
	invLogit{|x=0,a,b|
		var e=((a?defA)*x+(b?defB)).exp;
		^e/(1+e);
	}
	nextOnProbs {|a, b|
		var nextCandidates;
		var nextProb = Array.fill(128,0);
		nextCandidates = IdentitySet.newFrom(
			(((this.lowest-maxJump).max(0))..((this.highest+maxJump).min(127)))
		)-heldNotes.keys;
		nextCandidates.do({|i|
			nextProb[i] = this.invLogit(this.lmOn(i), a, b);
		});
		^nextProb.normalizeSum;
	}
	chooseOn {|a, b|
		^(heldNotes.size>0).if({
			allNotes.wchoose(this.nextOnProbs(a,b));
			}, {
				defaultNote.value
		});
	}
	pushOn {|a, b|
		var nextPitch = this.chooseOn(a,b);
		this.add(nextPitch);
		^nextPitch;
	}
	step{|step=0.5|
		/*
		Advances time.
		
		Possible optimisation: do not do anything when step=0.0
		NB then make sure to update *feature* state when new note is played, not just ages
		*/
		heldNotes.keysValuesDo({|note, newness|
			newness = newness - step;
			heldNotes[note] = newness;
			(newness<0).if({this.remove(note)});
		});
		
	}
	lmOn {|i|
		/*^(-4.96464116) +
		((nState[i-11]?0)*(-1.28343993)) +
		((nState[i-10]?0)*(-0.85412226)) +
		((nState[i-10]?0)*(nState[i-6]?0)*0.94919149) +
		((nState[i-10]?0)*(nState[i-3]?0)*(-0.04303883)) +
		((nState[i-9]?0)*(nState[i-8]?0)*(-0.08503607)) +
		((nState[i-9]?0)*(nState[i-7]?0)*(-0.21370876)) +
		((nState[i-9]?0)*(nState[i-6]?0)*(-0.55671085)) +
		((nState[i-9]?0)*(nState[i-4]?0)*1.62902766) +
		((nState[i-9]?0)*(nState[i-1]?0)*(-0.45750474)) +
		((nState[i-9]?0)*(nState[i+8]?0)*0.89711231) +
		((nState[i-8]?0)*(nState[i-5]?0)*1.07923913) +
		((nState[i-8]?0)*(nState[i-4]?0)*(-0.82666652)) +
		((nState[i-8]?0)*(nState[i+1]?0)*(-0.18430432)) +
	((nState[i-7]?0)*(-0.15140098)) + ...*/	}
}
