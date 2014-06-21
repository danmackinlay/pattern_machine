//window & views
~nkW = Window(
	"KORG nanoKONTROL", Rect.fromPoints(5@5,1280@1050),
	resizable:false, border:false)
	.userCanClose_(false)
	.alwaysOnTop_(false);
~nkW.view.background = Gradient(
	Color.new(0.15,0.15,0.15),
	Color(0.06,0.06,0.06), \h, 1280
	);
~nkV = UserView(~nkW, Rect(0,0,1280,1016));
~nkV2 = UserView(~nkW, Rect(0,0,1280,320));

~nkV.canFocus = false;
~nkV2.canFocus = false;

//array lookup
//an internal reference array to prevent sliders and knobs from "jumping" after a scene switch
//real-time value of gui object MUST match lookup value before slider can be updated
~valueLookup = [	//reference array
	[0,0,0,0,0,0,0,0,0],	//sliders, scene 1
	[0,0,0,0,0,0,0,0,0],	//knobs, scene 1
	[0,0,0,0,0,0,0,0,0],	//sliders, scene 2
	[0,0,0,0,0,0,0,0,0],	//knobs, scene 2
	[0,0,0,0,0,0,0,0,0],	//sliders, scene 3
	[0,0,0,0,0,0,0,0,0],	//knobs, scene 3
	[0,0,0,0,0,0,0,0,0],	//sliders, scene 4
	[0,0,0,0,0,0,0,0,0]		//knobs, scene 4
];

//binary array indicating whether real-time slider value
//matches value when scene was last active
~valueMatched = [
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0]
];

if(~sceneArray == nil,
	{~sceneArray = [1,0,0,0]},{});
	
	
//titles, text, etc.
~korg = StaticText(~nkW, Rect(84,40,80,30))
	.string_("KORG")
	.font_(Font("HeadLineA", 30))
	.background_(Color.clear)
	.stringColor_(Color.gray(0.65))
	.align_(\center);
~nano = StaticText(~nkW, Rect(38,116,40,20))
	.string_("nano")
	.font_(Font("Calibri-Italic", 16))
	.background_(Color.gray(0.65))
	.stringColor_(Color.black)
	.align_(\center);
~kontrol = StaticText(~nkW, Rect(76,104,150,38))
	.string_("KONTROL")
	.font_(Font("Calibri-BoldItalic",30))
	.background_(Color.clear)
	.stringColor_(Color.gray(0.65))
	.align_(\center);
	
//numbers
~sceneNums = StaticText(~nkW, Rect(90,290,140,20))
	.string_("1   2   3   4")
	.font_(Font("HeadLineA",18))
	.background_(Color.clear)
	.stringColor_(Color.gray(0.55))
	.align_(\center);
~groupNum1 = StaticText(~nkW, Rect(284,74,14,28))
	.string_("1")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum2 = StaticText(~nkW, Rect(394,74,14,28))
	.string_("2")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum3 = StaticText(~nkW, Rect(504,74,14,28))
	.string_("3")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum4 = StaticText(~nkW, Rect(614,74,14,28))
	.string_("4")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum5 = StaticText(~nkW, Rect(724,74,14,28))
	.string_("5")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum6 = StaticText(~nkW, Rect(834,74,14,28))
	.string_("6")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum7 = StaticText(~nkW, Rect(944,74,14,28))
	.string_("7")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum8 = StaticText(~nkW, Rect(1054,74,14,28))
	.string_("8")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);
~groupNum9 = StaticText(~nkW, Rect(1164,74,14,28))
	.string_("9")
	.font_(Font("Helvetica-Bold",24))
	.background_(Color.clear)
	.stringColor_(Color.black);

//background patterns
~nkV.drawFunc = {
	Pen.strokeColor = Color.gray(0.65);
	Pen.fillColor = Color.gray(0.65);
	9.do{
		|n|
		var horz;
		horz = n*110+250;
		Pen.addRect(Rect.fromPoints(horz@100,horz+76@1020));
		Pen.line(horz@100,horz+76@100);
		Pen.lineTo(horz+76@0);
		Pen.lineTo(horz+66@0);
		Pen.lineTo(horz@100);
	};
	Pen.addRect(Rect.fromPoints(20@160,230@250));
	Pen.width = 3;
	Pen.line(20@104,230@104);
	Pen.fillStroke
};

