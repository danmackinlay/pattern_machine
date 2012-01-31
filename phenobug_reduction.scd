(
~log = LogFile.global;
~iterations = 0;
~list = LinkedList.new;
~term = {|list, iterations| 
	var aliens;
	~log.logFlush("term").postln;
	aliens = list.detect({|i, idx| i.class!=Event;} );
	aliens.notNil || iterations>10; };
~birth = { (\a: 5.rand, \b: 10.rand, \birthday: ~iterations);};
~tend = {|list| 
	var doomed, deathCount;
	~log.logFlush("tend").postln;
	doomed = list.select({0.1.coin;});
	~log.logFlush("doomed", doomed).postln;
	deathCount = doomed.size;
	doomed.do({|i| list.remove(i);});
	~log.logFlush("culling", doomed).postln;
	deathCount.do({
		var babe = ~birth.value;
		~list.add(babe);
		~log.logFlush("breeding", babe).postln;
	});
	~log.logFlush("circule of life continues", ~iterations).postln;
	~iterations = ~iterations +1;
};
~rout = Routine.new({
	while(
		{
			~log.logFlush("whiletest", ~iterations).postln;
			(~term.value(
				~list, ~iterations
			).not)
		},
		{
			~log.logFlush("whiledo").postln;
			~tend.value(~list);
			true.yield;
		};
	);
	false.yield;},
	stackSize: 1024
);
100.do({~list.add(~birth.value);});
while {~rout.next } {
  //noop
  ~log.logFlush("parent while loop continues", ~iterations).postln;
};
)
