pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

--basic set up sections
--in the game


function _init()
	mode = 0 --for title call
	level= 1 --for changing levels
	colblind = 0 --for colorblind settings
	if mode == 0 then
		titleupdate()
	end
	
	--figure out music funtions
	--better
	music(0)

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
		ammo_count = 12,
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
		dx_max = 1,
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
		x1 = 10*8,
		y = 3*8,
		y1 = 8*8,
		dx = 2, --speed. not properly implemented yet
		timing = .15,
		sprite = 64,
		spr1 = 66,
		spr2 = 74,
		flipx = false,
		movecount = 0 --movecount format added to match hannah
	}

	camx=0

	danger = {}
	bullets = {}
	if level == 1 then
		create_soldier(40, 64)
		create_soldier(160, 64)
	end
	

	map_x=0
	map_speed=1
	gameover=false
	levelwin=false

	lives={}
	heart1 = {
		x=60,
		y=0,
		sprite=68
	}
	heart2={
		x=68,
		y=0,
		sprite=68
	}
	heart3={
		x=76,
		y=0,
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
		dx=3,
		dy=0
	}

	if player.flipx==false then
		bullet.dx=-3
		bullet.x-=3
	else
		bullet.x+=5
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


--adding a wizard function
function create_merlin(newx, newy)
	local actor = {
		movecount=0,
		flipx=false,
		shootcount=0,
		health=33, --undecided on health
		sprite=98,
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

function grab_suitcase(tile_on)
	if tile_on == 48 then
		mset(player.x/8+ map_x, player.y/8, 49)
		player.ammo_count += 12
	end
	if tile_on == 47 then
		mset(player.x/8 + map_x, player.y/8, 132)
		player.ammo_count += 12
	end
end

function moving_soldier()
	for actor in all(enemies) do
		local tile_below = mget((actor.x)/ 8+map_x, (actor.y + 8) / 8)
 	local tile_below_collidable = fget(tile_below, 0)

		local tile_above = mget((actor.x) / 8+map_x, (actor.y) / 8)
 	local tile_above_collidable = fget(tile_above, 0)

		local tile_right = mget((actor.x +8)/8+ map_x, actor.y/8)
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
		

		-- if the enemy is bames jond
		-- bames' bullets will shoot directly at
		-- our hero, even if not striaght
		elseif actor.sprite>=21 and actor.sprite <=25 then
			actor.x+=1
		

		-- if the enemy is herlock sholmes
		-- we want herlock to track him down
		elseif actor.sprite>=26 and actor.sprite <=30 then
			if not(tile_below_collidable) then
				actor.y += player.gravity
			elseif player.x < actor.x then
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
	
	--wizard movement
	if actor.sprite >= 98 or actor.sprite <= 99 then

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

	local allowance=14
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
	grab_suitcase(tile_left_character)
	
	x_move = calculate_x_movement()
	y_move = calculate_y_movement()
	local speed = abs(player.dx)
	player.x += x_move
	player.y += y_move
	
	if abs(x_move)>0 then
			-- switching to see animation
		if player.movecount==3 then
			player.movecount=1
		end
		if player.movecount<3 then
			player.movecount+=1
		end
		player.sprite =1+player.movecount
	end

	if(player.x-camx<(64-allowance)) then
		if camx<=0 then
			camx=0
		else
			camx-=speed
		end
	end

	if (player.x-camx>(64+allowance)) then
		if camx<=120 then
			camx+=speed
		end
	end

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
 	if level == 3 and tile_character_on == 57 then
 		mset(player.x/8 + map_x, player.y/8, 58)
 		mset(91, 8, 49)
 		mset(91, 7, 50)
 		mset(91, 6, 50)
 	end
 	if tile_character_on ==61 or tile_character_on == 179 then
 		level+=1
 		sfx(03)
 		if (level==2) then
 			for e in all(enemies) do
 				del(enemies, e)
 			end
 			create_soldier(120, 24)
				create_soldier(130, 64)
				create_herlock(120, 64)
				map_x=36
				player.x=176
				player.y=72
			end
			
			if level == 3 then
				for e in all(enemies) do
					del(enemies, e)
				end
				create_herlock(120, 64)
				create_herlock(120, 32)
				map_x = 67
				player.x = 150
				player.y = 64
			end
			
			if level == 4 then
				gamewin = true
			end
			
 	end
 	
 	if tile_character_on ==57 then
 		mset(player.x/8, player.y/8, 58)
 		mset(23, 7, 50)
 		mset(23, 8, 49)
 	end
 end

	if btnp(4) and mode == 1 then
		if player.ammo_count>0 then
			fire()
			player.ammo_count-=1
			sfx(04)
		else
			sfx(05)
		end
	end

	--we dont use 5 yet i think?
	--so this is for title to game
	if btnp(❎) and mode == 0 then
		mode = 1
	end

end

function _update()
	--mode updates
	if mode == 0 then
		titleupdate()
		colorflip()
	elseif mode == 1 then
		gameupdate()
	else
		pauseupdate()
	end
	--colorblind settings? 
	
	--gameplay mode updates
	if mode == 1 then
	
	local player_right_character = mget((player.x +8)/8 + map_x, player.y/8)
	local player_right_collidable = fget(player_right_character, 0)

	local player_left_character = mget((player.x)/8 + map_x, player.y/8)
	local player_left_collidable = fget(player_left_character, 0)

	-- moving all of the bullets
	for b in all(bullets) do
		local tile_below = mget(b.x / 8+map_x, (b.y + 8) / 8)
 	local tile_below_collidable = fget(tile_below, 0)

		local tile_above = mget((b.x) / 8 + map_x, (b.y-1) / 8)
 	local tile_above_collidable = fget(tile_above, 0)

		local tile_right = mget((b.x +8)/8 + map_x, b.y/8)
		local tile_right_collidable = fget(tile_right, 0)

		local tile_left = mget((b.x)/8 + map_x, b.y/8)
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
		local tile_below = mget(e.x / 8 + map_x, (e.y + 8) / 8)
 	local tile_below_collidable = fget(tile_below, 0)

		local tile_above = mget((e.x+4) / 8 + map_x, (e.y-1) / 8)
 	local tile_above_collidable = fget(tile_above, 0)

		local tile_right = mget((e.x +8)/8 + map_x, e.y/8)
		local tile_right_collidable = fget(tile_right, 0)

		local tile_left = mget((e.x)/8 + map_x, e.y/8)
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
	
	print(player.ammo_count, 100, 110)

end


	
function gamedraw()
	--will need to readjust levels for tutorial map
	if level==1 and levelwin==false and gameover==false then
 	cls(5)
 	camera(camx, -16)
 	--camera(0, -16)
 	--multiple in editor values by 8 to match map values
		drawclouds() --cloud animation 9*8
 	--map(0,0,map_x,0,32*8,9*8)
 	--map(16,0,map_x+128, 0, 32*8, 9*8)

		--test this
 	if colblind == 1 then
 	pal(3,130,1)--check this
 	pal(11,137,1)
 	end
 	if colblind == 0 then
 	pal()
 	end
 	
 	map(0, 0, 0, 0, 32*8, 9*8)
 	_drawmapsprites()
 	_moveextra()
 	spr(extra.sprite,extra.x,extra.y,1,1,extra.flipx,false)
 	spr(extra.spr1,extra.x1,extra.y1,1,1,extra.flipx,false)
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
		print('lives', 40, 1, 6)
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

	if level == 2 and gameover == false then
		level2draw()
	end
	
	if level == 3 and gameover == false then
		level3draw()
	end
	
	if gamewin then
		cls(1)
		_winscreen()
	end
	
end

function _winscreen()
	color(1)
	--rect(0, 0, 127, 127)
	spr(103,45,45,4,2)
	spr(11, 50, 80)
	spr(142, 60, 76, 4,2)
	print("the crown is yours, congrats!", 13)
	print("you successfully get out of", 13)
	print("england, leaving the queen", 13)
	print("crown-less and upset, hurrah!", 13)
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
		print("press ❎ to start",3,3,7)
		print("press 🅾️ for instructions",3,11,7)
		print("press ➡️ for story",3,19,7)
		spr(107,45,45,4,2)
	if cc > 0 then
	drawcutscene() --trying here
	end
	if btn(🅾️) then --🅾️ is z
		settings = true
	end
	if settings then
		setting()
	end
	if btnp(➡️) then
		ccplus() --story
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
		spr(13,35,20) --gun
		spr(12,50,20) --shotgun
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
		if sel.place >= 1 and sel.place < 3 then
		equip(true) --should work like this?
		rect(27,68,27+48,68+8,7)
		print("🅾️ to equip",30,70,7)
		end
end

--for inventory
function equip(truth) 
	if mode == 2 and truth and btnp(🅾️) then
		--we'll have to have multiple gun types coded before i do anything here
	end
--idk what to do for this
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
 spr(extra.sprite,extra.x-15,extra.y,1,1,extra.flipx,false)
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
	print('lives', 40, 1, 6)
	for h in all(lives) do
		spr(h.sprite, h.x, h.y)
	end
end

function level3draw()
	cls(0)
 camera(camx, -16)
 pal(13,134,1)
 drawclouds() 
 map(67, 0, 0, 0, 50*8, 9*8)
 _drawmapsprites()
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
	print('lives', 40, 1, 6)
	for h in all(lives) do
		spr(h.sprite, h.x, h.y)
	end
end

--settings
function setting()
	cls()
	--this first thing is unimplemented ♥
	--colorflip for this called in update
	--i need to choose better colors
	if colblind == 0 then
	print("press ⬆️ for colorblind settings",0,20,7)
	else
	print("press ⬇️ to reset colors",0,20,7)
		if btnp(⬇️)  then
			colorreset()
		end
	end
	--pass some value to gamedraw
	--this will be implemented later
	print("in game instructions:",15,30,7)
	print("use arrow keys to move",10,40,7)
	print("press z to shoot", 20,50,7)
	print("press ⬇️ to interact",17,60,7)
	print("press x for inventory", 15,70,7)
	print("...and still x to start", 15,80,7)
	
end

function colorflip()
	if btnp(⬆️)  then
		colblind = 1
	end
end

function colorreset()
		colblind = 0
end
-->8
--movement section
function _moveextra()
		--animate old lady
		extra.sprite +=extra.timing

		if(extra.sprite > 66) then
			extra.sprite = 64

		end

		--animate young lady
		extra.spr1 +=.75

		if(extra.spr1 >= 68) then
			extra.spr1 = 66

		end
		--animate guy
		extra.spr2 +=extra.timing

		if(extra.spr2 > 74) then
			extra.spr2 = 76

		end
		--dx needs to be added
		
		--this could be super improved
		if extra.movecount < 10 then
		 extra.x += 2/extra.dx
		 extra.flipx = false
		 end

		if extra.movecount > 10 then
		 extra.x -= 2/extra.dx
		 extra.flipx = true

		 end

		if extra.movecount< 20 then
			extra.movecount += 1
		else
			extra.movecount = 0
		end

		--other extra
	if extra.movecount < 10 then
		 extra.x1 += 2
		 extra.flipx = false
		 end

		if extra.movecount > 10 then
		 extra.x1 -= 2
		 extra.flipx = true

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
	rectfill(0,0,225,76,12) --number not quite right
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


-->8
--cutscenes (story elements)
cc = 0 --click counter
							--should be fine as a global variable here
function ccplus()
	if btn(➡️) then
		cc += 1
	end
end

function drawcutscene()
	cls()
	
	
	text1()
	text2()
	text3()
end

function text1()
	--top of screen
	print("north england, 196x")
	--bottom of screen
	print("press ➡️ to continue",40,100,0)
	
		
		if cc == 1 then	
		print(".",4,5,7)
		end
		if cc == 2 then
		print(". .",4,5,7)
		end
		if  cc == 3 then
		print(". . .",4,5,7)
		end
	
end

function text2()
	 --try this
	if cc >= 4 then
	townmap()
	end
	if cc > 4 then
	print("your hamlet is starving.",20,30,0)
	end
	if cc > 5 then
	print("the miners are sick,",22,40,0)
	print("but are ready to strike.",15,50,0)
	end
	if cc > 6 then
	print("what will you do about this--",5,60,0)
	end
	if cc > 7 then
	print("mabel brown?",40,70,0)
	end
end

function text3()
	if cc > 8 then
	cls()
	pal()
	spr(1,60,60)
	end
	if cc > 9 then
	spr(115,60,50)
	end
	if cc > 10 then
	spr(11,50,75)
	end
	if cc > 11 then
	print("+",63,77,7)
	end
	if cc > 12 then
	spr(12,70,75)
	end	
	if cc == 14 then --test this
	cls()
	mode = 1
	end
end

function townmap()
	color()
	color(15)
	pal(15,138,1) --change color
	rectfill(0,0,132,132)
	rectfill(0,61,132,132)
	--map is drawing incorrectly
	map(0,14,0,104,14*8,8*8)
end

--may need to add text box to explain limited bullets and etc.
--putting this here until better knowledge of where to put it
--could pass parameter location for whichever text to print
function tutorialtext()
--nothing fomratted yet
--first box
print("welcome to off the rails!",0,0,7)
print("and welcome to train twm sion cati",0,0,7)
print("on trains, people use 'arrow keys' to move",0,0,7)
--second box
print("trains tend to be passennger or cargo trains",0,0,7)
print("this one happens to be a passenger train",0,0,7)
print("so you'll see some other passengers--let them be",0,0,7)
--third box
print("you may notice some guys with guns",0,0,7)
print("this is because you stole the queen's crown",0,0,7)
print("press z or 🅾️ to shoot them before they get you!",0,0,7)
--fourth box
print("to interact and solve puzzles",0,0,7)
print("hit ⬇️ while on top of the object",0,0,7)
print("in england, this is known as takin a gander",0,0,7)
--fifth box
print("you'll need to hit ⬇️ twice to go thru doors",0,0,7)
print("before you go, though, try hitting 'x' or ❎",0,0,7)
print("this enters (and leaves) your inventory",0,0,7)

end

--tutorial map
--needs to be drawn
function tutorialmap()
cls()
--need to muck w these rectangles
rectfill(0,61,132,132)
--muck with map (may not be drawing--havent tested)
--tutorial map is in upper right corner
map(110,0,0,10,14*8,20*8)

--will call text function in here
--text boxes have flag 4

end

--formatting for printing tutorial etc?
function txtbox()
 rectfill(2,
end


__gfx__
00000000008888800088880000888800008888000088880000888800008888000088888000888880008888000000a00000000000000000000000100000000000
0000000008fff88000f8888000f8888000f8888000f8888000f8888000f8888008fff88008fff88008fff880000aa00000000000000000000001110000000000
0aaa0000083f388000f3888000f3888800f3888800f38880003f888800f38888883f3888083f3888083f388000aaaa000155555501555550001a111000000000
0a9aaa0008fff88000ff888000ff888800ff888800ff888000ff888800ff8888f8fff8f8088ff458f8fff8f0022722200411115004111500007cfc7000000000
0aaaa0000111118052111880521118805211180054111880541118805411180011111110008141f0011111100a8aa8a04450000044500000017fff7100000000
0aaaa000011111000f2110000f2110000f2110000f4110000f4110000f41100000111000001f1000081118800a2a82a044000000440000000f17771f00000000
009040000f101f0000101500001010000015100000101500001010000015100000151500001515000011104500222200000000004400000001a7711000000000
0000000000505000005000000050500000005000005000000050500000005000000000000000000005151400077777700000000000000000111711a100000000
01110000001110000011100000111000011100000044400000444000004440000044400000444000000000000000000000000000000000000044400000000000
0111000000111000001110000011100001110000004fc000004fc000004fc000004fc000004fc000004440000044400000444000004440000044440000000000
0111000000111000001110000011100001ff000000fff00000fff00000fff00000fff00000fff0000044440000444400004444000044440004fff06000000000
01ff0000001ff000001ff000001ff00008880000001770550017705500177055001770550017705504fff00004fff00004fff00004fff0600044440000000000
088800000088845500888000008884550788f55000117f0000117f0000117f0000117f0000117f00004440600044406000444060004444000444400000000000
0787455000784f000078745500784f000884000000f1100000f1100000f1100000f1100000f11000004444000044440000444400004440000101000000000000
0884f0000188800001884f0000888000101000000010100000101000051010000010100005151000004440000144400001444000004440000000000000000000
01010000000100000000100001010000000000000050500005050000000050000505000000000000001010000001000000001000000101000000000000000000
88888888333333333333333300888888888118888888228888880033b333333333333000000000220000800044444444344444433444444333333333dddddddd
aaaaaaaa3366666666666633008cddd6888118dcc6d88cdcccc8003ccc6633bdccdc300000000022000cc00044333344456666544566665433666633dddaaddd
a999999a360000000000006300cccdd6888008c6cddc86dcccc8003c6dccc33ccd66300000000022000cc00043444434463333644633336436000063ddaddadd
a9aaaa9a3600000000000063088cc6dc888008cdcdd88cd6ccc8003cddccc33cdd6c300000000022444444444344443446333364463333643600006345444454
a9aaaa9a36000000000000638a8888888880082888882888882800333bb333b33333300002222222000440004344443445666654456669543600006345444454
a999999a36000000000000632282882200811822888222888228003333333333bbb3300002222222000440004344443449999994400009943600006345444454
aaaaaaaa360000000000006388112288811008811888888118881133113333333113311005444445000440004433334449555594400009943600006345444454
99999999336666666666663300110000011000011000000110000000110000000110000005500055005555004444444449555594400009943600006345444454
3333333333333333333333330000000000000000cccccccc00000000000000000000000033333333333333333444444349999994400009943600006355555555
333aa333b3b3b3b3333333330000000007700770cccccccc000d0000000000000000000033333333333333333444444345999994400005943600006356555555
33a33a333b3b3b3b333333330000000077770000cccccccc00ddd000000000000000000033333333333333333444444345999994400005943600006356555655
4544445433333333333333330000000000000000cccccccc0ddddd00000000000000000033333333333333333666666349999994400009943600006355555655
4544445433333333333333330077700000000000ccccccccddddddd00dddd0000066000033999933333333333666666349999994400009943600006355555555
4544445433333333333333330777777000000700ccccccccddddddddddddddd00000000033888833339999333444444349999994400009943600006355565555
45444454bbbbbbbb333333337777777700077770ccccccccdddddddddddddddd00000000b444444bb444444b3444444349999994400009943600006355565555
4544445433333333333333330000000000000000ccccccccdddddddddddddddd0000000044444444444444443444444349999994400000943666666355555555
000ccc0000000000001111100011111000000000000000000c000000000000000000000000000000000111100001111000000b00000000000000000000000000
00c66f0000cccc000144411001444110066066000700000000000000607000006700000067000000001111100011111000bbbb00000088888000000000000000
00c6fff000c6fff00134311101343111666666600000000000d7c00000c600000660000006600000000cfcd0000cfcd000bb7bb0000088fff800000000000000
0cccff000cc6ff001144411111444111066666000d7c00000dd660000dd00000cd7c0000cd7c000000dfffd000dfffd000bb7bb00000883f3800000000000000
0eeeee000eeeeef01155551011555510006660000dd66700000d670000d667000dd667000dd6670000111110001111100bbb7bb0000088fff800000000000000
0eeeef000eeeee0000554500005555000006000000ddd600000dd000000dd60000ddd60000ddd6000011111000111f10007b77b0000088555000000000000000
0eeeee000eeeee000010150000151400000000000000d0600000d6600000d0600000dd600000d66000fdddf000fd0dd000077b00000087777500000000000000
eeeeee000eeeeee0005000000000500000000000000000000000000000000000000000000000000000000d00000d000000007500000075555700000000000000
00888888888118888888228888880033b333333333333000333b3333333333300000000000000000000000000000000000007700000057777500004400000000
008cddd6888118dcc6d88cdcccc8003ccc6633bdccdc3000ccccccb33ccccc30000000000000000000d55555002cc200000057000000f5555f00004400000000
00cccdd6888008c6cddc86dcccc8003c6dccc33ccd663000cdccccc33dcc7c3000000000000000000d44444402c77c2030005700000007777000444400000000
088cc6dc888008cdcdd88cd6ccc8003cddccc33cdd6c3000dcc77cc33ccccc3000000000000000005444494402c77c20130075b3000005555000444400000000
8a8888888880082888882888882800333bb333b3333330003b333333d333b330000000000000000004c145942cccccc211bb7733000007007044444400000000
2282882200811822888222888228003333333333bbb3300033333bb3333333300000000000000000041145440cc88cc01bbbb713000005005044444400000000
88112288811008811888888118881133113333333113311033113333333113310400000004000000041144440cc88cc03b333333555558858855555500000000
00110000011000011000000110000000110000000110000000000000000000005455555554555545041144440cc88cc033333333555555555555555500000000
333330003bb3b33300001000000010000000000000000000444244440000000000000000000000000000000000aaaa00aa000aa0000000000000000000000000
33333b0044343b440001110000011100000000000044444424424444000000000000000000000000000000005a005a5a05a5a05a05a05a0005a0000000000000
9999993044444444001a1110001a1110000000044444444422444444560560000000000000000000000000005a005a5a0005a0000aaa5a005a5a000000000000
3003980044444444007cfc70007cfc70000000444222222442444444560560566056560000000000000000005a005a5aaa05aaa005a05aaa5aaa000000000000
30d3980044444444017fff710f7fff7f000000442222224442444444566665605656560000000000000000005a005a5a0005a00005a05a5a5a00000000000000
99999800444444440f17771f01177711000004422222224422444444005605605656560000000000000000005a005a5a0005a00005a05a5a5a5a005a00000000
9999999a4444445501a7711001a17710000004422222224424aaaaa40056005660056600000000000000000005aaaa5a0005a000005a5a5a05a0005a00000000
4444444455444444111711a1111117a1000044422222224422a555a4000000000000000000000000000000000000000000000000000000000000005a00000000
3bb3b333333b333b9999999900000000000044222211224442a555a400000000000000000000000000000000005aaaa00000000000d00000000005a000000000
4b333bb44333b344aaaaaaaa07777700000042221111224442aadaa456666000000000006600000000600000005a005a00000005a00da000000005a000000000
34444444444b4445a999999a07787700000442221111224442aadaa456056000000000000560000006560000005a005a00aaa0000000ad05aa005a0000000000
4944444444444944a9aaaa9a07787700004442211111224444aaaaa456000056605660566565666056660000005aaaa000005a05a05a000a00a05a0000000000
4499494454499444a9aaaa9a0777770004444221555124434444444456600060565600600665605656000000005a05a005aa5a05a05a0005a000000000000000
9445444444444444a999999a0778770044442215554444344444444456056056005600600665605656560000005a05a00a05aa05a5a005a05a005a0000000000
5554455555445444aaaaaaaa0077700033554444444444334343333356666560605660566565666056600000005a05aa05aa5a05a5a0005aa000000000000000
5544445544554444999999990000007033333333333333b333333333000000560000000000056000000000000000000000000000000000000000000000000000
0000000000000000aaaaaaaa44444444dddd6ddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000cccccccccccccccc
0000666660000000ad66666a4a5555a4dddd6ddddd44444444444444444444ddddddd99dd99ddddd00000000000000000000000000000000cccc88888ccccccc
0000644460000000ad64446a45555554ddddddddd4000000000000000000004dddddd49dd94ddddd00000000000000000000000000000000cccc88fff8cccccc
0000614160000000ad61416a45545554ddddddddd4000000000000000000004ddddd44dddd44dddd00000000000000000000000000000000cccc883f38cccccc
0000044400000000ad64446a45554554ddddddddd4000000000000000000004dddd44dddddd44ddd00000000000000000000000000000000cffc88fff8cffccc
0000044000000000add44dda45555554d6ddddddd4000000000000000000004ddd44dddddd4444dd00000000000000000000000000000000c11c88fff8c11ccc
0041444414000000a111111a4a5555a4d6ddddddd4000000000000000000004dd46444ddd44464dd00000000000000000000000000000000c111811111111ccc
0041111114000000aaaaaaaa44444444dddd6ddddd44444444444444444444dd444644444446444400000000000000000000000000000000cc1111111111cccc
004444411400000044444444d6dddd6d66666666446444444444444444444444399999930000000000000000000000000000000000000000ccccc1111ccccccc
000114644400000044555544d6dddd6d444444444464444444666644495555a4777777770000000000000000000000000000000000000000ccccc1111ccccccc
000111111000000045555554dd6dd6dd44466444466666644644446445555554777777770000000000000000000000000000000000000000ccccc1111ccccccc
000111111000000045554554dd6dd6dd46666664444444444644446445545554777706770000000000000000000000000000000000000000ccccc1111ccccccc
000111111000000045545554dd6dd6dd46466464444444444644446445554554700677770000000000000000000000000000000000000000ccccc5115ccccccc
000111111000000045555554d6dddd6d46666664466666644644446445555554777777770000000000000000000000000000000000000000b333c5cc5cccbccb
000040040000000044555544d6dddd6d4446644444444644446666444a555594777777770000000000000000000000000000000000000000bb3bb88b88bb333b
000550055000000044444444d6dddd6d44444444444446444444444444444444399999930000000000000000000000000000000000000000bbbbbbbbbbbbb3bb
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56565666566656555666565655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56565655565656555565565655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56665665566656555565566655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56565655565656555565565655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56565666565656665565565655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
58888888888888888888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
58888888888888888888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56555666565656665566555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56555565565656555655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56555565565656655666555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
46443363366636333336333333334444444433333333333333334444444433333333333333333333333344444444333333333333333344444444333333333333
36663666336336663663333333334433334433333333333333334433334433333333333333333333333344333344333333333333333344333344333333333333
44343333333333333333333333334344443433333333333333334344443433333333333333333333333343444434333333333333333343444434333333333333
44343333333333333333333333334344443433333333333333334344443433333333333333333333333343444434333333333333333343444434333333333333
44343333333333333333333333334344443433333333333333334344443433333333333333333333333343444434333333333333333343444434333333333333
44663663336636633366366333334344443433333333333333334344443433333333333333333333333343444434333333333333333343444434333333333333
36666666366666663666666633334433334433333333333333334433334433333333333333333333333344333344333333333333333344333344333333333333
44666663336666633366666333334444444433333333333333334444444433333333333333333333333344444444333333333333333344444444333333333333
33366633333666333336663333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33336333333363333333633333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66333333333333333333333333333366663333333333333333333366663333333333333333333333333333666633333333333333333333666633333333333333
cc6333333333333333333333333336cccc63333333333333333336cccc6333333333333333333333333336cccc63333333333333333336cccc63333333333333
cc6333333333333333333333333336cccc63333333333333333336cccc6333333333333333333333333336cccc63333333333333333336cccc63333333333333
cc6333333333333333333333333336cccc63333333333333333336cccc6333333333333333333333333336cccc63333333333333333336cccc63333333333333
cc6333333333333333333333333336cccc63333333333333333336cccc6333333333333333333333333336cccc63333333333333333336cccc63333333333333
cc6333333333333333333333333336cccc63333333333333333336cccc6333333333333333333333333336cccc63333333333333333336cccc63333333333333
cc6333333333333333333333333336cccc63333333333333333336cccc6333333333333333333333333336cccc63333333333333333336cccc63333333333333
cc6322333333333383333333332236cccc63333333333333333336cccc6322333333333383333333332236cccc63333333333333333336cccc63333333333333
cc6322b3b3b3b3bcc3b3b3b3b32236cccc63b3b3b3b3b3b3b3b336cccc6322b3b3b3b3bcc3b3b3b3b32236cccc63b3b3b3b3b3b3b3b336cccc63b3b3b3b3b3b3
cc63223b3b3b3b3ccb3b3b3b3b2236cccc633b3b3b3b3b3b3b3b36cccc63223b3b3b3b3ccb3b3b3b3b2236cccc633b3b3b3b3b3b3b3b36cccc633b3b3b3b3b3b
cc6322333333444444443333332236cccc63333333333333333336cccc6322333333444444443333332236cccc63333333333333333336cccc63333333333333
cc6322222223333443333222222236cccc63333333333333333336cccc6322222223333443333222222236cccc63333333333333333336cccc63333333333333
cc6322222223333443333222222236cccc63333333333333333336cccc6322222223333443333222222236cccc63333333333333333336cccc63333333333333
cc635444445bbbb44bbbb544444536cccc63bbbbbbbbbbbbbbbb36cccc635444445bbbb44bbbb544444536cccc63bbbbbbbbbbbbbbbb36cccc63bbbbbbbbbbbb
66635533355333555533355333553666666333333333333333333666666355333553335555333553335536666663333333333333333336666663333333333333
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999
aa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aa
aa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aa
999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
44443333333333333333333333334444444433333333333333334444444433333333333333333333333344444444333333333333333344444444333333338888
3344333333333333333333333333443333443333333333333333443333443333333333333333333333334433334433333333333333334433334433333333aaaa
4434333333333333333333333333434444343333333333333333434444343333333333333333333333334344443433333333333333334344443433333333a999
4434333333333333333333333333434444343333333333333333434444343333333333333333333333334344443433333333333333334344443433333333a9aa
4434333333333333333333333333434444343333333333333333434444343333333333333333333333334344443433333333333333334344443433333333a9aa
4434333333333333333333333333434444343333333333333333434444343333333333333333333333334344443433333333333333334344443433333333a999
3344333333333333333333333333443333443333333333333333443333443333333333333333333333334433334433333333333333334433334433333333aaaa
44443333333333333333333333334444444433333333333333334444444433333333333333333333333344444444333333333333333344444444333333339999
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333338888
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333aaaa
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333a999
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333a9aa
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333a9aa
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333a999
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333aaaa
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333339999
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666663333333333336666666666663333333333333333333366666666666633333333333366666666666633333333333333333333666666666666333333
cccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333
cccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333
cccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333
cccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333
cccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333333336cccccccccccc63333333333333333336cccccccccccc633333
66666666663333333333336666666666663333333333333333333366666666666633333333333366666666666633333333333333333333666666666666333333
33223333333333333333333333332233333333333333333333333333332233333333333333333333333322333333388883333333331113333322333333333333
b322b3b3b3b3b3b3b3b3b3b3b3b322b3b3b3b3b3b3b3b3b3b3b3b3b3b322b3b3b3b3b3b3b3b3b3b3b3b322b3b3b38888f3b3b3b3b31113b3b322b3b3b3b3b3b3
3b223b3b3b3b3b3b3b3b3b3b3b3b223b3b3b3b3b3b3b3b3b3b3b3b3b3b223b3b3b3b3b3b3b3b3b3b3b3b223b3b388883fb3b3b3b3b111b3b3b223b3b3b3b3b3b
33223333333333333333333333332233333333333333333333333333332233333333333333333333333322333338888ff333333333ff13333322333333333333
22223333333333333333333333332222222333333333333333333222222233333333333333333333333322222223381112533333668882222222333333333333
2222333333333333333333333333222222233333333333333333322222223333333333333333333333332222222333112f333335547872222222333333333333
4445bbbbbbbbbbbbbbbbbbbbbbbb5444445bbbbbbbbbbbbbbbbbb5444445bbbbbbbbbbbbbbbbbbbbbbbb5444445bbb151bbbbbbbbf4885444445bbbbbbbbbbbb
33553333333333333333333333335533355333333333333333333553335533333333333333333333333355333553335333333333331315533355333333333333
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999
aa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aa
aa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aaaa9aa9aa
999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999999aa999
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555558888
5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555aaaa
5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555a999
5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555a9aa
5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555a9aa
5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555a999
5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555aaaa
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559999
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555

__gff__
0000000000000000000000000000000000000000000000000000000000000000010000000000000000000000020200000200000000000000000000010202000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000
0000000100000000000000000000000000000100010101010000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
723232322b32322b3232322b32322b3232322b32322b3232322b2b32323232200000000095848484938586868793848484858687848484938484848493848484950000727272727272727272727272727272727272727272727272727272727272ffffffffffff00000000000000000000000000000000000000000000000000
72323232323232323232323232323232323232323232323232323232323232200000000095848484939797979793848484848484848484938484848493848484950000723232323232323232323232323232323232323232323232323232323272ffffffffffff00000000000000000000000000000000000000000000000000
723232322e32322e3232322e32322e3232322e32322e3232322e2e32322e32200000000095848284938484848493848587848484858784938484848493848284950000723232212232323232323232212232323232323232322122323232323272ffffffffffff00000000000000000000000000000000000000000000000000
723232323e31313e3131313e31313e3131313e31313e3131313e3e30313e312000000000958484849384848484938484848484848484849384a2a28493848484950000723232323232322e322e3232323232322e322e32323232323232322e3272ffffffffffff00000000000000000000000000000000000000000000000000
723232322020202020202020202020202020202020202020202020202020202000000000959292928384848484839292929292929292929284b2b28492929292950000723232323231313e313e3131313131313e313e31313131313139313e3072ffffffffffff00000000000000000000000000000000000000000000000000
723220322b32322b3232322b32322b3232322b32322b3220322b2b3232322b200000000095848484938484848493848484848484848484839292929283848484950000723232203220202020202020202020202020202020202020202020202072ffffffffffffff000000000000000000000000000000000000000000000000
723232323232323232323232323232323232323232323220323232323232322000000000958484849384848484938484848484848484849384848484938484849500007232323232323232323232323232323232323232323232323f3232323272ffffffffffffff000000000000000000000000000000000000000000000000
722032212232322122322122323221223221223232212232322122323221222000000000958586879385868687938485878484848587849384848484938586879500007220323232322122323232323232323232322122323232323f3232323272ffffffffffffff000000000000000000000000000000000000000000000000
723131313131313131313131313131313131313131313132322c2c323131312000000000958488849384848484938484848484848484849384a6a5849384842f9500007231313131313131313131313131313131313131313131313f312c313172ffffffffffffff000000000000000000000000000000000000000000000000
202020202020202020202020202020202020202020202020313c3c312020202000000000969494949484848484949494949494949494949484b6b5849494949696000072202020202020202020202020202020202020202020202020203c322072ffffffffffff00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000002020202020200000000000000000000000969494949496a10000000000000000969494949496000000000000000000000000000000000000000000000000000000000000000020200000ffffffffffff00000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff000000000000000000000000000000000000000000000000000000
0000000000000000c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006a6a6a6a6a6a6a6a6a6a6a6a6a6a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6969004c0000000000000000004c646566000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60695b5c5a00000000000000005c747576000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6161717061716161617161717170707161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6058585958585958585958585959595958000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7061707161617170616161716161707161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
950f0000261502a0502d0502a050260502a0502d0502a050241502a0502c0502a050240502a0502c0502a050261502a0502d0502a050260502a0502d1502a050241502a0502c0502a050240502a0500000000000
3810000026450000000000026450000000000026450000002545000000000002545000000000002d450000002a45000000000002a45000000000002a450000002a45000000000002a45000000000002a45000000
c51000000000000000063500000000000063500000000000000000000006350000000000006350000000000000000000000635000000000000635000000000000000000000063500000000000063500000000000
001000002a010220501b0501a0501900000000110000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002205000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000005050320003200031000300002e0002d0002b0002900024000230002300023000220002200021000210001f0001d0001a000010000000000000000000000000000000000000000000000000000000000
__music__
00 00424344
00 00424344
00 00424344
00 00424344
00 00424344
00 00424344

