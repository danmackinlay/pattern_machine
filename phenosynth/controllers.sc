PSController {
  /*pass all server instructions through this guy to allow the instructions
  to be delivered in the right order and the boring bus/server allocation
  details to be abstracted away, and to track resources needing freeing.*/
  
  //Instance vars are all public to aid debugging, but, honestly, don't
  //touch them. Why would you touch them?
  var <server;
  var <queue;
  var <all;
  var <group;
  var <numChannels;
  *new {|serverOrGroup|
    ^super.new.init(serverOrGroup);
  }
  init {|serverOrGroup|
    all = IdentityDictionary.new;
    serverOrGroup.isKindOf(Group).if(
      {
        server = serverOrGroup.server;
        queue = PSServerQueue.new(server);
        group = serverOrGroup;
      }, {
        server = serverOrGroup;
        queue = PSServerQueue.new(server);
        queue.push({group = Group.head(server);});
      }
    );
  }
  playIndividual {|phenome|
    NotYetImplementedError.new.throw;
  }
  freeIndividual {|phenome|
    NotYetImplementedError.new.throw;
  }
  updateFitnesses {
    NotYetImplementedError.new.throw;
  }
}

PSServerQueue {
  //a queue to service instructions, waiting on sync from a particular server
  var <server;
  var <fifo;
  var <worker;
  var <doneFlag;
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