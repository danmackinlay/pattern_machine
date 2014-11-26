//define a vector space on [0,1]^n

//This maps between numerical vectors and actions
PSParamSpace {
	var <name;
	var <params;
	var <paramCounter;
	var <presetCounter;
	//Unless you are restoring from disk or somesuch, you probably wish only to pass in the name, and MAYBE params
	*new {
		arg name, params, paramCounter;
		params = params ? Array.new;
		^super.newCopyArgs(
			name ? \paramspace,
			params,
			paramCounter ? params.size,
		).initPSParamSpace;
	}
	initPSParamSpace {
		//nothing atm
	}
	nParams {
		^params.size;
	}
	paramNames {
		^params.collect(_.name);
	}
	default {
		arg nameOrNum;
		^this.at(nameOrNum).default;
	}
	//preset vector factory
	//Array of correct length, but all nils
	newPreset {
		^Array.fill(this.nParams)
	}
	newPresetDefault {
		^Array.fill(this.nParams, {|i| this.default(i)})
	}
	newPresetZeros {
		^Array.fill(this.nParams, 0)
	}
	newPresetOnes {
		^Array.fill(this.nParams, 1)
	}
	//like Array.fill but we additionally pass in the param object
	newPresetFill {
		arg fn;
		var newPreset = this.newPreset;
		this.nParams.do({
			arg i;
			newPreset[i] = fn.value(i, params[i]);
		});
		^newPreset;
	}
	newParam {
		arg name, spec, action;
		//note we don't set the paramspace in the first step
		var newParam = PSParam.new(
			name: name,
			spec: spec,
			action: action, //should i ditch actions? hard to serialise, opaque.
		);
		//paramspace will be set here
		this.addParam(newParam);
		^newParam;
	}
	addParam {
		arg param;
		params.includes(param).if({
			//not sure if this does the right thing w/r/t identity/equality
			("param % already included".format(param.name)).warn;
			^this;
		});
		this.paramNames.includes(param.name).if({
			("param % already included".format(param.name)).warn;
			^this;
		});
		paramCounter = paramCounter + 1;
		param.name.isNil.if({
			param.prName_(\param_ ++ paramCounter);
		});
		param.paramSpace = this;
		params = params.add(param);
	}
	at {
		arg nameOrNum;
		nameOrNum.isInteger.if({
			^params[nameOrNum];
		}, {
			^params.select({|p| p.name==nameOrNum})[0];
		});
	}
	storeArgs { ^[name, params, paramCounter] }
	presetFromEvent{
		arg evt;
		var paramNames = this.paramNames;
		^this.newPresetFill({
			arg i, param;
			param.unmap(evt[paramNames[i]]);
		});
	}
	eventFromPreset{
		arg vec;
		var evt;
		evt = Event.new(this.nParams);
		vec.do({
			arg val, i;
			var param = params[i];
			evt[param.name] = param.map(val);
		});
		^evt
	}
	map {
		arg vec;
		^vec.collect({
			arg v, i;
			params[i].map(v)
		})
	}
	unmap {
		arg vec;
		^vec.collect({
			arg v, i;
			params[i].unmap(v)
		})
	}
}
// 
PSParam {
	var <name;
	var <spec;
	var <action;
	var <>paramSpace;
	*new {
		arg name, spec, action, paramSpace;
		^super.newCopyArgs(
			name,
			spec.asSpec,
			FunctionList.new.addFunc(action),
			paramSpace,
		).initPSParam;
	}
	initPSParam {
		paramSpace.notNil.if({
			paramSpace.addParam(this);
		});
		^this;
	}
	//pseudo-private because if you change two names to the same, weird stuff will happen
	prName_{
		arg newName;
		name = newName.asSymbol;
	}
	//quasi-passthru to spec, except unmapped values are prime for us.
	default {
		^spec.unmap(spec.default);
	}
	defaultMapped {
		spec.default;
	}
	map {
		arg val;
		^spec.map(val)
	}
	unmap {
		arg val;
		^spec.unmap(val)
	}
	storeArgs { ^[name, spec, action] }
}