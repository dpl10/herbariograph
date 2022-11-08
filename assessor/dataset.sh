#!/bin/bash

###
### REUSED SCRIPTS
###

DOWNLOAD='XXH=$(echo "{}" | awk "{print substr(\$1,1,16)}"); URL=$(echo "{}" | awk "{print substr(\$1,17)}"); wget -O "$XXH".jpg "$URL"; MINWAIT=3; MAXWAIT=7; sleep $((MINWAIT+RANDOM % (MAXWAIT-MINWAIT)))'

SELECT1000='
import sys
OCCURRENCEID = 1
INSTITUTIONCODE = 2
COLLECTIONCODE = 3
SCIENTIFICNAME = 4
URL = 5
MAX = 1000
count = 0
genera = {} ### genus => True
for line in sys.stdin:
   columns = line.rstrip().split("\t")
   name = columns[SCIENTIFICNAME].split(" ")
   if count < MAX and name[0] not in genera:
      genera[name[0]] = True
      print(f"{columns[OCCURRENCEID]}\t{columns[INSTITUTIONCODE]}\t{columns[COLLECTIONCODE]}\t{columns[SCIENTIFICNAME]}\t{columns[URL]}")
      count += 1
'

SELECTDUP='
import sys
OCCURRENCEID = 1
INSTITUTIONCODE = 2
COLLECTIONCODE = 3
SCIENTIFICNAME = 4
URL = 5
MAX = 100000
count = 0
genera = {} ### genus => True
oid = {} ### occurenceID => True
for line in sys.stdin:
   columns = line.rstrip().split("\t")
   name = columns[SCIENTIFICNAME].split(" ")
   if columns[OCCURRENCEID] in oid:
      print(f"{columns[OCCURRENCEID]}\t{columns[INSTITUTIONCODE]}\t{columns[COLLECTIONCODE]}\t{columns[SCIENTIFICNAME]}\t{columns[URL]}")
   elif count < MAX and name[0] not in genera:
      genera[name[0]] = True
      oid[columns[OCCURRENCEID]] = True
      print(f"{columns[OCCURRENCEID]}\t{columns[INSTITUTIONCODE]}\t{columns[COLLECTIONCODE]}\t{columns[SCIENTIFICNAME]}\t{columns[URL]}")
      count += 1
'



###
### DATASET CREATION
###

HERBARIA=( 'C' 'F' 'K' 'MO' 'NY' )
for HERBARIUM in "${HERBARIA[@]}"; do
   mkdir -p 'raw-dataset/aesthetically-pleasing-mounted-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/biocultural-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/carpological-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/invisible-mounted-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/labels-only/'$HERBARIUM
   mkdir -p 'raw-dataset/live-plants/'$HERBARIUM
   mkdir -p 'raw-dataset/ordinary-mounted-specimens-closeup/'$HERBARIUM
   mkdir -p 'raw-dataset/ordinary-mounted-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/xylogical-specimens/'$HERBARIUM
done
mkdir -p raw-dataset/illustrations-color/BHL
mkdir -p raw-dataset/illustrations-gray/BHL

find raw-dataset -type d | xargs -I {} -P 1 mkdir -p 'final-dataset/{}'



###
### ILLUSTRATIONS
###
### manually download plant illustrations from BHL via https://www.flickr.com/photos/biodivlibrary/albums
### manually removed non-illustrations 

