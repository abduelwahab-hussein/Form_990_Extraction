# Pretty simple code in R to clean the data
# NOTE: The most important part of this code is the "Create" section. It harmonizes Form 990 and Form 990 EZ data that needs harmonizing. For instance, the IRS asks NPOs filing Form 990s for "Other Expenses", but they ask NPOs filing Form 990 EZ for four different types of "Other Expenses". Thus, the sum of the four expenses for an NPO that filed a Form 990 EZ is logically similar to the "Other Expenses" category of Form 990s.
# NOTE 2: "Create" also creates (how did you guess??) some cool variables that an MIT study on endowments created. Might be useful for your NPO research!

# ------ LOAD LIBRARIES -----
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(data.table)
library(reshape)
library(reshape2)
library(stargazer)

# ------ LOAD DATASETS -----
form_data <- read.csv("form_data.csv")

# -------------------- Append X40 with Muslim_Nonmuslim. Then, clean duplicate obs, i.e. intersection btwn X40 & Islam/Muslim  ------------------------- 

duplicates <- form_data %>%
  filter(duplicated(form_data[c("EIN", "Tax_Year")]) | duplicated(form_data[c("EIN", "Tax_Year")], fromLast = TRUE))


form_990ez_data <- read.csv("form_990ez_data.csv")

filer_data <- read.csv("/filer_data.csv")

schedule_A_data <- read.csv("schedule_A_data.csv")

schedule_D_data <- read.csv("schedule_D_data.csv")

# -------------------- DROP DUPLICATES  ------------------------- 

# filer data has excess filer data bc likely needed to specify in beautiful soup filers... Just join_inner on form_990 and form_990ez. same thing goes for header.
filer_data <- filer_data[!duplicated(filer_data[c("EIN","Tax_Year")]),]

form_data <- form_data[!duplicated(form_data[c("EIN","Tax_Year")]),]
form_data$X990_Type <- as.character(form_data$X990_Type)

form_990ez_data <- form_990ez_data[!duplicated(form_990ez_data[c("EIN","Tax_Year")]),]

schedule_A_data <- schedule_A_data[!duplicated(schedule_A_data[c("EIN","Tax_Year")]),]

schedule_D_data <- schedule_D_data[!duplicated(schedule_D_data[c("EIN","Tax_Year")]),]


form_990 <- bind_rows(form_data, form_990ez_data) # don't add form 990 pf
colnames(form_990)

# -------------------- Merge  ------------------------- 

form_master <- merge(filer_data, form_990, by=c("EIN", "Tax_Year"), all = FALSE)  # We are doing an inner join bc file & master has PFs and we only want non PF 
form_master <- merge(form_master, schedule_A_data, by = c("EIN", "Tax_Year"), all = TRUE)

# Drop overlapping vars
form_master <- subset(form_master, select = -c(X.y, Name.y, x40.y))

# cut nonprofits with low revenue
form_master <- subset(form_master,Total_Revenue>10000 | Total_Expenses>10000)

# -------------------- Create ------------------------- 

# Create "Other_Expenses", which is sum of four
form_master <- form_master %>%
  mutate(Other_Expenses = Other_Expenses_1 + Other_Expenses_2 + Other_Expenses_3 + Other_Expenses_4)

# Create the C_S_I_990 and then replace it with the true C_S_I value if the NPO is a 990.
form_master <- form_master %>%
  mutate(C_S_I_All = rowSums(select(., C_S_I_EOY,  C_S_I_EOY_1 , C_S_I_EOY_2,C_S_I_EOY_3,C_S_I_EOY_4,C_S_I_EOY_5,C_S_I_EOY_6,C_S_I_EOY_7,
                                    C_S_I_EOY_8,C_S_I_EOY_9,C_S_I_EOY_10,C_S_I_EOY_11,C_S_I_EOY_12), na.rm = TRUE)) %>%
  mutate(Cont_Grants_All = rowSums(select(., Cont_Grants, Cont_Grants_1, Cont_Grants_2), na.rm = TRUE)) %>%
  mutate(Other_Revenue_All = rowSums(select(., Other_Revenue,Other_Revenue_1,Other_Revenue_2,Other_Revenue_3,Other_Revenue_4), na.rm = TRUE)) 

# Make O_D_Compensation missing for 990EZ bc 990EZ doesn't have O_D comp, it only has total comp, which are different
form_master$O_D_Comp_Exp[form_master$X990_TYPE == "990EZ"] <- NA
form_master$Inv_Man_Exp[form_master$X990_TYPE == "990EZ"] <- NA
form_master$Num_Board[form_master$X990_TYPE == "990EZ"] <- NA
form_master$Num_Indep_Board[form_master$X990_TYPE == "990EZ"] <- NA
form_master$Program_Exp[form_master$X990_TYPE == "990EZ"] <- NA
form_master$Admin_Exp[form_master$X990_TYPE == "990EZ"] <- NA
form_master$Travel_Exp[form_master$X990_TYPE == "990EZ"] <- NA


# Create variables based on MIT Paper (SSRN-id3560240.pdf)
form_master <- form_master %>%
  mutate_at(c(  'Number_Employed','Cont_Grants','Prog_Revenue',
                'Investment_Income', 'Other_Revenue', 'Total_Revenue',
                'Grants_Expenses','Benefits_Expenses','Total_Comp',
                'Fundraising_Exp', 
                'Other_Expenses', 'Total_Expenses', 'Net_Revenue',
                'Total_Assets_EOY', 'Net_Assets_BOY', "Net_Assets_EOY", 
                'Total_Comp_Alt', 'Num_Above_100', 'Num_Board', 'Num_Indep_Board',
                'L_B_EOY', 'O_D_Comp_Exp', 'Travel_Exp', 'Admin_Exp',
                'Program_Exp', 'Inv_Man_Exp','C_S_I_EOY', 'Other_Assets_EOY'), ~replace_na(.,0)) %>%
  mutate(Program_Exp_Ratio = Program_Exp/Total_Expenses) %>% # no 990ez data on this
  mutate(Admin_Exp_Ratio = Admin_Exp/Total_Expenses) %>% # Only 990
  mutate(Fundraising_Exp_Ratio = Fundraising_Exp/Total_Expenses) %>% # both
  mutate(O_D_Ratio = O_D_Comp_Exp/Total_Expenses) %>% # 990
  mutate(Travel_Ratio = Travel_Exp/Total_Expenses) %>% # 990
  mutate(Board_Independence = Num_Indep_Board/Num_Board ) #990


write_csv(form_master, "~/990_Research/jewish_data/form_master.csv")