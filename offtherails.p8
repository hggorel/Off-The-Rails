pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
--basic set up sections
--in the game


function _init()
	mode = 0 --for title call
	level= 1 --for changing levels
	if mode == 0 then
		titleupdate()
	end
		
	--flags (global)
	--flag 0 = floor/coundary wall
	--flag 1 = interactable/door?

	--tables of characters

	--player table
		--[[sprites for mabel are as follows
		1 is idle sprite
		2-4 is running sprites
		5-7 is running n gunning sprites
		8 is jumping sprite
		9 is jumping w gun sprite
		10 is crouch w gun (if needed ever)
		--]]
	player ={
		movecount=1,
		sprite = 1,
		health = 50,
		lives=3,
		x = 32,
		y = 64,
		flipx=false,
		is_standing = true,
		jump_force = 3,
		run_force = 0.5,
		is_blocked_right = false,
		is_blocked_left = false,
		is_blocked_above = false,
		dy=0.0,
		dx=0.0,
		dy_max = 3,
		dx_max = 1.5,
		gravity=0.3,
		air_resistance = 0.8,
		friction = 0.5
	}

	--actors (enemies) table
	--[[
	queensguard is sprites 16-20
	16 is the idle sprite
	17-19 are moving sprites
	20 is jumping sprite
	21-25 is bames jond sprites
	21 is idle
	22-24 is running
	25 is jumping
	herlock sholmes is 26-30
	26 is idle
	27-29 is running
	30 is jumping
	--]]

	enemies = {}

	--extra people who aren't our
	--friends but aren't our enemies
	extra ={
		x = 4*8,
		y = 3*8,
		dx = 2, --speed. not properly implemented yet
		timing = .15,
		sprite = 64,
		flipx = false,
		movecount = 0 --movecount format added to match hannah
	}

	camx=0

	danger = {}
	bullets = {}
	if level == 1 then
		create_soldier(32, 64)
		create_soldier(160, 64)
	end
	

	map_x=0
	map_speed=1
	gameover=false
	levelwin=false

	lives={}
	heart1 = {
		x=1,
		y=20,
		sprite=68
	}
	heart2={
		x=9,
		y=20,
		sprite=68
	}
	heart3={
		x=17,
		y=20,
		sprite=68
	}
	add(lives, heart1)
	add(lives, heart2)
	add(lives, heart3)
end

function fire()
	local bullet = {
		sprite=56,
		x=player.x,
		y=player.y,
		dx=2,
		dy=0
	}

	if player.flipx==false then
		bullet.dx=-2
	end

	add(bullets, bullet)
end

function basic_shoot(startx, starty, flipx)
	local bullet= {
		sprite=56,
		x=startx,
		y=starty,
		dx=1,
		dy=0
	}

	if flipx then
		bullet.dx = -1
	end

	add(danger, bullet)
end

function herlock_shoot(startx, starty, targetx, targety)
	local bullet = {
		sprite = 56,
		speed = 1,
		x = startx,
		y = starty,
		dx =0,
		dy =0
	}

	local trajectory_x = targetx - startx
	local trajectory_y = targety - starty

	local trajectory_len = sqrt(trajectory_x^2 + trajectory_y^2)

	local len_to_speed = bullet.speed / trajectory_len

	bullet.dx = trajectory_x * len_to_speed
	bullet.dy = trajectory_y * len_to_speed

	add(danger, bullet)

end

function create_soldier(newx, newy)
	local actor ={
		movecount=0,
		flipx=false,
		shootcount=0,
		health = 5,
		sprite = 16,
		x = newx,
		y = newy
	}

	add(enemies, actor)
end

function create_bames(newx, newy)
	local actor = {
		movecount=0,
		flipx=false,
		shootcount=0,
		health=30,
		sprite = 21,
		x = newx,
		y = newy
	}

	add(enemies, actor)
end

function create_herlock(newx, newy)
	local actor = {
		movecount=0,
		flipx=false,
		shootcount=0,
		health=20,
		sprite=26,
		x = newx,
		y = newy
	}

	add(enemies, actor)
end

function flip_switch(right_tile, left_tile)
	if right_tile == 136 then
		mset((player.x+8)/8+map_x, player.y/8, 137)
		mset(41, 7, 151)
		mset(42, 7, 151)
		mset(43, 5, 151)
		mset(44, 5, 151)
		mset(41, 1, 132)
		mset(42, 1, 132)
		mset(43, 1, 132)
		mset(44, 1, 132)
	end
end

