import numpy as np
from chordmap_base import *
from matplotlib import pyplot as plt
from colorsys import hsv_to_rgb
from mpl_toolkits.mplot3d import Axes3D

# Colours are tricky; let's start by making a basis that colourises according to position on the cycle of 5ths.
rgbmap = np.array([
    hsv_to_rgb((i*7%12)/12.0, 1, 1.0/12) for i in xrange(12)
])

id_rgb = np.array([
    rgbmap[chord_notes_from_ind(i),:].sum(0) for i in xrange(4096)
])

def plot_2d(trans):
    n_dims = trans.shape[1]
    for d in n_dims:
        fig = plt.figure(d)
        ax = plt.axes([0., 0., 1., 1.])
        plt.scatter(
            trans[:, d],
            trans[:, (d+1) % n_dims],
        s=20, c=id_rgb)
    plt.show()

def plot_3d(trans):
    n_dims = trans.shape[1]
    fig = plt.figure()
    
    for x in n_dims-2:
        ax = plt.add_subplot(110+x, projection='3d')
        y = (d+1) % n_dims
        z = (d+2) % n_dims
        plt.scatter(
            trans[:, x],
            trans[:, y],
            trans[:, z],
        s=20, c=id_rgb)
        ax.set_xlabel('{0} ax'.format(x))
        ax.set_ylabel('{0} ax'.format(y))
        ax.set_zlabel('{0} ax'.format(z))
         
    plt.show()
