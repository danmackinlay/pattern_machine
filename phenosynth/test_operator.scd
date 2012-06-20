~scorez = (a:0.1, b: 0.01, c: 1.0, d:0.5);
~scorez.size;
~cooker = {|params, rawScoreMap|
	var fitnessOrder, size, cookedFitnessMap;
	cookedFitnessMap = IdentityDictionary.new;
	size = rawScoreMap.size;
	(size>0).if({
		fitnessOrder = Array.newClear(size);
		rawScoreMap.keysValuesDo({|key, val, i|
			[\i, i].postln;
			fitnessOrder[i] = (id:key, fitness:val);
		});
		fitnessOrder.sortBy(\fitness);
		fitnessOrder.do({|elem, i|
		cookedFitnessMap[elem[\id]] = i;
		});
	});
	cookedFitnessMap;
};
~cooker.(nil, ~scorez);
~a=Array.new(4);
~a[0]=\ghat;