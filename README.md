# DATASET

The dataset was constructed from a variety of public data sources detailed below. Each image was manually reviewed and a total of 12,288 images per class were randomly selected: 10,240 train, 1,024 test, and 1,024 validate. Images are licensed by their originating institutions under some form of Creative Commons license (CC0, CC-BY, CC-BY-NC, or CC-BY-SA).

<!-- find raw-dataset -type f -name '*.jpg' | awk -F/ '{print $2,$3}' | sort | uniq -c | awk 'BEGIN{OFS="\t"; c=""; n=0}{if(NR==1){c=$2}; if(c==$2){n+=$1}else{print "Total",c,n; c=$2; n=$1}; print $3,$2,$1}END{print "Total",c,n}' | datamash crosstab 2,1 unique 3 | perl -pe 's*N/A*0*g; s/^\t/Category\t/' | awk -F'\t' 'BEGIN{OFS="\t"}{if(NR>1){for(k=2; k<=NF; k++){totals[k]+=$k}}; print $0}END{printf "Total\t"; for(k=2; k<2+length(totals); k++){printf "%s\t", totals[k]}; printf "\n"}' | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$39,$40,$41,$42,$43,$44,$45,$38}' | awk -F'\t' '{if(NR==1){print $0}else{printf $1"\t"; for(k=2; k<=NF; k++){printf("%\047d\t",$k)}; printf "\n"}}' | perl -pe 's/-/ /g; s/^([a-z])/\U$1/' | csv2md -d $'\t' -->

