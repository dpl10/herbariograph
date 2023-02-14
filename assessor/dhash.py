#!/usr/bin/env python3

### SAFE AND REQUIRED IMPORTS
import getopt
import os
import sys
from imagededup.methods import DHash



### PRINT TO STANDARD ERROR
def eprint(*args, **kwargs):
	print(*args, file = sys.stderr, **kwargs)



### USER SETTINGS
settings = {}
settings['inputDirectory'] = ''



### READ OPTIONS
inputDirectoryError = 'input directory (required): -i directory | --input=directory'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'i:h', ['input=', 'help'])
except getopt.error as err:
	eprint(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-i', '--input'):
		if os.path.isdir(value):
			settings['inputDirectory'] = value
		else:
			eprint(f"input directory does not exist {value}")
			sys.exit(2)
	elif argument in ('-h', '--help'):
		eprint('\nA Python3 script to calculate difference hash (dHash) values.')
		eprint(inputDirectoryError + '\n')
		sys.exit(0)



### START/END
if not settings['inputDirectory']:
	eprint(inputDirectoryError)
	sys.exit(2)
else:
	eprint('started...')
	eprint(f"input directory = {settings['inputDirectory']}")



### DHASH
dhash = DHash()
dhashes = dhash.encode_images(image_dir = settings['inputDirectory'])
print('file\tdhash')
for file, hash in dhashes.items():
	print(f"{file}\t{hash}")
