###################################################
### code chunk number 2: Covar_sec2_1_load-plankton-data
###################################################
fulldat = lakeWAplanktonTrans
years = fulldat[,"Year"]>=1965 & fulldat[,"Year"]<1975
dat = t(fulldat[years,c("Greens", "Bluegreens")])
the.mean = apply(dat,1,mean,na.rm=TRUE)
the.sigma = sqrt(apply(dat,1,var,na.rm=TRUE))
dat = (dat-the.mean)*(1/the.sigma)


###################################################
### code chunk number 3: Covar_sec2_2_z-score-covar-data
###################################################
covariates = rbind(
   Temp = fulldat[years,"Temp"],
   TP = fulldat[years,"TP"])
   
# z.score the covariates
the.mean = apply(covariates,1,mean,na.rm=TRUE)
the.sigma = sqrt(apply(covariates,1,var,na.rm=TRUE))
covariates = (covariates-the.mean)*(1/the.sigma)


###################################################
### code chunk number 4: Covar_sec2_3_plot-dat
###################################################
LWA <- ts(cbind(Year=fulldat[years,"Year"], t(dat), t(covariates)), start=c(1965,1), end=c(1974,12), freq=12)
plot.ts(LWA[,c("Greens","Bluegreens", "Temp", "TP")], main="", yax.flip=TRUE)


###################################################
### code chunk number 5: Covar_sec3_1_covar-model-0
###################################################
Q = U = x0 = "zero"; B = Z = "identity"
d = covariates
A = "zero"
D = "unconstrained"
y = dat # to show relationship between dat & the equation
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,D=D,d=d,x0=x0)
kem = MARSS(y, model=model.list)


###################################################
### code chunk number 6: Covar_sec4_1_covar-model-1
###################################################
R = A = U = "zero"; B = Z = "identity"
Q = "equalvarcov"
C = "unconstrained"
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,C=C,c=covariates)
kem = MARSS(dat, model=model.list)


###################################################
### code chunk number 7: Covar_sec4_2_covar-model-1c
###################################################
model.list$B = "diagonal and unequal"
kem = MARSS(dat, model=model.list)


###################################################
### code chunk number 8: Covar_sec4_3_covar-model-2
###################################################
x0 = dat[,1,drop=FALSE]
model.list$tinitx = 1
model.list$x0 = x0
kem = MARSS(dat, model=model.list)


###################################################
### code chunk number 9: Covar_sec5_1_covar-model-5
###################################################
D = d = A = U = "zero"; Z = "identity"
B = "diagonal and unequal"
Q = "equalvarcov"
C = "unconstrained"
c=covariates
R = diag(0.16,2)
x0 = "unequal"
tinitx=1
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,D=D,d=d,C=C,c=c,x0=x0,tinitx=tinitx)
kem = MARSS(dat, model=model.list)


###################################################
### code chunk number 10: Covar_sec5_1_covar-model-6
###################################################
C = c = A = U = "zero"; Z = "identity"
B = "diagonal and unequal"
Q = "equalvarcov"
D = "unconstrained"
d=covariates
R = diag(0.16,2)
x0 = "unequal"
tinitx=1
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,D=D,d=d,C=C,c=c,x0=x0,tinitx=tinitx)
kem = MARSS(dat, model=model.list)


###################################################
### code chunk number 11: Covar_sec6_01_set-up-seasonal-dat
###################################################
years = fulldat[,"Year"]>=1965 & fulldat[,"Year"]<1975
phytos = c("Diatoms", "Greens", "Bluegreens",
           "Unicells", "Other.algae")
dat = t(fulldat[years,phytos])

# z.score data because we changed the mean when we subsampled
the.mean = apply(dat,1,mean,na.rm=TRUE)
the.sigma = sqrt(apply(dat,1,var,na.rm=TRUE))
dat = (dat-the.mean)*(1/the.sigma)
# number of time periods/samples
TT = dim(dat)[2]


###################################################
### code chunk number 12: Covar_sec6_02_set-up-month-factors
###################################################
# number of "seasons" (e.g., 12 months per year)
period = 12
# first "season" (e.g., Jan = 1, July = 7)
per.1st = 1
# create factors for seasons
c.in = diag(period)
for(i in 2:(ceiling(TT/period))) {c.in = cbind(c.in,diag(period))}
# trim c.in to correct start & length
c.in = c.in[,(1:TT)+(per.1st-1)]
# better row names
rownames(c.in) = month.abb


###################################################
### code chunk number 13: Covar_sec6_03_C-constrained
###################################################
C = matrix(month.abb,5,12,byrow=TRUE)
C


###################################################
### code chunk number 14: Covar_sec6_04_C-constrained2
###################################################
C = "unconstrained"


###################################################
### code chunk number 15: Covar_sec6_05_month-factor-marss-params
###################################################
# Each taxon has unique density-dependence
B = "diagonal and unequal"
# Assume independent process errors
Q = "diagonal and unequal"
# We have demeaned the data & are fitting a mean-reverting model
# by estimating a diagonal B, thus
U = "zero"
# Each obs time series is associated with only one process
Z = "identity" 
# The data are demeaned & fluctuate around a mean
A = "zero" 
# We assume observation errors are independent, but they
# have similar variance due to similar collection methods
R = "diagonal and equal"
# We are not including covariate effects in the obs equation
D = "zero"
d = "zero"


