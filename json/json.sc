JsonParser {
	/*@
	shortDesc: JsonParser is a parser class for JSON-serialized documents
	longDesc: JSON is a lightweight format for serializing data and communication between languages. It supports hierarchical embedding of list and dictionary types and is spoken natively by browsers. This class supports decoding of strings using a single tokenization/parsing pass, which uses less memory than a two-pass process, but isn't as svelte as an evented stream decoder. Ah well.
	seeAlso: httpCOLON//json.org for the spec. 
	issues: Note that a full JSON implementation appears to imply utf-8 encoding, which supercollider is coy about its support for. This parser is a little over-liberal with regard to missing or surplus commas.
	instDesc: you must instantiate to use the parser, as state is stored in the instance. 
	longInstDesc: Instantiation takes no arguments; pass the string you want to decode to the <strong>decode</strong> method of an instance. All other methods should be considered private. The parser object is re-usable if you wish to keep it around to decode multiple strings.
	@*/
	
	var parseCursor, jsonString, thisToken, thisChar;

	decode { arg jsonstr;
		/*@
		desc: The public interface of the instance is this method. It sets up state then invokes sub parsers to walk through the string.
		jsonstr: the string of JSON to parse.
		ex:
		JsonParser.new.decode("[1,2,3]").postln ;
		
		@*/
		
		jsonString = jsonstr;
		parseCursor = 0;
		thisChar = jsonstr[parseCursor];
		^this.parseValue(jsonString);
	}
	parseValue {
		/*@
		desc: (Private.) Parse unspecified object - first consume whitespace until unambiguous token found - then delegate to parser based on that token. TODO-- handle premature json string ending and unknown characters.
		@*/
		var parsed;
		this.toCurrentToken();
		parsed = thisToken.switch(
			\TOKEN_SQUARED_OPEN, { this.parseArray(); },
			\TOKEN_STRING, { this.parseString(); },
			\TOKEN_ATOM, { this.parseAtom(); },
			\TOKEN_CURLY_OPEN, { ^this.parseObject(); },
			\TOKEN_NUMBER, { ^this.parseNumber(); } /*, 
			\TOKEN_NONE //hmmmm;
			\TOKEN_END //hmmmm*/
		);
		^parsed;
	}
	advanceCursor { arg inc=1;
		/*@
		desc: (Private.) advance the cursor by a specified increment - usually 1, since that is the length of most tokens.
		inc: cursor increment
		@*/
		parseCursor = parseCursor + inc;
		thisChar = jsonString[parseCursor];
	}
	toCurrentToken {
		/*@
		desc: (Private.) This method increments the cursor to the next non-whitespace character so that we are pointing to a real token.
		@*/
		this.eatWhiteSpace();
		
		if (parseCursor >= (jsonString.size),
			{ ^\TOKEN_END; });
		thisToken = switch (thisChar,
						 ${, { \TOKEN_CURLY_OPEN },
						 $}, { \TOKEN_CURLY_CLOSE },
						 $[, { \TOKEN_SQUARED_OPEN },
						 $], { \TOKEN_SQUARED_CLOSE },
						 $,, { \TOKEN_COMMA },
						 34.asAscii, { \TOKEN_STRING }, //my IDE hates unbalanced quotes
						 $0, { \TOKEN_NUMBER },
						 $1, { \TOKEN_NUMBER },
						 $2, { \TOKEN_NUMBER },
						 $3, { \TOKEN_NUMBER },
						 $4, { \TOKEN_NUMBER },
						 $5, { \TOKEN_NUMBER },
						 $6, { \TOKEN_NUMBER },
						 $7, { \TOKEN_NUMBER },
						 $8, { \TOKEN_NUMBER },
						 $9, { \TOKEN_NUMBER },
						 $-, { \TOKEN_NUMBER },
						 $+, { \TOKEN_NUMBER },
						 $:, { \TOKEN_COLON },
						 $f, { \TOKEN_ATOM },
						 $t, { \TOKEN_ATOM },
						 $n, { \TOKEN_ATOM },
						 nil, { \TOKEN_END },
						 { \TOKEN_UNKNOWN });
	}
	eatWhiteSpace {
		/*@
		desc: (Private.) if there is whitespace under the	cursor, fast forward until there is not.
		@*/
		while (
			{ 
				parseCursor < jsonString.size &&
				thisChar.isSpace }, 
			{ 
				this.advanceCursor; 
			}
		);
	}
	parseObject { 
		/*@
		desc: (Private.) The token under the cursor is the opening curly brace of an object. parse it and successive characters accordingly 
		@*/
		var newObject, name, value, done, lastPos;
		done = false;
		newObject = Event.new();
		// skip {
		this.advanceCursor();
		this.toCurrentToken();
		while ( 
			{ thisToken != \TOKEN_CURLY_CLOSE },
			{ 
				this.toCurrentToken(); //optionally skip spaces
				if ((lastPos == parseCursor), {
					Error("Object parse is stuck at %!".format(parseCursor)).throw;
				});
				lastPos = parseCursor.copy;
				if ((thisToken != \TOKEN_STRING), {
					Error(
						"no string key found in object at %".format(parseCursor)
					).throw;
				});
				name = this.parseString();
				this.toCurrentToken(); //optionally skip spaces
				if ((thisToken != \TOKEN_COLON), {
					Error(
						"no separator : found in object at %".format(parseCursor)
					).throw;
				});
				this.advanceCursor();
				value = this.parseValue();
				this.toCurrentToken();
				if ((thisToken == \TOKEN_COMMA), {
					//we consume commas without checking for spurious or missing ones
					//probably should be smarter.
					this.advanceCursor();
					this.toCurrentToken();
				});
				newObject[name] = value;
			}
		);
		
		// skip }
		this.advanceCursor();
		^newObject;
	}
	parseAtom {
		var lastPos, parsedVal;
		lastPos = parseCursor.copy;
		/*@
		desc: (Private.) The token under the cursor must be the start of [true|false|null].
		@*/
		
		parsedVal = case
			{ jsonString.containsStringAt(parseCursor, "false") } { 
				this.advanceCursor(5);
				false; }
			{ jsonString.containsStringAt(parseCursor, "true") } { 
				this.advanceCursor(4);
				true; }
			{ jsonString.containsStringAt(parseCursor, "null") } { 
				this.advanceCursor(4);
				nil; }
			{ true }{
				Error("unknown token '%' at % while parsing true/false/null".format(
					thisChar, parseCursor
				)).throw;
			};
		
		if ((lastPos == parseCursor), {
			Error("Atom parse at % while parsing atom".format(parseCursor)).throw;
		});
		^parsedVal;
	}
	parseArray {
		/*@
		desc: (Private.) The token under the is the opening brace of an array. Parse the successive characters as list contents.
		@*/
		var newArray;
		var lastPos;
		var done = false;
		newArray = [];
		lastPos = parseCursor.copy;
		
		//skip "["
		this.advanceCursor();
		
		while ( 
			{ (done == false) },
			{ 
				this.toCurrentToken(); //optionally skip spaces
				 if ((lastPos == parseCursor), {
					Error("Arrayparse is stuck at %!".format(parseCursor)).throw;
				});
				lastPos = parseCursor.copy;
				if ((thisToken == \TOKEN_SQUARED_CLOSE), {
					this.advanceCursor();
					 //skip "]"
					done = true;
				}, {
					newArray = newArray.add(this.parseValue);
					this.toCurrentToken();
					if ((thisToken == \TOKEN_COMMA), {
						//commas are skipped. we should *require* them.
						this.advanceCursor();
					});
				});
			}
		);
		^newArray;
	}
	parseString {
		var nextChar;
		var newString = "";
		var escaped = false;
		/*@
		desc: (Private.) The token under the cursor is the first quote of a string. Parse the accordingly. (this string parser is a rule unto itself; there is a smaller bestiary of tokens inside strings than in lists or arrays, so we do it all by hand.
		@*/
		
		this.advanceCursor();
		while (
			{
				(parseCursor < jsonString.size) &&
				((thisChar != 34.asAscii) || (escaped==true))
			},
			{
				if (((thisChar != $\\) || (escaped==true)) , {
						newString = newString ++ thisChar;
						escaped = false;
				}, {
						escaped = true;
				});
				this.advanceCursor();
			}
		);
		this.advanceCursor();
		
		//skip final quote mark
		^newString;
	}
	parseNumber {
		var nextChar;
		var numberString = "";
		var legalNumberChars = Set[$0, $1, $2, $3, $4, $5, $6, $7, $8, $9,
			$e, $E, $., $-, $+];
		/*@
		desc: (Private.) The token under the cursor is the start of a number. Eat tokens so long as they are plausibly numeric, then try to parse them using the asFloat method. Could do with better handling of malformed numbers (with multiple decimal points, minus signs, exponents etc)
		@*/
		
		while (
			{ (parseCursor < jsonString.size) &&
					legalNumberChars.includes(thisChar) },
			{
				numberString = numberString ++ thisChar;
				this.advanceCursor();
			}
		);
		^numberString.asFloat;
	}
}

