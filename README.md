# Multiple Primer Design

Easily create a list of primers for any number of sequences specified inside of a BED file

## Example Usage

`./mult-primer.sh input.bed genome output.tsv`

This script takes in three arguments, a path to some BED file with sequences, a path to a genome which the BED files correspond to, and a destination path where the output will be saved. The output is by default saved as a tsv file.

## Pre-requisites
1. Install primer3 and bedtools.

* Instructions on installing primer3 can be found at https://github.com/primer3-org/primer3 
* Instructions on installing bedtools can be found at https://github.com/arq5x/bedtools2

## Details

This script works by first converting each genomic position in a BED file into fasta file, which is then inputed into primer3. The output of primer3 is then saved to a tsv file. For every one BED file inputted with n genomic positions, this script will output one tsv file with n pairs of primers.
