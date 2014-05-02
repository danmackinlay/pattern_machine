/*
stochastic cellular automata implementing harmonies
The model in this case comes from lasso regression on conditional note transitions in a corpus of midi files

TODO:
* swap note model
* multiple simultaneous onsets (actual cellular automata)
* dynamic default start note distribution
* multiple off-note models
* handle multiple voices with shared note list
* handle repeated notes - using IdentityBag, or a PriorityQueue
* the latter is nice because we can keep track of an internal time
*/

Noteomata {
	var <nState;
	var <heldNotes;
	var <allNotes;
	
	*new {
		^super.new.init;
	}
	init {
		nState = Array.fill(128,0);
		heldNotes = IdentitySet.new(128);
		allNotes = (0..127);
	}
	add {|i|
		nState[i]=1;
		heldNotes.add(i);
	}
	remove {|i|
		nState[i]=0;
		heldNotes.remove(i);
	}
	lowest{
		^heldNotes.minItem ? 64;
	}
	highest{
		^heldNotes.maxItem ? 64;
	}
	lmOn {|i|
		^(-4.96464116) +
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
		((nState[i-7]?0)*(-0.15140098)) +
		((nState[i-7]?0)*(nState[i-6]?0)*(-0.17156896)) +
		((nState[i-7]?0)*(nState[i-5]?0)*(-0.3471564)) +
		((nState[i-7]?0)*(nState[i-3]?0)*1.21097858) +
		((nState[i-7]?0)*(nState[i-2]?0)*(-0.21654709)) +
		((nState[i-6]?0)*(nState[i-5]?0)*(-0.13930213)) +
		((nState[i-6]?0)*(nState[i-3]?0)*(-0.04302074)) +
		((nState[i-6]?0)*(nState[i-1]?0)*(-0.08548712)) +
		((nState[i-5]?0)*0.26678056) +
		((nState[i-5]?0)*(nState[i-4]?0)*(-0.02200252)) +
		((nState[i-5]?0)*(nState[i-3]?0)*(-0.64130489)) +
		((nState[i-5]?0)*(nState[i-1]?0)*(-0.4669753)) +
		((nState[i-5]?0)*(nState[i+1]?0)*(-0.18629919)) +
		((nState[i-4]?0)*0.3923895) +
		((nState[i-4]?0)*(nState[i-1]?0)*(-0.26275819)) +
		((nState[i-4]?0)*(nState[i+1]?0)*(-0.21069791)) +
		((nState[i-3]?0)*0.50752238) +
		((nState[i-3]?0)*(nState[i+1]?0)*(-0.4397831)) +
		((nState[i-3]?0)*(nState[i+3]?0)*(-0.56287068)) +
		((nState[i-3]?0)*(nState[i+5]?0)*(-0.08215483)) +
		((nState[i-2]?0)*(nState[i+3]?0)*(-0.06215389)) +
		((nState[i+3]?0)*(-0.20170513)) +
		((nState[i+4]?0)*(-0.47917718)) +
		((nState[i+5]?0)*(-0.27236269)) +
		((nState[i+6]?0)*(-1.21159816)) +
		((nState[i+7]?0)*(-0.34736813)) +
		((nState[i+8]?0)*(-0.80713203)) +
		((nState[i+9]?0)*(-0.55466688)) +
		((nState[i+10]?0)*(-0.65407107)) +
		((nState[i+11]?0)*(-0.56899063));
	}
	lmOff{|i|
		((-5.39498548)) +
		((nState[i-11]?0)*(-0.81201252)) +
		((nState[i-11]?0)*(nState[i-8]?0)*(-0.33081911)) +
		((nState[i-11]?0)*(nState[i-3]?0)*(-0.00484306)) +
		((nState[i-10]?0)*(-0.32721688)) +
		((nState[i-10]?0)*(nState[i-9]?0)*(-0.18726971)) +
		((nState[i-10]?0)*(nState[i-7]?0)*(-0.23819043)) +
		((nState[i-10]?0)*(nState[i-6]?0)*1.26172181) +
		((nState[i-10]?0)*(nState[i-5]?0)*(-0.20922032)) +
		((nState[i-10]?0)*(nState[i-3]?0)*(-0.56285579)) +
		((nState[i-9]?0)*(nState[i-8]?0)*(-0.34617873)) +
		((nState[i-9]?0)*(nState[i-7]?0)*(-0.58608671)) +
		((nState[i-9]?0)*(nState[i-6]?0)*(-0.78579402)) +
		((nState[i-9]?0)*(nState[i-5]?0)*0.17596177) +
		((nState[i-9]?0)*(nState[i-4]?0)*2.2767305) +
		((nState[i-9]?0)*(nState[i-3]?0)*0.27260348) +
		((nState[i-9]?0)*(nState[i-1]?0)*(-0.81010215)) +
		((nState[i-9]?0)*(nState[i+8]?0)*0.98047865) +
		((nState[i-8]?0)*(nState[i-7]?0)*(-0.0581614)) +
		((nState[i-8]?0)*(nState[i-6]?0)*(-0.139325)) +
		((nState[i-8]?0)*(nState[i-5]?0)*1.79978889) +
		((nState[i-8]?0)*(nState[i-4]?0)*(-0.91943901)) +
		((nState[i-8]?0)*(nState[i-2]?0)*0.39296407) +
		((nState[i-8]?0)*(nState[i+1]?0)*(-0.3298326)) +
		((nState[i-7]?0)*(-0.02313544)) +
		((nState[i-7]?0)*(nState[i-6]?0)*(-0.61750279)) +
		((nState[i-7]?0)*(nState[i-5]?0)*(-0.48198278)) +
		((nState[i-7]?0)*(nState[i-3]?0)*1.77053988) +
		((nState[i-7]?0)*(nState[i-2]?0)*(-0.50818431)) +
		((nState[i-7]?0)*(nState[i+9]?0)*(-0.06539239)) +
		((nState[i-6]?0)*(nState[i-5]?0)*(-0.19485706)) +
		((nState[i-6]?0)*(nState[i-4]?0)*0.22389953) +
		((nState[i-6]?0)*(nState[i-1]?0)*(-0.17789939)) +
		((nState[i-6]?0)*(nState[i+2]?0)*(-0.19821903)) +
		((nState[i-5]?0)*0.01619571) +
		((nState[i-5]?0)*(nState[i-3]?0)*(-0.65543173)) +
		((nState[i-5]?0)*(nState[i-1]?0)*(-0.53707009)) +
		((nState[i-4]?0)*0.18540016) +
		((nState[i-4]?0)*(nState[i-1]?0)*(-0.02458103)) +
		((nState[i-4]?0)*(nState[i+7]?0)*0.14423396) +
		((nState[i-3]?0)*0.41369007) +
		((nState[i-3]?0)*(nState[i+1]?0)*(-0.10266089)) +
		((nState[i-3]?0)*(nState[i+3]?0)*(-0.93592823)) +
		((nState[i-3]?0)*(nState[i+5]?0)*(-0.41679382)) +
		((nState[i-2]?0)*(nState[i-1]?0)*0.31918143) +
		((nState[i-2]?0)*(nState[i+3]?0)*(-0.11018514)) +
		((nState[i-1]?0)*(-0.04131232)) +
		((nState[i-1]?0)*(nState[i+3]?0)*(-0.0810695)) +
		((nState[i+1]?0)*(-0.37274377)) +
		((nState[i+2]?0)*(-0.05085987)) +
		((nState[i+3]?0)*(-0.20609268)) +
		((nState[i+4]?0)*(-0.48166712)) +
		((nState[i+5]?0)*(-0.21707927)) +
		((nState[i+6]?0)*(-0.9870534)) +
		((nState[i+7]?0)*(-0.15548124)) +
		((nState[i+8]?0)*(-0.59470818)) +
		((nState[i+9]?0)*(-0.33404362)) +
		((nState[i+10]?0)*(-0.44344859)) +
		((nState[i+11]?0)*(-0.47676943));
	}
	invLogit{|x=0,a=1,b=0|
		var e=(a*x+b).exp;
		^e/(1+e);
	}
	nextOnProbs {|a=1, b=0|
		var nextCandidates;
		var nextProb = Array.fill(128,0);
		nextCandidates = IdentitySet.newFrom(
			(((this.lowest-12).max(0))..((this.highest+12).min(127)))
		)-heldNotes;
		nextCandidates.do({|i|
			nextProb[i] = this.invLogit(this.lmOn(i), a, b);
		});
		^nextProb.normalizeSum;
	}
	nextOffProbs {|a=1, b=0|
		var nextCandidates;
		var nextProb = Array.fill(128,0);
		heldNotes.do({|i|
			nextProb[i] = this.invLogit(this.lmOn(i), a, b);
		});
		^nextProb.normalizeSum;
	}
	chooseOn {|a=1, b=0|
		^allNotes.wchoose(this.nextOnProbs(a,b));
	}
	chooseOff {|a=1, b=0|
		^(heldNotes.size>0}.if({
			allNotes.wchoose(this.nextOffProbs(a,b));
			}, {
				nil
			}
		);
	}
	nextOn {|a=1, b=0|
		var nextPitch = this.chooseOn(a,b);
		this.add(nextPitch);
		^nextPitch;
	}
	nextOff {|a=1, b=0|
		var nextPitch = this.chooseOff(a,b);
		this.remove(nextPitch);
		^nextPitch;
	}
}