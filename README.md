# The Three Point Revolution: NBA vs NCAA


### Data

I used play-by-play data from the 2025 NBA and NCAA seasons sourced from the hoopR R package. I categorized shots into 12 zones on the court based off the coordinates. NCAA data is filtered to only look at the top 100 teams.

### Questions

- Has the three point revolution effected NBA or NCAA teams more?
- Is the approach of shooting more threes correct? 
- Does it generate more efficient offense?

### Plots

Here are a couple plots I used to help explore my research questions.

```{r}
#| echo: false
# Compute shot count per zone per league
zone_counts <- shot_df |>
  count(league, shot_zone) |>
  group_by(league) |>
  mutate(shot_pct = n / sum(n) * 100)  # % of shots from that zone

# Join back so every point knows its zone's shot %
shot_df <- shot_df |>
  left_join(zone_counts, by = c("league", "shot_zone"))

# Plot color by shot_pct, increase point size to fill zones visually
ggplot(shot_df, aes(x = coordinate_y, y = 47 - abs(coordinate_x), color = shot_pct)) +
  geom_point(size = 1.1, alpha = 0.8) +
  facet_wrap(~league) +
  scale_color_gradient(
    name = "% of Shots",
    low = "#fde8e8",
    high = "#8b0000"
  ) + 
  coord_fixed() +
  theme_minimal(base_size = 24) +
  labs(
    title = "Shot Distribution by Zone",
    x = NULL, y = NULL
  )
```

```{r}
#| echo: false
zone_pts <- shot_df |>
  group_by(league, shot_zone) |>
  summarise(pts_per_shot = mean(shot_outcome * pts_value, na.rm = TRUE), .groups = "drop")

shot_df <- shot_df |>
  left_join(zone_pts, by = c("league", "shot_zone"))

ggplot(shot_df, aes(x = coordinate_y, y = 47 - abs(coordinate_x), color = pts_per_shot)) +
  geom_point(size = 1.1, alpha = 0.8) +
  facet_wrap(~league) +
  scale_color_gradient(
    name = "Pts/Shot",
    low = "#fde8e8",
    high = "#8b0000"
  ) +
  coord_fixed() +
  theme_minimal(base_size = 24) +
  labs(
    title = "Points per Shot by Zone",
    x = NULL, y = NULL
  )
```

### Conclusion

I found that both NBA and NCAA teams are trying to limit mid range shots and increase their three point attempts. The NBA has adopted this philosophy more aggressively than the NCAA, but both leagues are trending in the same direction. I also was able to determine that this is the correct approach. Three pointers are much more valuable than mid range shots, and generate a higher average of points per shot. 

I also included an interactive shiny app for this project, allowing users to compare shot distribution, field goal percentage, and points per shot across NBA and NCAA teams or players.

The link to the app can be found here:
[ShinyApp](https://jacobilafferty.shinyapps.io/NBAvsNCAA/)
