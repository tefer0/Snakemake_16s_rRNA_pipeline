
SAMPLE_METADATA=$1
READS_DIR=$2

echo -e id"\t"forward-absolute-filepath"\t"reverse-absolute-filepath > manifest.tsv

for s in $(cat $SAMPLE_METADATA | cut -f1 | tail -n +2); do
#  echo $s;
  R1=$(realpath $(find $READS_DIR | grep $s"_" | grep "R1" | grep "\\.fastq"));
  R2=$(realpath $(find $READS_DIR | grep $s"_" | grep "R2" | grep "\\.fastq"));
  echo -e $s"\t"$R1"\t"$R2 >> manifest.tsv
done
