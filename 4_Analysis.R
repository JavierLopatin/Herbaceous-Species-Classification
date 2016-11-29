################################################################################
## R-Script - 4_Analysis.R                                                    ##
## author: Javier Lopatin                                                     ##
## mail: javierlopatin@gmail.com                                              ##  
##                                                                            ##
## Manuscript: Hyperspectral classification of grassland species: towards an  ##
## application for semi-automatic field surveys                               ##
##                                                                            ##
## description: Analysis of the canopy-level classification results           ## 
##                                                                            ##
################################################################################

home = "C:/Users/Lopatin/Dropbox/PhD/Grass_single_spp_segmentation/Single_spp"
rasterDir = "D:/Sp_Images"

setwd(home)

load("Analysis.RData")
load("outputGOF.RData")
load("potVal_cover.RData")
load("rf_cover.RData")

#### Source Functions from GitHub
source_github <- function(u) {
  # load package
  require(RCurl)
  # read script lines from website and evaluate
  script <- getURL(u, ssl.verifypeer = FALSE)
  eval(parse(text = script), envir=.GlobalEnv)
  detach("package:RCurl", unload=TRUE)
} 
source_github("https://raw.githubusercontent.com/JavierLopatin/Herbaceous-Species-Classification/master/Scripts/0_Functions.R")

## load the data
fit_potVal <-  read.table("Data/Fits_potVal.csv", sep = ",", header = T)
fit_rf     <-  read.table("Data/Fits_rf.csv", sep = ",", header = T)

## Obtain cover fits
setwd(rasterDir)

potVal_cover <- coverSummary("potVal")
rf_cover     <- coverSummary("rf")

potVal_cover$Species <- factor(potVal_cover$Species)
rf_cover$Species     <- factor(rf_cover$Species)

setwd(home)

save(potVal_cover, file="potVal_cover.RData")
save(rf_cover,     file="rf_cover.RData")

# Obtain R2, RMSE and Bias per species
gof_pv <- GOF(potVal_cover)
gof_rf <- GOF(rf_cover)

# erase empty "Species"
# gof_pv <- gof_pv[- seq(1,24,1),]
# gof_rf <- gof_rf[- seq(1,24,1),]

save(gof_pv, file="gof_pv.RData")
save(gof_rf, file="gof_rf.RData")

# get GOF per model/tag
#x = grep("potVal", outputGOF$Validation)
#gof_pv <- outputGOF[x, ]

#x = grep("rf", outputGOF$Validation)
#gof_rf <- outputGOF[x, ]

##################################
### Best model: rf SVM Spectra ###
##################################

x = grep("SVM", rf_cover$Model)
y <- rf_cover[x, ] 

x = grep("spectra", y$Normalization)
bestModel <- y[x, ]

x = grep("rf", outputGOF$Validation)
y <- outputGOF[x, ] 

x = grep("SVM", y$Models)
y <- y[x, ] 

x = grep("spectra", y$Normalization)
gof_best <- y[x, ]

# count for well, miss and over classifications
bestModel <- ClassPresence(bestModel)


###############################################
### Best model user and producer accuracies ###
###############################################

lis <- list.files("bestPA_UA", pattern = ".txt")

median_PA_UA <- data.frame( Species=character(), PA=double(), UA=double() )

for (i in 1:length(lis)){
  x <- read.table( paste0( "bestPA_UA/", lis[i]) , header = T)
  y <- data.frame(Species=x$Species, PA=x$PA_RF, UA=x$OA_RF)
  if (length( median_PA_UA[,1] ) == 0){
    median_PA_UA <- y
  } else {
    median_PA_UA <- merge(median_PA_UA, y, by = intersect(names(median_PA_UA), names(y)), all = TRUE)
  }
}

# merge species
median_PA_UA <- mergeSpecies(median_PA_UA)

# get the median value per specie
dummy_matrix <- matrix( ncol = ncol(median_PA_UA), nrow = length( unique(median_PA_UA$Species) ) )
colnames(dummy_matrix) <- colnames(median_PA_UA)
dummy_matrix[,1] <- as.character( unique(median_PA_UA$Species) )

