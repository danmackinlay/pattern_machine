/*
 ***************
 define a vector space on [0,1]^n
TODO: easy paramspace exploration
TODO: Instr-style tree-based library?
TODO: YAML serialization.
*/

//This maps between numerical vectors and actions
PSParamSpace {
	var <name;
	var <params;
	var <paramCounter;
	//Unless you are restoring from disk or somesuch,
	//you probably wish only to pass in the name, and MAYBE params
	*new {
		arg name, params, paramCounter;
		params = params ? Array.new;
		^super.newCopyArgs(
			name ? \paramspace,
			params.collect(_.asPSParam),
			paramCounter ? params.size,
		).initPSParamSpace;
	}
	initPSParamSpace {
		//nothing atm
	}
	storeArgs { ^[name, params, paramCounter]}
	printOn { arg stream;
		stream << this.class.asString <<"(" << name << ", " << params.asString <<" )";
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
	//create and bind a param
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
		//^newParam;
	}
	//bind an existing param to me
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
			param.prName_((\param_ ++ paramCounter).asSymbol);
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
	keys {
		^params.collect({arg param; param.name})
	}
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
		var evt = Event.new(this.nParams);
		vec.do({
			arg val, i;
			var param = params[i];
			evt[param.name] = param.map(val);
		});
		^evt
	}
	pairsFromPreset {
		arg vec;
		var pairs = Array.new(this.nParams);
		vec.do({
			arg val, i;
			var param = params[i];
			pairs[2*i] = param.name;
			pairs[2*i+1] = param.map(val);
		});
		^pairs
	}
	enact {
		arg vec;
		vec.do({
			arg val, i;
			var param = params[i];
			param.enact(val);
		});
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
	storeArgs { ^[name, spec, action] }
	printOn { arg stream;
		stream << this.class.asString <<"(" << name << " )";
	}
	asPSParam { ^this }
	//pseudo-private because if you change two names to the same, weird stuff will happen
	prName_{
		arg newName;
		name = newName.asSymbol;
	}
	//quasi-passthru to spec, except unmapped values are prime for us.
	default {
		^spec.unmap(spec.default).asFloat;
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
	enact {
		arg val;
		action.value(spec.map(val), val);
	}
}
//incremental param perturber
//TODO:  handle a dynamic subset of the paramspace's vars
PSParamwalker {
	var <paramSpace;
	var <pos;
	var <savedPresets;
	var <>speed;
	var <accelMag;
	var <vel;
	var <>nHistory;
	var <history;

	*new {
		arg paramSpace,
			pos,
			savedPresets,
			speed=0.1,
			accelMag=0.1,
			vel,
			nHistory=100,
			history;
		pos = pos ?? {paramSpace.newPresetDefault};
		^super.newCopyArgs(
			paramSpace,
			pos,
			savedPresets ?? [],
			speed,
			accelMag,
			vel ?? paramSpace.newPresetOnes,
			nHistory,
			LinkedList.newFrom(history ? []),
		).initPSParamwalker;
	}
	initPSParamwalker {
		//nowt, for the minute
	}
	storeArgs { ^[paramSpace, pos, savedPresets, speed, accelMag, vel, nHistory] }
	printOn { arg stream;
		stream << this.class.asString <<"(" << paramSpace.name << ", " << pos.asString <<" )";
	}
	save {
		arg meta;
		savedPresets = savedPresets.add(
			IdentityDictionary.newFrom(
				(preset: pos)
			).putAll(meta)
		);
	}
	load {
		arg i;
		pos = savedPresets[i].preset;
	}
	//record current values in history
	remember {
		history.add(pos);
		{(history.size)>nHistory}.while({
			history.popFirst;
		});
	}
	//rescale vel to unity
	normalizeVel {
		vel = vel/(vel.squared.sum.sqrt);
	}
	// clip pos and reflect vel if nec.
	normalizePos{
		//sticky-reflect off walls
		pos.do({|v,i| ((v-v.clip(0,1)) != 0).if({
			vel[i] = vel[i].neg;
		})});
		pos = pos.clip(0,1);
	}
	//random step
	step {
		var nDims, accel, scaleFactor;
		//random position perturbation
		nDims = vel.size;
		scaleFactor = nDims.sqrt;
		accel = {0.0.gaussian}.dup(vel.size);
		accel = accelMag * accel * scaleFactor/(accel.squared.sum.sqrt);
		vel = (vel + accel);
		this.normalizeVel;
		pos = pos + (vel * speed * scaleFactor);
		this.normalizePos;
		this.remember;
	}
	back {
		arg n=1;
		n.do({
			pos = history.pop;
		});
	}
	pos_ {
		arg vec;
		pos = vec;
		this.remember;
	}
	jump {
		vel = {0.0.gaussian}.dup(vel.size);
		pos = {1.0.rand}.dup(vel.size);
		this.normalizeVel;
		this.remember;
	}
	setFromEvent{ arg evt;
		pos = paramSpace.presetFromEvent(evt);
	}
	event {
		^paramSpace.eventFromPreset(pos);
	}
	pairs {
		^paramSpace.pairsFromPreset(pos);
	}
	enact {
		paramSpace.enact(pos);
	}
	asStream { ^Routine({ arg inval; this.embedInStream(inval) }) }
	embedInStream { arg event;
		while {
			event.notNil;
		}{
			var modEvent;
			this.step;
			modEvent = event.copy.putAll(this.event);
			event = modEvent.yield;
		}
		^event;
	}
	readFile {
		arg fileName, presetData;
		presetData = fileName.parseYAMLFile;
		savedPresets = presetData[\presets];
	}
	writeFile {
		arg fileName, presetData;
		presetData = IdentityDictionary.new;
		presetData[\presets] = savedPresets;
		File.use(fileName, "w", {
			arg file;
			file.write(JSON.stringify(presetData));
		});
	}
	gui {
		^ParamWalkerGui(this)
	}
}

