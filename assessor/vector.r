### LIBRARIES
library(caTools)
library(e1071)
library(rminer)

### INIT
set.seed(123456789)

### DATA FILES
closeup <- read.csv('vector-closeup.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
color <- read.csv('vector-color.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
fragmentary <- read.csv('vector-fragmentary.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
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
unpressed <- read.csv('vector-unpressed.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
xylogical <- read.csv('vector-xylogical.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)

unknown <- read.csv('vector-all.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
save(unknown, file = 'vector-unknown.RData')


### DATA FORMAT: MICROGRAPH
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 100
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, micrograph)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: MICROGRAPH
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-micrograph.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#             y_pred
#              micrograph other
#   micrograph        199     2
#   other               3   197
100*mean(y_pred == test[,1]) ### accuracy
# [1] 98.75312


### DATA FORMAT: OCCLUDED
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 110
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, occluded)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: OCCLUDED
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-occluded.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#           y_pred
#            occluded other
#   occluded      211     8
#   other           7   213
100*mean(y_pred == test[,1]) ### accuracy
# [1] 96.58314


### DATA FORMAT: ILLUSTRATION
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 136
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
illustration[,'class'] <- 'illustration'
data <- rbind(data, illustration)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: ILLUSTRATION
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-illustration.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#               y_pred
#                illustration other
#   illustration          267     6
#   other                  20   252
100*mean(y_pred == test[,1]) ### accuracy
# [1] 95.22936


### DATA FORMAT: LIVE
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 69
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, live)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: LIVE
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-live.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#        y_pred
#         live other
#   live   131     5
#   other    0   138
100*mean(y_pred == test[,1]) ### accuracy
# [1] 98.17518


### DATA FORMAT: REPRODUCTION
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 88
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, reproduction)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: REPRODUCTION
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-reproduction.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#               y_pred
#                other reproduction
#   other          172           26
#   reproduction     7          191
100*mean(y_pred == test[,1]) ### accuracy
# [1] 91.66667


### DATA FORMAT: MIXED
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, ordinary)
n <- 92
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, mixed)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: MIXED
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-mixed.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#        y_pred
#         mixed other
#   mixed   195    11
#   other    14   193
100*mean(y_pred == test[,1]) ### accuracy
# [1] 93.94673


### DATA FORMAT: TEXT
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 136
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),])
data[,'class'] <- 'other'
data <- rbind(data, text)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: TEXT
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-text.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#        y_pred
#         other text
#   other   255   17
#   text      6  266
100*mean(y_pred == test[,1]) ### accuracy
# [1] 95.77206


### DATA FORMAT: SPIRIT
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 82
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, spirit)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: SPIRIT
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-spirit.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#         y_pred
#          other spirit
#   other    164      0
#   spirit     2    162
100*mean(y_pred == test[,1]) ### accuracy
# [1] 99.39024


### DATA FORMAT: XYLOGICAL
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 22
data <- rbind(closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),], unpressed[sample(nrow(unpressed), n),])
data[,'class'] <- 'other'
data <- rbind(data, xylogical)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: XYLOGICAL
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-xylogical.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#            y_pred
#             other xylogical
#   other        49         1
#   xylogical     0        50
100*mean(y_pred == test[,1]) ### accuracy
# [1] 99


### DATA FORMAT: FRAGMENTARY
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(mixed, ordinary)
n <- 70
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, fragmentary)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: FRAGMENTARY
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-fragmentary.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#              y_pred
#               fragmentary other
#   fragmentary         150     8
#   other                 8   150
100*mean(y_pred == test[,1]) ### accuracy
# [1] 94.93671


### DATA FORMAT: CLOSEUP
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 113
data <- rbind(bulk[sample(nrow(bulk), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, closeup)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: CLOSEUP
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-closeup.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#          y_pred
#           closeup other
#   closeup     207    19
#   other        21   205
100*mean(y_pred == test[,1]) ### accuracy
# [1] 91.15044


### DATA FORMAT: UNPRESSED
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 109
data <- rbind(closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),], xylogical[sample(nrow(xylogical), n),])
data[,'class'] <- 'other'
data <- rbind(data, unpressed)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: UNPRESSED
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-unpressed.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#            y_pred
#             other unpressed
#   other       237         8
#   unpressed     7       239
100*mean(y_pred == test[,1]) ### accuracy
# [1] 96.94501