function moving_soldier()
	for actor in all(enemies) do
		local tile_below = mget((actor.x)/ 8+map_x, (actor.y + 7) / 8)
 	local tile_below_collidable = fget(tile_below, 0)

		local tile_above = mget((actor.x) / 8+map_x, (actor.y-1) / 8)
 	local tile_above_collidable = fget(tile_above, 0)

		local tile_right = mget((actor.x +7)/8+ map_x, actor.y/8)
		local tile_right_collidable = fget(tile_right, 0)

		local tile_left = mget((actor.x)/8+ map_x, actor.y/8)
		local tile_left_collidable = fget(tile_left, 0)

		-- if the enemy is a soldier
		if actor.sprite <=20 and actor.sprite >=16 then
			if actor.movecount<5 then
				actor.x+=1
				actor.flipx=false
			end
			if actor.movecount>5 then
				actor.flipx=true
				actor.x-=1
			end

			if actor.movecount<10 then
				actor.movecount+=1
			else
				actor.movecount=0
			end

			if actor.shootcount%20==0 then
				basic_shoot(actor.x, actor.y, actor.flipx)
			end
			actor.shootcount+=1
		end

		-- if the enemy is bames jond
		-- bames' bullets will shoot directly at
		-- our hero, even if not striaght
		if actor.sprite>=21 and actor.sprite <=25 then
			actor.x+=1
		end

		-- if the enemy is herlock sholmes
		-- we want herlock to track him down
		if actor.sprite>=26 and actor.sprite <=30 then
			if player.x < actor.x then
				 if not(tile_left_collidable) then
						actor.x -= 0.5 -- move towards
						actor.flipx = true
					end
			else
				if not(tile_right_collidable) then
					actor.x += 0.5 -- move towards
					actor.flipx = false
				end
			end
			
			if not(tile_below_collidable) then
				actor.y += player.gravity
			end

			if actor.movecount < 20 and actor.movecount/5 ==0 then
				--actor.y+=1
				actor.movecount += 1
				actor.sprite += 1
			else
				actor.sprite = 26
				actor.movecount=0
			end

			if actor.shootcount%20 == 0 then
				herlock_shoot(actor.x, actor.y, player.x, player.y)
			end
			actor.shootcount+=1
		end

	end
end

function check_jump_height(x, y)
	-- i starts at 8 because you want to start checking
	-- for collision one 8x8 block below the character.
	-- 8 < 24 will check two blocks below the character
 for i=8, 15, 1 do
 	for j=0, 7, 1 do
 		local tile = mget((player.x+j)/8+map_x, (player.y+i)/8)
 		if (fget(tile, 0)) then
 			return (i-8)
 		end
 	end
 end
	-- -1 indicates that height can not be detected because
	-- height only detects two blocks below
	-- so we must be higher than two blocks
	return 16
end

function check_ceiling_height()
	-- i starts at 0 because you want to start checking
	-- for collision one 8x8 block above the character.
	-- 8 < 24 will check two blocks above the character
 for i=1, 15, 1 do
  for j=0, 7, 1 do
  	local tile = mget((player.x + j) / 8 + map_x, (player.y - i) / 8)

			if (fget(tile, 0)) then
				return (i - 1)
			end
			
		end
	end
 -- 16 indicates that we are at least two blocks away
	return 16

end

function calculate_y_movement()

	local ceiling_height = check_ceiling_height()
	local jump_height = check_jump_height()

	if (jump_height == 0) player.is_standing = true
	if (jump_height > 0) player.is_standing = false

	-- applies gravity every frame
	if not player.is_standing then
		player.dy -= player.gravity
		if (player.dy < -3) player.dy = -3
	end

	-- if we are falling past the floor,
	-- fix it by changing dy to the height from the floor
	-- so we get sucked to the ground instead
	if (player.dy < 0) and (player.dy + jump_height < 0) then
		player.is_standing = true
		player.dy = (-1 * jump_height)
	end

	if(player.dy > 0) and (player.dy - ceiling_height > 0) then
		player.dy = (-1 * ceiling_height)
	end

	-- when the player lets go, and we are moving up
	-- then we fraction vertical velocity to start falling sooner
	if (not btn(2) and not player.is_standing and player.dy > 0) player.dy *= 0.5

 -- jump is pressed, jump up
	if btnp(2) and player.is_standing then
		player.dy += player.jump_force
		player.is_standing = false
	end

	-- make dy negative because positive dy moves character downward
 return (-1 * player.dy)
end

function check_collide_left()

	for i=1, 8, 1 do
		for j=0, 7, 1 do
			local tile = mget((player.x - i) / 8 + map_x, (player.y + j) / 8)

			if (fget(tile, 0)) return (i - 1)
		end
	end
 -- 9 indicates we are at least 1 block away
	return 9

end

function check_collide_right()

 for i=0, 7, 1 do
  for j=8, 15, 1 do
			local tile = mget((player.x + j) / 8 + map_x, (player.y + i) / 8)

			if (fget(tile, 0)) return (j - 8)
		end
	end
 -- 9 indicates we are at least 1 block away
	return 9

end

function calculate_x_movement()

	local collide_distance_right = check_collide_right()
	local collide_distance_left = check_collide_left()

	-- if we arent moving left or right,
	-- slow down the player if they are in the air
	if(not btn(1) and not btn(0) and not player.is_standing) then
	 player.dx *= player.air_resistance
	end
	-- if we are standing instead of in the air, friction is greater
 if(not btn(1) and not btn(0) and player.is_standing) then
		player.dx *= player.friction
	end

	-- move right, increases until we reach max speed
	if btn(1) then
		player.flipx = true
		player.dx += player.run_force
		if (player.dx > player.dx_max) player.dx = player.dx_max
	end

	-- move left, decreases until we reach minimum speed
	-- (-1 * player.dx_max is just the negative direction maximum)
	if btn(0) then
		player.flipx = false
		player.dx -= player.run_force
		if (player.dx < (-1 * player.dx_max)) player.dx = (-1 * player.dx_max)
	end

	if (player.dx > 0) then
		-- snaps movement right to the wall
		-- keep collide_distance_right positive because we are moving right
		if(player.dx - collide_distance_right > 0) player.dx = collide_distance_right
	end

	temp_dx = player.dx

	if (btn(0) and player.dx < 0) then
		-- snaps movement left to the wall
		-- make collide_distance_left negative cause we are moving left
		if (player.dx + collide_distance_left < 0) then
			player.dx = (-1 * collide_distance_left)
		end
 end

	return player.dx

