#!/bin/bash

usage() {
cat << EOF
Usage: `basename $0` [OPTIONS] <FILE>

-h                show this help
-e                encrypt file
-d                decrypt file
-p <PASSWORD>     password, Required
-s <SALT>         salt
-o <OUTPUT FILE>  output file, Required

EOF
}

action=encrypt

while getopts "dehp:s:i:o:" OPTION; do
    case $OPTION in
    d)
            action=decrypt
            ;;
    e)
            action=encrypt
            ;;
    h)
            usage
            exit 0
            ;;
    p)
            password=$OPTARG
            ;;
    s)
            salt=$OPTARG
            ;;
    i)
            infile=$OPTARG
            ;;
    o)
            outfile=$OPTARG
            ;;
    *)
            infile=$OPTARG
            usage
            exit 0
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z $password ];then
        usage
        echo Please use -p to setup password
        exit 1
fi

if [ -z $outfile ];then
        usage
        echo Please use -o to setup output file
        exit 1
fi

if [ $# -ne 1 ];then
        usage
        echo Must give a file as input file
        exit 1
fi

infile=$1
if [ ! -f ${infile} ];then
        usage
        echo "${infile} is not a file path"
        exit 1
fi

if [ -z $salt ];then
        eval `openssl aes-256-cbc -e -pass pass:${password} -md sha256 -P -pbkdf2 |sed 's/ //g'`
else
        salt=`echo -n $salt | od -A n -t x1 | sed 's/ //g'`
        eval `openssl aes-256-cbc -e -pass pass:${password} -S ${salt} -md sha256 -P -pbkdf2 |sed 's/ //g'`
fi
echo "salt=$salt"
echo "key=$key"
echo "iv=$iv"

if [ $action == encrypt ];then
        openssl aes-256-cbc -in $infile -out $outfile -K ${key} -iv ${iv} -e
        echo
        echo "Now you can set the key and iv in travis website as hide environment variables"
        echo
        echo "And use the follow commandline to decrypt ${outfile}"
        echo "\$ openssl aes-256-cbc -K \$key_variable_name -iv \$iv_variable_name -in ${outfile} -out ${infile} -d"
else
        openssl aes-256-cbc -K ${key} -iv ${iv} -in $infile -out $outfile -d
fi
