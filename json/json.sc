/*
 * TODO - handle unicode escapes
 *
 * Supercollider is from the land before 64 bit floats. Awkward.
 * Supercollider's unicode support is unspecified, but my heart is full of 
 *   fear.
 */

JsonParser {
  //SC has a broken parser w/r to escaped quotes
  var parsedIndex, jsonString, thisToken, thisChar;
  //start here
  decode { arg jsonstr;
    // light wrapper around parseValue; set up state and go.
    // The only public method.
    jsonString = jsonstr;
    parsedIndex = 0;
    ^this.parseValue(jsonString);
  }
  parseValue {
    // Parse unknown object:
    // First, consume whitespace until unambiguous token found.
    // Then delegate to specific parser.
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
  advanceIndex { arg inc=1;
    parsedIndex = parsedIndex + inc;
    thisChar = jsonString[parsedIndex];
  }
  toCurrentToken {
    this.eatWhiteSpace();
    
    if (parsedIndex >= (jsonString.size),
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
    //look for whitespace under the current cursor, and advance it
    // until there is none
    while (
      { 
        parsedIndex < jsonString.size &&
        thisChar.isSpace }, 
      { 
        this.advanceIndex; 
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
      { thisToken != \TOKEN_CURLY_CLOSE },
      { 
        this.toCurrentToken(); //optionally skip spaces
        if ((lastPos == parsedIndex), {
          Error("Object parse is stuck at %!".format(parsedIndex)).throw;
        });
        lastPos = parsedIndex.copy;
        if ((thisToken != \TOKEN_STRING), {
          Error(
            "no string key found in object at %".format(parsedIndex)
          ).throw;
        });
        name = this.parseString();
        this.toCurrentToken(); //optionally skip spaces
        if ((thisToken != \TOKEN_COLON), {
          Error(
            "no separator : found in object at %".format(parsedIndex)
          ).throw;
        });
        this.advanceIndex();
        value = this.parseValue();
        this.toCurrentToken();
        if ((thisToken == \TOKEN_COMMA), {
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
    lastPos = parsedIndex.copy;
    //parses true/false/nil/
    //index pointer refers to $t/$f/$n
    
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
          thisChar, parsedIndex
        )).throw;
      };
    
    if ((lastPos == parsedIndex), {
      Error("Atom parse at % while parsing atom".format(parsedIndex)).throw;
    });
    ^parsedVal;
  }
  parseArray { 
    // Array/List parser. The index pointer is set to a [

    var newArray;
    var lastPos;
    var done = false;
    newArray = [];
    lastPos = parsedIndex.copy;
    
    //skip "["
    this.advanceIndex();
    
    while ( 
      { (done == false) },
      { 
        this.toCurrentToken(); //optionally skip spaces
         if ((lastPos == parsedIndex), {
          Error("Arrayparse is stuck at %!".format(parsedIndex)).throw;
        });
        lastPos = parsedIndex.copy;
        if ((thisToken == \TOKEN_SQUARED_CLOSE), {
          this.advanceIndex();
           //skip "]"
          done = true;
        }, {
          newArray = newArray.add(this.parseValue);
          this.toCurrentToken();
          if ((thisToken == \TOKEN_COMMA), {
            //commas are skipped. we should *require* them.
            this.advanceIndex();
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
    //String parser is a rule unto itself;
    //Much smaller bestiary of tokens inside strings, so we do it all by hand
    
    this.advanceIndex();
    while (
      {
        (parsedIndex < jsonString.size) &&
        ((thisChar != 34.asAscii) || (escaped==true))
      },
      {
        if (((thisChar != $\\) || (escaped==true)) , {
            newString = newString ++ thisChar;
            escaped = false;
        }, {
            escaped = true;
        });
        this.advanceIndex();
      }
    );
    this.advanceIndex();
    
    //skip final quote mark
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
    
    while (
      { (parsedIndex < jsonString.size) &&
          legalNumberChars.includes(thisChar) },
      {
        numberString = numberString ++ thisChar;
        this.advanceIndex();
      }
    );
    ^numberString.asFloat;
  }
}

