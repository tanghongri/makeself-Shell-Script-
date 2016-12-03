cat << EOF  > "$TARNAME"
#!/bin/sh
# 脚本制作程序版本： $MP_VERSION

#md5值
MD5S="$MD5S"
#文件大小
FILESIZES="$FILESIZES"
#许可协议
licensetxt="$LICENSE"
#缓存文件夹
TEMPDIR="\$(dirname \$0)/Temp\$\$"
#校验程序名称
CHECKNAME="$CHECKNAME"
#安装脚本名称
INSTALLNAME="$INSTALLNAME"
#md5sum路径
MD5_PATH=""
#HEADER脚本大小
SKIP=0
#退出清理
OUTCLEAN=true
#许可协议
PrintLicense()
{
  	if test x"\$licensetxt" != x; then
   		echo "\$licensetxt"
    		while true
   		do
		printf "请输入 y 接受, n 退出安装: "
      		read yn
      		if test x"\$yn" = xn; then
        		exit 1
       	 		break;
      		elif test x"\$yn" = xy; then
        		break;
      		fi
    	done
  	fi
}
#空间
diskspace()
{	
	df -kP "\$1" | tail -1 | awk '{ if (\$4 ~ /%/) {print \$3} else {print \$4} }'
}
#dd进度条
dd_Progress()
{
    	file="\$1"
    	ddoffset=\$2
    	length=\$3
    	pos=0
    	bsize=4194304
    	while test \$bsize -gt \$length
 	do
        	bsize=\`expr \$bsize / 4\`
    	done
    	blocks=\`expr \$length / \$bsize\`
    	bytes=\`expr \$length % \$bsize\`
    	(
        	dd ibs=\$ddoffset skip=1 count=0 2>/dev/null
        	pos=\`expr \$pos \+ \$bsize\`
        	printf "     0%% " 1>&2
        	if test \$blocks -gt 0 
		then
            		while test \$pos -le \$length 
			do
                		dd bs=\$bsize count=1 2>/dev/null
                		pcent=\`expr \$length / 100\`
                		pcent=\`expr \$pos / \$pcent\`
                		if test \$pcent -lt 100; then
                    			printf "\b\b\b\b\b\b\b" 1>&2
                    			if test \$pcent -lt 10; then
                        			printf "    \$pcent%% \n" 1>&2
                    			else
                        			printf "   \$pcent%% \n" 1>&2
                   	 		fi
                		fi
                		pos=\`expr \$pos \+ \$bsize\`
           		done
        	fi
        	if test \$bytes -gt 0; then
            		dd bs=\$bytes count=1 2>/dev/null
        	fi
        	printf "\b\b\b\b\b\b\b" 1>&2
        	printf " 100%%  \n" 1>&2
    	) < "\$file"
}
#检查文件
Check()
{
    	printf "开始校验MD5......\\n"
    	OFFSET=\$2
    	Index=1
    	for filesize in \$FILESIZES
    	do	
		
        	md5=\`echo \$MD5S | cut -d" " -f\$Index\`
		if test x"\$md5" = x00000000000000000000000000000000; then
			echo " \$1 无MD5校验信息." >&2
		else
			md5sum=\`dd_Progress "\$1" \$OFFSET \$filesize | eval "\$MD5_PATH \$MD5_ARG" | cut -b-32\`;
			if test x"\$md5sum" != x"\$md5" 
			then
				echo "MD5 校验失败: \$s \$sum  与 \$md5 不同" >&2
				eval \$OUTCLEAN;exit 2
			else
				printf "文件\$Index MD5 校验成功.\\n" >&2
			fi
		fi
		
		Index=\`expr \$Index + 1\`
		OFFSET=\`expr \$OFFSET + \$filesize\`
    	done
    
    	if test \$Index -ne 3
	then
		printf "文件数量错误\n" 1>&2
		eval \$OUTCLEAN;exit 3
	fi 
    	echo "所有文件MD5校验成功."  
}

#命令开始

#
PrintLicense

mkdir \$TEMPDIR || {
    	echo '创建临时文件夹失败： \$tmpdir >&2' 
    	exit 4
}
OUTCLEAN="\$OUTCLEAN ;/bin/rm -rf \$TEMPDIR"


#检查md5环境
#查找md5sum
MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
if test ! -x "$MD5_PATH"; then  		
    	echo "MD5: 未找到 md5sum 命令"
	eval \$OUTCLEAN;exit 5		
fi
#
trap "echo "捕捉到信号，退出清理！" >&2; eval \$OUTCLEAN; exit 15" 1 2 3 15
#HEADER脚本大小
SKIP=\`head -n $SKIP "\$0" | wc -c | tr -d " "\`
#校验md5
Check "\$0" "\$SKIP"

#检测空间
leftspace=\`diskspace \$TEMPDIR\`
if test -n "\$leftspace"; then
    	if test "\$leftspace" -lt $USIZES; then
        	echo "目录没有足够的空间可用： "\`dirname \$TEMPDIR\`" (\$leftspace KB)来释放 \$0 ($USIZES KB)" >&2
		eval \$OUTCLEAN;exit 6
    	fi
fi
#分割文件
Index=1
OFFSET=\$SKIP

for filesize in \$FILESIZES	
do
	if test \$Index -eq 1
	then	 	
		printf "释放授权程序......\n" 1>&2
	 	dd_Progress "\$0" \$OFFSET \$filesize > "\$TEMPDIR/\$Index"
		chmod +x "\$TEMPDIR/\$Index"
		\$TEMPDIR/\$Index
		if test \$? -ne 0
		then
			echo "授权失败，退出安装程序！"
			eval \$OUTCLEAN;exit 7
		fi
	elif test \$Index -eq 2
	then
		printf "释放安装程序......\n" 1>&2
		dd_Progress "\$0" \$OFFSET \$filesize | tar -zxvf - -C"./\$TEMPDIR/"
	fi 
	
	Index=\`expr \$Index + 1\`
	OFFSET=\`expr \$OFFSET + \$filesize\`
done

eval \$OUTCLEAN;exit 0
EOF
