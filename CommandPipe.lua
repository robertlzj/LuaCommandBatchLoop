--LuaCommandPipe

local Command_Pipe_Input_Handle_Label,
	Command_Pipe_Output_Handle_Label,
	Command_Pipe_Output_Filename_Label,
	Command_Pipe_Output_Tmpfile_Label=0,1,-1,-2

local Command_Wrapper_Metatable={}
function Command_Wrapper_Metatable.__gc(self)
	local command_pipe_input_handle=rawget(self,Command_Pipe_Input_Handle_Label)
	if command_pipe_input_handle then
		self'exit'
		command_pipe_input_handle:close()
		rawget(self,Command_Pipe_Input_Handle_Label,nil)
	end
end
function Command_Wrapper_Metatable.__concat(self,b)
	assert(type(self)=='table' and getmetatable(self)==Command_Wrapper_Metatable)
	return self(b)
end
function Command_Wrapper_Metatable.__call(self,command)
	if command==nil then
		return Command_Wrapper_Metatable.__gc(self)
	end
	assert(type(command)=='string')
	local command_pipe_input_handle=rawget(self,Command_Pipe_Input_Handle_Label)
	assert(command_pipe_input_handle,'command pipe already closed')
		:write(command..'\n')
		:write''
		--	'\026': [SUB], ^Z; '\004': [EOT] end-of-Transmission character
		--	--	'\032' ^Z;
		--可以通过如AHK，生成控制字符，如[SUB]、，
		--	但Lua解释器会识别解析，报错'unfinished string near <eof>'
		--	当前作为内容（而非控制字符）被解析 `command parsed: SUB`.
		:flush()
	return self
end
Command_Wrapper_Metatable.__index=Command_Wrapper_Metatable.__call

local function CommandPipe(filename_to_receive_output)
	filename_to_receive_output=filename_to_receive_output==false and "nul" or filename_to_receive_output or '&1'
	--	'': stdout
	local command_pipe_input_handle=io.popen('loop_execute_input_command_until_exit.bat','w')
	--	asynchronous
	command_pipe_input_handle:setvbuf('line')
	local command_wrapper={
		[Command_Pipe_Input_Handle_Label]=command_pipe_input_handle,
	}
	setmetatable(command_wrapper,Command_Wrapper_Metatable)
	command_wrapper(filename_to_receive_output)
	--	first 'command' internal
	return command_wrapper
end

return CommandPipe