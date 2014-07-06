"""
rapidly analyse a bunch of files for a particular autocorrelation profile

For fractional sample delay, we could do cubic interpolation, or polyphase filtering:
http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html

TODO: kNN search on this data set:
http://scikit-learn.org/stable/modules/neighbors.html#ball-tree
TODO: OSC query server - basic PyOSC should be OK, given low IO load.
https://bitbucket.org/arjan/txosc/wiki/Home

To consider: should we highpass as the base f of the signal to reduce spurious bass "correlation"? (or is that OK? since it will select for similar spectral balances)
In which case, should normalising be relative to filtered, or total, amplitude?

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...

TODO: How do we detect inharmonic noise? Convolved with shuffled, or enveloped pink/white noise? This would have the bonus of reducing need for high pass
TODO: adaptive masking noise floor
TODO: live server bus setting (time index, estimated amplitude, file index)
TODO: live server synth triggering
TODO: live client feedback
TODO: serialise analysis to disk ? (not worth it right now; analysis speed is negligible even unoptimised)
TODO: handle updates per OSC
TODO: confirm this RC function has correct frequency parameterization
TODO: handle multiple files
TODO: decimation is to neareset whole number ratio and therefore does not respect time exactly.
TODO: dimension reduction
TODO: estimate variance of analysis; e.g. higher when amp is low, or around major changes
TODO: search ALSO on variance, to avoid spurious transient onset matches, or to at least allow myself to have such things
TODO: switch to Erik De Castro Lopo's libsamplerate to do the conversions; scipy's decimate could be better; there exist nice wrappers eg https://github.com/cournape/samplerate
"""
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree
from OSC import OSCClient, OSCMessage, OSCServer
from ps_correl_config import *
from ps_correl_analyze import sf_anal

wavdata = sf_anal(SF_PATH)
tree = BallTree(wavdata['all_corrs'].T, metric='euclidean')

client = OSCClient()
client.connect( ("localhost", SC_SERVER_PORT) )

def user_callback(path, tags, args, source):
    print path, tags, args, source
    # looks like 
    #/transect iifffffffffffff [1001, 1, -0.6750487089157104, -0.5806915163993835, -0.49237504601478577, -0.4095775783061981, -0.3318118751049042, -0.2586633563041687, -0.18976180255413055, -0.12478849291801453, -0.06346030533313751, -0.005534188821911812, 0.049216993153095245, 0.10099353641271591, 0.12387804687023163] ('127.0.0.1', 57110)
    node = args[0]
    idx = args[1]
    lookup = args[3:] #ignores the amplitude?
    indices = tree.query(lookup, k=10, return_distance=False)
    print indices
    indices = list(*sample_times[indices])
    # could send server bus messages and client info messages
    client.send(OSCMessage("/c_setn", 1, indices[0]))

# distances, indices = tree.query([1,1,1,1,1,1,1,1,1,1,1,1], k=10)
server = OSCServer(("localhost", 36000), client=client, return_port=57110)
server.addMsgHandler("/transect", user_callback )
client.send( OSCMessage("/notify", 1 ) ) #subscribe to server stuff

#client.send( OSCMessage("/quit") )