for (i in 1:length(unique(median_PA_UA$Species))){#(levelsNumber-1)
  x = grep( unique(median_PA_UA$Species)[i], median_PA_UA$Species )
  sp = median_PA_UA[x, ]
  pa =  sp$PA 
  ua = sp$UA 
  pa_med = median(pa) 
  ua_med = median(ua)
  dummy_matrix[i,2] <- as.numeric(pa_med)
  dummy_matrix[i,3] <- as.numeric(ua_med)
}

median_PA_UA <- as.data.frame(dummy_matrix)
median_PA_UA$PA <- as.numeric( as.character(median_PA_UA$PA) )
median_PA_UA$UA <- as.numeric( as.character(median_PA_UA$UA) )

graminoids <- subset(median_PA_UA, Species == "Grass_sp9" | Species == "Nardus_stricta" 
                               | Species == "Grass_Sp_23"   | Species == "Setaria_pumila" 
                               | Species == "Elymus_repens" | Species == "Echinochloa_crus-galli"
                               | Species == "Panicum_capillare")
graminoids$PFT <- "graminods"

fobs <- subset(median_PA_UA, Species == "Prunella_vulgaris" | Species == "Sp_2" 
                         | Species == "Hypochaeris_radicata" | Species == "Trifolium_pratense" 
                         | Species == "Trifolium_repens" | Species == "Conyza_canadensis" 
                         | Species == "Potentilla_reptans" | Species == "Taraxacum_officinale" 
                         | Species == "Galium_sp" | Species == "Bellis_perennis" 
                         | Species == "Glechoma_hederacea" | Species == "Medicago_lupulina" 
                         | Species == "Minuartia_hybrida" | Species == "Plantago_lancelota" 
                         | Species == "Geranium_pusillum" | Species == "Plantago_major" 
                         | Species == "Potentilla_2" | Species == "Achillea_millefolium"
                         | Species == "Oxalis_stricta" | Species == "Medicago_arabica" 
                         | Species == "Echium_vulgare" | Species == "Erigoron_annuus" 
                         | Species == "Senecio_vulgaris" | Species == "Filago_arvensis" 
                         | Species == "Anagallis_arvensis" | Species == "Daucum_carota" 
                         | Species == "Medicago_sativa " | Species == "Rumex_obtusifolius" 
                         | Species == "Convolvulus_sepium" | Species == "Verbena_officinalis" 
                         | Species == "Urtica_dioica" | Species == "Cichorium_intybus" 
                         | Species == "Solidago_gigantea" | Species == "Polygonum_persicaria" 
                         | Species == "Oenothera_biennis" | Species == "Arthemisia_vulgaris" 
                         | Species == "Anthemis_arvensis" | Species == "Crepis_capillaris")
fobs$PFT <- "fobs"

bryophytes <- subset(median_PA_UA, Species == "Brachythecium_sp")
bryophytes$PFT <- "bryophytes"

median_PA_UA <- rbind(bryophytes, graminoids, fobs)

write.table(median_PA_UA, file = "median_PA_UA.csv", sep = ",", col.names = T, row.names = F)

###########################
### Variable importance ###
###########################

library(vegan)

mat_mrpp = matrix(NA, ncol=61, nrow=2)
for(i in 1:61){
  #dat <- data.frame(sp=rf_spec_BN$Species, rf_spec_BN[,i+2])
  #SAM <- designdist(dat, "acos( J / ( (A*0.5) * (B*0.5) ) )", terms = "quadratic")
  #obj_mrpp = mrpp(dat = SAM, grouping = classes, parallel = 16)
  obj_mrpp = mrpp(dat = rf_spec_BN[, 3:length(rf_spec_BN[1,])][i], 
                  grouping = rf_spec_BN$Species, parallel = 16, distance = "mahalanobis")
  mat_mrpp[1,i] = obj_mrpp$A
  mat_mrpp[2,i] = obj_mrpp$Pvalue
}

save(mat_mrpp, file = "bestImp.RData")

