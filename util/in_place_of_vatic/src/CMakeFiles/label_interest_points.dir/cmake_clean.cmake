FILE(REMOVE_RECURSE
  "label_interest_points.pdb"
  "label_interest_points"
)

# Per-language clean rules from dependency scanning.
FOREACH(lang)
  INCLUDE(CMakeFiles/label_interest_points.dir/cmake_clean_${lang}.cmake OPTIONAL)
ENDFOREACH(lang)
