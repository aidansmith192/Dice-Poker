local ROLLS = 3 	-- variable
local DICE = 5 		-- set value
local PLAYERS = 1 	-- take in value from game
local DICE_DICT = {"9", "10", "J", "Q", "K", "A"}
local PLAYER_ARR = {}

local player_hands = {}
--local player_turn = 1
local roll_count = {}

local abort_timer = 0
local game_active = 0

local NEXT_GAME_TIMER = 10
local GAME_TIMER = 60

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ai_enabled = 0
local ai_difficulty = "Off"
local ai_off_votes = 0
local ai_easy_votes = 0
local ai_medium_votes = 0
local ai_hard_votes = 0
local ai_color = BrickColor.new(37)

function start_game()
	
	-- determine ai status
	if (ai_off_votes == 0) and (ai_easy_votes == 0) and (ai_medium_votes == 0) and (ai_hard_votes == 0) then
		-- no change, keep using same AI setting
	elseif (ai_off_votes >= ai_easy_votes) and (ai_off_votes >= ai_medium_votes) and (ai_off_votes >= ai_hard_votes) then
		ai_difficulty = "Off"
		ai_enabled = 0
		ai_color = BrickColor.new(37)
	elseif (ai_easy_votes >= ai_medium_votes) and (ai_easy_votes >= ai_hard_votes) then
		ai_difficulty = "Easy"
		ai_enabled = 1
		ai_color = BrickColor.new(24)
	elseif (ai_medium_votes >= ai_hard_votes) then
		ai_difficulty = "Medium"
		ai_enabled = 1
		ai_color = BrickColor.new(123)
	else
		ai_difficulty = "Hard"
		ai_enabled = 1
		ai_color = BrickColor.new(21)
	end
	
	ai_off_votes = 0
	ai_easy_votes = 0
	ai_medium_votes = 0
	ai_hard_votes = 0
	
	abort_timer = 0
	game_active = 1

	wait(1)
	PLAYER_ARR = game.Players:GetPlayers()
	
	PLAYERS = #PLAYER_ARR 	-- take in value from game
	
	-- reset hands
	player_hands = {}
	for i = 1, PLAYERS, 1 do
		table.insert(player_hands, {})
	end
	
	for i = 1, PLAYERS, 1 do
		if PLAYER_ARR[i] ~= nil and PLAYER_ARR[i]:FindFirstChild("PlayerGui") then
			local winner_gui = PLAYER_ARR[i].PlayerGui.ScreenGui.WinnerGui
			winner_gui.Enabled = false
			
			local dice_gui = PLAYER_ARR[i].PlayerGui.ScreenGui.DiceGui
			dice_gui.Roll.BackgroundColor3 = Color3.fromRGB(136, 136, 136)
			dice_gui.Stay.BackgroundColor3 = Color3.fromRGB(136, 136, 136)
			dice_gui.Stay.Text = "Stay"
			
			local ai_gui = PLAYER_ARR[i].PlayerGui.ScreenGui.AIGui
			ai_gui.CurrentAI.StatusLabel.BackgroundColor = ai_color
			ai_gui.CurrentAI.StatusLabel.Text = ai_difficulty
			
			ai_gui.Vote.Interactable = true
		end
		
		-- in case it is enabled some how
		stop_player_from_rerolling(i)
		
		-- set all dice locks to unlocked
		game.ReplicatedStorage.ResetLocksEvent:FireAllClients()
		
		roll_count[i] = 0
		update_dice_gui(i)
	end
	
	enable_dice_gui_for_all_players()
	allow_rolling()
	
	--allow_players_to_reroll()
	-- add a timer for the future
	
	start_game_timer()
end

function start_game_timer()
	local players = PLAYER_ARR
	for i = GAME_TIMER, 1, -1 do
		if abort_timer == 1 then
			return
		end
		local text = i .. " second"
		if i ~= 1 then
			text = text .. "s"
		end
		text = text .. " left in the round"
		
		for player_num_loop = 1, #players, 1 do
			if players[player_num_loop] ~= nil and players[player_num_loop]:FindFirstChild("PlayerGui") then
				players[player_num_loop].PlayerGui.ScreenGui.GameTimer.Text = text
			end
		end
		players = game.Players:GetPlayers()
		wait(1)
	end
	determine_winner()
