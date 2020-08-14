
library(shiny)
library(vegawidget)
library(rjson)
library(data.table)
library(dplyr)
library(shinyjs)
library(DT)
#get a list of all the samples. the chr1 file should have all samples since it is the biggest. 
samples <-unique(fread("www/vega_bedpes/1_all_samples_hic.bedpe")$sample_name)
colors <- c("red","orange","yellow","green","blue","purple","black","grey","brown")