end

 		
function move_player()

	local allowance=28
	--local speed=1
	--jump_height = check_jump_height()

	local tile_below_character = mget((player.x) / 8 + map_x, (player.y + 8) / 8)
 local tile_below_character_collidable = fget(tile_below_character, 0)
 local tile_above = mget((player.x) / 8+map_x, (player.y) / 8)
 local tile_above_collidable = fget(tile_above, 0)
	local tile_right_character = mget((player.x +8)/8+map_x, player.y/8)
	local tile_right_collidable = fget(tile_right_character, 0)
	local tile_left_character = mget((player.x)/8+map_x, player.y/8)
	local tile_left_collidable = fget(tile_left_character, 0)

	flip_switch(tile_right_character, tile_left_character)
	
	x_move = calculate_x_movement()
	y_move = calculate_y_movement()
	local speed = abs(player.dx)
	player.x += x_move
	player.y += y_move
	if x_move>0 then
		player.sprite =1+player.movecount
	end
	
 --if (tile_below_character_collidable) then
 --	player.is_standing = true
 -- player.dy = 0
 --else
 -- player.is_standing = false
 --	if (player.dy <= -3.0) then
 --		player.dy = -3.0
 --	else
 --		player.dy-=player.gravity
 --	end
 --end

 --if (tile_above_collidable) then
 --	player.is_blocked_above = true
 --	if player.is_standing then
 --		player.dy=0
 --	else
 --		player.dy=-player.gravity
 --	end
 --else
 --	player.is_blocked_above = false
 --end

 --if (tile_right_collidable) then
	--	player.is_blocked_right = true
	--else
	--	player.is_blocked_right = false
	--end

	--if (tile_left_collidable) then
	--	player.is_blocked_left = true
	--else
	--	player.is_blocked_left = false
	--end
	
	--if btnp(2) and player.is_standing and not(player.is_blocked_above) then
	--	player.dy = 3
	--	player.is_standing = false
	--end

 -- moving player based on input
	--if btn(0) and not(player.is_blocked_left) then
	--	player.flipx=false
	--	if player.x>0 then
	--		player.x-=1
	--	end
	--!!	player.sprite=1+player.movecount

		if(player.x-camx<(64-allowance)) then
			if camx<=0 then
				camx=0
			else
				camx-=speed
			end
		end

	--end
	--if btn(1) and not(player.is_blocked_right) then
	--	player.flipx=true
	--	if player.x<240 then
	--		player.x+=1
	--	end
	--!!	player.sprite =1+player.movecount
		--map_x-=map_speed
		if (player.x-camx>(64+allowance)) then
			if camx<=120 then
				camx+=speed
			end
		end
	--end

	--if(player.dy < 0 and (player.dy + jump_height)<0 and jump_height>0) then
	--	player.dy = (-1 * jump_height)
	--end

 -- make dy negative because positive dy moves character downward
 --player.y += (-1 * player.dy)

 if btnp(3) then
 	local tile_character_on = mget(player.x / 8+map_x, player.y / 8)
 	if tile_character_on == 60 then
 		mset(player.x/8+map_x, player.y/8, 61)
 		mset(player.x/8+map_x, (player.y-8)/8, 45)
 	end
 	if tile_character_on == 178 then
 		mset(player.x/8+map_x, player.y/8, 179)
 		mset(player.x/8+map_x, (player.y-8)/8, 163)
 	end
 	if tile_character_on ==61 or tile_character_on == 179 then
 		level+=1
 		if (level==2) then
 			create_soldier(120, 24)
				create_soldier(130, 64)
				create_herlock(120, 64)
				map_x=36
				player.x=176
				player.y=72
			end
			
			if level == 3 then
				gamewin=true
			end
			
 	end
 	
 	if tile_character_on ==57 then
 		mset(player.x/8, player.y/8, 58)
 		mset(23, 7, 50)
 		mset(23, 8, 49)
 	end
 end

	if btnp(4) and mode == 1 then
		fire()
	end

	--we dont use 5 yet i think?
	--so this is for title to game
	if btnp(❎) and mode == 0 then
		mode = 1
	end

	-- switching to see animation
	if player.movecount==3 then
		player.movecount=1
	end
	if player.movecount<3 then
		player.movecount+=1
	end

end

