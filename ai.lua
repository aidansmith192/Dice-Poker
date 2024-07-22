local ServerStorage = game:GetService("ServerStorage")

local DICE_DICT = {"9", "10", "J", "Q", "K", "A"}

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

-- Get reference to remote event instance
local ai_function = ServerStorage:FindFirstChild("AIFunction")
ai_function.OnInvoke = function(difficulty)
	if difficulty == "Easy" then
		return easy_ai()
	elseif difficulty == "Medium" then
		return medium_ai()
	elseif difficulty == "Hard" then
		return hard_ai()
	else
		print("error")
		--return easy_ai()
	end
end

function easy_ai()
	local hand = {}
	for i = 1, 5, 1 do
		table.insert(hand, math.random(1,6))
	end
	return determine_hand_value(hand)
end

function medium_ai()
	local hand = {}
	for i = 1, 5, 1 do
		table.insert(hand, math.random(1,6))
	end
	
	for i = 1, 2, 1 do
		local reroll = {0,0,0,0,0}
		
		local hand_copy = table.clone(hand)
		
		local ai_hand_type = 0      -- kind of hand
		local ai_primary_card = 0   -- highest part of hand
		local ai_secondary_card = 0 -- second highest part of hand
		local ai_hand_desc = 0      -- hand description
		local ai_hand_color = 0     -- hand color, to show rarity!
		local ai_hand_order = {} -- order to display players hand
		ai_hand_type, ai_primary_card, ai_secondary_card, ai_hand_desc, ai_hand_color, ai_hand_order = determine_hand_value(hand_copy)
		
		--print("loop: " .. i .. ", hand type: " .. ai_hand_type .. ", hand:")
		--print(hand)
		
		-- five of a kind
		if (ai_hand_type == 8) then
			-- improbable to beat this hand, keep it
			
		-- four of a kind
		elseif (ai_hand_type == 7) then
			-- keep four of a kind and hope for five of a kind
			for k = 1, 5, 1 do
				if hand[k] ~= ai_primary_card then
					reroll[k] = 1
				end
			end
			
		-- full house
		elseif (ai_hand_type == 6) then
			-- if we still have 2 rolls, keep the three and hope for four of a kind (66% chance)
			if i == 1 then 
				for k = 1, 5, 1 do
					if hand[k] ~= ai_primary_card then
						reroll[k] = 1
					end
				end
			else
				-- keep hand as we only have 33% to get a four of a kind, rather keep full house, 66% of the time its the better choice
			end
			
		-- straight
		elseif (ai_hand_type == 5) then
			-- hard to beat this hand, keep it
			
		-- three of a kind
		elseif (ai_hand_type == 4) then
			-- go for four or five of a kind!
			for k = 1, 5, 1 do
				if hand[k] ~= ai_primary_card then
					reroll[k] = 1
				end
			end
			
		-- two pair
		elseif (ai_hand_type == 3) then
			-- if we still have two rolls then go for a five of a kind
			if i == 1 then
				for k = 1, 5, 1 do
					if hand[k] ~= ai_primary_card then
						reroll[k] = 1
					end
				end
			else -- one roll left, damage control by going for full house and maintaining two pair
				for k = 1, 5, 1 do
					if hand[k] ~= ai_primary_card and hand[k] ~= ai_secondary_card then
						reroll[k] = 1
					end
				end
			end
		
		-- pair
		elseif (ai_hand_type == 2) then
			-- keep pair and reroll rest to hope for 5 of a kind
			for k = 1, 5, 1 do
				if hand[k] ~= ai_primary_card then
					reroll[k] = 1
				end
			end
			
		-- high card
		elseif (ai_hand_type == 1) then
			-- reroll all, hard to work with this hand
			reroll = {1,1,1,1,1}
		end
		
		--print("reroll:")
		--print(reroll)
		
		-- done choosing what to reroll, now reroll and continue
		for k = 1, 5, 1 do
			if reroll[k] == 1 then
				hand[k] = math.random(1,6)
			end
		end
	end
	return determine_hand_value(hand)
end

