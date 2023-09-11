F1::
{
tc_exe:="D:\SoftX\TotalCommander11\TotalCMD64.exe"
fpath:="D:\Downloads\yourfile.txt"
if(FileExist(fpath))
    r_cmd:=tc_exe . " /O /T /A /L=" . Chr(34) . fpath . Chr(34)
else
{
    SplitPath fpath,,&OutDir
    if(FileExist(OutDir)) 
        r_cmd:=tc_exe . " /O /T /L=" . Chr(34) . OutDir . Chr(34)
    else
        r_cmd:=tc_exe
}
Run r_cmd
}

