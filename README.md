# MalAdapter
Bash scripts for quantifying and removing adapter contamination from contigs and for reassembling cleaned contigs

This repository contains 5 scripts. 

'script-for-counting-adapters.sh' and 'script-for-counting-adapters-rc.sh' count and tabulate adapter content and statistics for assemblies in the input directory. 'script-for-counting-adapters.sh' outputs information regarding the prevalence and locations of the Illumina universal adapter 'AGATCGGAAGAG', and 'script-for-counting-adapters-rc.sh' outputs information regarding the prevalence and locations of the reverse complement 'CTCTTCCGATCT'.

Similarly, 'script-for-removing-adapters.sh' and 'script-for-removing-adapters-rc.sh' removes ends of contigs containing 'AGATCGGAAGAG' or 'CTCTTCCGATCT', respectively. 

'script-for-CAP3.sh' runs CAP3 (https://doua.prabi.fr/software/cap3) on input assemblies, with the goal of merging overlapping contiguous sequences.
