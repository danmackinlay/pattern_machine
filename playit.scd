~here = "/Users/dan/src/python/arpeggiate_by_numbers";
~mankymodel = (~here +/+ "coef-11.json").parseYAMLFile;
~s=IdentitySet[1,3,5];
~noteson = [0,0,0,1,0,0,1,0];
~notelm = {|i, nState|
	((-4.96464116)) +
((nState[i-7]?0)*(nState[i-6]?0)*(-0.17156896)) +
((nState[i-5]?0)*(nState[i-4]?0)*(-0.02200252)) +
((nState[i-7]?0)*(nState[i-5]?0)*(-0.3471564)) +
((nState[i-7]?0)*(nState[i-2]?0)*(-0.21654709)) +
((nState[i-7]?0)*(nState[i-3]?0)*1.21097858) +
((nState[i-5]?0)*(nState[i-3]?0)*(-0.64130489)) +
((nState[i-3]?0)*(nState[i+3]?0)*(-0.56287068)) +
((nState[i-2]?0)*(nState[i+3]?0)*(-0.06215389)) +
((nState[i-3]?0)*(nState[i+1]?0)*(-0.4397831)) +
((nState[i-4]?0)*(nState[i+1]?0)*(-0.21069791)) +
((nState[i-6]?0)*(nState[i+2]?0)*(-8.251e-05)) +
((nState[i-4]?0)*(nState[i-1]?0)*(-0.26275819)) +
((nState[i-5]?0)*(nState[i-1]?0)*(-0.4669753)) +
((nState[i-9]?0)*(nState[i+8]?0)*0.89711231) +
((nState[i-6]?0)*(nState[i-5]?0)*(-0.13930213)) +
((nState[i+8]?0)*(-0.80713203)) +
((nState[i+9]?0)*(-0.55466688)) +
((nState[i-6]?0)*(nState[i-3]?0)*(-0.04302074)) +
((nState[i-6]?0)*(nState[i-1]?0)*(-0.08548712)) +
((nState[i+3]?0)*(-0.20170513)) +
((nState[i+6]?0)*(-1.21159816)) +
((nState[i+7]?0)*(-0.34736813)) +
((nState[i+4]?0)*(-0.47917718)) +
((nState[i+5]?0)*(-0.27236269)) +
((nState[i-3]?0)*0.50752238) +
((nState[i-5]?0)*0.26678056) +
((nState[i-4]?0)*0.3923895) +
((nState[i-7]?0)*(-0.15140098)) +
((nState[i-5]?0)*(nState[i+1]?0)*(-0.18629919)) +
((nState[i-10]?0)*(-0.85412226)) +
((nState[i+10]?0)*(-0.65407107)) +
((nState[i+11]?0)*(-0.56899063)) +
((nState[i-9]?0)*(nState[i-8]?0)*(-0.08503607)) +
((nState[i-8]?0)*(nState[i-5]?0)*1.07923913) +
((nState[i-8]?0)*(nState[i-4]?0)*(-0.82666652)) +
((nState[i-11]?0)*(-1.28343993)) +
((nState[i-3]?0)*(nState[i+5]?0)*(-0.08215483)) +
((nState[i-8]?0)*(nState[i+1]?0)*(-0.18430432)) +
((nState[i-9]?0)*(nState[i-4]?0)*1.62902766) +
((nState[i-9]?0)*(nState[i-6]?0)*(-0.55671085)) +
((nState[i-9]?0)*(nState[i-7]?0)*(-0.21370876)) +
((nState[i-10]?0)*(nState[i-6]?0)*0.94919149) +
((nState[i-10]?0)*(nState[i-3]?0)*(-0.04303883)) +
((nState[i-9]?0)*(nState[i-1]?0)*(-0.45750474));
};
~noteslm.value(1, #[0,0,0,0,0,0,1,1,0,0,0,0,1]);