#! /bin/bash
#
# Program
#       该脚本用于将单元测试报告解析为 JSON 格式对象
#
#

# 获取当前指定的报告的路径
localReportsPath=$1;
localReportsDestination=$2;

# 声明一个临时字典，判断suite是否存在
tmpMap=();

# 声明序列数组
tmpPushArr=(); # 用于存储生成的类
tmpPushSubArr=(); # 用于存储子类集
tmpArrIsAction=(); # 用于存储当前的数组的操作状态

tmpCaseArr=() # 用于存储case的类
_tmpCaseSed=-1;

# 声明CASE-JSON模版,
# name 名称，result 测试是否成功 YES OR NO，type 类型为 suite OR case OR exected，message 错误信息字符, subs 如果为 suite 类型则存在该属性
jsonTemplate="{\"name\":\"{name}\",\"result\":\"{result}\",\"type\":\"{type}\",\"message\":\"{message}\",\"sec\":\"{sec}\",\"subs\":{subs}}";
jsonTmp="";

# 根据数组参数解析字符串
parseJSONArryToJSONStr() {
    # 替换数据
    jsonTmp="${jsonTemplate}";
    local frombase64Name=$(echo "${1}" | base64 -D )
    jsonTmp=${jsonTmp//\{name\}/$frombase64Name}
    jsonTmp=${jsonTmp//\{result\}/$2}
    jsonTmp=${jsonTmp//\{type\}/$3}
    if [[ ($4 == "\"\"") || $4 == "''" ]]
        then
        jsonTmp=${jsonTmp//\{message\}/""}
    else
        local frombase64Message=$(echo "${4}" | base64 -D )
        frombase64Message=`echo "${frombase64Message}" |sed s/[[:space:]]//g`
        frombase64Message=${frombase64Message//\"/\'};
        jsonTmp=${jsonTmp//\{message\}/$frombase64Message}
    fi

    jsonTmp=${jsonTmp//\{sec\}/$5}
    jsonTmp=${jsonTmp//\{subs\}/$6}
}

# 临时数据，用于存储每次解析后的内容
_tmpName="";
_tmpResult="";
_tmpType="";
_tmpMessage="";
_tmpSec="";
_tmpSubs="";
_tmpCType="";

# 当前指针
_tmpSed=-1;
_tmpElGoEnd="";

_lastResultJsonArr="";

# 判断是否存在
ifcontainedInTmpPushArr() {
    local name=$1;
    local base64To=$(echo "${name}" | base64);
    for i in $(seq 0 ${#tmpPushArr[@]})
        do
        if [[ "${tmpPushArr[$i]}" == "${base64To}" ]]
            then
            return 0;
        fi
    done
    return 1;
}

# 解析每一行Suite结果
convertAndParseReadLine() {
  local line=$1;
  local suiteName="";
  local max=${#line};
  local headerTag="Test Suite ";
#  echo $line;
  # 解析名称
  local readIn="false";
  for i in $(seq ${#headerTag} ${#line})
    do
        local str=${line:$i:1};
        if [[ $str == "'" ]]
            then
            if [[ $readIn == "false" ]]
                then
                 readIn="true";
                 continue;
            else
                readIn="false";
                break;
            fi
        fi
        if [[ $readIn == "true" ]]
            then
            suiteName="$suiteName$str";
        fi
  done;

  _tmpName=$suiteName;

  local replaceLine=${line//$suiteName/"-"};
  array_line=($replaceLine);
  _tmpResult=${array_line[3]};

}

# 临时数据，用于存储每次解析后的内容
_tmpCaseName="";
_tmpCaseResult="";
_tmpCaseType="";
_tmpCaseMessage="";
_tmpCaseSec="";

# 解析每一行Case结果
convertAndParseCaseReadLIne() {

  local line=$1;
  local suiteName="";
  local max=${#line};
  local headerTag="Test Case ";

   # 解析名称
  local readIn="false";
  for i in $(seq ${#headerTag} ${#line})
    do
        local str=${line:$i:1};
        if [[ $str == "'" ]]
            then
            if [[ $readIn == "false" ]]
                then
                 readIn="true";
                 continue;
            else
                readIn="false";
                break;
            fi
        fi
        if [[ $readIn == "true" ]]
            then
            suiteName="$suiteName$str";
        fi
  done;

  array_line=($suiteName);
  _tmpCaseName=${array_line[1]};
  _tmpCaseName=${_tmpCaseName//]/""};

  replaceLine=${line//"$suiteName"/-};
#  echo $replaceLine
  array_line=($replaceLine);
  _tmpCaseResult=${array_line[3]};

   _tmpCaseSec=${array_line[4]};
   _tmpCaseSec=${_tmpCaseSec//(/''};
  }

  completeHandler() {
  echo "finished";
      echo "var unitTestReports=$_lastResultJsonArr" > "$localReportsDestination";
  }

  # 遍历报告中每一行的内容
  cat "$localReportsPath" | while read line
  do
      # 如果读到 Test Suite 开头的字符代表为测试的内容
      if  [[ "${line:0:11}" == "Test Suite " ]]
          then
          convertAndParseReadLine "${line}";
          if ifcontainedInTmpPushArr "${_tmpName}"
              then
              # 再次访问到这个标签代表结束
              lastEl=${tmpPushArr[_tmpSed]};
              _tmpType="suite";
          else
              # 代表第一次访问到这个标签，设置对应的属性
              _tmpSed=`expr $_tmpSed + 1`;
              tmpPushArr[_tmpSed]=$(echo "${_tmpName}" | base64);
              tmpPushSubArr[_tmpSed]="[";
              _tmpCType="suite";
          fi

    # 如果读到 Test Case 开头的字符代表为测试的内容
    elif [[ "${line:0:10}" == "Test Case " ]]
        then

        convertAndParseCaseReadLIne "${line}";
        if ifcontainedInTmpPushArr "${_tmpCaseName}"
        then
            lastEl=${tmpPushArr[_tmpSed]};
            _tmpCaseType="case";

            parseJSONArryToJSONStr $lastEl $_tmpCaseResult $_tmpCaseType "$(echo "${_tmpCaseMessage}" | base64)" $_tmpCaseSec "[]";
#            echo $jsonTmp

            parentSed=`expr $_tmpSed - 1`;
            # 从当前元素追加上去
            subArrParent=${tmpPushSubArr[parentSed]};
            if [[ $subArrParent == "[" ]]
            then
                tmpPushSubArr[parentSed]="[${jsonTmp}]";
            else
                lineNum=${#subArrParent};
                lineNum=`expr $lineNum - 1`;
                subArrParent=${subArrParent:0:$lineNum};
                tmpPushSubArr[parentSed]="${subArrParent},${jsonTmp}]";
            fi

            _tmpSed=`expr $_tmpSed - 1`;

            _tmpCaseMessage="";
        else
            _tmpSed=`expr $_tmpSed + 1`;
            tmpPushArr[_tmpSed]=$(echo "${_tmpCaseName}" | base64);

            _tmpCType="case";
        fi;

    elif [[ "$(echo $line | grep "Executed ")" != "" ]]
        then

        array_line=($line);

        # 代表真正意义上的结束，需要将当前指针-1
        lastEl=${tmpPushArr[_tmpSed]};

        # 添加结果 result
        lastEl="${lastEl} ${_tmpResult}";

        # 添加类型 type
        lastEl="${lastEl} suite";

        # 添加信息 message
        if [[ $_tmpMessage == "" ]]
        then
            lastEl="${lastEl} ''";
        else
            lastEl="${lastEl} $(echo "${_tmpMessage}" | base64)";
        fi


        # 添加信息 sec
        sec=${array_line[10]};
        sec=${sec//(/""};
        sec=${sec//)/""};

        lastEl="${lastEl} ${sec}";

        # 添加信息 subs
        # 获取当前指针的数组
        subArrVal=${tmpPushSubArr[_tmpSed]};
        if [[ "${subArrVal}" == "[" ]]
        then
            subArrVal="[]";
        fi

        lastEl="${lastEl} ${subArrVal}";

        tmpPushArr[_tmpSed]=$lastEl;
        parseJSONArryToJSONStr $lastEl;

        # 获取父节点数组
        parentSed=`expr $_tmpSed - 1`;
        if [[ $parentSed == -1 ]]
        then
            # 覆盖第一个元素
            subArrParent=${tmpPushSubArr[0]};
            tmpPushSubArr[0]="[${jsonTmp}]";
        else
            # 从当前元素追加上去
            subArrParent=${tmpPushSubArr[parentSed]};
            if [[ $subArrParent == "[" ]]
            then
                tmpPushSubArr[parentSed]="[${jsonTmp}]";
            else
                lineNum=${#subArrParent};
                lineNum=`expr $lineNum - 1`;
                subArrParent=${subArrParent:0:$lineNum};
                tmpPushSubArr[parentSed]="${subArrParent},${jsonTmp}]";
            fi
        fi

        _tmpType="";
        _tmpMessage="";
        _tmpResult="";

        _tmpSed=`expr $_tmpSed - 1`;

        _lastResultJsonArr=${tmpPushSubArr[0]};

        if [[ $_tmpSed == -1 ]]
        then
            # 最后一次执行完毕
            completeHandler ;
        fi

    else
        # 搜集message
        if [[ $_tmpSed -gt -1 ]]
            then
            if [[ $_tmpCType == "suite" ]]
            then
                _tmpMessage="${_tmpMessage}$line";
            else
                _tmpCaseMessage="${_tmpCaseMessage}$line";
            fi
        fi
    fi;
done



#echo $_lastResultJsonArr
#echo ${#tmpPushSubArr[@]}