function hard_ai()
	local hand = {}
	for i = 1, 5, 1 do
		table.insert(hand, math.random(1,6))
	end
	
	-- two rerolls so two loops
	for i = 1, 2, 1 do
		local highest_value_reroll = {}
		local highest_value = 0
		
		--local hand_copy = table.clone(hand)
		--local ai_hand_type, _, _, _, _, _ = determine_hand_value(hand_copy)
		--print("loop: " .. i .. ", hand type: " .. ai_hand_type .. ", hand:")
		--print(hand)
	
		-- 2^5 possible locking permutations. a -> e stands for each dice and have binary value -> unlocked = 0, locked = 1
		for a = 0, 1, 1 do
			for b = 0, 1, 1 do
				for c = 0, 1, 1 do
					for d = 0, 1, 1 do
						for e = 0, 1, 1 do
							local current_reroll = {a, b, c, d, e}
							local value = estimate_hand_value(hand, current_reroll, i)
							if highest_value < value then
								highest_value = value
								highest_value_reroll = current_reroll
							end
						end
					end
				end
			end
		end
		
		--print("highest value: " .. highest_value .. ", reroll:")
		--print(highest_value_reroll)
		
		-- determined best course of action, now reroll
		for k = 1, 5, 1 do
			if highest_value_reroll[k] == 1 then
				hand[k] = math.random(1,6)
			end
		end
	end
	
	return determine_hand_value(hand)
end

function estimate_hand_value(hand, reroll, roll_count)
	
	local min = {}
	local max = {}
	
	for i = 1, 5, 1 do
		if reroll[i] == 0 then -- if not rerolling, turn range of numbers into the single number of the hand
			table.insert(min, hand[i])
			table.insert(max, hand[i])
		else -- if rerolling the die, then set the range for the for loop
			table.insert(min, 1)
			table.insert(max, 6)
		end
	end
	
	local number_of_possible_hands = 0
	local total_hand_values = 0
	
	-- 5^6 possible hands. only need to loop through the hands that are not locked
	for a = min[1], max[1], 1 do
		for b = min[2], max[2], 1 do
			for c = min[3], max[3], 1 do
				for d = min[4], max[4], 1 do
					for e = min[5], max[5] do
						local possible_hand = {a, b, c, d, e}
						local current_hand_type, primary_card, secondary_card, _, _, _ = determine_hand_value(possible_hand)
						
						-- we have another reroll after this so lets be more greedy, value higher hands more
						
						-- this is our last reroll so lets be more conservative, value higher hands less and ideally keep the most likely ~good~ hand
						
						if roll_count == 1 then
						total_hand_values = total_hand_values + 3^current_hand_type + 2^(primary_card-3)
						elseif roll_count == 2 then
							total_hand_values = total_hand_values + 2^current_hand_type
						end
						
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 3^current_hand_type
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + 2^current_hand_type
						--end
						
					-- ~2% down
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 3^current_hand_type + 2^(primary_card-1) + 2^(secondary_card-2)
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + 2^current_hand_type
						--end
						
					-- ~3%? better
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 4^current_hand_type + 3^(primary_card-1) + 2^(secondary_card-2)/2
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + 2^current_hand_type + primary_card
						--end
						
					-- ~3% up
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 3^current_hand_type + 2^(primary_card-1) + 2^(secondary_card-3)
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + 2^current_hand_type
						--end
						
					-- ~1% down
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 3^current_hand_type + (primary_card-1) + (secondary_card-2)/2
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + 3^current_hand_type
						--end
						
					-- ~1% down
						----if roll_count == 1 then
						--	total_hand_values = total_hand_values + 5^current_hand_type + (primary_card-1) + (secondary_card-2)/2
						----elseif roll_count == 2 then
						----	total_hand_values = total_hand_values + 2^current_hand_type
						----end
						
						
					-- ~1% down
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 5^current_hand_type + (primary_card-1) + (secondary_card-2)/2
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + 2^current_hand_type
						--end
						
					-- ~7% down	
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 2*current_hand_type + 2*(primary_card - 1) + 2*(secondary_card - 2)
						--elseif roll_count == 2 then
						--	total_hand_values = total_hand_values + current_hand_type
						--end
						
					-- ~10% down
						--total_hand_values = total_hand_values + 10^current_hand_type + 10^(primary_card-1) + 10^(secondary_card-2)
						
					-- ~5% down
						--if roll_count == 1 then
						--	total_hand_values = total_hand_values + 10*current_hand_type + (primary_card-1) + (secondary_card-2)/2
						--elseif roll_count == 2 then
						--		total_hand_values = total_hand_values + current_hand_type
						--end
						
						number_of_possible_hands = number_of_possible_hands + 1
					end
				end
			end
		end
	end
	
	local average_hand_value = (total_hand_values) / (number_of_possible_hands)
	--print("average hand value: " .. average_hand_value)
	return average_hand_value
