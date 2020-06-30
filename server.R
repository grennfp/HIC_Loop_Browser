



shinyServer(function(input, output, session) {
    #all of the gene/transcript data
    gene_data <- fread("www/refFlat_HG38.txt")
    
    
    
    #directory containing the per chromosome bedpes for vega
    bedpe_dir <-"www/vega_bedpes"
    #make a list of the files for the drop down
    files <- list.files(bedpe_dir)
    updateSelectInput(session, "fileSelect", choices = files, selected=files[1])
    
    #the loaded bedpe file dataframe
    loaded_bedpe <- NULL
    #name of the loaded file
    loaded_bedpe_name <-NULL
    #df containing some basic info about the loaded bedpe
    info_df <- NULL
    
    #the genes/transcripts in the bp range we selected
    range_marker_data <-NULL
    #the loops we will show in the plot
    range_loop_data <-NULL
    
    #the markers we want to show in the plot
    custom_marker_data <- NULL
    
    #the list of markers (genes/transcripts) to show in the group checkbox
    marker_list <- NULL
    #limit for the number of gene/transcript checkboxes to show
    limit <- 100
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
    
    
    observeEvent(input$sampleRadio,{
        if(input$sampleRadio == "All Samples")
        {
            updateCheckboxGroupInput(session,label = "Samples to Include:", inputId="sampleSelect", choices = sort(samples), selected=samples)
            hide("sampleSelect2")
            #disable("sampleSelect2")
            hide("sampleSelect")
            #disable("sampleSelect")
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
        sel_samples_only_data <- loaded_bedpe[loaded_bedpe$sample_name %in% input$sampleSelect]
        
        #then filter for loops whose x1, x2, y1, and y2 are all within the range
        range_loop_data <<- sel_samples_only_data[which((sel_samples_only_data$x1>=start & sel_samples_only_data$x1<=end) & (sel_samples_only_data$x2>=start & sel_samples_only_data$x2<=end) &(sel_samples_only_data$y1>=start & sel_samples_only_data$y1<=end) &(sel_samples_only_data$y2>=start & sel_samples_only_data$y2<=end))]

        #get loops that only have the left anchor in range
        only_x_in_range <- sel_samples_only_data[which((sel_samples_only_data$x1>=start & sel_samples_only_data$x1<=end) & (sel_samples_only_data$x2>=start & sel_samples_only_data$x2<=end) & ((sel_samples_only_data$y1<start | sel_samples_only_data$y1>end) |(sel_samples_only_data$y2<start | sel_samples_only_data$y2>end)))]
        #get loops that only have the right anchor in range
        only_y_in_range <- sel_samples_only_data[which((sel_samples_only_data$y1>=start & sel_samples_only_data$y1<=end) & (sel_samples_only_data$y2>=start & sel_samples_only_data$y2<=end) & ((sel_samples_only_data$x1<start | sel_samples_only_data$x1>end) |(sel_samples_only_data$x2<start | sel_samples_only_data$x2>end)))]

        #get the genes/transcripts in the range
        range_marker_data <<- gene_data[which(gene_data$chr == chrm & as.numeric(gene_data$bpstart)>=start & as.numeric(gene_data$bpend) <= end),]

        list_unique_genes_in_range <- unique(range_marker_data$gene)
        list_unique_transcripts_in_range <- unique(range_marker_data$transcript)
        
        #if using all samples or a custom list (not two groups of samples)
        if(input$sampleRadio!="Group Samples")
        {
            output$rangeTable <- DT::renderDataTable(
                {
                    
                    range_df <- data.frame("Loops Completely in Range"=nrow(range_loop_data), "Loops with only left anchor in range (won't be in plot)"=nrow(only_x_in_range),"Loops with only right anchor in range (won't be in plot)"=nrow(only_y_in_range)
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

            #filter data by the second group's samples
            sel_samples_only_data2 <- loaded_bedpe[loaded_bedpe$sample_name %in% input$sampleSelect2]
            
            #filter second group loops for loops whose x1, x2, y1, and y2 are all within the range
            range_loop_data2 <- sel_samples_only_data2[which((sel_samples_only_data2$x1>=start & sel_samples_only_data2$x1<=end) & (sel_samples_only_data2$x2>=start & sel_samples_only_data2$x2<=end) &(sel_samples_only_data2$y1>=start & sel_samples_only_data2$y1<=end) &(sel_samples_only_data2$y2>=start & sel_samples_only_data2$y2<=end))]

            #get loops of second group that only have left anchor in range
            only_x_in_range2 <- sel_samples_only_data2[which((sel_samples_only_data2$x1>=start & sel_samples_only_data2$x1<=end) & (sel_samples_only_data2$x2>=start & sel_samples_only_data2$x2<=end) & ((sel_samples_only_data2$y1<start | sel_samples_only_data2$y1>end) |(sel_samples_only_data2$y2<start | sel_samples_only_data2$y2>end)))]
            #get loops of second group that only have right anchor in range
            only_y_in_range2 <- sel_samples_only_data2[which((sel_samples_only_data2$y1>=start & sel_samples_only_data2$y1<=end) & (sel_samples_only_data2$y2>=start & sel_samples_only_data2$y2<=end) & ((sel_samples_only_data2$x1<start | sel_samples_only_data2$x1>end) |(sel_samples_only_data2$x2<start | sel_samples_only_data2$x2>end)))]
            
            
            output$rangeTable <- DT::renderDataTable(
                {
                    
                    range_df <- data.table("Loops Completely in Range"=c(nrow(range_loop_data),nrow(range_loop_data2)), "Loops with only left anchor in range (won't be in plot)"=c(nrow(only_x_in_range),nrow(only_x_in_range2)),"Loops with only right anchor in range (won't be in plot)"=c(nrow(only_y_in_range),nrow(only_y_in_range2))
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
                     if(input$gtRadio=="Genes")
                     {
                         marker <- "genes"
                         custom_marker_data <<- range_marker_data[!duplicated(range_marker_data[,c('gene')])]
                     }
                     if(input$gtRadio=="Transcripts")
                     {
                         marker <- "transcripts"
                         custom_marker_data <<- range_marker_data[!duplicated(range_marker_data[,c('transcript')])]
                     }
                     if(input$gtTypeRadio=="All")
                     {
                         #put this here again to catch changes to both radio button cols... i think
                         if(input$gtRadio=="Genes")
                         {
                             custom_marker_data <<- range_marker_data[!duplicated(range_marker_data[,c('gene')])]
                         }
                         if(input$gtRadio=="Transcripts")
                         {
                             custom_marker_data <<- range_marker_data[!duplicated(range_marker_data[,c('transcript')])]
                         }
                         output$numGeneOutput <- renderText(paste0("plot will include ", nrow(custom_marker_data), " ", marker))
                         hide("markerSelect")
                         hide("checkall")
                         hide("uncheckall")
                     }
                     if(input$gtTypeRadio=="None")
                     {
                         custom_marker_data<<- data.frame()
                         output$numGeneOutput <-renderText(paste0("plot will include 0 ", marker))
                         hide("markerSelect")
                         hide("checkall")
                         hide("uncheckall")
                     }
                     if(input$gtTypeRadio=="Custom")
                     {


                         
                         if(input$gtRadio=="Genes")
                         {
                             marker_list <<- sort(custom_marker_data$gene)
                         }
                         if(input$gtRadio=="Transcripts")
                         {
                             marker_list <<- sort(custom_marker_data$transcript)
                         }

                         

                         if(length(marker_list)<=limit)
                         {
                             show("markerSelect")
                             show("checkall")
                             show("uncheckall")
                             updateCheckboxGroupInput(session, inputId="markerSelect", choices = marker_list, selected=marker_list)
                             output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " ", marker))
                         }
                         else
                         {
                             hide("markerSelect")
                             hide("checkall")
                             hide("uncheckall")
                             output$numGeneOutput <-renderText(paste0(length(marker_list) ," is too many ", marker, " for custom selection. Please reduce to ", limit, " or less!"))
                         }

                         
                         
                     }
                 })
    #hit the checkall button
    observeEvent(input$checkall,
                 {
                     updateCheckboxGroupInput(session, inputId="markerSelect", choices = marker_list, selected=marker_list)
                     if(input$gtRadio=="Genes")
                     {
                         #custom_marker_data <<- range_marker_data[!duplicated(range_marker_data[,c('gene')])]
                         #output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " genes"))
                     }
                     if(input$gtRadio=="Transcripts")
                     {
                         #custom_marker_data <<- range_marker_data[!duplicated(range_marker_data[,c('transcript')])]
                         #output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " transcripts"))
                     }
                 })
    #hit the uncheck all button
    observeEvent(input$uncheckall,
                 {
                     updateCheckboxGroupInput(session, inputId="markerSelect", choices = marker_list, selected=NULL)
                     if(input$gtRadio=="Genes")
                     {
                         #custom_marker_data <<- data.frame()
                         #output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " genes"))
                     }
                     if(input$gtRadio=="Transcripts")
                     {
                         #custom_marker_data <<- data.frame()
                         #output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " transcripts"))
                     }
                 })
    #check one of the custom marker checkboxes
    observeEvent(ignoreNULL=F,{input$markerSelect},
                 {
                     if(input$gtTypeRadio=="Custom")
                     {
                         if(input$gtRadio=="Genes")
                         {
                             if(!is.null(input$markerSelect))
                             {
                                 selected_markers <- range_marker_data[which(range_marker_data$gene %in% input$markerSelect),]
                                 custom_marker_data <<- selected_markers[!duplicated(selected_markers[,c('gene')])]
                                 if(nrow(custom_marker_data <= limit))
                                 {
                                     output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " genes"))
                                 }
                                 else
                                 {
                                     output$numGeneOutput <-renderText(paste0(length(marker_list) ," is too many ", "genes", " for custom selection. Please reduce to ", limit, " or less!"))
                                 }
                             }
                             else
                             {
                                 custom_marker_data <<- data.frame()
                                 output$numGeneOutput <-renderText(paste0("plot will include 0 genes"))
                             }
                             
                         }
                         if(input$gtRadio=="Transcripts")
                         {
                             if(!is.null(input$markerSelect))
                             {
                                 selected_markers <- range_marker_data[which(range_marker_data$transcript %in% input$markerSelect),]
                                 custom_marker_data <<- selected_markers[!duplicated(selected_markers[,c('transcript')])]
                                 if(nrow(custom_marker_data <= limit))
                                 {
                                     output$numGeneOutput <-renderText(paste0("plot will include ", nrow(custom_marker_data), " transcripts"))
                                 }
                                 else
                                 {
                                     output$numGeneOutput <-renderText(paste0(length(marker_list) ," is too many ", "transcripts", " for custom selection. Please reduce to ", limit, " or less!"))
                                 }
                             }
                             else
                             {
                                 custom_marker_data <<- data.frame()
                                 output$numGeneOutput <-renderText(paste0("plot will include 0 transcripts"))
                             }

                         }
                     }

                 })
    #hit the plot button
    observeEvent(input$plotButton,
                 {
                     vega_json <- rjson::fromJSON(file="www/arc_schema.json")

                     
                     count_range_loop_data <- NULL
                     #if using all samples or a custom list (not grouping samples) then group by position, add counts, add sample name string, and add loop color
                     if(input$sampleRadio!="Group Samples")
                     {
                         
                         count_range_loop_data <- range_loop_data %>% group_by(chr1,x1,x2,chr2,y1,y2) %>% mutate(test_count = n())
                         count_range_loop_data <- count_range_loop_data %>% group_by(chr1,x1,x2,chr2,y1,y2,test_count) %>% mutate(sample_name = paste0(sample_name, collapse="\n,")) %>% mutate(color = input$colorSelect1)
                         #setup json to read color values
                         vega_json[["marks"]][[5]][["encode"]][["update"]][["stroke"]][["field"]] <- "datum.color"
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["stroke"]][["field"]] <- "datum.color"
                     }
                     #else if grouping samples, do the same as above, but assign group to each loop, and then assign colors based on the groups
                     else
                     {
                         start <- as.numeric(input$startInput)
                         end <- as.numeric(input$endInput)
                         sel_samples_only_data2 <- loaded_bedpe[loaded_bedpe$sample_name %in% input$sampleSelect2]
                         range_loop_data2 <- sel_samples_only_data2[which((sel_samples_only_data2$x1>=start & sel_samples_only_data2$x1<=end) & (sel_samples_only_data2$x2>=start & sel_samples_only_data2$x2<=end) &(sel_samples_only_data2$y1>=start & sel_samples_only_data2$y1<=end) &(sel_samples_only_data2$y2>=start & sel_samples_only_data2$y2<=end))]
                         
                         #assign group number
                         group1 <- range_loop_data
                         group1$group <- 1
                         group2 <- range_loop_data2
                         group2$group <- 2
                         #combine group1 and group2, group them by position, combine all the group numbers into one string
                         all_group_data <- rbind(group1,group2) %>% group_by(chr1,x1,x2,chr2,y1,y2) %>% mutate(groups = paste0(group, collapse=";")) 
                         #check the group number string and apply a color.
                         color_group_data <- all_group_data %>% mutate(color = ifelse(((grepl("1", groups)) && (grepl("2",groups))), input$colorSelect12, ifelse(grepl("1", groups),input$colorSelect1,input$colorSelect2))) 
                         #get distinct loops and add count
                         distinct_counted_data <- color_group_data %>% distinct_at(.vars=c('chr1','x1','x2','chr2','y1','y2','sample_name'),.keep_all=TRUE)  %>% mutate(test_count = n())
                         #add sample name string and select relevant values
                         count_range_loop_data <- distinct_counted_data %>% group_by(chr1,x1,x2,chr2,y1,y2,test_count)  %>% mutate(sample_name = paste0(sample_name, collapse="\n,")) %>% select(chr1,x1,x2,chr2,y1,y2,test_count,sample_name,color)
                         #setup json to read color values
                         vega_json[["marks"]][[5]][["encode"]][["update"]][["stroke"]][["field"]] <- "datum.color"
                         vega_json[["marks"]][[5]][["encode"]][["hover"]][["stroke"]][["field"]] <- "datum.color"
                     }


                     count_range_loop_data <- unique(count_range_loop_data)
                     
                     vega_json[["signals"]][[1]][["value"]] <- input$startInput
                     
                     vega_json[["signals"]][[2]][["value"]] <- input$endInput
                     vega_json[["width"]] <- as.numeric(input$widthInput)
                     vega_json[["height"]] <- as.numeric(input$heightInput)
                     vega_json[["data"]][[2]][["values"]] <- create_list_for_json(custom_marker_data)
                     vega_json[["data"]][[1]][["values"]] <- create_list_for_json(count_range_loop_data)
                     
                     vega_json[["axes"]][[1]][["tickCount"]] <- as.numeric(input$ticksInput)
                     
                     if(input$gtRadio=="Genes")
                     {
                         
                         vega_json[["marks"]][[3]][["encode"]][["enter"]][["text"]][["field"]] <- "gene"
                     }
                     if(input$gtRadio=="Transcripts")
                     {
                         vega_json[["marks"]][[3]][["encode"]][["enter"]][["text"]][["field"]] <- "transcript"
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

                     jsonstring <- rjson::toJSON(vega_json)
                     #write(jsonstring, "www/testtoJSON.json")
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
