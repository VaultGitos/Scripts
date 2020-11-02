local Players		= game:GetService'Players';
local RunService	= game:GetService'RunService';
local HttpService	= game:GetService'HttpService';
local LocalPlayer	= Players.LocalPlayer;
local Camera		= workspace.CurrentCamera;

local uESP = {
	'Made by ic3w0lf';
	Enabled = true;
	Settings = {
		Box3D			= true;
		DrawBox			= true;
		DrawDistance	= true;
		DrawNames		= true;
		DrawTracers		= true;
		MaxDistance		= 10000;
		RefreshRate		= 100;
		TextSize		= 18;
		TextOutline		= true;
		VisibilityCheck = false;

		TeamColor = Color3.new(0, 1, 0);
		EnemyColor = Color3.new(1, 0, 0);
	};
	RenderList = {};
	RenderingCache = {};
	LastTick = 0;
};

local Active = {};

shared.ESPAPIName = shared.ESPAPIName or HttpService:GenerateGUID(false);

local function Set(t, i, v)
	t[i] = v;
end

local function Combine(...)
	local Output = {};
	for i, v in pairs{...} do
		if typeof(v) == 'table' then
			table.foreach(v, function(i, v)
				Output[i] = v;
			end)
		end
	end
	return Output
end

function NewDrawing(InstanceName)
	local Instance = Drawing.new(InstanceName);
	return (function(Properties)
		for i, v in pairs(Properties) do
			pcall(Set, Instance, i, v);
		end
		return Instance;
	end)
end

function IsTeam(Player)
	if Player == LocalPlayer then return true; end
	if Player.Neutral and LocalPlayer.Neutral then
		return true;
	end
	if Player.TeamColor == LocalPlayer.TeamColor then
		return true;
	end
	return false;
end

local DrawingTypes = {
	Text = true;
	Line = true;
	Square = true;
	Circle = true;
	Triangle = true;
	Image = true;
}

function CleanDrawings(Table, Cache)
	Cache = Cache or {};
	if Cache[Table] or typeof(Table) ~= 'table' then return end
	Cache[Table] = true;
	for i, v in pairs(Table) do
		if typeof(v) == 'table' then
			local mt = getmetatable(v);
			if mt and DrawingTypes[mt.__type] then
				v:Remove();
			end
		end
		CleanDrawings(v, Cache);
	end
end

local Box = {};

local Colors = {
	Color3.new(1, 0, 0);
	Color3.new(0, 1, 0);
	Color3.new(0, 0, 1);
	Color3.new(1, 0, 1);
	Color3.new(1, 1, 0);
	Color3.new(0, 1, 1);
}

