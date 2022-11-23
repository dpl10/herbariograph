# DATASET

The dataset was constructed from a variety of public data sources detailed below. Each image was manually reviewed and a total of 10,240 images per class were randomly selected: 8,192 train, 1,024 test, and 1,024 validate. Vascular plant specimen data were downloaded from [GBIF](https://www.gbif.org/) in bulk and then reprocessed, as described below, to extract image URLs for collections at 
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
and [University of Oslo](https://www.nhm.uio.no/samlinger/botanikk/index.html) (O). 
The institutional origin of each image is detailed in the TensorFlow record files. Images are licensed by their originating institutions under some form of Creative Commons license (CC0, CC-BY, CC-BY-NC, or CC-BY-SA).


## Animal specimen images

<!-- sample images -->


## Biocultural specimen images

Biocultural specimen images were sourced from a selection of specialty collections: 
[Field Museum Timothy C. Plowman Economic Botany Collection](https://www.fieldmuseum.org/node/5211) (F), 
<!-- MO --> 
[Natural History Museum of Denmark Biocultural Botany Collection](https://www.gbif.org/dataset/acf5050c-3a41-4345-a660-652cb9462379) (C), 
and [Royal Botanic Gardens Kew Economic Botany Collection](https://www.gbif.org/dataset/1d31211e-350e-492a-a597-34d24bbc1769) (K). 
In addition, images were also sourced from a selection of open access cultural collections: 
[Metropolitan Museum of Art](https://github.com/metmuseum/openaccess) (Met) 
and [Cooper Hewitt (Smithsonian) National Design Museum](https://registry.opendata.aws/smithsonian-open-access/) (CHNDM). 
Downloaded images were manually screened to remove non–vascular plant images, mounted specimens, and specimens that had not been significantly altered from their natural state.

<!-- sample images -->


## Illustrations

Vascular plant illustrations were mainly sourced from [Biodiversity Heritage Library](https://www.biodiversitylibrary.org/) (BHL). Collections of images were manually downloaded via a [curated collection of Flickr albums](https://www.flickr.com/photos/biodivlibrary/albums). Additional images were manually separated from downloads that targeted other classes. Downloaded images were manually screened to remove non–vascular plant images as well as to segregate plant illustrations into color versus monochrome/grayscale classes. 
<!-- First run: no maps, portraits, landscapes, and altered or natural photographs, fungi, physiology diagrams; Second: Code Color vs. Gray; Third: 65.4% ok in color; additional cleaning (maps + yellowish and sepia appearance) -->

### Color illustrations

<!-- sample images -->

### Grayscale illustrations

<!-- sample images -->


## Live plant images

NY + MO

manually separated from MO herbarium2022 download

from NY Emu a maximum of 15 images per genus

Additional images were manually separated from downloads that targeted other classes. Downloaded images were manually screened to remove landscapes and people.

<!-- sample images -->


## Mounted specimen images


### Aesthetically pleasing mounted herbarium specimen images

<!-- sample images -->

### Ordinary mounted herbarium specimen images

<!-- sample images -->


## Unmounted and invisible specimen images

Images of unmounted specimens and images lacking a visible specimen were selected from the bulk GBIF download by searching for records with multiple images per occurrenceID. One collection (occurrenceID) per genus per institution was randomly selected for download and images were manually sorted into carpological, invisible, label only, mounted specimen closeup images, spirit collections, and xylogical specimen images.

### Carpological specimen images

<!-- sample images -->

### Invisible mounted specimen images

<!-- sample images -->

### Label only images

<!-- sample images -->

### Mounted herbarium specimen closeup images

<!-- sample images -->

### Spirit collection images

<!-- sample images -->

### Xylogical specimen images

<!-- sample images -->


## TensorFlow records

<!-- field structure -->

<!-- table of classes (id number) and image sources (id number) -->



# INFORMER MODEL ARCHITECTURE

The Informer architecture is a based on the Compact Convolutional Transformer (CCT; [Hassan et al 2021](https://arxiv.org/abs/2104.05704)) modified to include an image tokenizer and token reducer inspired by Inception ([Szegedy et al. 2016](https://arxiv.org/abs/1602.07261v2)) and SqueezeNet ([Iandola et al. 2016](https://arxiv.org/abs/1602.07360)). For greater computational efficiency, a mixture of conventional transformers and poolformers ([Yu et al. 2022](https://arxiv.org/abs/2111.11418)) have been employed. Thus, the name *Informer* is a combination of *In*ception and Trans*former*.



# TRAINING