function _update()
	--mode updates
	if mode == 0 then
		titleupdate()
	elseif mode == 1 then
		gameupdate()
	else
		pauseupdate()
	end

	--gameplay mode updates
	if mode == 1 then
	
	local player_right_character = mget((player.x +8)/8, player.y/8)
	local player_right_collidable = fget(player_right_character, 0)

	local player_left_character = mget((player.x)/8, player.y/8)
	local player_left_collidable = fget(player_left_character, 0)

	-- moving all of the bullets
	for b in all(bullets) do
		local tile_below = mget(b.x / 8, (b.y + 8) / 8)
 	local tile_below_collidable = fget(tile_below, 0)

		local tile_above = mget((b.x+4) / 8, (b.y-1) / 8)
 	local tile_above_collidable = fget(tile_above, 0)

		local tile_right = mget((b.x +8)/8, b.y/8)
		local tile_right_collidable = fget(tile_right, 0)

		local tile_left = mget((b.x)/8, b.y/8)
		local tile_left_collidable = fget(tile_left, 0)
		
		b.x+=b.dx
		b.y+=b.dy
		
		if b.dx < 0 and tile_left_collidable then
			del(bullets, b)
		elseif b.dx > 0 and tile_right_collidable then
			del(bullets, b)
		elseif b.dy < 0 and tile_above_collidable then
			del(bullets, b)
		elseif b.dy > 0 and tile_below_collidable then
			del(bullets, b)
		end
		
		if b.x<camx-128 or b.x > camx+128 or b.y < 0 or b.y>128 then
			del(bullets, b)
		end
	end

	for e in all(danger) do
		local tile_below = mget(e.x / 8, (e.y + 8) / 8)
 	local tile_below_collidable = fget(tile_below, 0)

		local tile_above = mget((e.x+4) / 8, (e.y-1) / 8)
 	local tile_above_collidable = fget(tile_above, 0)

		local tile_right = mget((e.x +8)/8, e.y/8)
		local tile_right_collidable = fget(tile_right, 0)

		local tile_left = mget((e.x)/8, e.y/8)
		local tile_left_collidable = fget(tile_left, 0)
		
		e.x+=e.dx
		e.y+=e.dy
		
		if e.dx < 0 and tile_left_collidable then
			del(danger, e)
		elseif e.dx > 0 and tile_right_collidable then
			del(danger, e)
		elseif e.dy < 0 and tile_above_collidable then
			del(danger, e)
		elseif e.dy > 0 and tile_below_collidable then
			del(danger, e)
		end
		
		if e.x<camx-128 or e.x>camx+128 or e.y<0 or e.y>128 then
			del(danger, e)
		end
	end

	if camx>=130 then
		camx=130
	end

	move_player()

	moving_soldier()

	-- removing enemies that have been shot
	for e in all(enemies) do
		for b in all(bullets) do
			if abs(b.x - e.x)<=1 and abs(b.y-e.y)<=5 then
				e.health-=5
				del(bullets, b)
				if e.health <=0 then
					del(enemies, e)
				end
			end
		end
	end

	for b in all(danger) do
		if abs(b.x - player.x)<=1 and abs(b.y - player.y)<=5 then
			if b.dx>0 and not(player_right_collidable) then
				player.x+=1
			end
			if b.dx < 0 and not(player_left_collidable) and player.x>0 then
				player.x-=1
			end
			player.health-=5
			del(danger, b)
		end
	end

	if player.health<=0 then
		player.health=50
		player.lives-=1
		if player.lives==2 then
			del(lives, heart3)
		end
		if player.lives==1 then
			del(lives, heart2)
		end
		if player.lives==0 then
			del(lives, heart1)
			gameover=true
		end
		--ask elise to make a sprite to show defeat??
		--^ this will be sprite 10 :)
	end
	end --should end gameplay mode

end

--changing modes
--settings screen not fully implemented yet
function titleupdate()
	if btnp(❎) then
		mode = 1
	end
end

--need to make it so health cannot be lost
--during pause
function pauseupdate()
	if(btnp(❎) ) then
		mode = 1
	end
end

--x for pause
function gameupdate()
	if(btnp(❎) ) then
		mode = 2 --pause screen
	end
end

--glocal sprite tables (for nongame screens)
	train={
	x=1*8,
	y=112,
	sprite=80, --80-87
	l=7,
	h=1
	}

	smoke={
	x=53,
	y=104,
	sprite=69,
	a=.25
	}

	title={
	sp=0,
	w=8,
	h=2
	}
	--inventory select box
	sel={ --short for select, an existing command
	x=18,
	y=18,
	move=15,
	minx=19,
	maxx=79,
	place=0
	}
	mode = 0 --for changing between modes
	level = 0 --for changing between levels
	--the above value could also be apart of the player table?

	cloud={
	spr1=51,
	spr2=52,
	x=0,
	y=20
	}

-->8
--map section
--[[
tile 32 is a basic floor tile
tiles 33-34-49-50 are\
	train windows
 [left transparent for animation behind)
 train walls
	tile 48 is a suitcase (to be drawn on layered)
	tiles 35-40 are train sprites
	tile 51-52 are clouds (for animation)
	tile 53 is blue sky (for animation)
	tile 54-55 is mountains (for animation)
	tile 41 is a bench
	tile 42 is a table
	room is left for other versions of these items

	tabs 1 and 2 have spare sprites and tuajuanda
	map is empty for level designer
--]]
function _draw()
	if mode == 0 then
		titledraw()
	elseif mode == 1 then
		gamedraw()
	else
		pausedraw()
	end

