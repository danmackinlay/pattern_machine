"""Export the model matrix into a supercollider script that outputs notes according to the model.
"""

def sc_string(model, i_name="i", nstate_name="nState"):
    """code-generate an SC function
    This SC function returns logit probability from a note volume array, nState, for a given pitch i
    Note that it hasn't yet been updated for the new matrix-based R export, so it doesn't work.
    """
    super_terms = []
    for refs, coef in model:
        terms = []
        for i in refs:
            subterm = ["("+nstate_name+"["+i_name]
            if i>=0: subterm.append("+")
            subterm.append(str(i))
            subterm.append("]?0)")
            terms.append("".join(subterm))
        if coef<0:
            terms.append("("+str(coef)+")")
        else:
            terms.append(str(coef))
        super_terms.append("("+"*".join(terms)+")")
    return " +\n\t".join(super_terms) + ";"

