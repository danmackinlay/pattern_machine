from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord

def transition_summary(note_transitions, threshold=0):
    #binomial note summary
    on_counts = dict()
    off_counts = dict()
    all_counts = dict()

    curr_held_notes = tuple()

    for held_notes in note_transitions:
        next_held_notes = tuple(sorted([n for n,t in held_notes.iteritems() if t>threshold]))
        # we only want to look at notes within a neighbourhood of something happening
        # otherwise nothing->nothing dominates the data
        domain = set(curr_held_notes + next_held_notes)
        for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain) + NEIGHBORHOOD_RADIUS+1):
            neighborhood = []
            # find ON notes:
            for i in curr_held_notes:
                rel_pitch = i - local_pitch
                if abs(rel_pitch)<=NEIGHBORHOOD_RADIUS:
                    neighborhood.append(rel_pitch)
            neighborhood = tuple(neighborhood)

            all_counts[neighborhood] = all_counts.get(neighborhood,0)+1
            if local_pitch in next_held_notes:
                on_counts[neighborhood] = on_counts.get(neighborhood,0)+1
            else:
                off_counts[neighborhood] = off_counts.get(neighborhood,0)+1
        curr_held_notes = tuple(next_held_notes)

    return on_counts, off_counts, all_counts

def analyze_times(note_stream):
    # do some analysis of note inter-arrival times to check our tempo assumptions
    first_event = note_stream.flat.notes.offsetMap[0]['offset']
    last_event = note_stream.flat.notes.offsetMap[-1]['offset']
    midi_length = float(last_event-first_event)
    curr_time_stamp = first_event
    pitch_rates = [0.0] * 128
    thinned_intervals = []
    for next_elem in note_stream.flat.notes.offsetMap:
        #event density stats
        event = next_elem['element']
        #only handle Notes and Chords
        if not isinstance(event, NotRest):
            continue
        next_time_stamp = next_elem['offset']
        if next_time_stamp > curr_time_stamp + ONSET_TOLERANCE:
            thinned_intervals.append(next_time_stamp-curr_time_stamp)
            curr_time_stamp = next_time_stamp
        #individual pitch density stats:
        pitches = []
        if hasattr(event, 'pitch'):
            pitches = [event.pitch.midi]
        if hasattr(event, 'pitches'):
            pitches = [p.midi for p in event.pitches]
        for p in pitches:
            pitch_rates[p] += 1.0/midi_length
    mean_event_time = sum(thinned_intervals)/len(thinned_intervals)
    return mean_event_time, pitch_rates

