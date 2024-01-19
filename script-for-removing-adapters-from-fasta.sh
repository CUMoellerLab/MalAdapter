#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_fasta_file>"
    exit 1
fi

input_file="$1"
output_file="${input_file%.fasta}_modified.fasta"

python3 -c '
with open("'"$input_file"'", "r") as infile, open("'"$output_file"'", "w") as outfile:
    header = None
    for line in infile:
        if line.startswith(">"):
            if header:
                outfile.write("\n")
            header = line.strip()
            outfile.write(line)
        else:
            outfile.write(line.strip())
    outfile.write("\n")
'

input_file="$output_file"
output_file2="${input_file%.fasta}_trimmed.fasta"

# Identify and trim contigs
awk -v pattern="AGATCGGAAGAG" '
    /^>/ {
        if (header) {
            if (match(sequence, pattern)) {
                position = RSTART + RLENGTH - 1
                if (length(sequence) - position < 300) {
                    sequence = substr(sequence, 1, position - 450)
                }
            }
            print header
            print sequence
        }
        header = $0
        sequence = ""
    }
    !/^>/ {
        sequence = sequence $0
    }
    END {
        if (header) {
            if (match(sequence, pattern)) {
                position = RSTART + RLENGTH - 1
                if (length(sequence) - position < 300) {
                    sequence = substr(sequence, 1, position - 450)
                }
            }
            print header
            print sequence
        }
    }
' "$input_file" > "$output_file2"

echo "Contig identification and trimming completed. Modified fasta file saved to: $output_file2"