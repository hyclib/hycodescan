#! /bin/sh

bin_path="../../../hy_bin/latest/"

for lib_name in "hycodescan"
do
	mkdir -p $bin_path"include/"
    mkdir -p $bin_path"include/"$lib_name"/"
	mkdir -p $bin_path"libs/ios/"
	cp -rf "./readme.txt"      $bin_path"include/"$lib_name"/readme.txt"

	rm -rf   $bin_path"include/include"
    rm -rf   $bin_path"include/"$lib_name"/ios"
	cp -rf "./ios/include"                        $bin_path"include/"
    mv -f  $bin_path"include/include"             $bin_path"include/"$lib_name"/ios"
	cp -rf "./bin/Debug-iphoneos" 		          $bin_path"libs/ios/"
	cp -rf "./bin/Debug-iphonesimulator"          $bin_path"libs/ios/"
	cp -rf "./bin/Release-iphoneos"               $bin_path"libs/ios/"
	cp -rf "./bin/Release-iphonesimulator"        $bin_path"libs/ios/"
done

echo "is done"

 

 
 
