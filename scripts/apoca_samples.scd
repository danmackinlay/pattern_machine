//load synthdefs; must be invoked by a forked thread.
{|state, basepath|
	var sampsetbufdict, sampsetbufarray, sampsetpaths, ind=0;
	sampsetbufdict = ();

	sampsetpaths = (
		siren: [
			"22370__druidus__Civil_Defence_Siren.wav",
			"24347__fonogeno__Police_sirens-short.wav",
			"30476__LG__Dutch_air_raid_warning_02.wav",
			"43807__daveincamas__WW2AirplaneFlyover.wav",
		].collect(basepath +/+ _),
		people: [
			"actors-laughing.wav",
			"tortureguy-3.wav",
			"actors-siren.wav",
			"actors-tuning.wav",
		].collect(basepath +/+ _),
		desolation: [
			"varese_on_a_lathe.wav",
			"whistling-wind.wav",
			"seagull-walk.wav",
			"10334_batchku_burning_iceberg.aiff",
		].collect(basepath +/+ _),
		tuneful: [
			"Unknown_Lead_Vocal.wav",
			"NS-wind-chimes-002-denoise-edit.wav",
			"CONCERTOFORCLARINETP2-solo.wav",
			"uc-ezchord.wav",
		].collect(basepath +/+ _),
		// choral: [
		// 	"choir/namgyalmonastery-chanthighlight.wav",
		// 	"choir/magnificat-build.wav",
		// 	"choir/huunhuurtu-legend.wav",
		// 	"choir/bulgur-legend.wav",
		// ].collect(basepath +/+ _),
	);
	sampsetbufarray = Buffer.allocConsecutive(
		20,
		s, 44100*60, 1); //dangerously hard coded, soz.
	s.sync;
	state[\sourcebuf] = sampsetbufarray[0];
	sampsetpaths.keysValuesDo({|key,paths|
		paths.do({|path|
			var buf;
			//[\loadin, key, ind, path].postln;
			buf=sampsetbufarray[ind];
			buf.readChannel(path, channels:[0]);
			sampsetbufdict[key]=(sampsetbufdict[key] ?? {Array.new}).add(buf);
			CmdPeriod.doOnce { buf.free };
			ind = ind + 1;
		});
	});
	s.sync;
	state[\sampsetpaths] = sampsetpaths;
	state[\sampsetbufdict] = sampsetbufdict;
	state[\sampsetbufarray] = sampsetbufarray;
	state;
}