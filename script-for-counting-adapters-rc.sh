#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 input_directory"
    exit 1
fi

input_directory="$1"
table_file="${input_directory}_occurrences_table_rc.txt"

# Initialize the table file
echo -e "Expectation\tOccurrences\tp-value\tAverage_distance_to_end\tMax_distance_to_end\tMin_distance_to_end\tAverage_distance_to_ambiguous_base\tMax_distance_to_ambiguous_base\tMin_distance_to_ambiguous_base\tGenome File" > "$table_file"

# Find all fasta files recursively
find "$input_directory" -type f -wholename "*.fna" | while read -r fasta_file; do
    output_file="${fasta_file%.fna}_processed_1A95AD3827A7rc.fasta"
    
    # Remove newlines within sequences and separate each fasta entry onto new lines
    awk 'BEGIN {RS=">"; ORS="\n"} NR>1 {gsub("\n", ""); print ">"$0}' "$fasta_file" > "$output_file"
    
    # Count occurrences of the specified string
    occurrences=$(grep -o "CTCTTCCGATCT" "$output_file" | wc -l)
    
    # Calculate distances between occurrences and the next '>' or 'NNN'
    distances_end=$(awk -v RS='>' 'NR > 1 {if ($0 ~ /CTCTTCCGATCT/) print FNR}' "$output_file")
    distances_ambig=$(awk -v RS='NNN' 'NR > 1 {if ($0 ~ /CTCTTCCGATCT/) print FNR}' "$output_file")

    # Calculate average, max, and min distances
    average_distance_end=$(echo "$distances_end" | awk '{total += $1} END {print total/NR}')
    max_distance_end=$(echo "$distances_end" | awk 'BEGIN {max=0} {if($1>max) max=$1} END {print max}')
    min_distance_end=$(echo "$distances_end" | awk 'BEGIN {min=9999999} {if($1<min) min=$1} END {print min}')

    average_distance_ambig=$(echo "$distances_ambig" | awk '{total += $1} END {print total/NR}')
    max_distance_ambig=$(echo "$distances_ambig" | awk 'BEGIN {max=0} {if($1>max) max=$1} END {print max}')
    min_distance_ambig=$(echo "$distances_ambig" | awk 'BEGIN {min=9999999} {if($1<min) min=$1} END {print min}')
    
    # Calculate the number of contigs multiplied by 11
    num_contigs=$(grep -c "^>" "$fasta_file")
    result=$((num_contigs * 11))
    
    # Extract sequences and remove headers
    sequence_only=$(awk '/^>/ {flag=0; next} {flag=1} flag' "$fasta_file")
    
    # Count the number of bases in the sequences
    num_bases=$(echo -n "$sequence_only" | tr -d '\n' | wc -c)

    # Subtract the number of contigs multiplied by 11 from the number of bases
    total_trials=$((num_bases - result))
    
    # Calculate the expected number of occurrences for a random 12 bp sequence
    expectation=$(echo "scale=10; $total_trials * 5.96046448 / (10^8)" | bc -l)

p_value_observed=$(python - <<END
from scipy.stats import poisson

def calculate_p_value(observed_count, expected_mean):
    cumulative_probability = poisson.cdf(observed_count - 1, expected_mean)
    p_value = 1 - cumulative_probability
    print(p_value)

calculate_p_value($occurrences, $expectation)

END
)

    # Append to the table file
        echo -e "$expectation\t$occurrences\t$p_value_observed\t$average_distance_end\t$max_distance_end\t$min_distance_end\t$average_distance_ambig\t$max_distance_ambig\t$min_distance_ambig\t$fasta_file" >> "$table_file"
        
        echo "Processing completed for $fasta_file. Occurrences: $occurrences"    
     
    rm "$output_file"
    echo "Removed $output_file"
done

echo "Search, counting, and distance calculation completed. Results saved in $table_file"
