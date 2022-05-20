# developed by Alex Klimovskikh in June 2021
# input: model, detail and mode(1d/2d/shear)
# output: ul.prn, ff.prn and fatigue.dat
  
"`reset`"
#1.clear old files
rm *.prn; rm *.dat

if [[ $# -ne 3 ]]; then echo "Args: 1st=model(41-1/..); 2nd=det.Z; 3rd=mode(1d-1/2d-2/shear-3)"; exit 1; fi
model="B378BCFAH4"
case ${3} in
  1) set_ul="set/1d_ul.set"; set_fa="set/1d_fa.set";;
  2) set_ul="set/2d_ul.set"; set_ul_sh="set/2d_ul_sh.set"; set_fa="set/2d_fa.set";;
  *) set_ul="set/sh_ul.set"; set_fa="set/sh_fa.set";;
esac

feadms -m $model${1}FA -det ${2}.det.Z -set $set_fa -a -o ${2}.dat
case ${3} in
  2)  
  feadms -m $model${1}UL -det ${2}.det.Z -set $set_ul -a -o ${2}_ul.prn
  feadms -m $model${1}UL -det ${2}.det.Z -set $set_ul_sh -a -o ${2}_ul_sh.prn
  feadms -m $model${1}FF -det ${2}.det.Z -set $set_ul -a -o ${2}_ff.prn
  feadms -m $model${1}FF -det ${2}.det.Z -set $set_ul_sh -a -o ${2}_ff_sh.prn
  echo -e "\n========== MAX PRINCIPAL LOAD UL ==========";  head -8 ${2}_ul.prn; 
  echo -e "\n========== MAX SHEAR LOAD UL =========="; head -8 ${2}_ul_sh.prn;
  echo -e "\n========== MAX PRINCIPAL LOAD FF ==========";  head -8 ${2}_ff.prn; 
  echo -e "\n========== MAX SHEAR LOAD FF =========="; head -8 ${2}_ff_sh.prn;;
  *)
  feadms -m $model${1}UL -det ${2}.det.Z -set $set_ul -a -o ${2}_ul.prn
  feadms -m $model${1}FF -det ${2}.det.Z -set $set_ul -a -o ${2}_ff.prn
  echo "===== 1.load file created: `ls -l`"

  head -12 ${2}_ul.prn; echo "-----"; tail -5 ${2}_ul.prn
  head -12 ${2}_ff.prn; echo "-----"; tail -5 ${2}_ff.prn;;
esac
