



shinyServer(function(input, output, session) {
    #all of the gene/transcript data
    gene_data <- fread("www/refFlat_HG38.txt")
    
    
    
    #directory containing the per chromosome bedpes for vega
    bedpe_dir <-"www/vega_bedpes"
    #make a list of the files for the drop down
    file_list <- list.files(bedpe_dir)
    files <- file_list[grepl("*hic.bedpe",file_list)]
    updateSelectInput(session, "fileSelect", choices = files, selected=files[1])
    
    #the loaded bedpe file dataframe
    loaded_bedpe <- NULL
    #name of the loaded file
    loaded_bedpe_name <-NULL
    #df containing some basic info about the loaded bedpe
    info_df <- NULL
    
    #the genes/transcripts in the bp range we selected
    range_marker_data <-NULL
    
    #### Loop Dataframes
    #all loops for group1 samples
    group1_loops <- NULL
    #all loops with both anchors in range for group1 samples
    group1_loops_full_inrange <- NULL
    #all loops with at least one anchor in range for group1 samples
    group1_loops_any_inrange <- NULL
    #all loops for group2 samples
    group2_loops <- NULL
    #all loops with both anchors in range for group2 samples
    group2_loops_full_inrange <- NULL
    #all loops with at least one anchor in range for group2 samples
    group2_loops_any_inrange <- NULL

    
    #the markers we want to show in the plot
    custom_marker_data <- NULL
    
    #the list of markers (genes/transcripts) to show in the group checkbox
    marker_list <- NULL
    #current chromosome we are looking at
    chrm <- NULL
    
    #changing the fileselect dropdown
    observeEvent(input$fileSelect,
                 {
                     
                     
                     loaded_bedpe_name <<- input$fileSelect
                     loaded_bedpe <<- fread(paste0(bedpe_dir,"/",input$fileSelect))
                     chrm <<- paste0("chr",loaded_bedpe[1,]$chr1)
                     output$infoOutput <- renderUI(HTML(paste0("<h3>",loaded_bedpe_name, " File Information:</h3>")))
                     
                     output$InfoTable <- DT::renderDataTable(
                         {
                             max <- max(c(max(loaded_bedpe$y2),max(loaded_bedpe$y1),max(loaded_bedpe$x1),max(loaded_bedpe$x2)))
                             min <- min(c(min(loaded_bedpe$y2),min(loaded_bedpe$y1),min(loaded_bedpe$x1),min(loaded_bedpe$x2)))
                             
                             
                             sample_num <- length(unique(loaded_bedpe$sample_name))
                             
                             distinct_loops_df <- loaded_bedpe %>% select("chr1","x1","x2","chr2","y1","y2") %>% distinct(.keep_all=TRUE)
                             
                             info_df <<- data.frame("Total Loops:"=nrow(loaded_bedpe), "Max Loop Position:"=max, "Min Loop Position:"=min, "Number of Samples:"=sample_num, "Number of Unique Loops:"=nrow(distinct_loops_df),check.names=F)
                             
                             updateTextInput(session, "startInput",value = info_df$"Min Loop Position:")
                             updateTextInput(session, "endInput",value = info_df$"Max Loop Position:")
                             
                             t(info_df)
                             
                         },
                         colnames = "", escape = F, options = list(searching =F, paginate = F, ordering = F, dom = 't')
                     )

                     
                 }
    )
    
    observeEvent(input$arcWidthRadio,{
        if(input$arcWidthRadio == "count")
        {
            output$arcWidthText <- renderText("Arc width will be the number of samples with the loop. The more samples with the exact same loop, the larger the arc width.")
        }
        if(input$arcWidthRadio == "region")
        {
            output$arcWidthText <- renderText("Arc width will cover the anchor region. So 1000-2000:4000-5000 will have an arc width that will cover the 1000bp region of both anchors.")
        }
        if(input$arcWidthRadio == "set")
        {
            output$arcWidthText <- renderText("Arc width will be the same for all loops.")
        }
    })
    
    
    observeEvent(input$sampleRadio,{
        if(input$sampleRadio == "All Samples")
        {
            updateCheckboxGroupInput(session,label = "Samples to Include:", inputId="sampleSelect", choices = sort(samples), selected=samples)
            hide("sampleSelect2")
            hide("sampleSelect")
        }
        if(input$sampleRadio == "Custom")
        {
            enable("sampleSelect")
            show("sampleSelect")
            disable("sampleSelect2")
            hide("sampleSelect2")
            updateCheckboxGroupInput(session,label = "Samples to Include:", inputId="sampleSelect")
        }
        if(input$sampleRadio == "Group Samples")
        {
            enable("sampleSelect")
            show("sampleSelect")
            enable("sampleSelect2")
            show("sampleSelect2")
            updateCheckboxGroupInput(session,label = "Group 1:", inputId="sampleSelect", choices = sort(samples), selected=grep("da0", samples,value=TRUE))
            updateCheckboxGroupInput(session,label = "Group 2:", inputId="sampleSelect2", choices = sort(samples), selected=grep("da65", samples,value=TRUE))
        }
    })
    
    #changing the range radio button
    observeEvent(input$rangeRadio,{
        if(input$rangeRadio == "Full Chromosome")
        {
            updateTextInput(session, "startInput",value = info_df$"Min Loop Position:")
            updateTextInput(session, "endInput",value = info_df$"Max Loop Position:")
            disable("startInput")
            disable("endInput")
        }
        if(input$rangeRadio == "Custom")
        {
            enable("startInput")
            enable("endInput")
        }
    })
    #changing the text in the range textboxes
    observeEvent({
        input$startInput
        input$endInput
        input$sampleSelect
        input$sampleSelect2
    },
    {
        
        start <- as.numeric(input$startInput)
        end <- as.numeric(input$endInput)
        
        #filter data by the selected samples
        group1_loops <<- loaded_bedpe[loaded_bedpe$sample_name %in% input$sampleSelect]
        
        #get all loops in the range. this includes loops with only one anchor in the range
        group1_loops_any_inrange <<- group1_loops[which(((group1_loops$x1>=start & group1_loops$x1<=end) & (group1_loops$x2>=start & group1_loops$x2<=end)) | ((group1_loops$y1>=start & group1_loops$y1<=end) &(group1_loops$y2>=start & group1_loops$y2<=end)))]
        #then filter for loops whose x1, x2, y1, and y2 are all within the range
        group1_loops_full_inrange <<- group1_loops[which((group1_loops$x1>=start & group1_loops$x1<=end) & (group1_loops$x2>=start & group1_loops$x2<=end) &(group1_loops$y1>=start & group1_loops$y1<=end) &(group1_loops$y2>=start & group1_loops$y2<=end))]
        
        #get loops that only have the left anchor in range
        only_x_in_range <- group1_loops[which((group1_loops$x1>=start & group1_loops$x1<=end) & (group1_loops$x2>=start & group1_loops$x2<=end) & ((group1_loops$y1<start | group1_loops$y1>end) |(group1_loops$y2<start | group1_loops$y2>end)))]
        #get loops that only have the right anchor in range
        only_y_in_range <- group1_loops[which((group1_loops$y1>=start & group1_loops$y1<=end) & (group1_loops$y2>=start & group1_loops$y2<=end) & ((group1_loops$x1<start | group1_loops$x1>end) |(group1_loops$x2<start | group1_loops$x2>end)))]
        
        #get the genes/transcripts in the range
        range_marker_data <<- gene_data[which(gene_data$chr == chrm & as.numeric(gene_data$bpstart)>=start & as.numeric(gene_data$bpend) <= end),]
        
        list_unique_genes_in_range <- unique(range_marker_data$gene)
        list_unique_transcripts_in_range <- unique(range_marker_data$transcript)

        
        #if using all samples or a custom list (not two groups of samples)
        if(input$sampleRadio!="Group Samples")
        {
            output$rangeTable <- DT::renderDataTable(
                {
                    
                    range_df <- data.frame("Loops Completely in Range"=nrow(group1_loops_full_inrange), "Loops with only left anchor in range"=nrow(only_x_in_range),"Loops with only right anchor in range"=nrow(only_y_in_range)
                                           ,"Unique Genes in Range"=length(list_unique_genes_in_range),"Unique Transcripts in Range"=length(list_unique_transcripts_in_range),check.names=F)
                    
                    t(range_df)
                    
                },
                colnames = "", escape = F, options = list(searching =F, paginate = F, ordering = F, dom = 't')
            )
        }
        #redo the same but for the other group of samples
        else
        {
            
            start <- as.numeric(input$startInput)
            end <- as.numeric(input$endInput)
            
            #filter data by the selected samples
            group2_loops <<- loaded_bedpe[loaded_bedpe$sample_name %in% input$sampleSelect2]
            
            #get all loops in the range. this includes loops with only one anchor in the range
            group2_loops_any_inrange <<- group2_loops[which(((group2_loops$x1>=start & group2_loops$x1<=end) & (group2_loops$x2>=start & group2_loops$x2<=end)) | ((group2_loops$y1>=start & group2_loops$y1<=end) &(group2_loops$y2>=start & group2_loops$y2<=end)))]
            #then filter for loops whose x1, x2, y1, and y2 are all within the range
            group2_loops_full_inrange <<- group2_loops[which((group2_loops$x1>=start & group2_loops$x1<=end) & (group2_loops$x2>=start & group2_loops$x2<=end) &(group2_loops$y1>=start & group2_loops$y1<=end) &(group2_loops$y2>=start & group2_loops$y2<=end))]
            
            #get loops that only have the left anchor in range
            only_x_in_range2 <- group2_loops[which((group2_loops$x1>=start & group2_loops$x1<=end) & (group2_loops$x2>=start & group2_loops$x2<=end) & ((group2_loops$y1<start | group2_loops$y1>end) |(group2_loops$y2<start | group2_loops$y2>end)))]
            #get loops that only have the right anchor in range
            only_y_in_range2 <- group2_loops[which((group2_loops$y1>=start & group2_loops$y1<=end) & (group2_loops$y2>=start & group2_loops$y2<=end) & ((group2_loops$x1<start | group2_loops$x1>end) |(group2_loops$x2<start | group2_loops$x2>end)))]
            
            output$rangeTable <- DT::renderDataTable(
                {
                    
                    range_df <- data.table("Loops Completely in Range"=c(nrow(group1_loops_full_inrange),nrow(group2_loops_full_inrange)), "Loops with only left anchor in range"=c(nrow(only_x_in_range),nrow(only_x_in_range2)),"Loops with only right anchor in range"=c(nrow(only_y_in_range),nrow(only_y_in_range2))
                                           ,"Unique Genes in Range"=c(length(list_unique_genes_in_range),length(list_unique_genes_in_range)),"Unique Transcripts in Range"=c(length(list_unique_transcripts_in_range),length(list_unique_transcripts_in_range)),check.names=F)
                    
                    t(range_df)
                    
                },
                colnames = c("Group 1", "Group 2"), escape = F, options = list(searching =F, paginate = F, ordering = F, dom = 't')
            )
        }
        
    })
    
    #changing the marker radio buttons or the range textboxes
    observeEvent({
        input$gtTypeRadio
        input$gtRadio
        input$startInput
        input$endInput
    },
    {
        marker <- ""
        chr_markers <- gene_data[which(gene_data$chr == chrm),]
        if(input$gtRadio=="Genes")
        {
            marker <- "genes"
            custom_marker_data <<- chr_markers[!duplicated(chr_markers[,c('gene')])]
        }
        if(input$gtRadio=="Transcripts")
        {
            marker <- "transcripts"
            custom_marker_data <<- chr_markers[!duplicated(chr_markers[,c('transcript')])]
        }
        if(input$gtTypeRadio=="All")
        {
            #put this here again to catch changes to both radio button cols... i think
            if(input$gtRadio=="Genes")
            {
                custom_marker_data <<- chr_markers[!duplicated(chr_markers[,c('gene')])]
            }
            if(input$gtRadio=="Transcripts")
            {
                custom_marker_data <<- chr_markers[!duplicated(chr_markers[,c('transcript')])]
            }
        }
        if(input$gtTypeRadio=="None")
        {
            custom_marker_data<<- data.frame()
        }
    })

    #hit the plot button
    observeEvent(input$plotButton,
                 {
                     vega_json <- rjson::fromJSON(file="www/arc_schema.json")
                     
                     
                     vega_loop_data <- NULL
                     #if using all samples or a custom list (not grouping samples) then group by position, add counts, add sample name string, and add loop color
                     if(input$sampleRadio!="Group Samples")
                     {
                         
                         vega_loop_data <- group1_loops %>% group_by(chr1,x1,x2,chr2,y1,y2) %>% mutate(test_count = n())#sel_samples_only_data %>% group_by(chr1,x1,x2,chr2,y1,y2) %>% mutate(test_count = n())
                         vega_loop_data <- vega_loop_data %>% group_by(chr1,x1,x2,chr2,y1,y2,test_count) %>% mutate(sample_name = paste0(sample_name, collapse="\n,")) %>% mutate(color = input$colorSelect1)
                         #setup json to read color values
                         vega_json[["marks"]][[5]][["encode"]][["update"]][["stroke"]][["field"]] <- "datum.color"
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["stroke"]][["field"]] <- "datum.color"

                         #if only one sample selected then need to make sure it gets passed as a list to correctly convert the data into json format later
                         if(length(input$sampleSelect)==1)
                         {
                             vega_json[["signals"]][[3]][["value"]] <- list(input$sampleSelect)
                         }
                         #if no samples were selected then enter a temp sample name so that the regex operation used to filter out sample works in vega
                         else if(length(input$sampleSelect)==0)
                         {
                             vega_json[["signals"]][[3]][["value"]] <- list("null")
                         }
                         #otherwise if there was more than one sample selected then pass the vector as usual
                         else
                         {
                             vega_json[["signals"]][[3]][["value"]] <- input$sampleSelect
                         }
                         #we are only converned with group1 samples, so set the group2 samples to "null" in vega
                         vega_json[["signals"]][[4]][["value"]] <- list("null")

                     }
                     #else if grouping samples, do the same as above, but assign group to each loop, and then assign colors based on the groups
                     else
                     {
                         #assign group number
                         group1 <- group1_loops
                         group1$group <- 1
                         
                         group2 <- group2_loops
                         group2$group <- 2
                         
                         #combine group1 and group2, group them by position, combine all the group numbers into one string
                         all_group_data <- rbind(group1,group2) %>% group_by(chr1,x1,x2,chr2,y1,y2) %>% mutate(groups = paste0(group, collapse=";")) 
                         #check the group number string and apply a color.
                         color_group_data <- all_group_data %>% mutate(color = ifelse(((grepl("1", groups)) && (grepl("2",groups))), input$colorSelect12, ifelse(grepl("1", groups),input$colorSelect1,input$colorSelect2))) 
                         #get distinct loops and add count
                         distinct_counted_data <- color_group_data %>% distinct_at(.vars=c('chr1','x1','x2','chr2','y1','y2','sample_name'),.keep_all=TRUE)  %>% mutate(test_count = n())
                         #add sample name string and select relevant values
                         vega_loop_data <- distinct_counted_data %>% group_by(chr1,x1,x2,chr2,y1,y2,test_count)  %>% mutate(sample_name = paste0(sample_name, collapse="\n,")) %>% select(chr1,x1,x2,chr2,y1,y2,test_count,sample_name,color)
                         #setup json to read color values
                         vega_json[["marks"]][[5]][["encode"]][["update"]][["stroke"]][["field"]] <- "datum.color"
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["stroke"]][["field"]] <- "datum.color"

                         #if only one sample selected then need to make sure it gets passed as a list to correctly convert the data into json format later
                         if(length(input$sampleSelect)==1)
                         {
                             vega_json[["signals"]][[3]][["value"]] <- list(input$sampleSelect)
                         }
                         #if no samples were selected then enter a temp sample name so that the regex operation used to filter out sample works in vega
                         else if(length(input$sampleSelect)==0)
                         {
                             vega_json[["signals"]][[3]][["value"]] <- list("null")
                         }
                         #otherwise if there was more than one sample selected then pass the vector as usual
                         else
                         {
                             vega_json[["signals"]][[3]][["value"]] <- input$sampleSelect
                         }
                         #if only one sample selected then need to make sure it gets passed as a list to correctly convert the data into json format later
                         if(length(input$sampleSelect2)==1)
                         {
                             vega_json[["signals"]][[4]][["value"]] <- list(input$sampleSelect2)
                         }
                         #if no samples were selected then enter a temp sample name so that the regex operation used to filter out sample works in vega
                         else if(length(input$sampleSelect2)==0)
                         {
                             vega_json[["signals"]][[4]][["value"]] <- list("null")
                         }
                         #otherwise if there was more than one sample selected then pass the vector as usual
                         else
                         {
                             vega_json[["signals"]][[4]][["value"]] <- input$sampleSelect2
                         }

                     }
                     

                     #provide the url to the correct chromosome atacseq json file if including atacseq data
                     if(input$atacRadio=="All")
                     {
                         #set url to atacseq json
                         vega_json[["data"]][[3]][["url"]] <- paste0("atac_jsons/",gsub("chr","",chrm),"_all_samples_atacseq.json")
                         #add vega expression to assign colors to atacseq data
                         vega_json[["data"]][[3]][["transform"]][[4]][["expr"]] <- paste0("if(test(regexp(join(group1_samples,'|')),datum.sample_name),'",input$colorSelect1,"','",input$colorSelect2,"')")
                         #move down the gene display if including atacseq data
                         vega_json[["scales"]][[1]][["range"]][[1]] <- 160
                         vega_json[["signals"]][[5]][["value"]] <- 160#as.numeric(input$heightInput) + 160
                     }
                     else
                     {
                         vega_json[["data"]][[3]][["url"]] <- ""
                         #move up the gene display if including atacseq data
                         vega_json[["scales"]][[1]][["range"]][[1]] <- 50
                         vega_json[["signals"]][[5]][["value"]] <- 50#as.numeric(input$heightInput) + 50
                     }
                     

                     
                     vega_loop_data <- unique(vega_loop_data)
                     
                     #set the signals for the full chromosome bp range
                     vega_json[["signals"]][[1]][["value"]] <- info_df$"Min Loop Position:"
                     
                     vega_json[["signals"]][[2]][["value"]] <- info_df$"Max Loop Position:"
                     
                     #set the signals for the desired start bp range
                     vega_json[["signals"]][[6]][["value"]] <- as.numeric(input$startInput)
                     
                     vega_json[["signals"]][[7]][["value"]] <- as.numeric(input$endInput)

                     vega_json[["padding"]][["top"]] <- input$loopHeightInput
                     vega_json[["width"]] <- as.numeric(input$widthInput)
                     vega_json[["signals"]][[8]][["value"]] <- as.numeric(input$spacingInput)
                     
                     vega_json[["data"]][[2]][["values"]] <- create_list_for_json(custom_marker_data)
                     vega_json[["data"]][[1]][["values"]] <- create_list_for_json(vega_loop_data)

                     
                     vega_json[["axes"]][[1]][["tickCount"]] <- as.numeric(input$ticksInput)
                     
                     if(input$gtRadio=="Genes")
                     {
                         
                         vega_json[["marks"]][[3]][["encode"]][["enter"]][["text"]][["field"]] <- "gene"
                         vega_json[["marks"]][[3]][["encode"]][["update"]][["text"]][["field"]] <- "gene"
                         #update bar tooltip to show gene
                         vega_json[["marks"]][[1]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.gene + ' ' + datum.chr + ':' + datum.bpstart + '-' + datum.bpend" 
                         #update exon tooltip to show gene
                         vega_json[["marks"]][[2]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.gene + ' ' + datum.chr + ':' + datum.bpstart + '-' + datum.bpend" 
                     }
                     if(input$gtRadio=="Transcripts")
                     {
                         vega_json[["marks"]][[3]][["encode"]][["enter"]][["text"]][["field"]] <- "transcript"
                         vega_json[["marks"]][[3]][["encode"]][["update"]][["text"]][["field"]] <- "transcript"
                         #update bar tooltip to show transcript
                         vega_json[["marks"]][[1]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.transcript + ' ' + datum.chr + ':' + datum.bpstart + '-' + datum.bpend" 
                         #update exon tooltip to show transcript
                         vega_json[["marks"]][[2]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.transcript + ' ' + datum.chr + ':' + datum.bpstart + '-' + datum.bpend" 
                     }
                     #tooltip to display count or the sample names
                     if("Count" %in% input$tooltipSelect && "Names" %in% input$tooltipSelect)
                     {
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.bpx1 + '-' + datum.bpx2 + ':' + datum.bpy1 +'-' + datum.bpy2 +' for '+ datum.disp_count + ': ' + datum.name"
                     }
                     else if("Names" %in% input$tooltipSelect)
                     {
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.bpx1 + '-' + datum.bpx2 + ':' + datum.bpy1 +'-' + datum.bpy2 +' for '+ datum.name"
                     }
                     else if("Count" %in% input$tooltipSelect)
                     {
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.bpx1 + '-' + datum.bpx2 + ':' + datum.bpy1 +'-' + datum.bpy2 +' for '+ datum.disp_count"
                     }
                     else
                     {
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["tooltip"]][["signal"]] <- "datum.bpx1 + '-' + datum.bpx2 + ':' + datum.bpy1 +'-' + datum.bpy2"
                     }
                     
                     #which arc width setting to use
                     if(input$arcWidthRadio == "count")
                     {
                         vega_json[["marks"]][[4]][["transform"]][[3]][["expr"]] <- "(datum.disp_count)*2"
                     }
                     if(input$arcWidthRadio == "region")
                     {
                         vega_json[["marks"]][[4]][["transform"]][[3]][["expr"]] <- "(datum.scalex2-datum.scalex1)"
                     }
                     if(input$arcWidthRadio == "set")
                     {
                         vega_json[["marks"]][[4]][["transform"]][[3]][["expr"]] <- "2"
                     }
                     
                     jsonstring <- rjson::toJSON(vega_json)
                     
                     vega <- as_vegaspec(jsonstring)
                     
                     output$vegatest <- renderVegawidget(
                         {
                             
                             vega
                             
                         })
                 })
    
    #function to create a list from a data frame formatted the way we want it for the vega json
    create_list_for_json <- function(data)
    {
        final_list <- c()
        if(nrow(data)>0)
        {
            for(i in 1:nrow(data))
            {
                row_list <- as.list(data[i,])
                final_list[[i]] <- row_list
            }
        }
        final_list
    }
    
    
    
})
