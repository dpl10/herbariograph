#!/bin/bash

###
### REUSED SCRIPTS
###

DOWNLOAD='XXH=$(echo "{}" | awk "{print substr(\$1,1,16)}"); URL=$(echo "{}" | awk "{print substr(\$1,17)}"); wget -O "$XXH".jpg "$URL"; MINWAIT=3; MAXWAIT=7; sleep $((MINWAIT+RANDOM % (MAXWAIT-MINWAIT)))'



###
### DATASET CREATION
###

### ILLUSTRATIONS

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

### gray scale versus color
mkdir test-out
find original-images/BHL/illustrations -type f -name '*.jpg' | awk -F/ '{print $NF}' | xargs -I {} -P $(nproc) convert original-images/BHL/illustrations/{} -separate test-out/{}
echo 'file,R,r,G,g,B,b' | tr ',' '\t' > bhl-fuzz.tsv
find original-images/BHL/illustrations -type f -name '*_o.jpg' | awk -F/ '{print $NF}' | xargs -I {} -P 1 bash -c 'echo -e {} | tr "\n" "\t";
compare -metric FUZZ original-images/BHL/illustrations/{} test-out/$(echo {} | perl -pe "s/_o.jpg/_o-0.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ original-images/BHL/illustrations/{} test-out/$(echo {} | perl -pe "s/_o.jpg/_o-1.jpg/") null 2>&1 3>&1 | tr -d " " | tr "()" "\t\t"; compare -metric FUZZ original-images/BHL/illustrations/{} test-out/$(echo {} | perl -pe "s/_o.jpg/_o-2.jpg/") null 2>&1 3>&1 | tr -d " " | tr "(" "\t" | tr ")" "\n"' >> bhl-fuzz.tsv
mkdir original-images/BHL/illustrations/color
mkdir original-images/BHL/illustrations/gray
tail +2 bhl-fuzz.tsv | awk -F'\t' '{if(-10.27471+(-77.86728*$3)+(320.70587*$5)+(-49.63974*$7) > 2){print "mv original-images/BHL/illustrations/" $1,"original-images/BHL/illustrations/color/"}else{print "mv original-images/BHL/illustrations/" $1,"original-images/BHL/illustrations/gray/"}}' | bash



### LIVE PLANT IMAGES

### manually separated from MO herbarium2022 download
### from NY Emu a maximum of 15 images per genus (by Leanna McMillin)



### SPECIMEN IMAGES

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
# unzip -c $GBIF occurrence.txt | head -3 | tail -1 | tr '\t' '\n' | awk '{print NR ": " $1}'



### BIOCULTURAL SPECIMENS

### GH (Economic Herbarium of Oakes Ames; ECON) and REFLORA (Economic Botany Collection; EBC)
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&((($60=="ECON")&&($61=="ECON"))||(($60=="EBC")&&($61=="EBC"))||(($60=="K")&&($61=="Economic Botany Collection")))){print $68,$60,$61,$189}}' > x
sort -t$'\t' -k 1b,1 x > ECON+EBC-specimens.tsv ### occurrenceID, institutionCode, collectionCode, scientificName; 7,341 records
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($68)&&length($60)&&length($61)&&length($189)&&((($60=="ECON")&&($61=="ECON"))||(($60=="EBC")&&($61=="EBC"))||(($60=="K")&&($61=="Economic Botany Collection")))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID; 7,341 records
sort -t$'\t' -k 1b,1 s > t
awk -F'\t' '{print $1}' t > g
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' > m ### gbifID, identifier
sort -t$'\t' -k 1b,1 m > n ### 40,430,745 records
grep -f g n > o ### 7,478 records
echo -n '' > y
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t o | cut -d$'\t' -f2- | grep -v EMPTY | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > ECON+EBC.tsv
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t o | cut -d$'\t' -f2- | grep -v EMPTY  | paste - y >> ECON+EBC.tsv ### 7,478 records

mkdir -p original-images/ECON
cd original-images/ECON
grep -P 'ECON\tECON' ../../ECON+EBC.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD" ### 7,168 images
cd ../../

mkdir -p original-images/EBC
cd original-images/EBC
grep -P 'EBC\tEBC' ../../ECON+EBC.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD" ### 303 images
cd ../../

### K (Economic Botany Collection)
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

### Natural History Museum of Denmark (Biocultural Botany Collection)
wget https://specify-snm.science.ku.dk/static/depository/export_feed/DwCA-BC.zip
echo -n '' > x
unzip -c DwCA-BC.zip Media.csv | tail +4 | awk -F, 'BEGIN{OFS="\t"}{print $1,$2}' | grep "\S" | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\turl\txxh64' > NHMD-BC.tsv
unzip -c DwCA-BC.zip Media.csv | tail +4 | awk -F, 'BEGIN{OFS="\t"}{print $1,$2}' | grep "\S" | paste - x >> NHMD-BC.tsv ### 1,488 records
mkdir -p original-images/NHMD
cd original-images/NHMD
tail -n +2 ../../NHMD-BC.tsv | awk -F'\t' '{print $3$2}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../



### F, MO, US also have collections, but difficult to individually extract
# F https://collections-botany.fieldmuseum.org/list?f%5B0%5D=ss_CatCatalogSubset%3A%22Economic%20Botany%22

# Korean Ethnobotany
# https://www.gbif.org/dataset/8300bfde-f762-11e1-a439-00145eb45e9a
# https://www.gbif.org/occurrence/download?dataset_key=8300bfde-f762-11e1-a439-00145eb45e9a


### AESTHETICALLY PLEASING MOUNTED SPECIMENS
# NIMA:
# https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=8352823
# https://ai.googleblog.com/2017/12/introducing-nima-neural-image-assessment.html
# https://github.com/titu1994/neural-image-assessment
# https://github.com/idealo/image-quality-assessment











#
# remove duplicates
# pretrain on imagenet (without plants) for out-of-distribution detection
#
