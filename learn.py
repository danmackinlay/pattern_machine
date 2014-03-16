import os
from music21 import converter, instrument

base = os.path.expanduser('~/Music/midi')
inpath = os.path.join(base, 'dillpick.mid')
outpath = os.path.join(base, 'dillpick-out.mid')

score = converter.parse(inpath)

for ev in score.recurse():
    pass
    
#score.write('midi', outpath)

