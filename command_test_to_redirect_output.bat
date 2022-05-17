REM use pipe to redirect output of previous command
@echo off

echo %time%

REM echo %time% | (@set /p "var=" & (cmd /v:on /c echo !var!)) >>test.txt
REM 	`set /p "var="`: can't use `echo`, for `echo` won't use stdin.
REM		`cmd /v:on`: to EnableDelayedExpansion. can't use `SETLOCAL EnableDelayedExpansion`, for parentheses.
REM			"When DelayedExpansion is used inside a code block (one or several commands grouped between parentheses) whose output is Piped, the variable expansion will be skipped"
REM		see: [EnableDelayedExpansion - Windows CMD - SS64.com](https://ss64.com/nt/delayedexpansion.html), 
REM					[batch file - Why does delayed expansion fail when inside a piped block of code? - Stack Overflow](https://stackoverflow.com/questions/8192318/why-does-delayed-expansion-fail-when-inside-a-piped-block-of-code)
REM		busy (`cmd`?), and can capture only one line

REM echo %time% | (@set /p "var=" & set var) >>test.txt
REM		result contain `var=` prefix

REM echo %time% >>test.txt
REM		OK

REM echo %time% >nul >>test.txt
REM 	output file get value. wiil change redirect set ealier `>nul`.

REM >>test.txt echo %time% >nul
REM		won't output to file, neither to 'stdout', but to 'nul', as expected.

REM >>&1 echo %time%
REM 	'重定向句柄 1 时，无法复制此句柄。'
REM 3>&1 1>>&3 echo %time%
REM		release then re-assign
set output="&1" REM or "nul"
3>>%output% 1>>&3 echo %time%
REM		necessary to use `>>`, even on `3`.
REM		success

REM	test
REM @ping 192.0.2.2 -n 1 -w 10000 > nul
REM @pause