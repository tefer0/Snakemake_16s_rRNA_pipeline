#!/bin/bash

var1=$(cat barcode_metadata_ov.csv | cut -f2 | tail -n +2)
var2=$(cat barcode_metadata_ov.csv | cut -f1 | tail -n +2)
var3=./trimmed

echo -e sample-id"\t"absolute-filepath"\t"direction > ov-manifest.tsv

fun()
{
    set $var2
    for i in $var1; do
        #echo "$i" "$1"
        Read=$(realpath $(find $var3 | grep $1 | grep "\\.fastq"));
        echo -e $i"\t"$Read"\t"forward >> ov-manifest.tsv
        shift
    done
}

fun
