#!/usr/bin/awk -f

# String Trim Helper Functions #################################################
# Source: https://gist.github.com/andrewrcollins/1592991
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
################################################################################


BEGIN {
  RECORD_TO_PRINT=""
  META_TO_PRINT=""
  print "{"
}

/: /{
  n=split($0, results, ": ")
  if (n > 1) {
    key=trim(results[1])
    if (key == "Target body name") {
      BODY_NAME = $4
      value = $4 " " $5
      print "\"" BODY_NAME "\": {"
    } else if (key == "Center body name") {
      value = $4 " " $5
    } else {
      for (i=2;i<=n;i++) {
        base_value=trim(results[i])
        if (i>2) {
          value=value ": " base_value
        } else {
          value=base_value
        }
      }
    }

    if (META_TO_PRINT!="") {
      print META_TO_PRINT ","
    }
    META_TO_PRINT="\"" key "\": " "\"" value "\""
  }
}

/\$\$SOE/ {
  FLAG=1
  print "\"data\": ["
  next
}

/\$\$EOE/ {
  FLAG=0
  print RECORD_TO_PRINT
  print "],"
}

{
  if (FLAG) {
    n=split($0, results, ",")
    if (n=11) {
      if (RECORD_TO_PRINT != "") {
        print RECORD_TO_PRINT ","
      }
      RECORD_TO_PRINT="["           \
        trim(results[1]) ","        \
        "\"" trim(results[2]) "\"," \
        trim(results[3])       ","  \
        trim(results[4])       ","  \
        trim(results[5])       ","  \
        trim(results[6])       ","  \
        trim(results[7])       ","  \
        trim(results[8])       ","  \
        trim(results[9])       ","  \
        trim(results[10])      ","  \
        trim(results[11])           \
        "]"
    }
  }
}

END {
  if (META_TO_PRINT != "") {
    print META_TO_PRINT
  }
  print "}"
  print "}"
}
