#!/bin/bash

###
### REUSED SCRIPTS
###

CSV2TSV='
my $csv = Text::CSV->new({binary=>1});
while(my $row = $csv->getline(STDIN)){
   my $buffer = "";
   for(my $k = 0; $k < $#{$row}; $k++){
      $buffer .= $row->[$k] . "\t";
   }
   $buffer =~ s/\t$//;
   print($buffer);
}
'

DOWNLOAD='XXH=$(echo "{}" | awk "{print substr(\$1,1,16)}"); URL=$(echo "{}" | awk "{print substr(\$1,17)}"); wget -O "$XXH".jpg "$URL"; MINWAIT=3; MAXWAIT=7; sleep $((MINWAIT+RANDOM % (MAXWAIT-MINWAIT)))'

DOWNLOADRESIZE='MINWAIT=3; MAXWAIT=7; sleep $((MINWAIT+RANDOM % (MAXWAIT-MINWAIT))); HERBARIUM=$(echo "{}" | awk -F"\t" "{print \$2}"); URL=$(echo "{}" | awk -F"\t" "{print \$3}"); XXH=$(echo "{}" | awk -F"\t" "{print \$1}"); wget -O "$XXH".jpg "$URL" && ./resizeImage.py -e resized-images/"$HERBARIUM" -f "$XXH".jpg -p -q 94 -s 1024 && rm -f "$XXH".jpg'

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
MAXGENUS = 36 ### assuming ca. 3.4% are useful
MAXIMAGE = 100000
count = 0
genera = {} ### genus => count
oid = {} ### occurenceID => True
for line in sys.stdin:
   columns = line.rstrip().split("\t")
   name = columns[SCIENTIFICNAME].split(" ")
   if columns[OCCURRENCEID] in oid:
      print(f"{columns[OCCURRENCEID]}\t{columns[INSTITUTIONCODE]}\t{columns[COLLECTIONCODE]}\t{columns[SCIENTIFICNAME]}\t{columns[URL]}")
   elif count < MAXIMAGE:
      if name[0] not in genera:
         genera[name[0]] = 0
      if genera[name[0]] < MAXGENUS:
         oid[columns[OCCURRENCEID]] = True
         print(f"{columns[OCCURRENCEID]}\t{columns[INSTITUTIONCODE]}\t{columns[COLLECTIONCODE]}\t{columns[SCIENTIFICNAME]}\t{columns[URL]}")
         genera[name[0]] += 1
         count += 1
'

XXHASH='
import sys
import xxhash
for k, line in enumerate(sys.stdin):
   if k:
      x = line.strip()
      print(f"{x}\t{xxhash.xxh64(x).hexdigest()}")
   else:
      print("occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64")
'



###
### DATASET CREATION
###

HERBARIA=( 'BR' 'C' 'E' 'F' 'GH' 'K' 'L' 'MA' 'MICH' 'MO' 'MPU' 'NY' 'O' 'P' 'US' ) ### 15; additional options (number of specimen records): V, LY, TEX, NCU, RSA, COLO, USF, TRH
for HERBARIUM in "${HERBARIA[@]}"; do
   mkdir -p 'raw-dataset/aesthetically-pleasing-pressed-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/animal-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/biocultural-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/corrupted-images/'$HERBARIUM
   mkdir -p 'raw-dataset/fragmentary-pressed-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/illustrations-color/'$HERBARIUM
   mkdir -p 'raw-dataset/illustrations-gray/'$HERBARIUM
   mkdir -p 'raw-dataset/live-plants/'$HERBARIUM
   mkdir -p 'raw-dataset/micrographs/'$HERBARIUM
   mkdir -p 'raw-dataset/microscope-slides/'$HERBARIUM
   mkdir -p 'raw-dataset/mixed-pressed-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/occluded-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/ordinary-pressed-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/pressed-specimen-reproductions/'$HERBARIUM
   mkdir -p 'raw-dataset/pressed-specimens-closeup/'$HERBARIUM
   mkdir -p 'raw-dataset/spirit-preserved-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/text-focused/'$HERBARIUM
   mkdir -p 'raw-dataset/unpressed-specimens/'$HERBARIUM
   mkdir -p 'raw-dataset/xylogical-specimens/'$HERBARIUM
#
# 19
# + seedlings? (BR?)
# + maps?
# + bark?
# + illustration focused
#
done
mkdir -p raw-dataset/biocultural-specimens/CHNDM
mkdir -p raw-dataset/biocultural-specimens/Met
mkdir -p raw-dataset/illustrations-color/BHL
mkdir -p raw-dataset/illustrations-gray/BHL



###
### ILLUSTRATIONS
###
### manually download plant illustrations from BHL via https://www.flickr.com/photos/biodivlibrary/albums
### manually removed non-illustrations
### also manually separated from other institutional downloads (see below)

### LDA from 20 arbitrarily selected images (should probably have used more than 20 images and used SVM in place of LDA)
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

### BR
### color: https://www.botanicalcollections.be/#/en/search/specimen?filters=%7B%22__fulltext__%22:%7B%22type%22:%22FULL_TEXT%22,%22searchText%22:null%7D,%22family_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22genus_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22name_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22hasImage_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22true%22,%22count%22:1412162%7D%5D%7D,%22collectionCountryCode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22typeSpecimen_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorName_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorNumber_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22specimenKind_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22DC%22,%22count%22:175%7D%5D%7D,%22plantDetails_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22VASCULAR_PLANTS%22,%22count%22:1412162%7D%5D%7D,%22barcode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D%7D&sort=%5B%5D
unzip -c herbarium_export_20221123031956.zip herbarium_export_20221123031956.txt | tail -n +2 | awk -F'\t' 'BEGIN{OFS="\t"}{print $9,"BR","BR",$1,$6}' | perl -pe 's!https://www.botanicalcollections.be/specimen/(BR[0-9]+)$!$1\t$1!' | perl -F'\t' -lane '$F[4]=~s!([BR0-9]{3,3})!$1/!g;$F[4]="https://oxalis.br.fgov.be/images/".$F[4].$F[5].".jpg";print(join("\t",@F[0..4]))' > x
echo -n '' > y
sort -u x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > BR-illustrations-color.tsv
sort -u x | paste - y >> BR-illustrations-color.tsv ### 178 records
mkdir -p original-images/BR-color
cd original-images/BR-color
tail -n +2 ../../BR-illustrations-color.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### grayscale: https://www.botanicalcollections.be/#/en/search/specimen?filters=%7B%22__fulltext__%22:%7B%22type%22:%22FULL_TEXT%22,%22searchText%22:null%7D,%22family_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22genus_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22name_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22hasImage_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22true%22,%22count%22:1412162%7D%5D%7D,%22collectionCountryCode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22typeSpecimen_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorName_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorNumber_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22specimenKind_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22DR%22,%22count%22:3918%7D%5D%7D,%22plantDetails_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22VASCULAR_PLANTS%22,%22count%22:1412162%7D%5D%7D,%22barcode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D%7D&sort=%5B%5D
unzip -c herbarium_export_20221123032343.zip herbarium_export_20221123032343.txt | tail -n +2 | awk -F'\t' 'BEGIN{OFS="\t"}{print $9,"BR","BR",$1,$6}' | perl -pe 's!https://www.botanicalcollections.be/specimen/(BR[0-9]+)$!$1\t$1!' | perl -F'\t' -lane '$F[4]=~s!([BR0-9]{3,3})!$1/!g;$F[4]="https://oxalis.br.fgov.be/images/".$F[4].$F[5].".jpg";print(join("\t",@F[0..4]))' > x
echo -n '' > y
sort -u x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > BR-illustrations-gray.tsv
sort -u x | paste - y >> BR-illustrations-gray.tsv ### 3,921 records
mkdir -p original-images/BR-gray
cd original-images/BR-gray
tail -n +2 ../../BR-illustrations-gray.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../



###
### GBIF SPECIMEN IMAGES
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

### BR
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MeiseBG")&&($61=="BR")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 1,381,188 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') BR-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert BR-specimens.bloom.gz

### C
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NHMD")&&(($61=="BC")||($61=="CB")||($61=="DK"))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 61,437 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') C-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert C-specimens.bloom.gz

### E
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="E")&&($61=="E")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 332,983 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') E-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert E-specimens.bloom.gz

### F
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="F")&&($61=="Botany")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 635,879 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') F-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert F-specimens.bloom.gz

### GH
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="GH")&&($61=="GH")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 686,404 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') GH-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert GH-specimens.bloom.gz

### K
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="K")&&($61=="K")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 76,033 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') K-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert K-specimens.bloom.gz

### MA
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MA")&&($61=="MA")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 305,022 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') MA-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert MA-specimens.bloom.gz

### MICH
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MICH")&&(($61=="Angiosperms")||($61=="Gymnosperms")||($61=="Pteridophytes"))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 426,799 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') MICH-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert MICH-specimens.bloom.gz

### MO
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MO")&&($61=="MO")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 476,015 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') MO-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert MO-specimens.bloom.gz