### LDA from 20 arbitrarily selected images (should probably have used more than 20)
mkdir test-out-color
mkdir test-out-gray
find test-color/ -type f -name '*.jpg' | awk -F/ '{print $2}' | xargs -I {} -P 1 convert test-color/{} -separate test-out-color/{}
find test-gray/ -type f -name '*.jpg' | awk -F/ '{print $2}' | xargs -I {} -P 1 convert test-gray/{} -separate test-out-gray/{}
echo 'file,type,R,r,G,g,B,b' | tr ',' '\t' > test-fuzz.tsv
find test-out-color/ -type f -name '*_o.jpg' | awk -F/ '{print $2}' | xargs -I {} -P 1 bash -c 'echo -e {}"\tcolor" | tr "\n" "\t";
compare -metric FUZZ test-color/{} test-out-color/$(echo {} | perl -pe "s/_o.jpg/_o-0.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ test-color/{} test-out-color/$(echo {} | perl -pe "s/_o.jpg/_o-1.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ test-color/{} test-out-color/$(echo {} | perl -pe "s/_o.jpg/_o-2.jpg/") null 2>&1 3>&1 | tr -d " " | tr "(" "\t" | tr ")" "\n"' >> test-fuzz.tsv
find test-out-gray/ -type f -name '*_o.jpg' | awk -F/ '{print $2}' | xargs -I {} -P 1 bash -c 'echo -e {}"\tgray" | tr "\n" "\t";
compare -metric FUZZ test-gray/{} test-out-gray/$(echo {} | perl -pe "s/_o.jpg/_o-0.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ test-gray/{} test-out-gray/$(echo {} | perl -pe "s/_o.jpg/_o-1.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ test-gray/{} test-out-gray/$(echo {} | perl -pe "s/_o.jpg/_o-2.jpg/") null 2>&1 3>&1 | tr -d " " | tr "(" "\t" | tr ")" "\n"' >> test-fuzz.tsv
# file	type	R	r	G	g	B	b
# n9_w1150_49491820678_o.jpg	color	11567.4	0.176508	9420.91	0.143754	14269.6	0.21774
# n7_w1150_48630723108_o.jpg	color	17690.4	0.269939	12517.3	0.191002	16050.2	0.24491
# n9_w1150_50806984592_o.jpg	color	16996.5	0.259351	12120.2	0.184943	18953	0.289205
# n10_w1150_50680756966_o.jpg	color	7579.91	0.115662	6614.29	0.100928	9465.63	0.144436
# n9_w1150_50804534081_o.jpg	color	11940.2	0.182196	9184.56	0.140147	13778.5	0.210246
# n12_w1150_50680716922_o.jpg	color	11803.5	0.18011	7785.7	0.118802	11463.1	0.174916
# n10_w1150_50682441031_o.jpg	color	14741.7	0.224943	10150.8	0.154891	14412	0.219913
# n5_w1150_9203346832_o.jpg	color	13413.2	0.204672	9095.43	0.138787	13765.1	0.210042
# n6_w1150_50679737793_o.jpg	color	9874.16	0.15067	8624.83	0.131606	11960.4	0.182504
# n5_w1150_49927463251_o.jpg	color	11107.3	0.169486	8462.99	0.129137	12970.5	0.197917
# n7_w1150_50704100162_o.jpg	gray	4995.71	0.0762297	3311.74	0.050534	5329.21	0.0813185
# n6_w1150_49894145506_o.jpg	gray	1204.11	0.0183736	873.101	0.0133227	1346.28	0.0205429
# n8_w1150_51222127577_o.jpg	gray	4656.41	0.0710523	3022.65	0.0461227	4841.93	0.0738831
# n5_w1150_49786345232_o.jpg	gray	9420.43	0.143747	7402.79	0.112959	11582.2	0.176732
# n9_w1150_51226126221_o.jpg	gray	5038.07	0.0768761	3375.74	0.0515105	5376.5	0.0820401
# n7_w1150_49012450221_o.jpg	gray	6976.79	0.106459	5435.52	0.0829407	8535.42	0.130242
# n12_w1150_49786151987_o.jpg	gray	6740.99	0.102861	5034.97	0.0768287	8007.23	0.122183
# n24_w1150_48308502967_o.jpg	gray	8982.29	0.137061	5898.71	0.0900085	9500.52	0.144969
# n9_w1150_49887512913_o.jpg	gray	546.924	0.00834552	503.464	0.00768237	677.625	0.0103399
# n10_w1150_49888029726_o.jpg	gray	519.2	0.00792248	396.294	0.00604706	587.991	0.00897216
R CMD BATCH gray.r
#             group.1   group.2
# constant  -1.462459 -10.27471
# var.1    -14.136089 -77.86728
# var.2     12.429549 320.70587
# var.3     38.943431 -49.63974

### grayscale versus color
mkdir test-out
find original-images/BHL/illustrations -type f -name '*.jpg' | awk -F/ '{print $NF}' | xargs -I {} -P $(nproc) convert original-images/BHL/illustrations/{} -separate test-out/{}
echo 'file,R,r,G,g,B,b' | tr ',' '\t' > bhl-fuzz.tsv
find original-images/BHL/illustrations -type f -name '*_o.jpg' | awk -F/ '{print $NF}' | xargs -I {} -P 1 bash -c 'echo -e {} | tr "\n" "\t";
compare -metric FUZZ original-images/BHL/illustrations/{} test-out/$(echo {} | perl -pe "s/_o.jpg/_o-0.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ original-images/BHL/illustrations/{} test-out/$(echo {} | perl -pe "s/_o.jpg/_o-1.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ original-images/BHL/illustrations/{} test-out/$(echo {} | perl -pe "s/_o.jpg/_o-2.jpg/") null 2>&1 3>&1 | tr -d " " | tr "(" "\t" | tr ")" "\n"' >> bhl-fuzz.tsv
mkdir original-images/BHL/illustrations/color
mkdir original-images/BHL/illustrations/gray
tail +2 bhl-fuzz.tsv | awk -F'\t' '{if(-10.27471+(-77.86728*$3)+(320.70587*$5)+(-49.63974*$7) > 2){print "mv original-images/BHL/illustrations/" $1,"original-images/BHL/illustrations/color/"}else{print "mv original-images/BHL/illustrations/" $1,"original-images/BHL/illustrations/gray/"}}' | bash



###
### LIVE PLANT IMAGES
###
### manually separated from MO Herbarium2022 download
### from NY Emu a maximum of 15 images per genus (by Leanna McMillin)



###
### GBIF RECORDED SPECIMEN IMAGES
###
### manual search of GBIF 24 October 2022
# Download format: DWCA
# Filter used:
# {
#   "and" : [
#     "BasisOfRecord is Specimen",
#     "License is one of (CC0 1.0, CC-BY 4.0, CC-BY-NC 4.0)",
#     "MediaType is Image",
#     "OccurrenceStatus is Present",
#     "TaxonKey is Tracheophyta"
#   ]
# }
wget https://api.gbif.org/v1/occurrence/download/request/0117680-220831081235567.zip
GBIF=0117680-220831081235567.zip 
### unzip -c $GBIF occurrence.txt | head -3 | tail -1 | tr '\t' '\n' | awk '{print NR ": " $1}'

### C
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NHMD")&&(($61=="BC")||($61=="CB")||($61=="DK"))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 61,437 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') C-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert C-specimens.bloom.gz

### F
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="F")&&($61=="Botany")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 635,879 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') F-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert F-specimens.bloom.gz

### K
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="K")&&($61=="K")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 76,033 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') K-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert K-specimens.bloom.gz

### MO
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MO")&&($61=="MO")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 476,015 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') MO-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert MO-specimens.bloom.gz

### NY
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NY")&&($61=="NY")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 2,727,071 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') NY-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert NY-specimens.bloom.gz



###
### CARPOLOGICAL, INVISIBLE MOUNTED SPECIMENS, LABELS, ORDINARY MOUNTED SPECIMENS CLOSEUP, AND XYLOGICAL
###

### C
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NHMD")&&(($61=="BC")||($61=="CB")||($61=="DK"))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 61,437 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check C-specimens.bloom.gz > m ### gbifID, identifier; 61,933 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for C specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="NHMD")&&(($3=="BC")||($3=="CB")||($3=="DK"))){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > C-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 61,933 records

awk -F'\t' '{print $2}' C-specimens.tsv | sort | uniq -d > d ### 495 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') C-multi-specimens.bloom.gz
cat d | bloom -gz insert C-multi-specimens.bloom.gz
sort -n C-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check C-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 23 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > C-multi-specimens.tsv
paste e x >> C-multi-specimens.tsv ### 23 records
mkdir -p original-images/C-multi
cd original-images/C-multi
tail -n +2 ../../C-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../


### F
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="F")&&($61=="Botany")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 635,879 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check F-specimens.bloom.gz > m ### gbifID, identifier; 1,317,863 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for F specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="F")&&($3=="Botany")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > F-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 1,317,860 records

