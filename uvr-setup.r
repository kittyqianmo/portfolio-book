
pak::pak("nbafrank/uvr-r")   # the uvr R package, from GitHub
uvr::install_uvr()           # installs the uvr binary 
uvr::init() 
uvr::r_install("4.5.2") 
uvr::r_pin("4.5.2")
uvr::add("rdatagouv") 
uvr::add("janitor") 
uvr::add("pheatmap")
uvr::add("pins")
uvr::add("ggplot2")