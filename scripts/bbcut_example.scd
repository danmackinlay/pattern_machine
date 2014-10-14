//"http://sc3howto.blogspot.ch/2010/10/getting-started-with-bbcut2.html"


(
 var clock, sf1, sf2, cut1, cut2, group;

 TempoClock.default.tempo_(180/60);
 clock = ExternalClock(TempoClock.default);
 clock.play;

 sf1= BBCutBuffer("sounds/break",8);
 sf2= BBCutBuffer("sounds/break2",4);

 Routine.run({
  s.sync; // this tells the task to wait

  group = CutGroup(CutBuf3(sf1, 0.2));  // make a group with a Buffer
  cut1 = BBCut2(group, BBCutProc11(8, 4, 2, 2, 0.2)).play(clock);  // then cut it up

  5.wait;

  cut2 = BBCut2(CutBuf3(sf2, 0.2),
   BBCutProc11(8, 4, 4, 2, 0.2)).play(clock); // start more drums from the other sound file

  5.wait;

  group.add(CutComb1.new); // put some FX on the drums in cut1

  15.wait;

  group.removeAt(2); // take the fx back off

  1.wait;
  cut2.pause;

  4.wait;
  cut1.stop;
 })
)


