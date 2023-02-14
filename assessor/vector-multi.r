### LIBRARIES
library(caTools)
library(e1071)
library(rminer)



### DATA FILES
unknown <- read.csv('vector-multi.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
save(unknown, file = 'vector-multi.RData')
# load('vector-multi.RData')



### SVM PREDICT: MICROGRAPH
load('vector-micrograph.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'micrograph'] > 0.55
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-micrograph-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: OCCLUDED
load('vector-occluded.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'occluded'] > 0.85
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-occluded-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: ILLUSTRATION
load('vector-illustration.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'illustration'] > 0.98
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-illustration-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: LIVE
load('vector-live.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'live'] > 0.65
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-live-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: REPRODUCTION
load('vector-reproduction.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'reproduction'] > 0.999
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-reproduction-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: MIXED
load('vector-mixed.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'mixed'] > 0.99
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-mixed-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: TEXT
load('vector-text.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'text'] > 0.75
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-text-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: SPIRIT
load('vector-spirit.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'spirit'] > 0.5
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-spirit-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: XYLOGICAL
load('vector-xylogical.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'xylogical'] > 0.5
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-xylogical-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: FRAGMENTARY
load('vector-fragmentary.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'fragmentary'] > 0.99
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-fragmentary-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: CLOSEUP
load('vector-closeup.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'closeup'] > 0.98
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-closeup-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: UNPRESSED
load('vector-unpressed.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'unpressed'] > 0.95
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-unpressed-multi.txt', quote = FALSE, sep = '\t', col.names = NA)

### SVM PREDICT: SLIDE
load('vector-slide.RData')
y_pred <- predict(classifier, newdata = unknown[, !(names(unknown) %in% c('class', 'model', 'file'))], decision.values = TRUE, probability = TRUE)
p <- attr(y_pred, 'probabilities')[,'slide'] > 0.5
sum(p)/length(p) 
sum(p)
write.table(unknown[p, 'file'], file = 'vector-slide-multi.txt', quote = FALSE, sep = '\t', col.names = NA)
