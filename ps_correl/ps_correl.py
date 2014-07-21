"""
Rapidly analyse a bunch of files for a particular autocorrelation profile

To consider: should we highpass as the base f of the signal to reduce spurious bass "correlation"? (or is that OK? since it will select for similar spectral balances)
In which case, should normalising be relative to filtered, or total, amplitude?

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...

TODO: cache analysis to disk ?
TODO: more conservative pregain management to avoid onset clipping
TODO: include grain size in search and search based on that (tricky but safer)
TODO: restrict search based on amplitude range
TODO: restrict search based on certainty range (this would require us to actually have a model), e.g. higher when amp is low, or around major changes, or estimated from sample variance
TODO: search ALSO on variance, to avoid spurious transient onset matches, or to at least allow myself to have such things
TODO: search ALSO on gradient
TODO: handle multiple files
TODO: handle multiple clients through e.g. nodeid
TODO: adaptive masking noise floor
TODO: plot spectrograms and sanity check against analysis data
TODO: work out how to suppress "no handler" warnings
TODO: How do we detect inharmonic noise? Convolved with shuffled, or enveloped pink/white noise? 
TODO: dimension reduction
TODO: switch to Erik De Castro Lopo's libsamplerate to do the conversions; scipy's decimate could be better; there exist nice wrappers eg https://github.com/cournape/samplerate
TODO: treat smoothing or other free parameters (or neighbourhood size) as a model-selection problem? AIC or cross-validation?
TODO: decimation is to neareset whole number ratio and therefore does not respect time exactly.
For fractional sample delay, we could do cubic interpolation, or polyphase filtering:
http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html
http://cnx.org/content/m15490/latest/
"""
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree
from OSC import OSCClient, OSCMessage, OSCServer
from ps_correl_analyze import sf_anal
import types
import time
import threading
import argparse
import os.path

parser = argparse.ArgumentParser(description='Sound analysis server')
parser.add_argument('infile',
    # nargs='+',
    nargs='?',
    default=os.path.expanduser('~/src/sc/f_lustre/sounds/draingigm.aif'),
    # default=os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif'),
    help='file to analyse')
parser.add_argument('--bus-num', dest='bus_num', type=int,
    default=83,
    help='which SC bus should I set?')
parser.add_argument('--n', dest='n_results', type=int,
    default=6,
    help='how many results to return? (NB need 3 times this many buses)')
parser.add_argument('--rate', dest='rate', type=float,
    default=80.0,
    help='how many points per second will I classify?')
parser.add_argument('--port', dest='ps_correl_port', type=int,
    default=36000,
    help='port of scsynth to talk to (but monopolised by scsynth)')
parser.add_argument('--sc-synth-port', dest='sc_synth_port', type=int,
    default=57110,
    help='port of scsynth to talk to')
parser.add_argument('--sc-lang-port', dest='sc_lang_port', type=int,
    default=57120,
    help='port of scsynth to talk to (not currently used)')
parser.add_argument('--base-freq', dest='base_freq', type=float,
    default=440.0,
    help='base analysis frequency')
parser.add_argument('--steps', dest='n_steps', type=int,
    default=12,
    help='number of analysis frequencies')
parser.add_argument('--min-level', dest='min_level', type=float,
    default=0.001,
    help='min rms amplitude')

args = parser.parse_args()

print "Analysing", args.infile
wavdata = sf_anal(
    args.infile,
    rate=args.rate,
    n_steps=args.n_steps,
    base_freq=args.base_freq,
    min_level=args.min_level)
    
all_corrs = wavdata['all_corrs']
sample_times = wavdata['sample_times']
amps = wavdata['amp']

print "Indexing..."
# Startlingly, manhattan distance performs poorly.
# euclidean is OK, or higher p-norms even.
# should test the robustness of that against, e.g. pre-filtering
#tree = BallTree(wavdata['all_corrs'].T, metric='minkowski', p=4) 
tree = BallTree(wavdata['all_corrs'].T, metric='euclidean') 

OSCServer.timeout = 0.01

sc_synth_facing_server = OSCServer(("127.0.0.1", args.ps_correl_port))
sc_synth_client = sc_synth_facing_server.client
sc_synth_facing_server.addDefaultHandlers()

def transect_handler(osc_path=None, osc_tags=None, osc_args=None, osc_source=None):
    node = osc_args[0]
    idx = osc_args[1]
    curr_amp = float(osc_args[2])
    lookup = osc_args[3:] #ignores the amplitude
    dists, indices = tree.query(lookup, k=args.n_results, return_distance=True)
    dists = dists.flatten()
    indices = indices.flatten()
    print "hunting", lookup
    times = sample_times[indices]
    makeup_gains = (curr_amp/amps[indices])
    # send scsynth bus messages
    print "dispatching", args.bus_num, args.n_results*3, times, makeup_gains, dists
    msg = OSCMessage("/c_setn", [args.bus_num, args.n_results*3])
    #msg.extend() 
    msg.extend(times)
    msg.extend(makeup_gains)
    msg.extend(dists)
    sc_synth_client.sendto(msg, ("127.0.0.1", args.sc_synth_port))

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

sc_synth_client.sendto(OSCMessage("/notify", 1),("127.0.0.1", args.sc_synth_port))

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

synth_server_thread = threading.Thread( target = sc_synth_facing_server.serve_forever )
synth_server_thread.start()

raw_input("Serving analysis. Press Enter to quit...")
sc_synth_facing_server.close()
