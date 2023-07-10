#!/usr/bin/env bash
# Songtao Gui 2022/02/22

# set -o xtrace
# set -o errexit
set -o nounset
set -o pipefail

# >>>>>>>>>>>>>>>>>>>>>>>> Load Common functions >>>>>>>>>>>>>>>>>>>>>>>>
export quiet=FALSE
export verbose=TRUE
source $(dirname $0)/lib/common.sh
if [ $? -ne 0 ];then 
    echo -e "\033[31m\033[7m[ERROR]\033[0m --> Cannot load common functions from easybash lib: $EASYBASH" >&2
    exit 1;
fi
# gst_rcd "Common functions loaded"
# <<<<<<<<<<<<<<<<<<<<<<<< Common functions <<<<<<<<<<<<<<<<<<<<<<<<

usage=$(
cat <<EOF
------------------------------------------------------------
Convert Chip data to hmp format
------------------------------------------------------------
Dependence: csvtk, perl
------------------------------------------------------------
USAGE:
    bash $(basename $0) [Genotype.xls] [mode] [outputfile]
Opt:
    - [Genotype.xls]: Genotype format of chip, with columns of
        ID,chrom,position,ref,genotype(sample1),ref_depth(sample1)...
    - [mode]: seq or num.
        if seq, geno would be "AA,TT,CC,GG", and "NA" for missing;
        if num, geno would be number of alt alleles, "0,1,2", and "-9" for missing;

** NOTE: Only output biallele SNP sites;
------------------------------------------------------------
Author: Songtao Gui
E-mail: songtaogui@sina.com
EOF
)
if [[ $# -ne 3 ]]; then 
    echo "$usage" >&2
    exit 1
fi

export in=$1
export mode=$2
export op=$3

check_files_exists $in
check_var_regex mode "^(seq|num)$" "should be seq or num"

gstcat $in | csvtk cut -tT -F -f "ID,chrom,position,ref,genotype*" |\
perl -F"\t" -slane '
    BEGIN{$,="\t";}
    if($.==1){
        s/genotype\(//g;
        s/\)//g;
        s/ID\t.*ref/rs#\talleles\tchrom\tpos\tstrand\tassembly\tcenter\tprotLSID\tassayLSID\tpanelLSID\tQCcode/;
        print;
        next;
    }
    @geno=@F[4..$#F];
    @geno = map {$_ eq "NA"?"NN":$_} @geno;
    # format geno: only snps
    @geno = map {length($_) == 2 ? $_ : "NN" } @geno;
    @non_na = grep {$_ ne "NN"} @geno;
    $alleles = join("", @non_na);
    @alleles = split(//, $alleles);
    %count = ();
    @ua = grep {++$count{$_} < 2} @alleles;
    @nrua = grep {$_ ne $F[3]} @ua;
    if($mode eq "num"){
        # for num mode, only biallele site is allowed
        next if length(@nrua) > 1;
        %map = ();
        $map{"$F[3]$F[3]"} = 0;
        $map{"$nrua[0]$nrua[0]"} = 2;
        $map{"$F[3]$nrua[0]"} = 1;
        $map{"$nrua[0]$F[3]"} = 1;
        $map{"NN"} = -9;
        @geno = map {$map{$_}} @geno;
    }
    $alleles_fmt = join("\/", $F[3],@nrua);
    print $F[0], $alleles_fmt, $F[1], $F[2], "+", "NA", "NA", "NA", "NA", "NA", "NA", @geno;
' -- -mode=$mode > $op
if [ $? -ne 0 ];then gst_err "$0 failed: Non-zero exit"; exit 1;fi

# rs#
# alleles
# chrom
# pos
# strand
# assembly
# center
# protLSID
# assayLSID
# panelLSID
# QCcode