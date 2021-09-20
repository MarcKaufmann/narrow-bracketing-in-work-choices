library(tidyverse)
library(AER)
library(kableExtra)
library(stargazer)
library(lubridate)

df_all <- read_csv("clean_data.csv") %>%
  mutate(
    gender    = as_factor(gender),
    treatment = fct_relevel(as_factor(treatment), "BROAD", "NARROW", "LOW", "PARTIAL", "BEFORE", "AFTER"),
    scenario  = as_factor(scenario)
  ) %>%
  ## Rename the treatments in line with the text
  mutate(
    treatment = dplyr::recode(treatment,
                              BROAD   = "NONE",
                              NARROW  = "BOTH",
                              LOW     = "MONEY/LOW",
                              PARTIAL = "MONEY")
  )

consistent_df_all <- df_all %>%
  ## Keep only choices which were done consistently (drop only that scenario)
  filter(inconsistent_choices == 0) %>%
  ## Keep only people who finish the study and hence the tasks
  filter(!is.na(time_questionnaire2)) %>%
  select(pid, scenario, treatment, reservation_wage, inconsistent_choices, everything())

session_randomization <- df_all %>%
  # Drop participants who never go beyond the welcome page (identical across all treatments)
  filter(!is.na(time_welcome)) %>%
  select(session_date, treatment, scenario) %>%
  filter(treatment %in% c("MONEY/LOW", "BOTH", "MONEY", "NONE"), scenario == "Scenario2") %>%
  count(treatment, session_date) %>%
  pivot_wider(names_from = treatment, values_from = n, values_fill = 0) %>%
  arrange(session_date) %>%
  mutate(session_id = row_number(), session_date = date(session_date)) %>%
  select(session_id, everything())

consistent_dfba <- consistent_df_all %>%
  filter(treatment %in% c("BOTH", "BEFORE", "AFTER"))
consistent_df <- consistent_df_all %>%
  filter(treatment %in% c("MONEY/LOW", "BOTH", "MONEY", "NONE"))

options(knitr.kable.NA = '')

rbind(session_randomization, imap_dfr(session_randomization, function(x, y) { if (!(y %in% c("session_id", "session_date"))) sum(x) else NA})) %>%
  rename(`Session ID` = "session_id", `Session Date` = session_date) %>%
  kbl(
    booktabs = T,
    caption = "Participant numbers by sessions and treatments",
    digits=2,
    align='rrrrr',
    format='latex',
    label='session_summary'
  ) %>%
  kable_styling(font_size=12, latex_options = "hold_position") %>%
  row_spec(15, hline_after = TRUE) %>%
  write("session_summary.tex")

                                        # Summary Statistics

summary_stats <- function(df) {
  # Only consider participants who finish the welcome screen
  df0 <- df %>%
    filter(!is.na(time_welcome)) %>%
    select(pid, scenario, inconsistent_choices) %>%
    pivot_wider(names_from = scenario, values_from = inconsistent_choices) %>%
    left_join(df %>% filter(scenario == "Scenario1"), by = "pid") %>%
    mutate(
      dropped_out   = is.na(time_questionnaire2),
      inconsistent1 = (Scenario1 > 0),
      inconsistent2 = (Scenario2 > 0)
    )

  df1 <- df0 %>%
    group_by(treatment) %>%
    summarize(
      observations  = n(),
      attrition     = paste0(round(100*mean(dropped_out), digits=1), "%"),
      final_obs     = as.character(sum(!dropped_out, na.rm=TRUE)),
      share_female  = round(mean(gender == "Female", na.rm=TRUE), digits=2),
      age           = round(mean(age, na.rm=TRUE),digits =1),
      tediousness   = round(mean(tediousness, na.rm=TRUE), digits=2),
      inconsistent1 = sum(inconsistent1, na.rm=TRUE),
      inconsistent2 = sum(inconsistent2, na.rm=TRUE)
    ) %>%
    mutate(treatment = as.character(treatment)) %>%
    ungroup()

  chi.p.value <- function(v) {
    round(chisq.test(df0$treatment, df0[[v]], correct=FALSE)$p.value, digits = 2)
  }

  df1 %>%
    rbind(c(
      treatment     = "p-value",
      observations  = "",
      attrition     = chi.p.value("dropped_out"),
      final_obs     = "",
      share_female  = chi.p.value("gender"),
      age           = chi.p.value("age"),
      tediousness   = chi.p.value("tediousness"),
      inconsistent1 = chi.p.value("inconsistent1"),
      inconsistent2 = chi.p.value("inconsistent2")
      ))
}

ss <- t(summary_stats(df_all %>% filter(treatment %in% c("BOTH", "MONEY/LOW", "MONEY", "NONE"))))
rownames(ss) <- c("", "Participants", "Attrition", "Final Participants", "Share Female", "Age", "Tediousness", "Scenario 1", "Scenario 2")

kbl(
  ss,
  booktabs = T,
  caption = "Summary statistics for main treatments.",
  digits=2,
  align='rrrrr',
  format='latex',
  label='summary_statistics'
) %>%
  kable_styling(font_size=12, latex_options = "hold_position") %>%
  row_spec(1, bold = TRUE, hline_after = TRUE) %>%
  row_spec(4, hline_after = TRUE) %>%
  row_spec(7, hline_after = TRUE) %>%
  pack_rows("Inconsistent Choices", 8, 9) %>%
  write("summary_statistics_main.tex")

