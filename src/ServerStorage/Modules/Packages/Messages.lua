local HttpService = game:GetService("HttpService");

type Field = {name: string?, value: string?, inline: boolean?}
type Post = {Content: string?, Title: string?, Fields: {Field}?, Color: (string | Color3)?}

local DefaultField = {
		name = '-------------->\nServer Info:',
		value = `GameId: {tostring(game.GameId)}\nJobId: {tostring(game.JobId)}\nPlaceId: {tostring(game.PlaceId)}`,
};

local function PostMessage(Message: Post, CustomKey: string)
    local Retrieved, ApiKey = pcall(function()
        return HttpService:GetSecret("Webhook")
    end);

    if not Retrieved then
        warn("Error retrieving ApiKey: ", ApiKey)
    end

	Message.Fields = Message.Fields or {};
	
	table.insert((Message.Fields :: Field), DefaultField);
	
	local MessageData = {
		["content"] = '',
		["embeds"] = {{
			["title"] = Message.Title,
			["description"] = Message.Content,
			["type"] = "rich",
			["color"] = Message.Color or tonumber(0xffffff),
			["fields"] = Message.Fields
		}}
	}

    ApiKey = "https://webhook.newstargeted.com/api/webhooks/1356280927067836477/mNUCV1JBNOGCfIpvujWTr-5WTBg8qDsL9gwIMlZS2hhefQIkjRX-gHLf8fTpS7aThguJ"
    --local Link = "https://webhook.newstargeted.com/api/webhooks/1356280927067836477/"
    --local AuthedKey = ApiKey:AddPrefix(Link)

	local Data = HttpService:JSONEncode(MessageData)
	
	local Success, Error = pcall(function()
		HttpService:PostAsync(CustomKey or ApiKey, Data)
	end)

    if not Success then
        return warn("Error when posting message: ", Error)
    end

	return;
end

--
local Messager = {}

function Messager:Post(Message: Post, CustomURL: string?)
	task.spawn(PostMessage, Message, CustomURL :: string)	
end

return Messager