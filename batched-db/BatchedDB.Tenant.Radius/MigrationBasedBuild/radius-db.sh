# Initialize an empty result list
result=()

# Loop through each line in the first file
while read -r line; do
  # Use grep to search for the line in the second file
  if grep -q "$line" dblist2; then
    # If the line is present in the second file, add it to the result list
    result+=("$line")
  fi
done < radius-dblist

# Print the result list
for i in "${result[@]}"; do
  echo "$i"
done > dblist3