### Growth forms
graminoids_varImport <- subset(rf_spec_BN, Species == "Grass_sp9" | Species == "Nardus_stricta" 
                     | Species == "Grass_Sp_23"   | Species == "Setaria_pumila" 
                     | Species == "Elymus_repens" | Species == "Echinochloa_crus-galli"
                     | Species == "Panicum_capillare")

forbs_varImport <- subset(rf_spec_BN, Species == "Prunella_vulgaris" | Species == "Sp_2" 
               | Species == "Hypochaeris_radicata" | Species == "Trifolium_pratense" 
               | Species == "Trifolium_repens" | Species == "Conyza_canadensis" 
               | Species == "Potentilla_reptans" | Species == "Taraxacum_officinale" 
               | Species == "Galium_sp" | Species == "Bellis perennis" 
               | Species == "Glechoma_hederacea" | Species == "Medicago_lupulina" 
               | Species == "Minuartia_hybrida" | Species == "Plantago_lancelota" 
               | Species == "Geranium_pusillum" | Species == "Plantago_major" 
               | Species == "Potentilla_2" | Species == "Achillea_millefolium"
               | Species == "Oxalis_stricta" | Species == "Medicago_arabica" 
               | Species == "Echium_vulgare" | Species == "Erigoron_annuus" 
               | Species == "Senecio_vulgaris" | Species == "Filago_arvensis" 
               | Species == "Anagallis_arvensis" | Species == "Daucum_carota" 
               | Species == "Medicago_sativa " | Species == "Rumex_obtusifolius" 
               | Species == "Convolvulus_sepium" | Species == "Verbena_officinalis" 
               | Species == "Urtica_dioica" | Species == "Cichorium_intybus" 
               | Species == "Solidago_gigantea" | Species == "Polygonum_persicaria" 
               | Species == "Oenothera_biennis" | Species == "Arthemisia_vulgaris" 
               | Species == "Anthemis_arvensis")

# graminoids
gram_mrpp = matrix(NA, ncol=61, nrow=2)
for(i in 1:61){
  #SAM <- designdist(spectra, "acos( J / ( (A*0.5) * (B*0.5) ) )")
  #obj_mrpp = mrpp(dat = SAM, grouping = classes, parallel = 16)
  obj_mrpp = mrpp(dat = graminoids_varImport[, 3:(length(graminoids_varImport[1,])-1 )][i], 
                  grouping = graminoids_varImport$Species, parallel = 16, distance = "mahalanobis")
  gram_mrpp[1,i] = obj_mrpp$A
  gram_mrpp[2,i] = obj_mrpp$Pvalue
}

save(gram_mrpp, file = "Gramm_Imp.RData")

# forbs
forbs_mrpp = matrix(NA, ncol=61, nrow=2)
for(i in 1:61){
  #SAM <- designdist(spectra, "acos( J / ( (A*0.5) * (B*0.5) ) )", terms = "quadratic")
  #obj_mrpp = mrpp(dat = SAM, grouping = classes, parallel = 16)
  obj_mrpp = mrpp(dat = forbs_varImport[, 3:length(forbs_varImport[1,])][i], 
                  grouping = forbs_varImport$Species, parallel = 16, distance = "mahalanobis")
  forbs_mrpp[1,i] = obj_mrpp$A
  forbs_mrpp[2,i] = obj_mrpp$Pvalue
}

save(frobs_mrpp, file = "Fobs_Imp.RData")

plot (wl, mat_mrpp[1,], type="l", main="mrpp", ylim=c(0,0.5))
lines(wl, gram_mrpp[1,], type="l", lty=2, col="blue")
lines(wl, forbs_mrpp[1,], type="l", lty=3, col="red")


##############################################
### Analysis of architectural complexities ###
##############################################

# evenness
library(fuzzySim)

plotsxx <- unique(bestModel$Plot)
evenness <- matrix(ncol = 11, nrow = 1 )
colnames(evenness) <- paste0( rep("plot_", nrow(classes)), plotsxx )  

for (i in 1:11){
  # subset plot
  plot = bestModel[bestModel$Plot == plotsxx[i], ]
  # convert species list
  classes <- splist2presabs(plot, sites.col = "Plot", sp.col = "Species", keep.n = T)
  # estimate evennes
  evenness[,i] = unlist( camargo( classes[ ,3:length(classes)] ) )
} 

