#!/bin/bash

# Parameters
FILE=$1
DEST=$2
HRS=$3
CHUNKS=$4

if [ ! -d "$DEST" ]
then
    echo "giterator >> Destination $DEST doesn't exist"
    exit 1
fi

cd "$DEST"

# Make repo at destination if non-existent
if [ -d ".git/" ]
then
    echo "giterator >> Repo exists at directory"
else
    echo "giterator >> Repo does not exist"
    git init
fi

# Store lines of source file into array
linecount=`wc -l < "$FILE"`
chunk_size=$((linecount / 4))
filename="$(basename -- "$FILE")"
period=$((HRS * 60 * 60 / 5)) # in seconds

echo "giterator >> File name: $filename"
echo "giterator >> File size: $linecount lines"
echo "giterator >> Chunk size: $chunk_size lines"
echo "giterator >> Chunk period: $period seconds"

mapfile -t lines < "$FILE"

# Write to destination file periodically
for chunk_i in {0..4}
do
    line_start=$((chunk_i * chunk_size))
    line_end=$((line_start + chunk_size-1))

    if (( $line_end > $linecount ))
    then line_end=$linecount
    fi

    echo "giterator >> Working on chunk $chunk_i ($line_start to $line_end)"
    sleep $period

    for (( line_j=$line_start; line_j<=$line_end; line_j++ ))
    do
        line=${lines[line_j]}
        echo $line >> "$filename"
    done

    echo "giterator >> Wrote chunk $chunk_i"

    git add .
    git commit -m "commit $((chunk_i + 1))"
done

truncate -s -1 "$filename" # Removes ending newline
echo "Done."