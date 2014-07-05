import numpy as np
from math import exp, log

def RC(Wn, btype='low', dtype=np.float64):
     """old-fashioned minimal filter design, if you don't want this modern bessel nonsense
     C'n'C SC out(i) = ((1 - abs(coef)) * in(i)) + (coef * out(i-1)).
     """
     epsilon = np.finfo(dtype).eps
     f = Wn/2.0 # shouldn't this be *2.0?
     x = exp(-2*np.pi*f)
     if btype == 'low':
         b, a = np.zeros(2), np.zeros(2)
         b[0] = 1.0 - x - epsilon #filter instability
         b[1] = 0.0
         a[0] = 1.0
         a[1] = -x
     elif btype == 'high':
         b, a = np.zeros(2), np.zeros(2)
         b[0] = (1.0+x)/2.0
         b[1] = -(1.0+x)/2.0
         a[0] = 1.0
         a[1] = -x
     else:
         raise ValueError, "btype must be 'low' or 'high'"
     return b,a

def notch(Wn, bandwidth):
    """
    Notch filter to kill line-noise.
    """
    f = Wn/2.0
    R = 1.0 - 3.0*(bandwidth/2.0)
    K = ((1.0 - 2.0*R*np.cos(2*np.pi*f) + R**2)/(2.0 - 
    2.0*np.cos(2*np.pi*f)))
    b,a = np.zeros(3),np.zeros(3)
    a[0] = 1.0
    a[1] = - 2.0*R*np.cos(2*np.pi*f)
    a[2] = R**2
    b[0] = K
    b[1] = -2*K*np.cos(2*np.pi*f)
    b[2] = K
    return b,a

def narrowband(Wn, bandwidth):
    """
    Narrow-band filter to isolate a single frequency.
    """
    f = Wn/2.0
    R = 1.0 - 3.0*(bandwidth/2.0)
    K = ((1.0 - 2.0*R*np.cos(2*np.pi*f) + R**2)/(2.0 - 
    2.0*np.cos(2*np.pi*f)))
    b,a = np.zeros(3),np.zeros(3)
    a[0] = 1.0
    a[1] = - 2.0*R*np.cos(2*np.pi*f)
    a[2] = R**2
    b[0] = 1.0 - K
    b[1] = 2.0*(K-R)*np.cos(2*np.pi*f)
    b[2] = R**2 - K
    return b,a