# cover per plot
x = bestModel
x$Observed[x$Observed == 0] <- NA

tapply(x$Observed, x$Plot, summary)

###

x = grep(paste0(c(18,19), collapse="|"), bestModel$Plot)
complex1 <- bestModel[x, ]

x = grep(paste0(c(13,14), collapse="|"), bestModel$Plot)
complex2 <- bestModel[x, ]

x = grep(paste0(c(9,10,11,12), collapse="|"), bestModel$Plot)
complex3 <- bestModel[x, ]

x = grep(paste0(c(15,16,17), collapse="|"), bestModel$Plot)
complex4 <- bestModel[x, ]

complex1$complex <- 1
complex2$complex <- 2
complex3$complex <- 3
complex4$complex <- 4

complex_all <- rbind(complex1, complex2, complex3, complex4)

gof_1 <- GOFbest(complex1)
gof_1$complex <- "complex1"
gof_2 <- GOFbest(complex2)
gof_2$complex <- "complex2"
gof_3 <- GOFbest(complex3)
gof_3$complex <- "complex3"
gof_4 <- GOFbest(complex4)
gof_4$complex <- "complex4"

gof_complex <- rbind(gof_1, gof_2, gof_3, gof_4)

#####################################
### analysis per cover percentage ###
#####################################

cov1 <- bestModel[bestModel$Observed < 20, ]
cov2 <- bestModel[bestModel$Observed >= 20 & bestModel$Observed < 40, ]
cov3 <- bestModel[bestModel$Observed >= 40 & bestModel$Observed < 60, ]
cov4 <- bestModel[bestModel$Observed >= 60 & bestModel$Observed < 80, ]
cov5 <- bestModel[bestModel$Observed >= 80 & bestModel$Observed < 100, ]

gof_cov1 <- GOFbest(cov1)
gof_cov2 <- GOFbest(cov2)
gof_cov3 <- GOFbest(cov3)
gof_cov4 <- GOFbest(cov4)
gof_cov5 <- GOFbest(cov5)

gof_cov1$CoverRange <- "0-20"
gof_cov2$CoverRange <- "20-40"
gof_cov3$CoverRange <- "40-60"
gof_cov4$CoverRange <- "60-80"
gof_cov5$CoverRange <- "80-100"

gof_cover <- rbind(gof_cov1, gof_cov2, gof_cov3, gof_cov4, gof_cov5)

save.image("Analysis.RData")

#################################
### Analysis per growth forms ###
#################################

graminoids <- subset(gof_rf, Species == "Grass_sp9" | Species == "Nardus_stricta" 
                     | Species == "Grass_Sp_23" | Species == "Setaria_pumila" 
                     | Species == "Elymus_repens" | Species == "Echinochloa_crus-galli"
                     | Species == "Panicum_capillare")

fobs <- subset(gof_rf, Species == "Prunella_vulgaris" | Species == "Sp_2" 
               | Species == "Hypochaeris_radicata" | Species == "Trifolium_pratense" 
               | Species == "Trifolium_repens" | Species == "Conyza_canadensis" 
               | Species == "Potentilla_reptans" | Species == "Taraxacum_officinale" 
               | Species == "Galium_sp" | Species == "Bellis perennis" 
               | Species == "Glechoma_hederacea" | Species == "Medicago_lupulina" 
               | Species == "Minuartia_hybrida" | Species == "Plantago_lancelota" 
               | Species == "Geranium_pusillum" | Species == "Plantago_major" 
               | Species == "Potentilla_2" | Species == "Achillea_millefolium"
               | Species == "Oxalis_stricta" | Species == "Medicago_arabica" 
               | Species == "Echium_vulgare" | Species == "Erigoron_annuus" 
               | Species == "Senecio_vulgaris" | Species == "Filago_arvensis" 
               | Species == "Anagallis_arvensis" | Species == "Daucum_carota" 
               | Species == "Medicago_sativa " | Species == "Rumex_obtusifolius" 
               | Species == "Convolvulus_sepium" | Species == "Verbena_officinalis" 
               | Species == "Urtica_dioica" | Species == "Cichorium_intybus" 
               | Species == "Solidago_gigantea" | Species == "Polygonum_persicaria" 
               | Species == "Oenothera_biennis" | Species == "Arthemisia_vulgaris" 
               | Species == "Anthemis_arvensis")

