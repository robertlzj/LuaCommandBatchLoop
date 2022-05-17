@echo off
REM	loop_execute_input_command_until_exit_command.bat
REM		assemble by RobertL
REM		use 'exit' (then ^Z, see bellow) command to stop.
REM		could use with Lua `io.popen('this.bat','w'):write'command':write'..'..`.
REM 	mainly from [windows - Read stdin stream in a batch file - Stack Overflow](https://stackoverflow.com/questions/6979747/read-stdin-stream-in-a-batch-file/6980605#6980605)

REM REM	can't use `set /q var=` here, will block
REM block because of input stream not end
setlocal DisableDelayedExpansion
set filename_to_receive_output=
REM		necessary, otherwise var inherited from environment

:start
REM 	repeat until 'exit' command
echo ^>(re)start, waiting input:
for /F "tokens=*" %%a in ('findstr /n "^"') do (
	REM 	wait (block) until input stream finish - EOF
	REM			when using CMD, Ctrl-Z will mark '^Z' [SUB] (EOF) signal
  set "line=%%a"
	setlocal EnableDelayedExpansion
  set "line=!line:*:=!"
	REM		remove '<number>:' in var 'line' in place
  if "!line!"=="exit" goto stop
	REM echo(^>command parsed: "!line!".
	if [!filename_to_receive_output!]==[] (
		REM can't use `if not defined..`.
		set filename_to_receive_output=!line!
		setlocal EnableDelayedExpansion
		REM		necessary here after assignment
		@echo ^>output to: !filename_to_receive_output!.
	) else (
		REM space `else (` necessary
		REM echo execute
		REM 	can't use :: inside parentheses!
		call :exec_command "!line!"
		REM		must use quotation then use "%~1" to remove surrounding quotation
		REM		[call | Microsoft Docs](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/call)
		REM		will expand any exclamation (!) even escaped
		REM		see [EnableDelayedExpansion - Windows CMD - SS64.com](https://ss64.com/nt/delayedexpansion.html)
	)
	endlocal
	REM can't use call or break, will broke handing input pipe
)
echo ^>input finish.
REM		echo when in interactive under CMD
REM		end of line
goto start
exit /b

:exec_command
	echo(^>command to execute: "%~1".
	3>>!filename_to_receive_output! 1>>&3 %~1
	exit /b

:exec_command_deprecate
	::setlocal EnableDelayedExpansion
	::echo(command received in sub: "%~1".
	if [!filename_to_receive_output!]==[] (
		::echo with default output
		%~1
	) else (
		::echo with specified output
		>>filename_to_receive_output %~1
		
		REM	%~1 | (@set /p "var=" && (cmd /v:on /c echo !var!)) 1>>!filename_to_receive_output! 2>&1
		REM 	deprecate, busy
	)
	REM	use `&&` as `if true then`
	::endlocal
	exit /b

:stop
	echo exit >nul