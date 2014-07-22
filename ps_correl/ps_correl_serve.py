from OSC import OSCClient, OSCMessage, OSCServer

OSCServer.timeout = 0.01

def serve(tree, wavdata, ps_correl_port, n_results, sc_synth_port, bus_num):
    all_corrs = wavdata['all_corrs']
    sample_times = wavdata['sample_times']
    amps = wavdata['amp']
    
    sc_synth_facing_server = OSCServer(("127.0.0.1", ps_correl_port))
    sc_synth_client = sc_synth_facing_server.client
    sc_synth_facing_server.addDefaultHandlers()

    def transect_handler(osc_path=None, osc_tags=None, osc_args=None, osc_source=None):
        node = osc_args[0]
        idx = osc_args[1]
        curr_amp = float(osc_args[2])
        lookup = osc_args[3:] #ignores the amplitude
        dists, indices = tree.query(lookup, k=n_results, return_distance=True)
        dists = dists.flatten()
        indices = indices.flatten()
        print "hunting", lookup
        times = sample_times[indices]
        makeup_gains = (curr_amp/amps[indices])
        # send scsynth bus messages
        print "dispatching", bus_num, n_results*3, times, makeup_gains, dists
        msg = OSCMessage("/c_setn", [bus_num, n_results*3])
        #msg.extend() 
        msg.extend(times)
        msg.extend(makeup_gains)
        msg.extend(dists)
        sc_synth_client.sendto(msg, ("127.0.0.1", sc_synth_port))

    # This currently never gets called as pyOSC will ignore everything
    # apart from the scsynth instance, in defiance of my understanding of UDP
    # Need to set up an additional OSC server on a new port
    # or somehow relay through scsynth
    def quit_handler(path=None, tags=None, args=None, source=None):
        print "quit", path, tags, args, source
        sc_synth_facing_server.close()

    def null_handler(path=None, tags=None, args=None, source=None):
        pass

    sc_synth_facing_server.addMsgHandler("/transect", transect_handler )
    sc_synth_facing_server.addMsgHandler("/quit", quit_handler )
    #sc_synth_facing_server.print_tracebacks = True

    sc_synth_client.sendto(OSCMessage("/notify", 1),("127.0.0.1", sc_synth_port))

    print sc_synth_facing_server.server_address, sc_synth_client.address(), sc_synth_facing_server.getOSCAddressSpace()

    sc_synth_facing_server.running = True

    # i = 0
    # ptime = time.time()
    # while True:
    #     i=i+1
    #     ntime = time.time()
    #     deltime = ntime - ptime
    #     if deltime>=1.0:
    #         print i, deltime
    #         ptime = ntime
    #     sc_synth_facing_server.handle_request()
    #     sc_lang_facing_server.handle_request()
    #
    # print "NOOOOOO"
    # sc_synth_facing_server.close()
    # sc_lang_facing_server.close()
    return sc_synth_facing_server
    