end


function determine_hand_value(hand)
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
	end
	return hand_type, primary_card, secondary_card, hand_desc, rarity_color, hand_order
end





function test_best_ai()
	local score = {
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}
	}
	
	for i = 1, 600, 1 do
		local ai_easy_type, ai_easy_primary, ai_easy_secondary, _, _, _ = easy_ai()
		local ai_medium_type, ai_medium_primary, ai_medium_secondary, _, _, _ = medium_ai()
		local ai_hard_type, ai_hard_primary, ai_hard_secondary, _, _, _ = hard_ai()
		
		local ai_type = {ai_easy_type, ai_medium_type, ai_hard_type}
		local ai_primary_card = {ai_easy_primary, ai_medium_primary, ai_hard_primary}
		local ai_secondary_card = {ai_easy_secondary, ai_medium_secondary, ai_hard_secondary}
		
		local winners = {}
		local second_place_player = {}
		
		for i = 1, 3, 1 do
			if #winners == 0 then -- if winner list empty then just add first player hit
				winners = {i}
			else -- already one person that can be a winner, compare to them
				if ai_type[winners[1]] < ai_type[i] then -- compare type
					second_place_player = determine_second_place(second_place_player, winners[1], ai_type, ai_primary_card, ai_secondary_card)
					winners = {i}
				elseif ai_type[winners[1]] == ai_type[i] then
					if ai_primary_card[winners[1]] < ai_primary_card[i] then -- compare first
						second_place_player = determine_second_place(second_place_player, winners[1], ai_type, ai_primary_card, ai_secondary_card)
						winners = {i}
					elseif ai_primary_card[winners[1]] == ai_primary_card[i] then
						if ai_secondary_card[winners[1]] < ai_secondary_card[i] then -- compare second
							second_place_player = determine_second_place(second_place_player, winners[1], ai_type, ai_primary_card, ai_secondary_card)
							winners = {i}
						elseif ai_secondary_card[winners[1]] == ai_secondary_card[i] then
							table.insert(winners, i)
						else
							second_place_player = determine_second_place(second_place_player, i, ai_type, ai_primary_card, ai_secondary_card)
						end
					else
						second_place_player = determine_second_place(second_place_player, i, ai_type, ai_primary_card, ai_secondary_card)
					end
				else
					second_place_player = determine_second_place(second_place_player, i, ai_type, ai_primary_card, ai_secondary_card)
				end
			end
		end
		
		for i = 1, 3, 1 do
			if table.find(winners, i) then
				score[i][1] = score[i][1] + 1
			elseif table.find(second_place_player, i) then
				score[i][2] = score[i][2] + 1
			else
				score[i][3] = score[i][3] + 1
			end
		end
	end
	
	print(score)
	print("easy winrate: " .. score[1][1] / 600)
	print("medium winrate: " .. score[2][1] / 600)
	print("hard winrate: " .. score[3][1] / 600)
	print("total points:")
	print("easy: " .. 2*score[1][1] + 1*score[1][2] + 0*score[1][3])
	print("medium: " .. 2*score[2][1] + 1*score[2][2] + 0*score[2][3])
	print("hard: " .. 2*score[3][1] + 1*score[3][2] + 0*score[3][3])
end

function determine_second_place(second_place_player, current_player, ai_type, ai_primary_card, ai_secondary_card)
	if second_place_player[1] == nil then -- if second_place_player doesnt exists
		return {current_player}
	else -- if second_place_player exists
		if ai_type[second_place_player[1]] < ai_type[current_player] then -- compare type
			return {current_player}
		elseif ai_type[second_place_player[1]] == ai_type[current_player] then
			if ai_primary_card[second_place_player[1]] < ai_primary_card[current_player] then -- compare first
				return {current_player}
			elseif ai_primary_card[second_place_player[1]] == ai_primary_card[current_player] then
				if ai_secondary_card[second_place_player[1]] < ai_secondary_card[current_player] then -- compare second
					return {current_player}
				elseif ai_secondary_card[second_place_player[1]] == ai_secondary_card[current_player] then
					table.insert(second_place_player, current_player)
					return second_place_player
				end
			end
		end
	end
	return second_place_player
end

--test_best_ai()
