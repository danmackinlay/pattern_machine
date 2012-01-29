LogFile {
	/* writes pipe-separated log messages */
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
	log {|...msgargs|
		var formatted = this.formatMsg(msgargs);
		file.write(formatted);
		^formatted;
	}
	logFlush {|...msgargs|
		var formatted = this.log(*msgargs);
		file.flush;
		^formatted;
	}
	formatMsg {|msgs|
		var stampedMsgs = msgs;
		//A nil in the first msg argument will be replaced by a datestamp
		msgs[0].isNil.if({
			stampedMsgs = msgs.copy;
			stampedMsgs[0] = Date.gmtime.stamp;
		});
		^"|||"+stampedMsgs.join("|")++"\n";
	}
}