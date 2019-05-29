#!/bin/bash
set -e
set -x

usage() {
cat << EOF
Usage: `basename $0` [OPTIONS] [index.html]

Generate analyzer results index

-h                 show this help
-b <BRANCH>        branch name
-c <COMMIT>        commit id
-d <PATH>          html files directory
-i <URL>           project icon url
-l <NUMBER>        keep results numbers.
-m <MESSAGES>      commit messages
-n <NAME>          project name
-o <OWNER>         project owner
-p <CPPCHECK_PATH> cppcheck html directory
-r <RANGE>         commit range
-t <TRAVIS_URL>    url
EOF
}

count=10
branch=${TRAVIS_BRANCH}
owner=${OWNER_NAME}
name=${REPO_NAME}
commit=${TRAVIS_COMMIT}
commit_range=${TRAVIS_COMMIT_RANGE}
commit_message=${TRAVIS_COMMIT_MESSAGE}
travis_url=${TRAVIS_BUILD_WEB_URL}
directory=html-report
cppcheck_directory=cppcheck-htmlreport
index_page=index.html

while getopts "hb:c:d:i:l:m:n:o:p:r:t:" OPTION; do
    case $OPTION in
    b)
            branch=$OPTARG
            ;;
    c)
            commit=$OPTARG
            ;;
    d)
            directory=$OPTARG
            ;;
    i)
            icon_url=$OPTARG
            ;;
    l)
            count=$OPTARG
            ;;
    m)
            message=$OPTARG
            ;;
    n)
            name=$OPTARG
            ;;
    o)
            owner=$OPTARG
            ;;
    p)
            cppcheck_directory=$OPTARG
            ;;
    r)
            commit_range=$OPTARG
            ;;
    t)
            travis_url=$OPTARG
            ;;
    h)
            usage
            exit 1
            ;;
    *)
            usage
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

if [ $# -eq 1 ];then
        index_page=$1
fi


if [ ! -d "$directory" ] && [ ! -d "${cppcheck_directory}" ]; then
        echo "No such directory ${directory} or ${cppcheck_directory}."
        exit 1
fi

echo "Generating clang analyzer results index file..."

cat > $index_page <<EOF
<!DOCTYPE HTML>
<html lang="en">
  <head>
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
EOF

if [ -n "$icon_url" ];then
        echo "  <link rel=\"icon\" href=\"$icon_url\" />" >> ${index_page}
fi

cat >> ${index_page} << EOF
  <title>${name} Code Analyzer results</title>
</head>
<body>
<h1>
  <a href="https://github.com/${owner}">${owner}</a>/<a href="https://github.com/${owner}/${name}">${name}</a> Static analyzer results
</h1>
  <a href="https://github.com/${owner}/${name}" title="Github"><i class="fa fa-github fa-2x"></i>GitHub</a>
  <a href="${travis_url}" title="Travis CI"><img src="https://travis-ci.org/${owner}/${name}.svg?branch=master" alt="Build Status" /></a>
<hr/>
Commit: <a href="https://github.com/${owner}/${name}/commit/${commit}">${commit}</a><br/>
Compare: <a href="https://github.com/${owner}/${name}/compare/${commit_range}">${commit_range}</a><br/>
Branch: <a href="https://github.com/${owner}/${name}/tree/${branch}">${branch}</a><br/>
Time: `date --rfc-3339=seconds`<br/>
Messages:<br/>
<pre>
${commit_message}
</pre>
<hr/>
<ul>
EOF

# add the cppcheck html directory
if [ -d "${cppcheck_directory}" ];then
    timenow=`date +%F-%H%M%S`
    nanoseconds=`date +%N`
    new_folder="${timenow}-${nanoseconds:0:4}-cppcheck@${commit:0:12}_${branch//\//_}"
    mv "${cppcheck_directory}" "${directory}/${new_folder}"
    echo "<li><a href=\"${new_folder}\">${new_folder}</a></li>" >> ${index_page}
    ((count-=1))
fi

# add the current clang analyzer result
if [ -d "${directory}" ];then
    current_result=`find ${directory} -maxdepth 1 -type d -name "????-??-??-*"|grep -v cppcheck|head -n1`
    if [ -n "$current_result" ];then
            old_result=`basename $current_result`
            new_result="${old_result}@${commit:0:12}_${branch//\//_}"
            mv "${directory}/${old_result}" "${directory}/${new_result}"
            echo "<li><a href=\"${new_result}\">${new_result}</a></li>" >> ${index_page}
            ((count-=1))
    fi
else
    mkdir ${directory}
fi

# add the history results
temp_work_dir=`mktemp -d -u`
remote_url=`git config remote.origin.url`

git clone --single-branch  --branch=gh-pages ${remote_url} ${temp_work_dir}
rm -f ${temp_work_dir}/${index_page} ${temp_work_dir}/CNAME
for i in `find ${temp_work_dir} -maxdepth 1 -name "????-??-??-*" -exec basename {} \; |sort -r | head -n ${count}`; do
        if [ -d "${temp_work_dir}/$i" ];then
                cp -r "${temp_work_dir}/$i" "${directory}"
                echo "<li><a href=$i>$i</a></li>" >> ${index_page}
        fi
done
rm -rf ${temp_work_dir}

echo "</ul>" >> ${index_page}
echo "</body>" >> ${index_page}
echo "</html>" >> ${index_page}
mv ${index_page} ${directory}
echo ${name}.mate-desktop.dev > ${directory}/CNAME
