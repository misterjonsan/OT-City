-----------------------------
/// AUTO COMPLETE HELPERS ///
-----------------------------
--suggestions must return as {}
--offset is the number by which the command will be shifted. (Useful if you are replacing some character with your sentence.
--example: return {{text="hello" , offset = 0, type = "anything here"}, {text="hello2" , offset = 0, type = "anything here"}}

echat.auto_complete = echat.auto_complete or {}

function echat:AddAutoComplete(uid, func)
	if echat.config.autocompleters[uid] ~= false then --nil == true. except only false
		echat.auto_complete[uid] = func
	end
end

--example: echat:AddCommandHelper("/ooc") --single command
function echat:AddCommandHelper(command_text)
	local fn = function(text)
		if string.find(text, "/", 1, true) ~= 1 then return nil end
    	if (string.find(command_text, text, 1, true) ~= nil) && not string.find(text, command_text, 1, true) then
			return {{text=command_text}}
		end
		return nil
	end
	self:AddAutoComplete(command_text,fn)
end