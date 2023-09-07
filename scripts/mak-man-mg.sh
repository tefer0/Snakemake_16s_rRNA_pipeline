#!/bin/bash

var1=$(cat barcode_metadata_mg.csv | cut -f2 | tail -n +2)
var2=$(cat barcode_metadata_mg.csv | cut -f1 | tail -n +2)
var3=./trimmed

echo -e id"\t"absolute-filepath"\t"direction > mg-manifest.tsv

fun()
{
    set $var2
    for i in $var1; do
        #echo "$i" "$1"
        Read=$(realpath $(find $var3 | grep $1 | grep "\\.fastq"));
        echo -e $i"\t"$Read"\t"forward >> mg-manifest.tsv
        shift
    done
}

fun
