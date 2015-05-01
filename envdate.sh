#!/bin/bash
# There are many development environments with different dates in my bank
# I read all these different envrionments and check what the system dates are
# and then present them in a readable format so that when issues occur,before
# we go to the unix tape restoration team we can check if any enviornments 
# for the date of issue reported already exists.I think this is pretty usefull.
# Warm regards,
# Harish
locs='/u01/globus /u03/globus' 
echo "\n"
for fsone in $locs;do
echo $fsone" space"
echo "*****************"
space=`df -g $fsone`
totspace=`echo $space | awk '{print $11}'`
freespace=`echo $space | awk '{print $12}'`
avgsize="Avg size of a T24 env      : 62-70 GB"
echo "Total space in "$fsone" : "$totspace" GB "
echo "Free space in "$fsone" : "$freespace" GB "
echo $avgsize
echo "------------------------------------------------"
echo "Globus Env Details\tEnv Date\tEnv.Desc"
echo "******************\t********\t*********"
reqenv=`ls $fsone`
for curenv in $reqenv;do
globusenv=$fsone'/'$curenv'/bnk.run'
if [ -d $globusenv ]
then
cd $globusenv
out=`exec /usr/tafcr11/bin/jpqn /root/VOC/datefunc`
echo $out | awk '{print $1"\t"$2"\t"$3}'
else
globusenv=$fsone'/'$curenv'/tebbnk/bnk.run'
if [ -d $globusenv ];then
cd $globusenv
out=`exec /usr/tafcr11/bin/jpqn /root/VOC/datefunc`
echo $out | awk '{print $1"\t"$2"\t"$3}'
fi
fi
done
echo "\n"
done
