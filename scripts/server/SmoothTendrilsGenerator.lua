-- File Name: SmoothTendrilsGenerator.lua
-- Generates a smooth branching tendril using tweens so that each part
-- appears to grow from the tip of the last part. Now attempts to attach
-- to nearby geometry so the tendril can spread along surfaces.

local TweenService = game:GetService("TweenService")

local ROOT_POSITION = Vector3.new(0, 10, 0)
local MAX_DEPTH = 18
local PART_LENGTH = 10
local PART_THICKNESS = 0.65
local BRANCH_CHANCE = 0.75
local TWEEN_TIME = 0.05 -- seconds for each part to grow
-- if true, segments only grow when a nearby surface is found
local REQUIRE_SURFACE = false
-- how far the new segment embeds into a hit surface
local EMBED_DEPTH = 0.1
-- how many attempts to find a surface when one is required
local RAYCAST_ATTEMPTS = 5
-- wider search angles when a surface is required
local SEARCH_YAW_RANGE = 180
local SEARCH_PITCH_RANGE = 90

local function createBranchPart(cframe, parent)
    local part = Instance.new("Part")
    part.Size = Vector3.new(PART_THICKNESS, 0.1, PART_THICKNESS)
    part.Anchored = true -- anchored while tweening
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(math.random(1, 255), math.random(1, 255), math.random(1, 255))
    part.CFrame = cframe
    part.Parent = parent
    return part
end

local function attachParts(partA, partB)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = partA
    weld.Part1 = partB
    weld.Parent = partA
end

local function computeTargetCFrame(base, rotation, params)
    local oriented = base * rotation
    local direction = oriented.UpVector
    local result = workspace:Raycast(base.Position, direction * (PART_LENGTH + EMBED_DEPTH), params)

    if result then
        local normal = result.Normal
        -- project movement direction onto surface plane so the tendril follows the wall
        local tangent = direction - normal * direction:Dot(normal)
        if tangent.Magnitude < 0.001 then
            tangent = oriented.RightVector:Cross(normal)
        end
        tangent = tangent.Unit

        local center = result.Position + normal * EMBED_DEPTH + tangent * (PART_LENGTH / 2)
        return CFrame.fromMatrix(center, normal, tangent)
    elseif REQUIRE_SURFACE then
        -- If a surface is required, returning nil tells the caller to abort
        return nil
    else
        return oriented * CFrame.new(0, PART_LENGTH / 2, 0)
    end
end

local function growTendril(cframe, depth, parent, lastPart)
    if depth > MAX_DEPTH then return end

    local base = cframe * CFrame.new(0, lastPart.Size.Y / 2, 0)

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {parent}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local rotation
    local finalCFrame
    for _ = 1, RAYCAST_ATTEMPTS do
        local pitchRange = REQUIRE_SURFACE and SEARCH_PITCH_RANGE or 10
        local yawRange = REQUIRE_SURFACE and SEARCH_YAW_RANGE or 30
        rotation = CFrame.Angles(
            math.rad(math.random(-pitchRange, pitchRange)),
            math.rad(math.random(-yawRange, yawRange)),
            math.rad(math.random(-10, 10))
        )
        finalCFrame = computeTargetCFrame(base, rotation, rayParams)
        if finalCFrame then
            break
        end
    end

    if not finalCFrame then
        return
    end

    local startCFrame = base

    local part = createBranchPart(startCFrame, parent)

    local tween = TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {
        CFrame = finalCFrame,
        Size = Vector3.new(PART_THICKNESS, PART_LENGTH, PART_THICKNESS)
    })
    tween:Play()
    tween.Completed:Wait()

    part.Anchored = false
    if lastPart then
        attachParts(lastPart, part)
    end

    if math.random() < BRANCH_CHANCE then
        for _ = 1, math.random(1, 2) do
            growTendril(part.CFrame, depth + 1, parent, part)
        end
    else
        growTendril(part.CFrame, depth + 1, parent, part)
    end
end

-- Bootstrapping
local rootPart = Instance.new("Part")
rootPart.Size = Vector3.new(1, 1, 1)
rootPart.Position = ROOT_POSITION
rootPart.Anchored = true
rootPart.Transparency = 1
rootPart.CanCollide = false
rootPart.Parent = workspace

local tendrilModel = Instance.new("Model", workspace)

tendrilModel.Name = "SeamlessTendril"
tendrilModel.PrimaryPart = rootPart

-- start the growth
growTendril(rootPart.CFrame, 1, tendrilModel, rootPart)
