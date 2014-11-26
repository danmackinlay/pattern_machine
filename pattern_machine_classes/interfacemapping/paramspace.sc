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
	unmappedDef{
		arg nameOrNum;
		var param = this.at(nameOrNum);
		^param.unmap(param.default);
	}
	//preset vector factory
	newPreset {
		^Array.new(this.nParams)
	}
	newPresetDefault {
		^Array.new(this.nParams, {|i| this.unmappedDef(i)})
	}
	newPresetFill {
		arg fn;
		^Array.fill(this.nParams, fn)
	}
	newParam {
		arg name, spec, value, action;
		//note we don't set the paramspace in the first step
		var newParam = PSParam.new(
			name: name,
			spec: spec,
			value: value,
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
			"param already incldued".warn;
			^this;
		});
		paramCounter = paramCounter + 1;
		param.name.isNil.if({
			param.name_(\param_ ++ paramCounter);
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
}
// 
PSParam {
	var <name;
	var <spec;
	var <value; //should I just ignore this, or only use it for "special" Params?
	var <action;
	var <>paramSpace;
	*new {
		arg name, spec, value, action, paramSpace;
		^super.newCopyArgs(
			name,
			spec.asSpec,
			value,
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
	storeArgs { ^[name, spec, value, action] }
}