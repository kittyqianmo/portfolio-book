url1 <- "https://raw.githubusercontent.com/AMLab-Amsterdam/CEVAE/refs/heads/master/datasets/TWINS/twin_pairs_T_3years_samesex.csv"

url2<-"https://raw.githubusercontent.com/AMLab-Amsterdam/CEVAE/refs/heads/master/datasets/TWINS/twin_pairs_X_3years_samesex.csv"

url3<-"https://raw.githubusercontent.com/AMLab-Amsterdam/CEVAE/refs/heads/master/datasets/TWINS/twin_pairs_Y_3years_samesex.csv"




download.file(url1, "twinsdata1.csv")
download.file(url2, "twinsdata2.csv")
download.file(url3, "twinsdata3.csv")

install.packages("readr")
install.packages("dplyr")
library(readr)

df <- read_csv("twinsdata2.csv") 

library(dplyr)
df <- df |>
  select(-`...1`, -`Unnamed: 0`)
head(df)


library(naniar)   

colMeans(is.na(df)) |>
  sort(decreasing = TRUE) |>
  round(3) |>
  head(90)



head(df)
