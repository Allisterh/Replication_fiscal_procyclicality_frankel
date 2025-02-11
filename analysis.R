library(tidyverse)
library(magrittr)
library(broom)
library(estimatr)
library(carData)
library(tidyquant)
library(plm)
library(stargazer)

## Visualizing pro cyclicality across the countries available.
# All the years
dtaFinal %>%
  group_by(Country) %>%
  summarise(Correlation = cor(cyclelNGDP_R, cyclelGGX_R)) %>%
  arrange(Correlation) %>%
  mutate(CountryName = factor(Country, levels=Country),
         Is_Procyc = if_else(condition = Correlation > 0,true = 1, false = 0)) %>%
  ggplot(mapping = aes(y = Correlation, x = CountryName, fill=factor(Is_Procyc))) +
  geom_bar(stat = "identity", alpha =.6, width = .4, show.legend = FALSE) +
  scale_fill_manual(values = c("#f68060", "#DD2C0C")) + 
  coord_flip() +
  xlab("") +
  theme(axis.text.x = element_text(angle = 45)) +
  theme_bw()
# Previous to the great global recession
dtaFinal %>%
  group_by(Country) %>%
  filter(Year <= 2007) %>%
  summarise(Correlation = cor(cyclelNGDP_R, cyclelGGX_R)) %>%
  arrange(Correlation) %>%
  mutate(CountryName = factor(Country, levels=Country),
         Is_Procyc = if_else(condition = Correlation > 0,true = 1, false = 0)) %>%
  ggplot(mapping = aes(y = Correlation, x = CountryName, fill=factor(Is_Procyc))) +
  geom_bar(stat = "identity", alpha =.6, width = .4, show.legend = FALSE) +
  scale_fill_manual(values = c("#f68060", "#DD2C0C")) + 
  coord_flip() +
  xlab("") +
  theme(axis.text.x = element_text(angle = 45)) +
  theme_bw()
# After to the great global recession
dtaFinal %>%
  group_by(Country) %>%
  filter(Year > 2007) %>%
  summarise(Correlation = cor(cyclelNGDP_R, cyclelGGX_R)) %>%
  arrange(Correlation) %>%
  mutate(CountryName = factor(Country, levels=Country),
         Is_Procyc = if_else(condition = Correlation > 0,true = 1, false = 0)) %>%
  ggplot(mapping = aes(y = Correlation, x = CountryName, fill=factor(Is_Procyc))) +
  geom_bar(stat = "identity", alpha =.6, width = .4, show.legend = FALSE) +
  scale_fill_manual(values = c("#f68060", "#DD2C0C")) + 
  coord_flip() +
  xlab("") +
  theme(axis.text.x = element_text(angle = 45)) +
  theme_bw()

# Country-specific examples
dtaFinal %>%
  group_by(Country) %>%
  mutate(Year = as_date(Year, format = "%Y")) %>%
  tq_mutate_xy(x = cyclelNGDP_R, y = cyclelGGX_R, mutate_fun = runCor, n = 10,
               use = "pairwise.complete.obs", col_rename = "Procyc_Deg") %>%
  filter(Country %in% c("Argentina", "Chile", "Canada") & Year > 1999) %>%
  ggplot(aes(x=Year, y=Procyc_Deg, color=Country)) +
  geom_line() +
  labs(title = "10-years Window Rolling Correlation between Government Purchases and GDP\nCyclical Components", y = "") +
  xlim(as_date("1990", format = "%Y"), NA) +
  theme_bw()

dtaFinal %>%
  group_by(Country) %>%
  mutate(Year = as_date(Year, format = "%Y")) %>%
  filter(Country %in% c("Argentina", "Chile", "Canada") & Year > 1999) %>%
  ggplot(aes(x=Year, y=IQindex, color=Country)) +
  geom_line(aes(group=Country)) +
  labs(y = "",  title = "Institutional Quality Index") +
  xlim(as_date("1996", format = "%Y"), NA) +
  theme_bw()

# The observed relationship between Institutional Quality and Fiscal Policy Cyclicality.

IQaverage <- ICRG_OCDELATAM %>%
  group_by(Country) %>%
  summarise(Average_IQ = mean(IQindex))

df_corrs %>%
  group_by(Country) %>%
  summarise(Correlation = cor(cyclelNGDP_R, cyclelGGX_R)) %>%
  left_join(IQaverage) %>%
  ggplot(aes(x=Average_IQ, y=Correlation)) +
  geom_point(stat = "identity") +
  labs(y = "Corr(G, GDP)") +
  theme_bw()


## Regression analysis


dtaFinal_reduc <- dtaFinal %>%
  filter(Year >= "1996-01-16" & Year < "2016-01-16") %>%
  mutate_at(.vars = "DebtPCHGDP", .funs = as.double) %>%
  group_by(Country) %>%
  mutate(Year = as_date(Year, format = "%Y")) %>%
  tq_mutate_xy(x = cyclelNGDP_R, y = cyclelGGX_R, mutate_fun = runCor, n = 10,
               use = "pairwise.complete.obs", col_rename = "Procyc_Deg")

dtaFinal %>%
  ggplot(aes(x = IQindex, y = Procyc_Deg)) +
  geom_point(na.rm = TRUE) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(y = "Rolling Correlation\nReal Government Purchases Cyle and Real GDP Cycle", x = "Institutional Quality Index", title = "Cross Country Relation between Government Purchases Cyclical Behavior and\nthe Institutional Quality Index")


dtaFinal %>%
  plm(cyclelGGX_R ~
    cyclelNGDP_R*IQindex +
    cyclelNGDP_R*IQchange,
    data = .,
    model = "pooling",
  ) %>%
  tidy()


dtaFinal %>%
  plm(cyclelGGX_R ~
    cyclelNGDP_R*IQindex,
    data = .,
    model = "within",
  ) %>%
  tidy()


fitted_table<-
  dtaFinal %>%
  plm(
    cyclelGGX_R ~
    cyclelNGDP_R +
    cyclelNGDP_R:IQindex +
    cyclelNGDP_R:ChinnIto +
    cyclelNGDP_R:DebtPCHGDP +
    cyclelNGDP_R:FER +
    cyclelNGDP_R:llgdp +
    cyclelNGDP_R:polity2,
    data = .,
    model = "within"
    ) %>%
  tidy()





  