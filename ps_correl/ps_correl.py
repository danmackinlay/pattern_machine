"""
Rapidly analyse a bunch of files for a particular autocorrelation profile

To consider: should we highpass as the base f of the signal to reduce spurious bass "correlation"? (or is that OK? since it will select for similar spectral balances)
In which case, should normalising be relative to filtered, or total, amplitude?

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...

TODO: start server ASAP to catch init messages
TODO: search based on amplitude (what is an appropriate normalisation for it?)
TODO: report amplitude of matched file section
TODO: search ALSO on variance, to avoid spurious transient onset matches, or to at least allow myself to have such things
TODO: launch or wrap python server from SC
TODO: handle multiple files
TODO: handle multiple clients through e.g. nodeid
TODO: adaptive masking noise floor
TODO: settable ports/addresses
TODO: indicate how good matches are (distance)
TODO: check alternate metrics
TODO: plot spectrograms and sanity check against analysis data
TODO: handle errors; at least print them somewhere; report ready and success
TODO: estimate variance of analysis; e.g. higher when amp is low, or around major changes
TODO: work out how to suppress "no handler" warnings
TODO: serialise analysis to disk ? (not worth it right now; analysis speed is negligible even unoptimised. might be worth it to avoid hiccups in single-threaded mode)
TODO: How do we detect inharmonic noise? Convolved with shuffled, or enveloped pink/white noise? 
TODO: dimension reduction
TODO: live scsynth synth triggering
TODO: decimation is to neareset whole number ratio and therefore does not respect time exactly.
TODO: switch to Erik De Castro Lopo's libsamplerate to do the conversions; scipy's decimate could be better; there exist nice wrappers eg https://github.com/cournape/samplerate
TODO: treat smoothing or other free parameters (or neighbourhood size) as a model-selection problem? AIC or cross-validation?

For fractional sample delay, we could do cubic interpolation, or polyphase filtering:
http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html
"""
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree
from OSC import OSCClient, OSCMessage, OSCServer
from ps_correl_config import PS_CORREL_PORT, SC_LANG_PORT, SC_SYNTH_PORT, SF_PATH, THAT_OTHER_PS_CORREL_PORT
from ps_correl_analyze import sf_anal
import types
import time

print "Analysing", SF_PATH
wavdata = sf_anal(SF_PATH)
all_corrs = wavdata['all_corrs']
sample_times = wavdata['sample_times']
amps = wavdata['amp']

print "Indexing..."
tree = BallTree(wavdata['all_corrs'].T, metric='euclidean')
scsynth_bus_start=None
scsynth_bus_n=3

def transect_handler(path=None, tags=None, args=None, source=None):
    node = args[0]
    idx = args[1]
    lookup = args[3:] #ignores the amplitude
    dists, indices = tree.query(lookup, k=scsynth_bus_n, return_distance=True)
    print "hunting", lookup, dists, indices
    times = list(*sample_times[indices])
    # send scsynth bus messages
    if scsynth_bus_start is not None:
        print "dispatching", scsynth_bus_start, scsynth_bus_n, times
        msg = OSCMessage("/c_setn")
        msg.extend([scsynth_bus_start, scsynth_bus_n])
        msg.extend(times)
        sc_synth_client.sendto(msg, ("127.0.0.1", SC_SYNTH_PORT))

def set_bus_handler(path=None, tags=None, args=None, source=None):
    print "set_bus", path, tags, args, source
    scsynth_bus_start = args[0]

def set_n_handler(path=None, tags=None, args=None, source=None):
    print "set_n", path, tags, args, source
    scsynth_bus_n = args[0]

def set_file_handler(path=None, tags=None, args=None, source=None):
    print "set_file", path, tags, args, source
    #not yet implemented

def quit_handler(path=None, tags=None, args=None, source=None):
    print "quit", path, tags, args, source
    #not yet implemented

def null_handler(path=None, tags=None, args=None, source=None):
    pass

OSCServer.timeout = 0.01
# sc_synth_client = OSCClient()
# sc_synth_client.connect( ("127.0.0.1", PS_CORREL_PORT))
# sc_synth_facing_server = OSCServer(("0.0.0.0", PS_CORREL_PORT), client=sc_synth_client, return_port=PS_CORREL_PORT) #SC_SYNTH_PORT
sc_synth_facing_server = OSCServer(("127.0.0.1", PS_CORREL_PORT))
sc_synth_client = sc_synth_facing_server.client

# # fix dicey-looking error messages
# sc_synth_facing_server.addMsgHandler("default", sc_synth_facing_server.msgPrinter_handler)
sc_synth_facing_server.addDefaultHandlers()
# sc_synth_facing_server.addMsgHandler("/transect", transect_handler )
# sc_synth_facing_server.addMsgHandler("/set_bus", set_bus_handler )
# sc_synth_facing_server.addMsgHandler("/set_n", set_n_handler )
# sc_synth_facing_server.addMsgHandler("/set_file", set_file_handler )
# sc_synth_facing_server.addMsgHandler("/quit", quit_handler )
#sc_synth_facing_server.print_tracebacks = True

sc_synth_client.sendto(OSCMessage("/notify"),("127.0.0.1", SC_SYNTH_PORT))


sc_lang_facing_server = OSCServer(("127.0.0.1", THAT_OTHER_PS_CORREL_PORT ))
sc_lang_client = sc_lang_facing_server.client
# # fix dicey-looking error messages
# sc_lang_facing_server.addMsgHandler("default", sc_lang_facing_server.msgPrinter_handler)
sc_lang_facing_server.addDefaultHandlers()
# sc_lang_facing_server.addMsgHandler("/transect", transect_handler )
# sc_lang_facing_server.addMsgHandler("/set_bus", set_bus_handler )
# sc_lang_facing_server.addMsgHandler("/set_n", set_n_handler )
# sc_lang_facing_server.addMsgHandler("/set_file", set_file_handler )
# sc_lang_facing_server.addMsgHandler("/quit", quit_handler )

sc_lang_client.sendto(OSCMessage("/notify"),("127.0.0.1", SC_LANG_PORT))


print sc_synth_facing_server.server_address, sc_synth_client.address(), sc_synth_facing_server.getOSCAddressSpace()
print sc_lang_facing_server.server_address, sc_lang_client.address(), sc_lang_facing_server.getOSCAddressSpace()

#hack to eliminate the possibility that rogue exceptions are poisoning this fucking thing
def handle_error(self,request,client_address):
    print "ERROR",self,request,client_address
    pass

sc_synth_facing_server.handle_error = types.MethodType(handle_error, sc_synth_facing_server)
sc_synth_facing_server.running = True
sc_lang_facing_server.handle_error = types.MethodType(handle_error, sc_lang_facing_server)
sc_lang_facing_server.running = True

i = 0
ptime = time.time()
while True:
    i=i+1
    ntime = time.time()
    deltime = ntime - ptime
    if deltime>=1.0:
        print i, deltime
        ptime = ntime
    sc_synth_facing_server.handle_request()
    sc_lang_facing_server.handle_request()

print "NOOOOOO"
sc_synth_facing_server.close()
sc_lang_facing_server.close()


