hook.Add("ChatText", "HideJoinLeaveRU", function(index, name, text, msgType)
    return true
end)