PSController {
  /*pass all server instructions through this guy to allow the instructions
  to be delivered in the right order and the boring bus/server allocation
  details to be abstracted away, and to track resources needing freeing.*/
  
  //Instance vars are all public to aid debugging, but, honestly, don't
  //touch 'em. Why would you touch them?
  var <server;
  var <queue;
  var <all;
  *new {|server|
    ^newCopyArgs(server).init;
  }
  init {
    all = IdentityDictionary.new;
    queue = (queue ?? {PSServerQueue.new(server);});
  }
  playIndividual {|phenome|
    NotYetImplementedError.new.throw;
  }
  freeIndividual {|phenome|
    NotYetImplementedError.new.throw;
  }
  updateFitnesses {
    Not YetImplementedError.new.throw;
  }
}

PSServerQueue {
  //a queue to service instructions, waiting on sync from a particular server
  var <server;
  var <fifo;
  var <worker;
  var flag;
  *new {|server|
    ^super.newCopyArgs(server ? Server.default).init;
  }
  init {
    fifo = LinkedList.new;
    flag = Condition.new(false);
    worker = Routine({
      loop {
        var job, result;
        job = fifo.pop;
        job.isNil.if({
          flag.hang;
        }, {
          server.sync;
          result = job.value;
        })
      }
    }).play;
  }
  push {|job|
    fifo.addFirst(job);
    flag.unhang;
  }
}