### MPU
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="UM")&&($61=="MPU")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 829,857 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') MPU-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert MPU-specimens.bloom.gz

### NY
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NY")&&($61=="NY")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 2,727,071 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') NY-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert NY-specimens.bloom.gz

### O
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="O")&&($61=="V")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 680,594 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') O-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert O-specimens.bloom.gz

### P
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MNHN")&&($61=="P")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 5,670,710 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') P-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert P-specimens.bloom.gz

### US
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="US")&&($61=="US")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 3,563,533 records
bloom -gz create -p 0.0000001 -n $(wc -l s | awk '{print $1}') US-specimens.bloom.gz
awk -F'\t' '{print $1}' s | bloom -gz insert US-specimens.bloom.gz



###
### NON-GBIF SPECIMEN IMAGES
###

### L (2022 NOVEMBER 22)
wget https://api.biodiversitydata.nl/v2/multimedia/download/?_querySpec=%7B%22conditions%22%3A%5B%7B%22field%22%3A%22identifications.defaultClassification.genus%22%2C%22operator%22%3A%22EQUALS%22%2C%22value%22%3A%22Sphagnum%22%7D%2C%7B%22field%22%3A%22collectionType%22%2C%22operator%22%3A%22EQUALS%22%2C%22value%22%3A%22Botany%22%7D%2C%7B%22field%22%3A%22license%22%2C%22operator%22%3A%22STARTS_WITH%22%2C%22value%22%3A%22CC%22%7D%5D%7D ### 4,597,324 records in count query, but 4,592,653 in download; https://api.biodiversitydata.nl/scratchpad/; {"conditions":[{"field":"collectionType","operator":"EQUALS","value":"Botany"},{"field":"license","operator":"STARTS_WITH","value":"CC"}]}
xz -9 download.ndjson
xz -cdk download.ndjson.xz | jq -r '[.sourceSystemId, .identifications[0].scientificName.fullScientificName, .serviceAccessPoints[0].accessUri, .identifications[0].defaultClassification.className] | @tsv' | grep -v -e '^113251_668217503' -e '^balgooy_0328733528' | perl -pe 's/^AMD\.{0,1}/AMD\tAMD./;s/^L\.{0,1}/L\tL./;s/^U\.{0,1}/U\tU./;s/^WAG\.{0,1}/WAG\tWAG./i' | awk -F'\t' -v seed=$(echo -n 'random number seed for L specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($5=="Lycopsida")||($5=="Magnoliopsidae")||($5=="Pinopsida")||($5=="Pteropsida")){print int(rand()*10000000),$2,"L",$1,$3,$4}}' > L-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 4,409,328 records



###
### UNMOUNTED AND OCCLUDED SPECIMEN IMAGES
###

### BR
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MeiseBG")&&($61=="BR")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 1,381,188 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check BR-specimens.bloom.gz > m ### gbifID, identifier; 2,765,564 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for BR specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="MeiseBG")&&($3=="BR")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > BR-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 2,765,558 records

awk -F'\t' '{print $2}' BR-specimens.tsv | sort | uniq -d > d ### 1,381,188 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') BR-multi-specimens.bloom.gz
cat d | bloom -gz insert BR-multi-specimens.bloom.gz
sort -n BR-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check BR-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 200,550 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > BR-multi-specimens.tsv
paste e x >> BR-multi-specimens.tsv ### 200,550 records
mkdir -p original-images/BR-multi
cd original-images/BR-multi
tail -n +2 ../../BR-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../BR-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### text: https://www.botanicalcollections.be/#/en/search/specimen?filters=%7B%22__fulltext__%22:%7B%22type%22:%22FULL_TEXT%22,%22searchText%22:null%7D,%22family_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22genus_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22name_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22hasImage_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22true%22,%22count%22:1412162%7D%5D%7D,%22collectionCountryCode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22typeSpecimen_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorName_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorNumber_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22specimenKind_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22DE%22,%22count%22:155%7D%5D%7D,%22plantDetails_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22VASCULAR_PLANTS%22,%22count%22:1412162%7D%5D%7D,%22barcode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D%7D&sort=%5B%5D
unzip -c herbarium_export_20221123034026.zip herbarium_export_20221123034026.txt | tail -n +2 | awk -F'\t' 'BEGIN{OFS="\t"}{print $9,"BR","BR",$1,$6}' | perl -pe 's!https://www.botanicalcollections.be/specimen/(BR[0-9]+)$!$1\t$1!' | perl -F'\t' -lane '$F[4]=~s!([BR0-9]{3,3})!$1/!g;$F[4]="https://oxalis.br.fgov.be/images/".$F[4].$F[5].".jpg";print(join("\t",@F[0..4]))' > x
echo -n '' > y
sort -u x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > BR-text.tsv
sort -u x | paste - y >> BR-text.tsv ### 159 records
mkdir -p original-images/BR-labels
cd original-images/BR-labels
tail -n +2 ../../BR-text.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### C
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NHMD")&&(($61=="BC")||($61=="CB")||($61=="DK"))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 61,437 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check C-specimens.bloom.gz > m ### gbifID, identifier; 61,933 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for C specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="NHMD")&&(($3=="BC")||($3=="CB")||($3=="DK"))){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > C-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 61,933 records
awk -F'\t' '{print $2}' C-specimens.tsv | sort | uniq -d > d ### 495 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') C-multi-specimens.bloom.gz
cat d | bloom -gz insert C-multi-specimens.bloom.gz
sort -n C-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check C-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 311 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > C-multi-specimens.tsv
paste e x >> C-multi-specimens.tsv ### 311 records
mkdir -p original-images/C-multi
cd original-images/C-multi
tail -n +2 ../../C-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../C-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### E
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="E")&&($61=="E")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 332,983 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check E-specimens.bloom.gz > m ### gbifID, identifier; 673,106 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for E specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="E")&&($3=="E")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > E-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 673,098 records
awk -F'\t' '{print $2}' E-specimens.tsv | sort | uniq -d > d ### 332,118 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') E-multi-specimens.bloom.gz
cat d | bloom -gz insert E-multi-specimens.bloom.gz
sort -n E-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check E-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 168,148 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > E-multi-specimens.tsv
paste e x >> E-multi-specimens.tsv ### 168,148 records
mkdir -p original-images/E-multi
cd original-images/E-multi
tail -n +2 ../../E-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../E-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
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
sort -n F-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check F-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 206,889 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > F-multi-specimens.tsv
paste e x >> F-multi-specimens.tsv ### 206,889 records
mkdir -p original-images/F-multi
cd original-images/F-multi
tail -n +2 ../../F-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../F-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### GH
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="GH")&&($61=="GH")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 686,404 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check GH-specimens.bloom.gz > m ### gbifID, identifier; 686,415 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for GH specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="GH")&&($3=="GH")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > GH-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 686,412 records
awk -F'\t' '{print $2}' GH-specimens.tsv | sort | uniq -d > d ###  records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') GH-multi-specimens.bloom.gz
cat d | bloom -gz insert GH-multi-specimens.bloom.gz
sort -n GH-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check GH-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 2,345 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > GH-multi-specimens.tsv
paste e x >> GH-multi-specimens.tsv ### 2,345 records
mkdir -p original-images/GH-multi
cd original-images/GH-multi
tail -n +2 ../../GH-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../GH-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
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
sort -n K-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check K-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 34 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > K-multi-specimens.tsv
paste e x >> K-multi-specimens.tsv ### 34 records, all blank images
mkdir -p original-images/K-multi
cd original-images/K-multi
tail -n +2 ../../K-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../K-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: bark sample: 126 records
echo '' > L-bark.txt
for k in {0..120..10}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Bark+sample&logicalOperator=AND&from='$k'&size=10' | grep -h -Po "(?<=href=')[^']*" >> L-bark.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-bark.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-bark-specimens.bloom.gz
cat x | bloom -gz insert L-bark-specimens.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-bark-specimens.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-bark-specimens.tsv
mkdir -p L/bark
cd L/bark
tail -n +2 ../../L-bark-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: carp: 13,448 records
echo '' > L-carp.txt
for k in {0..13400..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Carpologica&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-carp.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-carp.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./i;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-carp-specimens.bloom.gz
cat x | bloom -gz insert L-carp-specimens.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-carp-specimens.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-carp-specimens.tsv
mkdir -p L/carp
cd L/carp
tail -n +2 ../../L-carp-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: illustration: 239 records
echo '' > L-illustration.txt
for k in {0..200..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Illustration,+drawings&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-illustration.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-illustration.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-illustrations.bloom.gz
cat x | bloom -gz insert L-illustrations.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-illustrations.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-illustrations.tsv
mkdir -p L/illustrations
cd L/illustrations
tail -n +2 ../../L-illustrations.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: microscope slides: 90,760 anatomy records; 20,182 morphology records; 36,636 pollen records
echo '' > L-slides.txt
for k in {0..90700..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Microscopic+slide:+Anatomy&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-slides.txt
done
for k in {0..20100..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Microscopic+slide:+Morphology&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-slides.txt
done
for k in {0..36600..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Microscopic+slide:+Pollen&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-slides.txt
done
wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Slides&logicalOperator=AND&from=0&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-slides.txt
grep 'https://bioportal\.naturalis\.nl/specimen/' L-slides.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./i;s/^U\.{0,1}/U./i;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-slides.bloom.gz
cat x | bloom -gz insert L-slides.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-slides.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-slides.tsv
mkdir -p L/slides
cd L/slides
tail -n +2 ../../L-slides.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../
./dhash.py -i L/slides/ > x
echo '64' $(wc -l x | awk '{print $1-1}') > y
tail -n +2 x | awk -F'\t' 'BEGIN{x=0}{print $2,x;x++}' >> y
hamming y 22 > z
awk '{if($1<=10){print $3}}' z | sort -u > zz ### 71,080 of 83,593 leaving 12,513 that are more than 10/64 (85%) different
bloom -gz create -p 0.0000001 -n $(wc -l zz | awk '{print $1}') zz.bloom.gz
cat zz | bloom -gz insert zz.bloom.gz
cat y | tr ' ' '\t' | bloom -gz -d $'\t' -f 1 -s check zz.bloom.gz | awk -F'\t' '{print $1}' > zzz
tail -n +2 x | awk -F'\t' 'BEGIN{x=0}{print $2}' >> zzz
sort zzz | uniq -c | grep ' 1 ' | awk '{print $2}' > xx
bloom -gz create -p 0.0000001 -n $(wc -l xx | awk '{print $1}') xx.bloom.gz
cat xx | bloom -gz insert xx.bloom.gz
cat x | bloom -gz -d $'\t' -f 1 -s check xx.bloom.gz | awk -F'\t' '{print $1}' | xargs -I {} -P 1 bash -c 'cp L/slides/{} raw-dataset/microscope-slides/L/'

### L: photo: 558 records
echo '' > L-photo.txt
for k in {0..500..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Photographs%2F+negatives&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-photo.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-photo.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-photos.bloom.gz
cat x | bloom -gz insert L-photos.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-photos.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-photos.tsv
mkdir -p L/photo
cd L/photo
tail -n +2 ../../L-photos.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: preserved: 417 records
echo '' > L-preserved.txt
for k in {0..400..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Preserved+Specimen&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-preserved.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-preserved.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-preserved.bloom.gz
cat x | bloom -gz insert L-preserved.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-preserved.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-preserved.tsv
mkdir -p L/preserved
cd L/preserved
tail -n +2 ../../L-preserved.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: reproduction: 280 records
echo '' > L-reproduction.txt
for k in {0..200..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=photo(copy)+of+herbarium+sheet&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-reproduction.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-reproduction.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | grep -v nyIMG_ | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-reproduction.bloom.gz
cat x | bloom -gz insert L-reproduction.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-reproduction.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-reproduction.tsv 
mkdir -p L/reproduction
cd L/reproduction
tail -n +2 ../../L-reproduction.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: rhizome: 59 records
wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Rhizome&logicalOperator=AND&from=0&size=100' | grep -h -Po "(?<=href=')[^']*" > L-rhizome.txt
grep 'https://bioportal\.naturalis\.nl/specimen/' L-rhizome.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-rhizome-specimens.bloom.gz
cat x | bloom -gz insert L-rhizome-specimens.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-rhizome-specimens.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-rhizome-specimens.tsv ### 0

### L: seed collection; 381 records
echo '' > L-seed.txt
for k in {0..300..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Seed+collection&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-seed.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-seed.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-seed-specimens.bloom.gz
cat x | bloom -gz insert L-seed-specimens.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-seed-specimens.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-seed-specimens.tsv
mkdir -p L/seed
cd L/seed
tail -n +2 ../../L-seed-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: spirit collection; 27,520 records
echo '' > L-spirit.txt
for k in {0..27500..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Spirit+collection&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-spirit.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-spirit.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./i;s/^U\.{0,1}/U./;s/^WAG\.{0,1}/WAG./i;s/^W-G/WAG./;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-spirit-collections.bloom.gz
cat x | bloom -gz insert L-spirit-collections.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-spirit-collections.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-spirit-collections.tsv
mkdir -p L/spirit
cd L/spirit
tail -n +2 ../../L-spirit-collections.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### L: wood; 98,109 records
echo '' > L-wood.txt
for k in {0..98100..100}; do
   wget -O - 'https://bioportal.naturalis.nl/result/specimen/collectionType=Botany&kindOfUnit[0]=Wood+sample&logicalOperator=AND&from='$k'&size=100' | grep -h -Po "(?<=href=')[^']*" >> L-wood.txt
done
grep 'https://bioportal\.naturalis\.nl/specimen/' L-wood.txt | awk -F/ '{print $5}' | perl -pe 's/^AMD\.{0,1}/AMD./;s/^L\.{0,1}/L./i;s/^U\.{0,1}/U./i;s/^WAG\.{0,1}/WAG./i;s/\++//;' | sort -u > x
bloom -gz create -p 0.0000001 -n $(wc -l x | awk '{print $1}') L-wood-specimens.bloom.gz
cat x | bloom -gz insert L-wood-specimens.bloom.gz
cat L-specimens.tsv | perl -pe 's/_[0-9]+\t/\t/' | bloom -gz -d $'\t' -f 1 -s check L-wood-specimens.bloom.gz | awk -F'\t' 'BEGIN{OFS="\t"}{print $2,$3,$4,$5,$6}' | python3 -c "$XXHASH" > L-wood-specimens.tsv
mkdir -p L/wood
cd L/wood
tail -n +2 ../../L-wood-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### MA
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MA")&&($61=="MA")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 305,022 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check MA-specimens.bloom.gz > m ### gbifID, identifier; 310,948 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for MA specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="MA")&&($3=="MA")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > MA-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 310,944 records
awk -F'\t' '{print $2}' MA-specimens.tsv | sort | uniq -d > d ### 5,829 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') MA-multi-specimens.bloom.gz
cat d | bloom -gz insert MA-multi-specimens.bloom.gz
sort -n MA-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check MA-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 8,114 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > MA-multi-specimens.tsv
paste e x >> MA-multi-specimens.tsv ### 8,115 records
mkdir -p original-images/MA-multi
cd original-images/MA-multi
tail -n +2 ../../MA-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../MA-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### MICH
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MICH")&&(($61=="Angiosperms")||($61=="Gymnosperms")||($61=="Pteridophytes"))){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 426,799 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check MICH-specimens.bloom.gz > m ### gbifID, identifier; 437,103 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for MICH specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="MICH")&&(($3=="Angiosperms")||($3=="Gymnosperms")||($3=="Pteridophytes"))){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > MICH-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 437,100 records
awk -F'\t' '{print $2}' MICH-specimens.tsv | sort | uniq -d > d ### 8,784 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') MICH-multi-specimens.bloom.gz
cat d | bloom -gz insert MICH-multi-specimens.bloom.gz
sort -n MICH-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check MICH-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 15,571 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > MICH-multi-specimens.tsv
paste e x >> MICH-multi-specimens.tsv ### 15,571 records
mkdir -p original-images/MICH-multi
cd original-images/MICH-multi
tail -n +2 ../../MICH-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../MICH-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### MO (BROKEN)
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
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../MO-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P 1 bash -c 'XXH=$(echo "{}" | awk "{print substr(\$1,1,16)}"); URL=$(echo "{}" | awk "{print substr(\$1,17)}"); save-page.sh "$URL" --browser firefox --load-wait-time 13 --save-wait-time 3 --destination "$XXH".jpg'
cd ../../

### MPU
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="UM")&&($61=="MPU")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 829,857 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check MPU-specimens.bloom.gz > m ### gbifID, identifier; 833,522 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for MPU specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="UM")&&($3=="MPU")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > MPU-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 833,519 records
awk -F'\t' '{print $2}' MPU-specimens.tsv | sort | uniq -d > d ### 2,744 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') MPU-multi-specimens.bloom.gz
cat d | bloom -gz insert MPU-multi-specimens.bloom.gz
sort -n MPU-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check MPU-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 6,003 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > MPU-multi-specimens.tsv
paste e x >> MPU-multi-specimens.tsv ### 6,003 records
mkdir -p original-images/MPU-multi
cd original-images/MPU-multi
tail -n +2 ../../MPU-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../MPU-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
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
sort -n NY-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check NY-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 52,999 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > NY-multi-specimens.tsv
paste e x >> NY-multi-specimens.tsv ### 52,999 [initial: 7,374 records; 254 (3.4%) carpological records]
mkdir -p original-images/NY-multi
cd original-images/NY-multi
tail -n +2 ../../NY-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../NY-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### O
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="O")&&($61=="V")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 680,594 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check O-specimens.bloom.gz > m ### gbifID, identifier; 715,835 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for O specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="O")&&($3=="V")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > O-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 715,831 records
awk -F'\t' '{print $2}' O-specimens.tsv | sort | uniq -d > d ### 31,322 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') O-multi-specimens.bloom.gz
cat d | bloom -gz insert O-multi-specimens.bloom.gz
sort -n O-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check O-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 22,494 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > O-multi-specimens.tsv
paste e x >> O-multi-specimens.tsv ### 22,494 records
mkdir -p original-images/O-multi
cd original-images/O-multi
tail -n +2 ../../O-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -O $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../O-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### P
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="MNHN")&&($61=="P")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 5,670,710 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check P-specimens.bloom.gz > m ### gbifID, identifier; 5,753,607 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for P specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="MNHN")&&($3=="P")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > P-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 5,753,603 records
awk -F'\t' '{print $2}' P-specimens.tsv | sort | uniq -d > d ### 53,337 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') P-multi-specimens.bloom.gz
cat d | bloom -gz insert P-multi-specimens.bloom.gz
sort -n P-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check P-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 96,365 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > P-multi-specimens.tsv
paste e x >> P-multi-specimens.tsv ### 96,365 records
mkdir -p original-images/P-multi
cd original-images/P-multi
tail -n +2 ../../P-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../P-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### US
unzip -c $GBIF occurrence.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="US")&&($61=="US")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 3,563,533 records
sort -t$'\t' -k 1b,1 s > t
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | bloom -gz -d $'\t' -f 0 -s check US-specimens.bloom.gz > m ### gbifID, identifier; 3,833,478 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY | awk -F'\t' -v seed=$(echo -n 'random number seed for US specimen images' | xxh32sum | awk '{print "obase=10; ibase=16; " toupper($1)}' | bc) 'BEGIN{OFS="\t"; srand(seed)}{if(($2=="US")&&($3=="US")){print int(rand()*10000000),$1,$2,$3,$4,$5}}' > US-specimens.tsv ### random, occurrenceID, institutionCode, collectionCode, scientificName, url; 3,833,475 records
awk -F'\t' '{print $2}' US-specimens.tsv | sort | uniq -d > d ### 245,977 records
bloom -gz create -p 0.0000001 -n $(wc -l d | awk '{print $1}') US-multi-specimens.bloom.gz
cat d | bloom -gz insert US-multi-specimens.bloom.gz
sort -n US-specimens.tsv | bloom -gz -d $'\t' -f 1 -s check US-multi-specimens.bloom.gz | python3 -c "$SELECTDUP" > e ### 159,124 records
echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > US-multi-specimens.tsv
paste e x >> US-multi-specimens.tsv ### 159,124 records
mkdir -p original-images/US-multi
cd original-images/US-multi
tail -n +2 ../../US-multi-specimens.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
ls *.jpg | perl -pe 's/\.jpg$//' > done
tail -n +2 ../../US-multi-specimens.tsv | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../



###
### BIOCULTURAL SPECIMENS
###

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

#
# cleveland https://github.com/ClevelandMuseumArt/openaccess
#

### Cooper Hewitt (Smithsonian Design Museum; 16 November 2022)
wget -q -O - https://smithsonian-open-access.s3-us-west-2.amazonaws.com/metadata/edan/index.txt | grep '/chndm/' | xargs wget -q -O - | xargs wget -q -O - | xz -9 > CHNDM.json.xz
xz -cdk CHNDM.json.xz | grep -i -v -e 'amber glass' -e appears -e brayon -e cashmere -e crayon -e fire -e 'medium: cotton' -e 'medium: hemp' -e 'medium: linen' -e 'medium: metallic' -e 'medium: silk' -e 'medium: wool' -e pearl -e wash | grep -i -e agave -e aloe -e amber -e ash -e bamboo -e bark -e bean -e beech -e bogwood -e boxwood -e burl -e camphor -e cane -e cedar -e cinnabar -e cork -e cotton -e elm -e entada -e fiber -e fir -e flax -e fruit -e fruitwood -e gutta -e harewood -e hardwood -e hemp -e indigo -e linen -e mahogany -e maple -e mohogany -e mulberry -e muslin -e mustard -e oak -e papyrifera -e pear -e pearwood -e piña -e pine -e pineapple -e raffia -e rayon -e rice -e rosewood -e satinwood -e softwood -e sugar -e sycamore -e tulipwood -e walnut -e wicker -e wood -e yew | grep '"High-resolution JPEG"' | jq 'select(.content.descriptiveNonRepeating.online_media.media[0].usage.access == "CC0") | .content.descriptiveNonRepeating.online_media.media[0]' | jq 'try( .resources[] | select(.label == "High-resolution JPEG") | .url ) // ""' | grep -v '""' | tr -d '"' > x ### works correctly?
echo -n '' > y
cat x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'url\txxh64' > CHNDM.tsv
paste x y >> CHNDM.tsv ### 23,390 records (23,249 unique)
mkdir -p original-images/CHNDM
cd original-images/CHNDM
tail -n +2 ../../CHNDM.tsv | awk -F'\t' '{print $2$1}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../
find original-images/CHNDM -type f -name '*.jpg' | awk -F/ '{print $NF}' | perl -pe 's/\.jpg$//' > p
grep -f p CHNDM.tsv | awk -F'\t' '{print $1}' | awk -F= '{print $NF}' > q
xz -cdk CHNDM.json.xz | grep -f q | jq 'try ( .content.freetext.physicalDescription[] | select(.label == "Medium") | .content ) // "" ' > r
xz -cdk CHNDM.json.xz | grep -f q | jq 'try( .content.descriptiveNonRepeating.online_media.media[0].resources[] | select(.label == "High-resolution JPEG") | .url ) // ""' | paste - r > CHNDM-meta.tsv

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
../../resizeImage.py -d ECON-original -e ECON -q 94 -p -s 4096
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

### Met (Metropolitan Museum of Art; 15-16 November 2022)
wget https://github.com/metmuseum/openaccess/raw/master/MetObjects.csv
xz -9 MetObjects.csv
xz -cdk MetObjects.csv.xz | perl -CS -MText::CSV -le "$CSV2TSV" | awk -F'\t' 'BEGIN{OFS="\t"}{if(($4=="True")&&(($46~/Amber/)||($46~/Bamboo/)||($46~/Bark/)||($46~/Basketry/)||($46~/Gourd/)||($46~/Paper/)||($46~/Papyrus/)||($46~/Tobacco/)||($46~/Wood/))){print $1,$9,$46,$48}}' | grep -v -e 'Cut Paper' -e 'Paper-' -e 'Pastels & Oil Sketches on Paper' -e 'Works on Paper' > x
echo -n '' > y
cat x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'Object Number\tObject Name\tClassification\tLink Resource\txxh64' > Met.tsv
paste x y >> Met.tsv ### 3,019 records
mkdir Met
cd Met
tail -n +2 ../Met.tsv | awk -F'\t' '{print $5$4}' | xargs -I {} -P 1 bash -c 'XXH=$(echo "{}" | awk "{print substr(\$1,1,16)}"); URL=$(echo "{}" | awk "{print substr(\$1,17)}"); save-page.sh "$URL" --browser google-chrome --load-wait-time 13 --save-wait-time 13 --destination Met-"$XXH"'
tail -n +2 ../Met.tsv | awk -F'\t' '{print $5$4}' | xargs -I {} -P 1 bash -c 'XXH=$(echo "{}" | awk "{print substr(\$1,1,16)}"); URL=$(echo "{}" | awk "{print substr(\$1,17)}"); save-page.sh "$URL" --browser firefox --load-wait-time 13 --save-wait-time 3 --destination Met-"$XXH"' ### produces different results... wtf?
cd ../
tail -n +2 Met.tsv | awk -F'\t' 'BEGIN{OFS="\t"}{print $5,$1,$2,$3,$4}' | sort -t$'\t' -k 1b,1 > o
find Met/ -type f -name 'Met-*' | xargs grep -Po '(?<=href=")[^"]*' | grep '.jpg$' | sort -u | perl -pe 's*^Met/Met-**;s/:/\t/;s/\.html\t/\t/' | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2}' | sort -u-t$'\t' -k 1b,1 > m ### 16,845 records
echo -n '' > x
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY o m | cut -d$'\t' -f2- | grep -v EMPTY | sort -u > y ### 12,789 records
cat y | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'Object Number\tObject Name\tClassification\trecord url\timage url\txxh64' > Met-objects.tsv
paste y x >> Met-objects.tsv ### 12,789 records
mkdir -p original-images/Met
cd original-images/Met
tail -n +2 ../../Met-objects.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

### MO also has collections, but difficult to individually extract
# MO (also) http://www.mobot.org/plantscience/resbot/Econ/EconBot01.htm

### NY
unzip -c $GBIF occurrence.txt | grep -e Balick -e Vandebroek | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($68)&&length($60)&&length($61)&&length($189)&&($60=="NY")&&($61=="NY")){print $1,$68,$60,$61,$189}}' > s ### gbifID, occurrenceID, institutionCode, collectionCode, scientificName; 1,926 records
sort -t$'\t' -k 1b,1 s > t
awk -F'\t' '{print $1}' t > f
unzip -c $GBIF multimedia.txt | tail +4 | awk -F'\t' 'BEGIN{OFS="\t"}{if(length($1)&&length($4)){print $1,$4}}' | grep -f f > m ### gbifID, identifier; 3,031 records
sort -t$'\t' -k 1b,1 m > n
join -a 2 -1 1 -2 1 -t$'\t' -e EMPTY t n | cut -d$'\t' -f2- | grep -v EMPTY > e ### occurrenceID, institutionCode, collectionCode, scientificName, url; 3,031 records

echo -n '' > x
cat e | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> x
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > NY-EBC.tsv
paste e x >> NY-EBC.tsv ### 3,031 records
mkdir -p original-images/NY-ebc
cd original-images/NY-ebc
tail -n +2 ../../NY-EBC.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../

# amnh?
# * https://library.artstor.org
#    * Cornell? https://emuseum.cornell.edu
# * https://researcharchive.calacademy.org/research/anthropology/collections/index.asp
# * https://www.botanicgardens.org/our-collections/kathryn-kalmbach-herbarium-vascular-plants
# * https://www.soroherbaria.org/portal/collections/misc/collprofiles.php?collid=113
# * https://harvardlibrarybulletin.org/introducing-plant-humanities-lab
# * https://vplants.org/portal/collections/misc/collprofiles.php
# * https://www.fortlewis.edu/academics/schools-departments/departments/biology-department/herbarium
# * https://vplants.org/portal/collections/index.php
# * https://www.nms.ac.uk/explore-our-collections/search-our-collections/
# * http://argus.musnaz.org/ArgusNET/Portal/Default.aspx?lang=en-US
# * https://www.herbariumcurators.org/unam
#
# darwin cores
#



###
### ALL SPECIMENS
###

printf "%s\n" "${HERBARIA[@]}" | xargs -I {} -P $(nproc) bash -c "cat {}-specimens.tsv | python3 -c '$XXHASH' > {}-specimens-xx.tsv"  ### python is much faster, but produces different hashes than bash, so everything has to be downloaded again
for HERBARIUM in "${HERBARIA[@]}"; do
   mkdir -p 'original-images/'$HERBARIUM
done
grep -v occurrenceID *-specimens-xx.tsv | perl -pe 's/-specimens-xx\.tsv:/\t/' | awk -F'\t' 'BEGIN{OFS="\t"}{print $8,$1,$7}' > x ### 25,718,337 records ca. 152.9TB (*-multi has 891,143 files at 5.3T => 0.000005947TB/file)

sort x | head -n 1000 | awk -F'\t' '{print $2}' | sort | uniq -c | sort -n
#    2 C
#    2 K
#   15 MA
#   17 MICH
#   27 MPU
#   27 O
#   30 E
#   31 GH
#   31 MO
#   53 F
#   92 NY
#  101 BR
#  143 US
#  184 L
#  229 P
mkdir -p test-quality
cd test-quality
sort ../x | head -n 1000 | awk -F'\t' '{print $1$3}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD" ### 884 downloaded
cd ../

mkdir -p test-quality-100
../resizeImage.py -d test-quality -e test-quality-100 -q 100 -p -s 1024
echo -e 'quality\tfile\tRMSE' > test-quality.tsv
QUALITIES=( 98 96 94 92 90 88 86 84 82 80 78 76 74 72 70 )
for QUALITY in "${QUALITIES[@]}"; do ### based on https://github.com/rflynn/imgmin
   DIR='test-quality-'$QUALITY
   mkdir -p $DIR
   ../resizeImage.py -d test-quality -e $DIR -q $QUALITY -p -s 1024
   find $DIR -type f -name '*.jpg' | awk -F/ '{print $NF}' | perl -pe 's/\.jpg$//' | xargs -I {} -P $(nproc) bash -c 'echo -e "'$QUALITY'\t{}\t$(compare -metric RMSE test-quality-100/{}.jpg '$DIR'/{}.jpg null 2>&1 3>&1 | tr -d "()" | awk "{print 100*\$2}")" >> test-quality.tsv'
done

echo -e 'quality\t%RMSE>1' > test-quality-summary.tsv
for QUALITY in "${QUALITIES[@]}"; do
   awk -F'\t' -v QUALITY=$QUALITY 'BEGIN{OFS="\t"}{if($1==QUALITY){i++;if($3>1.0){r++}}}END{print QUALITY,100*(r/i)}' test-quality.tsv >> test-quality-summary.tsv
done
### => use quality 94 (1.8% images need better quality)

# mkdir docker
# cd docker
# echo 'FROM ubuntu:jammy' > Dockerfile
# echo 'RUN apt update -y && apt upgrade -y && apt install python3-opencv -y && apt install wget -y && apt install xxhash -y' >> Dockerfile
# docker build -t 'ubuntu:jammy-opencv' .
# cd ../

printf "%s\n" "${HERBARIA[@]}" | xargs -I {} -P 1 mkdir -p 'resized-images/'{}
sort x > y
# nohup docker run -v "${PWD}:/tmp" -w /tmp ubuntu:jammy-opencv bash -c './x.sh' > nohup.out 2>&1 &
cat y | xargs -I {} -P 32 bash -c "$DOWNLOADRESIZE" ### 25,718,337 records ca. 4.9TB @ q = 94 (test-quality-94 has 885 files at 172M => 0.194350282M/file)
for HERBARIUM in "${HERBARIA[@]}"; do
   cd 'original-images/'$HERBARIUM
   find . -type f -name '*.jpg' -exec jpeginfo -c {} \; | grep -E 'WARNING|ERROR' | awk '{print $1}' | xargs -I {} -P 1 rm {}
   ls *.jpg | perl -pe 's/\.jpg$//' > done
   tail -n +2 '../../'$HERBARIUM'-specimens.tsv' | grep -v -f done | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
   rm done
   cd ../../
done ###  downloaded



###
### AESTHETICALLY PLEASING MOUNTED HERBARIUM SPECIMENS
###
### 374 pleasing specimens from NY Emu (by Leanna McMillin), manually filtered down to 331

### 331 ordinary specimens from NY (maximum of 1 per genus)
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

### deep aesthetics (https://github.com/magcil/deep_photo_aesthetics)
wget https://github.com/magcil/deep_photo_aesthetics/archive/refs/heads/main.zip ### modified predict_local.py, manually downloaded and renamed models to match script expectations
unzip main.zip
cd deep_photo_aesthetics-main/
echo 'FROM pytorch/pytorch:1.9.1-cuda11.1-cudnn8-runtime' > Dockerfile
echo 'RUN python3 -m pip install --upgrade pip && python3 -m pip install --upgrade setuptools && python3 -m pip install --no-deps torchvision==0.10.1 && python3 -m pip install opencv-python==4.5.1.48 && python3 -m pip install numpy==1.21.4 && python3 -m pip install tensorflow==2.0.0 && python3 -m pip install pandas==1.3.5 && python3 -m pip install matplotlib==3.1.1 && python3 -m pip install Pillow==8.3.2 && python3 -m pip install googledrivedownloader==0.4' >> Dockerfile
docker build -t 'pytorch:1.9.1-aesthetics' .
find . -type f -name '*.jpg' | perl -pe 's*./**' | awk 'BEGIN{print "#!/bin/bash"}{ print "python3 predict_local.py -i " $1 " >> aesthetics.tsv"}' > x.sh
echo 'file,color0,color1,composition0,composition1,composition2,composition3,composition4,composition5,composition6,composition7,composition8,composition9,dof0,dof1,palette0,palette1,palette2,palette3,palette4,palette5,palette6,palette7,palette8,palette9,palette10,palette11,palette12,type0,type1,type2,type3,type4,type5,type6,type7,type8,type9,type10,type11,type12,type13,type14,type15,type16,type17,type18,type19,type20' | tr ',' '\t' > aesthetics.tsv
chmod +x x.sh
docker run -u $(id -u):$(id -g) -m 32g --rm -it -v "${PWD}:/tmp" -w /tmp 'pytorch:1.9.1-aesthetics'
./x.sh
exit
cd ../
head -n 1 deep_photo_aesthetics-main/aesthetics.tsv | perl -pe 's/file/class\tfile/' > aesthetic-scores.tsv
tail -n +2 deep_photo_aesthetics-main/aesthetics.tsv | perl -pe 's/NY-pleasing/pleasing\tNY-pleasing/;s/NY-ordinary/ordinary\tNY-ordinary/' >> aesthetic-scores.tsv
R CMD BATCH aesthetics.r ### ca. 10% error with sigmoid svm of all deep aesthetics output

### mass selection
docker run --runtime=nvidia -u $(id -u):$(id -g) -m 32g --rm -it -v "${PWD}:/tmp" -v "$HOME:/media" -w /tmp 'pytorch:1.9.1-aesthetics'
./predict.py -i /media/resized-images-calocedrus > all-specimen-aesthetics.tsv
exit
R CMD BATCH aesthetics.r ### ca. 4% of specimens are attractive

tail -n +2 all-specimen-aesthetics.tsv | awk -F'\t' '{print $1}' | awk -F/ '{print $4}' | sort | uniq -c | awk 'BEGIN{OFS="\t"}{print $2,$1}' | sort | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2}' > x
tail -n +2 all-specimen-aesthetic.txt | awk -F/ '{print $4}' | sort | uniq -c | awk 'BEGIN{OFS="\t"}{print $2,$1}' | sort | awk -F'\t' '{print $2}' | paste x - > y
awk -F'\t' 'BEGIN{OFS="\t"; print "institution","specimens","pleasing","%pleasing"}{print $1,$2,$3,sprintf("%.2f",100*($3/$2))}' y > all-specimen-aesthetics-stats.tsv

awk -F'\t' '{if($3<2500){print "/"$1"/"}}' all-specimen-aesthetics-stats.tsv > x
grep -f x all-specimen-aesthetic.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"raw-dataset/aesthetically-pleasing-pressed-specimens/"$3"/"$4}' | bash
tail -n +2 all-specimen-aesthetic.txt | grep -v -f x | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ 'BEGIN{F=0; L=0; MAX=3000; NY=0}{X=0; if($3=="F"&&F<MAX){X=1;F++}else if($3=="L"&&L<MAX){X=1;L++}else if($3=="NY"&&NY<MAX){X=1;NY++}; if(X==1){print "cp ",$0,"raw-dataset/aesthetically-pleasing-pressed-specimens/"$3"/"$4}}' | bash



###
### LIVE PLANT IMAGES
###
### from NY Emu a maximum of 15 images per genus (by Leanna McMillin), not used because of copyright concerns
### manually separated from other institutional downloads (see below)

### BR
### color: https://www.botanicalcollections.be/#/en/search/specimen?filters=%7B%22__fulltext__%22:%7B%22type%22:%22FULL_TEXT%22,%22searchText%22:null%7D,%22family_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22genus_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22name_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22hasImage_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22true%22,%22count%22:1412162%7D%5D%7D,%22collectionCountryCode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22typeSpecimen_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorName_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorNumber_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22specimenKind_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22PC%22,%22count%22:849%7D%5D%7D,%22plantDetails_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22VASCULAR_PLANTS%22,%22count%22:1412162%7D%5D%7D,%22barcode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D%7D&sort=%5B%5D
unzip -c herbarium_export_20221123032913.zip herbarium_export_20221123032913.txt | tail -n +2 | awk -F'\t' 'BEGIN{OFS="\t"}{print $9,"BR","BR",$1,$6}' | perl -pe 's!https://www.botanicalcollections.be/specimen/(BR[0-9]+)$!$1\t$1!' | perl -F'\t' -lane '$F[4]=~s!([BR0-9]{3,3})!$1/!g;$F[4]="https://oxalis.br.fgov.be/images/".$F[4].$F[5].".jpg";print(join("\t",@F[0..4]))' > x

### grayscale: https://www.botanicalcollections.be/#/en/search/specimen?filters=%7B%22__fulltext__%22:%7B%22type%22:%22FULL_TEXT%22,%22searchText%22:null%7D,%22family_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22genus_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22name_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22hasImage_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22true%22,%22count%22:849%7D%5D%7D,%22collectionCountryCode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22typeSpecimen_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorName_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorNumber_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22specimenKind_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22PB%22,%22count%22:742%7D%5D%7D,%22plantDetails_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22VASCULAR_PLANTS%22,%22count%22:849%7D%5D%7D,%22barcode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D%7D&sort=%5B%5D
unzip -c herbarium_export_20221123033141.zip herbarium_export_20221123033141.txt | tail -n +2 | awk -F'\t' 'BEGIN{OFS="\t"}{print $9,"BR","BR",$1,$6}' | perl -pe 's!https://www.botanicalcollections.be/specimen/(BR[0-9]+)$!$1\t$1!' | perl -F'\t' -lane '$F[4]=~s!([BR0-9]{3,3})!$1/!g;$F[4]="https://oxalis.br.fgov.be/images/".$F[4].$F[5].".jpg";print(join("\t",@F[0..4]))' >> x

### other: https://www.botanicalcollections.be/#/en/search/specimen?filters=%7B%22__fulltext__%22:%7B%22type%22:%22FULL_TEXT%22,%22searchText%22:null%7D,%22family_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22genus_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22name_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22hasImage_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22true%22,%22count%22:1412162%7D%5D%7D,%22collectionCountryCode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22typeSpecimen_b%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorName_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22collectorNumber_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D,%22specimenKind_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22P%22,%22count%22:62%7D%5D%7D,%22plantDetails_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%7B%22key%22:%22VASCULAR_PLANTS%22,%22count%22:1412162%7D%5D%7D,%22barcode_s%22:%7B%22type%22:%22STRING_FACET%22,%22values%22:%5B%5D%7D%7D&sort=%5B%5D
unzip -c herbarium_export_20221123033521.zip herbarium_export_20221123033521.txt | tail -n +2 | awk -F'\t' 'BEGIN{OFS="\t"}{print $9,"BR","BR",$1,$6}' | perl -pe 's!https://www.botanicalcollections.be/specimen/(BR[0-9]+)$!$1\t$1!' | perl -F'\t' -lane '$F[4]=~s!([BR0-9]{3,3})!$1/!g;$F[4]="https://oxalis.br.fgov.be/images/".$F[4].$F[5].".jpg";print(join("\t",@F[0..4]))' >> x

echo -n '' > y
sort -u x | while read -r line; do
   echo -n "$line" | xxh64sum | awk '{print $1}' >> y
done
echo -e 'occurrenceID\tinstitutionCode\tcollectionCode\tscientificName\turl\txxh64' > BR-live.tsv
sort -u x | paste - y >> BR-live.tsv ### 1,659 records
mkdir -p original-images/BR-live
cd original-images/BR-live
tail -n +2 ../../BR-live.tsv | awk -F'\t' '{print $6$5}' | xargs -I {} -P $(nproc) bash -c "$DOWNLOAD"
cd ../../



###
### SPECIMENS FROM FEATURE VECTORS (PART 0)
###

cd featureVector
docker build -t 'tensorflow:2.9.3-gpu-features' .
cd ../
docker run --runtime=nvidia --rm -it -u $(id -u):$(id -g) -w /tmp -v ${PWD}:/tmp -v ${HOME}:/media tensorflow:2.9.3-gpu-features

./featureVectorTest.py > all-models.tsv ### EfficientnetV2B0+Imagenet21k -or- MobileNetV3+iNaturalist+Imagenet21k

./featureVectors.py -g 0 -i raw-dataset/fragmentary-pressed-specimens -l fragmentary -m EfficientnetV2B0+Imagenet21k -o vector-fragmentary.tsv -p 1024 ### 632 images total

./featureVectors.py -g 0 -i raw-dataset/illustrations-color/BR -l color -m EfficientnetV2B0+Imagenet21k -o vector-color.tsv -p 256 ### 216: 273 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-color/E -l color -m EfficientnetV2B0+Imagenet21k -o vector-color.tsv -p 256 ### 1: 273 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-color/F -l color -m EfficientnetV2B0+Imagenet21k -o vector-color.tsv -p 256 ### 48: 273 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-color/MPU -l color -m EfficientnetV2B0+Imagenet21k -o vector-color.tsv -p 256 ### 3: 273 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-color/NY -l color -m EfficientnetV2B0+Imagenet21k -o vector-color.tsv -p 256 ### 2: 273 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-color/P -l color -m EfficientnetV2B0+Imagenet21k -o vector-color.tsv -p 256 ### 3: 273 images total

./featureVectors.py -g 0 -i raw-dataset/illustrations-gray/BR -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 3286: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/E -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 23: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/F -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 247: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/L -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 46: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/MA -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 2: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/MO -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 51: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/MPU -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 25: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/NY -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 26: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/P -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 140: 3848 images total
./featureVectors.py -a -g 0 -i raw-dataset/illustrations-gray/US -l gray -m EfficientnetV2B0+Imagenet21k -o vector-gray.tsv -p 256 ### 2: 3848 images total

./featureVectors.py -g 0 -i raw-dataset/live-plants/BR -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 963: 9597 images total
./featureVectors.py -a -g 0 -i raw-dataset/live-plants/L -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 10: 9597 images total
./featureVectors.py -a -g 0 -i raw-dataset/live-plants/MA -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 1: 9597 images total
./featureVectors.py -a -g 0 -i raw-dataset/live-plants/MICH -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 1: 9597 images total
./featureVectors.py -a -g 0 -i raw-dataset/live-plants/MPU -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 2: 9597 images total
./featureVectors.py -a -g 0 -i raw-dataset/live-plants/NY -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 15: 9597 images total
./featureVectors.py -a -g 0 -i raw-dataset/live-plants/O -l live -m EfficientnetV2B0+Imagenet21k -o vector-live.tsv -p 512 ### 3: 9597 images total

./featureVectors.py -g 0 -i raw-dataset/micrographs/E -l micrograph -m EfficientnetV2B0+Imagenet21k -o vector-micrograph.tsv -p 256 ### 15: 10310 images total
./featureVectors.py -a -g 0 -i raw-dataset/micrographs/F -l micrograph -m EfficientnetV2B0+Imagenet21k -o vector-micrograph.tsv -p 256 ### 425: 10310 images total
./featureVectors.py -a -g 0 -i raw-dataset/micrographs/MPU -l micrograph -m EfficientnetV2B0+Imagenet21k -o vector-micrograph.tsv -p 256 ### 3: 10310 images total
./featureVectors.py -a -g 0 -i raw-dataset/micrographs/NY -l micrograph -m EfficientnetV2B0+Imagenet21k -o vector-micrograph.tsv -p 256 ### 5: 10310 images total
./featureVectors.py -a -g 0 -i raw-dataset/micrographs/P -l micrograph -m EfficientnetV2B0+Imagenet21k -o vector-micrograph.tsv -p 256 ### 1320: 10310 images total
./featureVectors.py -a -g 0 -i raw-dataset/micrographs/US -l micrograph -m EfficientnetV2B0+Imagenet21k -o vector-micrograph.tsv -p 256 ### 8533: 10310 images total

./featureVectors.py -g 0 -i raw-dataset/microscope-slides -l slide -m EfficientnetV2B0+Imagenet21k -o vector-slide.tsv -p 512 ### 12456 images total

./featureVectors.py -g 0 -i raw-dataset/mixed-pressed-specimens/BR -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 66: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/C -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 1: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/E -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 1065: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/F -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 16: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/GH -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 17: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/L -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 4: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/MA -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 3: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/MICH -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 93: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/MO -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 2: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/MPU -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 20: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/NY -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 1229: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/O -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 85: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/P -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 271: 12456 images total
./featureVectors.py -a -g 0 -i raw-dataset/mixed-pressed-specimens/US -l mixed -m EfficientnetV2B0+Imagenet21k -o vector-mixed.tsv -p 128 ### 394: 12456 images total

./featureVectors.py -g 0 -i raw-dataset/occluded-specimens/BR -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 25: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/F -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 29: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/GH -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 25: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/L -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 323: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/MA -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 1: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/MICH -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 395: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/MO -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 1: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/NY -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 842: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/O -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 11: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/P -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 8: 1664 images total
./featureVectors.py -a -g 0 -i raw-dataset/occluded-specimens/US -l occluded -m EfficientnetV2B0+Imagenet21k -o vector-occluded.tsv -p 256 ### 4: 1664 images total

./featureVectors.py -g 0 -i raw-dataset/ordinary-pressed-specimens/BR -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 766: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/C -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 7: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/E -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 118: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/F -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 150: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/GH -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 10: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/L -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 668: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/MA -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 60: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/MICH -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 28: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/MO -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 20: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/MPU -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 463: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/NY -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 779: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/O -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 158: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/P -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 536: 4577 images total
./featureVectors.py -a -g 0 -i raw-dataset/ordinary-pressed-specimens/US -l ordinary -m EfficientnetV2B0+Imagenet21k -o vector-ordinary.tsv -p 128 ### 814: 4577 images total

./featureVectors.py -g 0 -i raw-dataset/pressed-specimen-reproductions/BR -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 603: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/E -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 146: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/F -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 8235: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/GH -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 1: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/L -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 75: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/MA -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 2: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/MICH -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 12: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/MO -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 4: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/MPU -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 11: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/NY -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 9: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/O -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 1: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/P -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 9: 9114 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimen-reproductions/US -l reproduction -m EfficientnetV2B0+Imagenet21k -o vector-reproduction.tsv -p 256 ### 5: 9114 images total

./featureVectors.py -g 0 -i raw-dataset/pressed-specimens-closeup/BR -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 202: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/E -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 145: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/F -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 1684: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/L -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 2: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/MA -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 1: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/MICH -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 331: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/MO -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 99: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/MPU -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 5: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/NY -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 244: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/O -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 20: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/P -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 435: 3169 images total
./featureVectors.py -a -g 0 -i raw-dataset/pressed-specimens-closeup/US -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup.tsv -p 128 ### 1: 3169 images total

./featureVectors.py -g 0 -i raw-dataset/spirit-preserved-specimens -l spirit -m EfficientnetV2B0+Imagenet21k -o vector-spirit.tsv -p 1024 ### 656 images total

./featureVectors.py -g 0 -i raw-dataset/text-focused/BR -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 113: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/E -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 48: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/F -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 5: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/GH -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 1: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/K -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 1: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/L -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 1: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/MA -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 13: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/MICH -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 148: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/MO -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 536: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/MPU -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 477: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/NY -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 957: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/O -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 1730: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/P -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 532: 6203 images total
./featureVectors.py -a -g 0 -i raw-dataset/text-focused/US -l text -m EfficientnetV2B0+Imagenet21k -o vector-text.tsv -p 128 ### 1637: 6203 images total

./featureVectors.py -g 0 -i raw-dataset/unpressed-specimens/BR -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 1: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/C -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 41: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/E -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 2: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/F -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 1397: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/K -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 389: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/L -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 98: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/MICH -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 1: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/MO -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 56: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/NY -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 981: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/P -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 12: 2980 images total
./featureVectors.py -a -g 0 -i raw-dataset/unpressed-specimens/US -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed.tsv -p 256 ### 2: 2980 images total

./featureVectors.py -g 0 -i raw-dataset/xylogical-specimens -l xylogical -m EfficientnetV2B0+Imagenet21k -o vector-xylogical.tsv -p 256 ### 202 images total

./featureVectors.py -g 0 -i /media/resized-images-calocedrus -l unknown -m EfficientnetV2B0+Imagenet21k -o vector-all.tsv -p 600000 ### 560,723 images total
./featureVectors.py -a -g 0 -i /media/resized-images-macPro -l unknown -m EfficientnetV2B0+Imagenet21k -o vector-all.tsv -p 600000 ### 118,547 images total
./featureVectors.py -g 0 -i /media/data/original-images/multi/ -l unknown -m EfficientnetV2B0+Imagenet21k -o vector-multi.tsv -p 700000 ### 647,200 images total [missing ca, 10k images from US due to restart]
exit

R CMD BATCH vector.r
find raw-dataset -type d | perl -pe 's*^raw-dataset/*new-dataset/*' | xargs -I {} -P 1 mkdir -p {}
tail -n +2 vector-closeup.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/pressed-specimens-closeup/"$3"/"$4}' | bash
tail -n +2 vector-fragmentary.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/fragmentary-pressed-specimens/"$3"/"$4}' | bash
tail -n +2 vector-illustration.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/illustrations-gray/"$3"/"$4}' | bash
tail -n +2 vector-live.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/live-plants/"$3"/"$4}' | bash
tail -n +2 vector-micrograph.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{if($3!="US"){print "cp ",$0,"new-dataset/micrographs/"$3"/"$4}}' | bash
tail -n +2 vector-mixed.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/mixed-pressed-specimens/"$3"/"$4}' | bash
tail -n +2 vector-occluded.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/occluded-specimens/"$3"/"$4}' | bash
tail -n +2 vector-reproduction.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/pressed-specimen-reproductions/"$3"/"$4}' | bash
tail -n +2 vector-slide.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{if($3!="L"){print "cp ",$0,"new-dataset/microscope-slides/"$3"/"$4}}' | bash
tail -n +2 vector-spirit.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/spirit-preserved-specimens/"$3"/"$4}' | bash
tail -n +2 vector-text.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/text-focused/"$3"/"$4}' | bash
tail -n +2 vector-unpressed.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/unpressed-specimens/"$3"/"$4}' | bash
tail -n +2 vector-xylogical.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"new-dataset/xylogical-specimens/"$3"/"$4}' | bash

R CMD BATCH vector-multi.r
find raw-dataset -type d | perl -pe 's*^raw-dataset/*multi-dataset/*' | xargs -I {} -P 1 mkdir -p {}
tail -n +2 vector-occluded-multi.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/occluded-specimens/"$5"/"$6}' | bash
tail -n +2 vector-occluded-multi.txt > done-files
tail -n +2 vector-text-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/text-focused/"$5"/"$6}' | bash
tail -n +2 vector-text-multi.txt >> done-files
tail -n +2 vector-fragmentary-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/fragmentary-pressed-specimens/"$5"/"$6}' | bash
tail -n +2 vector-fragmentary-multi.txt >> done-files
tail -n +2 vector-unpressed-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/unpressed-specimens/"$5"/"$6}' | bash
tail -n +2 vector-unpressed-multi.txt >> done-files
tail -n +2 vector-mixed-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/mixed-pressed-specimens/"$5"/"$6}' | bash
tail -n +2 vector-mixed-multi.txt >> done-files
tail -n +2 vector-spirit-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/spirit-preserved-specimens/"$5"/"$6}' | bash
tail -n +2 vector-spirit-multi.txt >> done-files
tail -n +2 vector-reproduction-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/pressed-specimen-reproductions/"$5"/"$6}' | bash
tail -n +2 vector-reproduction-multi.txt >> done-files
tail -n +2 vector-closeup-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/pressed-specimens-closeup/"$5"/"$6}' | bash
tail -n +2 vector-closeup-multi.txt >> done-files
tail -n +2 vector-live-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/live-plants/"$5"/"$6}' | bash
tail -n +2 vector-live-multi.txt >> done-files
tail -n +2 vector-micrograph-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{if($3!="US"){print "cp ",$0,"multi-dataset/micrographs/"$5"/"$6}}' | bash
tail -n +2 vector-micrograph-multi.txt >> done-files
tail -n +2 vector-illustration-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/illustrations-gray/"$5"/"$6}' | bash
tail -n +2 vector-illustration-multi.txt >> done-files
tail -n +2 vector-slide-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{if($3!="L"){print "cp ",$0,"multi-dataset/microscope-slides/"$5"/"$6}}' | bash
tail -n +2 vector-slide-multi.txt >> done-files
tail -n +2 vector-xylogical-multi.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/xylogical-specimens/"$5"/"$6}' | bash
tail -n +2 vector-xylogical-multi.txt >> done-files

docker run --runtime=nvidia --rm -it -u $(id -u):$(id -g) -w /tmp -v ${PWD}:/tmp -v ${HOME}:/media tensorflow:2.9.3-gpu-features
./featureVectors.py -g 0 -i raw-dataset/fragmentary-pressed-specimens -l fragmentary -m EfficientnetV2B0+Imagenet21k -o vector-fragmentary-4k.tsv -p 5000 ### 4,139 images total
./featureVectors.py -g 0 -i raw-dataset/pressed-specimens-closeup -l closeup -m EfficientnetV2B0+Imagenet21k -o vector-closeup-3k.tsv -p 4000 ### 3,329 images total
./featureVectors.py -g 0 -i raw-dataset/unpressed-specimens -l unpressed -m EfficientnetV2B0+Imagenet21k -o vector-unpressed-5k.tsv -p 6000 ### 5,637 images total
exit
R CMD BATCH vector-xk.r

tail -n +2 vector-unpressed-5k.txt | awk -F'\t' '{print $2}' | grep -v -f done-files | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"multi-dataset/unpressed-specimens/"$5"/"$6}' | bash
tail -n +2 vector-unpressed-multi.txt >> done-files


