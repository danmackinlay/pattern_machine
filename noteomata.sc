/*
stochastic cellular automata implementing harmonies
The model in this case comes from lasso regression on conditional note transitions in a corpus of midi files

TODO:
* swap note model
* multiple simultaneous onsets (actual cellular automata)
* dynamic default start note distribution
* multiple off-note models
* handle multiple voices with shared note list
* favour central or distant notes
* have a bag of "virtual" notes here that constrain whcih other notes play
* never consider more than say, *n* most recent notes
*/

Noteomata {
	var <window;
	var <>defA;
	var <>defB;
	var <>maxJump;
	var <>defaultNote;
	var <nState;
	var <heldNotes;
	var <allNotes;
	
	*new {|window=1, a=1,b=0,maxJump=12,defaultNote|
		^super.newCopyArgs(window,a,b,maxJump,defaultNote?{60.rrand(72)}).init;
	}
	init {
		nState = Array.fill(128,0);
		heldNotes = IdentityDictionary.new(128);
		allNotes = (0..127);
	}
	add {|i|
		nState[i]=1;
		heldNotes[i]=0.0;
	}
	remove {|i|
		nState[i]=0;
		heldNotes.removeAt(i);
	}
	lowest{
		^heldNotes.keys.minItem ? 64;
	}
	highest{
		^heldNotes.keys.maxItem ? 64;
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
	age{|step=0.5|
		/*
		Handles which notes are current and ditches those that are not
		*/
		heldNotes.keysValuesDo({|note, age|
			age = age + step;
			heldNotes[note] = age;
			(age>window).if({this.remove(note)});
		});
	}
}

//3rd order model, 1se from minimal CV error
Noteomata31 : Noteomata {
	lmOn {|i|
		^((-4.79918438)) +
		((nState[i-11]?0)*(-1.47387428)) +
		((nState[i-11]?0)*(nState[i+1]?0)*0.36184817) +
		((nState[i-10]?0)*(-1.20893014)) +
		((nState[i-9]?0)*(-0.31620227)) +
		((nState[i-9]?0)*(nState[i-6]?0)*(-0.03798096)) +
		((nState[i-9]?0)*(nState[i-4]?0)*0.74720674) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i-1]?0)*(-0.20729775)) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i+8]?0)*0.7308044) +
		((nState[i-9]?0)*(nState[i-3]?0)*(nState[i+2]?0)*0.95756849) +
		((nState[i-9]?0)*(nState[i-1]?0)*(-0.12900898)) +
		((nState[i-9]?0)*(nState[i+5]?0)*(-0.12263205)) +
		((nState[i-8]?0)*(-0.5281322)) +
		((nState[i-8]?0)*(nState[i-5]?0)*0.60674781) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i+4]?0)*(-0.63388498)) +
		((nState[i-8]?0)*(nState[i-4]?0)*(-0.41514276)) +
		((nState[i-8]?0)*(nState[i-3]?0)*(-0.12367297)) +
		((nState[i-8]?0)*(nState[i-2]?0)*(nState[i+2]?0)*0.71756623) +
		((nState[i-7]?0)*(-0.37863692)) +
		((nState[i-7]?0)*(nState[i-5]?0)*(-0.33944265)) +
		((nState[i-7]?0)*(nState[i-4]?0)*(-0.20889341)) +
		((nState[i-7]?0)*(nState[i-3]?0)*0.6591598) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i+2]?0)*0.17299863) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i+5]?0)*(-0.00355969)) +
		((nState[i-7]?0)*(nState[i-2]?0)*(-0.23369817)) +
		((nState[i-7]?0)*(nState[i-1]?0)*(-0.00413113)) +
		((nState[i-7]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.17590662)) +
		((nState[i-6]?0)*(-0.99915595)) +
		((nState[i-5]?0)*(nState[i-4]?0)*(-0.3120946)) +
		((nState[i-5]?0)*(nState[i-4]?0)*(nState[i-3]?0)*0.90968518) +
		((nState[i-5]?0)*(nState[i-3]?0)*(-0.49721351)) +
		((nState[i-5]?0)*(nState[i-2]?0)*(nState[i+4]?0)*(-0.63618484)) +
		((nState[i-5]?0)*(nState[i-1]?0)*(-1.03587172)) +
		((nState[i-5]?0)*(nState[i+1]?0)*(-0.53301072)) +
		((nState[i-5]?0)*(nState[i+2]?0)*(-0.06917172)) +
		((nState[i-5]?0)*(nState[i+4]?0)*1.68224049) +
		((nState[i-5]?0)*(nState[i+4]?0)*(nState[i+10]?0)*(-0.16600935)) +
		((nState[i-4]?0)*(nState[i-3]?0)*(nState[i-1]?0)*0.93422479) +
		((nState[i-4]?0)*(nState[i-3]?0)*(nState[i+2]?0)*1.47707889) +
		((nState[i-4]?0)*(nState[i-2]?0)*(-0.27979754)) +
		((nState[i-4]?0)*(nState[i-1]?0)*(-0.09169384)) +
		((nState[i-4]?0)*(nState[i+1]?0)*(-0.05549619)) +
		((nState[i-4]?0)*(nState[i+4]?0)*(-0.18368274)) +
		((nState[i-4]?0)*(nState[i+5]?0)*(-0.29922879)) +
		((nState[i-3]?0)*(nState[i-2]?0)*(-0.11974012)) +
		((nState[i-3]?0)*(nState[i-2]?0)*(nState[i-1]?0)*2.16016541) +
		((nState[i-3]?0)*(nState[i+1]?0)*(-0.16231424)) +
		((nState[i-3]?0)*(nState[i+3]?0)*(-0.42322803)) +
		((nState[i-3]?0)*(nState[i+4]?0)*(-0.06400695)) +
		((nState[i-3]?0)*(nState[i+5]?0)*0.16880858) +
		((nState[i-3]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.04545372)) +
		((nState[i-3]?0)*(nState[i+9]?0)*(-0.15654364)) +
		((nState[i-2]?0)*(-0.0483738)) +
		((nState[i-2]?0)*(nState[i+1]?0)*(-0.0563189)) +
		((nState[i-2]?0)*(nState[i+2]?0)*(-0.28747865)) +
		((nState[i-2]?0)*(nState[i+3]?0)*(-0.35990803)) +
		((nState[i-2]?0)*(nState[i+4]?0)*(-0.14570432)) +
		((nState[i-2]?0)*(nState[i+5]?0)*(-0.12593908)) +
		((nState[i-2]?0)*(nState[i+7]?0)*(-0.16146642)) +
		((nState[i-1]?0)*(nState[i+1]?0)*(-0.11423073)) +
		((nState[i-1]?0)*(nState[i+2]?0)*(-0.11574238)) +
		((nState[i-1]?0)*(nState[i+2]?0)*(nState[i+3]?0)*2.26088295) +
		((nState[i-1]?0)*(nState[i+4]?0)*(-0.33347439)) +
		((nState[i-1]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.01010494)) +
		((nState[i-1]?0)*(nState[i+8]?0)*(-0.2183357)) +
		((nState[i-1]?0)*(nState[i+9]?0)*(-0.13312891)) +
		((nState[i-1]?0)*(nState[i+11]?0)*0.2908458) +
		((nState[i+1]?0)*(-0.26274778)) +
		((nState[i+1]?0)*(nState[i+3]?0)*(-0.08440494)) +
		((nState[i+1]?0)*(nState[i+4]?0)*(-0.48127206)) +
		((nState[i+1]?0)*(nState[i+5]?0)*(-0.20628048)) +
		((nState[i+2]?0)*(-0.01059456)) +
		((nState[i+2]?0)*(nState[i+3]?0)*(-0.0845811)) +
		((nState[i+2]?0)*(nState[i+4]?0)*(-0.53633753)) +
		((nState[i+2]?0)*(nState[i+5]?0)*(-0.37097509)) +
		((nState[i+2]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.28184335)) +
		((nState[i+2]?0)*(nState[i+9]?0)*(-0.41267541)) +
		((nState[i+3]?0)*(nState[i+4]?0)*(-0.45493693)) +
		((nState[i+3]?0)*(nState[i+5]?0)*(-0.10607755)) +
		((nState[i+3]?0)*(nState[i+7]?0)*(-0.4309441)) +
		((nState[i+3]?0)*(nState[i+8]?0)*0.50470788) +
		((nState[i+3]?0)*(nState[i+9]?0)*(-0.39708462)) +
		((nState[i+4]?0)*(nState[i+5]?0)*(-0.55858533)) +
		((nState[i+4]?0)*(nState[i+8]?0)*(-0.17194306)) +
		((nState[i+4]?0)*(nState[i+9]?0)*(-0.09042721)) +
		((nState[i+4]?0)*(nState[i+10]?0)*0.64690445) +
		((nState[i+5]?0)*(-0.04107131)) +
		((nState[i+5]?0)*(nState[i+7]?0)*(-0.10036927)) +
		((nState[i+5]?0)*(nState[i+9]?0)*1.57214249) +
		((nState[i+5]?0)*(nState[i+10]?0)*(-0.04430801)) +
		((nState[i+6]?0)*(-0.75260051)) +
		((nState[i+7]?0)*(-0.47628208)) +
		((nState[i+8]?0)*(-0.62698496)) +
		((nState[i+9]?0)*(-0.43888132)) +
		((nState[i+10]?0)*(-0.91247975)) +
		((nState[i+11]?0)*(-1.19095297));
	}
}
//3rd order model, minimal CV error
Noteomata3min : Noteomata {
	lmOn {|i|
		^((-4.3616782)) +
		((nState[i-11]?0)*(-3.15543343)) +
		((nState[i-11]?0)*(nState[i-9]?0)*(-0.09302735)) +
		((nState[i-11]?0)*(nState[i-9]?0)*(nState[i-3]?0)*(-0.4606222)) +
		((nState[i-11]?0)*(nState[i-9]?0)*(nState[i+1]?0)*(-0.30892066)) +
		((nState[i-11]?0)*(nState[i-8]?0)*(-0.0222304)) +
		((nState[i-11]?0)*(nState[i-7]?0)*(nState[i+1]?0)*0.03781252) +
		((nState[i-11]?0)*(nState[i-7]?0)*(nState[i+5]?0)*(-0.03458711)) +
		((nState[i-11]?0)*(nState[i-5]?0)*(-0.15943928)) +
		((nState[i-11]?0)*(nState[i-5]?0)*(nState[i+4]?0)*(-0.13946633)) +
		((nState[i-11]?0)*(nState[i-4]?0)*(-0.17917144)) +
		((nState[i-11]?0)*(nState[i-4]?0)*(nState[i+1]?0)*(-0.33207353)) +
		((nState[i-11]?0)*(nState[i-3]?0)*(-0.13642732)) +
		((nState[i-11]?0)*(nState[i-3]?0)*(nState[i+1]?0)*(-0.18178589)) +
		((nState[i-11]?0)*(nState[i-2]?0)*0.00867147) +
		((nState[i-11]?0)*(nState[i-2]?0)*(nState[i+1]?0)*(-0.22852784)) +
		((nState[i-11]?0)*(nState[i+1]?0)*3.02737724) +
		((nState[i-11]?0)*(nState[i+1]?0)*(nState[i+4]?0)*(-0.02539332)) +
		((nState[i-11]?0)*(nState[i+1]?0)*(nState[i+5]?0)*(-0.48799672)) +
		((nState[i-11]?0)*(nState[i+4]?0)*(-0.17990481)) +
		((nState[i-11]?0)*(nState[i+5]?0)*(-0.11958764)) +
		((nState[i-10]?0)*(-2.1447716)) +
		((nState[i-10]?0)*(nState[i-9]?0)*(-0.48569933)) +
		((nState[i-10]?0)*(nState[i-8]?0)*(-0.1479072)) +
		((nState[i-10]?0)*(nState[i-8]?0)*(nState[i-2]?0)*(-1.37849285)) +
		((nState[i-10]?0)*(nState[i-8]?0)*(nState[i-1]?0)*4.0299603) +
		((nState[i-10]?0)*(nState[i-8]?0)*(nState[i+2]?0)*(-0.28329582)) +
		((nState[i-10]?0)*(nState[i-7]?0)*(-0.39839105)) +
		((nState[i-10]?0)*(nState[i-7]?0)*(nState[i-3]?0)*0.09608673) +
		((nState[i-10]?0)*(nState[i-6]?0)*0.18869434) +
		((nState[i-10]?0)*(nState[i-6]?0)*(nState[i+2]?0)*(-0.16206749)) +
		((nState[i-10]?0)*(nState[i-6]?0)*(nState[i+6]?0)*2.882475) +
		((nState[i-10]?0)*(nState[i-6]?0)*(nState[i+9]?0)*(-0.84642706)) +
		((nState[i-10]?0)*(nState[i-5]?0)*(-0.87354582)) +
		((nState[i-10]?0)*(nState[i-4]?0)*(nState[i-3]?0)*(-1.15973379)) +
		((nState[i-10]?0)*(nState[i-4]?0)*(nState[i-1]?0)*(-0.43420266)) +
		((nState[i-10]?0)*(nState[i-4]?0)*(nState[i+2]?0)*(-0.79451778)) +
		((nState[i-10]?0)*(nState[i-3]?0)*(-0.61414738)) +
		((nState[i-10]?0)*(nState[i-2]?0)*(nState[i+2]?0)*(-0.00074287)) +
		((nState[i-10]?0)*(nState[i-1]?0)*(nState[i+2]?0)*(-0.71509229)) +
		((nState[i-10]?0)*(nState[i+2]?0)*1.62739892) +
		((nState[i-10]?0)*(nState[i+2]?0)*(nState[i+5]?0)*(-0.10925315)) +
		((nState[i-10]?0)*(nState[i+2]?0)*(nState[i+6]?0)*(-0.59952154)) +
		((nState[i-10]?0)*(nState[i+4]?0)*(-0.03811293)) +
		((nState[i-10]?0)*(nState[i+5]?0)*(-0.55721461)) +
		((nState[i-10]?0)*(nState[i+6]?0)*(nState[i+9]?0)*(-0.279539)) +
		((nState[i-10]?0)*(nState[i+7]?0)*(-0.00109839)) +
		((nState[i-10]?0)*(nState[i+9]?0)*(-0.38992284)) +
		((nState[i-9]?0)*(-0.82567875)) +
		((nState[i-9]?0)*(nState[i-8]?0)*(-1.38559603)) +
		((nState[i-9]?0)*(nState[i-8]?0)*(nState[i-5]?0)*(-0.19278222)) +
		((nState[i-9]?0)*(nState[i-7]?0)*(-0.52367178)) +
		((nState[i-9]?0)*(nState[i-7]?0)*(nState[i-4]?0)*(-0.11971931)) +
		((nState[i-9]?0)*(nState[i-7]?0)*(nState[i-3]?0)*0.73486876) +
		((nState[i-9]?0)*(nState[i-7]?0)*(nState[i+2]?0)*(-3.2772751)) +
		((nState[i-9]?0)*(nState[i-7]?0)*(nState[i+3]?0)*(-0.00277767)) +
		((nState[i-9]?0)*(nState[i-6]?0)*(-1.37970978)) +
		((nState[i-9]?0)*(nState[i-6]?0)*(nState[i-4]?0)*(-0.05447545)) +
		((nState[i-9]?0)*(nState[i-5]?0)*0.29449455) +
		((nState[i-9]?0)*(nState[i-5]?0)*(nState[i-4]?0)*(-0.57802919)) +
		((nState[i-9]?0)*(nState[i-5]?0)*(nState[i-2]?0)*0.75623193) +
		((nState[i-9]?0)*(nState[i-5]?0)*(nState[i+3]?0)*0.92981349) +
		((nState[i-9]?0)*(nState[i-5]?0)*(nState[i+7]?0)*(-0.02965894)) +
		((nState[i-9]?0)*(nState[i-4]?0)*1.36730596) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i-3]?0)*(-1.73243055)) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i-2]?0)*(-0.91410623)) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i-1]?0)*(-1.845247)) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i+6]?0)*(-1.63596591)) +
		((nState[i-9]?0)*(nState[i-4]?0)*(nState[i+8]?0)*0.63144949) +
		((nState[i-9]?0)*(nState[i-3]?0)*(nState[i-1]?0)*(-0.06555749)) +
		((nState[i-9]?0)*(nState[i-3]?0)*(nState[i+1]?0)*3.11597516) +
		((nState[i-9]?0)*(nState[i-3]?0)*(nState[i+2]?0)*4.33500217) +
		((nState[i-9]?0)*(nState[i-3]?0)*(nState[i+3]?0)*(-0.09334574)) +
		((nState[i-9]?0)*(nState[i-3]?0)*(nState[i+5]?0)*(-0.00761165)) +
		((nState[i-9]?0)*(nState[i-2]?0)*(nState[i-1]?0)*(-0.30211367)) +
		((nState[i-9]?0)*(nState[i-2]?0)*(nState[i+3]?0)*0.00509011) +
		((nState[i-9]?0)*(nState[i-1]?0)*(-0.47640639)) +
		((nState[i-9]?0)*(nState[i-1]?0)*(nState[i+2]?0)*(-1.14098627)) +
		((nState[i-9]?0)*(nState[i-1]?0)*(nState[i+3]?0)*0.59548899) +
		((nState[i-9]?0)*(nState[i+1]?0)*(-0.181715)) +
		((nState[i-9]?0)*(nState[i+1]?0)*(nState[i+2]?0)*(-1.01455179)) +
		((nState[i-9]?0)*(nState[i+2]?0)*(-0.60016227)) +
		((nState[i-9]?0)*(nState[i+3]?0)*0.42617027) +
		((nState[i-9]?0)*(nState[i+3]?0)*(nState[i+6]?0)*(-0.56461087)) +
		((nState[i-9]?0)*(nState[i+3]?0)*(nState[i+8]?0)*(-2.17568361)) +
		((nState[i-9]?0)*(nState[i+4]?0)*(-0.33511856)) +
		((nState[i-9]?0)*(nState[i+5]?0)*(-1.63095579)) +
		((nState[i-9]?0)*(nState[i+6]?0)*1.2110592) +
		((nState[i-9]?0)*(nState[i+7]?0)*(-1.00471445)) +
		((nState[i-9]?0)*(nState[i+8]?0)*1.2977057) +
		((nState[i-9]?0)*(nState[i+9]?0)*(-0.92132581)) +
		((nState[i-9]?0)*(nState[i+10]?0)*(-0.40649489)) +
		((nState[i-9]?0)*(nState[i+11]?0)*(-0.06640651)) +
		((nState[i-8]?0)*(-0.9586446)) +
		((nState[i-8]?0)*(nState[i-7]?0)*(-1.20897539)) +
		((nState[i-8]?0)*(nState[i-6]?0)*(-0.57718704)) +
		((nState[i-8]?0)*(nState[i-5]?0)*1.6755532) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i-2]?0)*(-2.15405331)) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i-1]?0)*(-0.30144434)) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i+2]?0)*(-1.13949403)) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i+4]?0)*(-2.05718933)) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i+7]?0)*(-0.09344784)) +
		((nState[i-8]?0)*(nState[i-5]?0)*(nState[i+9]?0)*(-0.31894415)) +
		((nState[i-8]?0)*(nState[i-4]?0)*(-1.78655436)) +
		((nState[i-8]?0)*(nState[i-4]?0)*(nState[i-1]?0)*(-0.00211753)) +
		((nState[i-8]?0)*(nState[i-3]?0)*(-1.38949497)) +
		((nState[i-8]?0)*(nState[i-3]?0)*(nState[i+4]?0)*1.94201639) +
		((nState[i-8]?0)*(nState[i-3]?0)*(nState[i+9]?0)*2.57220719) +
		((nState[i-8]?0)*(nState[i-2]?0)*(-0.53657706)) +
		((nState[i-8]?0)*(nState[i-2]?0)*(nState[i-1]?0)*(-0.2173077)) +
		((nState[i-8]?0)*(nState[i-2]?0)*(nState[i+2]?0)*4.88239652) +
		((nState[i-8]?0)*(nState[i-2]?0)*(nState[i+4]?0)*2.36708611) +
		((nState[i-8]?0)*(nState[i-1]?0)*0.25417288) +
		((nState[i-8]?0)*(nState[i-1]?0)*(nState[i+4]?0)*(-0.31935577)) +
		((nState[i-8]?0)*(nState[i-1]?0)*(nState[i+11]?0)*(-0.09306229)) +
		((nState[i-8]?0)*(nState[i+1]?0)*(-0.88840607)) +
		((nState[i-8]?0)*(nState[i+2]?0)*(-0.27652952)) +
		((nState[i-8]?0)*(nState[i+3]?0)*(-0.44691771)) +
		((nState[i-8]?0)*(nState[i+4]?0)*(nState[i+9]?0)*1.28909561) +
		((nState[i-8]?0)*(nState[i+4]?0)*(nState[i+10]?0)*(-1.30718571)) +
		((nState[i-8]?0)*(nState[i+5]?0)*(-0.15689429)) +
		((nState[i-8]?0)*(nState[i+8]?0)*(-0.14312957)) +
		((nState[i-8]?0)*(nState[i+9]?0)*(-0.34284578)) +
		((nState[i-8]?0)*(nState[i+10]?0)*(-0.5862309)) +
		((nState[i-8]?0)*(nState[i+11]?0)*(-0.03781831)) +
		((nState[i-7]?0)*(-0.71842199)) +
		((nState[i-7]?0)*(nState[i-6]?0)*(-0.75846217)) +
		((nState[i-7]?0)*(nState[i-5]?0)*(-1.84090235)) +
		((nState[i-7]?0)*(nState[i-4]?0)*(-0.97277812)) +
		((nState[i-7]?0)*(nState[i-4]?0)*(nState[i-3]?0)*(-0.82108082)) +
		((nState[i-7]?0)*(nState[i-4]?0)*(nState[i+1]?0)*(-0.08274677)) +
		((nState[i-7]?0)*(nState[i-4]?0)*(nState[i+5]?0)*2.06457604) +
		((nState[i-7]?0)*(nState[i-3]?0)*1.31719643) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i-1]?0)*(-0.96256383)) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i+1]?0)*(-0.34851871)) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i+2]?0)*1.52226217) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i+3]?0)*0.24525204) +
		((nState[i-7]?0)*(nState[i-3]?0)*(nState[i+5]?0)*(-1.90546477)) +
		((nState[i-7]?0)*(nState[i-2]?0)*(-1.47393644)) +
		((nState[i-7]?0)*(nState[i-1]?0)*(-0.70765956)) +
		((nState[i-7]?0)*(nState[i-1]?0)*(nState[i+3]?0)*(-0.54815119)) +
		((nState[i-7]?0)*(nState[i-1]?0)*(nState[i+5]?0)*(-0.15800849)) +
		((nState[i-7]?0)*(nState[i+1]?0)*(nState[i+5]?0)*1.43800509) +
		((nState[i-7]?0)*(nState[i+2]?0)*(-0.23304363)) +
		((nState[i-7]?0)*(nState[i+2]?0)*(nState[i+3]?0)*(-0.63626512)) +
		((nState[i-7]?0)*(nState[i+2]?0)*(nState[i+5]?0)*(-0.51984103)) +
		((nState[i-7]?0)*(nState[i+3]?0)*3.207e-05) +
		((nState[i-7]?0)*(nState[i+3]?0)*(nState[i+5]?0)*(-0.61934449)) +
		((nState[i-7]?0)*(nState[i+3]?0)*(nState[i+9]?0)*(-0.01246914)) +
		((nState[i-7]?0)*(nState[i+4]?0)*(-0.86785375)) +
		((nState[i-7]?0)*(nState[i+5]?0)*0.46960692) +
		((nState[i-7]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.87712097)) +
		((nState[i-7]?0)*(nState[i+7]?0)*(-0.24356921)) +
		((nState[i-7]?0)*(nState[i+8]?0)*(-0.76688991)) +
		((nState[i-7]?0)*(nState[i+9]?0)*0.30639296) +
		((nState[i-7]?0)*(nState[i+10]?0)*(-0.25286198)) +
		((nState[i-6]?0)*(-1.29643522)) +
		((nState[i-6]?0)*(nState[i-5]?0)*(-1.23490799)) +
		((nState[i-6]?0)*(nState[i-4]?0)*(-0.53889142)) +
		((nState[i-6]?0)*(nState[i-4]?0)*(nState[i+6]?0)*(-0.3623622)) +
		((nState[i-6]?0)*(nState[i-3]?0)*(-1.3421964)) +
		((nState[i-6]?0)*(nState[i-2]?0)*(-0.95645216)) +
		((nState[i-6]?0)*(nState[i-1]?0)*(-0.46196133)) +
		((nState[i-6]?0)*(nState[i-1]?0)*(nState[i+3]?0)*(-0.31065874)) +
		((nState[i-6]?0)*(nState[i+1]?0)*(-0.34946118)) +
		((nState[i-6]?0)*(nState[i+2]?0)*(-1.04224118)) +
		((nState[i-6]?0)*(nState[i+2]?0)*(nState[i+6]?0)*(-0.06969136)) +
		((nState[i-6]?0)*(nState[i+3]?0)*0.11047959) +
		((nState[i-6]?0)*(nState[i+4]?0)*(-0.57031946)) +
		((nState[i-6]?0)*(nState[i+4]?0)*(nState[i+10]?0)*(-0.3470297)) +
		((nState[i-6]?0)*(nState[i+5]?0)*(-0.2530571)) +
		((nState[i-6]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.30795663)) +
		((nState[i-6]?0)*(nState[i+6]?0)*0.61370909) +
		((nState[i-6]?0)*(nState[i+6]?0)*(nState[i+9]?0)*1.37166277) +
		((nState[i-6]?0)*(nState[i+8]?0)*(-0.11157131)) +
		((nState[i-6]?0)*(nState[i+10]?0)*(-0.17266935)) +
		((nState[i-5]?0)*(-0.24812474)) +
		((nState[i-5]?0)*(nState[i-4]?0)*(-2.27295912)) +
		((nState[i-5]?0)*(nState[i-4]?0)*(nState[i-3]?0)*7.32133974) +
		((nState[i-5]?0)*(nState[i-3]?0)*(-2.28972769)) +
		((nState[i-5]?0)*(nState[i-2]?0)*(-0.18325188)) +
		((nState[i-5]?0)*(nState[i-2]?0)*(nState[i+3]?0)*0.00597784) +
		((nState[i-5]?0)*(nState[i-2]?0)*(nState[i+4]?0)*(-1.69182497)) +
		((nState[i-5]?0)*(nState[i-1]?0)*(-2.71467979)) +
		((nState[i-5]?0)*(nState[i-1]?0)*(nState[i+4]?0)*(-0.42691849)) +
		((nState[i-5]?0)*(nState[i+1]?0)*(-1.97371817)) +
		((nState[i-5]?0)*(nState[i+1]?0)*(nState[i+4]?0)*(-0.22922989)) +
		((nState[i-5]?0)*(nState[i+2]?0)*(-0.82942505)) +
		((nState[i-5]?0)*(nState[i+2]?0)*(nState[i+7]?0)*1.36698317) +
		((nState[i-5]?0)*(nState[i+3]?0)*(-0.179756)) +
		((nState[i-5]?0)*(nState[i+3]?0)*(nState[i+4]?0)*(-0.01748519)) +
		((nState[i-5]?0)*(nState[i+4]?0)*2.37635844) +
		((nState[i-5]?0)*(nState[i+4]?0)*(nState[i+7]?0)*(-0.91623633)) +
		((nState[i-5]?0)*(nState[i+4]?0)*(nState[i+9]?0)*1.67835661) +
		((nState[i-5]?0)*(nState[i+4]?0)*(nState[i+10]?0)*(-1.33572293)) +
		((nState[i-5]?0)*(nState[i+4]?0)*(nState[i+11]?0)*(-0.29191711)) +
		((nState[i-5]?0)*(nState[i+5]?0)*(-0.94470326)) +
		((nState[i-5]?0)*(nState[i+6]?0)*(-0.48581001)) +
		((nState[i-5]?0)*(nState[i+7]?0)*0.40725109) +
		((nState[i-5]?0)*(nState[i+7]?0)*(nState[i+10]?0)*2.76825883) +
		((nState[i-5]?0)*(nState[i+8]?0)*(-0.22114312)) +
		((nState[i-5]?0)*(nState[i+9]?0)*(-0.35394251)) +
		((nState[i-5]?0)*(nState[i+10]?0)*(-1.51749804)) +
		((nState[i-5]?0)*(nState[i+11]?0)*(-0.3774234)) +
		((nState[i-4]?0)*(-0.12493734)) +
		((nState[i-4]?0)*(nState[i-3]?0)*(-0.97125644)) +
		((nState[i-4]?0)*(nState[i-3]?0)*(nState[i-2]?0)*(-5.11085103)) +
		((nState[i-4]?0)*(nState[i-3]?0)*(nState[i-1]?0)*5.43273691) +
		((nState[i-4]?0)*(nState[i-3]?0)*(nState[i+2]?0)*5.15280578) +
		((nState[i-4]?0)*(nState[i-2]?0)*(-1.28103696)) +
		((nState[i-4]?0)*(nState[i-2]?0)*(nState[i-1]?0)*(-0.06229651)) +
		((nState[i-4]?0)*(nState[i-1]?0)*(-0.58063233)) +
		((nState[i-4]?0)*(nState[i-1]?0)*(nState[i+3]?0)*(-0.66593272)) +
		((nState[i-4]?0)*(nState[i+1]?0)*(-0.84106685)) +
		((nState[i-4]?0)*(nState[i+2]?0)*(-0.4305108)) +
		((nState[i-4]?0)*(nState[i+2]?0)*(nState[i+6]?0)*(-1.1683108)) +
		((nState[i-4]?0)*(nState[i+3]?0)*0.41583011) +
		((nState[i-4]?0)*(nState[i+3]?0)*(nState[i+6]?0)*(-1.56175752)) +
		((nState[i-4]?0)*(nState[i+3]?0)*(nState[i+8]?0)*(-0.82980174)) +
		((nState[i-4]?0)*(nState[i+4]?0)*(-1.56455416)) +
		((nState[i-4]?0)*(nState[i+5]?0)*(-1.18284288)) +
		((nState[i-4]?0)*(nState[i+6]?0)*1.85977849) +
		((nState[i-4]?0)*(nState[i+6]?0)*(nState[i+8]?0)*(-0.28120755)) +
		((nState[i-4]?0)*(nState[i+7]?0)*(-0.64709296)) +
		((nState[i-4]?0)*(nState[i+8]?0)*0.04462482) +
		((nState[i-4]?0)*(nState[i+9]?0)*(-0.80352631)) +
		((nState[i-4]?0)*(nState[i+10]?0)*(-0.45252704)) +
		((nState[i-4]?0)*(nState[i+11]?0)*(-0.32216355)) +
		((nState[i-3]?0)*(nState[i-2]?0)*(-2.22219173)) +
		((nState[i-3]?0)*(nState[i-2]?0)*(nState[i-1]?0)*5.91816733) +
		((nState[i-3]?0)*(nState[i-1]?0)*(-1.32502926)) +
		((nState[i-3]?0)*(nState[i+1]?0)*(-1.41205697)) +
		((nState[i-3]?0)*(nState[i+2]?0)*(-0.6360317)) +
		((nState[i-3]?0)*(nState[i+2]?0)*(nState[i+5]?0)*(-2.01523733)) +
		((nState[i-3]?0)*(nState[i+3]?0)*(-1.63174494)) +
		((nState[i-3]?0)*(nState[i+3]?0)*(nState[i+5]?0)*(-0.92082713)) +
		((nState[i-3]?0)*(nState[i+4]?0)*(-1.34373311)) +
		((nState[i-3]?0)*(nState[i+4]?0)*(nState[i+9]?0)*0.91993401) +
		((nState[i-3]?0)*(nState[i+5]?0)*1.62683843) +
		((nState[i-3]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-1.34478296)) +
		((nState[i-3]?0)*(nState[i+6]?0)*(-1.34360977)) +
		((nState[i-3]?0)*(nState[i+7]?0)*(-1.18339051)) +
		((nState[i-3]?0)*(nState[i+8]?0)*(-0.79472713)) +
		((nState[i-3]?0)*(nState[i+9]?0)*(-0.31562087)) +
		((nState[i-3]?0)*(nState[i+10]?0)*(-0.26552615)) +
		((nState[i-3]?0)*(nState[i+11]?0)*(-0.09676116)) +
		((nState[i-2]?0)*(-0.06296935)) +
		((nState[i-2]?0)*(nState[i-1]?0)*0.05071955) +
		((nState[i-2]?0)*(nState[i-1]?0)*(nState[i+11]?0)*(-0.74402169)) +
		((nState[i-2]?0)*(nState[i+1]?0)*(-1.03673926)) +
		((nState[i-2]?0)*(nState[i+2]?0)*(-1.652812)) +
		((nState[i-2]?0)*(nState[i+2]?0)*(nState[i+4]?0)*(-0.02630303)) +
		((nState[i-2]?0)*(nState[i+3]?0)*(-1.59127942)) +
		((nState[i-2]?0)*(nState[i+4]?0)*(-1.29512258)) +
		((nState[i-2]?0)*(nState[i+4]?0)*(nState[i+10]?0)*(-0.82684832)) +
		((nState[i-2]?0)*(nState[i+5]?0)*(-1.39099835)) +
		((nState[i-2]?0)*(nState[i+6]?0)*(-0.66696947)) +
		((nState[i-2]?0)*(nState[i+7]?0)*(-1.43206682)) +
		((nState[i-2]?0)*(nState[i+8]?0)*(-0.73665549)) +
		((nState[i-2]?0)*(nState[i+9]?0)*(-0.7741582)) +
		((nState[i-2]?0)*(nState[i+10]?0)*(-0.37242058)) +
		((nState[i-2]?0)*(nState[i+11]?0)*(-0.34930826)) +
		((nState[i-1]?0)*0.13680552) +
		((nState[i-1]?0)*(nState[i+1]?0)*(-2.07091821)) +
		((nState[i-1]?0)*(nState[i+2]?0)*(-0.98293053)) +
		((nState[i-1]?0)*(nState[i+2]?0)*(nState[i+3]?0)*6.56663862) +
		((nState[i-1]?0)*(nState[i+2]?0)*(nState[i+11]?0)*(-0.00627954)) +
		((nState[i-1]?0)*(nState[i+3]?0)*(-0.49723905)) +
		((nState[i-1]?0)*(nState[i+3]?0)*(nState[i+5]?0)*3.73692907) +
		((nState[i-1]?0)*(nState[i+3]?0)*(nState[i+8]?0)*(-0.17697717)) +
		((nState[i-1]?0)*(nState[i+3]?0)*(nState[i+11]?0)*(-0.28612341)) +
		((nState[i-1]?0)*(nState[i+4]?0)*(-0.88566072)) +
		((nState[i-1]?0)*(nState[i+4]?0)*(nState[i+7]?0)*(-0.00257017)) +
		((nState[i-1]?0)*(nState[i+4]?0)*(nState[i+11]?0)*0.90607279) +
		((nState[i-1]?0)*(nState[i+5]?0)*(-0.41558305)) +
		((nState[i-1]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.51413789)) +
		((nState[i-1]?0)*(nState[i+5]?0)*(nState[i+11]?0)*(-0.09497363)) +
		((nState[i-1]?0)*(nState[i+6]?0)*(-1.29224824)) +
		((nState[i-1]?0)*(nState[i+7]?0)*(-1.50146449)) +
		((nState[i-1]?0)*(nState[i+8]?0)*(-1.70151549)) +
		((nState[i-1]?0)*(nState[i+9]?0)*(-1.63311739)) +
		((nState[i-1]?0)*(nState[i+10]?0)*(-0.81282551)) +
		((nState[i-1]?0)*(nState[i+11]?0)*1.69444638) +
		((nState[i+1]?0)*(-0.44912921)) +
		((nState[i+1]?0)*(nState[i+2]?0)*(-2.01233416)) +
		((nState[i+1]?0)*(nState[i+3]?0)*(-1.70539728)) +
		((nState[i+1]?0)*(nState[i+4]?0)*(-1.12017623)) +
		((nState[i+1]?0)*(nState[i+4]?0)*(nState[i+10]?0)*(-0.04075368)) +
		((nState[i+1]?0)*(nState[i+5]?0)*(-0.98693423)) +
		((nState[i+1]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.00890352)) +
		((nState[i+1]?0)*(nState[i+6]?0)*(-0.7171652)) +
		((nState[i+1]?0)*(nState[i+7]?0)*(-0.76389876)) +
		((nState[i+1]?0)*(nState[i+8]?0)*(-0.90437134)) +
		((nState[i+1]?0)*(nState[i+9]?0)*(-0.96159673)) +
		((nState[i+1]?0)*(nState[i+10]?0)*(-0.70571013)) +
		((nState[i+1]?0)*(nState[i+11]?0)*(-0.00179814)) +
		((nState[i+2]?0)*(-0.22830149)) +
		((nState[i+2]?0)*(nState[i+3]?0)*(-2.04055622)) +
		((nState[i+2]?0)*(nState[i+4]?0)*(-2.19046967)) +
		((nState[i+2]?0)*(nState[i+5]?0)*(-0.15296591)) +
		((nState[i+2]?0)*(nState[i+5]?0)*(nState[i+9]?0)*(-0.85168731)) +
		((nState[i+2]?0)*(nState[i+6]?0)*(-0.09091287)) +
		((nState[i+2]?0)*(nState[i+7]?0)*(-0.59005949)) +
		((nState[i+2]?0)*(nState[i+8]?0)*(-0.89541214)) +
		((nState[i+2]?0)*(nState[i+9]?0)*(-1.9244154)) +
		((nState[i+2]?0)*(nState[i+10]?0)*(-0.67756863)) +
		((nState[i+2]?0)*(nState[i+11]?0)*(-0.38607018)) +
		((nState[i+3]?0)*(-0.21338903)) +
		((nState[i+3]?0)*(nState[i+4]?0)*(-2.23063398)) +
		((nState[i+3]?0)*(nState[i+5]?0)*(-0.45602228)) +
		((nState[i+3]?0)*(nState[i+5]?0)*(nState[i+8]?0)*(-0.88440484)) +
		((nState[i+3]?0)*(nState[i+5]?0)*(nState[i+9]?0)*0.14256786) +
		((nState[i+3]?0)*(nState[i+6]?0)*(-0.63416628)) +
		((nState[i+3]?0)*(nState[i+7]?0)*(-1.74911666)) +
		((nState[i+3]?0)*(nState[i+8]?0)*1.52845569) +
		((nState[i+3]?0)*(nState[i+9]?0)*(-1.12390968)) +
		((nState[i+3]?0)*(nState[i+10]?0)*(-0.85788536)) +
		((nState[i+3]?0)*(nState[i+11]?0)*(-0.78978312)) +
		((nState[i+4]?0)*(-0.23710538)) +
		((nState[i+4]?0)*(nState[i+5]?0)*(-2.05627805)) +
		((nState[i+4]?0)*(nState[i+6]?0)*(-1.28398079)) +
		((nState[i+4]?0)*(nState[i+6]?0)*(nState[i+10]?0)*(-0.03521688)) +
		((nState[i+4]?0)*(nState[i+7]?0)*0.79193112) +
		((nState[i+4]?0)*(nState[i+7]?0)*(nState[i+10]?0)*(-0.10793099)) +
		((nState[i+4]?0)*(nState[i+7]?0)*(nState[i+11]?0)*(-0.08643409)) +
		((nState[i+4]?0)*(nState[i+8]?0)*(-1.36498915)) +
		((nState[i+4]?0)*(nState[i+9]?0)*(-0.81658616)) +
		((nState[i+4]?0)*(nState[i+10]?0)*2.29429499) +
		((nState[i+5]?0)*(-0.46530831)) +
		((nState[i+5]?0)*(nState[i+6]?0)*(-1.31414387)) +
		((nState[i+5]?0)*(nState[i+6]?0)*(nState[i+9]?0)*(-0.58155727)) +
		((nState[i+5]?0)*(nState[i+7]?0)*(-1.13913355)) +
		((nState[i+5]?0)*(nState[i+8]?0)*0.01042967) +
		((nState[i+5]?0)*(nState[i+9]?0)*2.44960353) +
		((nState[i+5]?0)*(nState[i+9]?0)*(nState[i+11]?0)*(-0.0064093)) +
		((nState[i+5]?0)*(nState[i+10]?0)*(-1.23498412)) +
		((nState[i+5]?0)*(nState[i+11]?0)*(-0.53418465)) +
		((nState[i+6]?0)*(-1.16679454)) +
		((nState[i+6]?0)*(nState[i+7]?0)*(-0.68612418)) +
		((nState[i+6]?0)*(nState[i+8]?0)*(-1.15651439)) +
		((nState[i+6]?0)*(nState[i+9]?0)*0.55776684) +
		((nState[i+6]?0)*(nState[i+10]?0)*(-0.69866086)) +
		((nState[i+6]?0)*(nState[i+11]?0)*(-0.09336221)) +
		((nState[i+7]?0)*(-0.81057019)) +
		((nState[i+7]?0)*(nState[i+8]?0)*(-0.84336028)) +
		((nState[i+7]?0)*(nState[i+9]?0)*(-1.20362059)) +
		((nState[i+7]?0)*(nState[i+10]?0)*(-1.04692138)) +
		((nState[i+8]?0)*(-1.06935158)) +
		((nState[i+8]?0)*(nState[i+9]?0)*(-0.84721473)) +
		((nState[i+8]?0)*(nState[i+10]?0)*(-0.36589563)) +
		((nState[i+8]?0)*(nState[i+11]?0)*(-0.08885091)) +
		((nState[i+9]?0)*(-0.88568465)) +
		((nState[i+9]?0)*(nState[i+10]?0)*(-0.56639861)) +
		((nState[i+9]?0)*(nState[i+11]?0)*(-0.0671789)) +
		((nState[i+10]?0)*(-1.32191639)) +
		((nState[i+11]?0)*(-2.30652383));
	}
}