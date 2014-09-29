"""
Rapidly analyse a bunch of files for a particular autocorrelation profile
"""
from chordmap_serve import serve
import threading
import argparse
import os.path

parser = argparse.ArgumentParser(description='Sound analysis server')
parser.add_argument('--n', dest='n_results', type=int,
    default=6,
    help='how many results to return? (NB need 3 times this many buses)')
parser.add_argument('--port', dest='chordmap_port', type=int,
    default=36000,
    help='port of scsynth to talk to (but monopolised by scsynth)')
parser.add_argument('--sc-lang-port', dest='sc_lang_port', type=int,
    default=57120,
    help='port of scsynth to talk to (not currently used)')

if __name__ == '__main__': 
    args = parser.parse_args()
    
    print "Analysing", args.infile
    ####### DO STUFF HERE
    
    server = serve(tree, args.chordmap_port, args.n_results, args.sc_synth_port, args.bus_num)
    
    synth_server_thread = threading.Thread( target = server.serve_forever )
    synth_server_thread.start()

    raw_input("Serving chords. Press Enter to quit...")
    server.close()
    