### first 50 into ordinary 


### BR-based selector (not very successful)
# cd deep_photo_aesthetics-main/
# docker run --runtime=nvidia -u $(id -u):$(id -g) -m 32g --rm -it -v "${PWD}:/tmp" -v "$HOME:/media" -w /tmp 'pytorch:1.9.1-aesthetics'
# ./predict.py -i /media/Documents/botany/computer-vision/herbariograph/assessor/raw-dataset/live-plants/BR > live-specimens-aesthetics.tsv ### 925 manually selected images mounted on sheets
# exit
# cd ../
# tail -n +2 all-specimen-aesthetics.tsv | awk -F'\t' '{print $1}' | awk -F/ '{print $4}' | sort | uniq -c | awk 'BEGIN{OFS="\t"}{print $2,$1}' | sort | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2}' > x
# tail -n +2 all-specimen-live.txt | awk -F/ '{print $4}' | sort | uniq -c | awk 'BEGIN{OFS="\t"}{print $2,$1}' | sort | awk -F'\t' '{print $2}' | paste x - > y
# awk -F'\t' 'BEGIN{OFS="\t"; print "institution","images","live","%live"}{print $1,$2,$3,sprintf("%.2f",100*($3/$2))}' y > all-specimen-live-stats.tsv
# tail -n +2 all-specimen-live.txt | awk -F'\t' '{print $2}' | perl -pe 's*/media/*~/*' | awk -F/ '{print "cp ",$0,"raw-dataset/live-plants/"$3"/"$4}' | bash









