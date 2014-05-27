from config import *
import numpy as np
import scipy as sp
from scipy.sparse import coo_matrix, dok_matrix
from scipy.stats import power_divergence
from random import randint, sample
from sklearn.linear_model import Lasso, LogisticRegression

def lik_test(N,Y,p0):
    "likelihood ratio/ G-test. This will suffer from the multiple comparison issue, "
    "but is only an aid to guesstimation anyway."
    Y0 = int(round(p0*N))
    return power_divergence(f_obs=[N-Y,Y], f_exp=[N-Y0,Y0], lambda_="log-likelihood")[1]

def log_lik_ratio(N,Y,p0):
    Y0 = int(round(p0*N))
    return power_divergence(f_obs=[N-Y,Y], f_exp=[N-Y0,Y0], lambda_="log-likelihood")[0]

def square_feature(A, center=2.0, radius=0.125):
    return ((A-center)<radius).astype(np.int32)

def triangle_feature(A, center=2.0, radius=0.125):
    return (1.0-np.abs(A-center)/radius)*((A-center)<radius)

