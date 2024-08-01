# EasyAmplicon

The Chinese version in (中文版见) [README_cn.md](./README_cn.md)

[**EasyAmplicon: An easy-to-use, open-source, reproducible, and community-based pipeline for amplicon data analysis in microbiome research**](https://doi.org/10.1002/imt2.83)

Version：v1.21

Update：2024/08/01

## Pipeline manual and file description

Using RStudio to open the pipeline available in Chinese (pipeline.sh) and English (pipeline_en.sh)

Files Description:

- Readme.md # Introduction and install
- pipeline.sh # Command-line analysis for Windows and Linux (available in Chinese and English) 
- pipeline_mac.sh # Command-line analysis for MacOS
- result/ # Example result data
- result/Diversity.Rmd # Interactive diversity analysis in R and output reproducible report in HTML format

## What can we do? 

- Analysis and visualization of microbiome data, especially for 16S rDNA amplicon;
- From raw data into feature tables;
- Support 20+ analysis methods and publish-ready visualization;
- Finish your project on your laptop in short time (approx 3 hours);
- Supporting materials (manual and videos) in Chinese/English.

![image](http://www.imeta.science/github/EasyAmplicon/result/Figure1.jpg)

**Figure 1. Pipeline of EasyAmplicon for analyzing paired-end amplicon sequences.**

![image](http://www.imeta.science/github/EasyAmplicon/result/Figure2.jpg)

**Figure 2. Examples of publication-quality visualizations.**

![image](http://www.imeta.science/github/EasyAmplicon/result/Figure3.jpg)

**Figure 3. Supplementary examples of publication-quality visualizations to Figure 2.**

![image](http://www.imeta.science/github/EasyAmplicon/result/Figure4.jpg)

**Figure 4. Visualizations generated by third-party software using the intermediate files of EasyAmplicon.**

## Install 

### Install Dependency

All the software backups can be found in 

- FTP: [Filezilla](https://filezilla-project.org/index.php) visiting FTP download.nmdc.cn in anonymous. In the tools directory, you can find all the software and packages in amplicon and different systems supporting such mac, win
- Baidu Net Disk：https://pan.baidu.com/s/1Ikd_47HHODOqC3Rcx6eJ6Q?pwd=0315 

Please install the dependency software according to your system (Win/Mac/Linux).

- R 4.x.x is recommended for running R scripts https://www.r-project.org/. It is also recommended that Rtools be installed for source code packages.
- RStudio 2023.xx.x is a integrated development environment for R https://posit.co/download/rstudio-desktop/
- STAMP v2.1.3 http://kiwi.cs.dal.ca/Software/STAMP 
- Git for Windows 2.xx.x (Windows only) http://gitforwindows.org/
- R packages quick install

The statistics and visualization may require > 500 R packages. Installation is time-consuming and may also rely on other compilation tools. You can download all needed R packages in https://pan.baidu.com/s/1Ikd_47HHODOqC3Rcx6eJ6Q?pwd=0315 db/win/4.x.zip or db/mac/R4.2_mac_libraryX86_64.zip, then unzip and take the `4.x` folder in C:\Users\[$UserName]\AppData\Local\R\win-library\

### Install EasyAmplicon 

- Method 1. Visit the GitHub homepage, Code -- Download

- EasyAmplicon pipeline (Positive control) https://github.com/YongxinLiu/EasyAmplicon
- EasyMicrobiome includes scripts and databases https://github.com/YongxinLiu/EasyMicrobiome

Download the project in C: or D: then unzip (keep the directory name exactly the software name)

- Method 2. Download by the mirror site in BaiduNetDisk: https://pan.baidu.com/s/1Ikd_47HHODOqC3Rcx6eJ6Q?pwd=0315 db/soft/EasyAmplicon.tar.gz or EasyMicrobiome.tar.gz

- Method 3. `git clone https://github.com/YongxinLiu/EasyAmplicon` and `git clone https://github.com/YongxinLiu/EasyMicrobiome`. Note: `fatal: unable to access` can retry.

## Quick Start 

Using Windows 10+ as an example:

1. Open RStudio, and set the terminal as Git Bash (Tools -- Global Options -- Terminal -- New terminals -- Git Bash -- OK)
2. File -- Open File -- `EasyAmplicon` folder -- pipeline.sh (windows/linux) or pipeline_mac.sh (mac)
3. Setup the `work directory`(wd), and `EasyMicrobiome directory`(db), then run each line by clicking run in the top right corner

## Example dataset 

- seq/ # raw sequencing in zipped fastq format, backup can download by metadata from GSA https://ngdc.cncb.ac.cn/gsa/
- result/ # Example data and figures for standard pipeline, such as alpha, beta, tax
- advanced/ # Example of advanced analysis, included data, scripts and output figures

## FAQ 

Frequently Asked Questions in pipeline.sh

Note: All the .sh script is written in markdown format, using Youdao Note or VSCode for a better reading experience.

## Citation
If use this script, please cite:

**Yong-Xin Liu**, Lei Chen, Tengfei Ma, Xiaofang Li, Maosheng Zheng, Xin Zhou, Liang Chen, Xubo Qian, Jiao Xi, Hongye Lu, Huiluo Cao, Xiaoya Ma, Bian Bian, Pengfan Zhang, Jiqiu Wu, Ren-You Gan, Baolei Jia, Linyang Sun, Zhicheng Ju, Yunyun Gao, **Tao Wen**, **Tong Chen**. 2023. EasyAmplicon: An easy-to-use, open-source, reproducible, and community-based pipeline for amplicon data analysis in microbiome research. **iMeta** 2: e83. https://doi.org/10.1002/imt2.83

Copyright 2016-2023 Yong-Xin Liu <liuyongxin@caas.cn>, Tao Wen <taowen@njau.edu.cn>, Tong Chen <chent@nrc.ac.cn>
