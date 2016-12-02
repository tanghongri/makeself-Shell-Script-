cat << EOF  > "$TARNAME"
#!/bin/sh -x
# 脚本制作程序版本： $MP_VERSION

#md5值
MD5S="$MD5S"
#文件大小
FILESIZES="$FILESIZES"
#许可协议
licensetxt="$LICENSE"
#缓存文件夹
TEMPDIR="Temp\$\$"
#校验程序名称
CHECKNAME="$CHECKNAME"
#md5sum路径
MD5_PATH=""
#HEADER脚本大小
SKIP=0

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
                        			printf "    \$pcent%% " 1>&2
                    			else
                        			printf "   \$pcent%% " 1>&2
                   	 		fi
                		fi
                		pos=\`expr \$pos \+ \$bsize\`
           		done
        	fi
        	if test \$bytes -gt 0; then
            		dd bs=\$bytes count=1 2>/dev/null
        	fi
        	printf "\b\b\b\b\b\b\b" 1>&2
        	printf " 100%%  " 1>&2
    	) < "\$file"
}
#检查文件
Check()
{
    printf "开始校验MD5..."
    OFFSET=\$2
    Index=1
    for s in \$FILESIZES
    do	
		
                        md5=\`echo \$MD5S | cut -d" " -f\$Index\`
			if test x"\$md5" = x00000000000000000000000000000000; then
				echo " \$1 无MD5校验信息." >&2
			else
				md5sum=\`dd_Progress "\$1" \$OFFSET \$s | eval "\$MD5_PATH \$MD5_ARG" | cut -b-32\`;
				if test x"\$md5sum" != x"\$md5" 
				then
					echo "MD5 校验失败: \$s \$sum  与 \$md5 不同" >&2
					exit 2
				else
					printf "\$s MD5 校验成功." >&2
				fi
			fi
		
		
		Index=\`expr \$Index + 1\`
		OFFSET=\`expr \$OFFSET + \$s\`
    done

    echo "所有文件MD5校验成功."  
}

#命令开始

#
PrintLicense

mkdir \$TEMPDIR || {
    	echo '创建临时文件夹失败： \$tmpdir >&2' 
    	exit 1
}
#检查md5环境
#查找md5sum
MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
if test ! -x "$MD5_PATH"; then  		
    	echo "MD5: 未找到 md5sum 命令"
	exit 1		
fi
#HEADER脚本大小
SKIP=\`head -n $SKIP "\$0" | wc -c | tr -d " "\`
#校验md5
Check "\$0" "\$SKIP"

#检测空间
leftspace=\`diskspace \$TEMPDIR\`
if test -n "\$leftspace"; then
    	if test "\$leftspace" -lt $USIZES; then
        	echo
        	echo "目录没有足够的空间可用： "\`dirname \$TEMPDIR\`" (\$leftspace KB)来释放 \$0 ($USIZES KB)" >&2
		exit 1
    	fi
fi
#分割文件
Index=1
OFFSET=\$SKIP
for s in \$FILESIZES
do
    	dd_Progress "\$0" \$OFFSET \$s > "\$TEMPDIR/\$Index"
	chmod +x "\$TEMPDIR/\$Index"
       
    	OFFSET=\`expr \$OFFSET + \$s\`
	Index=\`expr \$Index + 1\`

done

cd ".."
#/bin/rm -rf \$TEMPDIR
exit 0
EOF
