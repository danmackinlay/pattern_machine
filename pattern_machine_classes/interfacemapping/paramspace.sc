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
		stream << this.class.asString <<"(" << name << ", " << spec <<" )";
	}
	asPSParam { ^this }
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
	enact {
		arg val;
		action.value(spec.map(val), val);
	}
}
PSParamwalker {
	var <paramSpace;
	var <pos;
	var <savedPresets;
	var <speed;
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
		stream << this.class.asString <<"(" << paramSpace.asString << ", " << pos.asString <<" )";
	}
	save {
		arg i, state;
		state = state ? pos;
		i.isNil.if({
			savedPresets = savedPresets.add(state);
			i = savedPresets.size;
		}, {
			savedPresets[i] = state;
		});
		^i
	}
	load {
		arg i;
		pos = savedPresets[i];
	}
	step {
		var nDims, accel, scaleFactor;
		//track history
		history.add(pos);
		{(history.size)>nHistory}.while({
			history.popFirst;
		});
		//handle position updates
		nDims = vel.size;
		scaleFactor = nDims.sqrt;
		accel = {0.0.gaussian}.dup(vel.size);
		accel = accelMag * accel * scaleFactor/(accel.squared.sum.sqrt);
		vel = (vel + accel);
		vel = (vel * speed * scaleFactor)/(vel.squared.sum.sqrt);
		pos = pos + vel;
		//sticky-reflect off walls
		pos.do({|v,i| ((v-v.clip(0,1)) != 0).if({
			vel[i] = vel[i].neg;
		})});
		pos = pos.clip(0,1);
	}
	back {
		arg n=1;
		n.do({
			pos = history.pop;
		});
	}
	jump {
		vel = {0.0.gaussian}.dup(vel.size);
		pos = {1.0.rand}.dup(vel.size);
		this.step;
	}
	setFromEvent{
		arg evt;
		pos = paramSpace.presetFromEvent(evt);
	}
	event {
		^paramSpace.eventFromPreset(pos);
	}
	enact {
		paramSpace.enact(pos);
	}
}
//Cartography for your presets
//should this do MDS or something?
//Or pseudo-random correlate interpolation?2
PSParamAtlas {
	var presets;
	readFile {
		arg fileName;
		presets = fileName.parseYAMLFile;
	}
	writeFile {
		arg fileName;
		File.use(fileName, "w", {
			arg file;
			file.write(JSON.stringify(presets));
		});
	}
}