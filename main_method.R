## Source the file containing all the functions we need:
source("sourcefunctions.R")

## Example input to replicate plate 1
plate1=list(list("Based on the manga by","S2",1200,c(5,19)),list("SHIROW  MASAMUNE","N",1040)) 
## Example input to replicate plate 3
plate3=list(list("Character Design","S2",1645,c(3,10)),
           list("HIROYUKI OKIURA","N",1499),
           list("Mechanical Design","S2",1245,c(4,11)),
           list("SHOJI KAWAMORI","N",1095),
           list("ATSUSHI TAKEUCHI","N",937),
           list("Weapon Design","S2",687,c(2,7)),
           list("MITSUO ISO","N",531))

## Create a test image so you can check the text positioning
generateframes(plate1,44,outdir="plate1")

## Generate all 44 frames replicating plate 1
generateframes(plate1,1:44,outdir="plate1")

