## 概述

尝试使用Lua的`io.popen(..,'w')`构造后台常驻的批处理(Batch)宿主，减小每次命令都调用`io.popen-close`的开销。

可用，但Lua下存在[结束流信号EOF](#CMD-BAT-概要.md)的问题，且需求环境下，有更好的方式，故放弃，仅存档。

## 文件

### Bat

构造的Bat-"loop_execute_input_command_until_exit.bat"：

- 输入的*第一行*为后续命令的输出重定向目标。
- *后续*行为命令，可动态接受命令输入，执行。
- 使用`exit`命令退出。

在CMD下测试：

```bat
..>loop_execute_input_command_until_exit.bat
>(re)start, waiting input:
&1
echo hello world
^Z
>output to: &1.
>command to execute: "echo hello world".
hello world
>input finish.
>(re)start, waiting input:
exit
^Z
```

可用文件形式`loop_execute_input_command_until_exit.bat < test_input.txt`。
另见：test.lua \\ test bat exectue command from input file。

### Lua

构造的Lua-"CommandPipe.lua"：

1. `commandPipe=CommandPipe(output)`
   output:

   - `nil`: `stdout`，
   - `false`: wont output (`nul`)，

   - `filename`: 初始重定向目标，命令中可以覆盖。

2. `commandPipe:write'command'`（Call）、`commandPipe..'command'`（Concat）、`commandPipe['command']`（Index）。

3. `commandPipe()`close。

### Test

test.lua。含：命令行、Lua `CommandPipe`、耗时测试。output：

```bat
test bat exectue command from input file:
start
>(re)start, waiting input:
>output to: test_output.txt.
>command to execute: "echo hello world, wait".
>command to execute: "ping 192.0.2.2 -n 1 -w 1000 > nul".
>command to execute: "echo goodbye".
done. result OK

test "CommandPipe":
try to un-comment `REM` and `::` in .bat to see process.
finish input
>(re)start, waiting input:
>output to: test_output.txt.
>command to execute: "echo hello".
>command to execute: "echo world, waiting".
>command to execute: "ping 192.0.2.2 -n 1 -w 5000 > nul".
>command to execute: "echo goodbye".
finish process
result OK

test time cost:
when repeat 5 times.
basic popen cost: 	0.13012146949768
traditional method: 	0.15064239501953
>(re)start, waiting input:
>output to: nul.
>command to execute: "echo 1 >>test_output.txt".
>command to execute: "echo 2 >>test_output.txt".
>command to execute: "echo 3 >>test_output.txt".
>command to execute: "echo 4 >>test_output.txt".
>command to execute: "echo 5 >>test_output.txt".
command pipe method: 	0.14091825485229
test done

all finish
```



## 其他

<a name="CMD-BAT-概要.md"></a>[CMD BAT 概要.md](.\CMD BAT 概要.md)是知识笔记