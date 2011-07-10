+ SequenceableCollection {
  indicesSuchThat {|fn|
    //Return list of indices matching fn. This is handy to .do things with later.
    fn.isNil.if({fn={|a| a;};});
    ^this.collect({|item, i|
      (fn.value(item, i)).if(
        {i},
        {nil})
      }).select(
        {|item, i| item.isNil.not;}
    );
  }
}
// see http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/too-many-Synthdefs-td5116364.html
+ InstrSynthDef { 
     *clearCache { arg server; 
         "Clearing AbstractPlayer SynthDef cache".inform; 
         if(Library.at(SynthDef, server).notNil and: { 
server.serverRunning }) { 
             Library.at(SynthDef, server).keysDo({ |key| 
                 server.sendMsg(\d_free, key); 
             }); 
         }; 
         Library.put(SynthDef,server,nil); 
     } 
}