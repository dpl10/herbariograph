### LIBRARIES
library(MASS)
### FUNCTION
ty.lda <- function(x, groups){ ### https://stackoverflow.com/questions/5629550/classification-functions-in-linear-discriminant-analysis-in-r
	x.lda <- lda(groups ~ ., as.data.frame(x))
	gr <- length(unique(groups)) ### groups might be factors or numeric
	v <- ncol(x) ### variables
	m <- x.lda$means ### group means
	w <- array(NA, dim = c(v, v, gr))
	for(i in 1:gr){
		tmp <- scale(subset(x, groups == unique(groups)[i]), scale = FALSE)
		w[,,i] <- t(tmp) %*% tmp
	}
	W <- w[,,1]
	for(i in 2:gr)
		W <- W + w[,,i]
	V <- W/(nrow(x) - gr)
	iV <- solve(V)
	class.funs <- matrix(NA, nrow = v + 1, ncol = gr)
	colnames(class.funs) <- paste("group", 1:gr, sep=".")
	rownames(class.funs) <- c("constant", paste("var", 1:v, sep = "."))
	for(i in 1:gr) {
		class.funs[1, i] <- -0.5 * t(m[i,]) %*% iV %*% (m[i,])
		class.funs[2:(v+1) ,i] <- iV %*% (m[i,])
	}
	x.lda$class.funs <- class.funs
	return(x.lda)
}
### DATA
x <- read.csv('test-fuzz.tsv', header = TRUE, sep = '\t', quote = '', dec = '.', check.names = FALSE)
### MASS STYLE (+ == 1; - == 0)
x[x['type']=='color','type'] <- 1
x[x['type']=='gray','type'] <- -1
dfa <- ty.lda(x[,c('r', 'g', 'b')], strtoi(x[,'type']))
dfa$class.funs
#             group.1   group.2
# constant  -1.462459 -10.27471
# var.1    -14.136089 -77.86728
# var.2     12.429549 320.70587
# var.3     38.943431 -49.63974
p <- dfa$class.funs[1,2]+(dfa$class.funs[2,2]*x[,'r'])+(dfa$class.funs[3,2]*x[,'g'])+(dfa$class.funs[4,2]*x[,'b'])
p < 2
# == 90% correct
