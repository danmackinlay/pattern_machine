/*
 * TODO - handle unicode escapes
 * call by name, ref or value semantics in the house?
 * Supercollider is from the land before 64 bit floats. Awkward.
 * Supercollider's unicode support is unspecified, but my heart is full of 
 *   fear.
 */

JsonParser {
  //SC has a broken parser w/r to escaped quotes
  var parsedIndex, jsonString, token;
  var depth;
  //start here
  decode { arg jsonstr;
    // light wrapper around parseValue; set up state and go.
    // The only public method.
    "decode".postln;
    jsonString = jsonstr;
    parsedIndex = 0;
    depth = 0;
    ^this.parseValue(jsonString);
  }
  parseValue {
    // Parse unknown object:
    // First, consume whitespace until unambiguous token found.
    // Then delegate to specific parser.
    var parsed;
    "parseValue".postln;
    this.toCurrentToken();
    "this token".postln;
    token.postln;
    "parsedIndex".postln;
    parsedIndex.postln;
    depth = depth + 1;
    if (depth > 20, {
      Error("recursion explosion").throw;
    });
    parsed = token.switch(
      \TOKEN_SQUARED_OPEN, { this.parseArray(); },
      \TOKEN_STRING, { this.parseString(); },
      \TOKEN_ATOM, { this.parseAtom(); },
      \TOKEN_CURLY_OPEN, { ^this.parseObject(); },
      \TOKEN_NUMBER, { ^this.parseNumber(); } /*, 
      \TOKEN_NONE //hmmmm;
      \TOKEN_END //hmmmm*/
    );
    "parseValue parsed %\n".postf(parsed);
    ^parsed;
  }
  advanceIndex { arg inc=1;
    "advancing index by %\n".postf(inc);
    parsedIndex = parsedIndex + inc;
  }
  toCurrentToken {
    "toCurrentToken".postln;
    
    this.eatWhiteSpace();
    
    if (parsedIndex >= (jsonString.size),
      { ^\TOKEN_END; });
    token = switch (jsonString[parsedIndex],
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
    "found token".postln;
    token.postln;
    "at".postln;
    parsedIndex.postln;
  }
  eatWhiteSpace {
    //look for whitespace under the current cursor, and advance it
    // until there is none
    "eatWhiteSpace".postln;
    parsedIndex.postln;
    jsonString[parsedIndex].postln;
    while (
      { 
        "maybe white space at".postln;
        parsedIndex.postln;
        " / ".postln;
        jsonString.size.postln;
        jsonString[parsedIndex].postln;
        parsedIndex < jsonString.size &&
        (jsonString[parsedIndex]).isSpace }, 
      { 
        this.advanceIndex; 
        "white space at".postln;
        parsedIndex.postln;
      }
    );
  }
  parseObject { 
    // Dict/Event parser. The index pointer is be set to a {
    var newObject, name, value, done, lastPos;
    done = false;
    newObject = Event.new();
    // skip {
    this.advanceIndex();
    this.toCurrentToken();
    while ( 
      { token != \TOKEN_CURLY_CLOSE },
      { 
        this.toCurrentToken(); //optionally skip spaces
        "in object % processing token %".postf(newObject, token);
        "current pos % last pos %\n".postf(parsedIndex, lastPos);
        if ((lastPos == parsedIndex), {
          Error("Object parse is stuck at %!".format(parsedIndex)).throw;
        });
        lastPos = parsedIndex.copy;
        if ((token != \TOKEN_STRING), {
          Error(
            "no string key found in object at %".format(parsedIndex)
          ).throw;
        });
        name = this.parseString();
        this.toCurrentToken(); //optionally skip spaces
        if ((token != \TOKEN_COLON), {
          Error(
            "no separator : found in object at %".format(parsedIndex)
          ).throw;
        });
        this.advanceIndex();
        value = this.parseValue();
        this.toCurrentToken();
        if ((token == \TOKEN_COMMA), {
          //we consume commas without checking for spurious or missing ones
          //probably should be smarter.
          this.advanceIndex();
          this.toCurrentToken();
        });
        newObject[name] = value;
      }
    );
    
    
    // skip }
    this.advanceIndex();
    ^newObject;
  }
  parseAtom {
    var lastPos, parsedVal;
    "parseAtom".postln;
    lastPos = parsedIndex.copy;
    //parses true/false/nil/ index pointer refers to $t/$f/$n
    parsedVal = case
      { jsonString.containsStringAt(parsedIndex, "false") } { 
        this.advanceIndex(5);
        false; }
      { jsonString.containsStringAt(parsedIndex, "true") } { 
        this.advanceIndex(4);
        true; }
      { jsonString.containsStringAt(parsedIndex, "null") } { 
        this.advanceIndex(4);
        nil; }
      { true }{
        Error("unknown token '%' at % while parsing true/false/null".format(
          jsonString[parsedIndex], parsedIndex
        )).throw;
      };
    
    if ((lastPos == parsedIndex), {
      Error("Atom parse at % while parsing atom".format(parsedIndex)).throw;
    });
    ^parsedVal;
  }
  parseArray { 
    // Array/List parser. The index pointer is set to a [
    // The swtich could be optimised away into a parseValue as per parseArray.
    var newArray;
    var lastPos;
    var done = false;
    newArray = [];
    "parseArray".postln;
    lastPos = parsedIndex.copy;
    
    this.advanceIndex(); //skip "["
    
    while ( 
      { (done == false) },
      { 
        this.toCurrentToken(); //optionally skip spaces
        "in array % processing token %".postf(newArray, token);
        "current pos % last pos %\n".postf(parsedIndex, lastPos);
        if ((lastPos == parsedIndex), {
          Error("Arrayparse is stuck at %!".format(parsedIndex)).throw;
        });
        lastPos = parsedIndex.copy;
        switch (token,
          \TOKEN_CURLY_OPEN, { 
            newArray = newArray.add(this.parseObject());
          },
          \TOKEN_SQUARED_OPEN, {
            newArray = newArray.add(this.parseArray());
          },
          \TOKEN_STRING, {
            newArray = newArray.add(this.parseString());
          },
          \TOKEN_NUMBER, {
            newArray = newArray.add(this.parseNumber());
          },
          \TOKEN_ATOM, {
            newArray = newArray.add(this.parseAtom());
          },
          \TOKEN_COMMA, {
            //commas are skipped. we should *require* them.
            this.advanceIndex();
          },
          \TOKEN_SQUARED_CLOSE, {
            "end array".postln;
            this.advanceIndex();
            done = true;
          },
          \TOKEN_END, { 
            Error("the string ended while parsing array");
          },
          {
            //raise some kind of parse error
            Error("unknown token '%' at % while parsing array".format(
              jsonString[parsedIndex], parsedIndex
            ));
          }
        );
      }
    );
    "Returning".postln;
    newArray.postln;
    ^newArray;
  }
  parseString {
    var nextChar;
    var newString = "";
    var esc = false;
    //String parser is a rule unto itself;
    //Much smaller bestiary of tokens inside strings, so we do it all by hand
    
    "parseString".postln;
    this.advanceIndex();
    while ( { 
      ( 
        (parsedIndex < jsonString.size) &&
        ((jsonString[parsedIndex] != 34.asAscii) || (esc==true))
      )},
      {
        if ( ( (jsonString[parsedIndex] != $\\) || (esc==true) ) , {
            newString = newString ++ (jsonString[parsedIndex]);
            esc = false;
        }, {
            esc = true;
        });
        this.advanceIndex();
      }
    );
    this.advanceIndex();
    
    //skip final quote mark
    "Returning".postln;
    ((34.asAscii) ++ newString ++ (34.asAscii)).postln;
    ^newString;
  }
  parseNumber {
    var nextChar;
    var numberString = "";
    var legalNumberChars = Set[$0, $1, $2, $3, $4, $5, $6, $7, $8, $9,
      $e, $E, $., $-, $+];
    /*@
    desc: (Private.) The token under the cursor is the start of a number. Eat tokens so long as they are plausibly numeric, then try to parse them using the asFloat method. Could do with better handling of malformed numbers (with multiple decimal points, minus signs, exponenets etc)
    @*/
    
    "parseNumber".postln;
    while (
      { (parsedIndex < jsonString.size) &&
          legalNumberChars.includes(jsonString[parsedIndex]) },
      {
        "digit %".postf(jsonString[parsedIndex]);
        numberString = numberString ++ (jsonString[parsedIndex]);
        this.advanceIndex();
      }
    );
    "Returning %".postf(numberString);
    ^numberString.asFloat;
  }
}

