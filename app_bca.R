# Load libraries
library(shiny)

# UI
ui <- fluidPage(
  titlePanel("BCA assay report"),
  sidebarLayout(
    sidebarPanel(
      fileInput("data", "Upload data file (.xlsx):", accept = ".xlsx"),
      fileInput("anno", "Upload annotation file (.xlsx):", accept = ".xlsx"),
      radioButtons("assay", "Indicate type of BCA assay", 
                   choices = c("Protein" = "prot",
                               "Peptide" = "pep")),
      selectInput("bc", "Position(s) of BC:",
                  choices = sort(do.call(paste0, expand.grid(LETTERS[1:8], 1:12))),
                  multiple = T),
      selectInput("bs", "Position(s) of BS:",
                  choices = sort(do.call(paste0, expand.grid(LETTERS[1:8], 1:12))),
                  multiple = T),
      numericInput("volume", "Indicate dilution:", value = 5),
      actionButton("generar", "Generate report")
    ),
    mainPanel(
      uiOutput("descarga_ui")
    )
  )
)

# Server
server <- function(input, output, session) {
  # Reactive para guardar temporalmente la ruta del archivo generado
  archivo_tmp <- reactiveVal(NULL)
  
  observeEvent(input$generar, {
    # Crear archivo temporal
    tmpfile <- tempfile(fileext = ".html")
    
    # Renderizar el .Rmd con los parametros
    rmarkdown::render(
      input = "bca_assay_report.Rmd",
      output_file = tmpfile,
      params = list(
        data = input$data$datapath,
        anno = input$anno$datapath,
        assay = input$assay,
        bc = input$bc,
        bs = input$bs,
        dil = input$volume
      ),
      envir = new.env(parent = globalenv())
    )
    
    # Guardar la ruta para el handler de descarga
    archivo_tmp(tmpfile)
  })
  
  output$descarga_ui <- renderUI({
    req(archivo_tmp())
    downloadButton("descargar", "Descargar report")
  })
  
  output$descargar <- downloadHandler(
    filename = function() {
      paste0("bca_report_", Sys.Date(), ".html")
    },
    content = function(file) {
      file.copy(archivo_tmp(), file)
    }
  )
}

# Run app
shinyApp(ui, server)
