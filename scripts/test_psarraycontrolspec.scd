c=PSArrayControlSpec([1,3,5], interp: 0.0);
c.map(0.0);
c.map(0.2);
c.map(0.49);
c.map(0.99);
c.map(1);
c.map(2);
c.interp.asBoolean
c.clipLo;
c.clipHi;
c.maxval;
c.minval;
c.unitToIndex(0.1)
c.unitToIndex(0.5)
c.unitToIndex(1.0)
c.warp.map(0.5)
ControlSpec(0.001,1.0,\exp).map(0.8);
