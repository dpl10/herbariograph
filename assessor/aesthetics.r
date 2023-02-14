### LIBRARIES
library(caTools)
library(e1071)
library(rminer)

### DATA
x <- read.csv('aesthetic-scores.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
x[,'class'] <- as.factor(x[,'class'])
x <- x[,c('class', 'color0', 'color1', 'composition0', 'composition1', 'composition2', 'composition3', 'composition4', 'composition5', 'composition6', 'composition7', 'composition8', 'composition9', 'dof0', 'dof1', 'palette0', 'palette1', 'palette2', 'palette3', 'palette4', 'palette5', 'palette6', 'palette7', 'palette8', 'palette9', 'palette10', 'palette11', 'palette12', 'type0', 'type1', 'type2', 'type3', 'type4', 'type5', 'type6', 'type7', 'type8', 'type9', 'type10', 'type11', 'type12', 'type13', 'type14', 'type15', 'type16', 'type17', 'type18', 'type19', 'type20')]
set.seed(123456789)
split <- sample.split(x$class, SplitRatio = 0.75)
train <- subset(x, split == TRUE)
test <- subset(x, split == FALSE)

### SVM MODEL
classifier = svm(formula = class ~ ., data = train, type = 'C-classification', kernel = 'sigmoid')
save(classifier, file = 'aesthetic-svm.RData')
y_pred <- predict(classifier, newdata = test[,-1])
cm <- table(test[,1], y_pred)
#           y_pred
#            ordinary pleasing
#   ordinary       76        7
#   pleasing       10       73
100*mean(y_pred==test[,1]) ### accuracy
# [1] 89.75904
M <- fit(class ~ ., data = train, model = 'svm', kpar = list(sigma = 0.10), C = 2)
svm.imp <- Importance(M, data = train)
svm.imp$value
#  [1] 0.00000000 0.39944955 0.39221646 0.34357238 0.07671367 0.12767544
#  [7] 0.29730522 0.28853628 0.09493318 0.18221513 0.12277799 0.22350257
# [13] 0.20705256 0.05549356 0.21630882 0.12012495 0.16530112 0.23758329
# [19] 0.08859436 0.18151539 0.21790608 0.27981898 0.09155628 0.21493366
# [25] 0.31098442 0.18762584 0.14048456 0.21931834 0.15885078 0.38952425
# [31] 0.25670101 0.13908360 0.14755846 0.14797835 0.26504976 0.15211015
# [37] 0.16110374 0.16878015 0.21462353 0.25842253 0.14947891 0.19801985
# [43] 0.12065376 0.12476928 0.13766524 0.14069920 0.18225325 0.18808449
# [49] 0.13595997
svm.imp$value > mean(svm.imp$value)+(1*sd(svm.imp$value))
#  [1] FALSE  TRUE  TRUE  TRUE FALSE FALSE  TRUE  TRUE FALSE FALSE FALSE FALSE
# [13] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE FALSE FALSE
# [25]  TRUE FALSE FALSE FALSE FALSE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE
# [37] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
# [49] FALSE
# color, composition, palette, type
svm.imp$value > mean(svm.imp$value)+(2*sd(svm.imp$value))
#  [1] FALSE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
# [13] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
# [25] FALSE FALSE FALSE FALSE FALSE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE
# [37] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
# [49] FALSE
### color, composition, type
### limiting to color, composition, type makes things worse

### SVM predict
y <- read.csv('all-specimen-aesthetics.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
y <- y[,c('file', 'color0', 'color1', 'composition0', 'composition1', 'composition2', 'composition3', 'composition4', 'composition5', 'composition6', 'composition7', 'composition8', 'composition9', 'dof0', 'dof1', 'palette0', 'palette1', 'palette2', 'palette3', 'palette4', 'palette5', 'palette6', 'palette7', 'palette8', 'palette9', 'palette10', 'palette11', 'palette12', 'type0', 'type1', 'type2', 'type3', 'type4', 'type5', 'type6', 'type7', 'type8', 'type9', 'type10', 'type11', 'type12', 'type13', 'type14', 'type15', 'type16', 'type17', 'type18', 'type19', 'type20')]
# load('aesthetic-svm.RData')
y_pred <- predict(classifier, newdata = y[,-1])
length(y_pred[y_pred=='pleasing'])/length(y_pred) 
# [1] 0.0420098
write.table(y[(y_pred=='pleasing'),'file'], file = 'all-specimen-aesthetic.txt', quote = FALSE, sep = '\t', col.names = NA)
