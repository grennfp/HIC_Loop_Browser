
shinyUI(tagList(
    useShinyjs(),




    #this will contain the url to the bedpe files
    hidden(tags$a(href='vega_bedpes/1_all_samples_loops.bedpe',target="_blank", id='interactive_ref_link','sample')),
    fluidPage(
    h1("HiC Loop Browser App (Alpha Version)"),

                         sidebarLayout(
                             
                             sidebarPanel(
                                 h4(tags$a(href='https://github.com/grennfp/HIC_Loop_Browser',target="_blank",'Github')),
                                 p("This browser shows chromatin interaction regions, or loops, across 20 different dopamineric neuron samples. Positions are based on the hg38 reference genome. Users may click and drag the plot to move the x-axis, and may scroll on the plot to zoom. The plot will need to be regenerated to view loops and genes outside of the initially selected region."),
                                 
                                 hr(),
                                 selectInput("fileSelect",label = "Choose a Chromosome File", choices=c("1_all_samples_loops.bedpe")),
                                 
                                 
                                 
                                 
                                 fluidRow(
                                     column(htmlOutput("infoOutput"),width = 12)
                                 ),
                                 fluidRow(
                                     column(dataTableOutput("InfoTable"), width = 12)
                                 ),
                                 
                                 
                                 
                                 h2("Data Settings:"),
                                 h3("Samples to Include:"),
                                 fluidRow(
                                     column(radioButtons(inputId = "sampleRadio", label = NULL, choices = c("All Samples", "Custom", "Group Samples"), selected="All Samples"),width = 4)
                                 ),
                                 fluidRow(
                                     column(div(checkboxGroupInput("sampleSelect",label = "Samples to include:",choices=samples,selected=samples),style="font-size:12px;"),width = 6),
                                     column(div(checkboxGroupInput("sampleSelect2",label = "Samples to include:",choices=samples,selected=samples),style="font-size:12px;"),width = 6)
                                 ),
                                 h3("Base Pair Range To Show:"),
                                 fluidRow(
                                     column(radioButtons(inputId = "rangeRadio", label = NULL, choices = c("Full Chromosome", "Custom"), selected="Full Chromosome"),width = 4),
                                     column(
                                         h4("Start"),
                                         textInput(inputId = "startInput", label = NULL, placeholder=0,width = "300px",value="0"),
                                         h4("End"),
                                         textInput(inputId = "endInput", label = NULL, placeholder=0, width = "300px",value="1000000"),
                                         width = 8
                                     )
                                 ),
                                 
                                 
                                 
                                 h3("Loop Information:"),
                                 h4("After taking chosen samples and range into account"),
                                 fluidRow(
                                     column(dataTableOutput("rangeTable"), width = 12)
                                 ),
                                 br(),
                                 textOutput(outputId = "numGeneOutput"),
                                 br(),
                                 fluidRow(
                                     column(radioButtons(inputId="gtRadio", label = "Genes or Transcripts", choices = c("Genes", "Transcripts"), selected = "Genes"), width = 3),
                                     column(radioButtons(inputId = "gtTypeRadio", label = "Show", choices=c("All","None","Custom"),selected="None"), width = 3),
                                     column(
                                         span(actionButton(inputId = "checkall", label = "Check All"), style = "display:inline-block;"),
                                         span(actionButton(inputId = "uncheckall", label = "Uncheck All"), style = "display:inline-block;"),
                                         checkboxGroupInput(inputId="markerSelect",label=NULL,choices=NULL),
                                         width = 6
                                     )
                                 ),
                                 
                                 
                                 h2("Plot Settings:"),
                                 
                                 h4("height (loop region)"),
                                 textInput(inputId = "loopHeightInput", label = NULL, placeholder = 0, width = "300px", value = 300),
                                 h4("height (gene/exon display)"),
                                 textInput(inputId = "heightInput", label = NULL, placeholder=0,width = "300px", value=100),
                                 h4("width"),
                                 textInput(inputId = "widthInput", label = NULL, placeholder=0, width = "300px", value=1000),
                                 h4("Number of Base Pair Ticks:"),
                                 h5("may vary slightly depending on chosen range and zoom."),
                                 textInput(inputId = "ticksInput", label= NULL, placeholder = 0, width = "300px", value = 10),
                                 h4("Arc Width"),
                                 textOutput(outputId = "arcWidthText"),
                                 radioButtons(inputId = "arcWidthRadio", label = NULL, choices=c("count","region","set"),selected="count"),
                                 h4("tooltip"),
                                 h5("show the sample count and/or the sample names when mousing over loops"),
                                 checkboxGroupInput(inputId="tooltipSelect",label=NULL,choices=c("Count","Names"),selected="Count"),
                                 h4("colors"),
                                 h5("color of the loops. Group 2 colors only apply if the 'Group Samples' option was selected."),
                                 selectInput("colorSelect1",label = "Group 1 Color:", choices=colors,selected="blue",width="25%"),
                                 selectInput("colorSelect2",label = "Group 2 Color:", choices=colors,selected="red",width="25%"),
                                 selectInput("colorSelect12",label = "Group 1 and 2 Color:", choices=colors,selected="purple",width="25%"),
                                 hr(),
                                 fluidRow(
                                     
                                     column(
                                         actionButton(inputId = "plotButton", label = "Generate Vega Plot"),width = 5)
                                 )
                                 
                                 
                                 
                             ),
                             
                             mainPanel(
                                 
                                 
                                 fluidRow(

                                     column(
                                         vegawidgetOutput("vegatest",width="100%"),width = 12)
                                 )
                             )
                         )
                         
                         )

)
)
