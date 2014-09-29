"""
Rapidly analyse a bunch of files for a particular autocorrelation profile


"""
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree
from ps_correl_analyze import sf_anal
from ps_correl_serve import serve
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

if __name__ == '__main__': 
    args = parser.parse_args()

    print "Analysing", args.infile
    wavdata = sf_anal(
        args.infile,
        chunk_rate=args.rate,
        n_steps=args.n_steps,
        base_freq=args.base_freq,
        min_level=args.min_level)

    print "Indexing..."
    # Startlingly, manhattan distance performs poorly.
    # euclidean is OK, or higher p-norms even.
    # should test the robustness of that against, e.g. pre-filtering
    #tree = BallTree(wavdata['all_corrs'].T, metric='minkowski', p=4) 
    tree = BallTree(wavdata['all_corrs'].T, metric='manhattan') # l1
    #tree = BallTree(wavdata['all_corrs'].T, metric='euclidean') # l2
    #tree = BallTree(wavdata['all_corrs'].T, metric='chebyshev') # l-infinity
    
    server = serve(tree, wavdata, args.ps_correl_port, args.n_results, args.sc_synth_port, args.bus_num)
    
    synth_server_thread = threading.Thread( target = server.serve_forever )
    synth_server_thread.start()

    raw_input("Serving analysis. Press Enter to quit...")
    server.close()
    
