(
p = PSParamSpace(\dan);
p.newParam(\x);
p.newParam(\y);
p.newParam;
p.newParam(\z, [1,5,\exp]);
)
p.postcs;
p.eventFromPreset([0.5, 0.5, 0.5, 0.5]);
p.presetFromEvent((x:0.5, y:0.5, param_3: 0.5, z:1.5));
p.presetFromEvent(p.eventFromPreset([0.5, 0.5, 0.5, 0.5]));
p.nParams;
p.paramNames;
p.newPresetDefault;
p.newPreset;
p.map([0.5, 0.5, 0.5, 0.5]);
p.unmap([0.5, 0.5, 0.5, 1.5]);
(
p = PSParamSpace(\dan, [[\a], [\b]]);
p.params;
w = PSParamwalker.new(p);
w.step;
)
w.history;
w.back(3);
w.event;
w.enact;