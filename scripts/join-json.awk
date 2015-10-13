#!/usr/bin/awk -f

BEGIN {
  FILE_NUMBER=0
  print "{"
}

FNR==1 {
  if (FILE_NUMBER > 0)  {
    print ","
  }
  FILE_NUMBER++
}

{
  print
}

END {
  print "}"
}