### DATA FORMAT: SLIDES
bulk <- rbind(unpressed, xylogical)
illustration <- rbind(color, gray)
sheets <- rbind(fragmentary, mixed, ordinary)
n <- 57
data <- rbind(bulk[sample(nrow(bulk), n),], closeup[sample(nrow(closeup), n),], illustration[sample(nrow(illustration), n),], live[sample(nrow(live), n),], micrograph[sample(nrow(micrograph), n),], occluded[sample(nrow(occluded), n),], sheets[sample(nrow(sheets), n),], spirit[sample(nrow(spirit), n),], text[sample(nrow(text), n),])
data[,'class'] <- 'other'
data <- rbind(data, slide)
data[,'class'] <- as.factor(data[,'class'])
data <- data[, !(names(data) %in% c('model', 'file'))]
split <- sample.split(data$class, SplitRatio = 0.75)
train <- subset(data, split == TRUE)
test <- subset(data, split == FALSE)

### SVM MODEL: SLIDES
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid', probability = TRUE)
save(classifier, file = 'vector-slide.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#        y_pred
#         other slide
#   other   128     0
#   slide     0   128
100*mean(y_pred == test[,1]) ### accuracy
# [1] 100



### SVM PREDICT: MICROGRAPH
load('vector-micrograph.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'micrograph'] > 0.55
sum(p)/length(p) 
# [1] 0.002954642
sum(p)
# [1] 2007
write.table(unknown[p, 'file'], file = 'vector-micrograph.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: OCCLUDED
load('vector-occluded.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'occluded'] > 0.85
sum(p)/length(p) 
# [1] 0.005847454
sum(p)
# [1] 3972
write.table(unknown[p, 'file'], file = 'vector-occluded.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: ILLUSTRATION
load('vector-illustration.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'illustration'] > 0.98
sum(p)/length(p) 
# [1] 0.007178294
sum(p)
# [1] 4876
write.table(unknown[p, 'file'], file = 'vector-illustration.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: LIVE
load('vector-live.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'live'] > 0.65
sum(p)/length(p) 
# [1] 0.007095853
sum(p)
# [1] 4820
write.table(unknown[p, 'file'], file = 'vector-live.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: REPRODUCTION
load('vector-reproduction.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'reproduction'] > 0.999
sum(p)/length(p) 
# [1] 0.007434452
sum(p)
# [1] 5050
write.table(unknown[p, 'file'], file = 'vector-reproduction.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: MIXED
load('vector-mixed.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'mixed'] > 0.99
sum(p)/length(p) 
# [1] 0.04043753
sum(p)
# [1] 27468
write.table(unknown[p, 'file'], file = 'vector-mixed.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: TEXT
load('vector-text.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'text'] > 0.75
sum(p)/length(p) 
# [1] 0.006792586
sum(p)
# [1] 4614
write.table(unknown[p, 'file'], file = 'vector-text.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: SPIRIT
load('vector-spirit.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'spirit'] > 0.5
sum(p)/length(p) 
# [1] 0.001111487
sum(p)
# [1] 755
write.table(unknown[p, 'file'], file = 'vector-spirit.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: XYLOGICAL
load('vector-xylogical.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'xylogical'] > 0.5
sum(p)/length(p) 
# [1] 0.002571879
sum(p)
# [1] 1747
write.table(unknown[p, 'file'], file = 'vector-xylogical.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: FRAGMENTARY
load('vector-fragmentary.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'fragmentary'] > 0.99
sum(p)/length(p) 
# [1] 0.003743725
sum(p)
# [1] 2543
write.table(unknown[p, 'file'], file = 'vector-fragmentary.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: CLOSEUP
load('vector-closeup.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'closeup'] > 0.98
sum(p)/length(p) 
# [1] 0.005245337
sum(p)
# [1] 3563
write.table(unknown[p, 'file'], file = 'vector-closeup.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: UNPRESSED
load('vector-unpressed.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'unpressed'] > 0.95
sum(p)/length(p) 
# [1] 0.007647916
sum(p)
# [1] 5195
write.table(unknown[p, 'file'], file = 'vector-unpressed.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: SLIDE
load('vector-slide.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'slide'] > 0.5
sum(p)/length(p) 
# [1] 0.00684264
sum(p)
# [1] 4648
write.table(unknown[p, 'file'], file = 'vector-slide.txt', quote = FALSE, sep = '\t', col.names = NA)
