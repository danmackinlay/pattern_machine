""" Clean up JSON output from R
because R is a fairly filthy language
with no scalars and horrible string handling.

Parses model matrix colnames into references and unpacks the single entry coefficient arrays.

Outputs as JSON - but why not code generate for SC? life is short.
"""

from json import dump, load

def tidy_json_model(file_path):
    r_model = load(open(file_path))
    predictor_pairs = [[[], r_model.pop(u'(Intercept)')[0]]]

    for this_predictor_string, [this_coef] in r_model.iteritems():
        print "*", this_predictor_string, this_coef
        this_predictor_chunks = this_predictor_string.split(":")
        this_predictor_refs = []
        for chunk in this_predictor_chunks:
            if not chunk.startswith("X"):
                continue
            chunk = chunk[1:]
            if chunk.startswith("."):
                ref = -int(chunk[1:])
            else:
                ref = int(chunk)
            this_predictor_refs.append(ref)
        predictor_pairs.append([this_predictor_refs,this_coef])
    return(predictor_pairs)

def write_json_model(model, path):
    with open(path, "w") as f:
        dump(model, f)

model = tidy_json_model("coef-11.json")