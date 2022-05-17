### 管道Pipe

`A | B`，同时（异步）开始A、B，设置B的输入流(0)为A的输出流(1)。
~~在A执行*结束*/*返回*/*退出*后，A的*输出*传递作为B的*输入*，执行B。"在A结束后"，而非*实时*。~~

- 关于**顺序**的测试：

    ```bat
    >(ping 192.168.0.0 >nul & echo 1 >>&2)  | echo 2 >>&2
    2	;回车以上命令后立即输出
    1	;等待ping命令超时后，得到此输出
    ```
- `A|B`中，`A`、`B`为新环境，其中`A`*独立*，`B`*继承*上文，即：

    ```bat
    >set var=a
    var=a
    >set var >&2 | echo >nul
    环境变量 var   没有定义			;独立新环境
    >echo %var% >&2 | echo >nul	;在解析时，展开为'echo a >&2 | echo >nul'
    a
    >echo >nul | set var
    var=a	;继承上文环境
    >echo >nul | set var >&2	;同上
    var=a
    >echo >nul | (set var)		;同上
    var=a
    >echo >nul | (<&3 set var)	;在管道中，在括号内设置输入输出流改变环境，且不继承
    环境变量 var   没有定义
    >(<&3 set var)			;在非管道中，括号无影响
    var=a
    >
    >echo >nul | set var=b	;设置了新环境中的var
    >set var
    var=a	;以上'set var=b'不影响上文环境
    >		;或者
    >echo >nul | (set var=b & set var)
    var=b	;设置了新环境中的var
    >set var
    var=a	;不影响上文环境
    >		;或者
    >echo c | (set /P var= & set var)
    var=c	;设置新环境中的var
    >set var
    var=a	;不影响上文环境
    ```
- 或者，单行：

    ```bat
    >set var=a & set var & set var >&2 | echo b | (set /p var= & set var) >&2 & set var >&2
    var=a
    环境变量 var   没有定义
    var=b
    var=a
    ```
    
    在管道中使用了2号流，为保持按顺序输出，后续流也改为2#。
    其中`(set /p var= & set var) >&2`，`>&2`得在括号外。

### 重定向Redirect