awk -F'\t' '{print $2}' F-specimens.tsv | sort | uniq -d > d ### 629,634 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') F-multi-specimens.bloom.gz
cat d | bloom -gz insert F-multi-specimens.bloom.gz
sort -n F-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check F-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 15,270 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > F-multi-specimens.tsv
paste e x >> F-multi-specimens.tsv ### 15,270 records
mkdir -p original-images/F-multi
cd original-images/F-multi
tail -n +2 ../../F-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../


### K
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="K")&&($61=="K")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 76,033 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check K-specimens.bloom.gz > m ### gbifID, identifier; 76,055 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for K specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="K")&&($3=="K")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > K-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 76,050 records

awk -F'\t' '{print $2}' K-specimens.tsv | sort | uniq -d > d ### 16 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') K-multi-specimens.bloom.gz
cat d | bloom -gz insert K-multi-specimens.bloom.gz
sort -n K-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check K-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 24 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > K-multi-specimens.tsv
paste e x >> K-multi-specimens.tsv ### 24 records, all blank images
mkdir -p original-images/K-multi
cd original-images/K-multi
tail -n +2 ../../K-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../


### MO
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MO")&&($61=="MO")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 476,015 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check MO-specimens.bloom.gz > m ### gbifID, identifier; 674,920 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for MO specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="MO")&&($3=="MO")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > MO-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 674,917 records

