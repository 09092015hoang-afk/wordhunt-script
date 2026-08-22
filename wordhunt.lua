local Rayfield = loadstring(game:HttpGet('https://[Log in to view URL]'))()

local Window = Rayfield:CreateWindow({
    Name = "Soupy Hub",
    LoadingTitle = "Soupy Hub Loading",
    LoadingSubtitle = "by @FoxyYT098",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = Soupy Hub Folder1, -- Create a custom folder for your hub/game
       FileName = "sui haun hub"
    },
    Discord = {
       Enabled = true,
       Invite = "Ez5xfGh2cs", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
       RememberJoins = true -- Set this to false to make them join the discord every time they load it up
    },
    KeySystem = true, -- Set this to true to use our key system
    KeySettings = {
       Title = "Soupy Hub Key",
       Subtitle = "Paste the key here ⬇",
       Note = "Go to https://[Log in to view URL] ",
       FileName = "Key11232323", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
       SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
       GrabKeyFromSite = true, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
       Key = {"FoxyYTtm123","https://[Log in to view URL]"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
 })

 local MainTab = Window:CreateTab("Main Thingys", nil) -- Title, Image
 local MainSection = MainTab:CreateSection("Player")

 Rayfield:Notify({
    Title = "Welcome To Soupy Hub",
    Content = "Beta test is now on!",
    Duration = 6.5,
    Image = nil,
    Actions = { -- Notification Buttons
       Ignore = {
          Name = "Okay!",
          Callback = function()
          print("The user tapped Okay!")
       end
    },
 },
 })


 local Button = MainTab:CreateButton({
   Name = "Infinite Jump",
   Callback = function()
           --Toggles the infinite jump between on or off on every script run
_G.infinjump = not _G.infinjump

if _G.infinJumpStarted == nil then
	--Ensures this only runs once to save resources
	_G.infinJumpStarted = true
	
	--Notifies readiness
	game.StarterGui:SetCore("SendNotification", {Title="Youtube Hub"; Text="Infinite Jump Activated!"; Duration=5;})

	--The actual infinite jump
	local plr = game:GetService('Players').LocalPlayer
	local m = plr:GetMouse()
	m.KeyDown:connect(function(k)
		if _G.infinjump then
			if k:byte() == 32 then
			humanoid = game:GetService'Players'.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
			humanoid:ChangeState('Jumping')
			wait()
			humanoid:ChangeState('Seated')
			end
		end
	end)
end
   end,
})

   end,
})


 local Input = MainTab:CreateInput({
   Name = "Speed 🏃‍♂️",
   PlaceholderText = "Put Speed Value Here",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
   game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = (Text)
   end,
})