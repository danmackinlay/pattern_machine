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
	var <maxAge=2.0;
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
			this.square(_,maxAge-0),
			this.square(_,maxAge-0.25),
			this.square(_,maxAge-0.5),
			this.square(_,maxAge-1)];
		this.updateFeatures;
	}
	square {|x,center=0,width|
		width = width?featureWidth;
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
		this.updateFeatures;
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
	logit{|x=0,a,b|
		var e=((a?defA)*x+(b?defB)).exp;
		^e/(1+e);
	}
	nextOnProbs {|a, b|
		var nextCandidates;
		var nextProb = Array.fill(128,0);
		nextCandidates = IdentitySet.newFrom(
			(((this.lowest-maxJump).max(0))..((this.highest+maxJump).min(127)))
		);
		nextCandidates.do({|i|
			nextProb[i] = this.logit(this.lmOn(i), a, b);
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
		*/
		heldNotes.keysValuesDo({|note, newness|
			newness = newness - step;
			heldNotes[note] = newness;
			(newness<0).if({this.remove(note)});
		});
		(step>0.0).if({this.updateFeatures});
	}
	lmOn {|i|
		^(-0.298561) +
			((featureData[0][i+0]?0)*0.309179558809) +
			((featureData[1][i+0]?0)*0.277442299863) +
			((featureData[2][i+0]?0)*0.249221591581) +
			((featureData[3][i+0]?0)*0.224101656816) +
			((featureData[0][i+5]?0)*0.11740175154) +
			((featureData[1][i+5]?0)*0.107444949198) +
			((featureData[2][i+5]?0)*0.0983746752031) +
			((featureData[3][i+5]?0)*0.0901068946112) +
			((featureData[0][i+2]?0)*0.089702092509) +
			((featureData[0][i+7]?0)*0.0827108304929) +
			((featureData[1][i+2]?0)*0.0822361649179) +
			((featureData[0][i-5]?0)*0.0766510247534) +
			((featureData[1][i+7]?0)*0.075738367963) +
			((featureData[2][i+2]?0)*0.0754177476102) +
			((featureData[1][i-5]?0)*0.0703311520518) +
			((featureData[2][i+7]?0)*0.0693766867615) +
			((featureData[3][i+2]?0)*0.0691873638118) +
			((featureData[2][i-5]?0)*0.0645606675302) +
			((featureData[3][i+7]?0)*0.0635693105169) +
			((featureData[3][i-5]?0)*0.059288144337) +
			((featureData[0][i-7]?0)*0.050728074902) +
			((featureData[1][i-7]?0)*0.046620890746) +
			((featureData[0][i-2]?0)*0.0466030115019) +
			((featureData[0][i+3]?0)*0.0452801447597) +
			((featureData[2][i-7]?0)*0.0428650059326) +
			((featureData[1][i-2]?0)*0.0428608312303) +
			((featureData[1][i+3]?0)*0.0418771575073) +
			((featureData[2][i-2]?0)*0.0394346556056) +
			((featureData[3][i-7]?0)*0.039427975533) +
			((featureData[2][i+3]?0)*0.0387429759009) +
			((featureData[3][i-2]?0)*0.0362956854462) +
			((featureData[3][i+3]?0)*0.0358545893891) +
			((featureData[0][i-6]?0)*(-0.0318185150601)) +
			((featureData[1][i-6]?0)*(-0.029912449689)) +
			((featureData[2][i-6]?0)*(-0.0281253514713)) +
			((featureData[3][i-6]?0)*(-0.026449083848)) +
			((featureData[0][i+4]?0)*0.0205566899951) +
			((featureData[1][i+4]?0)*0.0191091877913) +
			((featureData[2][i+4]?0)*0.0177683728954) +
			((featureData[3][i+4]?0)*0.0165257352471) +
			((featureData[0][i-1]?0)*0.00441345978386) +
			((featureData[1][i-1]?0)*0.00412629266723) +
			((featureData[2][i-1]?0)*0.00385855361263) +
			((featureData[3][i-1]?0)*0.00360882170962) +
			((featureData[0][i+6]?0)*(-0.00322539900385)) +
			((featureData[1][i+6]?0)*(-0.00302037207538)) +
			((featureData[2][i+6]?0)*(-0.0028286594091)) +
			((featureData[3][i+6]?0)*(-0.00264933119361));
	}
}