end

function enable_dice_gui_for_all_players()
	for i = 1, PLAYERS, 1 do
		if PLAYER_ARR[i] ~= nil and PLAYER_ARR[i]:FindFirstChild("PlayerGui") then
			PLAYER_ARR[i].PlayerGui.ScreenGui.DiceGui.Enabled = true
			PLAYER_ARR[i].PlayerGui.ScreenGui.HelpGui.Enabled = true
			PLAYER_ARR[i].PlayerGui.ScreenGui.AIGui.Enabled = true
		end
	end
end

function allow_rolling()
	for i = 1, #PLAYER_ARR, 1 do
		if PLAYER_ARR[i] ~= nil and PLAYER_ARR[i]:FindFirstChild("PlayerGui") then
			local dice_gui = PLAYER_ARR[i].PlayerGui.ScreenGui.DiceGui
			dice_gui.Roll.Interactable = true
		end
	end
end

local HAND_DICT = {"HIGH CARD", "PAIR", "TWO PAIR", "THREE OF A KIND", "FULL HOUSE", "STRAIGHT", "FOUR OF A KIND", "FIVE OF A KIND"}
local VALUE_INDEX = 1
local PRIMARY_INDEX = 2
local SECONDARY_INDEX = 3
local HAND_DESCRIPTION = 4
local RARITY_COLOR = 5

-- after rolling dice, give player the values of their hand
function update_dice_gui(player_num)
	if PLAYER_ARR[player_num] ~= nil and PLAYER_ARR[player_num]:FindFirstChild("PlayerGui") then
		local dice_gui = PLAYER_ARR[player_num].PlayerGui.ScreenGui.DiceGui
	
		if roll_count[player_num] ~= 0 then
			allow_locking(player_num)
			
			local hand = table.clone(player_hands[player_num])
			
			local _, _, _, hand_desc, rarity_color = determine_hand_value(hand, player_num)
			dice_gui.HandValue.Text = hand_desc
			dice_gui.HandValue.TextColor3 = rarity_color
			
			dice_gui.Stay.Interactable = true
			
			for i = 1, DICE, 1 do
				local dice_button = dice_gui:FindFirstChild("Die" .. i)
				dice_button.Text = DICE_DICT[player_hands[player_num][i]]
			end
		else -- before rolling
			for i = 1, DICE, 1 do
				local dice_button = dice_gui:FindFirstChild("Die" .. i)
				dice_button.Text = ""
				dice_gui.HandValue.Text = ""
			end
		end
		
		local roll = roll_count[player_num]
		dice_gui.Roll.Text = "Roll (" .. 3 - roll .. ")"
	end
end

-- enable the buttons to be pressed
function allow_locking(player_num)	
	if PLAYER_ARR[player_num] ~= nil and PLAYER_ARR[player_num]:FindFirstChild("PlayerGui") then
		local dice_gui = PLAYER_ARR[player_num].PlayerGui.ScreenGui.DiceGui
		for i = 1, DICE, 1 do
			local dice_button = dice_gui:FindFirstChild("Die" .. i)
			dice_button.Interactable = true
		end
	end
end

function stop_player_from_rerolling(player_num)
	if PLAYER_ARR[player_num] ~= nil and PLAYER_ARR[player_num]:FindFirstChild("PlayerGui") then
		local dice_gui = PLAYER_ARR[player_num].PlayerGui.ScreenGui.DiceGui
		
		for i = 1, DICE, 1 do
			local dice_button = dice_gui:FindFirstChild("Die" .. i)
			dice_button.Interactable = false
		end
		dice_gui.Roll.Interactable = false
		dice_gui.Stay.Interactable = false
	end
end

