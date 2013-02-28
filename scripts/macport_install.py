#!/usr/bin/python
import os
import subprocess
import glob
from optparse import OptionParser

def install (file, dir):
	if dest == "":
		f = prefix + dir + '/'
	else:
		f = dest + prefix + dir + '/'
		
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	print ("install: " + file + " in " + ' ' + dest + prefix + dir + '/')
	subprocess.check_call ('install -d ' + dest + prefix + dir, shell=True)
	subprocess.check_call ('install ' + file + ' ' + dest + prefix + dir + '/', shell=True)

parser = OptionParser()
parser.add_option ("-p", "--prefix", dest="prefix", help="install prefix", metavar="PREFIX")
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")

(options, args) = parser.parse_args()

if not options.prefix:
	options.prefix = "/opt/local"

if not options.dest:
	options.dest = ""

prefix = options.prefix
dest = options.dest

install ('build/bin/birdfont', '/bin')
install ('build/bin/birdfont-export', '/bin')	
install ('build/bin/libbirdfont.dylib', '/lib')

for file in os.listdir('./layout'):
	install ('layout/' + file, '/share/birdfont/layout')

for file in os.listdir('./icons'):
	install ('icons/' + file, '/share/birdfont/icons')
	
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' );
