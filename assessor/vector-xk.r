### LIBRARIES
library(caTools)
library(e1071)
library(rminer)

### INIT
set.seed(123456789)

### DATA FILES
closeup <- read.csv('vector-closeup-3k.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
color <- read.csv('vector-color.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
fragmentary <- read.csv('vector-fragmentary-4k.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
gray <- read.csv('vector-gray.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
live <- read.csv('vector-live.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
micrograph <- read.csv('vector-micrograph.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
mixed <- read.csv('vector-mixed.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
occluded <- read.csv('vector-occluded.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
ordinary <- read.csv('vector-ordinary.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
reproduction <- read.csv('vector-reproduction.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
slide <- read.csv('vector-slide.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
spirit <- read.csv('vector-spirit.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
text <- read.csv('vector-text.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
unpressed <- read.csv('vector-unpressed-5k.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
xylogical <- read.csv('vector-xylogical.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)

load('vector-unknown2.RData')



### PREDICT CONSTANTS
INCREMENT <- 250000
LOOP <- c(250001, 500001, 750001, 1000001, 1250001, 1500001, 1750001, 2000001, nrow(unknown))
P <- 0.95


### DATA FORMAT: CLOSEUP
illustration <- rbind(color, gray)
sheets <- rbind(mixed, ordinary)
n <- 348
data <- rbind(fragmentary[sample(nrow(fragmentary), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),], unpressed[sample(nrow(unpressed), n),], xylogical)
data[,'class'] <- 'other'
data <- rbind(data, closeup)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: CLOSEUP
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-closeup-3k.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
100*mean(y_pred == test[,1]) ### accuracy
# [1] 92.79712

### DATA FORMAT: FRAGMENTARY
illustration <- rbind(color, gray)
sheets <- rbind(mixed, ordinary)
n <- 438
data <- rbind(closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),], unpressed[sample(nrow(unpressed), n),], xylogical)
data[,'class'] <- 'other'
data <- rbind(data, fragmentary)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: FRAGMENTARY
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-fragmentary-4k.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
100*mean(y_pred == test[,1]) ### accuracy
# [1] 94.06084

### DATA FORMAT: UNPRESSED
illustration <- rbind(color, gray)
sheets <- rbind(mixed, ordinary)
n <- 543
data <- rbind(closeup[sample(nrow(closeup), n),], fragmentary[sample(nrow(fragmentary), n),], illustration[sample(nrow(illustration), n),], live, micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),], xylogical)
data[,'class'] <- 'other'
data <- rbind(data, unpressed)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: UNPRESSED
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-unpressed-5k.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
100*mean(y_pred == test[,1]) ### accuracy
# [1] 97.35272


### SVM PREDICT: CLOSEUP
load('vector-closeup-3k.RData')
for (k in LOOP){
	y_pred <- predict(classifier, newdata = unknown[(k-INCREMENT):k, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
	p <- attr(y_pred, 'probabilities')[,'closeup'] > P
	write.table(unknown[p, 'file'], file = 'vector-closeup-3k.txt', append = TRUE, quote = FALSE, sep = '\t', col.names = NA)
}

### SVM PREDICT: FRAGMENTARY
load('vector-fragmentary-4k.RData')
for (k in LOOP){
	y_pred <- predict(classifier, newdata = unknown[(k-INCREMENT):k, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
	p <- attr(y_pred, 'probabilities')[,'fragmentary'] > P
	write.table(unknown[p, 'file'], file = 'vector-fragmentary-4k.txt', append = TRUE, quote = FALSE, sep = '\t', col.names = NA)
}

### SVM PREDICT: UNPRESSED
load('vector-unpressed-5k.RData')
for (k in LOOP){
	y_pred <- predict(classifier, newdata = unknown[(k-INCREMENT):k, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
	p <- attr(y_pred, 'probabilities')[,'unpressed'] > P
	write.table(unknown[p, 'file'], file = 'vector-unpressed-5k.txt', append = TRUE, quote = FALSE, sep = '\t', col.names = NA)
}