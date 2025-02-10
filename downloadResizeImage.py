#!/usr/bin/env python3

### SAFE IMPORTS
import cv2
import getopt
import numpy as np
import os
import shutil
import sys
import textwrap
import time
import urllib.request



### CONSTANTS
WAIT = 3
WRAP = shutil.get_terminal_size().columns

### INFILE CONSTANTS
OCCURRENCEID = 0
INSTITUTIONCODE = 1
COLLECTIONCODE = 2
SCIENTIFICNAME = 3
URL = 4
XXH64 = 5

DHASH = 6



### PRINT TO STANDARD ERROR
def eprint(*args, **kwargs):
	print(*args, file = sys.stderr, **kwargs)

### WRAP TEXT
def eprintWrap(string, columns = WRAP):
	eprint(wrap(string, columns))

def wrap(string, columns = WRAP):
	return '\n'.join(textwrap.wrap(string, columns))



### USER SETTINGS
settings = {}
settings['append'] = False
settings['inFile'] = ''
settings['log'] = ''
settings['outDirectory'] = ''
settings['quality'] = 94
settings['size'] = 1024



### READ OPTIONS
inFileError = f"Download list (required; header assumed; zero indexed: URL = {URL}, file stem = {XXH64}): -i file.tsv | --input=file.tsv"
outFileError = 'Output log file (required): -l file.tsv | --log=file.tsv'
outDirectoryError = 'Output directory (required): -o directory | --output=directory'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'ahi:l:o:q:s:', ['append', 'help', 'input=', 'log=', 'output=', 'quality=', 'size='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-a', '--append'):
		settings['append'] = True
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to download and resize images with openCV2.')
		eprintWrap(f"Restart downloads in append mode (optional; default = {settings['append']}): -a | --append")
		eprintWrap(inFileError)
		eprintWrap(outFileError)
		eprintWrap(outDirectoryError)
		eprintWrap(f"JPEG quality (optional; default = {settings['quality']}): -q int | --quality=int")
		eprintWrap(f"Output image size in pixels of longest side (optional; default = {settings['size']}): -s int | --size=int")
		eprint('')
		sys.exit(0)
	elif argument in ('-i', '--input'):
		if os.path.isfile(value):
			settings['inFile'] = value
		else:
			eprintWrap(f"Input file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-l', '--log'):
		settings['log'] = value
	elif argument in ('-o', '--output'):
		if os.path.isdir(value):
			settings['outDirectory'] = value
		else:
			eprintWrap(f"Output directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-q', '--quality') and int(value) > 0 and int(value) <= 100:
		settings['quality'] = int(value)
	elif argument in ('-s', '--size') and int(value) > 0:
		settings['size'] = int(value)



### START/END
if not settings['inFile']:
	eprintWrap(inFileError)
	sys.exit(2)
elif not settings['log']:
	eprintWrap(outFileError)
	sys.exit(2)
elif settings['append'] and not os.path.isfile(settings['log']):
	eprintWrap(f"Log file '{settings['log']}' for appending does not exist!")
	sys.exit(2)
elif not settings['outDirectory']:
	eprintWrap(outDirectoryError)
	sys.exit(2)
else:
	eprintWrap('started...')
	for key, value in settings.items():
		eprintWrap(f"{key} = {value}")
	eprintWrap('')



### READ LOG
complete = {} ### file stem => True
if settings['append']:
	maxIndex = max((OCCURRENCEID, INSTITUTIONCODE, COLLECTIONCODE, SCIENTIFICNAME, URL, XXH64, DHASH))+1
	with open(settings['log'], mode = 'rt', encoding = 'utf8', errors = 'replace') as file:
		for k, line in enumerate(file):
			if k > 0:
				columns = line.strip().split('\t')
				if len(columns) >= maxIndex:
					complete[columns[XXH64]] = True



### READ AND PROCESS DOWNLOAD LIST
lastHost = ''
logFile = open(settings['log'], 'a' if settings['append'] else 'w')
maxIndex = max((OCCURRENCEID, INSTITUTIONCODE, COLLECTIONCODE, SCIENTIFICNAME, URL, XXH64))+1
with open(settings['inFile'], mode = 'rt', encoding = 'utf8', errors = 'replace') as file:
	for k, line in enumerate(file):
		if k == 0:
			if not settings['append']:
				logFile.write('occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64\tdhash\n')
		else:
			columns = line.strip().split('\t')
			if len(columns) >= maxIndex and len(columns[URL]) and len(columns[XXH64]):
				if settings['append'] and columns[XXH64] in complete:
					continue
				host = columns[URL].split('/')
				if len(host) >= 4:
					if lastHost == host[2]:
						time.sleep(WAIT)
					lastHost = host[2]
					### DOWNLOAD
					try:
						download = urllib.request.urlopen(columns[URL])
						imageArray = np.asarray(bytearray(download.read()), dtype = np.uint8)
					except:
						eprintWrap(f"URL '{columns[URL]}' could not be downloaded or read!")
						continue
					### RESIZE
					try:
						image = cv2.imdecode(imageArray, -1)
						x = image.shape[0]
						y = image.shape[1]
						if x > y:
							ratio = settings['size']/y
							resize = (settings['size'], int(x*ratio))
						else:
							ratio = settings['size']/x
							resize = (int(y*ratio), settings['size'])
						image = cv2.resize(image, resize)
					except:
						eprintWrap(f"Image '{columns[XXH64]}.jpg' could not be read!")
						continue
					### DHASH
					try:
						grayImage = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
						smallImage = cv2.resize(grayImage, (9, 8))
						bits = []
						for row in range(smallImage.shape[0]):
							for col in range(smallImage.shape[1]-1):
								l = smallImage[row][col]
								r = smallImage[row][col+1]
								if l > r:
									bits.append('1') 
								else:
									bits.append('0')
						dhash = ''
						for i in range(0, len(bits), 4):
							dhash += hex(int(''.join(bits[i:i+4]), 2))
						dhash = dhash.replace('0x', '')
					except:
						eprintWrap(f"DHASH could not be calculated for '{columns[XXH64]}.jpg'!")
						continue
					### SAVE
					try:
						outfile = os.path.join(settings['outDirectory'], f"{columns[XXH64]}.jpg")
						cv2.imwrite(outfile, image, (cv2.IMWRITE_JPEG_QUALITY, settings['quality']))
						logFile.write(f"{columns[OCCURRENCEID]}\t{columns[INSTITUTIONCODE]}\t{columns[COLLECTIONCODE]}\t{columns[SCIENTIFICNAME]}\t{columns[URL]}\t{columns[XXH64]}\t{dhash}\n")
					except:
						eprintWrap(f"Image '{columns[XXH64]}.jpg' could not be saved!")



### DONE
logFile.close()
sys.exit(0)
