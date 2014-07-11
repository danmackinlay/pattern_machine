import tables

def save(corr_path):

    filt = None
    # filt = tables.Filters(complevel=5)

    with tables.open_file(corr_path, 'w') as table_out_handle:
        table_out_handle.create_carray('/','v_freqs',
            atom=tables.Float32Atom(),
            shape=freqs.shape,
            title="freqs",
            filters=filt)[:] = freqs
        table_out_handle.create_carray('/','v_corrs',
            atom=tables.Float32Atom(), shape=all_corr.shape,
            title="corrs",
            filters=filt)[:] = all_corr
        table_out_handle.create_carray('/','v_mag',
            atom=tables.Float32Atom(), shape=v_mag.shape,
            title="mag",
            filters=filt)[:] = little_wav2
        table_out_handle.create_carray('/','v_times',
            atom=tables.Float32Atom(), shape=v_time.shape,
            title="v_times",
            filters=filt)[:] = sample_times