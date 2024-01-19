#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 input_file"
    exit 1
fi

input_file="$1"

max_length=21000 

# Create the output files
> "$input_file.longest_contigs.fna"
> "$input_file.shortest_contigs.fna"

# Remove contigs longer than the specified maximum length
# Initialize variables
saved_header=""
saved_sequence=""
contig_length=0

# Process each line in the input file
while IFS= read -r line; do
    if [[ $line == ">"* ]]; then
        # Header line
        if [ $contig_length -le $max_length ]; then
            # Save header and sequence to output file
            echo -e "$saved_header\n$saved_sequence" >> "$input_file.shortest_contigs.fna"
        else
            # Save header and sequence to removed contigs file
            echo -e "$saved_header\n$saved_sequence" >> "$input_file.longest_contigs.fna"
        fi
        saved_header="$line"
        saved_sequence=""
        contig_length=0
    else
        # Sequence line
        saved_sequence="$saved_sequence$line"
        contig_length=$((contig_length + ${#line}))
    fi
done < "$input_file"

# Handle the last contig
if [ $contig_length -le $max_length ]; then
    echo -e "$saved_header\n$saved_sequence" >> "$input_file.shortest_contigs.fna"
else
    echo -e "$saved_header\n$saved_sequence" >> "$input_file.longest_contigs.fna"
fi


echo "Contigs longer than $max_length bases removed and saved to $input_file.longest_contigs.fna."
echo "Remaining contigs saved to $input_file.shortest_contigs.fna."

CAP3/cap3 $input_file.shortest_contigs.fna -z 1 -y 6 -f 2 -p 99

cat $input_file.longest_contigs.fna $input_file.shortest_contigs.fna.cap.singlets $input_file.shortest_contigs.fna.cap.contigs > $input_file.adapters_removed.contigs_merged.fa

python script-for-n50.py $input_file.adapters_removed.contigs_merged.fa > $input_file.N50_value_after.txt
python script-for-n50.py $input_file > $input_file.N50_value_before.txt

rm $input_file.longest_contigs.fna
rm $input_file.shortest_contigs.fna

echo "finished $input_file"



