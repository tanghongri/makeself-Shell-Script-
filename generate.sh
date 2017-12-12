#!/bin/sh -x
#收集需要打包文件
DIR_PATH=$(dirname $(readlink -f "$0"))

if test $# -lt 3
then
	echo "arg:sourcedir packname targetdir"
	echo "ERROR:need 3,arg num $# $@"
	exit -1
fi

if test ! -d $1
then
	echo "sourcedir not exist:$1"
	exit -1
fi

#版本号
PACK_VISION=$(date +"%Y%m%d")

#目标文件夹
SourceDir=$1

#打包目录
PackName=$2

#生成包位置
TargetDir=$3

mkdir -p $TargetDir
#临时文件目录
TempDir="$DIR_PATH/temp"

rm -fr $TempDir
mkdir -p $TempDir

#复制打包脚本
cp -r $DIR_PATH/installsource/. 							$TempDir
cp -r $SourceDir/$PackName/. 								$TempDir


#删除资源目录中的.svn
find $TempDir -iname ".svn" | xargs -i rm -rf {}

#打包
chmod +x $DIR_PATH/makepackage.sh
$DIR_PATH/makepackage.sh "$TempDir" "$TargetDir/${PackName}_${PACK_VISION}.pkg"
#执行成功
echo "!!!!!!!!!!##########安装包制作完成##########!!!!!!!!!!"