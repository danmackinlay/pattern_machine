(
~iterations = 0;
~log = LogFile.global;
~rout = Routine.new({
	while(
		{
			~log.logFlush("whiletest", ~iterations).postln;
			~iterations < 100;
		},
		{
			~iterations = ~iterations + 1;
			~log.logFlush("whiledo", ~iterations).postln;
			true.yield;
		};
	);
	false.yield;},
	stackSize: 1024
);
while {~rout.next } {
  //noop
  //~log.logFlush("parent while loop continues", ~iterations).postln;
};
)