//transport buttons
~rew = Button(~nkW, Rect.fromPoints(25@166,88@204))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
		])
	.action_({
		|but|
		if(but.value == 1,
			{"rewind".postln},{"rewind stopped".postln}
			);
		})
	.font_(Font("Courier-Bold",20))
	//.enabled_(false)
	.canFocus_(false);
~play = Button(~nkW, Rect.fromPoints(93@166,156@204))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{
				Routine {
					"play".postln;
					0.07.wait;
					but.value = 0;
				}.play(AppClock);
			},
			{});
		})
	.font_(Font("Courier-Bold",20))
	//.enabled_(false)
	.canFocus_(false);
~ff = Button(~nkW, Rect.fromPoints(161@166,226@204))
	.states_([
	["",Color.black,Color.gray(0.88)],
	["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"fast forward".postln},{"fast forward stopped".postln}
			);
		})
	.font_(Font("Courier-Bold",20))
	//.enabled_(false)
	.canFocus_(false);
~loop = Button(~nkW, Rect.fromPoints(26@210,88@246))
	.states_([
	["",Color.black,Color.gray(0.88)],
	["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"looping on".postln},{"looping off".postln}
			);
		})
	.font_(Font("Courier-Bold",20))
	//.enabled_(false)
	.canFocus_(false);
~stop = Button(~nkW, Rect.fromPoints(93@210,156@246))
	.states_([
	["",Color.black,Color.gray(0.88)],
	["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{
				Routine {
					"stop".postln;
					0.07.wait;
					but.value = 0;
				}.play(AppClock);
			},
			{});
		})
	.font_(Font("Courier-Bold",20))
	//.enabled_(false)
	.canFocus_(false);
~rec = Button(~nkW, Rect.fromPoints(161@210,226@246))
	.states_([
	["",Color.black,Color.gray(0.88)],
	["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{
				Routine {
					"record".postln;
					0.07.wait;
					but.value = 0;
				}.play(AppClock);
			},
			{});
		})
	.font_(Font("Courier-Bold",20))
	//.enabled_(false)
	.canFocus_(false);
~scene = Button(~nkW, Rect.fromPoints(26@258,88@292))
	.states_([
		["SCENE",Color.black,Color.gray(0.88)],
		["SCENE",Color.black,Color.new255(255,130,130)]
		])
	.action_({
		|but|
		if(but.value == 1,
			{
				Routine {
					0.07.wait;
					but.value = 0;
				}.play(AppClock);
			},
			{});
		})
	.font_(Font("Helvetica",14))
	//.enabled_(false)
	.canFocus_(false);


//transport button icons & scene division lines
~nkW.drawHook = {
	Pen.strokeColor = Color.black;
	Pen.fillColor = Color.black;
	Pen.width = 1;
	
	//rew
	Pen.line(46@184,55@177);
	Pen.lineTo(55@191);
	Pen.lineTo(46@184);
	Pen.line(55@184,64@177);
	Pen.lineTo(64@191);
	Pen.lineTo(55@184);
	
	//play
	Pen.line(134@184,116@177);
	Pen.lineTo(116@191);
	Pen.lineTo(134@184);
	
	//ff
	Pen.line(185@177,185@191);
	Pen.lineTo(194@184);
	Pen.lineTo(185@177);
	Pen.line(194@177,194@191);
	Pen.lineTo(203@184);
	Pen.lineTo(194@177);
	Pen.fill;
	
	//loop
	Pen.addArc(56@227,11,5pi/3,5pi/3);
	Pen.stroke;
	Pen.line(53@216,51@222);
	Pen.lineTo(47@216);
	Pen.lineTo(53@216);
	
	//stop
	Pen.addRect(Rect.fromPoints(117@220,131@234));
	Pen.fillStroke;
	
	//rec
	Pen.strokeColor = Color.red;
	Pen.fillColor = Color.red;
	Pen.addArc(192@228,8,0,2pi);
	Pen.fillStroke;
	
	//division lines
	Pen.strokeColor = Color.new(0.06,0.06,0.06);
	Pen.width = 3;
	Pen.line(248@261,1280@261);
	Pen.line(248@515,1280@515);
	Pen.line(248@769,1280@769);
	Pen.stroke;
};

//LEDs
~nkV2.drawFunc = {
	Pen.fillColor = Color.red;
	Pen.strokeColor = Color.red;
	Pen.addArc(108@275,6,0,2pi);
	Pen.fillStroke;
	Pen.fillColor = Color.red(0.4);
	Pen.strokeColor = Color.red(0.4);
	Pen.addArc(142@275,6,0,2pi);
	Pen.addArc(176@275,6,0,2pi);
	Pen.addArc(210@275,6,0,2pi);
	Pen.fillStroke;
};

