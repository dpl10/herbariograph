# DATASET

The dataset was constructed from a variety of public data sources detailed below. Each image was manually reviewed and a total of 10,240 images per class were randomly selected: 8,192 train, 1,024 test, and 1,024 validate. Images are licensed by their originating institutions under some form of Creative Commons license (CC0, CC-BY, CC-BY-NC, or CC-BY-SA). The institutional origin of each image is detailed in the TensorFlow record files.


## Animal specimen images

Animal specimen data were downloaded from [GBIF](https://www.gbif.org/) in bulk and then reprocessed to extract image URLs for animal specimens belonging to genera that are also vascular plant genera. A random sample of collections at 
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


## Vascular plant illustrations

Vascular plant illustrations were mainly sourced from [Biodiversity Heritage Library](https://www.biodiversitylibrary.org/) (BHL). Collections of images were manually downloaded via a [curated collection of Flickr albums](https://www.flickr.com/photos/biodivlibrary/albums). Additional images were manually separated from downloads that targeted other classes. Downloaded images were manually screened to remove non–vascular plant images as well as to segregate plant illustrations into color versus monochrome/grayscale classes. 

### Color illustrations

<!-- sample images -->

### Grayscale illustrations

<!-- sample images -->


## Live vascular plant images

Images were manually separated from downloads that targeted other classes. Downloaded images were screened to remove landscapes and identifiable people.

<!-- sample images -->


## Micrograph images

Images were manually separated from downloads that targeted other classes.

<!-- sample images -->

## Microscope slides 



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
and [University of Oslo](https://www.nhm.uio.no/samlinger/botanikk/index.html) (O). A random subset of URLs were selected for for download and further sorting.

### Aesthetically pleasing pressed and dried herbarium specimen images

Aesthetically pleasing pressed and dried herbarium specimen images were manually separated from bulk downloads. Incomplete, partially obscured, and artifact–heavy specimen images were avoided.

<!-- sample images -->

### Mixed pressed and dried herbarium specimen images

Images that include specimens from multiple distinct collection events or single events that gathered multiple distinct taxa. Mixed specimen images include clear visible evidence of being mixed (e.g. expert annotations, multiple non–duplicate collection labels). The biological specimens may, or may not, be visible in the images—mixed specimens are frequently fully occluded (e.g. in packets), but occluded class images purport to be unmixed. Mixed specimen images occasionally feature photographs of live plants, micrographs, specimen reproductions, or illustrations, but unlike these classes biological specimens are present: either visible or, presumably, included in a specimen container (e.g. packet). 

<!-- sample images -->

### Ordinary pressed and dried herbarium specimen images

<!-- sample images -->

### Pressed and dried herbarium specimen closeup images

<!-- sample images -->

### Pressed and dried fragmentary herbarium specimen images

This class includes images with small amounts of biological material and often includes mounted photographic reproductions or illustrations of additional aspects. Minute whole plants are not included in this class.

<!-- sample images -->

### Pressed and dried specimen reproductions

Specimen reproductions—primarily mounted photographic prints of mounted pressed and dried herbarium specimens—were manually separated from downloads that targeted other classes. In contrast to all other classes, all depicted biological material is the product of at least two photographic events.

<!-- sample images -->

### Occluded specimen images

This class includes images of opaque specimen containers without visible biological specimens (e.g. boxes, packets, folders, etc.). Occluded specimen images often feature large amounts of text (e.g. specimen labels), but unlike the text–focused class which includes text in a number of settings, the full extent of the specimen container is visible in occluded specimen images and there are no visible biological specimens which may, or may not, be present in text–focused images. Occluded specimen images often feature photographs of live plants, micrographs, specimen reproductions, or illustrations, but unlike these classes a specimen container is clearly visible (e.g. packet) in the occluded specimen images. Occluded specimen images also differ from mixed specimen images: although mixed specimen images may also be entirely occluded, they contain clear evidence of multiple collections and/or taxa (e.g. visible expert annotations) whereas the occluded class images purport to be unmixed.  

<!-- sample images -->

### Spirit–preserved specimen images

<!-- sample images -->

### Text–focused images

This class includes images dominated by text to the exclusion biological specimens or other context (e.g. specimen labels). Text–focused specimen images occasionally feature live plants, micrographs, specimen reproductions, illustrations, or biological specimens, but when they present they are frequently arbitrarily cropped or out of focus. Text may be typeset, handwritten, or a combination of both. Text is usually on paper, but may be reproduced on other materials as well.

<!-- sample images -->

### Unpressed specimen images

<!-- sample images -->

### Xylogical specimen images

Milled on at least two sides

<!-- sample images -->


## TensorFlow records

<!-- field structure -->

<!-- table of classes (id number) and image sources (id number) -->



# INFORMER MODEL ARCHITECTURE

The Informer architecture is a based on the Compact Convolutional Transformer (CCT; [Hassan et al 2021](https://arxiv.org/abs/2104.05704)) modified to include an image tokenizer and token reducer inspired by Inception ([Szegedy et al. 2016](https://arxiv.org/abs/1602.07261v2)) and SqueezeNet ([Iandola et al. 2016](https://arxiv.org/abs/1602.07360)). For greater computational efficiency, a mixture of conventional transformers and poolformers ([Yu et al. 2022](https://arxiv.org/abs/2111.11418)) have been employed. Thus, the name *Informer* is a combination of *In*ception and Trans*former*.



# TRAINING