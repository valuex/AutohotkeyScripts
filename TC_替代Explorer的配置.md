# 配置autohotkey 脚本
1. 用`AHK2EXE`编译`OpenTCSelected.ahk`为`OpenTCSelected.exe` （可自行编译，或下载编译好的版本 https://github.com/valuex/AutohotkeyScripts/releases/tag/V0.1  ）
2. 将`OpenTCSelected.exe` 放入`TotalCMD64.exe` 或 `TotalCMD.exe`所在目录

# 配置注册表
1. 修改注册表 `计算机\HKEY_CLASSES_ROOT\Folder\shell\open\command`
- `默认`位置处修改为`D:\SoftX\TotalCommander11\OpenTCSelected.exe "%1"`
- `DelegateExecute`修改为 空

2. 注册表还原  `计算机\HKEY_CLASSES_ROOT\Folder\shell\open\command`
- `默认`位置处修改为 `%SystemRoot%\Explorer.exe`
- `DelegateExecute`修改为 `{11dbb47c-a525-400b-9e80-a54615a090c0}`

# 配置TotalCommander
在`usercmd.ini`中加入如下配置
```ini
[em_savealltabs]
button=wcmicons.dll,10
cmd=SAVETABS2
param="%|commander_path|\User\SAVETABS2.tab"
[em_focusfile]
button=wcmicons.dll,10
cmd=CD
param="D:\SoftX\TotalCommander11\TCMatch.ini"

```
