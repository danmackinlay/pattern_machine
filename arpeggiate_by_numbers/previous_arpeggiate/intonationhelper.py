def round_me(f, tolerance=0.06):
    candidates = {}
    for denom in range(1,11):
        num = round(f*denom)
        if hcf(num, denom)>1: continue
        approx = num/denom
        error = (approx-f)/f
        # print "%f ~ %d/%d, +/- %f" % (f, num, denom, error)
        candidates[abs(error)]=(error, (int(num), denom))
    key_list =candidates.keys()
    key_list.sort()
    # for error in key_list:
    #         print error, candidates[error]
    winner = key_list[0]
    return candidates[winner]
    
def hcf(a,b):
    lowest=int(min(a,b))
    for i in range(lowest, 0, -1):
        if (a % i == 0) and (b % i == 0) :
            return i
            
for i in range(0, 13):
    freq=pow(2., float(i)/12)
    # print "step %d, freq %f" % (i, freq)
    err, (num, denom,) = round_me(freq)
    print i, num, denom, err
