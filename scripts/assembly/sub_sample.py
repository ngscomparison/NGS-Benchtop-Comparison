#!/usr/bin/env python
#MIT License
#Copyright (c) 2009-2011 Brent Pedersen, Haibao Tang
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import random
import sys
import os

def write_random_records(fname, N=0.5):
    """ get N random headers from a fastq file without reading the
    whole thing into memory"""
    records = sum(1 for _ in open(fname)) / 4
    percentage = int(round(records * N))	
    rand_records = sorted(random.sample(xrange(records), int(percentage)))

    pName, pSuffix = os.path.splitext(fname)    
    pName = "%s.%.3fpercent.fastq" % (pName, N)
    fha = open(fname)
    suba = open(pName, "w")
    rec_no = -1
    for rr in rand_records:
        while rec_no < rr:
            rec_no += 1       
            for i in range(4): fha.readline()
        for i in range(4):
            suba.write(fha.readline())
	rec_no += 1 

    print >>sys.stderr, "wrote to %s" % (suba.name)
    suba.close()
    fha.close()

if __name__ == "__main__":
    N = 0.5 if len(sys.argv) < 3 else float(sys.argv[2])
    write_random_records(sys.argv[1], N)
