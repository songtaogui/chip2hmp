# INSTALLATION

1. make sure [csvtk](https://github.com/shenwei356/csvtk) is correctly installed and could be accessed in `$PATH`
2. clone the git repos, run `bash wlab_chip2hmp.sh [options]`, or
3. make the script executable and add it to `$PATH`, so you could exec it anywhere through `wlab_chip2hmp.sh`

# USAGE
```
------------------------------------------------------------
Convert Chip data to hmp format
------------------------------------------------------------
Dependence: csvtk, perl
------------------------------------------------------------
USAGE:
    bash wlab_chip2hmp.sh [Genotype.xls] [mode] [outputfile]
Opt:
    - [Genotype.xls]: Genotype format of chip, with columns of
        ID,chrom,position,ref,genotype(sample1),ref_depth(sample1)...
    - [mode]: seq or num.
        if seq, geno would be "AA,TT,CC,GG", and "NN" for missing;
        if num, geno would be number of alt alleles, "0,1,2", and "-9" for missing;

** NOTE: Only output biallele SNP sites;
------------------------------------------------------------
Author: Songtao Gui
E-mail: songtaogui@sina.com
```