function Box.new(Instance)
	local Box = {
		Instance = Instance;
		Cache = {};
		Lines = {};
		Was3D = uESP.Settings.Box3D;
	};

	function Box:Update(Properties) -- a lot of shorthand code im sorry
		local Properties = Properties or {};

		local Lines = self.Lines or {};
		local Instance = (self.Instance.ClassName == 'Model') and self.Instance or ((self.Instance.Parent.ClassName == 'Model') and self.Instance.Parent or self.Instance);

		if Instance == nil then
			self:Remove();
		end

		local Color = Properties.Color or Color3.new(1, 1, 1);

		local Properties = Combine({
			Transparency	= 1;
			Thickness		= 3;
			Color			= Color;
			Visible			= true;
		}, Properties);

		local Position, Size;

		if Instance.ClassName == 'Model' then
			Position, Size = Instance:GetBoundingBox();
		elseif Instance:IsA'BasePart' then
			Position, Size = Instance.CFrame, Instance.Size;
		else
			return;
		end

		if not uESP.Settings.Box3D and self.Was3D then
			self.Was3D = false;
			CleanDrawings(Lines);
			Lines = {};
		elseif uESP.Settings.Box3D and not self.Was3D then
			self.Was3D = true;
			CleanDrawings(Lines);
			Lines = {};
		end

		if Size.X < 16 and Size.Y < 16 and Size.Z < 16 then
			if uESP.Settings.Box3D then
				local Positions = {};

				Size = Size / 2;
				local Minimum, Maximum = -Size, Size

				local Corners = { -- https://www.unknowncheats.me/forum/counterstrike-global-offensive/175021-3d-box-esp.html
					[0] = CFrame.new(Minimum.x, Minimum.y, Minimum.z);
					[1] = CFrame.new(Minimum.x, Maximum.y, Minimum.z);
					[2] = CFrame.new(Maximum.x, Maximum.y, Minimum.z);
					[3] = CFrame.new(Maximum.x, Minimum.y, Minimum.z);
					[4] = CFrame.new(Minimum.x, Minimum.y, Maximum.z);
					[5] = CFrame.new(Minimum.x, Maximum.y, Maximum.z);
					[6] = CFrame.new(Maximum.x, Maximum.y, Maximum.z);
					[7] = CFrame.new(Maximum.x, Minimum.y, Maximum.z);
				}

				for i, v in pairs(Corners) do
					local SP = Camera:WorldToViewportPoint((Position * v).p);
					Positions[i] = Vector2.new(SP.X, SP.Y);
				end

				for i = 1, 4 do
					Lines[i] = Lines[i] or {};

					Lines[i][1] = Lines[i][1] or NewDrawing'Line'(Properties);
					Lines[i][2] = Lines[i][2] or NewDrawing'Line'(Properties);
					Lines[i][3] = Lines[i][3] or NewDrawing'Line'(Properties);

					Lines[i][1].Color = Color;
					Lines[i][2].Color = Color;
					Lines[i][3].Color = Color;

					Lines[i][1].From = Positions[i - 1];
					Lines[i][1].To = Positions[i % 4];

					Lines[i][2].From = Positions[i - 1];
					Lines[i][2].To = Positions[i + 3];

					Lines[i][3].From = Positions[i + 3];
					Lines[i][3].To = Positions[i % 4 + 4];
				end
			else
				local Positions = {};

				Size = Size / 2;
				local Minimum, Maximum = -Size, Size

				local Corners = {
					CFrame.new(Maximum.x, Maximum.y, 0);
					CFrame.new(-Maximum.x, Maximum.y, 0);
					CFrame.new(Minimum.x, Minimum.y, 0);
					CFrame.new(-Minimum.x, Minimum.y, 0);
				}

				for i, v in pairs(Corners) do
					local SP = Camera:WorldToViewportPoint((Position * v).p);
					Positions[i] = Vector2.new(SP.X, SP.Y);
				end

				Lines[1] = Lines[1] or {};
				-- these stupid [1]'s are there because i'm too lazy to make a check if box is 2d or 3d even tho its easy/shrug
				Lines[1][1] = Lines[1][1] or NewDrawing'Line'(Properties);
				Lines[1][2] = Lines[1][2] or NewDrawing'Line'(Properties);
				Lines[1][3] = Lines[1][3] or NewDrawing'Line'(Properties);
				Lines[1][4] = Lines[1][4] or NewDrawing'Line'(Properties);

				Lines[1][1].Color = Color;
				Lines[1][2].Color = Color;
				Lines[1][3].Color = Color;
				Lines[1][4].Color = Color;

				Lines[1][1].From = Positions[1];
				Lines[1][1].To = Positions[2];

				Lines[1][2].From = Positions[2];
				Lines[1][2].To = Positions[3];

				Lines[1][3].From = Positions[3];
				Lines[1][3].To = Positions[4];

				Lines[1][4].From = Positions[4];
				Lines[1][4].To = Positions[1];
			end

			self.Lines = Lines;
		end
	end

	function Box:SetVisible(boolean)
		for i, v in pairs(self.Lines) do
			for _, Line in pairs(v) do
				Line.Visible = boolean;
			end
		end
	end

	function Box:Remove()
		for i, v in pairs(self.Lines) do
			for _, Line in pairs(v) do
				Line.Visible = false;
				Line:Remove();
			end
		end

		self.Update = function () end;
	end

	return setmetatable(Box, {
		__tostring = function()
			return 'Box';
		end;
	});
end

function uESP:Toggle()
	self.Enabled = not self.Enabled;
end

function uESP:UpdateSetting(Key, Value)
	if Settings[Key] ~= nil and typeof(Settings[Key]) == typeof(Value) then -- prevent setting shit like boolean to integer
		Settings[Key] = Value;
	end
end

function uESP:AddToRenderList(Instance, ...)
	if typeof(Instance) ~= 'Instance' then return end
	if not Instance:IsA'BasePart' then return end

	rawset(self.RenderList, Instance, {...});
end

function uESP:DrawInstance(Instance, Properties)
	Properties = Properties or {};

	-- 
end