end

function gamedraw()
	if level==1 and levelwin==false and gameover==false then
 	cls(5)
 	camera(camx, -16)
 	--camera(0, -16)
 	--multiple in editor values by 8 to match map values
		drawclouds() --cloud animation 9*8
 	--map(0,0,map_x,0,32*8,9*8)
 	--map(16,0,map_x+128, 0, 32*8, 9*8)
 	map(0, 0, 0, 0, 32*8, 9*8)
 	_drawmapsprites()
 	_moveextra()
 	spr(extra.sprite,extra.x,extra.y,1,1,extra.flipx,false)
		if player.lives>0 then
			spr(player.sprite, player.x, player.y, 1, 1, player.flipx, false)
		end

		for e in all(enemies) do
			spr(e.sprite, e.x, e.y, 1, 1, e.flipx, false)
		end
		for b in all(bullets) do
			spr(b.sprite, b.x, b.y)
		end
		for b in all(danger) do
			spr(b.sprite, b.x, b.y)
		end

		camera()
		print('health', 1, 1, 6)
		rectfill(1,8, player.health,9,8)
		print('lives', 1, 13, 6)
		for h in all(lives) do
			spr(h.sprite, h.x, h.y)
		end
	end

	if gameover then
		-- draw new game over screen
		cls(1)
		print('game over', 7)
		print('youll be executed', 13)
		print('tomorrow at dawn', 13)
		print('your village gets nothing', 13)
		spr(77,112,112,2,2) --prints execution sprite
	end

	if level == 2 then
		level2draw()
	end
	
	if gamewin then
		cls(1)
		_winscreen()
	end
	
end

function _winscreen()
	color(1)
	rect(0, 0, 127, 127)
	spr(103,45,45,4,2)
	spr(11, 50, 80)
	print("the crown is yours, congrats!", 45, 90)
end

function _drawmapsprites()
	--multiplied in editor values by eight to fit map values
		--these should all be drawn behind the player
		--so this function will be called before the player is drawm
		--top level of car
		if level == 1 then
		spr(41,08*8,03*8,1,1,true,false) --booth 1
		spr(41,10*8,03*8)	--booth 2
		spr(41,15*8,03*8,1,1,true,false) --booth 3
		spr(41,17*8,03*8) --booth 4
		spr(42,09*8,03*8) --table 1
		spr(42,16*8,03*8) --table 2
		end
		if level == 2 then
		spr(42,12*8,03*8) --table 2
		spr(42,16*8,03*8) --table 3
		end
		--bottom level of car
		if level == 1 then
		spr(41,04*8,08*8,1,1,true,false)
		spr(41,07*8,08*8) --booths
		spr(41,11*8,08*8,1,1,true,false) 
		spr(41,14*8,08*8) 
		spr(41,18*8,08*8,1,1,true,false)
		spr(41,21*8,08*8)
		end
		if level == 2 then
		spr(42,12*8,08*8) --table 2
		spr(42,16*8,08*8) --table 3
		end
end

function titledraw()
	cls()
	color(12)
	pal(12, 140, 1)
	rectfill(0, 0, 127, 127)
		titleanimate()
	spr(train.sprite,train.x,train.y,train.l,train.h,true,false)
	spr(smoke.sprite,smoke.x,smoke.y)
	map(0,19,1,112,14*8,6*8)
	color(1)
	rect(0, 0, 127, 127)
		print("press x to start",3,3,7)
		print("press z for settings",3,13,7)
		spr(107,45,45,4,2)
	if btn(🅾️) then --🅾️ is z
		settings = true
	end
	if settings then
		setting()
	end
end

function titleanimate()
train.x+=.75
smoke.x+=.75

if train.x >= 145  then
	train.x = -50
	smoke.x = -6
end

smoke.sprite += .38

if smoke.sprite > 73 then
 smoke.sprite = 69

end

end

function pausedraw()
		rectmove()
		color(14)
		pal(14,131,1) --replace pink with 131
		rectfill(8, 8, 119, 119)
		print("inventory",10,10,7)
		spr(11,20,20) --queens crown
		spr(100,35,20) --gun
		spr(101,50,20) --shotgun
		rect(sel.x,sel.y,sel.x+12,sel.y+12,8)
		if sel.place == 0 then
			print("the queen's crown:", 20,40,7)
			print("you stole this.",25,50,7)
		end
		if sel.place == 1 then
			print("your trusty pistol:",20,40,7)
			print("you should equip this.",15,50,7)
		end
		if sel.place == 2 then
		print("a shotgun:",20,40,7)
		print("just like your pappy used.",15,50,7)
		end

end

--for inventory
function rectmove()
	if btnp(➡️) and sel.x < sel.maxx then
		sel.x += sel.move
		sel.place += 1 --for print out
	end
	if btnp(⬅️) and sel.x > sel.minx then
		sel.x -= sel.move
		sel.place -=1
	end

end

