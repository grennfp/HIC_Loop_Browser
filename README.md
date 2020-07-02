# HiC Vega Loop Browser
https://pdgenetics.shinyapps.io/HICLoopBrowser/  
updated 7/2/2020

## Contributors
* App Development: Frank Grenn
* Data: Frank Grenn, Xylena Reed, Cornelis Blauwendraat
* Tools: 
  * Loop regions generated with the [Juicer pipeline](https://pubmed.ncbi.nlm.nih.gov/27467249/). Credit to aidenlab.
  * App created with [R Shiny](https://shiny.rstudio.com/).
  * Plot made with [Vega visualization grammar](https://vega.github.io/vega/).

## Overview
This R shiny application creates Vega arc diagrams from chromatin interaction loop data in the form of bedpe files. Files are separated by chromosome, so only intrachromosomal interactions can be viewed with this tool. The data includes loop regions for dopaminergic neuron samples at different time points (day 0, day 25, day 65), with a total of 20 different samples included (counting the different days as different samples). 

Users may select all samples in the chosen file or a subset of the samples, and may group the samples into two different groups. The grouping option will color loops if they include only samples from group1, group2, or both. 

There are three settings for arc width. Count will have arc width represent the number of samples with the loop. Region will have the arc width cover the entire anchor region of the arcs. For example if a loop has an anchor at 1000-2000 and an anchor at 4000-5000, then the width will cover the 1000bp region at each anchor. Set width will make the width the same for all arcs. For the count and set settings, the arc anchor origin is the midpoint of each anchor. For example, a loop with a 1000-2000 anchor and a 4000-5000 anchor will draw an arc from 1500 to 4500. All positions are based on the hg38 reference genome. 

The number of samples with a loop and the names of those samples may be viewed by changing the tooltip options and mousing over the loop on the plot. 

Users can click and drag the plot to move along the x axis, and may zoom by scrolling. Doing so will not update the plot to include loops completely outside the selected region. This was allowed so that these features would not be slowed down. The base pair region, width and heights may need to be modified to properly see loops outside of the initially selected region after navigating outside of this region. 



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