| Category                       | AK    | ASU | BHL    | BR    | C     | CAS   | CHNDM | COLO | E     | F      | FMNH | GH    | K     | KY  | L      | LY    | MA  | MCZ | MICH  | MO    | MPU   | MZH | Met   | NCU   | NHMD | NHMO | NMR | NY     | O     | P      | RSA   | SDNHM | TEX | TRH   | TTU | TU  | Tw     | UA  | UHIM | UMMZ | US     | YPM | YU    | Total   |
| ------------------------------ | ----- | --- | ------ | ----- | ----- | ----- | ----- | ---- | ----- | ------ | ---- | ----- | ----- | --- | ------ | ----- | --- | --- | ----- | ----- | ----- | --- | ----- | ----- | ---- | ---- | --- | ------ | ----- | ------ | ----- | ----- | --- | ----- | --- | --- | ------ | --- | ---- | ---- | ------ | --- | ----- | ------- |
| Animal specimens               | 858   | 807 | 0      | 0     | 0     | 858   | 0     | 0    | 0     | 0      | 857  | 0     | 0     | 857 | 0      | 0     | 0   | 848 | 0     | 0     | 0     | 857 | 0     | 0     | 417  | 857  | 857 | 0      | 0     | 0      | 0     | 505   | 0   | 0     | 388 | 857 | 0      | 857 | 91   | 676  | 0      | 840 | 1     | 12,288  |
| Biocultural specimens          | 1     | 0   | 0      | 0     | 1,272 | 0     | 714   | 0    | 0     | 3,026  | 0    | 0     | 1,925 | 0   | 47     | 1     | 0   | 0   | 0     | 141   | 0     | 0   | 5,157 | 0     | 0    | 0    | 0   | 3      | 0     | 0      | 0     | 0     | 1   | 0     | 0   | 0   | 0      | 0   | 0    | 0    | 0      | 0   | 0     | 12,288  |
| Corrupted images               | 116   | 0   | 0      | 419   | 113   | 240   | 0     | 104  | 387   | 943    | 0    | 362   | 0     | 0   | 310    | 702   | 70  | 0   | 593   | 151   | 215   | 0   | 0     | 246   | 0    | 0    | 0   | 2,992  | 498   | 1,633  | 483   | 0     | 55  | 138   | 0   | 0   | 0      | 0   | 0    | 0    | 1,071  | 0   | 447   | 12,288  |
| Fragmentary pressed specimens  | 44    | 0   | 0      | 1,132 | 0     | 294   | 0     | 50   | 209   | 1,632  | 0    | 242   | 0     | 0   | 1,418  | 1,268 | 57  | 0   | 81    | 11    | 152   | 0   | 0     | 299   | 0    | 0    | 0   | 1,502  | 99    | 1,909  | 222   | 0     | 84  | 156   | 0   | 0   | 0      | 0   | 0    | 0    | 1,398  | 0   | 29    | 12,288  |
| Illustrations color            | 1     | 0   | 11,153 | 218   | 0     | 1     | 0     | 1    | 16    | 48     | 0    | 1     | 28    | 0   | 3      | 6     | 0   | 0   | 0     | 39    | 10    | 0   | 0     | 0     | 0    | 0    | 0   | 711    | 0     | 41     | 10    | 0     | 0   | 0     | 0   | 0   | 0      | 0   | 0    | 0    | 1      | 0   | 0     | 12,288  |
| Illustrations gray             | 3     | 0   | 7,553  | 3,278 | 0     | 5     | 0     | 1    | 177   | 299    | 0    | 4     | 0     | 0   | 67     | 4     | 41  | 0   | 1     | 26    | 91    | 0   | 0     | 0     | 0    | 0    | 0   | 57     | 2     | 599    | 71    | 0     | 3   | 0     | 0   | 0   | 0      | 0   | 0    | 0    | 4      | 0   | 2     | 12,288  |
| Live plants                    | 1,630 | 0   | 0      | 909   | 0     | 9     | 0     | 13   | 1,638 | 530    | 0    | 3     | 3     | 0   | 10     | 41    | 11  | 0   | 7     | 1,631 | 7     | 0   | 0     | 257   | 0    | 0    | 0   | 1,630  | 10    | 1,630  | 53    | 0     | 120 | 507   | 0   | 0   | 0      | 0   | 0    | 0    | 1,631  | 0   | 8     | 12,288  |
| Micrographs electron           | 0     | 0   | 0      | 0     | 0     | 3     | 0     | 0    | 6     | 0      | 0    | 0     | 0     | 0   | 0      | 0     | 1   | 0   | 0     | 1     | 1     | 0   | 0     | 0     | 0    | 0    | 0   | 3,864  | 0     | 48     | 0     | 0     | 1   | 0     | 0   | 0   | 2,301  | 0   | 0    | 0    | 6,061  | 0   | 1     | 12,288  |
| Micrographs reflected light    | 118   | 0   | 0      | 582   | 70    | 15    | 0     | 72   | 178   | 2,078  | 0    | 315   | 0     | 0   | 20     | 566   | 13  | 0   | 642   | 98    | 253   | 0   | 0     | 25    | 0    | 0    | 0   | 2,371  | 768   | 2,914  | 4     | 0     | 0   | 148   | 0   | 0   | 71     | 0   | 0    | 0    | 121    | 0   | 846   | 12,288  |
| Micrographs transmission light | 5     | 0   | 0      | 0     | 0     | 0     | 0     | 0    | 1     | 0      | 0    | 0     | 4,577 | 0   | 0      | 0     | 0   | 0   | 0     | 0     | 0     | 0   | 0     | 0     | 0    | 0    | 0   | 2      | 0     | 69     | 0     | 0     | 0   | 0     | 0   | 0   | 7,609  | 0   | 0    | 0    | 25     | 0   | 0     | 12,288  |
| Microscope slides              | 0     | 0   | 0      | 0     | 0     | 0     | 0     | 0    | 0     | 0      | 0    | 0     | 1,354 | 0   | 10,934 | 0     | 0   | 0   | 0     | 0     | 0     | 0   | 0     | 0     | 0    | 0    | 0   | 0      | 0     | 0      | 0     | 0     | 0   | 0     | 0   | 0   | 0      | 0   | 0    | 0    | 0      | 0   | 0     | 12,288  |
| Mixed pressed specimens        | 12    | 0   | 0      | 292   | 0     | 864   | 0     | 40   | 1,259 | 300    | 0    | 1,235 | 0     | 0   | 154    | 803   | 16  | 0   | 158   | 3     | 88    | 0   | 0     | 39    | 0    | 0    | 0   | 2,177  | 553   | 1,444  | 575   | 0     | 14  | 30    | 0   | 0   | 0      | 0   | 0    | 0    | 1,156  | 0   | 1,076 | 12,288  |
| Occluded specimens             | 8     | 0   | 0      | 178   | 300   | 38    | 0     | 34   | 143   | 275    | 0    | 114   | 0     | 0   | 983    | 1,874 | 21  | 0   | 1,676 | 1     | 28    | 0   | 0     | 612   | 0    | 0    | 0   | 2,384  | 545   | 1,783  | 171   | 0     | 13  | 401   | 0   | 0   | 0      | 0   | 0    | 0    | 630    | 0   | 76    | 12,288  |
| Ordinary pressed specimens     | 116   | 0   | 0      | 418   | 114   | 240   | 0     | 104  | 387   | 943    | 0    | 362   | 0     | 0   | 310    | 702   | 70  | 0   | 593   | 151   | 215   | 0   | 0     | 246   | 0    | 0    | 0   | 2,992  | 498   | 1,625  | 483   | 0     | 55  | 138   | 0   | 0   | 0      | 0   | 0    | 0    | 1,079  | 0   | 447   | 12,288  |
| Specimen reproductions         | 2     | 0   | 0      | 622   | 2     | 1     | 0     | 10   | 651   | 9,824  | 0    | 8     | 0     | 0   | 87     | 34    | 4   | 0   | 213   | 4     | 23    | 0   | 0     | 4     | 0    | 0    | 0   | 116    | 3     | 50     | 454   | 0     | 167 | 2     | 0   | 0   | 0      | 0   | 0    | 0    | 6      | 0   | 1     | 12,288  |
| Text focused                   | 59    | 0   | 0      | 751   | 0     | 143   | 0     | 223  | 208   | 19     | 0    | 13    | 2     | 0   | 69     | 67    | 276 | 0   | 198   | 536   | 629   | 0   | 0     | 443   | 0    | 0    | 0   | 2,201  | 457   | 1,388  | 94    | 0     | 26  | 41    | 0   | 0   | 1,372  | 0   | 0    | 0    | 2,993  | 0   | 80    | 12,288  |
| Unpressed specimens            | 341   | 0   | 0      | 159   | 157   | 63    | 0     | 118  | 27    | 1,733  | 0    | 15    | 763   | 0   | 203    | 4     | 1   | 0   | 99    | 67    | 9     | 0   | 0     | 29    | 0    | 0    | 0   | 4,838  | 1     | 102    | 1,409 | 0     | 203 | 26    | 0   | 0   | 1,810  | 0   | 0    | 0    | 103    | 0   | 8     | 12,288  |
| Total                          | 3,314 | 807 | 18,706 | 8,958 | 2,028 | 2,774 | 714   | 770  | 5,287 | 21,650 | 857  | 2,674 | 8,652 | 857 | 14,615 | 6,072 | 581 | 848 | 4,261 | 2,860 | 1,721 | 857 | 5,157 | 2,200 | 417  | 857  | 857 | 27,840 | 3,434 | 15,235 | 4,029 | 505   | 742 | 1,587 | 388 | 857 | 13,163 | 857 | 91   | 676  | 16,279 | 840 | 3,022 | 208,896 |



## TensorFlow records

[TensorFlow Record (.tfr) files]() containing images in JPEG format images.

<!--  csv2md category-index.csv  -->

| Category                      | Index |
| ----------------------------- | ----- |
| Animal                        | 0     |
| Biocultural                   | 1     |
| Corrupted                     | 2     |
| Fragmentary                   | 3     |
| Color illustration            | 4     |
| Grayscale illustration        | 5     |
| Live plant                    | 6     |
| Electron Micrograph           | 7     |
| Reflected Light Micrograph    | 8     |
| Transmission Light Micrograph | 9     |
| Microscope slide              | 10    |
| Mixed                         | 11    |
| Occluded                      | 12    |
| Ordinary                      | 13    |
| Reproduction                  | 14    |
| Text                          | 15    |
| Unpressed                     | 16    |



## CODE

Code developed and tested using TensorFlow 2.13.0 [official Docker images](https://hub.docker.com/r/tensorflow/tensorflow/tags).



### TRAINED MODEL