function uESP:DrawPlayer(Player)
	if Active[Player] then return false; end -- prevent retarded clones of drawings

	Active[Player] = true;

	local Character = Player.Character;

	if not Character or not Character:IsDescendantOf(workspace) then return end
	if Player == LocalPlayer then return end;

	local Cache = uESP.RenderingCache[Character] or {};

	Cache.Box = Cache.Box or Box.new(Character);
	Cache.NameTag = Cache.NameTag or NewDrawing'Text'{
		Center	= true;
		Outline	= uESP.Settings.TextOutline;
		Size	= uESP.Settings.TextSize;
		Visible	= true;
	};
	Cache.DistanceTag = Cache.DistanceTag or NewDrawing'Text'{
		Center	= true;
		Outline	= uESP.Settings.TextOutline;
		Size	= uESP.Settings.TextSize;
		Visible	= true;
	};
	Cache.Tracer = Cache.Tracer or NewDrawing'Line'{
		Transparency	= 1;
		Thickness		= 2;
	};

	uESP.RenderingCache[Character] = Cache;

	if uESP.Enabled and Player.Character:FindFirstChild'Head' then
		local Head = Character.Head;
		local Humanoid = Character:FindFirstChildOfClass'Humanoid';
		if Head then
			local ScreenPosition, Visible = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, Head.Size.Y / 2, 0));
			local Color = not Player.Neutral and Player.TeamColor.Color or (IsTeam(Player) and uESP.Settings.TeamColor or uESP.Settings.EnemyColor);

			if Humanoid and Humanoid.Health < 1 then
				Visible = false;
			end

			if Visible then
				if uESP.Settings.DrawNames then
					LocalPlayer.NameDisplayDistance = 0;
					Cache.NameTag.Color = Color;
					Cache.NameTag.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y);
					Cache.NameTag.Text = Player.Name;
					Cache.NameTag.Visible = true;
				else
					LocalPlayer.NameDisplayDistance = 100;
					Cache.NameTag.Visible = false;
				end
				if uESP.Settings.DrawDistance then
					Cache.DistanceTag.Color = Color3.new(1, 1, 1);
					Cache.DistanceTag.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y + (Cache.NameTag.TextBounds.Y));
					Cache.DistanceTag.Text = '[' .. math.floor(ScreenPosition.Z) .. ' Studs]';
					Cache.DistanceTag.Visible = true;
				else
					Cache.DistanceTag.Visible = false;
				end
				if uESP.Settings.DrawTracers then
					Cache.Tracer.From		= Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);
					Cache.Tracer.To			= Vector2.new(ScreenPosition.X, ScreenPosition.Y);
					Cache.Tracer.Color		= Color;
					Cache.Tracer.Visible	= true;
				else
					Cache.Tracer.Visible = false;
				end
				if ScreenPosition.Z >= 1.5 then
					Cache.Box:SetVisible(true);
				else
					Cache.Box:SetVisible(false);
				end
				Cache.Box:Update({Color = Color});
			else
				Cache.NameTag.Visible = false;
				Cache.DistanceTag.Visible = false;
				Cache.Tracer.Visible = false;
				Cache.Box:SetVisible(false);
			end
		end
	else
		Cache.NameTag.Visible = false;
		Cache.DistanceTag.Visible = false;
		Cache.Tracer.Visible = false;
		Cache.Box:SetVisible(false);
	end

	uESP.RenderingCache[Character] = Cache;
	Active[Player] = false;
end

function uESP:Draw()
	if uESP.Settings.RefreshRate > 1 and (tick() - uESP.LastTick) <= (uESP.Settings.RefreshRate / 1000) then
		return;
	end

	for i, v in pairs(Players:GetPlayers()) do
		uESP:DrawPlayer(v);
	end
	for i, v in pairs(self.RenderList) do
		uESP:DrawInstance(i, v);
	end

	for i, v in pairs(self.RenderingCache) do -- Remove trash
		if not i:IsDescendantOf(game) then
			CleanDrawings(self.RenderingCache[i]);
			self.RenderingCache[i] = nil;
		end
	end
end

function uESP:Unload()
	RunService:UnbindFromRenderStep(shared.ESPAPIName);
	CleanDrawings(uESP.RenderingCache);
	uESP = {};
end

pcall(function() shared.uESP:Unload() end);

wait(1/4);

shared.uESP = uESP;

RunService:BindToRenderStep(shared.ESPAPIName, 1, function()
	uESP:Draw();
end);
