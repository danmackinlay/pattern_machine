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

span5 = []
span7 = []
_this_span5 = []
_this_span7 = []

for i in xrange(12):
    _this_span5.append((5*i)%12)
    _this_span7.append((7*i)%12)
    span5.append(set(_this_span5))
    span7.append(set(_this_span7))

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
detune_12_tone = tuple(
    [
        abs(log(
            (float(num)/denom)/
            (2.0**(float(i)/12))))
        for i, (num,denom) in enumerate(ratios_12_tone)
    ]
)