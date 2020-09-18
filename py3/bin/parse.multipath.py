#!/unixworks/virtualenvs/py382/bin/python
from __future__ import print_function
from sys import stderr, stdout
import sys
import re

class multipathParser():

    disks = dict()
    diskstatus = dict()
    disktype = dict()
    file = None
    server = None
    outfile = None

    def __init__(self,fname,outfile=None):
        if outfile==None:  self.outfile = stdout
        else: self.outfile = outfile
        self.file = [x.strip() for x in open(fname,"r").readlines()]
        # we assume the first part of each line is "hostname: "
        # let's capture the name and then it out
        self.server = self.file[0].split(":")[0]
        self.file = [re.sub(self.server +": ","",line) for line in self.file]

        # lets parse out the device names and their path entries
        # this does not print anything, and leaves it ready
        self.get_disks(self.file)
    """ contents is list, containing the lines read from the log file"""

    def check(self):
        for disk in self.disks:
            self.check_disk(disk)
        

    # find disk labels, and record each path for that disk label into disks[label]=list()
    def get_disks(self,f):
        for i in range(len(f)):
            if re.search("\) dm\-",f[i]):
                dname = f[i].split(" ")[0]
                self.disks[dname]=list()
                self.disktype[dname]=re.search("\s(\w+,.*)$",f[i]).group(1)
            if re.search(" sd",f[i]):
                self.disks[dname].append(f[i])

    def check_disk(self,label):
        if re.search("LOGICAL VOLUME",self.disktype[label]):
            print(self.server,"device",label,":","WARNING: skipping disktype",self.disktype[label])
            return
        self.diskstatus[label]=True
        paths = self.disks[label]
        #print paths
        #print(label,end=" ")
        #for p in paths: print(p)
        # error if any disks are displayed and not healthy
        badpaths = [p for p in paths if not(re.search("active.ready.running|active..ready", p))]
        if len(badpaths)>0:
            for p in badpaths: print(self.server,"device",label,":","ERROR: bad path:",p,file=self.outfile)
            self.diskstatus[label]=False
        channels=set()
        for p in paths:
            result = re.search("(`-|\|-|\\_) ([0-9]+):",p)
            if result:
                channels.add(result.group(2))
        if len(channels) < 2:
            print(self.server,"device",label,":","ERROR: there are not redundant channels.  channel numbers are:",list(channels),file=self.outfile)
            self.diskstatus[label]=False
        channelcnt=dict()
        cnt = None
        for chan in channels:
            chan=str(chan)
            channelcnt[chan]=len([p for p in paths if re.search("(-|_) "+chan+":",p)])
            if cnt is None:
                cnt = channelcnt[chan]
            else:
                if channelcnt[chan] != cnt:
                    print(self.server,"device",label,":","ERROR: paths are not balanced across the channels:",str(cnt),"vs",str(channelcnt[chan]),"on",str(chan),file=self.outfile)
                    self.diskstatus[label]=False
        print(self.server,"device",label,":","path count by channel:",end=" ")
        for c in channels: print("cnt("+str(c)+")="+str(channelcnt[c]),end=" ")
        print()

if __name__ == "__main__":
    for fname in sys.argv[1:]:
        try:
            print("========== checking",fname,"==========")
            multipathParser(fname).check()
        except:
            pass
