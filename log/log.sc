/*
flexible loggers, because

1 logging to a GUI window is no good when SuperCollider does its segfault thing.
2 turning logging streams on and off is necessary
3 supercollider ain't acquiring a real interactive debugger any time soon

TODO: have instances with different default tags but stil central master control of filtering
*/

NullLogger {
	/* this parent class provdes a black hole logger so that you can stop
	 logging without changing code. */
	formatMsg {|msgchunks, tag=\default, priority=0, time=true|
		var stamp;
		time.if({
			stamp =  [tag, priority, Date.gmtime.stamp];
		}, {
			stamp = [tag, priority];
		});
		^">>>"+(stamp ++ msgchunks).join("|")++"\n";
	}
	*new {|fileName|
		^super.new;
	}
	*newFromDate {|prefix|
		^this.new;
	}
	*global {
		^this.new;
	}
	*default {
		^this.new;
	}
	log {|msgchunks, tag=\default, priority=0, time=true|
		^this.formatMsg(tag:tag, priority:priority, msgchunks: msgchunks, time: time);
	}
	basicLog {|...msgargs|
		^this.log(msgchunks: msgargs);
	}
}
FileLogger : NullLogger {
	/* writes pipe-separated log messages to a file */
	classvar global;
	classvar default;
	classvar <>logpath = "~/Logs/Supercollider";
	
	var file;
	var <fileName;
	
	*new {|fileName|
		var file, thisLogPath;
		thisLogPath = PathName(logpath);
		fileName.isNil.if({
			"No log name supplied".throw;
		});
		File.exists(thisLogPath.fullPath).not.if({
			File.mkdir(thisLogPath.fullPath);
		});
		
		fileName = (thisLogPath +/+ fileName).fullPath;
		file = File.open(fileName, "a");
		^super.newCopyArgs(file, fileName);
	}
	*newFromDate {|prefix|
		var fileName;
		fileName = Date.gmtime.stamp;
		prefix.notNil.if({
			fileName = prefix ++ "-" ++ fileName ++ ".log";
		});
		^this.new(fileName);
	}
	*global {
		/* a shared, appendable log that all local supercolldier procs 
		can write to. */
		global.isNil.if({global = this.new("_global")});
		^global;
	}
	*default {
		/* a fresh, time-stamped logfile for your ease of logging */
		default.isNil.if({default = this.newFromDate});
		^default;
	}
	log {|msgchunks, tag=\default, priority=0, time=true, flush=true|
		var formatted = this.formatMsg(tag:tag, priority:priority, msgchunks: msgchunks, time: time);
		file.write(formatted);
		flush.if({file.flush;});
		^formatted;
	}
}
PostLogger : NullLogger {
	/* writes pipe-separated log messages to a the standard post window */
	classvar global;

	*global {
		/* a shared, appendable log that all local supercolldier procs 
		can write to. */
		global.isNil.if({global = this.new("_global")});
		^global;
	}
	*default {
		/* a fresh, time-stamped logfile for your ease of logging */
		^this.global;
	}
	log {|msgchunks, tag=\default, priority=0, time=true|
		^this.formatMsg(tag:tag, priority:priority, msgchunks: msgchunks, time: time).post;
	}
}