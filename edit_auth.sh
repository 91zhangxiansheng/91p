#!/bin/bash

index=0
countadd=$time

git filter-branch --env-filter '
timeStamp=`date +%s`
# 加3年半
let futureTime=$timeStamp+110000000
# 减4个月
let startTime=$timeStamp-10000000   
# 平均值
let avg=(futureTime-startTime)/1000
# 增加波动值
let time=$startTime+$avg+$RANDOM
let index=$index+1
let countadd=$countadd+$avg+$RANDOM
let c=$countadd+$startTime

OLD_EMAIL="Anamu0136405119@163.com"
CORRECT_NAME="91zhangxiansheng"
CORRECT_EMAIL="zhangmujhv@163.com"

if [ $GIT_COMMIT != 119f9ecf58069b265ab22f1f97d2b648faf932e0 ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
    export GIT_AUTHOR_DATE="$c"
    export GIT_COMMITTER_DATE="$c"
fi

' --tag-name-filter cat -- --branches --tags

