# DATASET

The dataset was constructed from a variety of public data sources detailed below. Each image was manually reviewed and a total of 12,288 images per class were randomly selected: 10,240 train, 1,024 test, and 1,024 validate. Images are licensed by their originating institutions under some form of Creative Commons license (CC0, CC-BY, CC-BY-NC, or CC-BY-SA). The institutional origin of each image is detailed in the TensorFlow record files.

<!-- find raw-dataset/ -type f -name '*.jpg' | awk -F/ '{print $2,$3}' | sort | uniq -c | awk 'BEGIN{OFS="\t"; c=""; n=0}{if(NR==1){c=$2}; if(c==$2){n+=$1}else{print "Total",c,n; c=$2; n=$1}; print $3,$2,$1}END{print "Total",c,n}' | datamash crosstab 2,1 unique 3 | perl -pe 's*N/A*0*g; s/^\t/Class\t/' | awk -F'\t' 'BEGIN{OFS="\t"}{if(NR>1){for(k=2; k<=NF; k++){totals[k]+=$k}}; print $0}END{printf "Total\t"; for(k=2; k<2+length(totals); k++){printf "%s\t", totals[k]}; printf "\n"}' | awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$20,$19}' | awk -F'\t' '{if(NR==1){print $0}else{printf $1"\t"; for(k=2; k<=NF; k++){printf("%\047d\t",$k)}; printf "\n"}}' | perl -pe 's/-/ /g; s/^([a-z])/\U$1/' | csv2md -d $'\t' -->
| Class                                    | BHL    | BR    | C     | CHNDM | E     | F      | GH    | K     | L      | MA    | MICH  | MO    | MPU   | Met   | NY     | O     | P      | US     | Total   |
| ---------------------------------------- | ------ | ----- | ----- | ----- | ----- | ------ | ----- | ----- | ------ | ----- | ----- | ----- | ----- | ----- | ------ | ----- | ------ | ------ | ------- |
| Aesthetically pleasing pressed specimens | 0      | 315   | 13    | 0     | 591   | 2,808  | 1,008 | 0     | 2,879  | 449   | 229   | 20    | 137   | 0     | 3,437  | 217   | 121    | 397    | 12,621  |
| Biocultural specimens                    | 0      | 0     | 1,300 | 715   | 0     | 3,458  | 0     | 1,897 | 35     | 0     | 0     | 114   | 0     | 5,196 | 3      | 0     | 0      | 0      | 12,718  |
| Corrupted images                         | 0      | 1     | 0     | 0     | 0     | 0      | 2     | 0     | 14     | 2     | 0     | 48    | 0     | 0     | 1      | 1     | 1      | 3      | 73      |
| Fragmentary pressed specimens            | 0      | 336   | 0     | 0     | 134   | 1,768  | 49    | 0     | 469    | 42    | 40    | 14    | 43    | 0     | 848    | 11    | 315    | 175    | 4,244   |
| Illustrations color                      | 11,780 | 221   | 0     | 0     | 3     | 48     | 1     | 0     | 1      | 0     | 0     | 0     | 13    | 0     | 710    | 0     | 17     | 0      | 12,794  |
| Illustrations gray                       | 8,227  | 3,325 | 0     | 0     | 130   | 270    | 2     | 0     | 53     | 40    | 1     | 51    | 107   | 0     | 41     | 2     | 250    | 2      | 12,501  |
| Live plants                              | 0      | 1,061 | 0     | 0     | 2,048 | 419    | 3     | 0     | 10     | 7     | 9     | 2,048 | 8     | 0     | 2,048  | 6     | 2,048  | 2,048  | 11,763  |
| Micrographs                              | 0      | 0     | 0     | 0     | 16    | 425    | 0     | 0     | 0      | 2     | 0     | 2     | 4     | 0     | 5      | 0     | 1,333  | 8,520  | 10,307  |
| Microscope slides                        | 0      | 0     | 0     | 0     | 0     | 0      | 0     | 0     | 12,456 | 0     | 0     | 0     | 0     | 0     | 2      | 0     | 0      | 0      | 12,458  |
| Mixed pressed specimens                  | 0      | 260   | 1     | 0     | 1,627 | 216    | 1,060 | 0     | 31     | 10    | 173   | 3     | 41    | 0     | 2,068  | 358   | 923    | 656    | 7,427   |
| Occluded specimens                       | 0      | 185   | 309   | 0     | 201   | 324    | 97    | 0     | 873    | 17    | 2,676 | 1     | 30    | 0     | 2,849  | 583   | 4,006  | 515    | 12,666  |
| Ordinary pressed specimens               | 0      | 1,599 | 188   | 0     | 810   | 1,179  | 504   | 0     | 1,303  | 562   | 840   | 1,225 | 964   | 0     | 1,528  | 884   | 1,333  | 1,205  | 14,124  |
| Pressed specimen reproductions           | 0      | 620   | 0     | 0     | 287   | 8,711  | 3     | 0     | 75     | 3     | 178   | 4     | 39    | 0     | 25     | 2     | 27     | 12     | 9,986   |
| Pressed specimens closeup                | 0      | 229   | 0     | 0     | 157   | 1,679  | 0     | 0     | 8      | 10    | 328   | 99    | 53    | 0     | 300    | 42    | 609    | 1      | 3,515   |
| Spirit preserved specimens               | 0      | 0     | 106   | 0     | 0     | 0      | 0     | 18    | 5      | 0     | 0     | 0     | 0     | 0     | 536    | 0     | 0      | 0      | 665     |
| Text focused                             | 0      | 490   | 0     | 0     | 189   | 9      | 1     | 1     | 4      | 277   | 192   | 536   | 612   | 0     | 1,958  | 2,915 | 1,108  | 1,576  | 9,868   |
| Unpressed specimens                      | 0      | 49    | 46    | 0     | 16    | 1,459  | 4     | 389   | 109    | 1     | 71    | 59    | 3     | 0     | 3,422  | 0     | 50     | 8      | 5,686   |
| Xylogical specimens                      | 0      | 2     | 1     | 0     | 0     | 132    | 0     | 43    | 21     | 0     | 0     | 2     | 0     | 0     | 6      | 0     | 0      | 0      | 207     |
| Total                                    | 20,007 | 8,693 | 1,964 | 715   | 6,209 | 22,905 | 2,734 | 2,348 | 18,346 | 1,422 | 4,737 | 4,226 | 2,054 | 5,196 | 19,787 | 5,021 | 12,141 | 15,118 | 153,623 |


