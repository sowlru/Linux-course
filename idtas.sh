#created by Alex Klimovskikh in March 2021
#it help to automate task from extract FEADMS load and put it into IDTAS 
#input: xxx.det.Z & flight profile
#output: pnt29b
# directory structure:
# 1_detail | 2_loads | 3_profile | 4_result
if [[ $# -ne 3 ]]; then echo "1st arg = section; 2nd =  ../loads1d/STA-.dat; 3rd = mode(1D/2D/shear) "; exit 1; fi
"`reset`"

case ${3} in
  2) mode="mod fx-fy-fs";;
  3) mode="mod shear";;
  *) mode="mod tension";;
esac

#1.create load file
cp $2 2_loads/load.dat
load_file="2_loads/load.dat"
#feadms -m $model -det $det -set 1_detail/1d.set -a -o $load_file

echo "===== 1.load file created: `ls -l 2_loads`"

#2. clear all previous files
if [ -z "$(ls -A 4_result)" ]; then 
  echo "===== 2.result folder is empty: `ls -l 4_result`"
else `rm -r 4_result/*`; fi

#3. get elements array from xxx.dat 
#_.1.read element, lc, 1dstress string
  elem_line=$(tail -n 4 "$load_file" | head -1)
    lc_line=$(tail -n 3 "$load_file" | head -1)
stress_line=$(tail -n 2 "$load_file" | head -1)

#_.2.split line to array
IFS='|' read -ra   elem_ar <<< "$elem_line"
IFS='|' read -ra     lc_ar <<< "$lc_line"
IFS='|' read -ra stress_ar <<< "$stress_line"

#_.3.get bytes where block end
  elem_byte=${elem_ar[3]}
    lc_byte=${lc_ar[3]}
stress_byte=${stress_ar[3]}

#_.4.create array of  elems and x_coord
var_block_offset=80;
byte_sum=0; 
var_line=0;
elems=(); coord_x=()
while read line; do
  #count bytes in line and add to sum
  ((byte_sum+=${#line}+1))
  # echo "debug: len of $line = $byte_sum"
  #if we are in var block - put #elem, coord_x in array
  if (( $elem_byte+$var_block_offset  < byte_sum && byte_sum < $lc_byte-40 )); then
    # translate scientific notation to decimal
    #line=$(printf "%.1f" "$line");
    # var_block consist of group of 5 lines: #elem,beam,x,y,z
    echo "debug: reminder = $reminder"
    ((reminder=var_line%5))
    case $reminder in
      0) 
          # translate scientific notation to decimal
          line=$(printf "%.0f" "$line");
          elems+=($line);; 
      2)
          line=$(printf "%.1f" "$line");
          coord_x+=($line); ((byte_sum+=2));; 
      *) ((byte_sum+=2));;
    esac
    ((var_line+=1)); 
    echo "debug: var block $var_line"
  fi
  echo "debug: $line"
  if [ "$line" = "LoadCase" ]; then 
    echo "End of Elements Block"
    break
  fi
  #sleep 1 
done < $load_file
len_elem=${#elems[@]}
echo "===== 3.elements array ($len_elem) extracted from load_file"
for e in "${elems[@]}"; do echo -e $e; done
echo "===== x_coord"
for x in "${coord_x[@]}"; do echo -e $x; done

fold="3_profile/s4${1}/"
for ((pd=1;pd<=4;pd++)); do #pd - short for profile+dmf case
 case $pd in
   1) folder="${fold}med_mom";     profile="737-800bcfs4${1}medc";   dmf="M";;
   2) folder="${fold}med_shear";   profile="737-800bcfs4${1}medc";   dmf="V";;
   3) folder="${fold}short_mom";   profile="737-800bcfs4${1}shortc"; dmf="M";;
   4) folder="${fold}short_shear"; profile="737-800bcfs4${1}shortc"; dmf="V";;
 esac

 #4. create in159
 ((len_analysis=$len_elem*3))
 echo "debug: len_analysis = $len_analysis" 
 in159="$folder/$profile.in159"; rm $in159; touch $in159
 echo "$len_elem $len_analysis  /" > $in159 
 for((i=0; i<$len_elem; i++));do
  echo "${elems[i]}             1 $mode dmf X${coord_x[i]}$dmf /" >> $in159
 done
 echo -e "===== 4.idtas in159 file created\n `cat -n $in159`"

 #5. create idtas batch
 bat="tmp"; rm $bat; touch $bat
 echo -e "$folder\n$profile\nn\n4_result\nn" >> $bat
 idtas batch -bin $bat 
 echo -e "===== 6.create idtas batch file:\n `cat -n $bat`"
done

#6. check result
result="4_result/pnt29b"
echo -e "===== 7.show pnt29b"
if [[ -e $result ]]; then cat $result; else echo "pnt29b not found"; fi 
