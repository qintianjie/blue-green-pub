#!/bin/bash
echo "start"
#echo "$#"
#tag=${1:-dev}

if [ $# -gt 0 ]; then
    tag=$1
    if [ "x$tag" != "xdev" -a "x$tag" != "xprod" -a "x$tag" != "xqa" ]; then
        echo "tag should in  ["dev", "prod", "qa"]"
        exit 1
    fi  
else
    echo "No input tag, use default: dev"
    tag="dev"
fi

echo "package by tag: $tag"


basepath=$(cd `dirname $0`; pwd)
echo $basepath
output_dir=${basepath}/output
rm -rf ${output_dir}
mkdir ${output_dir}

packagepath=$basepath/src
configfile_base=${basepath}/conf/configbase.lua
configfile_src=${basepath}/conf/config-${tag}.lua
configpath_dest=${packagepath}/lua/conf/config.lua

cp $configfile_base  ${packagepath}/lua/conf/configbase.lua
cp $configfile_src  $configpath_dest

cd ${packagepath} 
tar -zcvf ${basepath}/output/bg-pub.tar.gz *

rm -rf ${configpath_dest}
rm -rf ${packagepath}/lua/conf/configbase.lua
