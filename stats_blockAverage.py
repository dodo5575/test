#!/usr/bin/env python
# This script calculates basic statistical property of a list.
# Usage: python stats.py input
# Chen-Yu Li cli56@illinois.edu
# 2014/5/20


import math, numpy, sys
import acor
    
def ACtime(g):

    MEAN=numpy.mean(g)
    STD=numpy.std(g)
        
    for t in range(len(g)):
        C = 0.0
        for i in range((len(g)-t)):
            C = C + (g[i]-MEAN)*(g[t+i]-MEAN)

        C = C/((STD*STD)*(len(g)-t))
        if C <= 0:
            tCut=t  
            break

    
    total = 0.0
    for t in range((tCut-1)):
        C = 0.0
        for i in range((len(g)-t)):
            C = C + (g[i]-MEAN)*(g[t+i]-MEAN)

        C = C / ((STD*STD)*(len(g)-t))
        total = total + C
    kappa = 1 + 2 * total
    return kappa

def error(g):

    nEFF=len(g)/ACtime(g)
    ERROR=numpy.stdev(g)/math.sqrt(nEFF)
    return ERROR

def blockReduceFB(g,blockSize):

    Nlength = len(g)
    reducedData = [];

    Nblock = int(Nlength / blockSize)
    for i in range(Nblock):
            reducedData.append(numpy.mean(g[i*blockSize : i*blockSize + blockSize]))

    return reducedData

def blockReduce(g):

    acor_result = acor.acor(g)
    blockSize = int(math.ceil(acor_result[0]))
    Nlength = len(g)
    reducedData = [];

    Nblock = int(Nlength / blockSize)
    for i in range(Nblock):
            reducedData.append(numpy.mean(g[i*blockSize : i*blockSize + blockSize]))

    return reducedData


def stats(g):

    reducedData = blockReduce(g)

    l = [len(reducedData), numpy.mean(reducedData), numpy.std(reducedData), numpy.std(reducedData)/math.sqrt(len(reducedData))]

    return l

#g = numpy.loadtxt(sys.argv[1])

#print "mean = %f" % (numpy.mean(g))
#print "stdev = %f" % (numpy.std(g))
#print "autocorrelation time = %f" % (ACtime(g))
#print "error = %f" % (error(g))