ssba <- t(summary_stats(df_all %>% filter(treatment %in% c("BOTH", "BEFORE", "AFTER"))))

rownames(ssba) <- c("", "Participants", "Attrition", "Final Participants", "Share Female", "Age", "Tediousness", "Scenario 1", "Scenario 2")

kbl(
  ssba,
  booktabs = TRUE,
  caption = "Summary statistics for follow-up treatments",
  digits = 2,
  format = 'latex',
  align='rrrr',
  label='summary_stats_before_after',
  row.names =
    ) %>%
  kable_styling(font_size=12, latex_options = "hold_position") %>%
  row_spec(1, bold = TRUE, hline_after = TRUE) %>%
  row_spec(4, hline_after = TRUE) %>%
  row_spec(7, hline_after = TRUE) %>%
  pack_rows("Inconsistent Choices", 8, 9) %>%
  write("summary_statistics_before_after.tex")

# Welcome time implies they saw the welcome screen
# time_instructions: they read instructions
# time_encryption_task: they did the practice tasks
# time_questionnaire: got to questionnaire
# time_task_preparation: they saw and completed the prep
# time_questionnaire2: they completed the study:
# wta1 in scenario1: they completed the first choice:

attrition_stats <- function(df) {
  paste_to_percent <- function(v) paste0(as.character(round(v)), "%")
  df0 <- df %>%
    filter(!is.na(time_welcome))
  df0 %>%
    # Count every person only once, not once per scenario
    filter(scenario == "Scenario1") %>%
    group_by(treatment) %>%
    summarise(
      practice_tasks    = 100*sum(is.na(time_encryption_task))/n(),
      # FIXME: Check that time_task_preparation really is the page before the first choice
      study_description = 100*sum(is.na(time_task_preparation))/n(),
      answer1           = 100*sum(is.na(reservation_wage))/n(),
      learn_total_tasks = 100*sum(is.na(time_summary))/n(),
      finish_study      = 100*sum(is.na(time_questionnaire2))/n()
    ) %>%
    # FIXME: Use mutate across
    mutate(
      practice_tasks    = paste_to_percent(practice_tasks),
      study_description = paste_to_percent(study_description),
      answer1           = paste_to_percent(answer1),
      learn_total_tasks = paste_to_percent(learn_total_tasks),
      finish_study      = paste_to_percent(finish_study)
    )
}

attrition_stats(df_all) %>%
  kbl(
    booktabs = T,
    caption = "Attrition in \\% by a given stage",
    digits=0,
    col.names = c("Treatments", "Practice", "Choice 1", "Answer 1", "Learn Tasks", "End"),
    align = 'lrrrrr',
    format = 'latex',
    label = 'attrition'
  ) %>%
  kable_styling(latex_options="striped", font_size=12) %>%
  pack_rows("Main", 1, 4) %>%
  pack_rows("Follow Up", 5, 6) %>%
  write("attrition_statistics.tex")

## Set to NULL to avoid using data with inconsistent choices in the analysis
df_all <- NULL

## Find out how many people report a higher WTW for Scenario 2 than Scenario 1, stay, or go down.
df_all_reservation_wage_change <- consistent_df %>%
  select(-c(switching_point, inconsistent_choices)) %>%
  pivot_wider(names_from = scenario, values_from = reservation_wage) %>%
  mutate(reservation_wage_change = Scenario2 - Scenario1) %>%
  mutate(reservation_wage_direction = case_when(
           reservation_wage_change > 0  ~ "Up",
           reservation_wage_change == 0 ~ "Stay",
           reservation_wage_change < 0  ~ "Down"
         ))

reservation_wage_direction <- df_all_reservation_wage_change %>%
  group_by(treatment, reservation_wage_direction) %>%
  summarize(n = n()) %>%
  mutate( freq = 100 * round(n/sum(n), digits=2 )) %>%
  select(-n) %>%
  pivot_wider( names_from = reservation_wage_direction, values_from = freq ) %>%
  mutate( `Up - Down` = Up - Down ) %>%
  rename(
    Treatment = treatment,
    `Drop out` = `NA`
  )

reservation_wage_change <- df_all_reservation_wage_change %>%
  filter(!is.na(reservation_wage_change)) %>%
  group_by(treatment, reservation_wage_direction) %>%
  summarize(avg = round(mean(reservation_wage_change), digits=2)) %>%
  pivot_wider( names_from = reservation_wage_direction, values_from = avg ) %>%
  select(treatment, Down, Up) %>%
  rename(Treatment = treatment)

kbl(
  reservation_wage_direction,
  booktabs = T,
  caption = "Frequencies (in \\%) of individuals who switch up, switch down, or stay at the same reservation wage from scenario 1 to scenario 2. The final column reports how many more people switch up rather than down.",
  digits=0,
  align = 'lrrrrr',
  format = 'latex',
  label = 'rw_direction_between_scenarios'
) %>%
  kable_styling(latex_options="striped", font_size=12) %>%
  write("rw_direction_change_between_scenarios.tex")

kbl(
  reservation_wage_change,
  booktabs = T,
  caption = "Average individual-level change in reservation wage, conditional on whether the jump was up or down.",
  align = 'lrrrrr',
  format = 'latex',
  label = 'rw_change_between_scenarios'
) %>%
  kable_styling(latex_options="striped", font_size=12) %>%
  write("rw_change_between_scenarios.tex")