awk -F'\t' '{print $2}' MO-specimens.tsv | sort | uniq -d > d ### 73,838 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') MO-multi-specimens.bloom.gz
cat d | bloom -gz insert MO-multi-specimens.bloom.gz
sort -n MO-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check MO-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 23,009 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > MO-multi-specimens.tsv
paste e x >> MO-multi-specimens.tsv ### 23,009 records
mkdir -p original-images/MO-multi
cd original-images/MO-multi
tail -n +2 ../../MO-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../


### NY
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NY")&&($61=="NY")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 2,727,071 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check NY-specimens.bloom.gz > m ### gbifID, identifier; 2,786,110 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for NY specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="NY")&&($3=="NY")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > NY-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 2,786,106 records

awk -F'\t' '{print $2}' NY-specimens.tsv | sort | uniq -d > d ### 39,627 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') NY-multi-specimens.bloom.gz
cat d | bloom -gz insert NY-multi-specimens.bloom.gz
sort -n NY-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check NY-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 7,374 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > NY-multi-specimens.tsv
paste e x >> NY-multi-specimens.tsv ### 7,374 records
mkdir -p original-images/NY-multi
cd original-images/NY-multi
tail -n +2 ../../NY-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../


# NY from ordinary-aesthetic download?







###
### BIOCULTURAL SPECIMENS
###

### GH (Economic Herbarium of Oakes Ames; ECON) and REFLORA (Economic Botany Collection; EBC) via GBIF
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($68)&&length($60)&&length($61)&&length($189)&&((($60=="ECON")&&($61=="ECON"))||(($60=="EBC")&&($61=="EBC"))||(($60=="K")&&($61=="Economic Botany Collection")))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 7,341 records
sort -t$'\t' -k 1b,1 s > t
awk -F'\t' '{print $1}' t > g
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' > m ### gbifID, identifier; 40,430,745 records
sort -t$'\t' -k 1b,1 m > n
grep -f g n > o ### 7,478 records
echo -n '' > y
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t o | cut -d$'\t' -f2- | grep -v EMPTY | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > ECON+EBC.tsv
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t o | cut -d$'\t' -f2- | grep -v EMPTY  | paste - y >> ECON+EBC.tsv ### 7,478 records

mkdir -p original-images/ECON-original
cd original-images/ECON-original
grep -P 'ECON\tECON' ../../ECON+EBC.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD" ### 7,168 images, all sheets
cd ../
mkdir ECON
../../resizeImage.py -i ECON-original -o ECON -q 94 -p -s 4096
cd ../

mkdir -p original-images/EBC
cd original-images/EBC
grep -P 'EBC\tEBC' ../../ECON+EBC.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P 1 bash -c "$DOWNLOAD" ### 303 downloads, all empty files
cd ../../ 

### K (Economic Botany Collection; 24 October 2022)
wget https://orphans.gbif.org/GB/1d31211e-350e-492a-a597-34d24bbc1769.zip
echo -n '' > x
unzip -c 1d31211e-350e-492a-a597-34d24bbc1769.zip image.txt | tail +4 | awk -F, 'BEGIN{OFS="\t"}{print $1,$2}' | grep "\S" | tr -d '"' | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\turl\txxh64' > K-EBC.tsv
unzip -c 1d31211e-350e-492a-a597-34d24bbc1769.zip image.txt | tail +4 | awk -F, 'BEGIN{OFS="\t"}{print $1,$2}' | grep "\S" | tr -d '"' | paste - x >> K-EBC.tsv ### 2,441 records
mkdir -p original-images/K
cd original-images/K
tail -n +2 ../../K-EBC.tsv | awk -F'\t' '{print $3$2}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### C (Natural History Museum of Denmark Biocultural Botany Collection; 24 October 2022)
wget https://specify-snm.science.ku.dk/static/depository/export_feed/DwCA-BC.zip
echo -n '' > x
unzip -c DwCA-BC.zip Media.csv | tail +4 | awk -F, 'BEGIN{OFS="\t"}{print $1,$2}' | grep "\S" | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\turl\txxh64' > C-BC.tsv
unzip -c DwCA-BC.zip Media.csv | tail +4 | awk -F, 'BEGIN{OFS="\t"}{print $1,$2}' | grep "\S" | paste - x >> C-BC.tsv ### 1,488 records
mkdir -p original-images/C
cd original-images/C
tail -n +2 ../../C-BC.tsv | awk -F'\t' '{print $3$2}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### US (Anthropology; 25 October 2022)
### manually downloaded records with images and material type = fibers by continent/region (to partially overcome the 5k limit [United States truncated at 5k]) from https://collections.nmnh.si.edu/search/anth/ 
### permission required... aborting

