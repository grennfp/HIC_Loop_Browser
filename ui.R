
shinyUI(tagList(
    useShinyjs(),




    #this will contain the url to the bedpe files
    hidden(tags$a(href='vega_bedpes/1_all_samples_hic.bedpe',target="_blank", id='interactive_ref_link','sample')),
    fluidPage(
    h1("HiC Loop Browser App (Alpha Version)"),

                         sidebarLayout(
                             
                             sidebarPanel(
                                 h4(tags$a(href='https://github.com/grennfp/HIC_Loop_Browser',target="_blank",'Github')),
                                 p("This browser shows chromatin interaction regions, or loops, across 20 different dopamineric neuron samples. Positions are based on the hg38 reference genome. Users may click and drag the plot to move the x-axis, and may scroll on the plot to zoom. Genes, Transcripts and ATAC-seq peaks will only be visible in 10Mbp or smaller regions."),
                                 
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
                                 h3("Starting Basepair Range:"),
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
                                 p("After taking chosen samples and starting range into account"),
                                 fluidRow(
                                     column(dataTableOutput("rangeTable"), width = 12)
                                 ),
                                 br(),
                                 h3("ATAC-Seq Data:"),
                                 p("Include Assay of Transposase Accessible Chromatin sequencing (ATAC-Seq) data to show regions of accessible chromatin. ATAC-seq peaks for the selected samples will be displayed below the HiC loops. "),
                                 radioButtons(inputId = "atacRadio", label = NULL, choices=c("All","None"),selected="All"),
                                 br(),
                                 h3("Gene/Transcript Data:"),
                                 fluidRow(
                                     column(radioButtons(inputId="gtRadio", label = "Genes or Transcripts", choices = c("Genes", "Transcripts"), selected = "Genes"), width = 3),
                                     column(radioButtons(inputId = "gtTypeRadio", label = "Show", choices=c("All","None"),selected="All"), width = 3)
                                 ),
                                 
                                 
                                 h2("Plot Settings:"),
                                 
                                 h4("height (loop region)"),
                                 textInput(inputId = "loopHeightInput", label = NULL, placeholder = 0, width = "300px", value = 300),
                                 h4("width"),
                                 textInput(inputId = "widthInput", label = NULL, placeholder=0, width = "300px", value=1000),
                                 h4("gene/transcript spacing"),
                                 p("space between genes and transcripts. This will impact the overall height of the figure if genes/transcripts are displayed."),
                                 textInput(inputId = "spacingInput", label = NULL, placeholder=0,width = "300px", value=20),
                                 h4("number of basepair ticks"),
                                 p("may vary depending on chosen range and zoom."),
                                 textInput(inputId = "ticksInput", label= NULL, placeholder = 0, width = "300px", value = 10),
                                 h4("Arc Width"),
                                 textOutput(outputId = "arcWidthText"),
                                 radioButtons(inputId = "arcWidthRadio", label = NULL, choices=c("count","region","set"),selected="region"),
                                 h4("tooltip"),
                                 p("show the sample count and/or the sample names when mousing over loops"),
                                 checkboxGroupInput(inputId="tooltipSelect",label=NULL,choices=c("Count","Names"),selected="Count"),
                                 h4("colors"),
                                 p("color of the loops. Group 2 colors only apply if the 'Group Samples' option was selected."),
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
