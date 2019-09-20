#! /bin/bash
#
# Program
#       该脚本用于自动运行单元测试，并且生成 HTML 报告
#
#

# 获取根目录
CURRENT_DIR=$1;
TARGET_TEST=$2;
if [ ${#TARGET_TEST} == 0 ]
    then
        TARGET_TEST="Tests";
    else
        TARGET_TEST=$2;
fi;

if [ -d "$CURRENT_DIR" ];
    then
    # 如果文件存在，则进行字符串分割
    declare CURRENT_LAST_FILELEN=`echo "$CURRENT_DIR" | awk -F ''\/'' '{printf "%d",length($NF)}'`
    declare CURRENT_POS=$[ ${#CURRENT_DIR} - $CURRENT_LAST_FILELEN  ];
    # 获取文件名称
    declare ProjName=${CURRENT_DIR:$CURRENT_POS:$CURRENT_LAST_FILELEN};
    CURRENT_PATH=${CURRENT_DIR:0:$CURRENT_POS};
#        echo $CURRENT_PATH;

    #CURRENT_PATH=${CURRENT_PATH//\/shells/""};

    # shell脚本执行环境
    SHEEL_CURRENT_PATH=$(cd `dirname $0`; pwd);
    SHELL_PATH="$SHEEL_CURRENT_PATH";

    # 最终生成报告的目录
    ROOT_DIR="${CURRENT_PATH}test-reports";

    # 单元测试报告目录文件目标地址
    LOG_DESTINATION_DIR="${ROOT_DIR}/reports.js"

    # 需要测试的工作空间 xcworkspace
    WORKSPACE_DIR=$CURRENT_DIR

    # 工作空间模式，project OR workspace
    WORKSPACE_TYPE="workspace";
    if [[ $ProjName =~ xcworkspace ]]
    then
        WORKSPACE_TYPE="workspace";
    else
        WORKSPACE_TYPE="project";
    fi

    # 代码覆盖率文件名称
    TestCoverageFileName="coverage.js"

    # 代码测试结果文件夹名称，系统参数，切勿修改
    UnitTestFileName="sys-reports"

    # 测试环境
    EnvTestToSimulator="platform=iOS Simulator,name=iPhone 6s"

    # 删除旧报告文件内容
    if [ -d "$ROOT_DIR" ];
        then
         rm -rf "$ROOT_DIR"
    fi

    # 创建目录文件
    mkdir "$ROOT_DIR"
    echo "报告目录创建成功"

    ##### --------xc2json.sh---- BEGIN 利用系统命令生成报告 ----------------- #######



    # 生成单元测试报告,并且将日志文件吸入 reports.log 文件
    echo `xcodebuild -enableCodeCoverage YES test -$WORKSPACE_TYPE "$WORKSPACE_DIR" -scheme $TARGET_TEST -destination "$EnvTestToSimulator" -resultBundlePath "$ROOT_DIR/$UnitTestFileName"` > "$ROOT_DIR/reports.log";

    ##### ------------ END 利用系统命令生成报告 ----------------- #######

    ##### ------------ BEGIN 解析报告 ----------------- #######

    # 解析报告，获取代码覆盖率路径
    CoveragePath="$ROOT_DIR/$UnitTestFileName/1_Test/action.xccovreport";
    LogsPath="$ROOT_DIR/$UnitTestFileName/1_Test/Diagnostics";
    for dir in $(ls "$LogsPath")
    do
        inclueString=$(echo $dir | grep "${Tests-}")
        if  [[ "$inclueString" != "" ]]
        then
            LogsPath="$LogsPath/$dir";


    ##### ------------ BEGIN 解析里层目录 ----------------- #######

            for dir in $(ls "$LogsPath")
            do
                inclueString=$(echo $dir | grep "Tests-")
                if  [[ "$inclueString" != "" ]]
                then
                    LogsPath="$LogsPath/$dir/StandardOutputAndStandardError.txt";
                    break;
                fi
            done;

    ##### ------------ BEGIN 解析里层目录 ----------------- #######


            break;
        fi
    done;

    # 获取到单元测试日志文件
    #echo $LogsPath;
    #cat $LogsPath;

    # 生成覆盖率文件 json 格式
    echo "var unitCoverageReports=$(xcrun xccov view "$CoveragePath" --json)" > "$ROOT_DIR/$TestCoverageFileName"


    # 生成单元测试文件 json 格式
    # 为防止路径中存在空格键进行base64编码
    source "$SHELL_PATH/xc2json.sh" "$LogsPath" "$LOG_DESTINATION_DIR"

    # 移动html主目录至目标目录
    cp "$SHELL_PATH/index.html" "$ROOT_DIR/index.html"



    # 删除系统报告目录
    rm -rf "$ROOT_DIR/$UnitTestFileName"



    #### ------------ END 解析报告 ----------------- #######

else
    echo "$1 is not exist!";
fi