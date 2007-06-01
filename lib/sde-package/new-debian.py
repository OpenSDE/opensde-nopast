import urllib2, re, os,sys,optparse
from BeautifulSoup import BeautifulSoup
from HTMLParser import HTMLParser
from info import *
class cParseHTML(HTMLParser):
    val=None
    def handle_starttag(self, tag, attrs):
        self.val=re.sub(self.get_starttag_text()+"|\n|\r",
        " ",self.val)
    def parse(self,string):
        self.val=string
        self.feed(self.val)
	return self.val 
cParse=cParseHTML()
parse=cParse.parse	
repo=None
pkg=None
parser = optparse.OptionParser(usage)
parser.add_option("-b", "--base", dest="base",
						help="""Change base i.e from 
						http://packages.debian.org to http://packages.ubuntu.com""")
parser.add_option("-d", "--distro",dest="distro",
						help="""chose distro i.e stable (default) testing,unstable	
						oldstable experimental etc. """)
parser.add_option("-f", "--force",
						action="store_true", dest="force",
						help="""Toggle force values on/off. Default can be set in 
						lib/sde-download/info.py.""")
parser.add_option("-g", "--guess",
						action="store_true", dest="guess",
						help="""Toggle guess values on/off. Default can be set in 
						lib/sde-download/info.py.""")
parser.add_option("-o", "--outpkg",dest="outpkg",
						help="""Write desc to package.""")
(options, args) = parser.parse_args()
argn=0
if len(args) != 1:
	parser.error("incorrect number of arguments")
if options.base:
    base=options.base
if options.distro:
	distro=options.distro
if options.force:
	if force:
		force=False
	else: force=True
if options.guess:
	if guess:
		guess=False
	else: force=True
nargs=len(sys.argv)-1
if sys.argv[nargs].startswith("-") or sys.argv[nargs].startswith("--"):
	parse.error("Invalid options")
opts=sys.argv[nargs].split("/")
if len(opts) == 1:
	pkg=sys.argv[nargs]
	for cat in categories:
		url=base + "/" + distro + "/" + cat + "/" + pkg
		try:
			urllib2.urlopen(url)
			repo=cat
		except:pass
elif len(opts)==2:
	repo=opts[0]
	pkg=opts[1]
else:
	parse.error("Invalid options.")
if not repo:parser.error("Package doesn't exist.")
if not pkg:parse.error("Invalid options.")	
url=base + "/" + distro + "/" + repo + "/" + pkg
try:
	page=urllib2.urlopen(url).read()
except: 
	print "Error: package '%s' does not exist." % sys.argv[nargs]
	sys.exit()
soup = BeautifulSoup(page)
copy=copynote(pkg)
for link in soup("a"):
    link=str(link)
    if re.search("tar\.gz",link):
        buf=re.sub("^.|.$","",
        re.search('("|\').*("|\')',link).group())
        descd+=" " + buf.split("/").pop()
        descd+=" " + re.sub(buf.split("/").pop()+"$","",buf)
try:
	descv="[V] " + re.sub("^.|.$","",re.search("\(.*\)",
					str(soup("h1"))).group())
except: pass
try:
	desci="[I] " + parse("".join(soup("h2")[0])).capitalize()+"."
except: pass
try:	
	desct=parse(str(soup("p")[1]))
except: pass
lcat=soup("span")
if len(lcat) > 0:
	lcat=re.sub("^.|.$","",str(lcat))
if force:
	descu="[U] " + url
	desca="[A] Unknown"
	descl="[L] Unknown"
	descs="[S] Stable"
if guess:
	try:
		stat=status[distro]
		descs="[S] " + stat
	except: pass
	try:
		cat=categories[repo]
		descc="[C] " + cat
	except: pass
	try:
		license=licenses[lcat]
		descl="[L] " + license
	except:pass	
sdesct=""
cnt=0
cnt2=0
desct=re.sub("^\s*","",desct)
for word in desct.split(" "):
	cnt+=len(word)+1
	if cnt < 76:
		if cnt2 == 0:
			sdesct+="[T] %s" % word
			cnt2=1
		else:sdesct+=" %s" % word
	else:
		sdesct+="\n[T] %s" % word
		cnt=1
formatteddesc="""%(copy)s

%(i)s

%(t)s

%(u)s

%(a)s
%(m)s

%(c)s

%(l)s
%(s)s
%(v)s
%(p)s

%(d)s
"""%{ "copy": copy,"i": desci,"t":sdesct,"u":descu,"a":desca,
"m":descm,"c":descc,"l":descl,"s":descs,"v":descv,"p":descp,
"d":descd} 

if options.outpkg:
	output=options.outpkg.split("/")
	optcnt=len(output) - output.count("")
	out=""
	if  optcnt == 1:
		os.system("echo -e \"\033[33;1m=>\033[0m assuming reqested repository as 'wip.'\"") 
		out="package/wip/" +output[0]+"/"+output[0]+".desc"
		dir="package/wip/" +output[0]
		if os.path.isdir(dir):
			if os.path.isfile(out):
				print """failed
					package %s belongs to wip!""" % output[0]
				sys.exit(1)
		else:
			os.mkdir(dir)
		#outf=open(out,"w")
		#outf.write(formatteddesc)	
		#outf.close()
	elif optcnt==2:
		repository="package/" + output[0]
		if not os.path.isdir(repository):
			print "Error:invalid repository '%s'!" % dir
			sys.exit(1)
		dir=repository + "/" + output[1]
		if os.path.isdir(dir):
			out=dir+"/"+output[1]+".desc"
			if os.path.isfile(out):
				print "failed\n	package %(p)s belongs to %(c)s!" %{"p":output[1],
					"c":output[0]}
				sys.exit(1)		
		else:
			os.mkdir(dir)
	else:parser.error("Inavlid Option for --outpkg (-o)")
	try:
		outf=open(out,"w")
		outf.write(formatteddesc)	
		outf.close()
	except:
		print"Error writing to file " + out		
	todo=""
	for line in formatteddesc.split("\n"):
		if re.search("^\[.\] TODO:",line):todo+="\n" + line
	if not todo == "":
		print "The following needs completing:"
		print todo
else:
	print formatteddesc
