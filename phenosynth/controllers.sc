PSController {
  /*pass all server instructions through this guy to allow the instructions
  to be delivered in the right order and the boring bus/server allocation
  details to be abstracted away, and to track resources needing freeing.*/
  
  //Instance vars are all public to aid debugging, but, honestly, don't
  //touch them. Why would you touch them?
  var <outBus;
  var <numChannels;
  var <q; //i.e. a Queue.
  var <server;
  var <all;
  var <playGroup;
  *new {|server, bus, numChannels=2, q|
    ^super.newCopyArgs(bus, numChannels, q).init(server);
  }
  init {|serverOrGroup|
    all = IdentityDictionary.new;
    serverOrGroup.isKindOf(Group).if(
      {
        server = serverOrGroup.server;
        q ?? {q = PSServerQueue.new(server);};
        playGroup = serverOrGroup;
      }, {
        server = serverOrGroup;
        q ?? {q = PSServerQueue.new(server);};
        q.push({playGroup = Group.head(server);});
      }
    );
    outBus ?? {q.push({outBus = Bus.audio(server, numChannels)});};
  }
  playIndividual {|phenome|
    //this doesn't actually play - it sets up a callback to play
    q.push({
      var indDict;
      indDict = this.getIndividualDict(phenome);
      this.loadIndividualDict(
        indDict
      );
      this.actuallyPlay(indDict);
    });
  }
  loadIndividualDict{|indDict|
    all.put(indDict.phenome.identityHash, indDict);
  }
  getIndividualDict {|phenome|
    //this doesn't need to be called in the server queue;
    //but in general, one could so need.
    ^(\phenome: phenome,
      \playBus: outBus
    );
  }
  actuallyPlay {|indDict|
    q.push({
      indDict.phenome.play(out:indDict.playBus, group:playGroup);
    });
  }
  freeIndividual {|phenome|
    var freed = all.at(phenome.identityHash);
    all.removeAt(phenome.identityHash);
    ^freed;
  }
}

PSListenSynthController : PSController {
  /* Handle a number of simultaneous synths being digitally listened to
  */
  var <fitnessPollInterval;
  var <listenGroup;
  var <worker;
  classvar <listenSynth = \ps_listen_eight_hundred;
  *new {|server, bus, numChannels=2, q, fitnessPollInterval=1|
    ^super.newCopyArgs(bus, numChannels, q).init(
      server, fitnessPollInterval);
  }
  init {|serverOrGroup, thisFitnessPollInterval|
    var clock;
    super.init(serverOrGroup);
    fitnessPollInterval = thisFitnessPollInterval;
    q.push({listenGroup = Group.after(playGroup);});
    clock = TempoClock.new(fitnessPollInterval.reciprocal, 1);
    worker = Routine.new({loop {this.updateFitnesses; 1.wait;}}).play(clock);
  }
  getIndividualDict {|phenome|
    ^(\phenome: phenome,
      \playBus: Bus.audio(server, numChannels),
      \listenBus: Bus.control(server, 1)
    )
  }
  actuallyPlay {|indDict|
    q.push({
      indDict.phenome.play(out:indDict.playBus, group:playGroup);
      Synth(this.class.listenSynth, this.getListenSynthArgs(indDict));
    });
  }
  getListenSynthArgs{|indDict|
    ^[\in, indDict.playBus];
  }
  freeIndividual {|phenome|
    var freed = super.freeIndividual(phenome);
    ^freed;
  }
  updateFitnesses {
    all.do({|id, phenome|
      ['tick', id, phenome].postln;
    });
  }
}

PSServerQueue {
  /*a queue to service instructions, waiting on sync from a particular server
  
  I know this looks overblown, but it sure does stop the wacky, unpredictable
  explosions I was having before.
  */
  var <server;
  var <fifo;
  var <worker;
  var doneFlag;//internal condition for list servicing
//  var <emptyFlag;//external signal that the list is empty - not implemented
  *new {|server|
    ^super.newCopyArgs(server ? Server.default).init;
  }
  init {
    fifo = LinkedList.new;
    doneFlag = Condition.new(false);
    worker = Routine({
      var job, result;
      loop {
        job = fifo.pop;
        job.isNil.if({
          doneFlag.hang;
        }, {
          result = job.value;
          server.sync;
        })
      }
    }).play;
  }
  push {|job|
    fifo.addFirst(job);
    doneFlag.unhang;
  }
}