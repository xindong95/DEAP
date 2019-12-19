# DEAP (Alpha)

## Introducton

Differential Expression Analysis Pipeline(DEAP) is a pipeline that can process expression data that RNA-seq or MicroArray experiments generated. The pipeline is built using [snakemake](https://snakemake.readthedocs.io/), which allows for ease of use, optimal speed, and highly modular code that can be further added onto and customized by experienced users.

## Basic Usage

We suppose you start your project with `PROJECT` folder:

```bash
mkdir PROJECT
cd PROJECT
git clone git@github.com:XinDong9511/DEAP.git
conda env create -n DEAP -f DEAP/environment.yaml # this might take long time based on your network environment
conda activate DEAP
```

The data can be stored anywhere with the given path in the config.yaml file, but we recommend you put all your data in the `data` folder.

```bash
mkdir data
```

You can download reference files [here](/mnt/Storage/home/dongxin/Files/DEAP_ref_files). All compressed files should be extracted to the `ref_files` folder.

```bash
mkdir ref_files
cd ref_files
wget https://XXXXXXX/hg38.tar.gz
wget https://XXXXXXX/mm10.tar.gz
wget https://XXXXXXX/GPL.tar.gz
tar xvzf hg38.tar.gz
tar xvzf mm10.tar.gz
tar xvzf GPL.tar.gz
cd ..
```

If you have already downloaded reference files on your server or local machine, we recommend you link the reference files by the soft link:

```bash
ln -s /mnt/Storage/home/dongxin/Files/DEAP_ref_files ref_files
```

Copy needed config files to the current folder.

```bash
cp DEAP/metasheet.csv .
cp DEAP/ref.yaml .
cp DEAP/config.yaml .
```

Then your folder structure should be like this:  

> PROJECT/  
├── data  *(store your data)  
├── ref_files  
├── DEAP *(this one is the git repo)*  
├── metasheet.csv  
├── ref.yaml  
└── config.yaml  

Please modify your config.yaml and metasheet following the instructions in **Files Format** part. After modifing config.yaml and metasheet.csv, type:

```bash
snakemake -s DEAP/DEAP.snakefile
```

Then the pipeline will start running for analysis. If you only want to check the tasks scheduling and command used in the analysis, you can type:

```bash
snakemake -s DEAP/DEAP.snakefile -npr
```

Other snakemake advanced instructions can be found [here](https://snakemake.readthedocs.io/).

## All Data Comes From GEO

[Gene Expression Omnibus (GEO)](https://www.ncbi.nlm.nih.gov/gds/) database stores a huge number curated gene expression DataSets, as well as original Series and Platform records. If you want to process data all from GEO, you can use the `geo_start.py` to help you download data and configure the pipeline.

```shell
usage: geo_start.py [-h] [-s SAMPLECONFIG] [-m METASHEET] [-e COMMAND]
                    [-j JOBS]

optional arguments:
  -h, --help            show this help message and exit
  -s SAMPLECONFIG, --sampleconfig SAMPLECONFIG
                        The path of new config file with samples.
  -e COMMAND, --command COMMAND
                        Other command you want to submit to snakemake,
                        should be quoted. This would overwrite "-j"/
                        "--jobs". Eg. "-npr"
  -j JOBS, --jobs JOBS  The cores you want to provide to snakemake
```

The basic configuration is the same as mentioned in **Basic Usage** part.

```bash
mkdir PROJECT
cd PROJECT
git clone git@github.com:XinDong9511/DEAP.git
conda env create -n DEAP -f DEAP/environment.yaml # this might took long time based on your network environment
conda activate DEAP

# use this
mkdir ref_files
cd ref_files
wget https://XXXXXXX/hg38.tar.gz
wget https://XXXXXXX/mm10.tar.gz
wget https://XXXXXXX/GPL.tar.gz
tar xvzf hg38.tar.gz
tar xvzf mm10.tar.gz
tar xvzf GPL.tar.gz
cd ..
# or this
ln -s path/to/previous/ref_files/ ref_files

cp DEAP/ref.yaml .
cp DEAP/metasheet.csv .
cp DEAP/config.yaml .
```

In this case, you still need to modify the metasheet table to define the relationship between the samples as instructed from **Files Format** first. Please note that all sample ID (2nd columns) should be exact accession that starts with upper-case "GSM", e.g. `GSM123456`.  
In config.yaml file, you can skip the `samples` part and leave them as blank.  

After the configuration of these two files, you can start download and processing by:

```bash
python DEAP/geo_start.py
```

This script also supports passing parameter to snakemake:

```bash
python DEAP/geo_start.py -j 8 # use 8 core to run snakemake
python DEAP/geo_start.py -e "-npr" # dry-run for snakemake
```

You can also specify the output new config files:

```bash
python DEAP/geo_start.py -s new_config.yaml # dry-run for snakemake
```

## Files Format

You can take the config.yaml, metasheet.csv and ref.yaml provided under the DEAP folder as a reference.

- config.yaml:  
Here are several keys in this yaml file.  
  - `metasheet`: a path for a table file that defined the relationship among samples.  
  - `ref`: a yaml file that stored the path where reference files are.  
  - `aligner`: the align tool that you want to use for RNA-seq samples, options: `"salmon"` or `"STAR"` *(Not support yet)*.  
  - `assembly`: the assembly you want to use for your data, options: `"mm10"` or `"hg38"`.  
  - `trim`: DEAP use [trim_galore](https://github.com/FelixKrueger/TrimGalore) to cut off the adapter at the distal of reads and do quality control, options: `True` or `False`.  
  - `lisa`: [Lisa](http://lisa.cistrome.org/) is used to determine the transcription factors and chromatin regulators that are directly responsible for the perturbation of a differentially expressed gene set. option:`True` or `False`.  
  - `check_compare`: options: `True` or `False`, when set `True` for this option, DEAP will check comparison relationship and won't process alignment for RNA-seq samples that do not have enough samples(at least two samples in one condition). When set `False`, DEAP will still process trimming adaptor and alignment but still won't make the comparison.
  - `samples`: Can include many samples in this key. For each child key, you can write one fastq file for single-end samples or two fastq files for pair-end samples. *You can remove the whole key if you use `geo_start.py` to run the pipeline.*  
  
- metasheet.csv:  
This is a table that define samples' relationship and the way you would like to do differential expression genes among samples. Except `compare_XXX`, other headers should not be modified.  
  - **The 1st column (run)** is the run name. Samples of a run(or batch) should share the same name, though they could be divided into several rows for different FASTQ files or CEL files.  
  - **The 2nd column (sample)** should always be samples ID. This sample ID **must** precisely match the sample names configured in the config yaml file. *If you use `geo_start.py` to run the pipeline, please make sure all sample IDs are exact accession begin with upper-case "GSM", e.g. `GSM123456`.*  
  - **The 3rd column (experment_type)** define the experiment type of data, please choose one of `{RS, MA_A, MA_O, MA_I}`. `RS` for RNA-seq, `MA_{}` for microarray data generated by **A**ffymatrix, **O**ligo or **I**llumina *(Not support yet)*.  
  - **The 4th column (platform)**: You are supposed to write the platform each sample used. We only use the first one platform you defined in the same run but still recommend you fulfill the whole table. For RNA-seq, the platform will be used for the reads group. For microarray data, the platform should use the GPL file you downloaded from GEO, e.g., `GPL570`. Please make sure the GPL you write in the table has the matched file which named by `GPL{XXXX}.txt` in `ref_files/GPL/`. The `{XXXX}` is the number of this platform.
  - **The 5th column (treatment)**: The annotation of each sample. It would help if you wrote some string in this column. For example, `"Control"`, `"RNAi"`, `"Treat"`, `"ESR1i"`, etc.
  - **The 6th column (compare_XXX)**: The samples that you want to perform a Differential Expression to using limma and DEseq. The "control" should be marked with a `1`, and the "treatment" should be marked with a `2`. You are allowed to have as many `compare_XXXX` columns as you want at the end.  
  
- ref.yaml:  
Here you are allowed to define your reference files, includes GPL files, hg38 index, and mm10 index files.  

## Appendix

### LISA installation

LISA isn't a necessary component of DEAP, and you needn't install it if you do not plan to run it -- set `lisa` in config as `False`. Otherwise, please install LISA following the instruction below.  

Since LISA also uses snakemake to build the workflow, to avoid the version conflict, we recommend you create a new environment for LISA.  
[LISA GIT](https://github.com/qinqian/lisa)

1. Install LISA by conda:

    ```bash
    conda create -n lisa python=3.6
    conda activate lisa
    conda install -c qinqian lisa
    ```

2. Download reference files of LISA:

    ```bash
    wget --user=lisa --password='xxx'  http://lisa.cistrome.org/cistromedb_data/lisa_v1.0_hg38.tar.gz
    wget --user=lisa --password='xxx'  http://lisa.cistrome.org/cistromedb_data/lisa_v1.1_mm10.tar.gz
    ```

3. Extract files and update LISA configuration: *The files can not move after `lisa_update_conf`, and please extract them to a proper position.*

    ```bash
    tar xvfz lisa_v1.0_hg38.tar.gz
    lisa_update_conf --folder hg38/ --species hg38
    # or
    tar xvfz lisa_v1.0_mm10.tar.gz
    lisa_update_conf --folder mm10/ --species mm10
    ```

4. Exit LISA environment and activate DEAP environment:

    ```bash
    conda deactivate
    conda activate DEAP
    ```