## Animal specimen images

Animal specimen data were downloaded from [GBIF](https://www.gbif.org/) in bulk and then reprocessed to extract image URLs for animal specimens belonging to genera whose names are also used for vascular plant genera in the World Checklist of Vascular Plants v9 (WCVP; [Govaerts et al. 2021](https://doi.org/10.1038/s41597-021-00997-6)). A random sample of such collections at 
<!-- places -->
were downloaded.

<!-- sample images -->


## Biocultural specimen images

Biocultural specimen images were sourced from a selection of specialty collections: 
[Field Museum Timothy C. Plowman Economic Botany Collection](https://www.fieldmuseum.org/node/5211) (F),
[Natural History Museum of Denmark Biocultural Botany Collection](https://www.gbif.org/dataset/acf5050c-3a41-4345-a660-652cb9462379) (C), 
and [Royal Botanic Gardens Kew Economic Botany Collection](https://www.gbif.org/dataset/1d31211e-350e-492a-a597-34d24bbc1769) (K). 
In addition, images were also sourced from a selection of open access cultural collections at the 
[Metropolitan Museum of Art](https://github.com/metmuseum/openaccess) (Met) 
and [Cooper Hewitt (Smithsonian) National Design Museum](https://registry.opendata.aws/smithsonian-open-access/) (CHNDM). 
Additional images were manually separated from downloads that targeted other classes. 
Downloaded images were manually screened to remove non–vascular plant images, pressed specimens, and specimens that had not been significantly altered from their natural state.

<!-- sample images -->


## Corrupted images



<!-- sample images -->


## Vascular plant illustrations

Vascular plant illustrations were mainly sourced from [Biodiversity Heritage Library](https://www.biodiversitylibrary.org/) (BHL). Collections of images were manually downloaded via a [curated collection of Flickr albums](https://www.flickr.com/photos/biodivlibrary/albums). Additional images were manually separated from downloads that targeted other classes. Downloaded images were manually screened to remove non–vascular plant images as well as to segregate plant illustrations into color versus monochrome/grayscale classes. Images of these classes do not contain visible preserved biological specimens or any evidence of preserved specimens in the form of specimen containers (e.g. packets). Text may be present, but the preponderance of the image is illustration(s). In rare cases, images are digitized photographic reproductions of illustrations (the photographic reproduction process used often converts color to grayscale).

### Color illustrations

<!-- sample images -->

### Grayscale illustrations

<!-- sample images -->


## Live vascular plant images

Images were manually separated from downloads that targeted other classes. Downloaded images were screened to remove identifiable people and landscape–only images. Living plant images include native digital, digitized analogue photographs, or images mounted on specimen sheets. Images of this class do not contain visible preserved biological specimens or any evidence of preserved specimens in the form of specimen containers (e.g. packets).

<!-- sample images -->


## Micrograph images

Images were manually separated from downloads that targeted other classes. Micrographs include images captured with Scanning Electron Microscopes (SEM), Transmission Electron Microscopes (TEM), transmission light microscopes, and reflected light microscopes. Images include native digital, digitized analogue micrographs, or micrographs mounted on specimen sheets. Images of this class do not contain visible preserved biological specimens or any evidence of preserved specimens in the form of specimen containers (e.g. packets).

<!-- sample images -->

## Microscope slides 

This class includes images of prepared transmission light microscope glass slides. Slides my be imaged in isolation or mounted on herbarium sheets. Images of this class do not contain any other visible preserved biological specimens or any evidence of other preserved specimens in the form of specimen containers (e.g. packets). Slides prepared for reflected light microscopes are considered fragments.

<!-- sample images -->


## Vascular plant specimen images

Vascular plant specimen data were downloaded from [GBIF](https://www.gbif.org/) in bulk and then reprocessed, as described below, to extract image URLs for collections at 
[Field Museum](https://collections-botany.fieldmuseum.org/) (F), 
[Harvard University Herbaria](https://huh.harvard.edu/) (GH),
[Meise Botanic Garden Herbarium](https://www.botanicalcollections.be) (BR), 
[Missouri Botanical Garden](https://www.missouribotanicalgarden.org/plant-science/plant-science/resources/herbarium) (MO), 
[Muséum National d'Histoire Naturelle](https://science.mnhn.fr/institution/mnhn/collection/p/item/search/form) (P),
[National Herbarium of New South Wales](https://www.rbgsyd.nsw.gov.au/science/national-herbarium-of-new-south-wales) (NSW),
[Natural History Museum of Denmark](https://samlinger.snm.ku.dk/en/dry-and-wet-collections/botany/) (C),
[Naturalis Biodiversity Center](https://www.naturalis.nl/collectie) (L; no GBIF records were available, so Darwin Core Archives were downloaded directly from the Naturalis API), 
[New York Botanical Garden](http://sweetgum.nybg.org/science/vh/) (NY), 
[Real Jardín Botánico](https://rjb.csic.es/rjb-colecciones/herbario-ma/) (MA),
[Royal Botanic Garden Edinburgh](https://www.rbge.org.uk/science-and-conservation/herbarium/) (E),
[Royal Botanic Gardens Kew](https://www.kew.org/science/collections-and-resources/collections/herbarium) (K), 
[Smithsonian Institution](https://naturalhistory.si.edu/research/botany) (US),
[Université de Montpellier](https://collections.umontpellier.fr/collections/botanique/herbier-mpu) (MPU),
[University of Michigan](https://lsa.umich.edu/herbarium/) (MICH),
and [University of Oslo](https://www.nhm.uio.no/samlinger/botanikk/index.html) (O). A arbitrary subset of URLs were selected for for download and further sorting.

### Aesthetically pleasing pressed and dried herbarium specimen images

Aesthetically pleasing pressed and dried herbarium specimen images were manually separated from bulk downloads. Incomplete, partially obscured, and artifact–heavy specimen images were avoided. Additional specimen containers (e.g. packet) may be included in images. All images of this class are at approximately the same scale.

<!-- sample images -->

### Mixed pressed and dried herbarium specimen images

This class includes images of specimens from multiple distinct collection events or single events that gathered multiple distinct taxa. Mixed specimen images include visibly documented evidence of being mixed (e.g. expert annotations, multiple non–duplicate collection labels). The biological specimens may, or may not, be visible in the images—mixed specimens are frequently fully occluded (e.g. in packets), but occluded class images purport to be unmixed. Mixed specimen images occasionally feature photographs of live plants, micrographs, specimen reproductions, or illustrations, but unlike these classes biological specimens are present: either visible or, presumably, included in a specimen container (e.g. packet). Mixed specimens are often fragmentary. All images of this class are at approximately the same scale.

<!-- sample images -->

### Ordinary pressed and dried herbarium specimen images

Ordinary pressed and dried herbarium specimen images occasionally feature photographs of live plants, micrographs, specimen reproductions, text documents, or illustrations, but unlike these classes there is a, mostly, unobstructed view of one or more preserved biological specimens. Additional specimen containers (e.g. packet) may be included in images of this class. All images of this class are at approximately the same scale.

<!-- sample images -->

### Pressed and dried herbarium specimen closeup images

This class includes images of pressed and dried herbarium specimens. Typical images include close views of mounted specimens or unmounted fragments (e.g. the contents of a fragment packet). Closeup images occasionally feature portions of photographs of live plants, micrographs, specimen reproductions, text documents, specimen labels, or illustrations, but when they present they are frequently arbitrarily cropped.

<!-- sample images -->

### Pressed and dried fragmentary herbarium specimen images

This class includes images of whole herbarium sheets with small amounts of preserved biological material and often include mounted photographs of live plants, micrographs, specimen reproductions, text documents, or illustrations. Specimens are often disarticulated and are frequently represent only one organ type (e.g. leaves). Closeup views of fragments or minute whole plants (no matter how disarrayed) are not included in this class. Additional specimen containers (e.g. packet) may be included in images of this class. All images of this class are at approximately the same scale.

<!-- sample images -->

### Pressed and dried specimen reproductions

Specimen reproductions—primarily mounted photographic prints of mounted pressed and dried herbarium specimens—were manually separated from downloads that targeted other classes. Color photographic prints are uncommon. In contrast to all other classes, all depicted biological material is the product of at least two photographic events: the first event is typically an analogue grayscale process and the second event is typically a color digital process.

<!-- sample images -->

### Occluded specimen images

This class includes images of non–transparent specimen containers (e.g. boxes, packets, folders, etc.) or redirection sheets (e.g. otherwise empty sheets that point to a carpological collection) without clearly visible biological specimens. Occluded specimen images often feature large amounts of text (e.g. specimen labels), but unlike the text–focused class which includes text in a number of settings, the full extent of the specimen container or redirection is visible in occluded specimen images and there are no visible biological specimens which may, or may not, be present in text–focused images. Occluded specimen images often feature photographs of live plants, micrographs, specimen reproductions, text documents, or illustrations, but unlike these classes a specimen container or indictor is clearly visible (e.g. packet) in the occluded specimen images. Occluded specimen images also differ from mixed specimen images: although mixed specimen images may also be entirely occluded, they contain clear evidence of multiple collections and/or taxa (e.g. visible expert annotations) whereas the occluded class images purport to be unmixed. Specimen detritus that does not appear to be attached to a herbarium sheet is occasionally visible in images of this class. 

<!-- sample images -->

### Spirit–preserved specimen images

This class includes images of fluid preserved specimens in clear or translucent containers. In rare cases the liquid preservative is not present.

<!-- sample images -->

### Text–focused images

This class includes images dominated by text to the exclusion biological specimens or other context (e.g. specimen labels). Text–focused specimen images occasionally feature live plant images, micrographs, specimen reproductions, illustrations, or biological specimens, but when they present they are frequently arbitrarily cropped or out of focus. Text may be typeset, handwritten, or a combination of both. Text is usually on paper, but may be reproduced on other materials as well.

<!-- sample images -->

### Unpressed specimen images

This class includes images of dried unpressed biological specimens. These preserved samples are typically unmounted and represent reproductive or vegetative parts too bulky to be pressed. Specimens that include a mixture of pressed and unpressed materials are not included in this class. Other than drying, these specimens have not been modified from their natural state. 

<!-- sample images -->

### Xylogical specimen images

This class includes images of wood samples that have been milled on at least two sides for the study of wood anatomy.

<!-- sample images -->

## TensorFlow records

<!-- field structure -->

<!-- table of classes (id number) and image sources (id number) -->



# INFORMER MODEL ARCHITECTURE

The Informer architecture is a based on the Compact Convolutional Transformer (CCT; [Hassan et al 2021](https://arxiv.org/abs/2104.05704)) modified to include an image tokenizer and token reducer inspired by Inception ([Szegedy et al. 2016](https://arxiv.org/abs/1602.07261v2)) and SqueezeNet ([Iandola et al. 2016](https://arxiv.org/abs/1602.07360)). For greater computational efficiency, a mixture of conventional transformers and poolformers ([Yu et al. 2022](https://arxiv.org/abs/2111.11418)) have been employed. Thus, the name *Informer* is a combination of *In*ception and Trans*former*.



# TRAINING