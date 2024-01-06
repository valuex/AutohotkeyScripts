# 利用Everything 1.5 进行代码管理
![image](https://github.com/valuex/AutohotkeyScripts/assets/3627812/d19c3712-1600-433a-a524-e3203722723a)

## 背景
代码片段管理软件/服务有很多，包括 cheerysnippet， masscode，gist等。  
个人体验下来，cheerysnippet 比较重，后端需要配置一个cheery note。  
masscode 和 visual studio code 配合较好，用其他编辑器时需要来回切换，就比较影响工作流了。  
gist 网页分类功能比较差。  
所以个人也在找一些更普世的代码片段管理方案。  
最近试用了Everything 1.5，里面升级的几个功能就非常适合用于代码片段管理了。
## 实现
1. 将Everything 1.5 以下的几大功能组合起来，就能很快的定位到特定代码片段文件
 自定义过滤（Filter） ，标题检索，内容检索（content search)，内容预览(preview)
2. 配合下面的Autohotkey 脚本，能够通过快捷键实现代码片段文件内容快速粘贴到正在工作的编辑器中
具体实现过程：
- AHK 脚本链接： https://github.com/valuex/AutohotkeyScripts/blob/main/Everything_PasteTo.ahk
- 将该脚本用ahk2exe转化为exe文件，放到某个目录下
- 在Everything 中定义Custom Open Commands https://www.voidtools.com/forum/viewtopic.php?t=13720
` $exec("Your_Path_Here\PasteTo.exe" "%1")  `
![image](https://github.com/valuex/AutohotkeyScripts/assets/3627812/2642d9e2-09f8-4800-859e-bd107c60e04c)

- 在Everything 中给上述命令配置一个快捷键
  ![image](https://github.com/valuex/AutohotkeyScripts/assets/3627812/7d811ed5-e321-4fb0-b1c7-db52e5256950)

- 当然，会使用AHK的，也可以把下面的脚本改一下，直接利用`#HotIf`定义一个只作用于Everything 的快捷键。
