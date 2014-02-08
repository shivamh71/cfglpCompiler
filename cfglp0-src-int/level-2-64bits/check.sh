# !/bin/bash

rm -rf tmpUs tmpSir
mkdir tmpUs tmpSir

for file in "test_files"/*.c 
do
	file=`echo $file | cut -d '/' -f2`
	make -f Makefile.cfg FILE=$file
done

echo "\nProcessing correct files"
echo "-------------------------\n"

for file in "test_files"/*.cs306.cfg 
do
	echo $file
	f=`echo $file | cut -d '/' -f2`
	f=`echo $f | cut -d '.' -f1`
	./cfglp $file -tokens -d > tmpUs/$f.cfg
	./run $file -tokens -d > tmpSir/$f.cfg
done

echo "\n\nProcessing error files"
echo "-----------------------\n"

for file in "test_files"/*.e* 
do
	echo $file
	f=`echo $file | cut -d '/' -f2`
	f=`echo $f | cut -d '.' -f1`
	./cfglp $file -tokens -d > tmpUs/$f.ecfg
	./run $file -tokens -d > tmpSir/$f.ecfg
	echo "-------------------------------------------"
done