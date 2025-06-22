--!native
--!optimize 2

local CollectionService = game:GetService("CollectionService")
local DebrisService = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")

local Nodes = ServerStorage:FindFirstChild("Nodes")
local Assets = script:FindFirstChild("Assets")
local Voicelines = script:FindFirstChild("Voicelines")
local BloodContainer = Workspace:FindFirstChild("BloodContainer")

--local Nodes = ServerStorage:FindFirstChild("Nodes")
local NPCModule = require(ServerScriptService:FindFirstChild("NPCModule"))
local NPFModule = require(ServerScriptService:FindFirstChild("AdvancedPathfinder"))
--[[local RankModule = require(ReplicatedStorage:FindFirstChild("PLAYERSharedModule")).RankSystem
local BloodEvent = ReplicatedStorage:FindFirstChild("Events"):WaitForChild("BloodEvent", 5)
local SpeechModule = require()]]

local PendingJumpHumanoids = {}
local LastDetectionTime = {}

local JumpOffsets = {
	Vector3.new(0, -1.5, 0),
	Vector3.new(0, 1.5, 0),
}

local CollisionPairs = {

	{"NPCNoCollision", "NPCNoCollision", false},
	{"NPCCollisionGroup", "NPCCollisionGroup", true},
	{"NPCNoCollision", "NPCCollisionGroup", false},
	{"NPCRagdoll", "NPCRagdoll", true},
	{"NPCRagdoll", "NPCNoCollision", false},
	{"NPCRagdoll", "NPCCollisionGroup", false},

}

-- [[ Utilitary / External ]]

for _, Group in ipairs({"NPCNoCollision", "NPCCollisionGroup", "NPCRagdoll"}) do
	PhysicsService:RegisterCollisionGroup(Group)
end

for _, Pair in ipairs(CollisionPairs) do
	PhysicsService:CollisionGroupSetCollidable(table.unpack(Pair))
end

local function HandlePathToTarget(Character, targetPosition, Yields, Config)
	return NPFModule.SmartPathfind(Character, targetPosition, Yields, Config)
end

local function HandleEntityStop(Character)
	return NPFModule.Stop(Character)
end

local function IsWeldedToAnchored(Object)
	for _, Weld in ipairs(Object:GetConnectedParts(true)) do
		if Weld.Anchored then
			return true
		end
	end
	return false
end

local function SetNetworkOwnership(Character, ObjectToSet, NetworkObject, NetworkType)
	if NetworkType == "Default" then
		if ObjectToSet then
			if (ObjectToSet:IsA("BasePart") or ObjectToSet:IsA("UnionOperation") or ObjectToSet:IsA("MeshPart")) 
				and ObjectToSet:CanSetNetworkOwnership() 
				and ObjectToSet:GetNetworkOwnershipAuto() 
				and not ObjectToSet.Anchored 
				and not IsWeldedToAnchored(ObjectToSet) then
				ObjectToSet:SetNetworkOwner(NetworkObject)
			end
		end
	elseif NetworkType == "SetFullNetwork" then
		for _, Part in pairs(Character:GetDescendants()) do
			if (Part:IsA("BasePart") or Part:IsA("UnionOperation") or Part:IsA("MeshPart")) 
				and Part:CanSetNetworkOwnership() 
				and Part:GetNetworkOwnershipAuto() 
				and not Part.Anchored 
				and not IsWeldedToAnchored(Part) then
				Part:SetNetworkOwner(NetworkObject)
			end
		end
	end
end

