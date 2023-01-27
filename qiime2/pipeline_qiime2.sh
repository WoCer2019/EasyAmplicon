[TOC]

# QIIME2 2022.2分析流程

## 0. 软件安装(附录1)

	# 仅限在Linux/Mac系统中运行，
	# Windows用户使用内置子系统(支持右键粘贴)、VirtualBox虚拟机、远程服务器中的Linux环境下安装并运行
	# 详细教程参阅官网https://docs.qiime2.org/2022.2/，或QIIME2教程专辑 https://mp.weixin.qq.com/s/farGisfX3fVL_5WgXS8lIg
    # 安装Windows子系统，https://mp.weixin.qq.com/s/0PfA0bqdvrEbo62zPVq4kQ

## 1. 准备工作

	# 设置工作目录，如服务器为~/amplicon/qiime2，Win子系统如下：
	wd=/mnt/c/amplicon/qiime2/
	# 进入工作目录
	mkdir -p ${wd}
	cd ${wd}
	# 激活QIIME2工作环境，旧版conda使用source替换conda运行
	conda activate qiime2-2022.2

	# 准备样本元数据metadata.txt、原始数据seq/*.fq.gz
	
	## 此处代码基于metadata.txt从公共数据下载测序数据，按GSA的CRA(批次)和CRR(样品)编号下载数据
	mkdir -p seq
	# # 公网下载
	# cd seq
	# awk '{system("wget -c ftp://download.big.ac.cn/gsa/"$5"/"$6"/"$6"_f1.fq.gz -O "$1"_1.fq.gz")}' \
	#     <(tail -n+2 ../metadata.txt)
	#  awk '{system("wget -c ftp://download.big.ac.cn/gsa/"$5"/"$6"/"$6"_r2.fq.gz -O "$1"_2.fq.gz")}' \
	#     <(tail -n+2 ../metadata.txt)
	# cd .. && ls -lsh seq
	# 从其他地方链接(不额外占用空间)
	ln /mnt/c/amplicon/seq/* seq/
	ln /mnt/c/amplicon/result/metadata.txt ./
	# 根据metadata生成manifest文件
	awk 'NR==1{print "sample-id\tforward-absolute-filepath\treverse-absolute-filepath"} \
	  NR>1{print $1"\t$PWD/seq/"$1"_1.fq.gz\t$PWD/seq/"$1"_2.fq.gz"}' \
	  metadata.txt > manifest
	head -n3 manifest

	# 数据导入qiime2，格式为双端33格式
	qiime tools import \
	  --type 'SampleData[PairedEndSequencesWithQuality]' \
	  --input-path manifest \
	  --output-path demux.qza \
	  --input-format PairedEndFastqManifestPhred33V2
	# fq文件1G用时7m，fq.gz压缩格式仅34s，测试数据9s


## 2. 生成特征表和代表序列

### 方法1. DADA2(慢，依赖R和Python包多容易报错)

	# 支持多线程加速，90万条PE250数据，0/96p, 34m；24p, 44m；8p, 77m；1p, 462m
	# 27万，8p, 9m; 4p, 11m;
	time qiime dada2 denoise-paired \
	  --i-demultiplexed-seqs demux.qza \
	  --p-n-threads 4 \
	  --p-trim-left-f 29 --p-trim-left-r 18 \
	  --p-trunc-len-f 0 --p-trunc-len-r 0 \
	  --o-table dada2-table.qza \
	  --o-representative-sequences dada2-rep-seqs.qza \
	  --o-denoising-stats denoising-stats.qza
	# 确定使用dada2结果并导入主流程
	cp dada2-table.qza table.qza
	cp dada2-rep-seqs.qza rep-seqs.qza

### 方法2. 外部导入特征表和代表序列(常用)

	# 上传我们生成的OTU表otutab.txt和代表序列otus.fa
	# 转换文本为Biom1.0，注意biom --version 2.1.5/8可以，2.1.7报错
	biom convert -i otutab.txt -o otutab.biom \
	  --table-type="OTU table" --to-json
	# 导入特征表，9s
	qiime tools import --input-path otutab.biom \
	  --type 'FeatureTable[Frequency]' --input-format BIOMV100Format \
	  --output-path table.qza
	# 导入代表序列，8s
	qiime tools import --input-path otus.fa \
	  --type 'FeatureData[Sequence]' \
	  --output-path rep-seqs.qza


### 特征表和代表序列统计

	qiime feature-table summarize \
	  --i-table table.qza \
	  --o-visualization table.qzv \
	  --m-sample-metadata-file metadata.txt
	qiime feature-table tabulate-seqs \
	  --i-data rep-seqs.qza \
	  --o-visualization rep-seqs.qzv
	# 下载qzv在线查看，dada2只有1千多个ASV


## 3. Alpha和beta多样性分析

### 构建进化树用于多样性分析 53s
	qiime phylogeny align-to-tree-mafft-fasttree \
	  --i-sequences rep-seqs.qza \
	  --o-alignment aligned-rep-seqs.qza \
	  --o-masked-alignment masked-aligned-rep-seqs.qza \
	  --o-tree unrooted-tree.qza \
	  --o-rooted-tree rooted-tree.qza

### 计算核心多样性 
	# 13s，采样深度通常选择最小值，来自table.qzv
	qiime diversity core-metrics-phylogenetic \
	  --i-phylogeny rooted-tree.qza \
	  --i-table table.qza \
	  --p-sampling-depth 11216 \
	  --m-metadata-file metadata.txt \
	  --output-dir core-metrics-results

### Alpha多样性组间显著性分析和可视化
	# 7s, 可选的alpha指数有 faith_pd、shannon、observed_features、evenness
	index=observed_features
	qiime diversity alpha-group-significance \
	  --i-alpha-diversity core-metrics-results/${index}_vector.qza \
	  --m-metadata-file metadata.txt \
	  --o-visualization core-metrics-results/${index}-group-significance.qzv

### Alpha多样性稀疏曲线
	# 25s, max-depth选最大值，来自table.qzv
	qiime diversity alpha-rarefaction \
	  --i-table table.qza \
	  --i-phylogeny rooted-tree.qza \
	  --p-max-depth 10298 \
	  --m-metadata-file metadata.txt \
	  --o-visualization alpha-rarefaction.qzv
	# 结果有observed_otus, shannon, 和faith_pd三种指数可选

### Beta多样性组间显著性分析和可视化
	# 可选的beta指数有 unweighted_unifrac、bray_curtis、weighted_unifrac和jaccard
	# 7s, 指定分组是减少计算量，置换检验较耗时
	distance=weighted_unifrac
	column=Group
	qiime diversity beta-group-significance \
	  --i-distance-matrix core-metrics-results/${distance}_distance_matrix.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization core-metrics-results/${distance}-${column}-significance.qzv \
	  --p-pairwise


## 4. 物种组成分析

	# 下载GreenGenes 99% OTUs训练集 (可选)
	wget -c http://210.75.224.110/db/GreenGenes/classifier_gg_13_8_99.qza
	### 物种注释
	# 1m 可选特异引物训练集如：classifier_gg_13_8_99_V5-V7.qza 是我用V5-V7训练的文件，详见附录或官方教程
	qiime feature-classifier classify-sklearn \
	  --i-classifier classifier_gg_13_8_99.qza \
	  --i-reads rep-seqs.qza \
	  --o-classification taxonomy.qza
	# 可视化物种注释
	qiime metadata tabulate \
	  --m-input-file taxonomy.qza \
	  --o-visualization taxonomy.qzv

	# 堆叠柱状图展示
	qiime taxa barplot \
	  --i-table table.qza \
	  --i-taxonomy taxonomy.qza \
	  --m-metadata-file metadata.txt \
	  --o-visualization taxa-bar-plots.qzv


## 5. 差异分析ancom

	# 格式化特征表，添加伪计数，4s
	qiime composition add-pseudocount \
	  --i-table table.qza \
	  --o-composition-table comp-table.qza

	# 计算差异特征，指定分组类型比较，1m
	column=Group
	time qiime composition ancom \
	  --i-table comp-table.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization ancom-${column}.qzv

	# 按属水平合并，并统计
	## 按属水平合并，6s
	qiime taxa collapse \
	  --i-table table.qza \
	  --i-taxonomy taxonomy.qza \
	  --p-level 6 \
	  --o-collapsed-table table-l6.qza
	# 格式化特征表，添加伪计数，6s
	qiime composition add-pseudocount \
	  --i-table table-l6.qza \
	  --o-composition-table comp-table-l6.qza
	# 计算差异属，指定分组类型比较，16s
	qiime composition ancom \
	  --i-table comp-table-l6.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization ancom-l6-${column}.qzv


# 附录

## 1. qiime2 2022.2安装

### 安装Conda

    # 下载、安装和启动conda
    wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -f
    ~/miniconda3/condabin/conda init
    # 关闭终端重新打开

### 方法1. Conda在线安装QIIME

    # 附软件在线安装和打包代码
    # 下载软件列表
	wget https://data.qiime2.org/distro/core/qiime2-2022.2-py38-linux-conda.yml
	# 备用链接
	wget -c http://210.75.224.110/github/QIIME2ChineseManual/2022.2/qiime2-2022.2-py38-linux-conda.yml
	# 新环境安装
	conda env create -n qiime2-2022.2 --file qiime2-2022.2-py38-linux-conda.yml
	# 环境打包(可选，1.2G)
	n=qiime2-2022.2
	conda pack -n ${n} -o ${n}.tar.gz

### 方法2. 本地安装QIIME

    # 安装包下载链接 
	wget -c http://210.75.224.110/db/conda/qiime2-2022.2.tar.gz
	# 新环境安装
    mkdir -p ~/miniconda3/envs/qiime2-2022.2
    tar -xzf qiime2-2022.2.tar.gz -C ~/miniconda3/envs/qiime2-2022.2
    # 激活并初始化环境
    conda activate qiime2-2022.2
	conda unpack


## 2. 物种注释数据训练集

	wd=/mnt/c/amplicon/qiime2
	mkdir -p $wd
	cd $wd
	# 下载数据库文件(greengenes, 320M)
	# wget -c ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz
	# 国内备用链接
	# wget -c http://210.75.224.110/db/GreenGenes/gg_13_8_otus.tar.gz
	# 国内备份核心99数据库(60M)
	wget -c http://210.75.224.110/db/GreenGenes/gg_13_8_otus_99.tar.gz
	mv gg_13_8_otus_99.tar.gz gg_13_8_otus.tar.gz
	# 解压
	tar -zxvf gg_13_8_otus.tar.gz
	
	# 使用rep_set文件中的99_otus.fasta数据和taxonomy中的99_OTU_taxonomy.txt数据作为参考物种注释
	# 导入参考序列，50s
	qiime tools import \
	  --type 'FeatureData[Sequence]' \
	  --input-path gg_13_8_otus/rep_set/99_otus.fasta \
	  --output-path 99_otus.qza
	# Fontconfig error: Cannot load default config file 不影响结果

	# 导入物种分类信息，6s
	qiime tools import \
	  --type 'FeatureData[Taxonomy]' \
	  --input-format HeaderlessTSVTaxonomyFormat \
	  --input-path gg_13_8_otus/taxonomy/99_otu_taxonomy.txt \
	  --output-path ref-taxonomy.qza

	# Train the classifier（训练分类器）——全长，30m
	time qiime feature-classifier fit-classifier-naive-bayes \
	  --i-reference-reads 99_otus.qza \
	  --i-reference-taxonomy ref-taxonomy.qza \
	  --o-classifier classifier_gg_13_8_99.qza
	# 备用下载链接	wget -c http://210.75.224.110/db/GreenGenes/classifier_gg_13_8_99.qza
	  
	# 引物提取参考序列的扩增区段 Extract reference reads
	# 常用Greengenes 13_8 99% OTUs from 341F CCTACGGGNGGCWGCAG/805R GACTACHVGGGTATCTAATCC region of sequences（分类器描述），提供测序的引物序列，截取对应的区域进行比对，达到分类的目的。
	# 本次使用引物799F-1193R，请根据实际替换, 8m
	time qiime feature-classifier extract-reads \
	  --i-sequences 99_otus.qza \
	  --p-f-primer AACMGGATTAGATACCCKG \
	  --p-r-primer ACGTCATCCCCACCTTCC \
	  --o-reads ref-seqs.qza
	# Train the classifier（训练分类器）
	# 基于筛选的指定区段，生成实验特异的分类器，7 min
	time qiime feature-classifier fit-classifier-naive-bayes \
	  --i-reference-reads ref-seqs.qza \
	  --i-reference-taxonomy ref-taxonomy.qza \
	  --o-classifier classifier_gg_13_8_99_V5-V7.qza

	# 常见问题1：scikit-learn版本不兼容，重新fit-classifier-naive-bayes构建训练集即可
	Plugin error from feature-classifier:
	  The scikit-learn version (0.21.2) used to generate this artifact does not match the current version of scikit-learn installed (0.22.1). Please retrain your classifier for your current deployment to prevent data-corruption errors.
	Debug info has been saved to /tmp/qiime2-q2cli-err-5ngzk2hm.log

	# 常见问题2: dada2运行报错，环境配置不完全，运行conda unpack初始化
	Plugin error from dada2:
	An error was encountered while running DADA2 in R (return code 255), please inspect stdout and stderr to learn more.
	Debug info has been saved to /tmp/qiime2-q2cli-err-utwt1cmu.log