--for map 2 must use palette to swap
--so that gray in background doesnt belnd in w gun
function level2draw()
	cls(0)
 camera(camx, -16)
 pal(13,134,1)
 drawclouds() 
 map(36, 0, 0, 0, 32*8, 9*8)
 _drawmapsprites()
 _moveextra()
 spr(extra.sprite,extra.x,extra.y,1,1,extra.flipx,false)
	if player.lives>0 then
		spr(player.sprite, player.x, player.y, 1, 1, player.flipx, false)
	end
		
	for e in all(enemies) do
		spr(e.sprite, e.x, e.y, 1, 1, e.flipx, false)
	end
	for b in all(bullets) do
		spr(b.sprite, b.x, b.y)
	end
	for b in all(danger) do
		spr(b.sprite, b.x, b.y)
	end

	camera()
	print('health', 1, 1, 6)
	rectfill(1,8, player.health,9,8)
	print('lives', 1, 13, 6)
	for h in all(lives) do
		spr(h.sprite, h.x, h.y)
	end
end

--settings
function setting()
	cls()
	--this first thing is unimplemented ♥
	print("press ⬆️ for colorblind settings",0,20,7)
	--pass some value to gamedraw
	--this will be implemented later
	print("in game instructions:",15,30,7)
	print("use arrow keys to move",10,40,7)
	print("press z to shoot", 20,50,7)
	print("press ⬇️ to interact",17,60,7)
	print("press x for inventory", 15,70,7)
end
--for color blind people
function colorflip()
	if cblind then
		color(3,130,1)
		--this color may look bad
		--but should replace green to avoid red green problem
	end
end

-->8
--movement section
function _moveextra()
		--animate
		extra.sprite +=extra.timing

		if(extra.sprite > 66) then
			extra.sprite = 64

		end

		--dx needs to be added
		if extra.movecount < 5 then
		 extra.x += 4/extra.dx
		 extra.flipx = false
		 end

		if extra.movecount > 5 then
		 extra.x -= 4/extra.dx
		 extra.flipx = true

		 end

		if extra.movecount< 10 then
			extra.movecount += 1
		else
			extra.movecount = 0
		end



	end

function drawclouds()
	pal() --reset blue for the clouds
	--for draw state
	if level == 1 then
	rectfill(0,10,260,70,12)
	moveclouds()
	spr(cloud.spr1,cloud.x,cloud.y)
	spr(cloud.spr2,cloud.x+10,cloud.y+37)
	end
	if level == 2 then
	rectfill(0,0,220,75,12) --number not quite right
	moveclouds()
	spr(cloud.spr1,cloud.x,cloud.y)
	spr(cloud.spr2,cloud.x+10,cloud.y+37)
	spr(cloud.spr1,cloud.x+30,cloud.y-22)
	end
end

function moveclouds()
cloud.x += .5

if cloud.x > 260 then
	cloud.x = -5
end
end