# find multi-dataset/ -type f -name '*.jpg' | xargs -I {} -P 4 bash -c './resizeImage.py -g $(echo {} | perl -pe "s/^multi-dataset/x-dataset/") -f {} -p -q 94 -s 1024'




#
# compress *-specimens.tsv
# remove duplicates:
#  ./dhash.py -i original-images/F-multi/ > x
#  tail -n+2 x | awk -F'\t' '{print $2}' | sort | uniq -d | xargs -I {} -P 1 bash -c 'echo deleting {}; rm original-images/F-multi/$(grep -m 1 {} x | awk -F"\t" "{print \$1}")'
#  ./dhashr.py -i raw-dataset/ > x
#  tail -n+2 x | awk -F'\t' '{print $3}' | sort | uniq -d | xargs -I {} -P 1 bash -c 'FILE=$(grep -m 1 {} x | awk -F"\t" "{print \$1,\$2}" | tr " " "/"); echo deleting $FILE; rm -f $FILE'
# remove similar:
# ./dhash.py -i L/slides/ > x
# echo '64' $(wc -l x | awk '{print $1-1}') > y
# tail -n +2 x | awk -F'\t' 'BEGIN{x=0}{print $2,x;x++}' >> y
# hamming y 22 > z
# awk '{if($1<=10){print $3}}' z | sort -u > zz
# bloom -gz create -p 0.0000001 -n $(wc -l zz | awk '{print $1}') zz.bloom.gz
# cat zz | bloom -gz insert zz.bloom.gz
# cat y | tr ' ' '\t' | bloom -gz -d $'\t' -f 1 -s check zz.bloom.gz | awk -F'\t' '{print $1}' > zzz
# tail -n +2 x | awk -F'\t' 'BEGIN{x=0}{print $2}' >> zzz
# sort zzz | uniq -c | grep ' 1 ' | awk '{print $2}' > xx
# bloom -gz create -p 0.0000001 -n $(wc -l xx | awk '{print $1}') xx.bloom.gz
# cat xx | bloom -gz insert xx.bloom.gz
# cat x | bloom -gz -d $'\t' -f 1 -s check xx.bloom.gz | awk -F'\t' '{print $1}' | xargs -I {} -P 1 bash -c 'cp L/slides/{} raw-dataset/microscope-slides/L/'

