# HiC Vega Loop Browser
https://pdgenetics.shinyapps.io/HICLoopBrowser/  
updated 6/30/2020

## Contributors
* App Development: Frank Grenn
* Data: Frank Grenn, Xylena Reed, Cornelis Blauwendraat
* Tools: 
  * Loop regions generated with the [Juicer pipeline](https://pubmed.ncbi.nlm.nih.gov/27467249/). Credit to aidenlab.
  * App created with [R Shiny](https://shiny.rstudio.com/).
  * Plot made with [Vega visualization grammar](https://vega.github.io/vega/).

## Overview
This R shiny application creates Vega arc diagrams from chromatin interaction loop data in the form of bedpe files. Files are separated by chromosome, so only intrachromosomal interactions can be viewed with this tool. The data includes loop regions for dopaminergic neuron samples at different time points (day 0, day 25, day 65), with a total of 20 different samples included (counting the different days as different samples). 

As of now, one caveat of this tool is loops with only one anchor in the selected range will not be displayed. This is partially accounted for in the "Loop Information" table where the number of loops with only the left/right anchor in the range are displayed. All positions are from the hg38 reference genome. 

The thickness of each loop represents the number of samples containin that exact loop. The number of samples with a loop and the names of those samples may be viewed by changing the tooltip options and mousing over the loop on the plot. 

Users may select all samples in the chosen file or a subset of the samples, and may group the samples into two different groups. The grouping option will color loops if they include only samples from group1, group2, or both. 

## Files
* `server.R` - contains all of the logic of the app. Reads inputs to update outputs and generate the vega plot.
* `ui.R` - user interface code for the app. 
* `global.R` - includes libraries used and some global variables.
* `www/arc_schema.json` - the vega json that `server.R` uses as a template to generate the vega plot.
* `www/refFlat_HG38.txt` - file containing hg38 genes and transcripts to display in the plot.
* `www/vega_bepdes/[chromosome number]_all_samples_loops.bedpe` - folder containing all of the loop regions for all samples on a chromosome. Files include header and are tab delimited with the following:
  * chr1 - chromosome of first anchor
  * x1 - start base pair position of first anchor
  * x2 - end base pair position of first anchor
  * chr2 - chromosome of second anchor
  * y1 - start base pair position of second anchor
  * y2 - end base pair position of second anchor
  * sample_name - some identifier for the sample in which this loop was found