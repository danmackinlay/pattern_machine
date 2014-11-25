//define a vector space on [0,1]^n

//This maps between numerical vectors and actions, and keeps all presets in the space coherent
PresetSpace {
	var <name;
	var <params;
	var <presets;
	var <paramCounter;
	var <presetCounter;
	//Unless you are restoring from disk or somesuch, you probably wish only to pass in the name, and MAYBE params
	*new {
		arg name, Params, presets, presetCounter, paramCounter;
		Params = Params ? Array.new;
		presets = presets ? Array.new;
		^super.newCopyArgs(
			name,
			params,
			presets,
			paramCounter ? Params.size,
			presetCounter ? presets.size,
		).initPresetSpace;
	}
	initPresetSpace {
		this.enforcePresetSanity;
	}
	nParams {
		^params.size;
	}
	enforcePresetSanity {
		presets.do({
			//count params?
		});
	}
	//preset vector factory
	newPreset {
		arg name, vals, params;
		var newPreset = PSPreset.new(
			name: name,
			vals: vals,
		);
		this.addPreset(newPreset);
		^newPreset;
	}
	addPreset {
		arg preset;
		presetCounter = presetCounter + 1;
		preset.name.isNil.if({
			preset.name_(\preset_ ++ presetCounter);
		});
		preset.presetSpace = this;
		preset.attach;
	}
	//preset vector factory
	newParam {
		arg name, spec, value, action;
		var newParam = PSParam.new(
			name: name,
			spec: spec,
			value: value,
			action: action,
		);
		this.addParam(newParam);
		^newParam;
	}
	addParam {
		arg param;
		paramCounter = paramCounter + 1;
		param.name.isNil.if({
			param.name_(\param_ ++ paramCounter);
		});
		param.presetSpace = this;
	}
	at {
		arg nameOrNum;
		
	}
}
//A vector in preset space; basically a vector with named entries
//Should I subclass array? yes,then it woudl be very simple
PSPreset[slot] : Array {
	var <>presetSpace;
	var <>name;
	var <vals;
	
	//probably shouldn't call this yourself.
	//construct it from the parent why not
	*new {
		arg presetSpace, name, vals;
		var nParams = 8, newPreset;
		presetSpace.notNil.if({nParams=presetSpace.nParams});
		newPreset = super.new(nParams);
		newPreset.name_(name);
		newPreset.presetSpace_(presetSpace);
		presetSpace.notNil.if({
			presetSpace.addPreset(newPreset);
		});
		^newPreset;
	}
	//called when attached to a PSPresetSpace
	attach {
		//replace nil in vals with default
		vals = vals.extend(presetSpace.params.size);
		vals.do({
			arg v,i;
			v.isNil.if({
				var param = presetSpace.params.at(i);
				vals[i] = param.unmap(param.default);
			});
		})
	}
	//could create accessors here but booooring
}
// 
PSParam {
	var <>presetSpace;
	var <name;
	var <spec;
	var <value; //should I just ignore this, or only use it for "special" Params?
	var <action;
	*new {
		arg presetSpace, name, spec, value, action;
		^super.newCopyArgs(
			presetSpace,
			name.asSymbol,
			spec.asSpec,
			value,
			FunctionList.new.addFunc(action)
		).initPSParam;
	}
	initPSParam{
		presetSpace.notNil.if({
			presetSpace.addParam(this);
		});
		^this;
	}
}