bryophytes <-  subset(gof_rf, Species == "Brachythecium_sp")


graminoids$PFT <- "Graminoids"
fobs$PFT <- "Fobs"
bryophytes$PFT <- "Bryophytes"

PFT <- rbind(graminoids, fobs, bryophytes)


###############################
### Analysis of resolutions ###
###############################

setwd(rasterDir)

## load the data
rf_spec <- read.table("Data/rf_spec.csv", sep = ",", header = T)

# load species cover dataset
species <- read.table("Data/Plots_Species.csv", header = T, sep=",")

## load plot images 
# resample done with gdal_translate, as: 
# Windows --> for %i in (*.tif) do gdal_translate -tr 2 2 %i 2/%i 
# Linux   --> FILES=inPath/*tif
#             for f in $FILES
#             do
#               gdal_translate gdal_translate -tr 2 2 ${f} 2/${f}
#             done

## Obtain the spectras for each resolution using the ExtractValues.py code
## load the spectras
res2  <- read.table("Plots/resolution/res2.csv", header = T, sep=",")
res4  <- read.table("Plots/resolution/res4.csv", header = T, sep=",")
res6  <- read.table("Plots/resolution/res6.csv", header = T, sep=",")
res8  <- read.table("Plots/resolution/res8.csv", header = T, sep=",")
res10 <- read.table("Plots/resolution/res10.csv", header = T, sep=",")
res12 <- read.table("Plots/resolution/res12.csv", header = T, sep=",")

# load rasters
raster2 <- rasterList(fileExtantion = ".tif", folder = "Plots/resolution_analysis/2", dir=rasterDir)
raster4 <- rasterList(fileExtantion = ".tif", folder = "Plots/resolution_analysis/4", dir=rasterDir)
raster6 <- rasterList(fileExtantion = ".tif", folder = "Plots/resolution_analysis/6", dir=rasterDir)
raster8 <- rasterList(fileExtantion = ".tif", folder = "Plots/resolution_analysis/8", dir=rasterDir)
raster10 <- rasterList(fileExtantion = ".tif", folder = "Plots/resolution_analysis/10", dir=rasterDir)
raster12 <- rasterList(fileExtantion = ".tif", folder = "Plots/resolution_analysis/12", dir=rasterDir)

## apply parameter tuning
tun2 <- tunningModels(classes = Species, 
                      spectra = res2[, 3:length( res2 )], 
                      wl=wl)
tun4 <- tunningModels(classes = Species, 
                      spectra = res4[, 3:length( res4 )], 
                      wl=wl)
tun6 <- tunningModels(classes = Species, 
                      spectra = res6[, 3:length( res6 )], 
                      wl=wl)
tun8 <- tunningModels(classes = Species, 
                      spectra = res8[, 3:length( res8 )], 
                      wl=wl)
tun10 <- tunningModels(classes = Species, 
                      spectra = res10[, 3:length( res10 )], 
                      wl=wl)
tun12 <- tunningModels(classes = Species, 
                      spectra = res12[, 3:length( res22 )], 
                      wl=wl)

## apply bootstrap classification
BootsClassificationBest(classes = Species, 
                        spectra = res2[, 3:length( res2 )],
                        en = tun2, 
                        raster = raster2, 
                        boots = 10, 
                        outDir = file.path(rasterDir, "Plots/resolution/res2"), 
                        modelTag = res2,
                        plotName = plot_name)
BootsClassificationBest(classes = Species, 
                        spectra = res4[, 3:length( res4 )],
                        en = tun4, 
                        raster = raster4, 
                        boots = 10, 
                        outDir = file.path(rasterDir, "Plots/resolution/res4"), 
                        modelTag = res4,
                        plotName = plot_name)
BootsClassificationBest(classes = Species, 
                        spectra = res6[, 3:length( res6 )],
                        en = tun6, 
                        raster = raster6, 
                        boots = 10, 
                        outDir = file.path(rasterDir, "Plots/resolution/res6"), 
                        modelTag = res6,
                        plotName = plot_name)
