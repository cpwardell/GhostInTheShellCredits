## This file contains functions to be sourced and should not be used or edited

## Load packages
library(ggplot2)
library(png)
library(grid)
library(extrafont)
library(knitr)

## Function to generate PNGs of background digits
digitcreator=function(digitcolor){
  dir.create("digits",showWarnings = FALSE)
  for(i in 0:9){
    ## Open a PNG device exactly X by Y pixels
    png(file.path("digits",paste0(i,".png")), width = 108, height = 160, units = "px", bg = "#000000")
  
    ## Start a new page
    grid.newpage()

    ## Draw character, filling the space
    grid.text(i, x = 0.5, y = 0.5, gp = gpar(fontsize = 150,fontfamily="Libre Bodoni",fontface="bold",col=digitcolor), just = "center")
    
    ## Close the device
    dev.off()
  }
}

## Function to generate row positions
generaterows=function(input){
  ## Find lowest and highest row positions in input
  ycoords=unlist(lapply(input,"[",3))
  types=unlist(lapply(input,"[",2))
  lowrow=min(ycoords)
  highrow=max(ycoords)

  ## Produce rows below lowest row
  currenty=lowrow
  while(currenty > -60){
    newrow=currenty-sample(150:160,1)
    ycoords=c(ycoords,newrow)
    types=c(types,sample(c("N","S2","S1"),1,prob=c(2/3,2/6,1/6)))
    currenty=newrow
  }
  ## Produce rows above highest row
  currenty=highrow
  while(currenty < 2100){
    newrow=currenty+sample(150:160,1)
    ycoords=c(ycoords,newrow)
    types=c(types,sample(c("N","S2","S1"),1,prob=c(2/3,2/6,1/6)))
    currenty=newrow
  }
  ## Return results in a dataframe  
  df=data.frame(ycoords=ycoords,types=types)
  return(df)
}

