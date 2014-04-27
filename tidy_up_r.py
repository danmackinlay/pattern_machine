""" Clean up JSON output from R
because R is a fairly filthy language
with no scalars and horrible string handling.

Parses model matrix colnames into references and unpacks the single entry coefficient arrays.
"""

from json import dump, load

r_model = load(open("coef-11.json"))
predictor_refs = [[]]
predictor_coefs = [r_model.pop(u'(Intercept)')[0]]

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
    predictor_refs.append(this_predictor_refs)
    predictor_coefs.append(this_coef)
    print this_predictor_refs, this_coef