BootsClassificationBest(classes = Species, 
                        spectra = res2[, 3:length( res2 )],
                        en = tun8, 
                        raster = raster8, 
                        boots = 10, 
                        outDir = file.path(rasterDir, "Plots/resolution/res8"), 
                        modelTag = res8,
                        plotName = plot_name)
BootsClassificationBest(classes = Species, 
                        spectra = res10[, 3:length( res10 )],
                        en = tun10, 
                        raster = raster10, 
                        boots = 10, 
                        outDir = file.path(rasterDir, "Plots/resolution/res10"), 
                        modelTag = res10,
                        plotName = plot_name)
BootsClassificationBest(classes = Species, 
                        spectra = res12[, 3:length( res12 )],
                        en = tun2, 
                        raster = raster12, 
                        boots = 10, 
                        outDir = file.path(rasterDir, "Plots/resolution/res12"), 
                        modelTag = res12,
                        plotName = plot_name)

### obtain cover predictions
obstainCovers(ObservedSpecies = valData, 
                  rasterDir = file.path(rasterDir, "Plots/resolution/res2"),
                  subplotDir = subplotDir, 
                  shpMaskName = plot_name, 
                  plotNumber = plot, 
                  Iter = boots,
                  algorithm = "SVM")
obstainCovers(ObservedSpecies = valData, 
                  rasterDir = file.path(rasterDir, "Plots/resolution/res4"),
                  subplotDir = subplotDir, 
                  shpMaskName = plot_name, 
                  plotNumber = plot, 
                  Iter = boots,
                  algorithm = "SVM")
obstainCovers(ObservedSpecies = valData, 
                  rasterDir = file.path(rasterDir, "Plots/resolution/res6"),
                  subplotDir = subplotDir, 
                  shpMaskName = plot_name, 
                  plotNumber = plot, 
                  Iter = boots,
                  algorithm = "SVM")
obstainCovers(ObservedSpecies = valData, 
                  rasterDir = file.path(rasterDir, "Plots/resolution/res8"),
                  subplotDir = subplotDir, 
                  shpMaskName = plot_name, 
                  plotNumber = plot, 
                  Iter = boots,
                  algorithm = "SVM")
obstainCovers(ObservedSpecies = valData, 
                  rasterDir = file.path(rasterDir, "Plots/resolution/res10"),
                  subplotDir = subplotDir, 
                  shpMaskName = plot_name, 
                  plotNumber = plot, 
                  Iter = boots,
                  algorithm = "SVM")
obstainCovers(ObservedSpecies = valData, 
                  rasterDir = file.path(rasterDir, "Plots/resolution/res12"),
                  subplotDir = subplotDir, 
                  shpMaskName = plot_name, 
                  plotNumber = plot, 
                  Iter = boots,
                  algorithm = "SVM")

### Estimate prediction accuracies
gof_res2 <-  GOFbest(read.table(file.path(rasterDir, "Plots/resolution/res2.txt"), heather = T))
gof_res4 <-  GOFbest(read.table(file.path(rasterDir, "Plots/resolution/res4.txt"), heather = T))
gof_res6 <-  GOFbest(read.table(file.path(rasterDir, "Plots/resolution/res6.txt"), heather = T))
gof_res8 <-  GOFbest(read.table(file.path(rasterDir, "Plots/resolution/res8.txt"), heather = T))
gof_res10 <- GOFbest(read.table(file.path(rasterDir, "Plots/resolution/res10.txt"), heather = T))
gof_res12 <- GOFbest(read.table(file.path(rasterDir, "Plots/resolution/res12.txt"), heather = T))

gof_res2$Resolution <- 0.6
gof_res4$Resolution <- 1.2
gof_res6$Resolution <- 1.8
gof_res8$Resolution <- 2.4
gof_res10$Resolution <- 3
gof_res12$Resolution <- 3.6

gof_resolution <- rbind(gof_res1, gof_res2, gof_res4, gof_res6,
                        gof_res8, gof_res10, gof_res12)

save.image("Analysis.RData")