require(rhdf5)
h5.corrs = "non_sc/corr.h5"
freqs = h5read(h5.corrs, '/v_freqs')
correls = h5read(h5.corrs, '/v_corrs')