def parse():
    global event_counter, obs_counter
    event_counter = 0
    event_list = []
    obs_counter = 0
    obs_list = []
    p_list = []
    recence_list = []
    mean_pitch_rate = [0.0] * 128
    curr_delta = 0.0
    with open(CSV_OUT_PATH, 'w') as csv_handle, tables.open_file(BASIC_TABLE_OUT_PATH, 'w') as table_handle:
        csv_writer = csv.writer(csv_handle, quoting=csv.QUOTE_NONNUMERIC)
        csv_writer.writerow(csv_fieldnames)

        def write_csv_row(counts):
            on_counts, off_counts, all_counts = counts
            for i, neighborhood in enumerate(sorted(all_counts.keys())):
                csv_writer.writerow(
                  [file_key] +
                  [(1 if i in neighborhood else 0) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] +
                  [total_detunedness(neighborhood), span_in_5ths(neighborhood),
                    span_in_5ths_up(neighborhood), span_in_5ths_down(neighborhood)] +
                  [on_counts.get(neighborhood, 0), off_counts.get(neighborhood, 0)]
                )
        #ignore warnings for that bit; I know my column names are annoying.
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            obs_table = table_handle.create_table('/', 'note_meta',
                meta_table_description,
                filters=tables.Filters(complevel=1))
            barcode_table = table_handle.create_table('/', 'note_barcode',
                barcode_table_description,
                filters=tables.Filters(complevel=1))
        col_table = table_handle.create_table('/', 'col_names',
            {'i': tables.IntCol(1), 'rname': tables.StringCol(5)})
        for i in sorted(r_name_for_i.keys()):
            col_table.row['i'] = i
            col_table.row['rname'] = r_name_for_i[i]
            col_table.row.append()

        obs_table.attrs.maxAge = MAX_AGE
        obs_table.attrs.neighborhoodRadius = NEIGHBORHOOD_RADIUS

        def fan_out_event(note_times, next_time_stamp, next_note, file_key):
            global event_counter, mean_pitch_rate, obs_counter
            """turn one event into a set of observations - one of which is a success.
            Send this to a file."""
            domain = set(note_times.keys() + [next_note])

            #now we record what transitions have just happened, conditional on the local env
            for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain) + NEIGHBORHOOD_RADIUS+1):
                # count how many predictors we actually have
                n_held_notes = 0

                # create a new row for each local note environment
                result = 0
                if next_note == local_pitch:
                    result = 1

                for this_note, this_time_stamp in note_times.iteritems():
                    rel_pitch = this_note - local_pitch
                    if abs(rel_pitch) <= NEIGHBORHOOD_RADIUS:
                        n_held_notes += 1
                        this_recence = MAX_AGE - next_time_stamp + this_time_stamp
                        p_list.append(rel_pitch+NEIGHBORHOOD_RADIUS) # 0-based array indexing
                        recence_list.append(this_recence)
                        obs_list.append(obs_counter)

                if n_held_notes>0:
                    barcode = int(math.floor((next_time_stamp % 4.0 + 0.99/8) * 4.0))
                    obs_table.row['file'] = file_key
                    obs_table.row['time'] = next_time_stamp
                    obs_table.row['obsID'] = obs_counter
                    obs_table.row['eventID'] = event_counter
                    obs_table.row['thisNote'] = local_pitch
                    obs_table.row['result'] = result
                    obs_table.row.append()
                    barcode_table.row['obsID'] = obs_counter
                    barcode_table.row['b4'] = (barcode & 8) /8
                    barcode_table.row['b3'] = (barcode & 4) /4
                    barcode_table.row['b2'] = (barcode & 2) /2
                    barcode_table.row['b1'] = (barcode & 1)
                    barcode_table.row.append()
                    obs_counter += 1

        def parse_midi_file(base_dir, midi_file):
            """workhorse function
            does too much, for reasons of efficiency
            plus the inconvenient os.path.walk API"""
            global mean_pitch_rate, event_counter
            midi_in_file = os.path.join(base_dir, midi_file)
            file_key = midi_in_file[len(MIDI_BASE_DIR):]
            print "parsing", file_key
            note_stream = converter.parse(midi_in_file)
            note_transitions = []
            note_times = dict()
            mean_event_time, mean_pitch_rate = analyze_times(note_stream)

            for next_elem in note_stream.flat.notes.offsetMap:
                event = next_elem['element']
                #only handle Notes and Chords
                if not isinstance(event, NotRest):
                    continue
                next_time_stamp = next_elem['offset']

                # first we increment time, which involves deleting notes too old to love
                for this_note, this_time_stamp in note_times.items():
                    if next_time_stamp-this_time_stamp>MAX_AGE:
                        del(note_times[this_note])

                if hasattr(event, 'pitch'):
                    pitches = [event.pitch.midi]
                if hasattr(event, 'pitches'):
                    pitches = sorted([p.midi for p in event.pitches])
                    ## OR: randomize order:
                    #pitches = random.sample(pitches, len(pitches))

                for next_note in pitches:
                    #table writer can have a bash
                    fan_out_event(note_times, next_time_stamp, next_note, file_key)

                    #for the next time step, we need to include the new note:
                    note_times[next_note] = next_time_stamp

                    # For the CSV file we append the next note to the transition info
                    # NB this means that CSV ignores the note's own prior state, a difference with the full data.
                    next_transition = dict([
                        (this_note, MAX_AGE - next_time_stamp + this_time_stamp)
                        for this_note, this_time_stamp in note_times.iteritems()
                    ])

                    event_counter += 1

            # CSV writer can haz pound of flesh
            write_csv_row(transition_summary(note_transitions, ROUGH_NEWNESS_THRESHOLD))

        def parse_if_midi(_, file_dir, file_list):
            for f in file_list:
                if f.lower().endswith('mid'):
                    parse_midi_file(file_dir, f)

        os.path.walk(MIDI_BASE_DIR, parse_if_midi, None)

        filt = tables.Filters(complevel=5)
    
        table_handle.create_carray('/','v_obsid',
            atom=tables.Int32Atom(), shape=(len(obs_list),),
            title="obsID",
            filters=filt)[:] = obs_list
        table_handle.create_carray('/','v_p',
            atom=tables.Int32Atom(), shape=(len(p_list),),
            title="pitch index",
            filters=filt)[:] = p_list
        table_handle.create_carray('/','v_recence',
            atom=tables.Float32Atom(), shape=(len(recence_list),),
            title="recence",
            filters=filt)[:] = recence_list
        table_handle.create_carray('/','v_base_rate',
            atom=tables.Float32Atom(), shape=(128,),
            title="base rate",
            filters=filt)[:] = mean_pitch_rate
        # Now, because this is easier in Python than in R, we precalc relative pitch neighbourhoods
        # BEWARE 1-BASED INDEXING IN R
        base_rate_store = table_handle.create_carray('/','v_rel_base_rate',
            atom=tables.Float32Atom(), shape=(128,2*NEIGHBORHOOD_RADIUS+1),
            title="rel base rate",
            filters=filt)
        _mean_pitch_rate_plus = [0]*NEIGHBORHOOD_RADIUS + mean_pitch_rate + [0]*NEIGHBORHOOD_RADIUS
        for i in xrange(128):
            base_rate_store[i,:] = _mean_pitch_rate_plus[i:i+(2*NEIGHBORHOOD_RADIUS+1)]
        #it would also be a very convenient time to generate exotic features here based on this sparse matrix form