## Main function; generates all necessary base frames that will need postprocessing
generateframes=function(input,frames,savepngs=TRUE,outdir="output"){
  ## Perform processing on input to create fragments
  ## Results are assigned to named dataframes; e.g. T1 for title, N1.1 & N1.2 for a two-word name
  titleinputs=which(unlist(lapply(input,"[",2))%in%"S2")
  nameinputs=which(unlist(lapply(input,"[",2))%in%"N")
  print(titleinputs)
  print(nameinputs)
  message("Title rows converted to these outputs:")
  for(i in 1:length(titleinputs)){
    cuts=as.numeric(tryCatch({input[[titleinputs[i]]][[4]]},error = function(e) { return(NA) }))
    titlefrags=titlesplitter(input[[titleinputs[i]]][1],cuts)
    sfp=stringsforprint(titlefrags)
    assign(paste0("T",titleinputs[i]),sfp)
    print(kable(sfp))
  }
  message("Name rows converted to these outputs:")
  for(i in 1:length(nameinputs)){
    namefrags=namesplitter(input[[nameinputs[i]]][1])
    for(j in 1:length(namefrags)){
      sfp=stringsforprint(namefrags[[j]])
      assign(paste0("N",nameinputs[i],".",j),sfp)
      print(kable(sfp))
    }
  }
  
  ## Create an empty plot of the correct dimensions to use as a canvas
  ## We use the first row of the built-in mtcars dataset as a dummy dataframe
  ## Note that "expand=FALSE" is critical as it sets the clipping box to the edges of the plot, NOT the margins
  gplot=ggplot(mtcars[1,], aes(xmin = 0, xmax = 3840, ymin = 0, ymax = 2074)) +
        geom_rect(fill="#000000") + coord_fixed(clip="on",expand=FALSE) + theme_void() +
    theme(plot.background = element_rect(fill = "black", color = NA),
          panel.background = element_rect(fill = "black", color = NA))

  ## Define where rows of digits and text go
  rowdf=generaterows(input)

  ## Generate dataframe containing the proportion of invisible digits in each row for each frame
  ## We use the one closest to the calculated position of each row, mirrored about the center point
  pdis=read.table(text = "
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.09	0.57	0.71	0.83	0.86	0.89	0.89	0.89	0.89	0.91	0.97	1	1
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.1	0.3	0.46	0.69	0.77	0.83	0.89	0.91	0.91	0.97	0.97	1	1
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.14	0.23	0.31	0.51	0.77	0.91	0.97	0.97	0.97	0.97	0.97	1	1
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.11	0.2	0.3	0.43	0.63	0.8	0.8	0.83	0.86	0.91	0.94	1	1
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.06	0.17	0.34	0.43	0.46	0.69	0.74	0.83	0.83	0.83	0.86	1	1
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.04	0.14	0.23	0.31	0.37	0.54	0.6	0.7	0.75	0.84	0.89	1	1
  0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.09	0.2	0.31	0.43	0.51	0.63	0.66	0.83	0.86	0.86	0.89	1	1")

  ## Create a dataframe to hold the visible status of each digit
  vdf=as.data.frame(matrix(rep(TRUE,nrow(rowdf)*37),nrow=nrow(rowdf),ncol=37))
  
  ## Set a random offset to begin plotting so digits can clip off the left and right edges
  ## This offset is up to one width of a digit to the left
  loffset=sample(-110:0,1)

  ## Create background digit PNGs and assign them to objects
  digitcolor="#4efb61"
  digitcreator(digitcolor)
  for(i in 0:9){
    assign(paste0("num",i),readPNG(file.path("digits",paste0(sample(0:9,1),".png"))))
  }
  
  ## Loop through all frames. Logic on what to do with each frame is based on this iterator
  for(i in frames){
    message(paste("Creating frame",i))
    ## Create a copy of the blank plot for this frame
    gplotcopy=gplot
    
    ## Set text color based on the frame we're generating
    textcolor=ifelse(i==44,"white",digitcolor)
    
    ## NOTE: if you wanted to left-align or right-align text, just change the xcoords add this argument to geom_text(hjust=)
    ## hjust=0.5 # center the text (default)
    ## hjust=0   # align left (i.e. first character)
    ## hjust=1   # align right (i.e. last character)

    ## Loop through the rows to add digits as necessary
    for(j in 1:nrow(rowdf)){
      ## Set up exclusion zone object; use a list so we can store several in cases where multiple strings on the same ling
      ezones=list()
      ## If row is in titleinputs object, get the appropriate text and plot it
      if(j%in%titleinputs){
        ## Fetch and plot the appropriate string for this frame
        tstring=fetchtitlestring(get(paste0("T",j)),i)
        gplotcopy=gplotcopy+geom_text(x = 1920, y = rowdf$ycoords[j], label = tstring,col=textcolor,family="Libre Bodoni",fontface="bold",size=9.36)
        ## Define the "exclusion zone" for this row based on the plotted text
        if(tstring!=""){
          ezones=c(ezones,getexclusionzone(tstring,1920,"S2"))
        }
      }
      ## If row is in titleinputs object, fetch and plot the appropriate text
      if(j%in%nameinputs){
        ## Need different behaviour for first 4 frames; plot two geom_text separately for first fragment of each word
        if(i%in%25:28){
          leftnstring=fetchnamestringmini(get(paste0("N",j,".1")),i)
          rightnstring=fetchnamestringmini(get(paste0("N",j,".2")),i)
          gplotcopy=gplotcopy+geom_text(x = 1043, y = rowdf$ycoords[j], label = leftnstring,col=textcolor,family="Libre Bodoni",fontface="bold",size=13)
          gplotcopy=gplotcopy+geom_text(x = 2426, y = rowdf$ycoords[j], label = rightnstring,col=textcolor,family="Libre Bodoni",fontface="bold",size=13)
          ## Append exclusion zones to master object
          ezones=c(ezones,getexclusionzone(leftnstring,1043,"N"),getexclusionzone(rightnstring,2426,"N"))
        }
        ## Single text string for remainder of frames
        if(i%in%29:44){
          nstring=fetchnamestring(get(paste0("N",j,".1")),get(paste0("N",j,".2")),i)
          gplotcopy=gplotcopy+geom_text(x = 1920, y = rowdf$ycoords[j], label = nstring,col=textcolor,family="Libre Bodoni",fontface="bold",size=13)
          ## Define the "exclusion zone" for this row based on the plotted text
          ezones=c(ezones,getexclusionzone(nstring,1920,"N"))
        }
      }

      ## Update the visible status dataframe based on the probabilities for this frame and row
      
      ## Calculate the absolute distance between the row and the vertical center of the plot
      centerdist=abs(rowdf$ycoords[j]-(2074/2))

      ## There are 14 bins in total (7 either side of center), so 2074/14 = 148.1429 pixels per bin
      ## Divide the distance from the center by the bin size, with a min of 1 and max of 7
      pbin=min(max(round(centerdist/(2074/14)),1),7)
      
      ## Count the number of visible digits and compare to the expected number
      ndigitstoremove=sum(vdf[j,])-round(37-pdis[pbin,i]*37)
      if(ndigitstoremove>0){
        digitstoremove=sample(names(which(unlist(vdf[j,]))),ndigitstoremove)
        vdf[j,digitstoremove]=FALSE
      }

      ## Loop through the 37 columns and plot digits
      for(k in 1:37){
        if(vdf[j,k]){
          ## Select a random digit and get it from memory
          img=get(paste0("num",paste0(sample(0:9,1))))
          
          ## Set digit size based on the row 
          if(rowdf$types[j]%in%"N"){ img_grob = rasterGrob(img,interpolate=TRUE) } # N size, 1.00 (full size)
          if(rowdf$types[j]%in%"S1"){ img_grob = rasterGrob(img,interpolate = TRUE,width = unit(1, "npc"),height = unit(0.87, "npc")) } # S1 size, 0.87
          if(rowdf$types[j]%in%"S2"){ img_grob = rasterGrob(img,interpolate = TRUE,width = unit(1, "npc"),height = unit(0.72, "npc")) } # S2 size, 0.72

          ## Check exclusion zone
          xmin=loffset+dim(img)[2]*(k-1)
          xmax=loffset+dim(img)[2]*(k)
          outofzone=checkexclusionzone(xmin,xmax,ezones)
          if(!outofzone){ next }

          ## Add the digit to the image
          gplotcopy=gplotcopy+annotation_custom(
            img_grob,
            xmin = xmin, xmax = xmax,  # x bounds of one digit
            ymin = rowdf$ycoords[j]-dim(img)[1]/2, ymax = rowdf$ycoords[j]+dim(img)[1]/2     # y bounds of one digit
          )
        }
      }
    }
    ## If savepngs is true, create PNG, otherwise return this single frame
    if(savepngs==TRUE){ 
      dir.create(outdir,showWarnings = FALSE) # top dir
      dir.create(file.path(outdir,"raw"),showWarnings = FALSE) # raw frames dir
      ggsave(file.path(outdir,"raw",paste0(i,".png")),width = 3840, height = 2074, units = "px")
    }
    if(savepngs==FALSE){ return(gplotcopy) }
  }
}

## Function to split title text into fragments
## Split "title" text into 3 fragments.
## Fragment size is either user-defined or these proportions: 0.25+0.44+0.31 = 1
titlesplitter=function(asciititle,cuts){
  ## First, remove any extraneous whitespace
  asciititle=trimws(asciititle)
  ## Determine cut positions if not user defined
  if(any(is.na(cuts))){
    cut1=round(nchar(asciititle)*0.25)
    cut2=round(nchar(asciititle)*0.69)
  }else{
    cut1=cuts[1]
    cut2=cuts[2]
  }
  ## Create 3 fragments
  frag1=substr(asciititle,1,cut1)
  frag2=substr(asciititle,cut1+1,cut2)
  frag3=substr(asciititle,cut2+1,nchar(asciititle))
  
  ## Return results as a list
  return(list(frag1,frag2,frag3))
}

## Function to split main text into fragments
## First, split into two parts, determined by the first space
## Then, split first part into 3 fragments
## Then, split second part into 4 fragments
## Return everything as a list of lists: list(list(frags1),list(frags2))
namesplitter=function(asciiname){
  ## First, remove any extraneous whitespace
  asciiname=trimws(asciiname)
  
  ## Determine cut for breaking into two parts based on first space
  ## If there are no spaces (i.e. it's a single word) then use the midpoint of the word
  ## We may have to check for 1 word cases later so no space is introduced when resassembling/printing
  cutpoint=unlist(gregexpr("\\s", asciiname))[1]
  if(cutpoint%in%-1){ cutpoint=round(nchar(asciiname)/2) }
  
  ## Produce words
  word1=trimws(substr(asciiname,1,cutpoint))
  word2=trimws(substr(asciiname,cutpoint+1,nchar(asciiname)))

  ## Split word1 into 3 fragments
  fraglengths1=fraglengthcalc(word1,3)
  w1frag1=substr(word1,1,fraglengths1[1])
  w1frag2=substr(word1,fraglengths1[1]+1,sum(fraglengths1[1:2]))
  w1frag3=substr(word1,sum(fraglengths1[1:2])+1,nchar(word1))
  
  ## Split word2 into 4 fragments
  fraglengths2=fraglengthcalc(word2,4)
  w2frag1=substr(word2,1,fraglengths2[1])
  w2frag2=substr(word2,fraglengths2[1]+1,sum(fraglengths2[1:2]))
  w2frag3=substr(word2,sum(fraglengths2[1:2])+1,sum(fraglengths2[1:3]))
  w2frag4=substr(word2,sum(fraglengths2[1:3])+1,nchar(word2))

  ## Return results as a list of lists
  return(list(list(w1frag1,w1frag2,w1frag3),list(w2frag1,w2frag2,w2frag3,w2frag4)))
}

## Function to calculate fragment lengths based on input word and number of fragments
fraglengthcalc=function(word,nfrag){
  ## length1 is the length of most fragments
  length1=round(nchar(word)/nfrag)
  ## length2 is the length of the final "straggler" fragment intended to pick up remaining characters
  length2=ifelse(nfrag*length1==nchar(word),length1,nchar(word)-((nfrag-1)*length1))
  
  ## Return a vector of fragment lengths
  fraglengths=c(rep(length1,nfrag-1),length2)
  return(fraglengths)
}

## Function to return the strings that will be used in plots
stringsforprint=function(frags){
  ## Dataframe to hold results, 1 row per fragment
  ts=data.frame(hex=1:length(frags),octcat=1:length(frags),oct=1:length(frags),spaced=1:length(frags),final=1:length(frags))
  
  ## Fill in the dataframe for each fragment
  for(i in 1:length(frags)){
    ## Convert fragment to hexadecimal and arrange in blocks of 4, trimming outer whitespace
    hexraw=as.character(charToRaw(frags[[i]]))
    hexcat=paste(hexraw,collapse="")
    hexblocks=trimws(gsub("(.{4})", "\\1 ", hexcat, perl = TRUE))
    ts[i,"hex"]=hexblocks
    
    ## Convert fragment to octal
    octraw=as.character(as.octmode(strtoi(hexraw,16)))
    octs=paste(octraw,collapse=" ")
    ts[i,"oct"]=octs
    
    ## Convert hexblocks to octblocks
    ## Blocks of 4 hex characters result in blocks of 6 octal characters (prefix a zero if necessary)
    ## Example: ascii "by" => hex 6279 => octal 61171 => prefix zero 061171
    ## If the input text is 1 character, then a whitespace (20) is prefixed to create a 4 hexblock and processed like a normal 4 hexblock
    ## Example: ascii "K" => hex 4b => (prefix 20) hex 204b => octal 20113 => prefix zero 020113
    ## If 1 character input is trailing (e.g. input text is and odd number of characters like 3), blocks of 2 hex characters have a whitespace (20) appended to them,
    ## then a zero is prefixed and the first 3 digits are used
    ## Example: ascii "R" => hex 52 => (append 20) hex 5220 => octal 51040 => (prefix 0) 051040 => first 3 digits 051
    ts[i,"octcat"]=octblocker(frags[[i]],hexblocks)
    
    ## Update fields for singleton fragments
    if(nchar(ts[i,"oct"])==3){
      ## Update hex
      ts[i,"hex"]=paste0("20",ts[i,"hex"],collapse="")
      ## Update oct
      ts[i,"oct"]=paste0("040",ts[i,"oct"],collapse="")
      ## Update octcat
      ts[i,"octcat"]=paste0("02",substr(ts[i,"oct"],3,6),collapse="")
    }
    
    ## Add spaced-out text
    nospacefrag=gsub("\\s","",frags[[i]])
    ts[i,"spaced"]=paste(strsplit(nospacefrag, "")[[1]], collapse = " ")
    ## Fragments with correct whitespace
    ts[i,"final"]=frags[[i]]
  }
  return(ts)
}

## Function to convert hexblocks into octblocks; 3 methods depending on input
## "frag" is the input text string, "hexblocks" is the string containing the hexblock conversion
## 1.) Blocks of 4 hex characters result in blocks of 6 octal characters (prefix a zero if necessary)
## Example: ascii "by" => hex 6279 => octal 61171 => prefix zero 061171
## 2.) If the input text is 1 character, then a whitespace (20) is prefixed to create a 4 hexblock and processed like a normal 4 hexblock
## Example: ascii "K" => hex 4b => (prefix 20) hex 024b => octal 20113 => prefix zero 020113
## 3.) If 1 character input is trailing (e.g. input text is and odd number of characters like 3), blocks of 2 hex characters have a whitespace (20) appended to them,
## then a zero is prefixed and the first 3 digits are used
## Example: ascii "R" => hex 52 => (append 20) hex 5220 => octal 51040 => (prefix 0) 051040 => first 3 digits 051
octblocker=function(frag,hexblocks){
  ## Immediately return if the frag is an empty string
  if(frag==""){ return("")}
  
  ## Split hexblocks string into single blocks
  hexblocks=unlist(strsplit(hexblocks," "))
  octblocks=rep(NA,length(hexblocks))
  for(i in 1:length(hexblocks)){
    hexblock=hexblocks[i]
    
    ## Assign a temporary value to octblock
    octblock="TEMP"
    
    ## If the hexblock has 4 digits, perform regular conversion
    if(nchar(hexblock) == 4){
      octblock=as.character(as.octmode(strtoi(hexblock,16)))
      ## If the octblock is only 5 digits, prefix a zero
      if(nchar(octblock)==5){ octblock=paste0("0",octblock,collapse="")}
    }
    ## If the hexblock has 2 digits and the input fragment is longer than 1, modify the hexblock:
    ## Suffix "20", convert to oct, use the first two digits and prefix a zero
    if(nchar(hexblock) == 2 & nchar(frag)>1){
      hexblock=paste0(hexblock,"20",collapse="")
      octblock=as.character(as.octmode(strtoi(hexblock,16)))
      octblock=paste0("0",octblock,collapse="")
      octblock=substr(octblock,1,3)
    }
    
    ## Assign result to output object
    octblocks[i]=octblock
  }  
  
  ## Concatenate octblocks into a single string and return
  octblocks=paste(octblocks,collapse=" ")
  return(octblocks)
}

## Determine how big the "exclusion zone" is on a row to not print digits
## Note that this is slightly larger than it needs to be to act as a safe buffer
getexclusionzone=function(string,xcoord,texttype){
  if(texttype%in%"N"){
    emin=xcoord-(((nchar(string)+1)/2)*3840/35)
    emax=xcoord+(((nchar(string)+1)/2)*3840/35)
  }
  if(texttype%in%"S2"){
    emin=xcoord-(((nchar(string)+1)/2)*3840/64)
    emax=xcoord+(((nchar(string)+1)/2)*3840/64)
  }
  return(list(c(emin,emax)))
}

## Return the string to print for this title text and frame
fetchtitlestring=function(tdf,frame){
  ## Frames 1-29 nothing happens
  tstring=""
  ## Define string based on the frame
  if(frame%in%c(30,31)){ tstring=paste0(tdf$hex[1],wsget(),tdf$hex[2]) }
  if(frame==32){ tstring=paste0(tdf$octcat[1],wsget(),tdf$hex[2]) }
  if(frame==33){ tstring=paste0(tdf$oct[1],wsget(),tdf$octcat[2]) }
  if(frame==34){ tstring=paste0(tdf$spaced[1],wsget(),tdf$oct[2]) }
  if(frame==35){ tstring=paste0(tdf$final[1],wsget(),tdf$spaced[2]) }
  if(frame%in%c(36,37)){ tstring=paste0(tdf$final[1],tdf$final[2],wsget(),tdf$hex[3]) }
  if(frame==38){ tstring=paste0(tdf$final[1],tdf$final[2],wsget(),tdf$octcat[3]) }
  if(frame==39){ tstring=paste0(tdf$final[1],tdf$final[2],wsget(),tdf$oct[3]) }
  if(frame==40){ tstring=paste0(tdf$final[1],tdf$final[2],wsget(),tdf$spaced[3]) }
  ## For any frame at or after 17, always return full final string
  if(frame>=41){ tstring=paste0(tdf$final[1],tdf$final[2],tdf$final[3]) }
  
  ## Limit title string to 40 characters
  tstring=substr(tstring,1,40)
  return(tstring)
}

## Define whitespace here to change gaps between subparts
## Whitespace is randomly 1 to 4 spaces
wsget=function(){
  paste(rep(" ",sample(0:4,1)),collapse="")
}

## Return the string to print for this name text and frame
fetchnamestringmini=function(ndf,frame){
  ## Frames 1-24 nothing happens
  nstring=""
  ## Potentially add a random string here to change gaps between subparts
  if(frame%in%c(25,26)){ nstring=ndf$hex[1] }
  if(frame==27){ nstring=ndf$octcat[1] }
  if(frame==28){ nstring=paste0(ndf$oct[1],wsget(),ndf$hex[2]) }
  return(nstring)
}

## Return TRUE if the digit to be plotted falls within the exclusion zones
checkexclusionzone=function(xmin,xmax,ezones){
  outofzones=rep(FALSE,length(ezones))
  if(length(ezones)>0){
    for(i in 1:length(ezones)){
      zonexmin=ezones[[i]][1]
      zonexmax=ezones[[i]][2]
      if((xmin < zonexmin & xmax < zonexmin) | (xmin > zonexmax & xmax > zonexmax)){
        outofzones[i]=TRUE
      }
    }
  }
  return(all(outofzones))
}

## Return the string to print for this title text and frame
fetchnamestring=function(ndf1,ndf2,frame){
  ## Frames 1-28 nothing happens
  nstring=""
  ## Potentially add a random string here to change gaps between subparts
  if(frame==29){ nstring=paste0(ndf1$spaced[1],wsget(),ndf1$hex[2],wsget(),ndf2$spaced[1]) }
  if(frame==30){ nstring=paste0(ndf1$final[1],wsget(),ndf1$octcat[2],wsget(),ndf2$final[1]) }
  if(frame==31){ nstring=paste0(ndf1$final[1],wsget(),ndf1$oct[2],wsget(),ndf2$final[1]) }
  if(frame==32){ nstring=paste0(ndf1$final[1],wsget(),ndf1$spaced[2],wsget(),ndf1$hex[3],wsget(),ndf2$final[1],wsget(),ndf2$hex[2]) }
  if(frame==33){ nstring=paste0(ndf1$final[1],ndf1$final[2],wsget(),ndf1$hex[3],wsget(),ndf2$final[1],wsget(),ndf2$octcat[2]) }
  if(frame==34){ nstring=paste0(ndf1$final[1],ndf1$final[2],wsget(),ndf1$octcat[3],wsget(),ndf2$final[1],wsget(),ndf2$oct[2],wsget(),ndf2$hex[3]) }
  if(frame==35){ nstring=paste0(ndf1$final[1],ndf1$final[2],wsget(),ndf1$oct[3],wsget(),ndf2$final[1],wsget(),ndf2$spaced[2],wsget(),ndf2$hex[3]) }
  if(frame==36){ nstring=paste0(ndf1$final[1],ndf1$final[2],wsget(),ndf1$spaced[3],wsget(),ndf2$final[1],ndf2$final[2],wsget(),ndf2$octcat[3]) }
  if(frame==37){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],wsget(),ndf2$oct[3]) }
  if(frame==38){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],wsget(),ndf2$spaced[3],wsget(),ndf2$hex[4]) }
  if(frame==39){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],ndf2$final[3],wsget(),ndf2$hex[4]) }
  if(frame==40){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],ndf2$final[3],wsget(),ndf2$octcat[4]) }
  if(frame==41){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],ndf2$final[3],wsget(),ndf2$oct[4]) }
  if(frame==42){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],ndf2$final[3],wsget(),ndf2$spaced[4]) }
  if(frame%in%43:44){ nstring=paste0(ndf1$final[1],ndf1$final[2],ndf1$final[3],"  ",ndf2$final[1],ndf2$final[2],ndf2$final[3],ndf2$final[4]) }
  return(nstring)
}
