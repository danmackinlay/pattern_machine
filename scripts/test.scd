{"this is an error".throw}.try{|err| "caught %".format(err).postln;}
{Error("this is an error").throw}.try{|err| "caught %".format(err).postln; err.reportError;}
{5.nonsuchmethod}.try{|err| "caught %".format(err).postln;err.reportError;};
TestUnitTestErrorHandling.run(report:true);