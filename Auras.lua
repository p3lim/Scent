--[[

	Copyright (c) 2009 Adrian L Lange <adrianlund@gmail.com>
	All rights reserved.

	You're allowed to use this addon, free of monetary charge,
	but you are not allowed to modify, alter, or redistribute
	this addon without express, written permission of the author.

--]]

local buffFilter = {
	[52610] = true, -- Druid: Savage Roar
	[16870] = true, -- Druid: Clearcast
	[50213] = true, -- Druid: Tiger's Fury
	[50334] = true, -- Druid: Berserk
	[57960] = true, -- Shaman: Water Shield
	[32182] = true, -- Buff: Heroism
	[49016] = true, -- Buff: Hysteria
}

local floor, max = math.floor, math.max
local match, format, gsub = string.match, string.format, string.gsub

local function hookTooltip(self)
	if(self.owner and UnitExists(self.owner)) then
		if(self.owner == 'vehicle' or self.owner == 'pet') then
			GameTooltip:AddLine(format('Cast by %s <%s>', UnitName(self.owner), UnitName('player')))
		elseif(self.owner:match('^partypet[1-4]$')) then
			GameTooltip:AddLine(format('Cast by %s <%s>', UnitName(self.owner), UnitName(format('party%d', self.owner:gsub('^partypet(%d)$', '%1')))))
		elseif(self.owner:match('^raidpet[1-40]$')) then
			GameTooltip:AddLine(format('Cast by %s <%s>', UnitName(self.owner), UnitName(format('raid%d', self.owner:gsub('^raidpet(%d)$', '%1')))))
		else
			GameTooltip:AddLine(format('Cast by %s', UnitName(self.owner)))
		end
	else
		GameTooltip:AddLine(format('Cast by %s', UNKNOWN))
	end

	GameTooltip:Show()
end

local function updateTime(self, elapsed)
	self.timeLeft = max(self.timeLeft - elapsed, 0)

	if(self.timeLeft <= 0) then
		self.timeLeft = -1
		self.time:SetText()
		self:SetScript('OnUpdate', nil)
	else
		self.time:SetText(self.timeLeft < 90 and floor(self.timeLeft) or '')
	end
	
	if(GameTooltip:IsOwned(self)) then
		GameTooltip:SetUnitAura(self.parent:GetParent().unit, self:GetID(), self.filter)
		hookTooltip(self)
	end
end

local function updateAura(element, unit, button, index)
	local _, _, _, _, type = UnitAura(unit, index, button.filter)

	local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
	button:SetBackdropColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
end

local function createAura(element, button)
	element.disableCooldown = true

	button:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, bottom = -1, left = -1, right = -1}})
	button:SetBackdropColor(0, 0, 0)
	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.icon:SetDrawLayer('ARTWORK')

	button.time = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	button.time:SetPoint('TOPLEFT', button)

	button:HookScript('OnEnter', hookTooltip)
end

local function filterAura(element, unit, button, ...)
	local _, _, _, _, _, _, timeLeft, owner, _, _, spell = ...

	if(not (buffFilter[spell] and owner == 'player')) then
		button.owner = owner

		if(timeLeft == 0) then
			button.time:SetText()
			button.timeLeft = math.huge
			button:SetScript('OnUpdate', nil)
		else
			button.timeLeft = timeLeft - GetTime()
			button:SetScript('OnUpdate', updateTime)
		end

		return true
	else
		-- Auras that is filtered out will still count for the sorting function.
		button.timeLeft = timeLeft
	end
end

local function sortAura(a, b)
	return a.timeLeft > b.timeLeft
end

local function positionAura(element)
	table.sort(element, sortAura)
end

local function style(self)
	self.Buffs = CreateFrame('Frame', nil, self)
	self.Buffs:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -20, 0)
	self.Buffs:SetHeight(64)
	self.Buffs:SetWidth(384)
	self.Buffs.num = 24
	self.Buffs.size = 26
	self.Buffs.spacing = 6
	self.Buffs.initialAnchor = 'TOPRIGHT'
	self.Buffs['growth-x'] = 'LEFT'
	self.Buffs['growth-y'] = 'DOWN'
	self.Buffs.PreSetPosition = positionAura
	self.Buffs.PostCreateIcon = createAura
	self.Buffs.PostUpdateAuraIcon = updateAura
	self.Buffs.CustomFilter = filterAura

	self.Debuffs = CreateFrame('Frame', nil, self)
	self.Debuffs:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMLEFT', -20, 0)
	self.Debuffs:SetHeight(64)
	self.Debuffs:SetWidth(384)
	self.Debuffs.num = 24
	self.Debuffs.size = 26
	self.Debuffs.spacing = 6
	self.Debuffs.initialAnchor = 'BOTTOMRIGHT'
	self.Debuffs['growth-x'] = 'LEFT'
	self.Debuffs.PreSetPosition = positionAura
	self.Debuffs.PostCreateIcon = createAura
	self.Debuffs.PostUpdateAuraIcon = updateAura
	self.Debuffs.CustomFilter = filterAura

	BuffFrame:Hide()
	BuffFrame:UnregisterEvent('UNIT_AURA')

	TicketStatusFrame:EnableMouse(false)
	TicketStatusFrame:SetFrameStrata('BACKGROUND')
end

oUF:RegisterStyle('Scent', style)
oUF:SetActiveStyle('Scent')
oUF:Spawn('player') -- dummy