###################################################
### code chunk number 16: Covar_sec6_06_fit-month-factor-with-MARSS
###################################################
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,C=C,c=c.in,D=D,d=d)
seas.mod.1 = MARSS(dat,model=model.list,control=list(maxit=1500))

# Get the estimated seasonal effects
# rows are taxa, cols are seasonal effects
seas.1 = coef(seas.mod.1,type="matrix")$C
rownames(seas.1) = phytos
colnames(seas.1) = month.abb


###################################################
### code chunk number 17: Covar_sec6_07_poly-month-factor
###################################################
# number of "seasons" (e.g., 12 months per year)
period = 12
# first "season" (e.g., Jan = 1, July = 7)
per.1st = 1
# order of polynomial
poly.order = 3
# create polynomials of months
month.cov = matrix(1,1,period)
for(i in 1:poly.order) {month.cov = rbind(month.cov,(1:12)^i)}
# our c matrix is month.cov replicated once for each year
c.m.poly = matrix(month.cov, poly.order+1, TT+period, byrow=FALSE)
# trim c.in to correct start & length
c.m.poly = c.m.poly[,(1:TT)+(per.1st-1)]

# Everything else remains the same as in the previous example
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,C=C,c=c.m.poly,D=D,d=d)
seas.mod.2 = MARSS(dat, model=model.list, control=list(maxit=1500))


###################################################
### code chunk number 18: Covar_sec6_08_seasonal-effect-poly
###################################################
C.2 = coef(seas.mod.2,type="matrix")$C
seas.2 = C.2 %*% month.cov
rownames(seas.2) = phytos
colnames(seas.2) = month.abb


###################################################
### code chunk number 19: Covar_sec6_09_seasonal-fourier
###################################################
cos.t = cos(2 * pi * seq(TT) / period)
sin.t = sin(2 * pi * seq(TT) / period)
c.Four = rbind(cos.t,sin.t)


###################################################
### code chunk number 20: Covar_sec6_10_seasonal-fourier-fit
###################################################
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,C=C,c=c.Four,D=D,d=d)
seas.mod.3 = MARSS(dat, model=model.list, control=list(maxit=1500))


###################################################
### code chunk number 21: Covar_sec6_11_seasonal-effects-fourier
###################################################
C.3 = coef(seas.mod.3, type="matrix")$C
# The time series of net seasonal effects
seas.3 = C.3 %*% c.Four[,1:period]
rownames(seas.3) = phytos
colnames(seas.3) = month.abb


###################################################
### code chunk number 22: Covar_sec6_12_plot-seas-effects
###################################################
par(mfrow=c(3,1), mar=c(2,4,2,2)) 
matplot(t(seas.1),type="l",bty="n",xaxt="n", ylab="Fixed monthly", col=1:5)
axis(1,labels=month.abb, at=1:12,las=2,cex.axis=0.75)
legend("topright", lty=1:5, legend=phytos, cex=0.6, col=1:5)

matplot(t(seas.2),type="l",bty="n",xaxt="n", ylab="Cubic", col=1:5)
axis(1,labels=month.abb, at=1:12,las=2,cex.axis=0.75)
legend("topright", lty=1:5, legend=phytos, cex=0.6, col=1:5)

matplot(t(seas.3),type="l",bty="n",xaxt="n",ylab="Fourier", col=1:5)
axis(1,labels=month.abb, at=1:12,las=2,cex.axis=0.75)
legend("topright", lty=1:5, legend=phytos, cex=0.6, col=1:5)


###################################################
### code chunk number 23: Covar_sec6_13_show-aics
###################################################
data.frame(Model=c("Fixed", "Cubic", "Fourier"),
           AICc=round(c(seas.mod.1$AICc,
                        seas.mod.2$AICc,
                        seas.mod.3$AICc),1))


###################################################
### code chunk number 24: Covar_sec7_01_diagnostic-code (eval = FALSE)
###################################################
## for(i in 1:3) {
##   dev.new()
##   modn = paste("seas.mod",i,sep=".")
##   for(j in 1:5) {
##     plot.ts(residuals(get(modn))$model.residuals[j,], 
##       ylab="Residual", main=phytos[j])
##     abline(h=0, lty="dashed")
##     acf(residuals(get(modn))$model.residuals[j,])
##     }
##   }


###################################################
### code chunk number 25: Covar_sec7_01_diagnostic-fig
###################################################
  i = 3; #Fourier
  j = 1; #First state
  par(mfrow=c(2,1))
  modn = paste("seas.mod",i,sep=".")
  plot.ts(residuals(get(modn))$model.residuals[j,], 
      ylab="Residual", main=phytos[j])
  abline(h=0, lty="dashed")
  acf(residuals(get(modn))$model.residuals[j,])



