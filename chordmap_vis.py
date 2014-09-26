import numpy as np
from chordmap_base import *
from matplotlib import pyplot as plt
from colorsys import hsv_to_rgb
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm

# Colours are tricky; let's start by making a basis that colourises according to position on the cycle of 5ths.
rgbmap = np.array([
    hsv_to_rgb((i*7%12)/12.0, 1, 1.0/12) for i in xrange(12)
])

id_rgb = np.array([
    rgbmap[chord_notes_from_ind(i),:].sum(0) for i in xrange(4096)
])

def plot_2d(trans):
    n_dims = trans.shape[1]
    for d in xrange(n_dims):
        fig = plt.figure(d)
        ax = plt.axes([0., 0., 1., 1.])
        plt.scatter(
            trans[:, d],
            trans[:, (d+1) % n_dims],
        s=20, c=id_rgb)
    plt.show()

def plot_3d(trans, cols=None):
    if cols is None:
        cols = id_rgb
    n_dims = trans.shape[1]
    fig = plt.figure()
    
    for x in xrange(n_dims-2):
        ax = fig.add_subplot(n_dims-2, 1, 1+x, projection='3d')
        y = (x+1) % n_dims
        z = (x+2) % n_dims
        ax.scatter(
            xs=trans[:, x],
            ys=trans[:, y],
            zs=trans[:, z],
            c=cols,
            )
        ax.set_xlabel('{0} ax'.format(x))
        ax.set_ylabel('{0} ax'.format(y))
        ax.set_zlabel('{0} ax'.format(z))
         
    plt.show()
