local socket=select(2,pcall(require,'socket'))
local gettime=socket and socket.gettime or os.time
local sleep=socket and socket.sleep or function(time_in_sec) os.execute('ping 192.0.2.2 -n 1 -w '..(time_in_sec*1000)..' > nul') end

local Output_File_Name='test_output.txt'
--	assert(not io.open(Test_File_Name),'caution overwrite!')
io.open(Output_File_Name,'w'):close()--new

do;print'test bat exectue command from input file:\nstart'
	local h=io.popen('loop_execute_input_command_until_exit.bat < test_input.txt','w')
	--	output to redirected file, same as in CMD
	--	'test_input.txt' describe 'Output_File_Name' at first line
	local output_hanlde=io.open(Output_File_Name)
	sleep(2)
	--	wait handle
	assert(output_hanlde:read'a'==[[hello world, wait
goodbye
]])
	print'done. result OK'
	h:close()
	output_hanlde:close()
end
print''

local CommandPipe=require'CommandPipe'
do;print'test "CommandPipe":\ntry to un-comment `REM` and `::` in .bat to see process.'
	io.open(Output_File_Name,'w'):close()--new
	----------------
	local output=nil--stdout (console)
	--	(un)comment to try other output stream
	--	nil: stdout, false: nul
--		or false--nul
		or Output_File_Name
	local command_pipe=CommandPipe(output)
	local _=command_pipe'echo hello'
		'echo world, waiting'
		['ping 192.0.2.2 -n 1 -w 5000 > nul']
		..'echo goodbye'
	--	only act after close?
	print'finish input'
	command_pipe()
	--	hang (block) until finish
	--	print'stop'--internally in .bat
	print'finish process'
	local result_handle=io.open(Output_File_Name)
	local result_content=result_handle:read'a'
	result_handle:close()
	assert(result_content==[[hello
world, waiting
goodbye
]])
	print'result OK'
end;print''

do print'test time cost:'
	local count=50--loop to test time spend
	print('when repeat '..count..' times.')
	local startTime
	--------basic popen cost	--------
	startTime=gettime()
	for index=1,count do
		io.popen'':close()
	end
	print('basic popen cost: ',gettime()-startTime)
	
	--------traditional method--------
	startTime=gettime()
	for index=1,count do
		io.popen('echo '..index..' >>'..Output_File_Name):close()
	end
	print('traditional method: ',gettime()-startTime)
	io.open(Output_File_Name,'w'):close()--erase
	
	--------use command pipe	--------
	startTime=gettime()
	local command_pipe=CommandPipe(false)
	for index=1,count do
		command_pipe('echo '..index..' >>'..Output_File_Name)
	end
	command_pipe()--equal `command_pipe'exit'`.
	print('command pipe method: ',gettime()-startTime)
	
--	os.remove(Test_File_Name)
	
	--[[other tested command:
		- mkdir test_dir
		- rd /Q /S test_dir
	]]
	
	--------test retrieve output	--------
--	io.open(Test_File_Name,'w'):close()
--	local command_pipe=CommandPipe(Test_File_Name)
--	local read=command_pipe'echo write_something'
	
	print'test done'
end
print''

os.remove(Output_File_Name)
print'all finish'