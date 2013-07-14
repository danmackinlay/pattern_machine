/*Gaussian copula business*/
//Todo: currenlty the (4 sigma) buffer is inefficient because 1) it is symmetric and 2) many samples are at the fringes. 
//      Thist coudl be made more efficient by polynomial warping and symmetrisation.
PSGaussCopula {
	classvar <arr_Erf, <arr_iErf;
	classvar <length=1025;
	classvar <dict_Servers;
	*initClass{
		StartUp.add({
			this.init;
		});
	}
	*init {
		dict_Servers = ();
		arr_Erf = Array.interpolation(length,-4,4).collect(_.gaussCurve).integrate.normalize;
		arr_iErf = Array.interpolation(length).collect({|v| arr_Erf.indexInBetween(v)}).normalize(-4,4);
	}
	*initServer {|server|
		var dict_serverBufs, servername = server.name;
		dict_serverBufs = IdentityDictionary.new;
		dict_Servers[servername] = dict_serverBufs;
		server.doWhenBooted({
			server.makeBundle(nil, {
				dict_serverBufs[\buf_Erf] = Buffer.alloc(server, length, 1);
				dict_serverBufs[\buf_iErf] = Buffer.alloc(server, length, 1);
				server.sync;
				dict_serverBufs[\buf_Erf].setn(0, arr_Erf);
				dict_serverBufs[\buf_iErf].setn(0, arr_iErf);
				[\making, servername, dict_Servers[servername], dict_Servers[servername].identityHash].postln;
			});
		});
		[\making2, servername, dict_Servers[servername], dict_Servers[servername].identityHash].postln;
		^dict_Servers[servername];
	}
	*buffersFor{|server|
		
		^dict_Servers.atFail(server.name, {this.initServer(server)});
	}
	*gaussianize {
		
	}
}