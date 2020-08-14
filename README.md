# HiC Vega Loop Browser
https://pdgenetics.shinyapps.io/HICLoopBrowser/  
updated 8/13/2020

## Contributors
* App Development: Frank Grenn
* Data: Frank Grenn, Xylena Reed, Cornelis Blauwendraat
* Tools: 
  * Loop regions generated with the [Juicer pipeline](https://pubmed.ncbi.nlm.nih.gov/27467249/). Credit to aidenlab.
  * App created with [R Shiny](https://shiny.rstudio.com/).
  * Plot made with [Vega visualization grammar](https://vega.github.io/vega/).

## Overview
This R shiny application creates Vega arc diagrams from chromatin interaction loop data in the form of bedpe files. Files are separated by chromosome, so only intrachromosomal interactions can be viewed with this tool. The data includes loop regions for dopaminergic neuron samples at different time points (day 0, day 25, day 65), with a total of 20 different samples included (counting the different days as different samples). 

Assay of Transposase Accessible Chromatin sequencing (ATAC-Seq) data has also been included to show regions of accessible chromatin in samples. 

Users may select all samples in the chosen file or a subset of the samples, and may group the samples into two different groups. The grouping option will color loops if they include only samples from group1, group2, or both. HiC loops that have identical positions in multiple samples are combined and displayed as only one loop in the browser. The number of samples with a loop and the names of those samples may be viewed by changing the tooltip options and mousing over the loop on the plot. ATAC-seq peaks are not combined like the HiC loops, so they will only be colored by the group1 or group2 color.

There are three settings for arc width. Count will have arc width represent the number of samples with the loop. Region will have the arc width cover the entire anchor region of the arcs. For example if a loop has an anchor at 1000-2000 and an anchor at 4000-5000, then the width will cover the 1000bp region at each anchor. Set width will make the width the same for all arcs. For the count and set settings, the arc anchor origin is the midpoint of each anchor. For example, a loop with a 1000-2000 anchor and a 4000-5000 anchor will draw an arc from 1500 to 4500. All positions are based on the hg38 reference genome. 

Users can click and drag the plot to move along the x axis, and may zoom by scrolling. Genes, transcripts and ATAC-seq peaks will only become visible if the vega plot displays a region of 10Mbp or less. Users may select a custom base pair region, or may start with the full chromosome in view. The width, height, and gene/transcript spacing may be modified to properly space the data. 



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
* `www/atac_jsons/[chromosome number]_all_samples_atacseq.json` - folder containing json files for each chromosome's ATAC-seq peaks. The following fileds are included:
  * chr - chromosome of the peak
  * start - start base pair position 
  * end - end base pair position 
  * sample_name - some identifier for the sample in which this peak was found