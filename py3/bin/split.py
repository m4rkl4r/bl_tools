#!/unixworks/virtualenvs/py382/bin/python

## written by mark e price Wed Jan 31 17:54:41 EST 2018
# generally useful, but intended to split hostlists into chuncks for bladelogic job runs

from optparse import OptionParser
from sys import exit

splitOptCnt=0
(option,args)=(None,None)

parser = OptionParser()
parser.add_option("--input", dest="input",type="string",help="newline delimited file we are splitting")
parser.add_option("--no-strip", dest="no-strip",action="store_true",help="by default trailing and ending white space is removed from each line")
parser.add_option("--prefix",dest="prefix",type="string",help="name of output files.  Defaults to input filename. .1, .2, .3, etc will be appended.")
parser.add_option("--size",dest="size",type="int",action="store",help="How many lines per output file.  Required.")
parser.add_option("--destdir",dest="destdir",type="string",action="store",help="The directory to place files in.  Defaults to CWD.")
parser.add_option("--verbose",dest="verbose",action="store_true",help="makes the output more verbose")

(option,args) = parser.parse_args()

if not option.size or option.size <= 0:
	parser.print_help()
	print("\nNOTE: --count is required")
	exit(1)
if not option.input:
	parser.print_help()
	print("\nNOTE: you must specify the input file with --input")
	exit(1)

if option.prefix: prefix=option.prefix
else: prefix = option.input.split("/")[-1]
	
inputlist = open(option.input,"r").readlines()
inputlist = [x.strip()+"\n" for x in inputlist]
linecount = len(inputlist)

step=option.size

start=0
end=step

iterations=0

while end <= linecount:
	batch=inputlist[start:end]

	name=prefix + "." + str(iterations)
	if option.destdir: name = option.destdir + "/" + name

	iterations = iterations + 1

	if option.verbose:
		print("opening",name)
		print(len(batch))

	f=open(name,"w")
	f.writelines(batch)
	#for line in batch:
	#	print "writing",line
	#	f.write(line)
	#	f.write("\n")
	f.close()
	#open(name,"w").writelines(batch)

	if end == linecount: end = linecount+1
	else:
		start=end
		end=end+step
		if end>linecount: end=linecount
