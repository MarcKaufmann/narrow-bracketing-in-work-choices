require(tidyverse)

fulldf <- read_csv("full_raw_data.csv")

# Clean the dataset:
# 1. Drop variables with no information (i.e. constant value)
# 2. Replace playerNr by unique pid (rownumber()), keep treatment information
#   - Keep playerNr to compare with raw data
# 3. Document variable names
# 4. Collect rows by scenario
# 5. Identify inconsistent choices by scenarios
# 6. Get unique switching point for consistent choices by scenario x pid
#   - requires identifying the payment associated with the switching point
# 7. Compute reservation wages from switching points and treatments/scenarios
# 8. Save smaller dataset for direct analysis

# Step 1: drop variables with no information that have constant values
takes_on_only_one_value <- function(cname)  { 
  length(unique(fulldf[[cname]])) == 1 
}

colnames_to_discard <- fulldf %>% 
  select(-starts_with("wta"), -starts_with("incons")) %>%
  colnames() %>%
  as.list() %>%
  keep(takes_on_only_one_value)

df1 <- select(fulldf, -as_vector(colnames_to_discard))

# Step 2: 
df2 <- df1 %>%
  mutate(pid = row_number()) %>%
  select(pid, everything())

# Step 3:

df3 <- df2 %>% rename(scenariochosen = scenario)
# pid: unique participant ID
# treatment: number indicating treatment of participant
#   1: BOTH
#   2: MONEY/LOW
#   3: NONE
#   4: MONEY
#   5: BEFORE
#   6: AFTER
# relevant: choice that matters, first 16 are scenario 1 next 16 are scenario 32
# t2_correcttexts: (DROP) related to task performance
# t2_numseq: (DROP) related to task performance
# t2_answer: ???
# tediousness: rating of tediousness of task from 1 (not at all tedious) to 10 (very tedious)
# test: get to attrition
# wtaNM: answer to choice M in scenario N, where 1 means default, 2 means higher work option
# pchosen: the variable payment chosen (at random) for this participant
#     participants receive it if they chose the option with higher work and do the work     
# optionchosen: the option the participant chose for the randomly determined choice that matters
#     1: the default option (low work)
#     2: the variable option with variable payment (high work)
# extra: the extra tasks they have to do based on their choice (on top of endowment/baseline) 
#     0 if optionchosen == 1, 15 if optionchosen == 2
# scenariochosen: the scenario that is randomly chosen to matter
#     scenario 1 is the first price list; scenario 2 the second 
# rel: (DROP) seems unnecessary, same as old playerNr
# totaltask: total number of tasks the participant has to do
# vchosen: chosen payment from the choice, ignoring the baseline payment. 
#     From 4.00 to 1.00 in 0.25 increments
#     Contains baseline payment in BROAD, since that's how the choice is presented.
# gender: self-reported gender 1 == 'Male', 2 == 'Female', 3 == 'Other'?
# age: self-reported age in years
# bonus: DROP, related to payment calculations, depends on treatment
# total: total payment received, including participation bonus
# (DROP all time_* variables, except time_encryption_main_task, which we need to compute how long participants take to do the tasks) all time_* variables denote the time in seconds taken on that step
# time_welcome:
# time_instructions_pre:
# time_encryption_task:
# time_questionnaire1:
# time_task_preparation:
# time_summary:
# time_encryption_main_task:
# time_questionnaire2:
# session_date: date and time of the experimental session the participant was part of
#     different sessions were run on different dates
#     sessions to session 8, NARROW sessions were done with baseline
#     on the page before choices, afterwards first mention on choice page

# Step 4: Collect pid x scenario into separate rows

# First standardize the names of wta that depend on scenarios so that they end in _1 or _2 for scenario 1 or 2.
df4a <- df3 %>%
  rename_with(
    function(x) {str_replace(x, "(\\d)(\\d\\d?)", "\\2_\\1")},
    c(starts_with("wta"))
  ) 

df4 <- df4a %>%
  pivot_longer(
    c(starts_with("wta")),
    names_to = c(".value", "scenario"),
    names_pattern = "(.*)_(\\d)"
  )

