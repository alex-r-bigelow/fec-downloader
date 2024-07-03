#! /usr/bin/env bash

cd ./output
rm *.csv

set -e

# edit this line to pick different two-year periods;
# FCC labels files by the ending year, e.g. "20" will download data from 2019-2020
# declare -a years=("24")
declare -a years=("04" "06" "08" "10" "12" "14" "16" "18" "20" "22")

# All files go back as far as 2003-2004, a subset of the data goes back to 1979-1980
# TODO: maybe consider rewriting this script to support custom date ranges for each file?
# Should handle 19xx years more robustly...

# edit this line to add/remove specific tables
declare -A files=(["cn"]="candidates" ["ccl"]="candidate_committee" ["cm"]="committees" ["webk"]="pac_summary" ["webl"]="campaigns" ["weball"]="candidate_summary")
# declare -A files=(["oppexp"]="operating_expenditures" ["pas2"]="committee_candidate_expenditures" ["oth"]="inter_committee_transactions" ["indiv"]="individual_contributions" ["cn"]="candidates" ["ccl"]="candidate_committee" ["cm"]="committees" ["webk"]="pac_summary" ["webl"]="campaigns" ["weball"]="candidate_summary")

# (currently skipping, because they're big files):
# ["indiv"]="individual_contributions"
# ["oth"]="inter_committee_transactions"
# ["pas2"]="committee_candidate_expenditures"
# ["oppexp"]="operating_expenditures"

declare -A decompressedFilenames=(["indiv"]="by_date/itcont_*.txt" ["pas2"]="itpas2.txt" ["oppexp"]="oppexp.txt" ["oth"]="itoth.txt" ["cm"]="cm.txt" ["cn"]="cn.txt" ["ccl"]="ccl.txt")
declare -A extraFilesToDelete=(["indiv"]="by_date itcont.txt")

for file in "${!files[@]}"
do
  echo "Copying manual header file for ${files[$file]}"
  cp ../${file}_header_file.csv ./${files[$file]}.csv
done

# download, decompress, and append data
for year in "${years[@]}"
do
  for file in "${!files[@]}"
  do
    echo "Downloading, decompressing, and appending ${files[$file]} data for 20$year"
    if ! [ -f $file$year.zip ]
    then
      curl -L "https://www.fec.gov/files/bulk-downloads/20$year/$file$year.zip" > $file$year.zip
    fi
    unzip -o $file$year.zip
    if [[ ${decompressedFilenames[$file]} ]]
    then
      cat ${decompressedFilenames[$file]} | sed -E 's/"/""/g' | sed -E 's/^/"/g' | sed -E 's/\|/"|"/g' | sed -E "s/$/\"|20$year/g" >> ${files[$file]}.csv
      rm ${decompressedFilenames[$file]}
    else
      cat $file$year.txt | sed -E 's/"/""/g' | sed -E 's/^/"/g' | sed -E 's/\|/"|"/g' | sed -E "s/$/\"|20$year/g" >> ${files[$file]}.csv
      rm $file$year.txt
    fi
    if [[ ${extraFilesToDelete[$file]} ]]
    then
      rm -rf ${extraFilesToDelete[$file]}
    fi
  done
done
