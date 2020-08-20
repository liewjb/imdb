library(tidyverse)
library(RCurl)
library(curl)
library(magrittr)
library(rvest)
library(furrr)
future::plan(multiprocess)

links <- read_csv('links.csv')
only_4 <- read_csv('only4.csv')

## OMDB API for downloading images

imgAPI <- 'http://img.omdbapi.com/?apikey=9c9e16a&i=tt'
rootDir <- 'data/images/'
get_img <- function(id, genre = "Action"){
  url <- paste0(imgAPI,str_pad(id, 7, pad = "0"))
  if(url.exists(url)){
    curl_download(url = url ,destfile = paste0(rootDir, genre, '/tt',id,'.png'))
  }
}

map2(only_4$imdbId, only_4$genre, get_img)


posters <- list.files('./data/images/')
links <- links %>%
  mutate(poster = paste0('tt',imdbId,'.png')) %>%
  filter(poster %in% posters)

full_movie_info <- movies %>%
  inner_join(links, by = 'movieId') %>%
  mutate(year = substr(title, nchar(title)-4,nchar(title)-1)) %>%
  select(imdbId, title, year, genres, poster) %>%
  separate(genres, c('genres1','genres2', 'genres3', 'genres4', 'genres5','genres6', 'genres7', 'genres8', 
                     'genres9', 'genres10', 'genres11')) %>% 
  filter(year > 1950)

library(jpeg)
for(r in seq(1, nrow(full_movie_info))){
  full_movie_info$height[r] = dim(readJPEG(paste0("data/images/", full_movie_info$poster[r])))[2]
  full_movie_info$width[r] = dim(readJPEG(paste0("data/images/", full_movie_info$poster[r])))[1]
}

final <- full_movie_info %>% 
  gather(genres, genre, genres1:genres11) %>%
  select(imdbId:height, genre) %>%
  group_by(imdbId, genre) %>%
  summarize(value = n()) %>%
  drop_na() %>%
  spread(genre, value, fill = 0) %>%
  left_join(full_movie_info) %>%
  select(imdbId:Fantasy, Horror, Musical:Mystery, Noir:Western, title, year, height, poster) %>%
  mutate(total_genres = Action + Adventure + Animation + Children + Comedy + Crime + Documentary + Drama + Fantasy + Horror + Musical + Mystery + Noir + Romance + Sci + Thriller + War + Western) %>%
  filter(total_genres != 0)

write_csv(final, 'full_movies.csv')

#Delete movie poster we are not going to use

delete_poster <- links %>%
  anti_join(final) %>%
  mutate(file = paste0('data/images/',poster))

sapply(delete_poster$file, file.remove)
sapply(delete_poster$file, file.exists)
