# DATASET

The dataset was constructed from a variety of public data sources detailed below. Each image was manually reviewed and a total of 8,192 images per class were randomly selected: 7,168 train, 512 test, and 512 validate.


## Illustrations

Vascular plant illustrations were sourced from the [Biodiversity Heritage Library (BHL)](https://www.biodiversitylibrary.org/). Collections of images were manually downloaded via a [curated collection of albums](https://www.flickr.com/photos/biodivlibrary/albums). Downloaded images were further processed...

First run: no maps, portraits, landscapes, and altered or natural photographs, fungi, physiology diagrams

Second: Code Color vs. Gray

Third: 65.4% ok in color; additional cleaning (maps+ yellowish and sepia appearance)


## Live plant images

NY + MO

manually separated from MO herbarium2022 download

from NY Emu a maximum of 15 images per genus


## Biocultural specimens

Natural History Museum of Denmark [Biocultural Botany Collection](https://www.gbif.org/dataset/acf5050c-3a41-4345-a660-652cb9462379)

GH [Economic Herbarium of Oakes Ames (ECON)](https://huh.harvard.edu/pages/economic-herbarium-oakes-ames-econ) 

K [Economic Botany Collection](https://www.gbif.org/dataset/1d31211e-350e-492a-a597-34d24bbc1769)

REFLORA [Economic Botany Collection (EBC)](https://www.gbif.org/dataset/a71ae102-f65d-4bd5-9915-bb1a96d86c16)


# INFORMER MODEL ARCHITECTURE

The Informer architecture is a based on the Compact Convolutional Transformer (CCT; [Hassan et al 2021](https://arxiv.org/abs/2104.05704)) modified to include an image tokenizer and token reducer inspired by Inception ([Szegedy et al. 2016](https://arxiv.org/abs/1602.07261v2)) and SqueezeNet ([Iandola et al. 2016](https://arxiv.org/abs/1602.07360)). For greater computational efficiency, a mixture of conventional transformers and poolformers ([Yu et al. 2022](https://arxiv.org/abs/2111.11418)) have been employed. Thus, the name *Informer* is a combination of *In*ception and Trans*former*.