local function SetCollisionGroup(NPC, GroupName)
	for _, Part in ipairs(NPC:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part .CollisionGroup = GroupName
		end
	end
end

local function EnsureFolder(Name, Parent)
	local Folder = Parent:FindFirstChild(Name)
	if not Folder then
		Folder = Instance.new("Folder")
		Folder.Name = Name
		Folder.Parent = Parent
	end
	return Folder
end

-- [[ External Entity Setup ]]


local UnitsFolder = EnsureFolder("Units", Workspace)
local DebrisFolder = EnsureFolder("Debris", Workspace)

local function CreateNPCConnections(Character)

	if Character:FindFirstChild("Exclude") then return end

	-- [[ Server Entity Flags ]]

	local EntityFlagClass = require(script.Parent.EntityFlagDirectory)
	local EntityFlagDirectory = EntityFlagClass.new()
	local NewRandom = Random.new()

	-- Character Parts
	local Humanoid = Character:FindFirstChild("Humanoid")
	local Head = Character:FindFirstChild("Head")
	local RightArm = Character:FindFirstChild("Right Arm")
	local RightLeg = Character:FindFirstChild("Right Leg")
	local LeftArm = Character:FindFirstChild("Left Arm")
	local LeftLeg = Character:FindFirstChild("Left Leg")
	local Torso = Character:FindFirstChild("Torso")
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local Face = Head:FindFirstChild("Face") or Head:FindFirstChild("face")
	local PrimaryPart = Character.PrimaryPart

	-- Unit Values
	local UnitValues = Character:FindFirstChild("UnitValues")
	local UVSettings = UnitValues:FindFirstChild("Settings")
	local UVMiscSettings = UnitValues:FindFirstChild("MiscSettings")

	-- Death Settings
	local DeathSettings = UVSettings:FindFirstChild("DeathSettings")
	local HasDeadFace = DeathSettings:FindFirstChild("HasDeadFace")
	local DeadFace = DeathSettings:FindFirstChild("DeadFace")

	-- Entity States
	local EntityStates = UVSettings:FindFirstChild("EntityStates")
	local FearConfigs = EntityStates:FindFirstChild("FearConfigs")
	local FearChecks = FearConfigs:FindFirstChild("Checks")
	local FearMisc = FearConfigs:FindFirstChild("Misc")
	local FearSettings = FearConfigs:FindFirstChild("Settings")
	local FearProminence = FearSettings:FindFirstChild("MoreProminentToFear")
	local VomitProminence = FearSettings:FindFirstChild("MoreProminentToVomit")
	local DefenseAgainstFear = FearSettings:FindFirstChild("DefenseAgainstFear")
	local DefenseAgainstVomit = FearSettings:FindFirstChild("DefenseAgainstVomit")

	-- AI Type Settings
	local AITypeSettings = UVSettings:FindFirstChild("AITypeSettings")
	local ASEntitySettings = AITypeSettings:FindFirstChild("ASEntitySettings")
	local CamperSettings = AITypeSettings:FindFirstChild("CamperSettings")
	local MedicSettings = AITypeSettings:FindFirstChild("MedicSettings")

	-- Targeting Settings
	local TargettingSettings = UVSettings:FindFirstChild("TargettingSettings")
	local Target_MaxDistance = TargettingSettings:FindFirstChild("MaxDistance").Value
	local Target_LowestHeight = TargettingSettings:FindFirstChild("LowestHeight").Value
	local Target_MaxHeight = TargettingSettings:FindFirstChild("MaxHeight").Value
	local Target_FavoriteTargets = TargettingSettings:FindFirstChild("FavoriteTargets")

	-- Speech Flags
	local SpeechFlags = UVSettings:FindFirstChild("SpeechFlags")
	local NoTalk = SpeechFlags:FindFirstChild("NoTalk")
	local NoVoice = SpeechFlags:FindFirstChild("NoVoice")
	local IsCurrentlyTalking = SpeechFlags:FindFirstChild("IsCurrentlyTalking")
	local CurrentlyTalkingTo = SpeechFlags:FindFirstChild("CurrentlyTalkingTo")
	local EntityType = SpeechFlags:FindFirstChild("EntityType")

	-- Misc Flags
	local Toughness = UVMiscSettings:FindFirstChild("Toughness")
	local AttackBool = UVMiscSettings:FindFirstChild("Attack")
	local MovingBackwards = UVMiscSettings:FindFirstChild("MovingBackwards")
	local Strafing = UVMiscSettings:FindFirstChild("Strafing")
	local Sprinting = UVMiscSettings:FindFirstChild("Sprinting")
	local MovingToTarget = UVMiscSettings:FindFirstChild("MovingToTarget")
	local Target = UVMiscSettings:FindFirstChild("Target")
	local Distance = UVMiscSettings:FindFirstChild("Distance")
	local AllyTarget = MedicSettings:FindFirstChild("AllyTarget")
	local AllyTargetDistance = MedicSettings:FindFirstChild("AllyTargetDistance")

	-- Additional Settings
	local HasFPSMode = UVSettings:FindFirstChild("HasFPSMode")
	local HasTankFPSMode = UVSettings:FindFirstChild("HasTankFPSMode")
	local Intelligence = UVSettings:FindFirstChild("Intelligence")
	local UnitRange = UVSettings:FindFirstChild("UnitRange")
	local AIType = UVSettings:FindFirstChild("AIType")
	local IsRanged = UVSettings:FindFirstChild("IsRanged")
	local EmptyAmmunition = UVSettings:FindFirstChild("EmptyAmmunition")
	local EntityAllowedToJump = UVSettings:FindFirstChild("EntityAllowedToJump")

	-- Pathfinding
	local PathfindingDirectory = UVSettings:FindFirstChild("PathfindingDirectory")
	local LastTargetID = PathfindingDirectory:FindFirstChild("LastTarget_ID")
	local LastComputeID = PathfindingDirectory:FindFirstChild("LastPathComputed_ID")

	-- NPC Items
	local NPCItems = UVSettings:FindFirstChild("NPCItems")

	-- Team
	local TEAM = Character:FindFirstChild("TEAM")

	-- Regular Speed
	local RegularSpeed = (UVSettings:FindFirstChild("RegularSpeed") or Instance.new("NumberValue", UVSettings))
	RegularSpeed.Name = "RegularSpeed"
	RegularSpeed.Value = Humanoid.WalkSpeed

	local ReadOnlySpeed = (UVSettings:FindFirstChild("ReadOnlySpeed") or Instance.new("NumberValue", UVSettings))
	ReadOnlySpeed.Name = "EntityReadOnlySpeed"
	ReadOnlySpeed.Value = RegularSpeed.Value

	-- Previous State
	local PreviousTorsoPosition = Torso.Position
	local PreviousHealth = Humanoid.Health
	local PreviousJumpPower = Humanoid.JumpPower
	local PreviousSpeed = Humanoid.WalkSpeed

	-- Entity Flag Filters
	local JumpConditionParameters = RaycastParams.new()
	JumpConditionParameters.FilterType = Enum.RaycastFilterType.Exclude
	local FearDetRaycastParams = RaycastParams.new()
	FearDetRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

	JumpConditionParameters.FilterDescendantsInstances = { Character }
	FearDetRaycastParams.FilterDescendantsInstances = { Character }

	local SpecialAgentParameters = { 
		AgentRadius = Character:GetExtentsSize().X / 2, -- Radius of the entity.
		AgentHeight = Character:GetExtentsSize().Y, -- Height of the entity.
		AgentWalkableClimb = Character:GetExtentsSize().Y / 2, -- How much the entity can climb without jumping
		AgentCanJump = true, -- Can the entity jump?
		AgentCanClimb = true, -- Can the entity climb?
		AgentCollisionGroupName = "NPCCollisionGroup", -- Collsion group that the path must respect.
		Costs = { 
			BoundaryWall = math.huge, 
			BuildingPart = 1000,
			LadderLink = 500
		}; -- Entity Costs, for what is cheaper is what it'll use to pathfind through.
		WaypointSpacing = math.min(EntityFlagDirectory.MaxWPSpacing, math.round(((Character:GetExtentsSize().X * Character:GetExtentsSize().Y) / 2))) + EntityFlagDirectory.MinAdditiveWPSpacing,
		SupportPartialPath = false; -- Can the entity support a failed path/unchecked path?
	}

	local JointConfigs = {
		{ Limb = LeftArm,  Name = "LeftJoint",      TorsoOffset = Vector3.new(-1, 1, 0),    LimbOffset = Vector3.new(0, 1, 0) },
		{ Limb = RightArm, Name = "RightJoint",     TorsoOffset = Vector3.new(1, 1, 0),     LimbOffset = Vector3.new(0, 1, 0) },
		{ Limb = LeftLeg,  Name = "LeftThigh",      TorsoOffset = Vector3.new(-0.5, -1, 0), LimbOffset = Vector3.new(0, 1, 0) },
		{ Limb = RightLeg, Name = "RightThigh",     TorsoOffset = Vector3.new(0.5, -1, 0),  LimbOffset = Vector3.new(0, 1, 0) },
		{ Limb = Head,     Name = "NeckAttachment", TorsoOffset = Vector3.new(0, 1, 0),   LimbOffset = Vector3.new(0, -0.5, 0) },
	}

	local Sounds = {

		DeathSound = HumanoidRootPart:FindFirstChild("DeathSound") or Torso:FindFirstChild("DeathSound") or Head:FindFirstChild("DeathSound"),
		HurtSound = HumanoidRootPart:FindFirstChild("HurtSound") or Torso:FindFirstChild("HurtSound") or Head:FindFirstChild("HurtSound"),
		ScaredSound = HumanoidRootPart:FindFirstChild("ScaredSound") or Torso:FindFirstChild("ScaredSound") or Head:FindFirstChild("ScaredSound"),
		EngineSound = HumanoidRootPart:FindFirstChild("EngineSound") or Torso:FindFirstChild("EngineSound") or Head:FindFirstChild("EngineSound"),
		BurnSound = HumanoidRootPart:FindFirstChild("BurnSound") or Torso:FindFirstChild("BurnSound") or Head:FindFirstChild("BurnSound"),
		CrashSound = HumanoidRootPart:FindFirstChild("CrashSound") or Torso:FindFirstChild("CrashSound") or Head:FindFirstChild("CrashSound"),

	}

	-- Misc. Parameters
	local SpecialConditions = UVSettings:FindFirstChild("SpecialConditions")
	local AS_PathFolder = (ASEntitySettings:FindFirstChild("SpecificWPSetName") and Nodes:FindFirstChild(ASEntitySettings:FindFirstChild("SpecificWPSetName").Value)) or nil
	local CanCollide = Character:GetAttribute("CanCollide")
	local DefensiveSpot = nil
	local InitialStates = {}
	local RuntimeStates = {}
	local CurrentSprintState = nil

	-- [[ Enablers & Startup Logic <<-|->> Miscellaneous. ]]

	if not Humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", Humanoid)
	end

	if EntityFlagDirectory.EntityHasTag and not CollectionService:HasTag(Character, "NPC") then
		CollectionService:AddTag(Character, "NPC")
	end

	if EntityFlagDirectory.EntityHasUniqueGUID and not PrimaryPart:GetAttribute("UniqueId") or Torso:GetAttribute("UniqueId") then
		local SingleID = HttpService:GenerateGUID(false)
		PrimaryPart:SetAttribute("UniqueId", SingleID)
		Torso:SetAttribute("UniqueId", SingleID)
	end

	if EntityFlagDirectory.EntitiesCanCollide and not CanCollide then
		Character:SetAttribute("CanCollide", "")
	end

	for _, SoundObject in pairs(Sounds) do
		if SoundObject:IsA("Sound") and SoundObject.Looped then
			SoundObject:Play()
		end
	end

	local function SetToolValue(Tool, Setting)
		if Setting:IsA("ValueBase") then
			Tool.Value = Setting.Value
		elseif Setting:IsA("Animation") then
			Tool.AnimationId = Setting.AnimationId
			local Speed = Setting:FindFirstChild("Speed")
			if Speed then
				Tool.Speed.Value = Speed.Value
			end
		elseif Setting:IsA("Sound") then
			Tool.SoundId = Setting.SoundId
			Tool.PlaybackSpeed = Setting.PlaybackSpeed
			Tool.Volume = Setting.Volume
		end
	end

	local function ConfigureTool(Tool, Item)
		if Tool:FindFirstChild("Settings") then
			for _, Setting in pairs(Item:GetChildren()) do
				local TargetItem = Tool.Settings:FindFirstChild(Setting.Name)
				if TargetItem then
					SetToolValue(TargetItem, Setting)
				end
			end
		end
	end

	local function HandleTool(Item, Character)
		local ToolTemplate = ServerStorage.Items:FindFirstChild(Item.Name, true)
		if ToolTemplate then
			local Tool = ToolTemplate:Clone()
			ConfigureTool(Tool, Item)

			local SetModeValue = Item:FindFirstChild("SetMode")
			if SetModeValue and Tool:FindFirstChild("GetScript_Script") then
				Tool.GetScript_Script.Mode.Value = SetModeValue.Value
			end

			Tool.Parent = Character
		end
	end

	local function HandleNPCItems(Character, UVSettings)
		if not UVSettings or not UVSettings:FindFirstChild("NPCItems") then return end
		for _, Item in pairs(UVSettings:FindFirstChild("NPCItems"):GetChildren()) do
			HandleTool(Item, Character)
		end
	end

	local function ComputeAdjustedPosition(Target)
		return Target.Position + NPCModule.GetDistance(
			"Regular",
			EntityFlagDirectory.MinimumDistanceFromTarget,
			EntityFlagDirectory.DistanceFromTarget
		)
	end

	local function SetupNPCFPSMode(Character, FPSModeValue, UVSettings)
		if FPSModeValue and FPSModeValue.Name == "HasFPSMode" and FPSModeValue.Value == true and UVSettings.AIType.Value ~= "AllyFollower" then
			local DefFPSMode = Assets:WaitForChild("NPCScripts"):FindFirstChild("FPSMode"):Clone()
			DefFPSMode.Enabled = true
			DefFPSMode.Parent = Character
		elseif FPSModeValue and FPSModeValue.Name == "HasTankFPSMode" and FPSModeValue.Value == true then
			local TankFPSMode = Assets:WaitForChild("NPCScripts"):FindFirstChild("TankFPSMode"):Clone()
			TankFPSMode.Enabled = true
			TankFPSMode.Parent = Character
		elseif UVSettings.AIType.Value == "AllyFollower" and UVSettings.HasFPSMode.Value == true then
			local MedicFPSMode = Assets:WaitForChild("NPCScripts"):FindFirstChild("FPSModeAllyFollower"):Clone()
			MedicFPSMode.Enabled = true
			MedicFPSMode.Parent = Character
		end
	end

	local function SetupEntityDifficulty(Character, TEAM)
		local Humanoid = Character:WaitForChild("Humanoid")
		if TEAM.Value == "Zombie" and Workspace:FindFirstChild("KaturiBuff") then
			Humanoid.MaxHealth = Humanoid.MaxHealth * 1.75
			Humanoid.Health = Humanoid.MaxHealth
		end
	end

	local function AttemptSprint(Mode)
		if Mode == "Sprint" then
			if not Sprinting.Value then
				Sprinting.Value = true
				RegularSpeed.Value *= 1.5
			end
		elseif Mode == "Walk" then
			if Sprinting.Value then
				Sprinting.Value = false
				RegularSpeed.Value /= 1.5
			end
		end
	end

	local function LoadAnim(NameOfAnimation: string)
		return Humanoid:FindFirstChild("Animator"):LoadAnimation(Assets.Animations:WaitForChild(NameOfAnimation))
	end

	if not Character:FindFirstChild("FPSMode") and UVSettings.HasFPSMode.Value and UVSettings.AIType.Value ~= "AllyFollower" then
		SetupNPCFPSMode(Character, UVSettings.HasFPSMode, UVSettings)
	elseif not Character:FindFirstChild("TankFPSMode") and UVSettings.HasTankFPSMode.Value then
		SetupNPCFPSMode(Character, UVSettings.HasTankFPSMode, UVSettings)
	elseif UVSettings.AIType.Value == "AllyFollower" and UVSettings.HasFPSMode.Value then
		SetupNPCFPSMode(Character, UVSettings.HasFPSMode, UVSettings)
	end

	task.defer(SetCollisionGroup, Character, CanCollide and "NPCCollisionGroup" or "NPCNoCollision")

	-- [[ Speech Logic ]]

	local function PlayVoiceline(VoiceGroup, MessageSet, Character, TimeToDestroy)
		if Character:GetAttribute("MINDCONTROLLED") then return end
		if AIType.Value == "Mutant" then return end

		local Head = Character:FindFirstChild("Head")
		if not Head then return end

		local Choice = MessageSet[NewRandom:NextInteger(1, #MessageSet)]
		if not Choice or not Choice.Sound then return end

		local SoundTemplate = VoiceGroup:FindFirstChild(Choice.Sound)
		if SoundTemplate and not NoVoice.Value then
			local Sound = SoundTemplate:Clone()
			Sound.PlaybackSpeed = NPCModule.GetVoicePlaybackSpeed(TEAM, Character)
			Sound.Parent = Head
			Sound:Play()

			EntityFlagDirectory.VoiceCooldown = true
			task.delay(TimeToDestroy, function()
				Sound:Destroy()
				EntityFlagDirectory.VoiceCooldown = false
			end)
		end

		if not NoTalk.Value and Choice.Text then
			game:GetService("Chat"):Chat(Head, Choice.Text)
		end
	end

	local function PlaySpawnVoiceline()
		if AIType.Value == "Mutant" or NoTalk.Value then return end

		local TeamValue = TEAM.Value
		local CharacterName = Humanoid.Parent.Name

		if TeamValue == "Zombie" then
			PlayVoiceline(Voicelines.ZombieVoicelines2, {
				{Text = "*YAWN*", Sound = "Zombie_Spawn1"},
				{Text = "Mm. I hope no one reminds me that I eat cake over brain..", Sound = "Zombie_Spawn2"},
				{Text = "Now then, how many noobs will I kill today.", Sound = "Zombie_Spawn3"},
				{Text = "*BURP* I can't wait to go home and eat more cake!!", Sound = "Zombie_Spawn4"},
				{Text = "Another day, another noob DEAD.", Sound = "Zombie_Spawn5"},
				{Text = "I wonder if I'm ready to fight.", Sound = "Zombie_Spawn6"},
				{Text = "The undead shall win this war!", Sound = "Zombie_Spawn7"}
			}, Character, 6)

		elseif (TeamValue == "Noob" or TeamValue == "Splinter")
			and not Humanoid.Parent:GetAttribute("NoVoice")
			and not Humanoid.Parent:GetAttribute("MindControlled")
			and CharacterName ~= "Noob Plasma Tank" then

			PlayVoiceline(Voicelines.NoobVoicelines2, {
				{Text = "Let's do this.", Sound = "Noob_Spawn1"},
				{Text = "The zombies are going to pay after I take a massive poop!", Sound = "Noob_Spawn2"},
				{Text = "I hope I can collect a dead body and sell it to buyer.", Sound = "Noob_Spawn3"},
				{Text = "*BURP* I can't wait to go home and eat more cake!!", Sound = "Noob_Spawn4"},
				{Text = "I cannot wait until I eat some takeos!", Sound = "Noob_Spawn5"},
				{Text = "Woohoo! Hopefully we can win this war!", Sound = "Noob_Spawn6"},
				{Text = "Finally, I am bored!", Sound = "Noob_Spawn7"}
			}, Character, 6)
		end
	end

	local function PlayMiscLines()
		if EntityFlagDirectory.VoiceCooldown then return end

		local TeamValue = TEAM.Value
		local CharacterName = Humanoid.Parent.Name

		if TeamValue == "Zombie" then
			PlayVoiceline(Voicelines.ZombieVoicelines, {
				{Text = "Back up, sucker!", Sound = "Zombie_WalkBackwards1"},
				{Text = "Back up boy, I'mma kill you!", Sound = "Zombie_WalkBackwards2"},
				{Text = "Get away from me you weakling!", Sound = "Zombie_WalkBackwards3"},
				{Text = "Fool I'm not gonna stand still!", Sound = "Zombie_WalkBackwards4"},
				{Text = "Hmph, tryna sneak up on me, huh!", Sound = "Zombie_WalkBackwards5"}
			}, Character, 10)

		elseif TeamValue == "Noob" then
			PlayVoiceline(Voicelines.NoobVoicelines, {
				{Text = "Get away from me boi!", Sound = "Noob_WalkBackwards1"},
				{Text = "Oh you thought I was gonna stand still huh!", Sound = "Noob_WalkBackwards2"}
			}, Character, 10)

		elseif CharacterName == "Survivor Noob" then
			PlayVoiceline(Voicelines.SurvivorVoicelines, {
				{Text = "STAY BACK! STAY BACK! YOU'RE NOT TURNING ME INTO ONE OF THOSE THINGS!", Sound = "Survivor_Scream1"},
				{Text = "I'LL BLOW YOUR BRAINS OUT! GET AWAY FROM ME!", Sound = "Survivor_Scream2"},
				{Text = "DON'T TOUCH ME YOU FREAKS! I WON'T BE LIKE YOU I'LL DIE FIRST!", Sound = "Survivor_Scream3"},
				{Text = "FIND YOUR OWN HIDING PLACE, THE MONSTERS ARE EVERYWHERE!", Sound = "Survivor_Scream4"}
			}, Character, 10)
		end
	end

	local function HandleAttackSequence(Hit, Team, MessageSet, VoiceGroup)
		if not Hit or not Hit.Parent then return end
		if FearChecks.EntityInFear.Value then return end
		if EntityFlagDirectory.VoiceCooldown2 or NoTalk.Value then return end

		local Target = Hit.Parent
		local IsAlly = NPCModule.CheckIfAlly(Target, Team, true)
		local IsEnemy = NPCModule.CheckIfEnemy(Target, Team)

		if IsAlly or IsEnemy then
			PlayVoiceline(VoiceGroup, MessageSet, Character, 10)
			EntityFlagDirectory.VoiceCooldown2 = true
			task.delay(10, function()
				EntityFlagDirectory.VoiceCooldown2 = false
			end)
		end
	end

	local function PlayCombatLines()
		if tick() - EntityFlagDirectory.LastRaycastTime < EntityFlagDirectory.RaycastCooldown then return end
		EntityFlagDirectory.LastRaycastTime = tick()

		if not (AIType.Value and UnitRange.Value) or Humanoid:GetState() == Enum.HumanoidStateType.Dead then
			warn("[HandleNPCAttack] Missing settings for " .. Character.Name)
			return
		end

		local Direction = (Target.Value.Position - HumanoidRootPart.Position).Unit
		local HitResult = nil

		if AIType.Value == "AllyFollower" then
			HitResult = NPCModule.NPCRaycast("HitTEAM", HumanoidRootPart.Position, Direction, UnitRange.Value, Character)
		else
			HitResult = NPCModule.NPCRaycast("Normal", HumanoidRootPart.Position, Direction, UnitRange.Value, Character)
		end

		if not HitResult or not HitResult.Parent then return end
		if not NPCModule.CheckIfEnemy(HitResult.Parent, TEAM.Value) then return end
		if FearChecks.EntityInFear.Value then return end

		if TEAM.Value == "Zombie" then
			HandleAttackSequence(HitResult, TEAM.Value, {
				{Text = "Eeeeuuuurrrghh..!!", Sound = "Zombie_Attacking1"},
				{Text = "This fool shall die to me!", Sound = "Zombie_Attacking2"},
				{Text = "Oh, you are dead now!", Sound = "Zombie_Attacking3"},
				{Text = "*Inhale* PFFHUFFHUFF DIEEEE!", Sound = "Zombie_Attacking4"},
				{Text = "It is time for me to end you!", Sound = "Zombie_Attacking5"},
				{Text = "Just give me 5 seconds and you're dead!", Sound = "Zombie_Attacking6"},
				{Text = "I shall give death to you.", Sound = "Zombie_Attacking7"}
			}, Voicelines.FightVoicelines)

		elseif TEAM.Value == "Noob" then
			HandleAttackSequence(HitResult, TEAM.Value, {
				{Text = "Ooo, I'mma get you..!", Sound = "Noob_Attacking1"},
				{Text = "Take this, sucker!", Sound = "Noob_Attacking2"},
				{Text = "Oh, it's over for you now, sucker!", Sound = "Noob_Attacking3"}
			}, Voicelines.FightVoicelines)
		end
	end

	local function PlayNeedAmmoVoice()
		PlayVoiceline(Voicelines.AmmoVoicelines, {{ Text = "Excuse me", Sound = "NeedAmmo" }}, Character, 3)
		EntityFlagDirectory.VoiceCooldown2 = true
		task.delay(NewRandom:NextNumber(2, 10), function()
			EntityFlagDirectory.VoiceCooldown2 = false
		end)
	end

	local function RemoveNoAmmoLabel()
		local NoAmmoLabel = Head:FindFirstChild("NoAmmoLabel")
		if NoAmmoLabel then
			NoAmmoLabel:Destroy()
		end
	end

	local function HandleAmmoStatus()
		if not Character.Head:FindFirstChild("NoAmmoLabel") then
			local NoAmmoLabel = Assets.Misc:Clone()
			NoAmmoLabel.Parent = Character.Head
			NoAmmoLabel.Adornee = Character.Head
			NoAmmoLabel.Enabled = true
		end

		local AmmoBox = NPCModule.FindNearestAmmoBox(HumanoidRootPart)
		if not AmmoBox and not EntityFlagDirectory.VoiceCooldown2 then
			PlayNeedAmmoVoice()
		end
	end

	local function PlayHurtSound()
		if Humanoid.Health < PreviousHealth and not EntityFlagDirectory.HurtSoundCooldown then
			Sounds.HurtSound:Play()
			EntityFlagDirectory.HurtSoundCooldown = true
			task.defer(function()
				task.wait(EntityFlagDirectory.HurtSoundCooldownValue)
				EntityFlagDirectory.HurtSoundCooldown = false
			end)
		end
	end

	local function RegisterEntityForSpeech(NPC)
		if not NPC:IsA("Model") or not NPC:FindFirstChild("Humanoid") then
			return
		end

		if table.find(EntityFlagDirectory.ActiveTalkingNPCs, NPC) then return end -- Prevent duplicate registration
		table.insert(EntityFlagDirectory.ActiveTalkingNPCs, NPC)

		NPC.HumanoidRootPart.Anchored = false

		task.defer(function()
			while true do
				task.wait(2)
				if not IsCurrentlyTalking.Value and NPC.Parent and not CurrentlyTalkingTo.Value then
					local ClosestNPC, ClosestDistance = nil, math.huge

					for _, OtherNPC in ipairs(EntityFlagDirectory.ActiveTalkingNPCs) do
						if OtherNPC ~= NPC and OtherNPC.PrimaryPart then
							local Distance = (NPC.PrimaryPart.Position - OtherNPC.PrimaryPart.Position).Magnitude
							if Distance < 10 and Distance < ClosestDistance then
								ClosestNPC, ClosestDistance = OtherNPC, Distance
							end
						end
					end

					if ClosestNPC and not ClosestNPC:FindFirstChild("IsTalking").Value then
						NPC.HumanoidRootPart.CFrame = CFrame.lookAt(NPC.HumanoidRootPart.Position, ClosestNPC.HumanoidRootPart.Position)
						ClosestNPC.HumanoidRootPart.CFrame = CFrame.lookAt(ClosestNPC.HumanoidRootPart.Position, NPC.HumanoidRootPart.Position)

						NPC.HumanoidRootPart.Anchored = true
						ClosestNPC.HumanoidRootPart.Anchored = true

						IsCurrentlyTalking.Value = true
						ClosestNPC:FindFirstChild("IsTalking").Value = true
						--SpeechModule:StartConversation(NPC, ClosestNPC)

						task.wait(5)
						NPC.HumanoidRootPart.Anchored = false
						ClosestNPC.HumanoidRootPart.Anchored = false
						IsCurrentlyTalking.Value = false
						ClosestNPC:FindFirstChild("IsTalking").Value = false
					end
				end
			end
		end)
	end

	local function UnregisterEntityFromSpeech(NPC)
		for i, StoredNPC in ipairs(EntityFlagDirectory.ActiveTalkingNPCs) do
			if StoredNPC == NPC then
				table.remove(EntityFlagDirectory.ActiveTalkingNPCs, i)
				break
			end
		end
	end

	-- [[ State System ]]

	local function ShouldRunDetection(NPC)
		local Now = tick()
		if not LastDetectionTime[NPC] or (Now - LastDetectionTime[NPC]) > 1.5 then
			LastDetectionTime[NPC] = Now
			return true
		end
		return false
	end

	local function IsABloodObject(Object)
		return Object.Name:lower():find("blood") ~= nil
	end

	local function GetDeathType(Model)
		local Humanoid = Model:FindFirstChildOfClass("Humanoid")

		if Humanoid and Humanoid.Health <= 0 then
			if Model:FindFirstChild("Gibbed") then
				return "Gibbed"
			elseif Model:FindFirstChild("Dead") then
				return "DeadCharacter"
			end
		end

		return nil
	end

	local function IsCorpseDetected(Model)
		return EntityFlagDirectory.DetectedModels[Model] ~= nil
	end

	local function MarkCorpseDetected(Model, DeathType)
		if not DeathType then
			warn("[MarkCorpseDetected] DeathType is nil for", Model:GetFullName())
			return
		end

		EntityFlagDirectory.DetectedDeathInstances = EntityFlagDirectory.DetectedDeathInstances or {}

		if not EntityFlagDirectory.DetectedDeathInstances[DeathType] then
			warn("[MarkCorpseDetected] Initializing list for death type:", DeathType)
			EntityFlagDirectory.DetectedDeathInstances[DeathType] = {}
		end

		table.insert(EntityFlagDirectory.DetectedDeathInstances[DeathType], Model)
		EntityFlagDirectory.DetectedModels[Model] = true

		print(EntityFlagDirectory.DetectedDeathInstances)
	end

	local function IsBloodAlreadyDetected(BloodInstance)
		if BloodInstance ~= nil then
			return EntityFlagDirectory.DetectedBlood[BloodInstance] == true
		else
			return warn("Check bypassed and instance went nil.")
		end
	end

	local function MarkBloodDetected(BloodInstance)
		local List = EntityFlagDirectory.DetectedDeathInstances.Blood
		if List then
			List[#List + 1] = BloodInstance
		end
		EntityFlagDirectory.DetectedBlood[BloodInstance] = true
	end

	local function DecrementFinalCost(mode: string, amount: number)
		assert(mode == "Fear" or mode == "Vomit", "Mode must be 'Fear' or 'Vomit'")
		EntityFlagDirectory.CostDecrements[mode] += amount
	end

	local function PostFinalCost(FCMode)
		local T_CostSet = EntityFlagDirectory.DeathCostValues_Fear
		local KeyCheck = "Fear"

		if FCMode == "Vomit" then
			T_CostSet = EntityFlagDirectory.DeathCostValues_Vomit
			KeyCheck = "Vomit"
		end

		local TotalC = 0
		local BreakdownC = {}

		for DeathType, List in pairs(EntityFlagDirectory.DetectedDeathInstances) do
			local Count = #List
			local Cost = Count * (T_CostSet[DeathType] or 0)
			TotalC += Cost
			BreakdownC[DeathType] = Cost
		end

		local Decrement = EntityFlagDirectory.CostDecrements[KeyCheck] or 0
		local Adjusted = math.max(TotalC - Decrement, 0)

		EntityFlagDirectory.AdjustedFinalCosts[KeyCheck] = Adjusted

		return {
			TotalCost = TotalC,
			AdjustedCost = Adjusted,
			Breakdown = BreakdownC
		}
	end

	local function BuildFinalCostTable(CostReport, Defense)
		local FCTable = {}
		local FCost = nil
		local DefMult = Defense or 1

		for Category, FinalCost in pairs(CostReport.Breakdown) do
			local Count = #EntityFlagDirectory.DetectedDeathInstances[Category]
			--print(Category .. " - Count: " .. Count .. " | Cost: " .. FinalCost)
			FCost = CostReport.AdjustedCost * DefMult
			FCTable[Category] = {
				Count = Count,
				Cost = FinalCost
			}
		end

		return FCTable, FCost
	end

	local RCDebugRays = false

	local function VisualizeRay(StartPosition: Vector3, EndPosition: Vector3, HitInstance: Instance?)
		if not RCDebugRays then return end
		local Direction = EndPosition - StartPosition
		local Magnitude = Direction.Magnitude
		if Magnitude == 0 then return end

		local VisualizerPart = Instance.new("Part")
		VisualizerPart.Anchored = true
		VisualizerPart.CanCollide = false
		VisualizerPart.CanQuery = false
		VisualizerPart.Size = Vector3.new(0.1, 0.1, Magnitude)
		VisualizerPart.CFrame = CFrame.new(StartPosition, EndPosition) * CFrame.new(0, 0, -Magnitude / 2)
		VisualizerPart.Material = Enum.Material.Neon
		VisualizerPart.Color = HitInstance and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		VisualizerPart.Transparency = 0.25
		VisualizerPart.Name = "RaycastVisualizer_" .. tostring(tick())
		VisualizerPart.Parent = workspace

		task.delay(2, function()
			if VisualizerPart and VisualizerPart.Parent then
				VisualizerPart:Destroy()
			end
		end)
	end

	local function DetectFromNPC(NPC)
		if not ShouldRunDetection(NPC) then return end

		local HRP = NPC:FindFirstChild("HumanoidRootPart")
		local Humanoid = NPC:FindFirstChildOfClass("Humanoid")
		if not HRP or not Humanoid or Humanoid.Health <= 0 then return end

		local RCOrigin = HRP.Position + Vector3.new(0, 2, 0)

		task.defer(function()
			for _, ItemRet in ipairs(BloodContainer:GetChildren()) do
				if IsABloodObject(ItemRet) and not IsBloodAlreadyDetected(ItemRet) then
					local Root = ItemRet:IsA("BasePart") and ItemRet or ItemRet:FindFirstAncestorOfClass("Model")
					if Root then
						local Dir = Root.Position - RCOrigin
						if Dir.Magnitude < 50 then
							local RCRes = Workspace:Raycast(RCOrigin, Dir, FearDetRaycastParams)
							task.defer(VisualizeRay, RCOrigin, Root.Position, RCRes and RCRes.Instance == ItemRet)
							if RCRes and RCRes.Instance == ItemRet then
								MarkBloodDetected(ItemRet)
							end
						end
					end
				end
			end
		end)

		task.defer(function()
			for _, Model in ipairs(UnitsFolder:GetChildren()) do
				if Model ~= NPC and not IsCorpseDetected(Model) then
					local Hum = Model:FindFirstChildOfClass("Humanoid")
					if Hum and Hum.Health <= 0 then
						local Root = Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart") or Model:FindFirstChildOfClass("BasePart")
						if Root then
							local Dir = Root.Position - RCOrigin
							if Dir.Magnitude < 50 then
								local Result = Workspace:Raycast(RCOrigin, Dir, FearDetRaycastParams)
								task.defer(VisualizeRay, RCOrigin, Root.Position, Result and Result.Instance:IsDescendantOf(Model))
								if Result then
									if Result.Instance:IsDescendantOf(Model) then
										local DeathType = GetDeathType(Model)
										if DeathType then
											MarkCorpseDetected(Model, DeathType)
										else
											warn("[Corpse] No death type for:", Model:GetFullName())
										end
									end
								else
									warn("Ray hit nothing for model:", Model:GetFullName())
								end
							end
						end
					end
				end
			end
		end)

		task.defer(function()
			local CostReport = PostFinalCost("Fear")
			local CostReport2 = PostFinalCost("Vomit")
			local FearBase = FearSettings:FindFirstChild("DefenseAgainstFear")
			local VomitBase = FearSettings:FindFirstChild("DefenseAgainstVomit")
			local ProminentFear = FearSettings:FindFirstChild("MoreProminentToFear")
			local ProminentVomit = FearSettings:FindFirstChild("MoreProminentToVomit")
			local Mult1 = (ProminentFear and ProminentFear.Value) and 1.5 or 1
			local Mult2 = (ProminentVomit and ProminentVomit.Value) and 1.5 or 1
			local FCTable1, FCost1 = BuildFinalCostTable(CostReport, (FearBase and FearBase.Value or 1) * Mult1)
			local FCTable2, FCost2 = BuildFinalCostTable(CostReport2, (VomitBase and VomitBase.Value or 1) * Mult2)
			FearSettings.VomitLevel.Value = FCost2
			FearSettings.FearLevel.Value = FCost1
		end)
	end

	local function RestoreFearState(Character, NormalSpeed, RegularSpeed, CrySound, CryEffect, UVSettings)
		RegularSpeed.Value = NormalSpeed.Value
		HandleNPCItems(Character, UVSettings)
		if Sprinting.Value then
			AttemptSprint("Walk")
		end
	end

	local function PlayEffect(
		Character: Model,
		Humanoid: Humanoid,
		UVSettings: Instance,
		EffectType: string,
		SoundType: string,
		AnimationData: {
			Start: string,
			Idle: string?,
			Finish: string?,
			PlaybackSpeed: number?,
			IdleLooping: boolean?,
			IdleDuration: number?,
			StartToIdleDelay: number?,
			IdleToFinishDelay: number?
		},
		ColorChange: boolean?,
		HasLabel: boolean?,
		DelayStart: number?,
		EffectDuration: number?,
		RestoreDelay: number?
	)

		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		if not Animator then return end

		local EffectSound = Assets.Misc:FindFirstChild(SoundType .. "Sound", true):Clone() :: Sound
		EffectSound.RollOffMaxDistance = 75
		EffectSound.PlaybackSpeed = NPCModule.GetVoicePlaybackSpeed(Character:FindFirstChild("TEAM"), Character)
		EffectSound.Volume = (Character.Name == "Giant Noob" or Character.Name == "Giant Zombie") and 5 or 1.5
		EffectSound.Parent = Head
		EffectSound:Play()

		local AnimStart = LoadAnim(AnimationData.Start)
		local AnimIdle = AnimationData.Idle and LoadAnim(AnimationData.Idle) or nil
		local AnimFinish = AnimationData.Finish and LoadAnim(AnimationData.Finish) or nil

		local Effect = Assets.Misc[EffectType]:Clone()
		Effect.Parent = Head

		local Label = nil

		if HasLabel then
			Label = Assets.Misc[EffectType .. "Label"]:Clone()
			Label.Adornee = Head
			Label.Parent = Head
		end

		local OldHeadColor = Head.Color

		task.spawn(function()
			task.wait(DelayStart or 0)
			Humanoid:UnequipTools()

			if ColorChange then
				Head.Color = Color3.fromRGB(0, 131, 9)
			end

			Effect.Enabled = true
			AnimStart:Play(AnimationData.PlaybackSpeed or 1)
			task.wait(AnimStart.Length / (AnimationData.PlaybackSpeed or 1))

			task.wait(AnimationData.StartToIdleDelay or 0)

			if AnimIdle then
				AnimIdle.Looped = AnimationData.IdleLooping and true or false
				AnimIdle:Play(AnimationData.PlaybackSpeed or 1)
			end

			if not AnimationData.IdleLooping then
				task.wait(AnimationData.IdleDuration or EffectDuration or 1)
				if AnimIdle then AnimIdle:Stop() end

				task.wait(AnimationData.IdleToFinishDelay or 0)

				if ColorChange then
					Head.Color = OldHeadColor
				end

				Effect.Enabled = false

				if AnimFinish then
					AnimFinish:Play(AnimationData.PlaybackSpeed or 1)
				end

				task.wait(RestoreDelay or 1)

				if not AnimationData.IdleLooping then
					RestoreFearState(
						Character,
						UVSettings:FindFirstChild("EntityReadOnlySpeed"),
						UVSettings:FindFirstChild("RegularSpeed"),
						EffectSound,
						Effect,
						UVSettings
					)

					if Label then
						Label:Destroy()
					end
				end
			end
		end)

		return AnimIdle, Effect, EffectSound, AnimFinish, OldHeadColor, Label
	end

	-- [[: Inner Works of the Entity States :]] --
	
	-- [[[>EntityStates/Fear/MiscellaneousUtilities<]]] --

	local function IsEntityGiant(Character)
		return Character.Name == "Giant Noob" or Character.Name == "Giant Zombie"
	end

	local function MultiplyNumberValueIfExists(Parent: Instance, Name: string, Multiplier: number)
		local Value = Parent:FindFirstChild(Name)
		if Value and Value:IsA("NumberValue") then
			Value.Value *= Multiplier
		end
	end

	local function CreateStableTimer(ValueToCheckMod: NumberValue, TimeUntilClockStop: number)
		local LastValue = ValueToCheckMod.Value
		local Clock = os.clock()

		return function()
			local CurrentVal = ValueToCheckMod.Value
			if CurrentVal ~= LastValue then
				LastValue = CurrentVal
				Clock = os.clock()
			end
			return (os.clock() - Clock) >= TimeUntilClockStop
		end
	end

	local function IsEntityAvailable()
		return not FearChecks.EntityIsCrying.Value
			and not FearChecks.EntityIsVomitting.Value
			and not FearChecks.EntityInFear.Value
	end

	-- [[[>EntityStates/Fear/Vomit<]]] --

	local function GetVomitDuration(Character, VSettings)
		local Multiplier = IsEntityGiant(Character) and 1.15 or 1
		local EFDelay = VSettings.VomittingEffectDelay.Value * Multiplier
		local EFDuration = VSettings.VomittingDuration.Value * Multiplier
		local RESDelay = VSettings.VomitRestoreDelay.Value * Multiplier
		return EFDelay, EFDuration, RESDelay
	end

	local function GetAnimationConfiguration_Vomit(Character)
		return {
			Start = "VomitStart",
			Idle = "VomitIdle",
			Finish = "VomitFinish",
			PlaybackSpeed = IsEntityGiant(Character) and 0.6 or 0.45,
			IdleLooping = false,
			IdleDuration = FearSettings.VomittingDuration.Value,
			StartToIdleDelay = 0.75,
			IdleToFinishDelay = 0,
		}
	end

	local function HandleVomitDurationMode(Character, Humanoid, UVSettings, FearSettings, FearChecks)

		local EFDelay, EFDuration, RESDelay = GetVomitDuration(Character, FearSettings)

		FearSettings.DelayTimeUntilStoppingVomit.Value = 
			EFDelay + 
			EFDuration + 
			RESDelay + 0.1

		task.delay(FearSettings.DelayTimeUntilStoppingVomit.Value, function()
			DecrementFinalCost("Vomit", FearSettings.VomitLevel.Value)
			task.wait(0.1)
			FearChecks.EntityIsVomitting.Value = false
		end)

		PlayEffect(
			Character,
			Humanoid,
			UVSettings,
			"Vomitting",
			"Vomitting",
			GetAnimationConfiguration_Vomit(Character),
			true,
			true,
			EFDelay,
			EFDuration,
			RESDelay
		)
	end

	local function HandleVomitIdleMode(Character, Humanoid, UVSettings, FearSettings)
		local EFDelay, EFDuration, RESDelay = GetVomitDuration(Character, FearSettings)

		local IdleAnim, Effect, EffectSound, AnimFinish, OldHeadColor, Label = PlayEffect(
			Character,
			Humanoid,
			UVSettings,
			"Vomitting",
			"Vomitting",
			(function()
				local Configuration = GetAnimationConfiguration_Vomit(Character)
				Configuration.IdleLooping = true
				return Configuration
			end)(),
			true,
			true,
			EFDelay,
			EFDuration,
			RESDelay
		)

		task.spawn(function()
			while task.wait(0.1) do
				DecrementFinalCost("Vomit", 2.5)
				if FearSettings.VomitLevel.Value <= 0 then
					IdleAnim:Stop()
					AnimFinish:Play()
					Head.Color = OldHeadColor
					Effect.Enabled = false
					FearChecks.EntityIsVomitting.Value = false

					task.delay(1, function()
						RestoreFearState(
							Character,
							UVSettings:FindFirstChild("EntityReadOnlySpeed"),
							UVSettings:FindFirstChild("RegularSpeed"),
							EffectSound,
							Effect,
							UVSettings
						)
					end)

					if Label then
						Label:Destroy()
					end

					break
				end
			end
		end)
	end
	
	local function HandleVomitState()
		FearChecks.EntityIsVomitting.Value = true
		if FearSettings.VomittingLastsForDuration.Value then
			task.defer(HandleVomitDurationMode, Character, Humanoid, UVSettings, FearSettings, FearChecks)
		else
			task.defer(HandleVomitIdleMode, Character, Humanoid, UVSettings, FearSettings)
		end
	end
	
	-- [[[>EntityStates/Fear/Fearing<]]] --

	local function DeferAnimationSpeedReduction(Folder: Instance, ExcludeName: string)
		if not Folder then return end
		task.defer(function()
			for _, Anim in ipairs(Folder:GetChildren()) do
				if Anim:IsA("Animation") and Anim.Name ~= ExcludeName then
					MultiplyNumberValueIfExists(Anim, "Speed", 0.75)
				end
			end
		end)
	end

	local function DeferTweakMultipliers(Target: Instance, Tweaks: { [number]: { Name: string, Multiplier: number } })
		if not Target then return end
		task.defer(function()
			for _, Tweak in ipairs(Tweaks) do
				MultiplyNumberValueIfExists(Target, Tweak.Name, Tweak.Multiplier)
			end
		end)
	end

	local function DeferRevertTweakMultipliers(Target: Instance, Tweaks: { [number]: { Name: string, Multiplier: number } })
		if not Target then return end
		task.defer(function()
			for _, Tweak in ipairs(Tweaks) do
				local Inverse = 1 / Tweak.Multiplier
				MultiplyNumberValueIfExists(Target, Tweak.Name, Inverse)
			end
		end)
	end

	local function DeferRevertAnimationSpeed(Folder: Instance, ExcludeName: string)
		if not Folder then return end
		task.defer(function()
			for _, Anim in ipairs(Folder:GetChildren()) do
				if Anim:IsA("Animation") and Anim.Name ~= ExcludeName then
					MultiplyNumberValueIfExists(Anim, "Speed", 1 / 0.75)
				end
			end
		end)
	end

	local function FearEffects(Tool: Tool)
		local Configuration = Tool:FindFirstChild("Configuration")
		if not Configuration then return end

		if IsRanged.Value then
			DeferAnimationSpeedReduction(Configuration:FindFirstChild("Animations"), "Fire")
			DeferTweakMultipliers(Configuration, EntityFlagDirectory.FearRangeTweaks)
		else
			local AssetsFolder = Tool:FindFirstChild("Assets_Folder")
			DeferAnimationSpeedReduction(AssetsFolder, "Idle_Animation")
			DeferTweakMultipliers(Configuration, EntityFlagDirectory.FearMeleeTweaks)
		end
	end

	local function RevertFearEffects(Tool: Tool)
		local Configuration = Tool:FindFirstChild("Configuration")
		if not Configuration then return end

		if IsRanged.Value then
			DeferRevertAnimationSpeed(Configuration:FindFirstChild("Animations"), "Fire")
			DeferRevertTweakMultipliers(Configuration, EntityFlagDirectory.FearRangeTweaks)
		else
			local AssetsFolder = Tool:FindFirstChild("Assets_Folder")
			DeferRevertAnimationSpeed(AssetsFolder, "Idle_Animation")
			DeferRevertTweakMultipliers(Configuration, EntityFlagDirectory.FearMeleeTweaks)
		end
	end

	local function StartFearState()
		FearChecks.EntityInFear.Value = true

		task.defer(function()
			local ToolAccq = Character:FindFirstChildWhichIsA("Tool", true)
			if ToolAccq and ToolAccq:FindFirstChild("Configuration") then
				task.defer(FearEffects, ToolAccq)
			end

			task.spawn(function()
				local StableTimer = CreateStableTimer(FearSettings.FearLevel, FearSettings.TimeUntilFearReduces.Value)
				EntityFlagDirectory.EntityInternalClock = os.clock()

				while task.wait(0.25) do
					local ShouldDecremet = false

					if not FearSettings.NotResetClockOnFearLevelMod.Value then
						ShouldDecremet = StableTimer()
					else
						ShouldDecremet = os.clock() - EntityFlagDirectory.EntityInternalClock >= FearSettings.TimeUntilFearReduces.Value
					end

					if ShouldDecremet then
						task.defer(DecrementFinalCost, "Fear", 1)
					end

					if FearSettings.FearLevel.Value <= 0 then
						task.defer(RevertFearEffects, ToolAccq)
						break
					end
				end
			end)
		end)
	end
	
	-- [[[>EntityStates/Fear/Crying<]]] --

	local function GetCryDuration(Character, VSettings)
		local Multiplier = IsEntityGiant(Character) and 1.15 or 1
		local EFDelay = VSettings.CryingEffectDelay.Value * Multiplier
		local EFDuration = VSettings.CryingDuration.Value * Multiplier
		local RESDelay = VSettings.CryingRestoreDelay.Value * Multiplier
		return EFDelay, EFDuration, RESDelay
	end

	local function GetAnimationConfiguration_Cry(Character)
		return {
			Start = "CryStart",
			Idle = "CryIdle",
			Finish = "CryFinish",
			PlaybackSpeed = IsEntityGiant(Character) and 0.6 or 0.45,
			IdleLooping = false,
			IdleDuration = FearSettings.VomittingDuration.Value,
			StartToIdleDelay = 0.75,
			IdleToFinishDelay = 0,
		}
	end
	
	local function HandleCryRetreatToPoint(Character, RetreatPoint)
		AttemptSprint("Sprint")
		task.spawn(function()
			while task.wait(0.5) do
				HandlePathToTarget(Character, RetreatPoint, false, { Visualize = false, Tracking = false })
				if not FearChecks.EntityIsCrying.Value then
					HandleEntityStop(Character)
					break
				end
			end
		end)
	end

	local function HandleCryDurationMode(Character, Humanoid, UVSettings, FearSettings, FearChecks)
		local EFDelay, EFDuration, RESDelay = GetCryDuration(Character, FearSettings)

		FearSettings.DelayTimeUntilStoppingCry.Value = EFDelay + EFDuration + RESDelay + 0.1

		task.delay(FearSettings.DelayTimeUntilStoppingCry.Value, function()
			DecrementFinalCost("Fear", FearSettings.FearLevel.Value)
			FearChecks.EntityIsCrying.Value = false
		end)

		PlayEffect(
			Character,
			Humanoid,
			UVSettings,
			"Crying",
			"Crying",
			GetAnimationConfiguration_Cry(Character),
			true,
			true,
			EFDelay,
			EFDuration,
			RESDelay
		)

		if FearSettings.RetreatWhileCrying.Value then
			local RetreatPoint = NPCModule.FindNearestMedicRetreatSpot(HumanoidRootPart)
			if RetreatPoint then
				HandleCryRetreatToPoint(Character, RetreatPoint)
			end
		end
	end

	local function HandleCryIdleMode(Character, Humanoid, UVSettings, FearSettings, FearChecks)
		local EFDelay, EFDuration, RESDelay = GetCryDuration(Character, FearSettings)

		local IdleAnim, Effect, EffectSound, AnimFinish, OldHeadColor, Label = PlayEffect(
			Character,
			Humanoid,
			UVSettings,
			"Crying",
			"Crying",
			(function()
				local C = GetAnimationConfiguration_Cry(Character)
				C.IdleLooping = true
				return C
			end)(),
			true,
			true,
			EFDelay,
			EFDuration,
			RESDelay
		)

		if FearSettings.RetreatWhileCrying.Value then
			local RetreatPoint = NPCModule.FindNearestMedicRetreatSpot(HumanoidRootPart)
			if RetreatPoint then
				HandleCryRetreatToPoint(Character, RetreatPoint)
			end
		end

		task.spawn(function()
			while task.wait(0.1) do
				DecrementFinalCost("Fear", 1)
				if FearSettings.FearLevel.Value <= 0 then
					IdleAnim:Stop()
					AnimFinish:Play()
					Head.Color = OldHeadColor
					Effect.Enabled = false
					FearChecks.EntityIsCrying.Value = false
					task.delay(1, function()
						RestoreFearState(
							Character,
							UVSettings:FindFirstChild("EntityReadOnlySpeed"),
							UVSettings:FindFirstChild("RegularSpeed"),
							EffectSound,
							Effect,
							UVSettings
						)
					end)

					if Label then Label:Destroy() end
					break
				end
			end
		end)
	end
	
	local function HandleCryState()
		FearChecks.EntityIsCrying.Value = true
		if FearSettings.CryingLastsForSetTime.Value then
			task.defer(HandleCryDurationMode, Character, Humanoid, UVSettings, FearSettings, FearChecks)
		else
			task.defer(HandleCryIdleMode, Character, Humanoid, UVSettings, FearSettings, FearChecks)
		end
	end

	-- [[[>EntityStates/OperatorFunction<]]] --

	local function CheckEntityState()
		
		local FearLevel = FearSettings.FearLevel.Value
		local VomitLevel = FearSettings.VomitLevel.Value
		local CanFear = FearChecks.EntityCanFear.Value
		local CanCry = FearChecks.EntityCanCry.Value
		local CanVomit = FearChecks.EntityCanVomit.Value

		if FearLevel >= 100 and CanFear and CanCry and not FearChecks.EntityIsCrying.Value --[[and IsEntityAvailable()]] then
						
			if FearSettings.CryWhenFearPeak.Value then
				task.defer(HandleCryState)
			end
			
			return
		end

		if FearLevel >= 75 and FearLevel < 100 and VomitLevel < 100 and CanFear and IsEntityAvailable() then
			task.defer(StartFearState)
			return
		end

		if VomitLevel >= 100 and CanFear and CanVomit and IsEntityAvailable() then
			task.defer(HandleVomitState)
			return
		end

		-- TODO: Add other states (e.g. concussion, mind control)
	end

	-- [[ Navigation Logic ]]

	local function AttemptEntityJump(Humanoid)
		if EntityAllowedToJump ~= nil then
			if EntityFlagDirectory.CanJump and EntityAllowedToJump.Value == true then
				EntityFlagDirectory.CanJump = false
				task.delay(EntityFlagDirectory.TimeUntilCanJump, function()
					EntityFlagDirectory.CanJump = true
					Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end)
			end
		else
			warn("Boolean returns nil, did you happen to not add it or it is due to game lag?")
		end
	end

	local function StartPathfinding(Target, Character, ForceManualRecomputation)
		if tick() - EntityFlagDirectory.LastPathfindingDone < EntityFlagDirectory.EntityPathfindDuration then
			return
		end

		if Humanoid.Health <= 0 then
			return
		end
		
		if FearChecks.EntityIsVomitting.Value or FearChecks.EntityIsCrying.Value then return end

		EntityFlagDirectory.LastPathfindingDone = tick()

		ForceManualRecomputation = ForceManualRecomputation or false

		if not Target or not Target:IsDescendantOf(game) then return end

		local TargetID = Target:GetAttribute("UniqueId")
		if not TargetID then return end
		LastTargetID.Value = TargetID

		if not ForceManualRecomputation and LastTargetID == TargetID and LastComputeID.Value == TargetID then
			return
		end

		EntityFlagDirectory.LastPathRefToken += 1
		local MyToken = EntityFlagDirectory.LastPathRefToken

		if EntityFlagDirectory.CanPathfind then return end
		EntityFlagDirectory.CanPathfind = true

		task.defer(function()
			if not Target or not Target:IsDescendantOf(game) then
				EntityFlagDirectory.CanPathfind = false
				return
			end

			local Path, Status = HandlePathToTarget(Character, Target, false, {
				StandardPathfindSettings = SpecialAgentParameters,
				Visualize = false,
				Tracking = true
			})

			if not Path or Status == Enum.PathStatus.NoPath then
				EntityFlagDirectory.CanPathfind = false
				task.delay(0.1, StartPathfinding, Target, Character, false)
				return
			end

			local Waypoints = Path:GetWaypoints()
			local InternalLastPosition = HumanoidRootPart.Position
			local FinishedPathing = false

			for i, Waypoint in ipairs(Waypoints) do
				if MyToken ~= EntityFlagDirectory.LastPathRefToken then return end
				if not Target or not Target:IsDescendantOf(game) then HandleEntityStop(Character) return end

				if i < EntityFlagDirectory.SkipServerPathWaypoints and #Waypoints >= EntityFlagDirectory.SkipServerPathWaypoints then
					if Waypoint.Action == Enum.PathWaypointAction.Jump then
						AttemptEntityJump(Humanoid)
					end
					continue
				end

				local StartTime = tick()
				Humanoid:MoveTo(Waypoint.Position)

				while task.wait(1) do
					if MyToken ~= EntityFlagDirectory.LastPathRefToken then return end
					if not Target or not Target:IsDescendantOf(game) then HandleEntityStop(Character) return end

					local ElapsedTime = tick() - StartTime
					local DistanceMoved = (HumanoidRootPart.Position - InternalLastPosition).Magnitude

					if DistanceMoved > EntityFlagDirectory.PathDistanceThreshold then
						break
					end

					if ElapsedTime > EntityFlagDirectory.PathStuckThreshold then
						warn("Entity:", Character.Name, "might be stuck, retrying MoveTo")
						Humanoid:MoveTo(Waypoint.Position)
						StartTime = tick()
					end
				end

				InternalLastPosition = HumanoidRootPart.Position

				if i == #Waypoints then
					FinishedPathing = true
					HandleEntityStop(Character)
				end
			end

			LastComputeID.Value = TargetID

			if MyToken == EntityFlagDirectory.LastPathRefToken or FinishedPathing then
				EntityFlagDirectory.CanPathfind = false
			end
		end)
	end

	local function ChooseByRanged(IsRanged, RangedVal, MeleeVal)
		return IsRanged and RangedVal or MeleeVal
	end

	local function CheckIfMeetsCombatConditions(Mode, ValueA, ValueB)
		if Mode == "StrafeCheck" then
			local WithinRange = ValueA < UnitRange.Value
			local HighIntel = Intelligence.Value >= 100
			local CanAttack = AttackBool.Value == true
			if ValueA > ValueB and WithinRange and HighIntel and CanAttack then
				return true
			end
		elseif Mode == "BackupCheck" then
			if ValueA < ValueB then
				return true
			end
		end

		return false
	end

	local function GetValidBackupDirection(RootPos, TargetPos, IsRanged, RangeVal, Character)
		local BackupDir = (RootPos - TargetPos).Unit
		if NPCModule.IsDirectionObstructed(RootPos, BackupDir, RangeVal, Character) then
			local Right = HumanoidRootPart.CFrame.RightVector
			local Offset = ChooseByRanged(IsRanged, Right, Right / 2)
			local Alternatives = {
				-Offset.Unit,
				Offset.Unit,
				(BackupDir - Offset).Unit,
				(BackupDir + Offset).Unit,
			}
			for _, Dir in ipairs(Alternatives) do
				if not NPCModule.IsDirectionObstructed(RootPos, Dir, RangeVal, Character) then
					return Dir
				end
			end
		end
		return BackupDir
	end

	local function SelectCombatMovement(Target, Chance, DivValue, Exclude)
		if not Target or not Character then return end

		local PhysDist = (Target.Position - HumanoidRootPart.Position).Magnitude
		local CloseRange = UnitRange.Value / DivValue

		if AIType.Value == "Normal" then
			if CheckIfMeetsCombatConditions("StrafeCheck", PhysDist, CloseRange) then
				local StrafeDir = NPCModule.GetRandomStrafeDirection().Vector
				local MoveDir = ChooseByRanged(IsRanged.Value, StrafeDir, StrafeDir / EntityFlagDirectory.MeleeStrafeFactor)
				EntityFlagDirectory.IsStrafing = true
				EntityFlagDirectory.IsBackingUp = false
				task.spawn(PlayCombatLines)
				task.defer(NPCModule.AttemptStrafe, Character, Humanoid, HumanoidRootPart, Intelligence, MoveDir, RegularSpeed, HandlePathToTarget)
			elseif CheckIfMeetsCombatConditions("BackupCheck", PhysDist, CloseRange) then
				local BackupDir = GetValidBackupDirection(HumanoidRootPart.Position, Target.Position, IsRanged.Value, ChooseByRanged(IsRanged.Value, EntityFlagDirectory.RangedBackupRCDistance, EntityFlagDirectory.MeleeBackupRCDistance), Character)
				EntityFlagDirectory.IsStrafing = false
				EntityFlagDirectory.IsBackingUp = true
				task.spawn(PlayMiscLines)
				task.defer(NPCModule.AttemptStrafe, Character, Humanoid, HumanoidRootPart, Intelligence, BackupDir, RegularSpeed, HandlePathToTarget)
			else
				EntityFlagDirectory.IsStrafing = false
				EntityFlagDirectory.IsBackingUp = false
				EntityFlagDirectory.CanPathfind = false
				task.defer(StartPathfinding, Target, Character, false)
			end
		elseif AIType.Value == "Camper" then
			if DefensiveSpot then
				task.defer(HandlePathToTarget, Character, DefensiveSpot, false, {Tracking = false, Visualize = false})
			end
		end

		if EntityFlagDirectory.CanJump and NewRandom:NextInteger(1, Chance) == 1 then
			AttemptEntityJump(Humanoid)
		end
	end

	local function HandleAttack(JumpChance, DivValue)
		local Direction = (Target.Value.Position - HumanoidRootPart.Position).Unit	
		task.defer(function()
			NPCModule.RetryRaycastAsync(
				{ "IgnoreSameTeam", HumanoidRootPart.Position, Direction, 5000, Character },
				4,           -- MaxAttempts
				0.05,         -- Delay
				function(Hit, Pos)
					if Hit and Hit.Parent and NPCModule.CheckIfEnemy(Hit.Parent, TEAM.Value) then

						if AIType.Value == "Camper" then
							if DefensiveSpot ~= nil and Target then
								if not FearChecks.EntityIsCrying.Value and not FearChecks.EntityIsVomitting.Value and not EmptyAmmunition.Value then
									if CamperSettings:FindFirstChild("CanAttackWhileTravelling").Value then
										AttackBool.Value = true
										task.defer(SelectCombatMovement,Target.Value, JumpChance, DivValue, false)
										return
									elseif (DefensiveSpot.Position - Character.PrimaryPart.Position).Magnitude <= CamperSettings:FindFirstChild("GuardNodeDistance").Value then
										AttackBool.Value = true
										task.defer(SelectCombatMovement,Target.Value, JumpChance, DivValue, false)
										return
									else
										task.defer(SelectCombatMovement,Target.Value, JumpChance, DivValue, false)
										task.delay(2, function()
											AttackBool.Value = false
										end)
										return
									end
								end
							end
						end

						if not FearChecks.EntityIsCrying.Value and not FearChecks.EntityIsVomitting.Value and not EmptyAmmunition.Value then
							AttackBool.Value = true
							task.defer(SelectCombatMovement,Target.Value, JumpChance, DivValue, false)
						end

					else
						task.delay(2, function()
							AttackBool.Value = false
						end)
					end
				end
			)
		end)
	end

	local function CreateEntityCombatLogic(SetTarget)
		if not SetTarget then
			--warn("No target provided.")
			return
		end

		Humanoid.WalkSpeed = RegularSpeed.Value

		local MaxHealth = Humanoid.MaxHealth
		local CurrentHealth = Humanoid.Health
		local MissingHpRatio = (MaxHealth - CurrentHealth) / MaxHealth
		local IntelligenceMultiplier = 1 + ((Intelligence.Value - 100) / 200)
		local MissingHPAdjustment = math.floor(MissingHpRatio * EntityFlagDirectory.JumpChanceDecreaseCap)
		local RawJumpChance = (EntityFlagDirectory.BaseCombatJumpChance - MissingHPAdjustment) * IntelligenceMultiplier
		local AdjustedJumpChance = math.max(1, RawJumpChance)		
		local TargetTeam = SetTarget.Parent and SetTarget.Parent:FindFirstChild("TEAM", true)
		local DivisionFactor = IsRanged.Value and NewRandom:NextInteger(4, 5) or 2.5
		local RangeLimit = UnitRange.Value
		local CloseRange = RangeLimit / DivisionFactor
		local DistanceToTarget = (SetTarget.Position - HumanoidRootPart.Position).Magnitude

		if not TargetTeam or TargetTeam.Value == TEAM.Value then
			warn("Target is not an enemy.")
			return
		end

		local function ResetFlags()
			EntityFlagDirectory.IsBackingUp = false
			EntityFlagDirectory.IsStrafing = false
		end

		local function AttemptDisengage()
			ResetFlags()
			if not FearChecks.EntityInFear.Value then
				task.delay(1, function()
					AttackBool.Value = false
				end)
			end
		end

		ResetFlags()

		if AIType.Value == "Camper" then

			task.defer(HandleAttack, AdjustedJumpChance, DivisionFactor)

			if DistanceToTarget < RangeLimit and CamperSettings:FindFirstChild("CanAttackWhileTravelling").Value then
				RegularSpeed.Value = 0
			else
				RegularSpeed.Value = ReadOnlySpeed.Value
			end

		elseif IsRanged.Value and AIType.Value ~= "Camper" or not SpecialConditions:FindFirstChild("EntityIsMedic") then
			if DistanceToTarget < RangeLimit and DistanceToTarget > CloseRange then
				task.defer(HandleAttack, AdjustedJumpChance, DivisionFactor)
			elseif DistanceToTarget <= CloseRange then
				task.defer(HandleAttack, AdjustedJumpChance, DivisionFactor)
			elseif DistanceToTarget > RangeLimit then
				AttemptDisengage()
			end
		else
			if DistanceToTarget > math.round(RangeLimit / DivisionFactor) and DistanceToTarget < RangeLimit and AIType.Value ~= "Camper" or not SpecialConditions:FindFirstChild("EntityIsMedic") then
				task.defer(HandleAttack, AdjustedJumpChance, DivisionFactor)
			elseif DistanceToTarget < math.round(RangeLimit / DivisionFactor) then
				task.defer(HandleAttack, AdjustedJumpChance, DivisionFactor)
			elseif DistanceToTarget > RangeLimit then
				AttemptDisengage()
			end
			task.spawn(PlayCombatLines)
		end

		if MovingBackwards and Strafing then
			MovingBackwards.Value = EntityFlagDirectory.IsBackingUp
			Strafing.Value = EntityFlagDirectory.IsStrafing
		end
	end

	-- [[ Node Logic ]]

	local function HasReachedStarPoint(Waypoint, Threshold)
		return (HumanoidRootPart.Position - Waypoint.Position).Magnitude <= (Threshold or EntityFlagDirectory.AS_CommitRadius)
	end

	local function CollectWaypoints()
		EntityFlagDirectory.AS_Waypoints = {}

		if not AS_PathFolder then
			warn("No Waypoints Folder found.")
			return
		end

		for _, Waypoint in ipairs(AS_PathFolder:GetChildren()) do
			if Waypoint:IsA("Part") then
				EntityFlagDirectory.AS_Waypoints[#EntityFlagDirectory.AS_Waypoints + 1] = Waypoint
				if ASEntitySettings:FindFirstChild("PathDebugging").Value and not Waypoint:FindFirstChild("Highlight") then
					local Highlight = Instance.new("Highlight")
					Highlight.Parent = Waypoint
					Highlight.FillColor = Color3.fromRGB(0, 255, 0)
				end
			end
		end
		print(#EntityFlagDirectory.AS_Waypoints)
	end

	local function Heuristic(Node, Goal)
		local BaseCost = (Node.Position - Goal.Position).Magnitude

		if EntityFlagDirectory.AS_VisitedWaypointSet[Node] then
			BaseCost += 20
		end

		return BaseCost
	end

	local function GetLowestFScore(Set, FScore)
		local LowestNode = nil
		local LowestScore = math.huge

		for _, Node in ipairs(Set) do
			local Score = FScore[Node]
			if Score and Score < LowestScore then
				LowestScore = Score
				LowestNode = Node
			end
		end

		return LowestNode
	end

	local function ReconstructPath(CameFrom, Current)
		local TotalPath = table.create(10) 

		while Current do
			table.insert(TotalPath, 1, Current) 
			Current = CameFrom[Current]
		end

		for _, Part in ipairs(Workspace:GetDescendants()) do
			if Part.Name == "A_STAR_PATH_POINT" then
				Part:Destroy()
			end
		end

		if ASEntitySettings:FindFirstChild("PathDebugging").Value then
			for _, Waypoint in ipairs(TotalPath) do
				local Part = Instance.new("Part")
				Part.Name = "A_STAR_PATH_POINT"
				Part.Size = Vector3.new(1, 5, 1)
				Part.Color = Color3.fromRGB(255, 0, 0)
				Part.Position = Waypoint.Position
				Part.Anchored = true
				Part.CanCollide = false
				Part.Parent = Workspace
			end
		end

		return TotalPath
	end

	local function GetNeighbors(Node)
		local Neighbors = {}
		local NodePosition = Node.Position

		for _, Waypoint in ipairs(EntityFlagDirectory.AS_Waypoints) do
			if Waypoint ~= Node then
				local Distance = (Waypoint.Position - NodePosition).Magnitude
				if Distance < 70 and not Neighbors[Waypoint] and not EntityFlagDirectory.AS_VisitedWaypointSet[Waypoint] then
					Neighbors[#Neighbors + 1] = Waypoint
				end
			end
		end

		return Neighbors
	end

	local function FindBestStartingWaypoint(SetTarget)
		local NPCPosition = HumanoidRootPart.Position
		local BestWaypoint = nil
		local BestDistance = math.huge

		for _, Waypoint in ipairs(EntityFlagDirectory.AS_Waypoints) do
			local Distance = (Waypoint.Position - NPCPosition).Magnitude

			if Distance < BestDistance and Distance > 5 and (Waypoint.Position - SetTarget.Position).Magnitude < (NPCPosition - SetTarget.Position).Magnitude then
				BestDistance = Distance
				BestWaypoint = Waypoint
			end
		end

		return BestWaypoint
	end

	local function AStar(Start, Goal)
		local OpenSet = {[Start] = true}
		local ClosedSet = {}
		local CameFrom = {}
		local GScore = {[Start] = 0}
		local FScore = {[Start] = Heuristic(Start, Goal)}

		local function GetLowestFScore()
			local LowestNode = nil
			local LowestScore = math.huge
			for Node in pairs(OpenSet) do
				if FScore[Node] and FScore[Node] < LowestScore then
					LowestScore = FScore[Node]
					LowestNode = Node
				end
			end
			return LowestNode
		end


		while next(OpenSet) do
			local Current = GetLowestFScore()

			if not Current then
				warn("Pathfinding failed: No valid node found!")
				return nil
			end

			if Current == Goal then
				return ReconstructPath(CameFrom, Current)
			end

			OpenSet[Current] = nil
			ClosedSet[Current] = true

			for _, Neighbor in ipairs(GetNeighbors(Current)) do
				if not ClosedSet[Neighbor] then
					local TentativeGScore = GScore[Current] + (Neighbor.Position - Current.Position).Magnitude

					if CameFrom[Current] == Neighbor then
						TentativeGScore = TentativeGScore + 15
					end

					if not GScore[Neighbor] or TentativeGScore < GScore[Neighbor] then
						CameFrom[Neighbor] = Current
						GScore[Neighbor] = TentativeGScore
						FScore[Neighbor] = TentativeGScore + Heuristic(Neighbor, Goal)

						if not OpenSet[Neighbor] then
							OpenSet[Neighbor] = true
						end
					end
				end
			end
		end

		warn("No path found!")
		return nil
	end

	local function MoveNodeEntity(SetTarget)
		if not EntityFlagDirectory.AS_Path or #EntityFlagDirectory.AS_Path < 2 then return end 

		ASEntitySettings:FindFirstChild("IsEntityMoving").Value = true
		ASEntitySettings:FindFirstChild("CommitToPath").Value = true

		coroutine.wrap(function()
			for i, Waypoint in ipairs(EntityFlagDirectory.AS_Path) do
				if not ASEntitySettings:FindFirstChild("IsEntityMoving").Value then return end

				print("Moving to Waypoint:", Waypoint.Name, Waypoint.Position)

				local Retries = 0
				local MaxRetries = 3
				local Reached = false
				local CommitRadius = EntityFlagDirectory.AS_CommitRadius or 5

				repeat
					HandlePathToTarget(Character, Waypoint.Position, false, { Tracking = false, Visualize = false})
					local StartTime = os.clock()

					repeat
						task.wait(ASEntitySettings:FindFirstChild("ReachUntilTime").Value)
						local dist = (HumanoidRootPart.Position - Waypoint.Position).Magnitude
						print("Distance to", Waypoint.Name, ":", dist)
					until HasReachedStarPoint(Waypoint, CommitRadius) or (os.clock() - StartTime) > 3

					Reached = HasReachedStarPoint(Waypoint, CommitRadius)
					Retries += 1
				until Reached or Retries >= MaxRetries

				if not Reached then
					warn("Failed to reach waypoint after retries:", Waypoint.Name)
				end
			end

			if SetTarget then
				HandlePathToTarget(Character, SetTarget.Position, false, { Tracking = false, Visualize = false})
				local Success = Humanoid.MoveToFinished:Wait(3)

				if not Success then
					warn("Final move failed, retrying...")
					HandlePathToTarget(Character, SetTarget.Position, false, { Tracking = false, Visualize = false})
					Humanoid.MoveToFinished:Wait(3)
				end
			end

			ASEntitySettings:FindFirstChild("IsEntityMoving").Value = false
			ASEntitySettings:FindFirstChild("CommitToPath").Value = false
		end)()
	end

	local function FindClosestWaypoint(Position)
		local Closest, ClosestDist = nil, math.huge
		for _, Waypoint in ipairs(EntityFlagDirectory.AS_Waypoints) do
			local Dist = (Waypoint.Position - Position).Magnitude
			if Dist < ClosestDist then
				ClosestDist = Dist
				Closest = Waypoint
				if ClosestDist < 1 then break end
			end
		end
		return Closest
	end

	local function FindNextWaypoint(CurrentWaypoint, Goal)
		local BestWaypoint = nil
		local BestDistance = math.huge

		for _, Waypoint in ipairs(EntityFlagDirectory.AS_Waypoints) do
			if Waypoint ~= CurrentWaypoint then
				local DistanceToGoal = (Waypoint.Position - Goal.Position).Magnitude
				local DistanceToCurrent = (Waypoint.Position - CurrentWaypoint.Position).Magnitude

				if DistanceToGoal < BestDistance and DistanceToCurrent > 5 then
					BestDistance = DistanceToGoal
					BestWaypoint = Waypoint
				end
			end
		end

		return BestWaypoint or CurrentWaypoint
	end

	local function UpdatePath(Force, SetTarget)
		if not Force and (ASEntitySettings:FindFirstChild("CheckForRecalculation").Value  or os.clock() - EntityFlagDirectory.AS_LastRecalculationTime < ASEntitySettings:FindFirstChild("RecalculationCooldown").Value  or os.clock() - EntityFlagDirectory.AS_LastRecalculationTime < ASEntitySettings:FindFirstChild("MinPathLifetime").Value) then
			return
		end

		ASEntitySettings:FindFirstChild("CheckForRecalculation").Value  = true
		EntityFlagDirectory.AS_LastRecalculationTime = os.clock()

		local Start = FindBestStartingWaypoint(SetTarget)
		local Goal = FindClosestWaypoint(SetTarget.Position)

		if Start and Goal then
			local NewPath = AStar(Start, Goal)

			if NewPath then
				EntityFlagDirectory.AS_Path = NewPath
				MoveNodeEntity(SetTarget)
			else
				EntityFlagDirectory.AS_Path = {SetTarget}
				MoveNodeEntity(SetTarget)
			end
		end

		ASEntitySettings:FindFirstChild("CheckForRecalculation").Value = false
	end

	local function TrackTarget(SetTarget)
		if EntityFlagDirectory.AS_TrackingThread then return end
		if ASEntitySettings:FindFirstChild("CommitToPath").Value and ASEntitySettings:FindFirstChild("IsEntityMoving").Value then return end

		EntityFlagDirectory.AS_TrackingThread = game:GetService("RunService").Heartbeat:Connect(function()
			if SetTarget then
				local TargetPosition = SetTarget.Position
				local NPCPosition = HumanoidRootPart.Position

				if os.clock() - EntityFlagDirectory.AS_LastRecalculationTime > 1 or (TargetPosition - EntityFlagDirectory.AS_LastTargetPosition).Magnitude > 2 then
					EntityFlagDirectory.AS_LastTargetPosition = TargetPosition
					UpdatePath(false, SetTarget)
				end

				if os.clock() - EntityFlagDirectory.AS_LastRecalculationTime > 3 then
					UpdatePath(true, SetTarget)
				end
			end
		end)
	end

	local function OnTargetSet(NewTarget)
		if not NewTarget then return end
		if ASEntitySettings:FindFirstChild("CommitToPath").Value and ASEntitySettings:FindFirstChild("IsEntityMoving").Value then return end

		EntityFlagDirectory.AS_LastTargetPosition = NewTarget.Position
		UpdatePath(false, NewTarget)

		if not EntityFlagDirectory.AS_TrackingThread then
			TrackTarget(NewTarget)
		end
	end

	-- [[ Death Logic ]]

	local function UpdateDamageTable(Humanoid, DamageDealt)
		local Creator = Humanoid:FindFirstChild("creator")
		if Creator and Creator.Value and Creator.Value:IsA("Player") then
			local Player = Creator.Value
			EntityFlagDirectory.DamageTable[Player] = (EntityFlagDirectory.DamageTable[Player] or 0) + DamageDealt
		end
	end

	local function CalculateRewards(DamagePercentage, BaseEXP, BaseCoins)
		local CoinsReward = math.floor((DamagePercentage / 100) * BaseCoins)
		local EXPReward = math.floor((DamagePercentage / 100) * BaseEXP)
		return CoinsReward, EXPReward
	end

	local function DistributeRewards(TopDamager, TotalDamage, DifficultyMultiplier)
		local VictimName = Character.Name

		local BaseEXP = Character:GetAttribute("XPGivenOnDeath") 
			or math.floor(Humanoid.MaxHealth / EntityFlagDirectory.REWARD_DIVISOR_XP)
		BaseEXP = math.floor(BaseEXP * DifficultyMultiplier)

		local BaseCoins = Character:GetAttribute("CoinsGivenOnDeath") 
			or math.floor(math.clamp(Humanoid.MaxHealth / EntityFlagDirectory.REWARD_DIVISOR_XP, EntityFlagDirectory.MIN_COINS, EntityFlagDirectory.MAX_COINS))
		BaseCoins = math.floor(BaseCoins * DifficultyMultiplier)

		for Player, Damage in pairs(EntityFlagDirectory.DamageTable) do
			local DamagePercentage = (Damage / TotalDamage) * 100
			local CoinsReward, EXPReward = CalculateRewards(DamagePercentage, BaseEXP, BaseCoins)

			local Leaderstats = Player:FindFirstChild("leaderstats")
			if Leaderstats then
				Leaderstats.Coins.Value += CoinsReward
			end

			--RankModule.RewardEXP(Player, EXPReward)

			--ReplicatedStorage.Events.KillFeed:FireClient(Player, TopDamager.Name, VictimName, CoinsReward, EXPReward)
		end
	end

	local function GetTopDamager()
		local TopDamager = nil
		local MaxDamage = 0

		for Player, Damage in pairs(EntityFlagDirectory.DamageTable) do
			if Damage > MaxDamage then
				MaxDamage = Damage
				TopDamager = Player
			end
		end

		return TopDamager
	end

	local function CreateAttachment(Parent, Name, Position)
		local Attachment = Instance.new("Attachment")
		Attachment.Name = Name
		Attachment.Position = Position
		Attachment.Parent = Parent
		return Attachment
	end

	local function CreateLimbJoint(Torso, Limb, JointName, TorsoOffset, LimbOffset)
		if Torso:FindFirstChild(JointName) then
			warn("Joint already exists:", JointName)
			return
		end

		local A0 = CreateAttachment(Torso, JointName, TorsoOffset)
		local A1 = CreateAttachment(Limb, JointName .. "Attachment", LimbOffset)

		local Constraint = Instance.new("BallSocketConstraint")
		Constraint.Attachment0 = A0
		Constraint.Attachment1 = A1
		Constraint.Parent = Torso
	end

	local function EnableRagdoll()

		if RightArm:FindFirstChild("RightGrip") then
			RightArm:FindFirstChild("RightGrip"):Destroy()
		end

		local function IsValidLimb(Joint)
			return Joint.Limb and Joint.Limb:IsA("BasePart")
		end

		local function UnanchorAndConfigure(Part)
			Part.Anchored = false
			if Part.Name ~= "Head" then
				Part.CanCollide = true
			end
			if Part:CanSetNetworkOwnership() then
				Part:SetNetworkOwner(nil)
			end
		end

		local function AddRandomMotion(Part)
			local Rng = Random.new()
			Part.AssemblyAngularVelocity += Vector3.new(Rng:NextNumber(-30,30), Rng:NextNumber(-30,30), Rng:NextNumber(-30,30))
			Part.AssemblyLinearVelocity += Vector3.new(Rng:NextNumber(-15,15), Rng:NextNumber(-15,15), Rng:NextNumber(-15,15))
		end

		-- Step 1: Create joints
		for _, Joint in ipairs(JointConfigs) do
			if IsValidLimb(Joint) then
				CreateLimbJoint(Torso, Joint.Limb, Joint.Name, Joint.TorsoOffset, Joint.LimbOffset)
			else
				warn("Invalid limb for:", Joint.Name)
			end
		end

		for _, Inst in ipairs(Character:GetDescendants()) do
			if Inst:IsA("Motor6D") or Inst:IsA("Weld") or Inst:IsA("WeldConstraint") then
				Inst:Destroy()
			elseif Inst:IsA("BasePart") then
				UnanchorAndConfigure(Inst)
			end
		end

		local BodyParts = {LeftArm, RightArm, LeftLeg, RightLeg, Torso, Head}
		for _, Part in ipairs(BodyParts) do
			AddRandomMotion(Part)
		end
	end

	local function DisableRagdoll()
		if not EntityFlagDirectory.EntityRagdollState then return end

		EntityFlagDirectory.EntityRagdollState = false
		Humanoid.PlatformStand = false

		for _, Descendant in pairs(Character:GetDescendants()) do
			if Descendant:IsA("BallSocketConstraint") or Descendant:IsA("Attachment") then
				Descendant:Destroy()
			elseif Descendant:IsA("Motor6D") then
				Descendant.Enabled = true
			end
		end
	end

	local function ApplyEuphoriaForces()
		if not EntityFlagDirectory.EntityRagdollState then return end
		if EntityFlagDirectory.EntityHasGibbed then return end

		local LookVector = Torso.CFrame.LookVector

		local Parts = {
			{Part = Character:FindFirstChild("Left Leg"),  Multiplier = -1, Type = EntityFlagDirectory.EuphoriaForceMultiplier.Legs},
			{Part = Character:FindFirstChild("Right Leg"), Multiplier = -1, Type = EntityFlagDirectory.EuphoriaForceMultiplier.Legs},
			{Part = Character:FindFirstChild("Left Arm"),  Multiplier = 1, Type = EntityFlagDirectory.EuphoriaForceMultiplier.Arms},
			{Part = Character:FindFirstChild("Right Arm"), Multiplier = 1, Type = EntityFlagDirectory.EuphoriaForceMultiplier.Arms},
			{Part = Torso, Multiplier = 1, Type = EntityFlagDirectory.EuphoriaForceMultiplier.Torso}
		}

		for _, Data in pairs(Parts) do
			if Data.Part then
				local Force = LookVector * NewRandom:NextNumber(Data.Type.Min, Data.Type.Max) * Data.Multiplier
				Data.Part.AssemblyLinearVelocity += Force
				Data.Part.AssemblyAngularVelocity += Force
			end
		end

		task.wait(0.1)

		for _, Data in pairs(Parts) do
			if Data.Part then
				local Force = LookVector * NewRandom:NextNumber(Data.Type.Min, Data.Type.Max) * -Data.Multiplier
				Data.Part.AssemblyLinearVelocity += Force
			end
		end
	end

	local function MonitorMovement()
		local AccumulatedTime = 0
		local Interval = 0.5
		local Connection = nil

		Connection = RunService.Heartbeat:Connect(function(DeltaTime)

			if not Humanoid or Humanoid.RigType ~= Enum.HumanoidRigType.R6 or not EntityFlagDirectory.EntityRagdollState then
				if Connection then Connection:Disconnect() end
				return
			end

			AccumulatedTime += DeltaTime
			if AccumulatedTime < Interval then return end
			AccumulatedTime = 0

			local PositionDelta = (Torso.Position - PreviousTorsoPosition).Magnitude
			if PositionDelta > 5 then
				ApplyEuphoriaForces()
			end

			PreviousTorsoPosition = Torso.Position

		end)
	end

	local function TweenDecay(Entity, TargetColor, TweenDuration)
		local BodyParts = {}
		local ProcessedParts = {}

		for _, Part in ipairs(Entity:GetDescendants()) do
			if Part:IsA("BasePart") then
				table.insert(BodyParts, Part)
			end
		end

		if #BodyParts == 0 then return end

		while #ProcessedParts < #BodyParts do
			task.wait(NewRandom:NextInteger(2, 6))

			local RandomObject
			local UnprocessedParts = {}

			-- Collect unprocessed parts
			for _, PKey in ipairs(BodyParts) do
				if not ProcessedParts[PKey] then
					table.insert(UnprocessedParts, PKey)
				end
			end

			if #UnprocessedParts == 0 then break end

			RandomObject = UnprocessedParts[math.random(1, #UnprocessedParts)]

			local TweenInformation = TweenInfo.new(TweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local PossibleMaterial = NewRandom:NextInteger(1, 3)

			if PossibleMaterial == 1 then
				RandomObject.Material = EntityFlagDirectory.DecayMaterial1
			elseif PossibleMaterial == 2 then
				RandomObject.Material = EntityFlagDirectory.DecayMaterial2
			else
				RandomObject.Material = EntityFlagDirectory.DecayMaterial3
			end

			ProcessedParts[RandomObject] = true

			local Tween = TweenService:Create(RandomObject, TweenInformation, { Color = TargetColor })
			Tween:Play()
		end
	end

	local function FadeAndDestroyCharacter()
		for _, CharObj in ipairs(Character:GetDescendants()) do
			if CharObj:IsA("BasePart") then
				CharObj.CanCollide = false
				CharObj.Anchored = true
			end
		end

		local TweensStored = {}

		for _, CharObj in ipairs(Character:GetDescendants()) do
			if (CharObj:IsA("BasePart") or CharObj:IsA("Decal")) and CharObj.Transparency < 1 then
				local Tween = TweenService:Create(CharObj, EntityFlagDirectory.FadingTweenInfo, { Transparency = 1 })
				Tween:Play()
				table.insert(TweensStored, Tween)
			end
		end

		task.wait(EntityFlagDirectory.FadingDuration + 0.05)

		Character:Destroy()
	end

	local function GibEntityIfOverkilled(Humanoid, DamageTaken)
		if not Humanoid or not Humanoid.Parent then return end

		local HealthRemaining = Humanoid.Health
		if DamageTaken <= HealthRemaining then return end

		local Character = Humanoid.Parent
		local OverkillAmount = DamageTaken - HealthRemaining
		local BaseForce = 75
		local ForceMultiplier = math.clamp(OverkillAmount / HealthRemaining, 1, 5)
		local TotalForce = BaseForce * ForceMultiplier

		EntityFlagDirectory.EntityHasGibbed = true

		local GibbedTag = Instance.new("StringValue")
		GibbedTag.Name = "Gibbed"
		GibbedTag.Parent = Character

		for _, Part in ipairs(Character:GetChildren()) do
			if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" then
				Part.Anchored = false
				if Part.Name ~= "Head" then
					Part.CanCollide = true
				end
				Part:BreakJoints()

				if Part:CanSetNetworkOwnership() then
					Part:SetNetworkOwner(nil)
				end

				local RandomDirection = Vector3.new(
					math.random(-100, 100),
					math.random(50, 150),
					math.random(-100, 100)
				).Unit

				Part.AssemblyLinearVelocity = RandomDirection * TotalForce
				Part.AssemblyAngularVelocity = Vector3.new(
					math.random(-30, 30),
					math.random(-30, 30),
					math.random(-30, 30)
				)

				DebrisService:AddItem(Part, 10)
			end
		end
	end

	local function HandleDeathRewards()
		local TotalDamage = Humanoid.MaxHealth
		local TopDamager = GetTopDamager()

		-- Skip kill feed if no valid top damager
		if not TopDamager then
			return
		end

		--[[local Difficulty = ReplicatedStorage.Values.WaveData.Difficulty.Value
		local DifficultyMultiplier = math.clamp(Difficulty, DIFFICULTY_MIN, DIFFICULTY_MAX) * DIFFICULTY_MULTIPLIER_BASE + DIFFICULTY_MULTIPLIER_OFFSET]]

		-- Distribute rewards
		--[[DistributeRewards(TopDamager, TotalDamage, DifficultyMultiplier)]]

		-- Reset damage table
		EntityFlagDirectory.DamageTable = {}
	end

	local function SetBossDropAttributes(ItemDropScript, ItemTemplate)
		ItemDropScript:SetAttribute("BossDrop")
		ItemDropScript:SetAttribute("FillColor", ItemTemplate:GetAttribute("FillColor"))
		ItemDropScript:SetAttribute("OutlineColor", ItemTemplate:GetAttribute("OutlineColor"))
		ItemDropScript:SetAttribute("Music", ItemTemplate:GetAttribute("Music"))
	end

	local function CreateItemDrop(ItemTemplate, ItemName)

		--[[local ItemDrop = ItemTemplate.Handle:Clone()
		local ItemDropModel = Instance.new("Model")
		ItemDropModel.Name = "ItemDropModel"
		ItemDrop.Parent = ItemDropModel
		ItemDropModel.PrimaryPart = ItemDrop
		ItemDropModel:PivotTo(Head.CFrame * CFrame.new(DROP_OFFSET))
		ItemDropModel.Parent = DebrisFolder

		local ItemDropScript = ServerStorage.Misc.ItemDropScript:Clone()
		ItemDropScript.ItemValue.Value = ItemName
		ItemDropScript.Parent = ItemDrop
		ItemDropScript.Enabled = true

		return ItemDropScript]]

	end

	local function DropItem() 
		if not (Head and DeathSettings:FindFirstChild("ItemToDrop")) then
			return
		end

		local ItemName = DeathSettings.ItemToDrop.Value
		local ItemTemplate = ServerStorage.Items:FindFirstChild(ItemName, true)

		if not (ItemTemplate and ItemTemplate:FindFirstChild("Handle")) then
			return
		end

		local MinChance = DeathSettings.ItemToDrop.MinChance.Value
		local MaxChance = DeathSettings.ItemToDrop.MaxChance.Value

		if NewRandom:NextInteger(MinChance, MaxChance) ~= MinChance then
			return
		end

		local ItemDropScript = CreateItemDrop(ItemTemplate, ItemName)

		if ItemTemplate:GetAttribute("BossDrop") then
			SetBossDropAttributes(ItemDropScript, ItemTemplate)
		end

		if ItemTemplate:GetAttribute("FillColor") then
			ItemDropScript.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			ItemDropScript.Highlight.FillColor = ItemTemplate:GetAttribute("FillColor")
			ItemDropScript.Highlight.OutlineColor = ItemTemplate:GetAttribute("OutlineColor")

			--[[ReplicatedStorage.Events.HeroMorphed:FireAllClients(
				Character.Name, 
				ItemTemplate.Name, 
				"BossDrop2", 
				ItemTemplate:GetAttribute("FillColor"), 
				ItemTemplate:GetAttribute("OutlineColor")
			)]]
		end
	end

	local function SetDeathEffectProperties(Part)
		Part.Velocity = Vector3.new(
			NewRandom:NextNumber(EntityFlagDirectory.VELOCITY_MIN, EntityFlagDirectory.VELOCITY_MAX), 
			NewRandom:NextNumber(EntityFlagDirectory.UPWARD_VELOCITY_MIN, EntityFlagDirectory.UPWARD_VELOCITY_MAX), 
			NewRandom:NextNumber(EntityFlagDirectory.VELOCITY_MIN, EntityFlagDirectory.VELOCITY_MAX)
		)
		Part.Material = Enum.Material.CorrodedMetal
		Part.BrickColor = BrickColor.new("Black")
		if Part.Name ~= "Head" then
			Part.CanCollide = true
		end
	end

	local function HandleSpecialDeathEffects()
		local DeathSettings = DeathSettings
		if not DeathSettings then return end

		local DeathType = DeathSettings:FindFirstChild("DeathType") and DeathSettings.DeathType.Value
		if DeathType ~= "VehicleExplosion" then return end

		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		for _, Part in pairs(Character:GetDescendants()) do
			if Part:IsA("BasePart") then
				SetDeathEffectProperties(Part)
			elseif Part:IsA("ParticleEmitter") or Part:IsA("PointLight") then
				if Part:FindFirstChild("EnableOnDeath") then
					Part.Enabled = true
				elseif Part:FindFirstChild("DisableOnDeath") then
					Part.Enabled = false
				end
			end
		end

		-- Explosion effect
		if Head then
			local Explosion = Instance.new("Explosion")
			Explosion.BlastRadius = 0
			Explosion.DestroyJointRadiusPercent = 0
			Explosion.ExplosionType = Enum.ExplosionType.NoCraters
			Explosion.Position = Head.Position
			Explosion.Parent = DebrisFolder
		end
	end

	-- [[ Humanoid Events ]]

	Humanoid.BreakJointsOnDeath = false

	Humanoid.Seated:Connect(function()
		task.delay(1, function()
			Humanoid.Jump = true
		end)
	end)

	Humanoid.Died:Connect(function()
		if EntityFlagDirectory.HasDied then
			return
		end

		EntityFlagDirectory.HasDied = true

		local DeathTag = Instance.new("IntValue")
		DeathTag.Name = "Dead"
		DeathTag.Parent = Character

		if TEAM.Value == "Noob" and not Character:FindFirstChild("Gibbed") then
			local DownedTag = Instance.new("StringValue")
			DownedTag.Name = "Downed"
			DownedTag.Parent = Character
		end

		if Character.Name == "Inferno" then
			local RandomDeathSound = "Death" .. Random.new():NextInteger(1, 6)
			if Head:FindFirstChild(RandomDeathSound) then
				Head[RandomDeathSound]:Play()
			end
		elseif Sounds.DeathSound then
			Sounds.DeathSound:Play()
		end

		task.defer(function()
			SetCollisionGroup(Character, "NPCRagdoll")
			DropItem()
			HandleSpecialDeathEffects()
			HandleEntityStop(Character)
			HandleDeathRewards()
			if not EntityFlagDirectory.EntityHasGibbed then
				EnableRagdoll()
			end
		end)

		--BloodEvent:FireAllClients(BloodSettings, HumanoidRootPart, nil, DefaultBloodEmitAmmount, UseBloodTimeDestroy, TimeBeforeBloodDestroy)

		task.delay(EntityFlagDirectory.TimeBeforeDecay, function() TweenDecay(Character, EntityFlagDirectory.DecayColor, EntityFlagDirectory.DecayDuration) end)

		for _ = 1, NewRandom:NextInteger(1, 10) do
			ApplyEuphoriaForces()
			task.wait(NewRandom:NextNumber(0, 2))
		end

		task.delay(EntityFlagDirectory.TimeBeforeCharacterDestroy, function() 
			task.defer(FadeAndDestroyCharacter) 
		end)
	end)

	Humanoid.HealthChanged:Connect(function()
		task.defer(PlayHurtSound)
		local CurrentHealth = Humanoid.Health
		local DamageDealt = PreviousHealth - CurrentHealth
		task.defer(UpdateDamageTable, Humanoid, DamageDealt)
		if CurrentHealth < 0 and DamageDealt > PreviousHealth and DamageDealt ~= Humanoid.MaxHealth and not EntityFlagDirectory.EntityHasGibbed then
			task.defer(GibEntityIfOverkilled, Humanoid, DamageDealt)
		end
		PreviousHealth = CurrentHealth
	end)

	-- [[ General Logic ]]

	AttackBool.Changed:Connect(function(NewValue)
		if NewValue == true then
			EntityFlagDirectory.LastTimeWhenAtkTrue = tick()
		end
	end)

	local function CheckRecentATKBoolean()
		local CurrentTickTime = tick()
		return (CurrentTickTime - EntityFlagDirectory.LastTimeWhenAtkTrue <= EntityFlagDirectory.CloseATKTrueWindowTime)
	end

	local function HandleTargeting()
		if not Character then return end
		local TargetObject = Target.Value
		if not Target then return end
		if MovingBackwards and MovingBackwards.Value then return end
		if IsRanged.Value and AttackBool.Value then return end

		local ForceManualRecomputation = CheckRecentATKBoolean()
		task.defer(StartPathfinding, TargetObject, Character, ForceManualRecomputation)
	end

	local function EntityLoop()
		if EntityFlagDirectory.EntityPathfindingCallsign then return end
		if SpecialConditions:FindFirstChild("EntityIsMedic") then return end
		if AIType.Value == "Camper" then return end

		EntityFlagDirectory.EntityPathfindingCallsign = true

		task.defer(function()
			while task.wait(EntityFlagDirectory.PathfindingProcessingSpeed) do
				task.defer(HandleTargeting)
			end
		end)
	end

	local function IsNonHumanoidHit(instance)
		local ancestor = instance:FindFirstAncestorOfClass("Model")
		if not ancestor then return true end
		return not ancestor:FindFirstChildOfClass("Humanoid")
	end

	local function ProcessJumpRequests()
		while true do
			task.wait(0.25)
			if #PendingJumpHumanoids > 0 then
				for _, humanoid in ipairs(PendingJumpHumanoids) do
					AttemptEntityJump(humanoid)
				end
				table.clear(PendingJumpHumanoids)
			end
		end
	end

	coroutine.wrap(ProcessJumpRequests)()

	local function ShouldJumpObstacle(HRP, Humanoid, Character)
		local position = HRP.Position
		local lookVector = HRP.CFrame.LookVector * 3
		local hitCount = 0

		for i = 1, #JumpOffsets do
			if hitCount >= 2 then break end

			local offset = JumpOffsets[i]
			local origin = position + offset
			local result = Workspace:Raycast(origin, lookVector, JumpConditionParameters)

			if result and IsNonHumanoidHit(result.Instance) then
				hitCount += 1
			end
		end

		if hitCount >= 2 then
			table.insert(PendingJumpHumanoids, Humanoid)
		end
	end

	--@Administrat0rROBL0X: Things to do.
	-- TODO#1: Have the entities not talk to each other again and again.
	-- TODO#2: Have the entities tween to look to each other instead of a fucking snap and anchor.
	-- TODO#3: It must be doing a all-time check so if it happens when the entity is mid-air it doesn't keep a weird angle.

	task.defer(function()
		PlaySpawnVoiceline()
		SetupEntityDifficulty(Character, TEAM)
		HandleNPCItems(Character, UVSettings)
		MonitorMovement()
		--
		--[[if EntityHasSpoken == false and NoTalk.Value == false and EntitySpeakChance == 1 and AttackBool.Value == false then
			EntityHasSpoken = true

			for _, NPC in ipairs(CollectionService:GetTagged("NPC")) do
				RegisterEntityForSpeech(NPC)
			end

			CollectionService:GetInstanceAddedSignal("NPC"):Connect(RegisterEntityForSpeech)
			CollectionService:GetInstanceRemovedSignal("NPC"):Connect(UnregisterEntityFromSpeech)
		end]]
	end)

	local function IsValueObject(obj)
		return obj:IsA("BoolValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")
			or obj:IsA("StringValue") or obj:IsA("ObjectValue")
	end

	local function ScanEntityCachedData()
		EntityFlagDirectory.ValueObjects = {}
		EntityFlagDirectory.BaseParts = {}

		for _, obj in ipairs(Character:GetDescendants()) do
			if IsValueObject(obj) then
				table.insert(EntityFlagDirectory.ValueObjects, obj)
			elseif obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
				table.insert(EntityFlagDirectory.BaseParts, obj)
			end
		end
	end

	local function ScanEntInitialPhysStates()
		EntityFlagDirectory.InitialHumanoidStates = {
			_WalkSpeed = Humanoid.WalkSpeed,
			_JumpPower = Humanoid.JumpPower,
		}
		EntityFlagDirectory.InitialValueStates = {}
		for _, obj in ipairs(EntityFlagDirectory.ValueObjects) do
			if obj:IsA("ValueBase") then
				EntityFlagDirectory.InitialValueStates[obj] = obj.Value
			end
		end
	end

	local function AnchorEntity(state)
		for _, part in ipairs(EntityFlagDirectory.BaseParts) do
			part.Anchored = state
		end
	end

	local function FreezeEntity()
		RuntimeStates = {}
		RuntimeStates["_WalkSpeed"] = Humanoid.WalkSpeed
		RuntimeStates["_JumpPower"] = Humanoid.JumpPower

		for _, obj in ipairs(EntityFlagDirectory.ValueObjects) do
			RuntimeStates[obj] = obj.Value

			local t = typeof(obj.Value)
			if t == "number" then
				obj.Value = 0
			elseif t == "boolean" then
				obj.Value = false
			elseif t == "string" then
				obj.Value = ""
			elseif t == "Instance" then
				obj.Value = nil
			end
		end

		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
		AnchorEntity(true)
	end

	local function UnfreezeEntity()
		for obj, value in pairs(InitialStates) do
			if obj == "_WalkSpeed" then
				Humanoid.WalkSpeed = value
			elseif obj == "_JumpPower" then
				Humanoid.JumpPower = value
			elseif obj:IsA("ValueBase") and obj:IsDescendantOf(Character) then
				obj.Value = value
			end
		end

		AnchorEntity(false)
	end

	DefensiveSpot = NPCModule.GetRandomSpot(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight)

	-- [[ Main Logic ]]

	while task.wait(EntityFlagDirectory.EntityProcessingSpeed) and Humanoid and Humanoid.Health > 0 and not Players:GetPlayerFromCharacter(Character) do

		ReplicatedStorage.disable_le_ai:GetPropertyChangedSignal("Value"):Connect(function()
			if ReplicatedStorage.disable_le_ai.Value then
				task.defer(FreezeEntity)
			else
				task.defer(UnfreezeEntity)
			end
		end)

		task.defer(ScanEntInitialPhysStates)
		task.spawn(CheckEntityState)
		task.defer(DetectFromNPC, Character)	
		task.defer(ShouldJumpObstacle, HumanoidRootPart, Humanoid, Character)

		task.delay(2, function()
			if Target.Value then return end

			local Core = UnitsFolder:FindFirstChild("Core")
			if Core and Core:IsA("Model") and TEAM.Value ~= "Noob" then
				if not FearChecks.EntityIsVomitting.Value and not FearChecks.EntityIsCrying.Value then
					Target.Value = Core.PrimaryPart
				end
			else
				--warn("No target yet.")
				return
			end
		end)
		

		Humanoid.WalkSpeed = (RegularSpeed.Value and RegularSpeed.Value > 0) and RegularSpeed.Value or 0

		if AIType.Value == "AllyFollower" then
			if SpecialConditions:FindFirstChild("EntityIsMedic") and not IsRanged.Value then
				local Enemy, EnemyDistance = NPCModule.FindNearestEnemyPrimaryPart(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight)
				Target.Value = Enemy
				Distance.Value = EnemyDistance
				local MinEnemyDistance = MedicSettings:FindFirstChild("MinMedicEnemyDetDistance").Value

				if not FearChecks.EntityIsCrying.Value and not FearChecks.EntityIsVomitting.Value and Target.Value and Distance.Value <= MinEnemyDistance then
					task.spawn(PlayMiscLines)
					RegularSpeed.Value = MedicSettings:FindFirstChild("MinimumSprintValue").Value
					local BackupDistance = ChooseByRanged(IsRanged.Value, EntityFlagDirectory.RangedBackupRCDistance, EntityFlagDirectory.MeleeBackupRCDistance)
					local BackupDirection = GetValidBackupDirection(HumanoidRootPart.Position, Target.Value.Position, IsRanged.Value, BackupDistance, Character)
					NPCModule.AttemptStrafe(Character, Humanoid, HumanoidRootPart, Intelligence, BackupDirection, RegularSpeed, HandlePathToTarget)
					MovingBackwards.Value = true
				else
					MovingBackwards.Value = false
				end

				if not MovingBackwards.Value then
					AllyTarget.Value, AllyTargetDistance.Value = NPCModule.FindNearestTargetToHeal(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight)	
					local SprintClamp = MedicSettings:FindFirstChild("SprintClampDivValue").Value
					local MinSprint = MedicSettings:FindFirstChild("MinimumSprintValue").Value
					local MaxSprint = MedicSettings:FindFirstChild("MaximumSprintValue").Value
					RegularSpeed.Value = math.clamp(AllyTargetDistance.Value / SprintClamp, MinSprint, MaxSprint)
				end
			end
		elseif AIType.Value == "FindTargetAlt" then

			local function NPCLifeCheck()
				if Humanoid.Health >= 0 and Character and UnitValues then
					return true
				else
					return false
				end
			end

			local function TargetLifeCheck(Target)
				if Target and Target.Parent:FindFirstChildOfClass("Humanoid") then
					return true
				elseif not Target or Target.Parent or Target.Parent:FindFirstChild("HumanoidRootPart") or Target.Parent:FindFirstChild("Humanoid").Health <= 0 then
					return false
				end
			end

			local function HandleTargetFinder()
				while task.wait() do
					local Target = NPCModule.FindNearestEnemyPrimaryPart(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight, EntityFlagDirectory.ExcludeFromFinding, Target_FavoriteTargets)
					if NPCLifeCheck() and TargetLifeCheck(Target) then
						Target.Value = Target
					else
						return
					end
				end
			end

			task.defer(function()
				HandleTargetFinder()
			end)

		elseif AIType.Value == "Waypoint" then
			task.defer(CollectWaypoints)
			while task.wait(EntityFlagDirectory.AS_TrackerUpdateTime) do
				Target.Value, Distance.Value = NPCModule.FindNearestEnemyPrimaryPart(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight, EntityFlagDirectory.ExcludeFromFinding, Target_FavoriteTargets)
				if Target.Value then
					OnTargetSet(Target.Value)
				end
			end
		elseif AIType.Value == "Camper" then
			task.spawn(function()
				if CamperSettings:FindFirstChild("CamperCanTravelNodes").Value then
					while task.wait() do
						if CamperSettings:FindFirstChild("MinTimeUntilCanChangeNode") and CamperSettings:FindFirstChild("MaxTimeUntilCanChangeNode") then
							task.wait(NewRandom:NextNumber(
								CamperSettings:FindFirstChild("MinTimeUntilCanChangeNode").Value,
								CamperSettings:FindFirstChild("MaxTimeUntilCanChangeNode").Value
								))
							DefensiveSpot = NPCModule.GetRandomSpot(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight)
						end
					end
				else
					DefensiveSpot = NPCModule.GetRandomSpot(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight)
				end
			end)
		end

		if MovingBackwards.Value == false then
			if UVSettings:FindFirstChild("Pathfinder") and UVSettings.Pathfinder.Value == true and not SpecialConditions:FindFirstChild("EntityIsMedic") then

				-- [[ Default Target Finding ]]

				Target.Value, Distance.Value = NPCModule.FindNearestEnemyPrimaryPart(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight, EntityFlagDirectory.ExcludeFromFinding, Target_FavoriteTargets)

				if Target.Value then
					local Direction = (Target.Value.Position - HumanoidRootPart.Position).Unit
					task.defer(function()
						NPCModule.RetryRaycastAsync(
							{ "Normal", HumanoidRootPart.Position, Direction, UnitRange.Value, Character },
							1,           -- MaxAttempts
							0.05,         -- Delay
							function(Hit, Pos)
								if Hit and Hit.Parent and NPCModule.CheckIfEnemy(Hit.Parent, TEAM.Value) then
									EntityFlagDirectory.ExcludeFromFinding = {}
								end
							end
						)
					end)
				end

				-- [[ Ammunition Logic for Ranged Entities]]

				if not FearChecks.EntityIsCrying.Value and not FearChecks.EntityIsVomitting.Value and EmptyAmmunition and EmptyAmmunition.Value and IsRanged.Value then
					local AmmoBox = NPCModule.FindNearestAmmoBox(PrimaryPart)
					task.defer(HandleAmmoStatus)
					if AmmoBox then
						AttemptSprint("Sprint")
						task.defer(HandlePathToTarget, Character, AmmoBox.Position, false, { Tracking = true, Visualize = false })
					else
						AttemptSprint("Walk")
						local Supplier = NPCModule.FindNearestSupplier(TEAM, HumanoidRootPart)
						if Supplier then
							AttemptSprint("Sprint")
							task.defer(StartPathfinding, Supplier, Character, false)
						else
							AttemptSprint("Walk")
						end
					end
				else
					task.defer(RemoveNoAmmoLabel)
				end

				-- [[ General Entity Logic ]]

				-- Medic Finding
				if AttackBool.Value == false and not SpecialConditions:FindFirstChild("EntityIsMedic") then
					local CurrentHealthRatio = Humanoid.Health / Humanoid.MaxHealth
					local Threshold = Toughness.Value

					if CurrentHealthRatio <= Threshold then
						if CurrentSprintState ~= "Sprint" then
							AttemptSprint("Sprint")
							CurrentSprintState = "Sprint"
						end

						Target.Value, Distance.Value = NPCModule.FindNearestMedicAlly(Target_MaxDistance, Character, Target_MaxHeight, Target_LowestHeight, EntityFlagDirectory.ExcludeFromFinding)

						if not Target.Value then
							Target.Value, Distance.Value = NPCModule.FindNearestMedicBox(HumanoidRootPart)
						end

						if Distance.Value and Distance.Value <= 20 and Target.Value.Parent:FindFirstChild("Humanoid", true) then
							RegularSpeed.Value = 0
						else
							RegularSpeed.Value = ReadOnlySpeed.Value
						end
					else
						if CurrentSprintState ~= "Walk" then
							AttemptSprint("Walk")
							RegularSpeed.Value = ReadOnlySpeed.Value
							CurrentSprintState = "Walk"
						end
					end
				end

			elseif (UVSettings:FindFirstChild("Pathfinder") and UVSettings.Pathfinder.Value == false) or SpecialConditions:FindFirstChild("EntityIsMedic") then
				if AllyTarget and AllyTargetDistance and AllyTarget.Value then
					local TargetPlayer = Players:GetPlayerFromCharacter(AllyTarget.Value.Parent)

					if TargetPlayer then
						SetNetworkOwnership(Character, HumanoidRootPart, TargetPlayer, "Default")
					end

					local AdjustedPosition = ComputeAdjustedPosition(AllyTarget.Value)

					if AIType.Value == "AllyFollower" and not FearChecks.EntityIsCrying.Value and not FearChecks.EntityIsVomitting.Value then
						task.defer(HandlePathToTarget, Character, AdjustedPosition, false, { Tracking = false, Visualize = false })
						if AllyTargetDistance.Value <= UnitRange.Value then
							AttackBool.Value = true
							RegularSpeed.Value = 0
						else
							RegularSpeed.Value = ReadOnlySpeed.Value
							task.delay(2, function()
								AttackBool.Value = false
							end)
						end
					end
				end
			elseif not UVSettings:FindFirstChild("Pathfinder") then
				return
			end
		end
		task.defer(CreateEntityCombatLogic, Target.Value)
		task.defer(EntityLoop)
	end

	Character:FindFirstChild("Attack", true).Value = false
	Character:FindFirstChild("Target", true).Value =  nil
end


local function IsProcessable(Character)
	if Players:GetPlayerFromCharacter(Character) then return false end
	if CollectionService:HasTag(Character, "HasNPCConnections") then return false end
	if not Character:IsA("Model") then return false end

	local UnitValues = Character:FindFirstChild("UnitValues")
	if not UnitValues then return false end

	local Settings = UnitValues:FindFirstChild("Settings")
	local Misc = UnitValues:FindFirstChild("MiscSettings")
	local HasChaseScript = Character:FindFirstChild("ChaseScript")
	local Humanoid = Character:FindFirstChild("Humanoid")

	if not (Settings and Misc and Humanoid) or HasChaseScript then return false end

	return true
end

local function ProcessEntityReturn(Character)
	if not IsProcessable(Character) then return end

	CollectionService:AddTag(Character, "HasNPCConnections")

	local Humanoid = Character:FindFirstChild("Humanoid")
	local IsDowned = false

	local EntDownedConnection = Humanoid.HealthChanged:Connect(function(EntHealth)
		if EntHealth <= 0 and not IsDowned and not Character:FindFirstChild("Downed") then
			IsDowned = true
			task.delay(0.35, function()
				--PlaceholderActivity
			end)
		end
	end)

	Character.AncestryChanged:Connect(function(_, parent)
		if not parent and EntDownedConnection then
			EntDownedConnection:Disconnect()
		end
	end)

	task.defer(CreateNPCConnections, Character)
end

task.spawn(function()
	for _, Character in ipairs(UnitsFolder:GetChildren()) do
		task.defer(ProcessEntityReturn, Character)
	end
end)

UnitsFolder.ChildAdded:Connect(function(Character)
	task.defer(ProcessEntityReturn, Character)
end)
