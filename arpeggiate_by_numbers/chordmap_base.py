import numpy as np

def cross_p_idx(n1, n2):
    "poor-mans's nditer, written offline when i couldn't look it up"
    return np.vstack([
        np.tile(np.arange(n1),n2),
        np.repeat(np.arange(n2), n1),
    ])

def bit_unpack(i):
    # little-endian bit-unpacking
    bits = [int(s) for s in bin(i)[2:]]
    bits.reverse()
    return bits

def binrotate(i, steps=1, lgth=12):
    "convenient to pack note strings to ints for performance"
    binrep = bin(i)[2:]
    pad_digits = lgth-len(binrep)
    binrep = "0"*pad_digits + binrep
    binrep = binrep[steps:]+binrep[0:steps]
    return int(binrep, base=2)

def chord_notes_from_ind(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_ind_from_notes(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_mask_from_ind(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_mask_from_notes(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")

def write_matrix(matrix, ids=None, filename="chordmap_data.scd"):
    if ids is None:
        ids = np.arange(matrix.shape[0])
    with open(filename, 'w') as h:
        h.write("[\n")
        for i in xrange(matrix.shape[0]):
            r = matrix[i,:]
            h.write("\t[ %i, " % ids[i])
            for c in r:
                h.write("%f, " % c)
            h.write("],\n")
        h.write("];\n")