#!/bin/bash

## Input argument is the path to the top directory for this plate.  Example usage:
## ./pp.sh plate1

PATHTOIM="convert"
PATHTOFF="ffmpeg"

## Define some variables:
PLATEDIR=$1
RAWDIR=${PLATEDIR}/raw
PPDIR=${PLATEDIR}/pp
VIDEODIR=${PLATEDIR}/video

## Create output directories
mkdir -p $PPDIR
mkdir -p $VIDEODIR

## For each green frame, perform the pipeline below:

## Proposed pipeline via photoshop
## 1: Create hexagons 
## 2: Make hexagons thicker (90)
## 3: Merge hexagons with raw frame
## 4: Gaussian blur ~2 or 3 pixels
## 5: Sharpen ~200%, pixel radius is 40
## 6: Reduce brightness to 80% and hue to 0
## 7: Apply color lookup table
## 8: Gaussian blur ~1 pixel

echo "Generating hexagonal background images"
## Step 1 of 8
## Create basic hexagon pattern to be superimposed on frames:
$PATHTOIM \( -size 3072x1659 pattern:hexagons -resize 3840x2074 \) ${PPDIR}/hexonlyraw.png

## Step 2 of 8
## What if we use different thresholds for the binary mask?
## Outlines get progressively thicker and darker with higher thresholds 
$PATHTOIM ${PPDIR}/hexonlyraw.png -colorspace Gray -threshold 90% ${PPDIR}/outline90.png

for i in {1..43}; do
  echo "Processing frame $i"
  ## Step 3 of 8
  ## Merge the darkest hexagons with the frame
  $PATHTOIM ${RAWDIR}/${i}.png ${PPDIR}/outline90.png -compose Multiply -composite ${PPDIR}/step3.png # good

  ## Step 4 of 8
  ## Apply 2 pixel gaussian blur
  $PATHTOIM ${PPDIR}/step3.png -blur 0x2 ${PPDIR}/step4.png

  ## Step 5 of 8
  ## unsharpen is configured like this: radius=2  amount=1.5  threshold=5 
  $PATHTOIM ${PPDIR}/step4.png -unsharp 0x40+1.5+0.2 ${PPDIR}/step5.png

  ## Step 6 of 8
  ## Adjust brightness and hue
  $PATHTOIM ${PPDIR}/step5.png -modulate 80,0 ${PPDIR}/step6.png

  ## Step 7 of 8
  ## Recolor using color lookup table
  $PATHTOIM ${PPDIR}/step6.png sorted_swatches.png -clut ${PPDIR}/step7.png

  ## Step 8 of 8
  ## Apply a 1 pixel gaussian blur
  $PATHTOIM ${PPDIR}/step7.png -blur 0x1 ${PPDIR}/${i}.png

  ## Clean up temporary files for this frame
  rm ${PPDIR}/step*.png

done

## Postprocessing for white frames
### Apply slight chromatic abberation and blur
$PATHTOIM ${RAWDIR}/44.png \
  \( -clone 0 -channel R -separate +channel -morphology Convolve Octagon:4 \) \
  \( -clone 0 -channel G -separate +channel -morphology Convolve Octagon:3 \) \
  \( -clone 0 -channel B -separate +channel -morphology Convolve Octagon:2 \) \
  -delete 0 -set colorspace sRGB -combine -blur 0x1 ${PPDIR}/73.png

### Create filler green frames
for i in {44..48}; do
  cp ${PPDIR}/43.png ${PPDIR}/${i}.png
done

### Create filler white frames
for i in {74..168}; do
  cp ${PPDIR}/73.png ${PPDIR}/${i}.png
done

## Create transition from green to white frames and rename them
$PATHTOIM ${PPDIR}/43.png ${PPDIR}/73.png -morph 24 ${PPDIR}/frame_%d.png

for i in $(seq 49 72); do
  FRAME=$((i - 48))
  mv ${PPDIR}/frame_${FRAME}.png ${PPDIR}/${i}.png
done

## Clean up temporary files
rm ${PPDIR}/frame_*png ${PPDIR}/hexonlyraw.png ${PPDIR}/outline90.png

## Create final video using ffmpeg
echo "Generating final video"
$PATHTOFF -framerate 24 -start_number 1 -i ${PPDIR}/%d.png -c:v libx264 -pix_fmt yuv420p $VIDEODIR/output.mp4

echo "All done"