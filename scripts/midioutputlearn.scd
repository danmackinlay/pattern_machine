MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");

w = Window.new("GUI Introduction", Rect(200,200,255,100));
b = Button.new(w,Rect(10,0,80,30)).states_([["Hide"],["Show"]]);
s = Slider.new(w,Rect(95,0,150,30));
c = CompositeView.new(w,Rect(20,35,100,60));
StaticText.new(c,Rect(0,0,80,30)).string_("Hello");
StaticText.new(c,Rect(20,30,80,30)).string_("World!");
b.action = { c.visible = b.value.asBoolean.not };
s.action = { c.bounds = Rect( s.value * 150 + 20, 35, 100, 100 ) };
w.front;

x.keyDownAction = {t.background = Color.green};
x.keyUpAction = ~reset;
y.keyDownAction = {t.background = Color.blue};
y.keyUpAction = ~reset;
~reset.value;