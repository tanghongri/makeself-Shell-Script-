cat << EOF  > "$TARNAME"
#!/bin/sh -x
# 脚本制作程序版本： $MP_VERSION

ORIG_UMASK=\`umask\`

#umask 077

#md5值
MD5S="$MD5S"
#文件大小
FILESIZES="$FILESIZES"
#许可协议
licensetxt="$LICENSE"
#缓存位置
TMPROOT=\${TMPDIR:=/tmp}
#缓存文件夹
TEMPDIR="\$TMPROOT/mkpackage\$\$"

PrintLicense()
{
  if test x"\$licensetxt" != x; then
    echo "\$licensetxt"
    while true
    do
      printf "Please type y to accept, n otherwise: "
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
    offset=\$2
    length=\$3
    pos=0
    bsize=4194304
    while test \$bsize -gt \$length; do
        bsize=\`expr \$bsize / 4\`
    done
    blocks=\`expr \$length / \$bsize\`
    bytes=\`expr \$length % \$bsize\`
    (
        dd ibs=\$offset skip=1 count=0 2>/dev/null
        pos=\`expr \$pos \+ \$bsize\`
        printf "     0%% " 1>&2
        if test \$blocks -gt 0; then
            while test \$pos -le \$length; do
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

    MD5_PATH=\`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum\`
    if test ! -x "\$MD5_PATH"; then
        echo "MD5: 未找到 md5sum 命令"
        exit 1
    fi
    printf "Verifying archive integrity..."
    
    offset=\`head -n $SKIP "\$1" | wc -c | tr -d " "\`
    verb=\$2
    i=1
    for s in \$FILESIZES
    do	
		
                        md5=\`echo \$MD5S | cut -d" " -f\$i\`
			if test x"\$md5" = x00000000000000000000000000000000; then
				echo " \$1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=\`dd_Progress "\$1" \$offset \$s | eval "\$MD5_PATH \$MD5_ARG" | cut -b-32\`;
				if test x"\$md5sum" != x"\$md5"; then
					echo "Error in MD5 checksums: \$md5sum is different from \$md5" >&2
#					exit 2
				else
					printf " MD5 checksums are OK." >&2
				fi
			fi
		
		
		i=\`expr \$i + 1\`
		offset=\`expr \$offset + \$s\`
    done

    echo " All good."  
}

#命令开始
PrintLicense

mkdir \$TEMPDIR || {
    echo 'Cannot create target directory' \$tmpdir >&2
    echo 'You should try option --target dir' >&2
    exit 1
}

Check "\$0"

#trap 'echo Signal caught, cleaning up >&2; cd \$TMPROOT; /bin/rm -rf \$tmpdir; eval \$finish; exit 15' 1 2 3 15
#检测空间
leftspace=\`diskspace \$TEMPDIR\`
if test -n "\$leftspace"; then
    if test "\$leftspace" -lt $USIZES; then
        echo
        echo "Not enough space left in "\`dirname \$TEMPDIR\`" (\$leftspace KB) to decompress \$0 ($USIZES KB)" >&2
        if test x"\$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval \$finish; exit 1
    fi
fi
#分割文件
offset=\`head -n $SKIP "\$0" | wc -c | tr -d " "\`

for s in \$FILESIZES
do
    dd_Progress "\$0" \$offset \$s >"Test\$s.sh"
    offset=\`expr \$offset + \$s\`
    break;
done

cd \$TMPROOT
#/bin/rm -rf \$TEMPDIR
exit 0
EOF
