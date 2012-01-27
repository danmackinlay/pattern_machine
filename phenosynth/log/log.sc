LogFile {
	/* writes pipe-separated log messages */
	classvar <globalLog;
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
		fileName = Date.gmtime.format("%Y-%m-%d-%H:%M:%S");
		prefix.notNil.if({
			fileName = prefix ++ "-" ++ fileName ++ ".log";
		});
		^this.new(fileName);
	}
	log {|...msgargs|
		file.write(this.formatMsg(msgargs));
	}
	logFlush {|...msgargs|
		file.write(this.formatMsg(msgargs));
		file.flush;
	}
	formatMsg {|msgs|
		^"|||"+msgs.join("|")++"\n";
	}
}