__gfx__
00000000008888800088880000888800008888000088880000888800008888000088888000888880008888000000a00000777700000ccc000000100000000000
0000000008fff88000f8888000f8888000f8888000f8888000f8888000f8888008fff88008fff88008fff880000aa0007071716000c66f000001110000000000
0aaa0000083f388000f3888000f3888800f3888800f38880003f888800f38888883f3888083f3888083f388000aaaa007777776700c6fff0001a111000000000
0a9aaa0008fff88000ff888000ff888800ff888800ff888000ff888800ff8888f8fff8f8088ff458f8fff8f002272220077717600cccff00007cfc7000000000
0aaaa0000111118052111880521118805211180054111880541118805411180011111110008141f0011111100a8aa8a0077777600eeeee00017fff7100000000
0aaaa000011111000f2110000f2110000f2110000f4110000f4110000f41100000111000001f1000081118800a2a82a0007777600eeeef000f17771f00000000
009040000f101f0000101500001010000015100000101500001010000015100000151500001515000011104500222200000777600eeeee0001a7711000000000
00000000005050000050000000505000000050000050000000505000000050000000000000000000051514000777777000007666eeeeee00111711a100000000
01110000001110000011100000111000011100000044400000444000004440000044400000444000000000000000000000000000000000000044400000000000
0111000000111000001110000011100001110000004fc000004fc000004fc000004fc000004fc000004440000044400000444000004440000044440000000000
0111000000111000001110000011100001ff000000fff00000fff00000fff00000fff00000fff0000044440000444400004444000044440004fff06000000000
01ff0000001ff000001ff000001ff00008880000001770550017705500177055001770550017705504fff00004fff00004fff00004fff0600044440000000000
088800000088845500888000008884550788f55000117f0000117f0000117f0000117f0000117f00004440600044406000444060004444000444400000000000
0787455000784f000078745500784f000884000000f1100000f1100000f1100000f1100000f11000004444000044440000444400004440000101000000000000
0884f0000188800001884f0000888000101000000010100000101000051010000010100005151000004440000144400001444000004440000000000000000000
01010000000100000000100001010000000000000050500005050000000050000505000000000000001010000001000000001000000101000000000000000000
88888888333333333333333300888888888118888888228888880033b33333333333300000000022000080004444444434444443344444433333333300000000
aaaaaaaa3366666666666633008cddd6888118dcc6d88cdcccc8003ccc6633bdccdc300000000022000cc0004433334445666654456666543366663300000000
a999999a360000000000006300cccdd6888008c6cddc86dcccc8003c6dccc33ccd66300000000022000cc0004344443446333364463333643600006300000000
a9aaaa9a3600000000000063088cc6dc888008cdcdd88cd6ccc8003cddccc33cdd6c300000000022444444444344443446333364463333643600006300000000
a9aaaa9a36000000000000638a8888888880082888882888882800333bb333b33333300002222222000440004344443445666654456669543600006300000000
a999999a36000000000000632282882200811822888222888228003333333333bbb3300002222222000440004344443449999994400009943600006300000000
aaaaaaaa360000000000006388112288811008811888888118881133113333333113311005444445000440004433334449555594400009943600006300000000
99999999336666666666663300110000011000011000000110000000110000000110000005500055005555004444444449555594400009943600006300000000
0000000033333333333333330000000000000000cccccccc00000000000000000000000033333333333333333444444349999994400009943600006300000000
000aa000b3b3b3b3333333330000000007700770cccccccc000d0000000000000000000033333333333333333444444345999994400005943600006300000000
00a00a003b3b3b3b333333330000000077770000cccccccc00ddd000000000000000000033333333333333333444444345999994400005943600006300000000
4544445433333333333333330000000000000000cccccccc0ddddd00000000000000000033333333333333333666666349999994400009943600006300000000
4544445433333333333333330077700000000000ccccccccddddddd00dddd0000066000033999933333333333666666349999994400009943600006300000000
4544445433333333333333330777777000000700ccccccccddddddddddddddd00000000033888833339999333444444349999994400009943600006300000000
45444454bbbbbbbb333333337777777700077770ccccccccdddddddddddddddd00000000b444444bb444444b3444444349999994400009943600006300000000
4544445433333333333333330000000000000000ccccccccdddddddddddddddd0000000044444444444444443444444349999994400000943666666300000000
000ccc0000000000001111100001111000000000000000000c0000000000000000000000000000000ca0000000c0000000000000000000000000000000000000
00c66f0000cccc0001444110001111100660660007000000000000006070000067000000670000000cca7000000a000000000000000088888000000000000000
00c6fff000c6fff001343111000c4cd0666666600000000000d7c00000c60000066000000660000000ca0000000c000000000000000088fff800000000000000
0cccff000cc6ff001144411100d444d0066666000d7c00000dd660000dd00000cd7c0000cd7c0000000aa0000000ca00000c00000000883f3800000000000000
0eeeee000eeeeef01555551000111110006660000dd66700000d670000d667000dd667000dd667000000a00000000a000000ca00000088fff800000000000000
0eeeef000eeeee0005555500001111100006000000ddd600000dd000000dd60000ddd60000ddd6000000ca00000000a0000000a0000088555000000000000000
0eeeee000eeeee0004101400004d0d40000000000000d0600000d6600000d0600000dd600000d660000000c00000000a000000a0000087777500000000000000
eeeeee000eeeeee000505000000d0d00000000000000000000000000000000000000000000000000000000000000000000000000000075555700000000000000
00888888888118888888228888880033b333333333333000333b3333333333300000000000000000000000000000000000000000000057777500004400000000
008cddd6888118dcc6d88cdcccc8003ccc6633bdccdc3000ccccccb33ccccc3000000000000000000000000000000000000000000000f5555f00004400000000
00cccdd6888008c6cddc86dcccc8003c6dccc33ccd663000cdccccc33dcc7c300000000000000000000000000000000000000000000007777000444400000000
088cc6dc888008cdcdd88cd6ccc8003cddccc33cdd6c3000dcc77cc33ccccc300000000000000000000000000000000000000000000005555000444400000000
8a8888888880082888882888882800333bb333b3333330003b333333d333b3300000000000000000000000000000000000000000000007007044444400000000
2282882200811822888222888228003333333333bbb3300033333bb3333333300000000000000000000000000000000000000000000005005044444400000000
88112288811008811888888118881133113333333113311033113333333113310400000004000000000000000000000000000000555558858855555500000000
00110000011000011000000110000000110000000110000000000000000000005455555554555545000000000000000000000000555555555555555500000000
333330003bb3b33300001000000010000000000000000000000000000000000000000000000000000000000000aaaa00aa000aa0000000000000000000000000
33333b0044343b440001110000011100000000000000000000000000000000000000000000000000000000005a005a5a05a5a05a05a05a0005a0000000000000
9999993044444444001a1110001a1110015555550155555000000000560560000000000000000000000000005a005a5a0005a0000aaa5a005a5a000000000000
3003980044444444007cfc70007cfc70041111500411150000000000560560566056560000000000000000005a005a5aaa05aaa005a05aaa5aaa000000000000
30d3980044444444017fff710f7fff7f445000004450000000000000566665605656560000000000000000005a005a5a0005a00005a05a5a5a00000000000000
99999800444444440f17771f01177711440000004400000000000000005605605656560000000000000000005a005a5a0005a00005a05a5a5a5a005a00000000
9999999a4444445501a7711001a177100000000044000000000000000056005660056600000000000000000005aaaa5a0005a000005a5a5a05a0005a00000000
4444444455444444111711a1111117a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000005a00000000
3bb3b333333b333b000000000000000000000000000000000000000000000000000000000000000000000000005aaaa00000000000d00000000005a000000000
4b333bb44333b344000000000000000000000000000000000000000056666000000000006600000000600000005a005a00000005a00da000000005a000000000
34444444444b4445000000000000000000000000000000000000000056056000000000000560000006560000005a005a00aaa0000000ad05aa005a0000000000
4944444444444944000000000000000000000000000000000000000056000056605660566565666056660000005aaaa000005a05a05a000a00a05a0000000000
4499494454499444000000000000000000000000000000000000000056600060565600600665605656000000005a05a005aa5a05a05a0005a000000000000000
9445444444444444000000000000000000000000000000000000000056056056005600600665605656560000005a05a00a05aa05a5a005a05a005a0000000000
5554455555445444000000000000000000000000000000000000000056666560605660566565666056600000005a05aa05aa5a05a5a0005aa000000000000000
55444455445544440000000000000000000000000000000000000000000000560000000000056000000000000000000000000000000000000000000000000000
0000000000000000aaaaaaaa44444444dddd6ddddddddddddddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000
0000666660000000ad66666a4a5555a4dddd6ddddd44444444444444444444ddddddd99dd99ddddd000000000000000000000000000000000000000000000000
0000644460000000ad64446a45555554ddddddddd4000000000000000000004dddddd49dd94ddddd000000000000000000000000000000000000000000000000
0000614160000000ad61416a45545554ddddddddd4000000000000000000004ddddd44dddd44dddd000000000000000000000000000000000000000000000000
0000044400000000ad64446a45554554ddddddddd4000000000000000000004dddd44dddddd44ddd000000000000000000000000000000000000000000000000
0000044000000000add44dda45555554d6ddddddd4000000000000000000004ddd44dddddd4444dd000000000000000000000000000000000000000000000000
0041444414000000a111111a4a5555a4d6ddddddd4000000000000000000004dd46444ddd44464dd000000000000000000000000000000000000000000000000
0041111114000000aaaaaaaa44444444dddd6ddddd44444444444444444444dd4446444444464444000000000000000000000000000000000000000000000000
004444411400000044444444d6dddd6d666666664464444444444444444444440000000000000000000000000000000000000000000000000000000000000000
000114644400000044555544d6dddd6d444444444464444444666644495555a40000000000000000000000000000000000000000000000000000000000000000
000111111000000045555554dd6dd6dd444664444666666446444464455555540000000000000000000000000000000000000000000000000000000000000000
000111111000000045554554dd6dd6dd466666644444444446444464455455540000000000000000000000000000000000000000000000000000000000000000
000111111000000045545554dd6dd6dd464664644444444446444464455545540000000000000000000000000000000000000000000000000000000000000000
000111111000000045555554d6dddd6d466666644666666446444464455555540000000000000000000000000000000000000000000000000000000000000000
000040040000000044555544d6dddd6d4446644444444644446666444a5555940000000000000000000000000000000000000000000000000000000000000000
000550055000000044444444d6dddd6d444444444444464444444444444444440000000000000000000000000000000000000000000000000000000000000000
0000000000000000d777777dd777777d4aaaaaa4d777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007566665775666657aa44449a7566665775666657000000000000000000000000000000000000000000000000000000000000000000000000
007007000000000076dddd6776dddd67a494494a76dddd6776dddd67000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000076dddd6776dddd67a44a944a76dddd6776dddd67000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000007566665775666957a449944a7566695775666657000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007999999770000997a494494a7555599779999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007955559770000997a944449a7555599779555597000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000079555597700009974aaaaaa47555599779555597000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000007555599779999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007599999770000597000000007555559775999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007599999770000597000000007555559775999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000007555599779999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000007555599775555557000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000007555599775555557000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000007555599779999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000097000000007555599779999997000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000010000000000000000000000020200000200000000000000000000010202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000100010101010000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
203232322b32322b3232322b32322b3232322b32322b3232322b2b3232323220000000009584848493858686879384848485868784848493848484849384848495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2032323232323232323232323232323232323232323232323232323232323220000000009584848493979797979384848484848484848493848484849384848495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203232322e32322e3232322e32322e3232322e32322e3232322e2e32322e3220000000009584828493848484849384858784848485878493848484849384828495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203232323e31313e3131313e31313e3131313e31313e3131313e3e31393e312000000000958484849384848484938484848484848484849384a2a2849384848495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203232322020202020202020202020202020202020202020202020202020202000000000959292928384848484839292929292929292929284b2b2849292929295000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203220322b32322b3232322b32322b3232322b32322b3220322b2b3232322b20000000009584848493848484849384848484848484848483929292928384848495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2032323232323232323232323232323232323232323232203232323232323220000000009584848493848484849384848484848484848493848484849384848495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020322122323221223221223232212232212232322122323221223232212220000000009585868793858686879384858784848485878493848484849385868795000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203131313131313131313131313131313131313131313132322c2c323131312000000000958488849384848484938484848484848484849384a6a5849384848495000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202020202020202020202020202020202020202020202020313c3c312020202000000000969494949484848484949494949494949494949484b6b5849494949696000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000002020202020200000000000000000000000969494949496a1000000000000000096949494949600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6058585958585958585958585959595958000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7061707161617170616161716161707161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