`A > B`、`C < D`，是执行前的*赋值*操作，传递关于输入、输出[流](#流)之环境（广义的参数）。

- "执行前的赋值"：类似于（狭义的）传递参数，不过位置宽松，形式不同于`Command Arg Arg2 ..`。

- "环境"：类似upvalue。

- "输入、输出"：默认是[stdin](#stdin)、[stdout](#stdout)、[stderr](#stderr)，传递的是*变量名*/*地址*，而非*值*。

- 赋值**顺序**：

  从前往后，后面的会覆盖前面的。

  可以在前面放置*默认值*，不影响后半部分覆盖。

  如`3>>%default% 1>>&3`，设置流1默认为default。

  - `3`作为*中间*/*临时*/*中转*流，初始为空。
  - 不可直接`1>>%default%`，否则，若`default==&1`，则相当于`1>&1`，会报错"重定向句柄 1 时，无法复制此句柄。"

### 流Stream

- 来自设备、（广义）文件的数据流。描述：

  - <a name="con">`con`</a>(console)，默认输入([stdin](#stdin))。

  - `nul`，空输出（如同不显示输出）。

  - `&<number>`其他编号的流。

  - `<filename>`文件。


- 系统默认，使用流**编号**：

  - 1=<a name="stdout">stdout</a>

  - 0=<a name="stdin">stdin</a>

  - 2=<a name="stderr">stderr</a>


#### 命令使用流

如`findstr`（、`find`）等**命令**会等待*静态*值参数满足后**执行**。
"等待*静态*值"：即，不可一边输入，一边处理。具体如：

- 当使用*管道*时，不存在问题，立即执行。
- 当使用*重定向*时，
   - 如果输入流是（狭义的）文件，不存在问题，立即执行；
   - 如果是输入设备（如[`con`](#con)(console)终端），则等待输入完毕时，才会执行。
     涉及[结束输入流](#结束输入流)的问题。
     - "等待输入完毕"：相当于Lua中的`input:read'a'`，会*阻塞*。

#### 结束输入流

- 命令行(CMD)终端设备下，

  - 按键Ctrl+Z，生成[EOF]（[End of File](https://de.wikipedia.org/wiki/End_of_File)） [SUB]，ASCII '\026'。作为内容，显示为`^Z`。

  - 按键Ctrl+D，生成[EOT]（[End of Transmission](http://en.wikipedia.org/wiki/End-of-transmission_character)），ASCII '\004'。作为内容，显示为`^D`。

    示例。在CMD中，

    - 对`findstr`命令：

        ```bat
        >findstr "b"
        abc	;输入
        ^d	;输入Ctrl-D
        abc ;输出，找到的结果
        ^z	;输入Ctrl-Z，退出
        >findstr "b"
        ac	;输入
        ^d	;输入Ctrl-D（未找到，其后无输出）
        ^z	;输入Ctrl-Z，退出
        >_
        ```

    - 对[`set /p var=`](#set命令)命令，`Ctrl-D`、`Ctrl-Z`都可以结束。  


- 在Lua中，正文中的控制字符无特殊意义。
	即，`'\004\026\0'`不产生控制作用。


  参见：
  - [command line - How to signal the end of stdin input - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/16333/how-to-signal-the-end-of-stdin-input)
  - [windows - terminating input in cmd - Stack Overflow](https://stackoverflow.com/questions/22619519/terminating-input-in-cmd)
  - [command line - How to signal the end of stdin input - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/16333/how-to-signal-the-end-of-stdin-input)
  - [c - EOF in the middle of an input - Stack Overflow](https://stackoverflow.com/questions/28223254/eof-in-the-middle-of-an-input)
  - [How would you represent EOF in bash? - Stack Overflow](https://stackoverflow.com/questions/463913/how-would-you-represent-eof-in-bash)

### 命令

#### `echo`命令

不使用输入[流](#流)。
如`echo 12 | echo`会显示"ECHO 处于打开状态。"，如同单独的`echo`命令（管道无作用）。

建议使用`echo(`+正文内容（`(`后无空格）形式。

#### `set`命令

`set /p var=`，接受的输入流仅可以是*单行*。

建议使用`set /p "var="`，带双引号。

#### `call`命令

形式`call :<label> arg`（之一）。
`arg`可以`"%var%"`，使用双引号（类似[set](#set)），再在子命令内使用`%~1`解析掉双引号。

[call | Microsoft Docs](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/call)

#### 其他

- [If - Conditionally perform command - Windows CMD - SS64.com](https://ss64.com/nt/if.html)
  [if | Microsoft Docs](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/if)
- [For - Loop through command output - Windows CMD - SS64.com](https://ss64.com/nt/for_cmd.html)
- [Findstr - Search for strings - Windows CMD - SS64.com](https://ss64.com/nt/findstr.html)

### Delayed Expansion

- *运行时*执行变量解析，而非加载代码块时。

- 使用`!`作为变量名分隔符/标记，解析变量。
  如`!var!`。区分于`%var%`。

- 需要在环境中开启。

  - 使用`com /v:on`（`/v:off`）
  - batch内`setlocal DisableDelayedExpansion`、`setlocal EnableDelayedExpansion`，搭配`endlocal`。

- 有作用范围（`()`parentheses）问题。


​	参考：

- [EnableDelayedExpansion - Windows CMD - SS64.com](https://ss64.com/nt/delayedexpansion.html)
- [batch file - Why does delayed expansion fail when inside a piped block of code? - Stack Overflow](https://stackoverflow.com/questions/8192318/why-does-delayed-expansion-fail-when-inside-a-piped-block-of-code)

### 其他

CMD BAT 概要[windows - Command to run a .bat file - Stack Overflow](https://stackoverflow.com/questions/41030190/command-to-run-a-bat-file/41049135#41049135)

检索关键词index：cmd command batch, findstr find, stdin input, redirect pipe, read write dynamic realtime, flush refresh buffer, block wait hang, control character signal, Ctrl-D ^D, Ctrl-Z ^Z

纪念下过程，目的向导，七零八碎的拼凑起来，测试完善，但仍不够系统..
![image-20220517012408479](CMD BAT 概要.assets/image-20220517012408479.png)![image-20220517012430946](CMD BAT 概要.assets/image-20220517012430946.png)