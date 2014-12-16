PhiWarp : LinearWarp {
	classvar <lowcut;
	classvar <highcut;
	classvar <lowinvcut;
	classvar <highinvcut;
	
	*initClass {
		StartUp.add({
			Warp.warps[\phi] = PhiWarp;
			lowcut = PSPhi(-3);
			highcut = PSPhi(3);
			lowinvcut = PSInvPhi(lowcut);
			highinvcut = PSInvPhi(highcut);
		});
	}
	
	map { arg value;
		// maps a value from [0..1] to spec range
		^super.map(
			PSPhi(value.linlin(0.0, 1.0, lowinvcut, highinvcut)
			).linlin(lowcut, highcut,0.0, 1.0));
	}
	unmap { arg value;
		// maps a value from spec range to [0..1]
		^PSInvPhi(
			super.unmap(value).linlin(0.0,1.0,lowcut, highcut)
		).linlin(lowinvcut, highinvcut, 0.0, 1.0)
	}
}
InvPhiWarp : LinearWarp {
	classvar <lowcut;
	classvar <highcut;
	classvar <lowinvcut;
	classvar <highinvcut;
	
	*initClass {
		StartUp.add({
			Warp.warps[\invphi] = InvPhiWarp;
			lowcut = PSPhi(-3);
			highcut = PSPhi(3);
			lowinvcut = PSInvPhi(lowcut);
			highinvcut = PSInvPhi(highcut);
		});
	}
	map { arg value;
		// maps a value from spec range to [0..1]
		^PSInvPhi(
			super.unmap(value).linlin(0.0,1.0,lowcut, highcut)
		).linlin(lowinvcut, highinvcut, 0.0, 1.0)
	}
	unmap { arg value;
		// maps a value from [0..1] to spec range
		^super.map(
			PSPhi(value.linlin(0.0, 1.0, lowinvcut, highinvcut)
			).linlin(lowcut, highcut,0.0, 1.0));
	}
}
