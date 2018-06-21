#/bin/bash

#take in some bed file with sequences and return primers for said sequences

#convert each line of bed to fasta to be inserted into primer3 one by one
INPUT=$1
LINES=$(wc -l < $INPUT)
GENOME=$2
output=$3
seq="SEQUENCE"
if [ -e "$output" ]
then
  rm "$output"
fi
echo -e "bed \t pair \t OLIGO \t primer \t start \t len \t tm \t gc% \t any_th \t 3'_th \t hairpin \t seq" > $output
for ((n=1;n<=$LINES;n++))
do
    #get position for n loci
    sed "${n}q;d" $INPUT > hold.bed

    #convert bed to fasta in temp.fa
    bedtools "getfasta" -fi $GENOME -bed hold.bed -fo temp.fa

    #read temp.fa excluding the header
    SEQUENCE=`cat temp.fa | tail -n 1`

    #find length of sequence for primer iteration
    LENGTH=${#SEQUENCE}

    #desired product size
    AMOUNT=200

    #number of times to repeat iteration
    DIV=$((LENGTH / AMOUNT))
    ONE=$((DIV - 1))

    #sequence ID
    NAME=`cat temp.fa | head -n 1`

    #delete temporary files
    rm hold.bed temp.fa

    #repeat primer3 i times depending on size of sequence and product size range
    for ((i=0;i<=$ONE;i++));
    do
      #increase each iteration by product size, starting at 50; with a range of product size - product size + 50
      CURRENT=$(($AMOUNT * i))
      AMOUNTR=$((AMOUNT+50))
      RANGE=($AMOUNT-$AMOUNTR)
      ACT=$((50 + CURRENT))
      echo "$ACT/$LENGTH"
      TARGET=($ACT,$AMOUNT)

      #create primer file for primer3 input
      echo "SEQUENCE_ID=$NAME">primer
      echo "SEQUENCE_TEMPLATE=$SEQUENCE">>primer
      echo "SEQUENCE_TARGET=$TARGET">>primer
      echo "PRIMER_PICK_LEFT_PRIMER=1">>primer
      echo "PRIMER_PICK_INTERNAL_OLIGO=0">>primer
      echo "PRIMER_PICK_RIGHT_PRIMER=1">>primer
      echo "PRIMER_PRODUCT_SIZE_RANGE=$RANGE">>primer
      echo "=">>primer

      #save right primer from primer3 to check for errors
      secondrow=`primer3_core -format_output primer | sed '7q' | tail '-n' 1`

      #output first eight characters to check for errors
      shorter=${secondrow:0:8}

      #If it fails to find a primer, increase the product range by 25 bp until primer found
      until [[ "$shorter" != "$seq" ]];
      do
        AMOUNTR=$((AMOUNTR+25))
        RANGE=($AMOUNT-$AMOUNTR)
        CURRENT=$(($AMOUNT * i))
        ACT=$((50 + CURRENT))
        echo "no primers found, increasing product size range to $RANGE"
        TARGET=($ACT,$AMOUNT)
        echo "SEQUENCE_ID=$NAME">primer
        echo "SEQUENCE_TEMPLATE=$SEQUENCE">>primer
        echo "SEQUENCE_TARGET=$TARGET">>primer
        echo "PRIMER_PICK_LEFT_PRIMER=1">>primer
        echo "PRIMER_PICK_INTERNAL_OLIGO=0">>primer
        echo "PRIMER_PICK_RIGHT_PRIMER=1">>primer
        echo "PRIMER_PRODUCT_SIZE_RANGE=$RANGE">>primer
        echo "=">>primer
        secondrow=`primer3_core -format_output primer | sed '7q' | tail '-n' 1`

        shorter=${secondrow:0:8}
      done

      #get left primer after confirming no errors
      firstrow=`primer3_core -format_output primer | sed '6q' | tail '-n' 1`

      #store sequence name and iteration id for pairing
      firstrowind=`echo "$NAME $i $firstrow"`
      secondrowind=`echo "$NAME $i $secondrow"`

      #convert spaces to tabs for tsv output
      tabbedfirst=`echo $firstrowind | tr -s ' ' '\t'`
      tabbedsecond=`echo $secondrowind | tr -s ' ' '\t'`
      echo "$tabbedfirst" >> $output
      echo "$tabbedsecond" >> $output
      clear
    done
done

#remove primer column (column 4)
cat $output | cut -f4 --complement > $output
