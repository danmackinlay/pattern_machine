from fractions import Fraction
from math import log

"""
  Generator for getting factors for a number
"""
def factor(n):
    i = 2
    limit = n**0.5
    while i <= limit:
        if n % i == 0:
            yield i
            n = n / i
            limit = n**0.5
        else:
            i += 1
    if n > 1:
        yield n

def fold_to_octave(note_set):
    return set(i % 12 for i in note_set)

def print_approx_scale():
    for i in xrange(1,12):
        print i, Fraction(2.0**(i/12.0)).limit_denominator(20)

ratios_12_tone = (
    (1,1), #0
    (15,14), #1
    (9,8), #2
    (6,5), #3
    (5,4), #4
    (4,3), #5
    (7,5), #6
    (3,2), #7
    (8,5), #8
    (5,3), #9
    (16,9), #10
    (28,15), #11
)
#How much are we out from just intonation on each pitch, as a fraction of a whole tine?
detune_12_tone = tuple(
    [
        abs(log(
            (float(num)/denom)/
            (2.0**(float(i)/12))
        ))/ log(2.0**(1.0/12.0))
        for i, (num,denom) in enumerate(ratios_12_tone)
    ]
)

def total_detunedness(neighborhood):
    """
    ad hoc measure of how much this scale differs from just intonation
    """
    return sum([detune_12_tone[i] for i in fold_to_octave(neighborhood)])

# decompose into powers of (2,3,5,7)
prime_ratios_12_tone = (
    ((0,0,0,0),(0,0,0,0)), #0
    ((0,1,1,0),(1,0,0,1)), #1
    ((0,2,0,0),(3,0,0,0)), #2
    ((1,1,0,0),(0,0,1,0)), #3
    ((0,0,1,0),(2,0,0,0)), #4
    ((2,0,0,0),(0,1,0,0)), #5
    ((0,0,0,1),(0,0,1,0)), #6
    ((0,1,0,0),(1,0,0,0)), #7
    ((3,0,0,0),(0,0,1,0)), #8
    ((0,0,1,0),(0,1,0,0)), #9
    ((4,0,0,0),(0,2,0,0)), #10
    ((2,0,0,1),(0,1,1,0)), #11
)

def sanity_check_prime_ratios():
    for (n2,n3,n5,n7), (d2,d3,d5,d7) in prime_ratios_12_tone:
        num = 2**n2*3**n3*5**n5*7**n7
        denom = 2**d2*3**d3*5**d5*7**d7
        print num, denom, float(num)/denom

_span5 = ()
_span7 = ()
_this_span5 = []
_this_span7 = []

for i in xrange(12):
    _this_span5.append((5*i)%12)
    _this_span7.append((7*i)%12)
    _span5 = _span5 + (set(_this_span5),)
    _span7 = _span7 + (set(_this_span7),)

del(_this_span5)
del(_this_span7)

def span_in_5ths(neighborhood):
    """
    how many 5ths do I need to jump to encompass this entire set of pitches?
    NB implicitly starts from the tonic.
    """
    folded_hood = fold_to_octave(neighborhood)
    for i in xrange(12):
        if _span5[i].issuperset(folded_hood):
            return i
        if _span7[i].issuperset(folded_hood):
            return i

def span_in_5ths_up(neighborhood):
    """
    how many 5ths do I need to jump up to encompass this entire set of pitches?
    NB implicitly starts from the tonic.
    """
    folded_hood = fold_to_octave(neighborhood)
    for i in xrange(12):
        if _span5[i].issuperset(folded_hood):
            return i

def span_in_5ths_down(neighborhood):
    """
    how many 5ths do I need to jump down to encompass this entire set of pitches?
    NB implicitly starts from the tonic.
    """
    folded_hood = fold_to_octave(neighborhood)
    for i in xrange(12):
        if _span7[i].issuperset(folded_hood):
            return i

def ad(v1, v2):
    return tuple([s1+s2 for s1,s2 in zip(v1,v2)])

def pitches_to_ratios(pitchset):
    n=(0,0,0,0)
    d=(0,0,0,0)
    for p in fold_to_octave(pitchset):
        n=ad(n,prime_ratios_12_tone[p][0])
        d=ad(d,prime_ratios_12_tone[p][1])
    return n,d
    