# Step 5: Identify inconsistent choices
# But first drop all participants who don't have full answers to all wta
is_consistent <- function(wta0, wta1) {
  if_else( wta0 <= wta1, 0, 1)
}

df5a <- df4 %>%
  mutate(
    consistent1  = is_consistent(wta1, wta2),
    consistent2  = is_consistent(wta2, wta3),
    consistent3  = is_consistent(wta3, wta4),
    consistent4  = is_consistent(wta4, wta5),
    consistent5  = is_consistent(wta5, wta6),
    consistent6  = is_consistent(wta6, wta7),
    consistent7  = is_consistent(wta7, wta8),
    consistent8  = is_consistent(wta8, wta9),
    consistent9  = is_consistent(wta9, wta10),
    consistent10 = is_consistent(wta10, wta11),
    consistent11 = is_consistent(wta11, wta12),
    consistent12 = is_consistent(wta12, wta13),
    consistent13 = is_consistent(wta13, wta14),
    consistent14 = is_consistent(wta14, wta15),
    consistent15 = is_consistent(wta15, wta16)
  )

df5 <- df5a %>%
  mutate(across(starts_with("consistent"), function(x) (x == 0)))

stopifnot(all(is.na(df5$consistent15) | (df5$consistent15 == (df5a$consistent15 == 0))))

# Step 6: Get lowest switching point, and number of inconsistent choices
# per person per scenario. 

# Get lowest switching point, set to 17 if never choose higher work option
# Get second lowest switching point, set to 17 if never choose higher work option

df6a <- df5 %>% 
  select(pid, scenario, starts_with("wta"), starts_with("consistent")) %>%
  pivot_longer(
    c(starts_with("wta"), starts_with("consistent"),),
    names_pattern = "(wta|consistent)(\\d\\d?)",
    names_to = c(".value", "option_number")
  ) %>%
  mutate(option_number = parse_number(option_number)) 

df6b <- df6a %>%
  group_by(pid, scenario) %>%
  summarise(
    inconsistent_choices = sum(!consistent, na.rm=TRUE),
    switching_point = first(sort(option_number[wta == 2], na.last=TRUE), default = 17)
  )

df6 <- df5 %>%
  select(-starts_with("wta"), -starts_with("consistent")) %>%
  left_join(df6b, by = c("pid", "scenario")) %>%
  select(
    pid, 
    scenario, 
    treatment, 
    switching_point,
    inconsistent_choices,
    everything()
  )

# Step 7: Compute reservation wages
# Which numbers correspond to which treatments?
# Treatment 1 seems NARROW (originally called NARROW+)
# Treatment 3 seems BROAD
# Treatment 4 seems PARTIAL
# Treatment 2 is LOW
# Doesn't matter for switching point, it is always how much more I have to be paid
# Which is always switching point times 0.25 (dollars)

df7 <- df6 %>%
  mutate(
    reservation_wage = 0.25 * switching_point
  ) %>%
  # Drop columns we don't need
  select(-c(starts_with("t2_"),
            "rel",
            "bonus",
            "playerNr",
            ))

  # Step 8: Recode treatment and gender

library(lubridate)

march1 <- ymd("20200301")

df8 <- df7 %>%
  mutate(
    treatment = as_factor(case_when(
      (date(session_date) < march1) & (treatment == 1) ~ 'NARROW',
      (date(session_date) < march1) & (treatment == 2) ~ 'LOW',
      (date(session_date) < march1) & (treatment == 3) ~ 'BROAD',
      (date(session_date) < march1) & (treatment >= 4) ~ 'PARTIAL',
      (treatment == 1)                                 ~ 'BEFORE',
      (treatment == 2)                                 ~ 'AFTER'
      )),
    scenario  = as_factor(dplyr::recode(scenario, `1` = 'Scenario1', `2` = 'Scenario2')),
    gender    = as_factor(dplyr::recode(gender,
                                 `1` = 'Male',
                                 `2` = 'Female',
                                 `3` = 'Other'
  )))

# Step 9: Save data to csv-file
write_csv(df8, "clean_data.csv")
