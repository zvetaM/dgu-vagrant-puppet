core = 7.x
api = 2
projects[drupal][version] = 7.21

projects[dgu][type] = "profile"
projects[dgu][download][type] = "git"
projects[dgu][download][url] = "https://github.com/datagovuk/dgu_d7.git"

; download missing d3.js and d3.min.js files
; TODO: move to dgu_d7 make after forking it
libraries[d3][download][type] = "get"
libraries[d3][download][url] = "https://github.com/d3/d3/releases/download/v3.5.17/d3.zip"
libraries[d3][directory-name] = "d3"
libraries[d3][destination] = "libraries"

