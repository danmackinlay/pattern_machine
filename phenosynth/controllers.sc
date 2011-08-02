PSController {
  /*pass all server instructions through this guy to allow the instructions
  to be delivered in the right order and the boring bus/server allocation
  details to be abstracted away, and to track resources needing freeing.*/
  
  //Instance vars are all public to aid debugging, but, honestly, don't
  //touch them. Why would you touch them?
  var <phenoFactory;
  var <outBus;
  var <numChannels;
  var <q; //i.e. a Queue.
  var <server;
  var <all;
  var <playGroup;
  *new {|server, phenoFactory, bus, numChannels=2, q|
    ^super.newCopyArgs(phenoFactory, bus, numChannels, q).init(server);
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
    all.put(phenome.identityHash, (\phenome: phenome));
  }
  freeIndividual {|phenome|
    var freed = all.at(phenome.identityHash);
    all.removeAt(phenome.identityHash);
    ^freed;
  }
  updateFitnesses {
    NotYetImplementedError.new.throw;
  }
}

PSListenInstrController : PSController {
  var <fitnessPollInterval;
  var <listenGroup;
  var <worker;
  *new {|server, phenoFactory, bus, numChannels=2, q, fitnessPollInterval=1|
    ^super.newCopyArgs(phenoFactory, bus, numChannels, q).init(
      server, fitnessPollInterval);
  }
  init {|serverOrGroup, thisFitnessPollInterval|
    super.init(serverOrGroup);
    fitnessPollInterval = thisFitnessPollInterval;
    q.push({listenGroup = Group.after(playGroup);});
  }
}

//Factory instances 
PSPhenosynthFactory {}

PSInstrPhenosynthFactory : PSPhenosynthFactory {}

PSServerQueue {
  //a queue to service instructions, waiting on sync from a particular server
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
      loop {
        var job, result;
        job = fifo.pop;
        job.isNil.if({
          doneFlag.hang;
        }, {
          server.sync;
          result = job.value;
        })
      }
    }).play;
  }
  push {|job|
    fifo.addFirst(job);
    doneFlag.unhang;
  }
}