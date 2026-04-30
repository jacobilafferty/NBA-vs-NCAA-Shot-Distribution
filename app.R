




library(shiny)
library(tidyverse)
library(glue)

# write as csv for shinyapp.io
shot_df <- read_csv("shot_df.csv")


ui <- fluidPage(
  titlePanel("NBA vs. NCAA Shot Zone Explorer"),
  sidebarLayout(
    sidebarPanel(
      radioButtons("compare_type", "Compare by:",
                   choices = c("Teams", "Players")),
      selectInput("metric", "Metric:",
                  choices = c("% of Shots" = "shot_pct",
                              "FG%"         = "fg_pct",
                              "Pts/Shot"    = "pts_per_shot")),
      hr(),
      strong("Selection 1"),
      radioButtons("league1", "League:", choices = c("NBA", "NCAA")),
      selectizeInput("selection1", "Team/Player:", choices = NULL),
      hr(),
      strong("Selection 2"),
      radioButtons("league2", "League:", choices = c("NBA", "NCAA")),
      selectizeInput("selection2", "Team/Player:", choices = NULL),
    ),
    
    mainPanel(
      fluidRow(
        column(6, plotOutput("plot1", height = "500px")),
        column(6, plotOutput("plot2", height = "500px"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # when league1 or compare_type changes, update selection1 dropdown
  observeEvent(c(input$league1, input$compare_type), {
    df <- shot_df |> filter(league == input$league1)
    if (input$compare_type == "Teams") {
      new_choices <- df |> distinct(team_name) |> pull(team_name) |> sort()
    } else {
      new_choices <- df |> filter(!is.na(athlete_display_name)) |>
        distinct(athlete_display_name) |> pull(athlete_display_name) |> sort()
    }
    updateSelectizeInput(inputId = "selection1", choices = new_choices)
  })
  
  # same for selection2
  observeEvent(c(input$league2, input$compare_type), {
    df <- shot_df |> filter(league == input$league2)
    if (input$compare_type == "Teams") {
      new_choices <- df |> distinct(team_name) |> pull(team_name) |> sort()
    } else {
      new_choices <- df |> filter(!is.na(athlete_display_name)) |>
        distinct(athlete_display_name) |> pull(athlete_display_name) |> sort()
    }
    updateSelectizeInput(inputId = "selection2", choices = new_choices)
  })
  
  # reactive 1
  reactive_df1 <- reactive({
    df <- shot_df |> filter(league == input$league1)
    if (input$compare_type == "Teams") {
      df |> filter(team_name == input$selection1)
    } else {
      df |> filter(athlete_display_name == input$selection1)
    }
  })
  
  # reactive 2
  reactive_df2 <- reactive({
    df <- shot_df |> filter(league == input$league2)
    if (input$compare_type == "Teams") {
      df |> filter(team_name == input$selection2)
    } else {
      df |> filter(athlete_display_name == input$selection2)
    }
  })
  
  
  # plot 1
  output$plot1 <- renderPlot({
    
    # labels for plot titles
    metric_label <- case_when(
      input$metric == "shot_pct" ~ "% of Total Shots",
      input$metric == "fg_pct" ~ "FG%",
      input$metric == "pts_per_shot" ~ "Expected Points Per Shot"
    )
    
    zone_stats <- reactive_df1() |>
      group_by(shot_zone) |>
      summarise(
        n = n(),
        low_sample  = n() < 15,
        fg_pct = mean(shot_outcome, na.rm = TRUE) * 100,
        pts_per_shot = mean(shot_outcome * pts_value, na.rm = TRUE),
        .groups = "drop"
      ) |>
      mutate(
        shot_pct = n / sum(n) * 100,
        value = if (input$metric == "shot_pct") shot_pct
        else if (input$metric == "fg_pct") fg_pct
        else pts_per_shot
      )
    
    plot_df <- reactive_df1() |> left_join(zone_stats, by = "shot_zone")
    
    ggplot(plot_df, aes(x = coordinate_y, y = 47 - abs(coordinate_x), color = value)) +
      geom_point(aes(alpha = if_else(low_sample, 0.15, 0.8)), size = 1.1) +
      scale_color_gradient(name = input$metric, low = "#fde8e8", high = "#8b0000") +
      scale_alpha_identity() +
      coord_fixed() +
      theme_minimal() +
      labs(title = glue::glue(input$selection1, " ", metric_label), 
           x = NULL, 
           y = NULL,
           caption = "Zones with less than 15 shots will be faded.")
  })
  
  # plot 2
  output$plot2 <- renderPlot({
    
    # labels for plot titles
    metric_label <- case_when(
      input$metric == "shot_pct" ~ "% of Total Shots",
      input$metric == "fg_pct" ~ "FG%",
      input$metric == "pts_per_shot" ~ "Expected Points per Shot"
    )
    
    zone_stats <- reactive_df2() |>
      group_by(shot_zone) |>
      summarise(
        n = n(),
        low_sample = n() < 15,
        fg_pct = mean(shot_outcome, na.rm = TRUE) * 100,
        pts_per_shot = mean(shot_outcome * pts_value, na.rm = TRUE),
        .groups = "drop"
      ) |>
      mutate(
        shot_pct = n / sum(n) * 100,
        value = if (input$metric == "shot_pct") shot_pct
        else if (input$metric == "fg_pct") fg_pct
        else pts_per_shot
      )
    
    plot_df <- reactive_df2() |> left_join(zone_stats, by = "shot_zone")
    
    ggplot(plot_df, aes(x = coordinate_y, y = 47 - abs(coordinate_x), color = value)) +
      geom_point(aes(alpha = if_else(low_sample, 0.15, 0.8)), size = 1.1) +
      scale_color_gradient(name = input$metric, low = "#fde8e8", high = "#8b0000") +
      scale_alpha_identity() +
      coord_fixed() +
      theme_minimal() +
      labs(title = glue::glue(input$selection2, " ", metric_label), 
           x = NULL, 
           y = NULL,
           caption = "Zones with less than 15 shots will be faded.")
  })
  
}

shinyApp(ui, server)