# drawings, live, and micrographs
# https://sweetgum.nybg.org/science/vh/media-search/

# remove anything with less than 1024 on shortest side? find raw-dataset/live-plants/ -type f -name '*.jpg' | xargs -I {} -P 4 jpeginfo {} | awk '{print $1,$2,$4}' > z; awk '{if(($2<1000)&&($3<1000)){print $1}}' z | xargs rm
# pretrain on imagenet (without plants etc) for out-of-distribution detection? https://arxiv.org/pdf/2107.08976.pdf
#

#
# class                                      status   next action
# aesthetically-pleasing-pressed-specimens   NDY      first check, extract from multi too?
# animal-specimens                           NDY      download
# biocultural-specimens                      done*    check to remove unpressed
# corrupted-images                           NDY      get from MO backup?
# fragmentary-pressed-specimens              NDY      make better selector
# illustrations-color                        done*    final check
# illustrations-gray                         done*    final check
# live-plants                                NDY      E, MO, P, US done; make new 1k selector from BR
# micrographs                                NDY      make new selector?
# microscope slides                          done*    make new 4k selector for not L
# mixed-pressed-specimens                    NDY      make new 4k selector
# occluded-specimens                         NDY      select more images
# ordinary-pressed-specimens                 NDY      from other classes
# pressed-specimen-reproductions             NDY      select more images
# pressed-specimens-closeup                  NDY      make new 4k selector
# spirit-preserved-specimens                 NDY      select from more NY then make new selector
# text-focused                               NDY      select more images
# unpressed-specimens                        NDY      make new 3k selector
# xylogical-specimens                        NDY      make new selector
#

#
# find raw-dataset/ -type f -name '*.jpg' | awk -F/ '{print $2}' | sort | uniq -c | awk '{print $2,$1}'
# find raw-dataset/ -type f -name '*.jpg' | awk -F/ '{print $2,$3}' | sort | uniq -c | awk 'BEGIN{OFS="\t"; c=""; n=0}{if(NR==1){c=$2}; if(c==$2){n+=$1}else{print "Total",c,n; c=$2; n=$1}; print $3,$2,$1}END{print "Total",c,n}' | datamash crosstab 2,1 unique 3 | perl -pe 's*N/A*0*g; s/^\t/Class\t/' | awk -F'\t' 'BEGIN{OFS="\t"}{if(NR>1){for(k=2; k<=NF; k++){totals[k]+=$k}}; print $0}END{printf "Total\t"; for(k=2; k<2+length(totals); k++){printf "%s\t", totals[k]}; printf "\n"}' | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$20,$19}' | awk -F'\t' '{if(NR==1){print $0}else{printf $1"\t"; for(k=2; k<=NF; k++){printf("%\047d\t",$k)}; printf "\n"}}' | perl -pe 's/-/ /g; s/^([a-z])/\U$1/' | csv2md -d $'\t'
#