//knobs
~knob1 = Knob(~nkW,Rect(303,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob2 = Knob(~nkW,Rect(413,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob3 = Knob(~nkW,Rect(523,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob4 = Knob(~nkW,Rect(633,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob5 = Knob(~nkW,Rect(743,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob6 = Knob(~nkW,Rect(853,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob7 = Knob(~nkW,Rect(963,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob8 = Knob(~nkW,Rect(1073,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob9 = Knob(~nkW,Rect(1183,16,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob10 = Knob(~nkW,Rect(303,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob11 = Knob(~nkW,Rect(413,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob12 = Knob(~nkW,Rect(523,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob13 = Knob(~nkW,Rect(633,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob14 = Knob(~nkW,Rect(743,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob15 = Knob(~nkW,Rect(853,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob16 = Knob(~nkW,Rect(963,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob17 = Knob(~nkW,Rect(1073,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob18 = Knob(~nkW,Rect(1183,270,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob19 = Knob(~nkW,Rect(303,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob20 = Knob(~nkW,Rect(413,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob21 = Knob(~nkW,Rect(523,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob22 = Knob(~nkW,Rect(633,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob23 = Knob(~nkW,Rect(743,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob24 = Knob(~nkW,Rect(853,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob25 = Knob(~nkW,Rect(963,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob26 = Knob(~nkW,Rect(1073,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob27 = Knob(~nkW,Rect(1183,524.40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob28 = Knob(~nkW,Rect(303,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob29 = Knob(~nkW,Rect(413,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob30 = Knob(~nkW,Rect(523,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob31 = Knob(~nkW,Rect(633,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob32 = Knob(~nkW,Rect(743,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob33 = Knob(~nkW,Rect(853,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob34 = Knob(~nkW,Rect(963,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob35 = Knob(~nkW,Rect(1073,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);
~knob36 = Knob(~nkW,Rect(1183,778,40,40))
	.background_(Color.clear)
	.color_([
		Color.black,
		Color.red,
		Color.gray(0.8),
		Color.gray(0.9)
		])
	//.enabled_(false)
	.canFocus_(false);

//sliders
~slider1 = Slider(~nkW,Rect(316,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider2 = Slider(~nkW,Rect(426,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider3 = Slider(~nkW,Rect(536,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider4 = Slider(~nkW,Rect(646,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider5 = Slider(~nkW,Rect(756,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider6 = Slider(~nkW,Rect(866,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider7 = Slider(~nkW,Rect(976,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider8 = Slider(~nkW,Rect(1086,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider9 = Slider(~nkW,Rect(1196,84,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider10 = Slider(~nkW,Rect(316,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider11 = Slider(~nkW,Rect(426,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider12 = Slider(~nkW,Rect(536,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider13 = Slider(~nkW,Rect(646,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider14 = Slider(~nkW,Rect(756,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider15 = Slider(~nkW,Rect(866,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider16 = Slider(~nkW,Rect(976,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider17 = Slider(~nkW,Rect(1086,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider18 = Slider(~nkW,Rect(1196,338,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider19 = Slider(~nkW,Rect(316,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider20 = Slider(~nkW,Rect(426,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider21 = Slider(~nkW,Rect(536,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider22 = Slider(~nkW,Rect(646,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider23 = Slider(~nkW,Rect(756,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider24 = Slider(~nkW,Rect(866,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider25 = Slider(~nkW,Rect(976,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider26 = Slider(~nkW,Rect(1086,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider27 = Slider(~nkW,Rect(1196,592,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider28 = Slider(~nkW,Rect(316,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider29 = Slider(~nkW,Rect(426,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider30 = Slider(~nkW,Rect(536,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider31 = Slider(~nkW,Rect(646,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider32 = Slider(~nkW,Rect(756,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider33 = Slider(~nkW,Rect(866,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider34 = Slider(~nkW,Rect(976,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider35 = Slider(~nkW,Rect(1086,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
~slider36 = Slider(~nkW,Rect(1196,846,22,146))
	.background_(Gradient(Color.gray(0.45),Color.gray(0.75),\h,30))
	.canFocus_(false)
	//.enabled_(false)
	.knobColor_(Color.red(0.85));
	
//buttons
~holdButton1 = Button(~nkW, Rect(266,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton1 down".postln},{"holdButton1 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton2 = Button(~nkW, Rect(376,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton2 down".postln},{"holdButton2 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton3 = Button(~nkW, Rect(486,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton3 down".postln},{"holdButton3 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton4 = Button(~nkW, Rect(596,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton4 down".postln},{"holdButton4 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton5 = Button(~nkW, Rect(706,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton5 down".postln},{"holdButton5 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton6 = Button(~nkW, Rect(816,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton6 down".postln},{"holdButton6 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton7 = Button(~nkW, Rect(926,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton7 down".postln},{"holdButton7 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton8 = Button(~nkW, Rect(1036,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton8 down".postln},{"holdButton8 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~holdButton9 = Button(~nkW, Rect(1146,118,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"holdButton9 down".postln},{"holdButton9 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);

~togButton1 = Button(~nkW, Rect(266,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton1 down".postln},{"togButton1 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton2 = Button(~nkW, Rect(376,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton2 down".postln},{"togButton2 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton3 = Button(~nkW, Rect(486,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton3 down".postln},{"togButton3 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton4 = Button(~nkW, Rect(596,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton4 down".postln},{"togButton4 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton5 = Button(~nkW, Rect(706,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton5 down".postln},{"togButton5 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton6 = Button(~nkW, Rect(816,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton6 down".postln},{"togButton6 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton7 = Button(~nkW, Rect(926,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton7 down".postln},{"togButton7 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton8 = Button(~nkW, Rect(1036,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton8 down".postln},{"togButton8 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);
~togButton9 = Button(~nkW, Rect(1146,190,25,25))
	.states_([
		["",Color.black,Color.gray(0.88)],
		["",Color.black,Color.new255(255,130,130)]
	])
	.action_({
		|but|
		if(but.value == 1,
			{"togButton9 down".postln},{"togButton9 up".postln}
			);
		})
	//.enabled_(false)
	.canFocus_(false);



//StaticText objects for displaying CC MIDI data (0-127)
//knob displays
~k1text = StaticText(~nkW,Rect(310,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k2text = StaticText(~nkW,Rect(420,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k3text = StaticText(~nkW,Rect(530,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k4text = StaticText(~nkW,Rect(640,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k5text = StaticText(~nkW,Rect(750,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k6text = StaticText(~nkW,Rect(860,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k7text = StaticText(~nkW,Rect(970,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k8text = StaticText(~nkW,Rect(1080,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k9text = StaticText(~nkW,Rect(1190,61,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k10text = StaticText(~nkW,Rect(310,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k11text = StaticText(~nkW,Rect(420,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k12text = StaticText(~nkW,Rect(530,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k13text = StaticText(~nkW,Rect(640,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k14text = StaticText(~nkW,Rect(750,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k15text = StaticText(~nkW,Rect(860,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k16text = StaticText(~nkW,Rect(970,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k17text = StaticText(~nkW,Rect(1080,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k18text = StaticText(~nkW,Rect(1190,315,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k19text = StaticText(~nkW,Rect(310,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k20text = StaticText(~nkW,Rect(420,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k21text = StaticText(~nkW,Rect(530,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k22text = StaticText(~nkW,Rect(640,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k23text = StaticText(~nkW,Rect(750,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k24text = StaticText(~nkW,Rect(860,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k25text = StaticText(~nkW,Rect(970,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k26text = StaticText(~nkW,Rect(1080,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k27text = StaticText(~nkW,Rect(1190,569,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k28text = StaticText(~nkW,Rect(310,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k29text = StaticText(~nkW,Rect(420,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k30text = StaticText(~nkW,Rect(530,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k31text = StaticText(~nkW,Rect(640,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k32text = StaticText(~nkW,Rect(750,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k33text = StaticText(~nkW,Rect(860,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k34text = StaticText(~nkW,Rect(970,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k35text = StaticText(~nkW,Rect(1080,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~k36text = StaticText(~nkW,Rect(1190,823,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));

//slider displays
~s1text = StaticText(~nkW,Rect(313,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s2text = StaticText(~nkW,Rect(423,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s3text = StaticText(~nkW,Rect(533,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s4text = StaticText(~nkW,Rect(643,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s5text = StaticText(~nkW,Rect(753,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s6text = StaticText(~nkW,Rect(863,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s7text = StaticText(~nkW,Rect(973,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s8text = StaticText(~nkW,Rect(1083,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s9text = StaticText(~nkW,Rect(1193,236,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s10text = StaticText(~nkW,Rect(313,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s11text = StaticText(~nkW,Rect(423,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s12text = StaticText(~nkW,Rect(533,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s13text = StaticText(~nkW,Rect(643,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s14text = StaticText(~nkW,Rect(753,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s15text = StaticText(~nkW,Rect(863,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s16text = StaticText(~nkW,Rect(973,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s17text = StaticText(~nkW,Rect(1083,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s18text = StaticText(~nkW,Rect(1193,490,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s19text = StaticText(~nkW,Rect(313,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s20text = StaticText(~nkW,Rect(423,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s21text = StaticText(~nkW,Rect(533,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s22text = StaticText(~nkW,Rect(643,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s23text = StaticText(~nkW,Rect(753,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s24text = StaticText(~nkW,Rect(863,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s25text = StaticText(~nkW,Rect(973,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s26text = StaticText(~nkW,Rect(1083,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s27text = StaticText(~nkW,Rect(1193,744,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s28text = StaticText(~nkW,Rect(313,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s29text = StaticText(~nkW,Rect(423,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s30text = StaticText(~nkW,Rect(533,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s31text = StaticText(~nkW,Rect(643,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s32text = StaticText(~nkW,Rect(753,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s33text = StaticText(~nkW,Rect(863,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s34text = StaticText(~nkW,Rect(973,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s35text = StaticText(~nkW,Rect(1083,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));
~s36text = StaticText(~nkW,Rect(1193,998,30,15))
	.string_("0")
	.align_(\center)
	.canFocus_(false)
	.background_(Color.gray(0.95))
	.font_(Font("Helvetica",14));

//close window
~closeWin = Button(~nkW,Rect(10,10,24,24))
	.states_([["X",Color.white,Color.red]])
	.action_({~nkW.close})
	.font_(Font("Helvetica",20));

//two arrays containing all sliders, knobs, and slider/knob texts.
//for easy lookup in CCResp function.
~guiArray = [
	~slider1,~slider2,~slider3,~slider4,~slider5,~slider6,~slider7,~slider8,~slider9,
	~knob1,~knob2,~knob3,~knob4,~knob5,~knob6,~knob7,~knob8,~knob9,
	~slider10,~slider11,~slider12,~slider13,~slider14,~slider15,~slider16,~slider17,~slider18,
	~knob10,~knob11,~knob12,~knob13,~knob14,~knob15,~knob16,~knob17,~knob18,
	~slider19,~slider20,~slider21,~slider22,~slider23,~slider24,~slider25,~slider26,~slider27,
	~knob19,~knob20,~knob21,~knob22,~knob23,~knob24,~knob25,~knob26,~knob27,
	~slider28,~slider29,~slider30,~slider31,~slider32,~slider33,~slider34,~slider35,~slider36,~knob28,
	~knob29,~knob30,~knob31,~knob32,~knob33,~knob34,~knob35,~knob36
];

~guiTextArray = [
	~s1text,~s2text,~s3text,~s4text,~s5text,~s6text,~s7text,~s8text,~s9text,
	~k1text,~k2text,~k3text,~k4text,~k5text,~k6text,~k7text,~k8text,~k9text,
	~s10text,~s11text,~s12text,~s13text,~s14text,~s15text,~s16text,~s17text,~s18text,
	~k10text,~k11text,~k12text,~k13text,~k14text,~k15text,~k16text,~k17text,~k18text,
	~s19text,~s20text,~s21text,~s22text,~s23text,~s24text,~s25text,~s26text,~s27text,
	~k19text,~k20text,~k21text,~k22text,~k23text,~k24text,~k25text,~k26text,~k27text,
	~s28text,~s29text,~s30text,~s31text,~s32text,~s33text,~s34text,~s35text,~s36text,
	~k28text,~k29text,~k30text,~k31text,~k32text,~k33text,~k34text,~k35text,~k36text
];

~nkW.front;

//respond to MIDI data
MIDIIn.connectAll;
~nkResp.remove;
~nkResp = CCResponder({
	|src, chan, num, val|
	var row, column;
	row = ((num-1)/9).floor;
	column = (num-1)%9;
	if(
		num <= 72,
		{
			if(
				~valueMatched[row][column] == 1,
				
				{
					~valueLookup[row][column] = val;
					{
						~guiTextArray.at(num-1).string_(val.asString);
						~guiArray.at(num-1).valueAction_(val/127);
					}.defer
				},
				
				{
					if(
						(val >= ((~valueLookup[row][column])-3)) && (val <= ((~valueLookup[row][column])+3)),
						{~valueMatched[row][column] = 1;},
						{}
					)
				}
			)
		},
		{
			case
			{num==73}{{~holdButton1.valueAction_(val/127)}.defer}
			{num==74}{{~holdButton2.valueAction_(val/127)}.defer}
			{num==75}{{~holdButton3.valueAction_(val/127)}.defer}
			{num==76}{{~holdButton4.valueAction_(val/127)}.defer}
			{num==77}{{~holdButton5.valueAction_(val/127)}.defer}
			{num==78}{{~holdButton6.valueAction_(val/127)}.defer}
			{num==79}{{~holdButton7.valueAction_(val/127)}.defer}
			{num==80}{{~holdButton8.valueAction_(val/127)}.defer}
			{num==81}{{~holdButton9.valueAction_(val/127)}.defer}
			{num==82}{{~togButton1.valueAction_(val/127)}.defer}
			{num==83}{{~togButton2.valueAction_(val/127)}.defer}
			{num==84}{{~togButton3.valueAction_(val/127)}.defer}
			{num==85}{{~togButton4.valueAction_(val/127)}.defer}
			{num==86}{{~togButton5.valueAction_(val/127)}.defer}
			{num==87}{{~togButton6.valueAction_(val/127)}.defer}
			{num==88}{{~togButton7.valueAction_(val/127)}.defer}
			{num==89}{{~togButton8.valueAction_(val/127)}.defer}
			{num==90}{{~togButton9.valueAction_(val/127)}.defer}
			{num==96}{{~rec.valueAction_(val/127)}.defer}
			{num==92}{{~play.valueAction_(val/127)}.defer}
			{num==95}{{~stop.valueAction_(val/127)}.defer}
			{num==91}{{~rew.valueAction_(val/127)}.defer}
			{num==93}{{~ff.valueAction_(val/127)}.defer}
			{num==94}{{~loop.valueAction_(val/127)}.defer};
		}
	)
});

//coordinate scene change LEDs
MIDIIn.sysex = {
	|src, sysex|
	{~scene.valueAction_(1)}.defer;
	//zero the binary matching array after every scene switch
	~valueMatched = [
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0]
	];
	~nkV2.drawFunc = {
		case
		{sysex[9]==0}{
			Pen.fillColor = Color.red;
			Pen.strokeColor = Color.red;
			Pen.addArc(108@275,6,0,2pi);
			Pen.fillStroke;
			Pen.fillColor = Color.red(0.4);
			Pen.strokeColor = Color.red(0.4);
			Pen.addArc(142@275,6,0,2pi);
			Pen.addArc(176@275,6,0,2pi);
			Pen.addArc(210@275,6,0,2pi);
		}
		{sysex[9]==1}{
			Pen.fillColor = Color.red;
			Pen.strokeColor = Color.red;
			Pen.addArc(142@275,6,0,2pi);
			Pen.fillStroke;
			Pen.fillColor = Color.red(0.4);
			Pen.strokeColor = Color.red(0.4);
			Pen.addArc(108@275,6,0,2pi);
			Pen.addArc(176@275,6,0,2pi);
			Pen.addArc(210@275,6,0,2pi);
		}
		{sysex[9]==2}{
			Pen.fillColor = Color.red;
			Pen.strokeColor = Color.red;
			Pen.addArc(176@275,6,0,2pi);
			Pen.fillStroke;
			Pen.fillColor = Color.red(0.4);
			Pen.strokeColor = Color.red(0.4);
			Pen.addArc(108@275,6,0,2pi);
			Pen.addArc(142@275,6,0,2pi);
			Pen.addArc(210@275,6,0,2pi);
		}
		{sysex[9]==3}{
			Pen.fillColor = Color.red;
			Pen.strokeColor = Color.red;
			Pen.addArc(210@275,6,0,2pi);
			Pen.fillStroke;
			Pen.fillColor = Color.red(0.4);
			Pen.strokeColor = Color.red(0.4);
			Pen.addArc(108@275,6,0,2pi);
			Pen.addArc(142@275,6,0,2pi);
			Pen.addArc(176@275,6,0,2pi);
		};
		Pen.fillStroke;
		~nkW.refresh;
	};
};