function player_reroll(player_rolling, reroll_arr)
	local player_num = table.find(PLAYER_ARR, player_rolling)
	
	for i = 1, DICE, 1 do
		--print("reroll val: ", reroll_arr[i])
		if reroll_arr[i] == 1 then
			player_hands[player_num][i] = math.random(1,6)
		end
	end
	
	-- check if player is out of rerolls
	roll_count[player_num] += 1
	
	if roll_count[player_num] == 3 then
		if PLAYER_ARR[player_num] ~= nil and PLAYER_ARR[player_num]:FindFirstChild("PlayerGui") then
			local dice_gui = PLAYER_ARR[player_num].PlayerGui.ScreenGui.DiceGui
			dice_gui.Roll.BackgroundColor3 = Color3.fromRGB(89,89,89)
		end
	end
	
	update_dice_gui(player_num)
	
	
	if roll_count[player_num] >= 3 then
		check_if_all_players_are_done()
		stop_player_from_rerolling(player_num)
	end
end


-- Get reference to remote event instance
local reroll_event = ReplicatedStorage:FindFirstChild("RerollEvent")
reroll_event.OnServerEvent:Connect(player_reroll)

function player_stay(player)
	local player_num = table.find(PLAYER_ARR, player)
	
	if PLAYER_ARR[player_num] ~= nil and PLAYER_ARR[player_num]:FindFirstChild("PlayerGui") then
		local dice_gui = PLAYER_ARR[player_num].PlayerGui.ScreenGui.DiceGui
		dice_gui.Stay.BackgroundColor3 = Color3.fromRGB(89,89,89)
		dice_gui.Stay.Text = "Stayed"
	end

	-- set player out of rerolls
	roll_count[player_num] = 3

	check_if_all_players_are_done()
	
	stop_player_from_rerolling(player_num)
end

function check_if_all_players_are_done()
	for i = 1, PLAYERS, 1 do
		if roll_count[i] < 3 then
			if PLAYER_ARR[i] ~= nil and PLAYER_ARR[i]:FindFirstChild("PlayerGui") then
				return -- not all players done, exit
			end
		end
	end
	abort_timer = 1
	determine_winner()
end


local stay_event = ReplicatedStorage:FindFirstChild("StayEvent")
stay_event.OnServerEvent:Connect(player_stay)


local VALUE_DICT = {
	FIVE_OF_A_KIND = 8,
	FOUR_OF_A_KIND = 7,
	FULL_HOUSE = 6,
	STRAIGHT = 5,
	THREE_OF_A_KIND = 4,
	TWO_PAIR = 3,
	PAIR = 2,
	HIGH_CARD = 1,
}