### F (Field Museum Economic Botany Collection; 28 October 2022)
for k in {0..542}; do
   save-page.sh 'https://collections-botany.fieldmuseum.org/list?f%5B0%5D=ss_CatCatalogSubset%3A%22Economic%20Botany%22&page='$k --browser firefox --load-wait-time 13 --save-wait-time 3 --destination 'F-page'$k
done
find F -type f -name 'F-page*' | xargs grep -h -Po '(?<=href=")[^"]*' | grep '.jpg$' | sort -u | awk '{print "F\t" $1}' > x
echo -n '' > y
cat x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'institutionCode\turl\txxh64' > F-EBC.tsv
paste x y >> F-EBC.tsv ### 9,017 records
mkdir -p original-images/F
cd original-images/F
tail -n +2 ../../F-EBC.tsv | awk -F'\t' '{print $3$2}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### MO also has collections, but difficult to individually extract
#
# add 
#
# MO (also) http://www.mobot.org/plantscience/resbot/Econ/EconBot01.htm



###
### AESTHETICALLY PLEASING MOUNTED HERBARIUM SPECIMENS
###
### 374 pleasing specimens from NY Emu (by Leanna McMillin), manually filtered down to 331

### 334 ordinary specimens from NY (maximum of 1 per genus)
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NY")&&($61=="NY")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 2,727,071 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check NY-specimens.bloom.gz > m ### gbifID, identifier; 2,786,110 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for 1000 NY average specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="NY")&&($3=="NY")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > a ### 2,786,106 records
sort -n a | python3 -c "$SELECT1000" > b
echo -n '' > x
cat b | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > NY-ordinary-aesthetic.tsv
paste b x >> NY-ordinary-aesthetic.tsv ### 1,000 records
mkdir -p original-images/NY-ordinary
cd original-images/NY-ordinary
tail -n +2 ../../NY-ordinary-aesthetic.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../
### => manually screened 331 images in default sort order




# MUSIQ

mkdir musiq
cd musiq
TF='2.10.0'
echo 'FROM tensorflow/tensorflow:'$TF > Dockerfile
echo 'RUN python3 -m pip install --upgrade pip && python3 -m pip install --upgrade setuptools && python3 -m pip install tensorflow-addons && python3 -m pip install "absl-py>=0.12.0" && python3 -m pip install "chex>=0.0.7" && python3 -m pip install "clu>=0.0.3" && python3 -m pip install "einops>=0.3.0" && python3 -m pip install "flax==0.3.3" && python3 -m pip install "ml-collections==0.1.0" && python3 -m pip install "numpy>=1.19.5" && python3 -m pip install "pandas>=1.1.0" && python3 -m pip install "jax>=0.1.55" && python3 -m pip install "jaxlib>=0.1.37"' >> Dockerfile
docker build -t 'tensorflow:'$TF'-cpu-musiq' .
mkdir -p musiq/model
cd musiq/model
wget https://storage.googleapis.com/gresearch/musiq/ava_ckpt.npz
wget https://raw.githubusercontent.com/google-research/google-research/master/musiq/model/multiscale_transformer.py
wget https://raw.githubusercontent.com/google-research/google-research/master/musiq/model/multiscale_transformer_utils.py
wget https://raw.githubusercontent.com/google-research/google-research/master/musiq/model/preprocessing.py
wget https://raw.githubusercontent.com/google-research/google-research/master/musiq/model/resnet.py
cd ../
wget https://raw.githubusercontent.com/google-research/google-research/master/musiq/run_predict_image.py
cd ../
docker run --runtime=nvidia -u $(id -u):$(id -g) --rm -it -v "${PWD}:/tmp" -w /tmp 'tensorflow:'$TF'-cpu-musiq'
python3 -m musiq.run_predict_image --ckpt_path=musiq/model/musiq_ava_ckpt.npz --image_path=$(pwd)/grace.jpg # fails
exit
cd ../







