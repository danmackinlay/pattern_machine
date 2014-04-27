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

def sc_string(model):
    """code-generate an SC function
    This SC function returns logit probability from a note volume array, nState, for a given pitch i
    """
    super_terms = []
    for refs, coef in model:
        terms = []
        for i in refs:
            subterm = ["(nState[i"]
            if i>=0: subterm.append("+")
            subterm.append(str(i))
            subterm.append("]?0)")
            terms.append("".join(subterm))
        if coef<0:
            terms.append("("+str(coef)+")")
        else:
            terms.append(str(coef))
        super_terms.append("("+"*".join(terms)+")")
    return " + ".join(super_terms)
    
model = tidy_json_model("coef-11.json")