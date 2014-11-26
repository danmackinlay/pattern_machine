(
p = PSParamSpace(\dan);
p.newParam(\x);
p.newParam(\y);
p.newParam;
p.newParam(\z, [1,5,\exp]);
p.eventFromPreset([0.5, 0.5, 0.5, 0.5]);
p.presetFromEvent((x:0.5, y:0.5, param_3: 0.5, z:1.5));
p.presetFromEvent(p.eventFromPreset([0.5, 0.5, 0.5, 0.5]));
)
p.postcs;
p.nParams;
p.paramNames;