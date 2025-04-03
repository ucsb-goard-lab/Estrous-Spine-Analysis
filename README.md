# ReadME

## Spine-Analysis-Pipeline

Pipeline for morphological classification of dendrite spines.  
Originally, created in part for analysis of dendritic spine turnover due to estrous cycle changes, this pipeline is modular for both cross sectional and time series analysis, and includes the option to account for estrous cycle stage.

## Features

### Time Series Analysis
Runs getAllSpines (and subsequent functions) to determine the total population of spines to calculate turnover dynamics. Gaussian averaged images, binarized images, and super resolution images of the data are first produced. Manual selection of the threshold and editing of dendrites in each image is allowed. Then spine detection occurs. Spines are separated based on boundary boxes with centroids > 25 pixels (~1.7 microns) apart. Two 4D matrices (spine width x spine height x num days x num spines) are generated for each spine. Additionally, after spines are individually registered, classification based on morphological factors occurs. The four spine types are stubby, thin, mushroom, or filopodium. Users can edit the spines detected. Another GUI runs to allow selection of the spines the program could not ascertain as a spine (outliers), allowing for manual selection and classification.

### Cross Sectional Analysis

Images have been previously gaussian averaged across 4 imaging planes, typically ~3 micrometers apart. All spines in the sequence of images are detected, and the cumulative population of spines is determined. Spine type (stubby, thin, mushroom, or filopodium) is determined by a decision tree that is highly reliant on specific morphological features, therefore if the user is imaging outside of a 16X magnification (51.8 x 51.8 micron FOV) the decision tree should be modified to accommodate these changes, or the images should be normalized to match this magnification. Otherwise, an ML approach is more appropriate. This, along with morphological feature extraction, concludes the cross-sectional spine analysis, and results are plotted.

### Optional Cycle Input

Estrous cycle classifications saved as a cell array of strings can be preloaded if the user indicates that they would like to analyze spine dynamics as a function of the estrous cycle stage. Please refer to EstrousNet (https://github.com/ucsb-goard-lab/EstrousNet) for more information on how to reliably classify estrous stages from vaginal cytology images.

## Folder Structure

<details>
  <summary>View Structure</summary>
  
  ### Main Folder
  1. README.md
  2. Data Folder
     * ImagesforAnalysis.png
     * cycle.mat (i.e for estrous cycle)
     * binarized
       * binarized images
       * superresolution
            * superresolution images
        * data
          * original images
  3. SpineAnalysisPackage
      * .gitattributes
      * masterSpineAnalysis.m
      * main functions
          * getAllSpines.m
          * crossSectionalSpineAnalysis.m
          * analyzeDendrite_NSWEdit.m
      * subfunctions
          * violinplot.m
          * getManualSpines.m
          * binarizeMeanGausProjection_NSWEdit.m
          * natsortfiles
              * natsortfiles.m
              * natsort.m
              * license.txt
              * html
                  * natsortfiles_doc.html
          * ClassesAndHelpers
              * Violin_2.m
              * pixel_intersection.m
              * linept.m
              * getDendriteInfoClass.m
              * getSpineMorphologyClass.m
              * getFilteredImageClass.m
</details>

## MatLab Set-Up
1. Ensure at least 2018b version of MatLab 
2. Upload Main Folder into MatLab Current Folder
3. Open masterSpineAnalysis.m in editor
4. Direct to data folder in MatLab Current Folder
5. (If not done so) Create Cycle data as a cell array of strings
6. Make sure all functions in the program have not been renamed
7. Install Matlab Packages: _Image Processing Toolbox, Statistics and Machine Learning Toolbox, Computer Vision Toolbox_

## Usage & Important Notes
1. Move current working directory to directory contain all the average projections from dendritic images
2. While open on Editor, run masterSpineAnalysis.m
3. If prompted, select add to path
    1. DO NOT CHANGE FROM CURRENT FOLDER
    2. May add Spine Analysis Package and all subfolders to Matlab path permanently
4. Time Series Analysis or Cross Sectional Analysis. Follow Prompts

### Time Series Analysis Features
#### Options
* If the user would like to see images as they are processed, set the input 
              _show_image_steps_ of _analyzeDendrite_NSWEdit_ to true.
<br> main functions/getAllSpines.m, Lines 46-47 </br>



#### Manual Binarization Editing (Best Practices)
  1. Change Threshold (If want to) first
      * Images shown are of threshold x0.75, x1, x1.25 of current
  2. Remove/Add Portion of Dendrite: “adding” a portion of the image increases threshold by x 1.8
      <br> Note: If add/remove and then re-binarize, will revert to before addition/removal of ROI </br>

#### Manual Spine Classification Approval
1. Will be shown a diagram of the spines and color coded based on the type of spine (determined by program)
<br>Legend</br>
      * magenta - stubby
      * cyan - thin
      * yellow - mushroom
      * green - filopodia
2. Option to add or remove spines:
   * Add:
     <br> 1. select spine region and make sure first and final point for ROI connects  </br> 
        2. Select the classification for the spine
        3. Confirm classification
   * Subtract:
        <br> 1. Choose spine number wish to remove </br>
        2. Confirm selection
   * Neither: Saves all changes and continues analysis

#### SpineDetectionGUI
GUI for selecting spines the program could not determine  
    GUI Structure:
<br>![drawing](https://docs.google.com/drawings/d/1o0OSf1Kc4vRM7I8bdtr34yE2cf0N_oBoMo3K8hjxRKs/export/png)</br>
1. Look through all spines for all dendrites and determine if detection was accurate
   * Horizontal scroll to see other spines
3. If you wish to change some information, select the Edit Button
4. Select the Rec #
5. Choose whether it should be classified as a spine or not
    * Confirm Selection
6. Accept Changes

## References

Program was written by Nora S. Wolcott, Marie Karpinska, William T. Redman, Luca Montelisciani, and Mounami Reddy Kayitha. The reference paper is:  
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Redman, W.T., Wolcott, N.S., Montelisciani, L., Luna, G., Marks, T.D., Sit, K.K., Yu, C., Smith, S., Goard, M.J. Long-term transverse &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;imaging of the hippocampus with glass microperiscopes eLife 11:e75391 (2022).

The binarizing algorithm utilizes code from:
  * SuperResolution functions written by William T. Redman.   
  * Part of a procedure from Smirnov MS., et. al. An open-source tool for analysis and automatic identification of dendritic spines using machine learning. PLOS ONE 13, e0199589 (2018). 
  

Automatic Threshold Selection from Histogram of Image, inspired by Bai, W., Zhou, X., Ji, L., Cheng, J. and Wong, S.T.C., Automatic dendritic spine analysis in two-photon laser scanning microscopy images. Cytometry, 71A: 818-826 (2007).  

**Helper functions:**
Cobeldick S (2021) natSortfiles for Matlab, version 3.4.1.  

Uses Bechtold B (2016) Violin Plots for Matlab, version 1.7.0.0. For more information: Hintze, J.L. & Nelson, R.D. Violin plots: a box plot-density trace synergism. The American Statistician 2, 181-184 (1998).  

Spine Morphology Classification utilizes Georges C. (2003) linept (renamed to “connecting two pixels”) for Matlab, version 1.0.0.0.  