function determine_winner()	
	game_active = 0
	
	-- game is over, cannot reroll any more
	
	for i = 1, #PLAYER_ARR, 1 do
		stop_player_from_rerolling(i)
		if #player_hands[i] == 0 then
			table.remove(PLAYER_ARR, i)
		end
		if PLAYER_ARR[i] ~= nil and PLAYER_ARR[i]:FindFirstChild("PlayerGui") then
			PLAYER_ARR[i].PlayerGui.ScreenGui.DiceGui.Enabled = false
		end
	end

	local players_hand_type = {} 	-- kind of hand
	local players_primary_card = {} 	-- highest part of hand
	local players_secondary_card = {}	-- second highest part of hand
	local players_hand_desc = {} -- hand description
	local players_hand_color = {} -- hand color, to show rarity!
	local players_hand_order = {} -- order to display players hand
	-- EX: kings/queens full house: F, K, Q

	for i = 1, PLAYERS, 1 do
		table.insert(players_hand_order, {})
		
		local hand = table.clone(player_hands[i])
		players_hand_type[i], players_primary_card[i], players_secondary_card[i], players_hand_desc[i], players_hand_color[i], players_hand_order[i] = determine_hand_value(hand, i)
	end
	
	--print(player_hands_desc)
	
	-- ai handling
	local ai_hand_type = 0      -- kind of hand
	local ai_primary_card = 0   -- highest part of hand
	local ai_secondary_card = 0 -- second highest part of hand
	local ai_hand_desc = 0      -- hand description
	local ai_hand_color = 0     -- hand color, to show rarity!
	local ai_hand_order = {} -- order to display players hand
	if ai_enabled == 1 then
		ai_hand_type, ai_primary_card, ai_secondary_card, ai_hand_desc, ai_hand_color, ai_hand_order = game.ServerStorage.AIFunction:Invoke(ai_difficulty)
		
		table.insert(players_hand_type, ai_hand_type)
		table.insert(players_primary_card, ai_primary_card)
		table.insert(players_secondary_card, ai_secondary_card)
		table.insert(players_hand_desc, ai_hand_desc)
		table.insert(players_hand_color, ai_hand_color)
		table.insert(players_hand_order, ai_hand_order)
	end
	
	--print("ai hand type: " .. ai_hand_type)



	--print(players_hand_desc)

	-- ai is #PLAYERS_ARR ++

	-- compare hands to find best
	local winners = {}
	local second_place_player = nil
	
	-- #PLAYERS + AI ? 1 : 0
	local num_hands = PLAYERS + ai_enabled

	-- above checks if there is AI, if so then AI needs to be considered
	for i = 1, num_hands, 1 do
		if (i == PLAYERS + 1) or (#player_hands[i] ~= 0) then -- if current is AI  OR  if player rolled
			if #winners == 0 then -- if winner list empty then just add first player hit
				winners = {i}
			else -- already one person that can be a winner, compare to them
				if players_hand_type[winners[1]] < players_hand_type[i] then -- compare type
					second_place_player = determine_second_place(second_place_player, winners[1], players_hand_type, players_primary_card, players_secondary_card)
					winners = {i}
				elseif players_hand_type[winners[1]] == players_hand_type[i] then
					if players_primary_card[winners[1]] < players_primary_card[i] then -- compare first
						second_place_player = determine_second_place(second_place_player, winners[1], players_hand_type, players_primary_card, players_secondary_card)
						winners = {i}
					elseif players_primary_card[winners[1]] == players_primary_card[i] then
						if players_secondary_card[winners[1]] < players_secondary_card[i] then -- compare second
							second_place_player = determine_second_place(second_place_player, winners[1], players_hand_type, players_primary_card, players_secondary_card)
							winners = {i}
						elseif players_secondary_card[winners[1]] == players_secondary_card[i] then
							table.insert(winners, i)
						else
							second_place_player = determine_second_place(second_place_player, i, players_hand_type, players_primary_card, players_secondary_card)
						end
					else
						second_place_player = determine_second_place(second_place_player, i, players_hand_type, players_primary_card, players_secondary_card)
					end
				else
					second_place_player = determine_second_place(second_place_player, i, players_hand_type, players_primary_card, players_secondary_card)
				end
			end
		end
	end
	
	-- add for win to winners
	for i = 1, #winners, 1 do
		if winners[i] ~= PLAYERS + 1 then -- make sure we arent checking an AI
			local leaderstats = PLAYER_ARR[winners[i]].leaderstats
			local win = leaderstats and leaderstats:FindFirstChild("All Time")
			win.Value = tostring(tonumber(win.Value) + 1)
			
			local session_win = leaderstats and leaderstats:FindFirstChild("Session")
			session_win.Value = tostring(tonumber(session_win.Value) + 1)
			
			-- award badge
			game.ServerStorage.BadgeEvent:Fire(PLAYER_ARR[winners[i]], "win")
		end
	end

	-- declare winner(s)
	if #winners > 0 then
		local winner_string = ""
		if #winners > 1 then
			for i = 1, #winners, 1 do
				if winners[i] == PLAYERS + 1 then -- if winner is AI
					winner_string = winner_string .. ai_difficulty .. "-AI "
				else
					winner_string = winner_string .. PLAYER_ARR[winners[i]].Name .. " "
				end
			end
			winner_string = winner_string .. "are the winners!"
		else
			if winners[1] == PLAYERS + 1 then -- if winner is AI
				winner_string = ai_difficulty .. "-AI is the winner!"
			else
				winner_string = PLAYER_ARR[winners[1]].Name .. " is the winner!"
			end
		end
		
		for i = 1, PLAYERS, 1 do
			if PLAYER_ARR[i] ~= nil and PLAYER_ARR[i]:FindFirstChild("PlayerGui") then
				local winner_gui = PLAYER_ARR[i].PlayerGui.ScreenGui.WinnerGui
				winner_gui.Enabled = true
				
				winner_gui.Background.HandValue.Text = players_hand_desc[winners[1]]
				winner_gui.Background.HandValue.TextColor3 = players_hand_color[winners[1]]
				
				winner_gui.Background.WinnerLabel.Text = winner_string
				
				-- show winner's dice with ideal order
				for k = 1, DICE, 1 do
					winner_gui.Background:FindFirstChild("Die" .. k).Text = DICE_DICT[players_hand_order[winners[1]][k]]
				end
				
				-- if current player is a winner then show second place player's hand
				if table.find(winners, i) ~= nil then
					winner_gui.Background.Background.YourLabel.Text = "Second place\'s hand:"
					if second_place_player ~= nil then -- if there is a second player
						if second_place_player == PLAYERS + 1 then -- second place player is AI
							winner_gui.Background.Background.YourLabel.Text = "Second place (" .. ai_difficulty .. "-AI)\'s hand:"
						else
							winner_gui.Background.Background.YourLabel.Text = "Second place (" .. PLAYER_ARR[second_place_player].Name .. ")\'s hand:"
						end
						--if #player_hands[second_place_player] == 0 then -- if second place player didnt play (should never be possible)
						--	for k = 1, DICE, 1 do
						--		winner_gui.Background.Background:FindFirstChild("Die" .. k).Text = ""
						--	end
						--	winner_gui.Background.Background.HandValue.Text = ""
						--else
							for k = 1, DICE, 1 do
								winner_gui.Background.Background:FindFirstChild("Die" .. k).Text = DICE_DICT[players_hand_order[second_place_player][k]]
							end
							winner_gui.Background.Background.HandValue.Text = players_hand_desc[second_place_player]
							winner_gui.Background.Background.HandValue.TextColor3 = players_hand_color[second_place_player]
						--end
					else -- if no second player then leave empty
						for k = 1, DICE, 1 do
							winner_gui.Background.Background:FindFirstChild("Die" .. k).Text = ""
						end
						winner_gui.Background.Background.HandValue.Text = ""
					end
				else -- if player is not winner, show their hand
					winner_gui.Background.Background.YourLabel.Text = "Your hand:"
					if #player_hands[i] == 0 then -- if player didnt play
						for k = 1, DICE, 1 do
							winner_gui.Background.Background:FindFirstChild("Die" .. k).Text = ""
						end
						winner_gui.Background.Background.HandValue.Text = ""
					else
						for k = 1, DICE, 1 do
							winner_gui.Background.Background:FindFirstChild("Die" .. k).Text = DICE_DICT[players_hand_order[i][k]]
						end
						winner_gui.Background.Background.HandValue.Text = players_hand_desc[i]
						winner_gui.Background.Background.HandValue.TextColor3 = players_hand_color[i]
					end
				end
			end
		end
	end
	start_next_game_counter()
end

function determine_second_place(second_place_player, current_player, players_hand_type, players_primary_card, players_secondary_card)
	if second_place_player == nil then -- if second_place_player doesnt exists
		return current_player
	else -- if second_place_player exists
		if players_hand_type[second_place_player] < players_hand_type[current_player] then -- compare type
			return current_player
		elseif players_hand_type[second_place_player] == players_hand_type[current_player] then
			if players_primary_card[second_place_player] < players_primary_card[current_player] then -- compare first
				return current_player
			elseif players_primary_card[second_place_player] == players_primary_card[current_player] then
				if players_secondary_card[second_place_player] < players_secondary_card[current_player] then -- compare second
					return current_player
				end
			end
		end
	end
	return second_place_player
end

function start_next_game_counter()
	for i = NEXT_GAME_TIMER, 1, -1 do
		for player_count = 1, #PLAYER_ARR, 1 do
			local text = "Game starting in " .. i .. " second"
			if i ~= 1 then
				text = text .. "s"
			end
			
			if PLAYER_ARR[player_count] ~= nil and PLAYER_ARR[player_count]:FindFirstChild("PlayerGui") then
				PLAYER_ARR[player_count].PlayerGui.ScreenGui.GameTimer.Text = tostring(text)
				
			end
		end
		PLAYER_ARR = game.Players:GetPlayers()
		wait(1)
	end
	start_game()
end



function determine_hand_value(hand, player_num)
	-- sort hand
	table.sort(hand)
	-- set base values / reset previous values
	local hand_type = 0
	local primary_card = 0
	local secondary_card = 0
	local hand_desc = ""
	local rarity_color
	local hand_order = {}
	
	if #hand == 0 then
		return 
	end
	
	-- 5 of a kind
	if hand[1] == hand[5] then
		hand_type = VALUE_DICT["FIVE_OF_A_KIND"]
		primary_card = hand[1]
		secondary_card = 0 -- default value to avoid errors when comparing for winner
		hand_desc = "Five of a Kind of " .. DICE_DICT[primary_card] .. "\'s"
		rarity_color = Color3.fromRGB(250,100,20)
		hand_order = {primary_card, primary_card, primary_card, primary_card, primary_card}
		
		-- award badge(s)
		game.ServerStorage.BadgeEvent:Fire(PLAYER_ARR[player_num], "five")
		
		if DICE_DICT[primary_card] == "A" then
			game.ServerStorage.BadgeEvent:Fire(PLAYER_ARR[player_num], "best")
		end
		
	-- 4 of a kind
	elseif hand[1] == hand[4] or hand[2] == hand[5] then
		hand_type = VALUE_DICT["FOUR_OF_A_KIND"]
		primary_card = hand[3]
		secondary_card = hand[5]
		if hand[3] == hand[5] then -- if quad includes dice #5, then dice #1 is extra high card [OXXXX]
			secondary_card = hand[1]
		end
		
		if DICE_DICT[secondary_card] == "A" then
			hand_desc = "Four of a Kind of " .. DICE_DICT[primary_card] .. "\'s and an " .. DICE_DICT[secondary_card]
		else
			hand_desc = "Four of a Kind of " .. DICE_DICT[primary_card] .. "\'s and a " .. DICE_DICT[secondary_card]
		end
		rarity_color = Color3.fromRGB(132, 54, 156)
		hand_order = {primary_card, primary_card, primary_card, primary_card, secondary_card}
		
		-- award badge
		game.ServerStorage.BadgeEvent:Fire(PLAYER_ARR[player_num], "four")
		
	-- full house
	elseif (hand[1] == hand[3] and hand[4] == hand[5])
		or (hand[1] == hand[2] and hand[3] == hand[5]) then
		hand_type = VALUE_DICT["FULL_HOUSE"]
		primary_card = hand[3]
		secondary_card = hand[5]
		if hand[3] == hand[5] then -- if full house includes 5, then 2 is highest [OOXXX]
			secondary_card = hand[2]
		end
		hand_desc = "Full House of " .. DICE_DICT[primary_card] .. "\'s over " .. DICE_DICT[secondary_card] .."\'s"
		rarity_color = Color3.fromRGB(80,90,250)
		hand_order = {primary_card, primary_card, primary_card, secondary_card, secondary_card}
		
	-- straight
	elseif hand[1] == hand[2] - 1 and hand[1] == hand[3] - 2
		and hand[1] == hand[4] - 3 and hand[1] == hand[5] - 4 then
		hand_type = VALUE_DICT["STRAIGHT"]
		primary_card = hand[5] -- highest is top card (Ace or King)
		secondary_card = hand[1]
		hand_desc = "Straight from " .. DICE_DICT[secondary_card] .. " to " .. DICE_DICT[primary_card]
		rarity_color = Color3.fromRGB(80,90,250)
		hand_order = {hand[5], hand[4], hand[3], hand[2], hand[1]}
		
	-- 3 of a kind
	elseif hand[1] == hand[3]
		or hand[2] == hand[4]
		or hand[3] == hand[5] then
		
		hand_type = VALUE_DICT["THREE_OF_A_KIND"]
		primary_card = hand[3]
		secondary_card = hand[5]
		if hand[3] == hand[5] then -- if triple includes 5, then 2 is higest [ABXXX]
			secondary_card = hand[2]
		end
		
		if DICE_DICT[secondary_card] == "A" then
			hand_desc = "Three of a Kind of " .. DICE_DICT[primary_card] .. "\'s and an " .. DICE_DICT[secondary_card]
		else
			hand_desc = "Three of a Kind of " .. DICE_DICT[primary_card] .. "\'s and a " .. DICE_DICT[secondary_card]
		end
		rarity_color = Color3.fromRGB(30,220,30)
		
		local tertiary_card = hand[1]
		if hand[1] == hand[3] then
			tertiary_card = hand[4]
		end
		hand_order = {primary_card, primary_card, primary_card, secondary_card, tertiary_card}
		
	-- 2 pair
	elseif (hand[1] == hand[2] and hand[3] == hand[4])
		or (hand[1] == hand[2] and hand[4] == hand[5]) 
		or (hand[2] == hand[3] and hand[4] == hand[5]) then
		
		hand_type = VALUE_DICT["TWO_PAIR"]
		primary_card = hand[4]
		secondary_card = hand[2]
		hand_desc = "Two Pair of " .. DICE_DICT[primary_card] .. "\'s and " .. DICE_DICT[secondary_card] .."\'s"
		rarity_color = Color3.fromRGB(30,220,30)
		
		local tertiary_card = hand[5]
		if (hand[1] == hand[2] and hand[4] == hand[5]) then
			tertiary_card = hand[3]
		elseif (hand[2] == hand[3] and hand[4] == hand[5]) then
			tertiary_card = hand[1]
		end
		hand_order = {primary_card, primary_card, secondary_card, secondary_card, tertiary_card}
		
	-- pair
	elseif hand[1] == hand[2]
		or hand[2] == hand[3]
		or hand[3] == hand[4]
		or hand[4] == hand[5] then
		
		hand_type = VALUE_DICT["PAIR"]
		primary_card = hand[2] 				-- default: if 2 paired
		secondary_card = hand[5]
		if hand[3] == hand[4] then 		-- if 3 & 4 paired
			primary_card = hand[3]
		elseif hand[4] == hand[5] then 	-- if 4 & 5 paired
			primary_card = hand[4]
			secondary_card = hand[3]
		end
		
		if DICE_DICT[secondary_card] == "A" then
			hand_desc = "Pair of " .. DICE_DICT[primary_card] .. "\'s and an " .. DICE_DICT[secondary_card]
		else
			hand_desc = "Pair of " .. DICE_DICT[primary_card] .. "\'s and a " .. DICE_DICT[secondary_card]
		end
		rarity_color = Color3.fromRGB(189,189,189)
		
		local tertiary_card, fourth_order_card = hand[2], hand[1]
		if hand[1] == hand[2] then
			tertiary_card, fourth_order_card = hand[4], hand[3]
		elseif hand[2] == hand[3] then
			tertiary_card, fourth_order_card = hand[4], hand[1]
		end
		hand_order = {primary_card, primary_card, secondary_card, tertiary_card, fourth_order_card}
		
	-- high card
	else
		hand_type = VALUE_DICT["HIGH_CARD"]
		primary_card = hand[5]
		secondary_card = 0 -- default value to avoid errors when comparing for winner
		if DICE_DICT[primary_card] == "A" then
			hand_desc = "High Card of an " .. DICE_DICT[primary_card]
		else
			hand_desc = "High Card of a " .. DICE_DICT[primary_card]
		end
		rarity_color = Color3.fromRGB(189,189,189)
		hand_order = {hand[5], hand[4], hand[3], hand[2], hand[1]}
		
		-- award badge
		game.ServerStorage.BadgeEvent:Fire(PLAYER_ARR[player_num], "worst")
	end
	
	return hand_type, primary_card, secondary_card, hand_desc, rarity_color, hand_order
end


-- if player leaves mid round, we want to make sure all players are done
game.Players.PlayerRemoving:Connect(function()
	if game_active == 1 then
		check_if_all_players_are_done()
	end
end)


local ai_vote = ReplicatedStorage:FindFirstChild("AIVoteEvent")
ai_vote.OnServerEvent:Connect(function(player, difficulty)
	if player ~= nil and player:FindFirstChild("PlayerGui") then
		player.PlayerGui.ScreenGui.AIGui.Vote.Interactable = false
	end
	if difficulty == "Off" then
		ai_off_votes = ai_off_votes + 1
	elseif difficulty == "Easy" then
		ai_easy_votes = ai_easy_votes + 1
	elseif difficulty == "Medium" then
		ai_medium_votes = ai_medium_votes + 1
	elseif difficulty == "Hard" then
		ai_hard_votes = ai_hard_votes + 1
	end
end)




wait(2)

start_next_game_counter()