# python3 -c '
# from tf2cv.model_provider import get_model as tf2cv_get_model
# import tensorflow as tf
# net = tf2cv_get_model("shufflenet_g1_wd4", pretrained = True, data_format = "channels_last")
# x = tf.random.normal((1, 224, 224, 3))
# y_net = net(x)
# print(y_net)
# '
python3 -c '
from tf2cv.model_provider import get_model as tf2cv_get_model
import numpy as np
import PIL.Image as Image
import tensorflow as tf


PIXELS = (224, 224)

net = tf2cv_get_model("shufflenet_g1_wd4", pretrained = True, data_format = "channels_last")

grace_hopper = tf.keras.utils.get_file("image.jpg","https://storage.googleapis.com/download.tensorflow.org/example_images/grace_hopper.jpg")
grace_hopper = Image.open(grace_hopper).resize(PIXELS)
grace_hopper = np.array(grace_hopper)/255.0

y_net = net(grace_hopper[np.newaxis, ...])
print(tf.nn.softmax(y_net))

# labels_path = tf.keras.utils.get_file("ImageNetLabels.txt","https://storage.googleapis.com/download.tensorflow.org/data/ImageNetLabels.txt")
# imagenet_labels = np.array(open(labels_path).read().splitlines())

# predicted_class = tf.math.argmax(y_net[0], axis = -1)
# print(imagenet_labels[predicted_class])

'


# TRes:
# https://arxiv.org/pdf/2108.06858.pdf
# https://github.com/isalirezag/TReS
# SqueezeNet https://pypi.org/project/tf2cv/ + https://openaccess.thecvf.com/content_cvpr_2018/papers/Zhang_The_Unreasonable_Effectiveness_CVPR_2018_paper.pdf

# AIHIQnet https://github.com/junyongyou/aihiqnetvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

# MANIQA https://github.com/IIGROUP/MANIQA

#
# NIMA == does not work
#


mkdir nima
cd nima
wget https://github.com/idealo/image-quality-assessment/archive/refs/heads/master.zip
unzip master.zip
cd image-quality-assessment-master
docker build -t nima-cpu . -f Dockerfile.cpu ### gpu fails due to GPG signing error
cd ../../

### pleasing
nima/image-quality-assessment-master/predict --docker-image nima-cpu --base-model-name MobileNet --weights-file $(pwd)/nima/image-quality-assessment-master/models/MobileNet/weights_mobilenet_aesthetic_0.07.hdf5 --image-source $(pwd)/original-images/NY-pleasing > a
tail -n +2 a | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @tsv' | tail -n +2 > b
nima/image-quality-assessment-master/predict --docker-image nima-cpu --base-model-name MobileNet --weights-file $(pwd)/nima/image-quality-assessment-master/models/MobileNet/weights_mobilenet_technical_0.11.hdf5 --image-source $(pwd)/original-images/NY-pleasing > t
tail -n +2 t | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @tsv' | tail -n +2 > u
paste b u | awk -F'\t' 'BEGIN{OFS="\t";print "image","type","aesthetic","technical"}{print $1,"pleasing",$2,$4}' > nima.tsv 
grep pleasing nima.tsv | datamash mean 3 mean 4 ### 5.6472267427625	4.5191672003484

### ordinary
nima/image-quality-assessment-master/predict --docker-image nima-cpu --base-model-name MobileNet --weights-file $(pwd)/nima/image-quality-assessment-master/models/MobileNet/weights_mobilenet_aesthetic_0.07.hdf5 --image-source $(pwd)/original-images/NY-ordinary > a
tail -n +2 a | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @tsv' | tail -n +2 > b
nima/image-quality-assessment-master/predict --docker-image nima-cpu --base-model-name MobileNet --weights-file $(pwd)/nima/image-quality-assessment-master/models/MobileNet/weights_mobilenet_technical_0.11.hdf5 --image-source $(pwd)/original-images/NY-ordinary > t
tail -n +2 t | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @tsv' | tail -n +2 > u
paste b u | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,"ordinary",$2,$4}' >> nima.tsv 
grep ordinary nima.tsv | datamash mean 3 mean 4 ### 5.5303331218473	4.5123623302256

R CMD BATCH aesthetic.r 













#
# remove duplicates
# pretrain on imagenet (without plants) for out-of-distribution detection
#

