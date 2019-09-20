## 自动化单元测试脚本


##### 该脚本应用于任何iOS工程基于XCTest编写的单元测试代码，主要目的用于自动化运行脚本，并且自动生成报告内容。


### 脚本运行

在运行之前，需要确认对应项目是否存在"XCTest"项目的Target，并且该Target是否添加进 scheme 中，可以通过 "edit scheme->manage scheme-> 查看测试的Target 是否存在"

``` 

   // 命令
   // ./run.sh [包含XCTest项目的根目录，传入xcworkespace或者xcodeproj] [传入脚本的Target，默认为Tests]
   // 例如：

   ./run.sh  /[YOUR_PATH]/[YOUR PROJECT NAME].xcworkspace Tests 
```

### 文件说明

index.html 为最终的html报告模版，由于作者的H5水平有限，所以比较丑，使用者可以自行修改Html的报告样式

### 数据格式

报告生成后伴随两份js文件

unitCoverageReports // 代码覆盖率JSON数组

unitTestReports // 测试报告数组

