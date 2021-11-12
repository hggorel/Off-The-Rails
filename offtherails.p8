pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--basic set up sections
--in the game
--use inventory for cutscene

function _init()
--	mode = 0 --for title call
--	if mode == 0 then
	--	titleupdate()
--	end

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
		ydiff=0,
		--jump_height=0,
		--jump_allowed=true
		is_standing = true,
		is_blocked_right = false,
		is_blocked_left = false,
		dy=0.0,
		dx=0.0,
		gravity=0.3
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
	create_soldier(32, 64)
	create_soldier(160, 64)
	
	map_x=0
	map_speed=1
	gameover=false
	gamewin=false
	
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

function shoot(startx, starty, flipx)
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

function create_soldier(newx, newy)
	local actor ={
		movecount=0,
		flipx=false,
		shootcount=0,
		sprite = 16,
		x = newx,
		y = newy
	}

	add(enemies, actor)

end

function moving_soldier()
	for actor in all(enemies) do
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
			shoot(actor.x, actor.y, actor.flipx)
		end
		actor.shootcount+=1
	end
end

function move_player()

	local allowance=28
	local speed=1
	
	local tile_below_character = mget(player.x / 8, (player.y + 8) / 8)
 local tile_below_character_collidable = fget(tile_below_character, 0)
	
	local tile_right_character = mget((player.x +8)/8, player.y/8)
	local tile_right_collidable = fget(tile_right_character, 0)
	
	local tile_left_character = mget((player.x)/8, player.y/8)
	local tile_left_collidable = fget(tile_left_character, 0)

 if (tile_below_character_collidable) then
 	player.is_standing = true
  player.dy = 0
 else
 	player.is_standing = false
 	player.dy-=player.gravity
 end
 
 if (tile_right_collidable) then
		player.is_blocked_right = true
	else
		player.is_blocked_right = false
	end
	
	if (tile_left_collidable) then
		player.is_blocked_left = true
	else
		player.is_blocked_left = false
	end
 if btnp(2) and player.is_standing then
  player.dy = 3
  player.is_standing = false
 end
 -- moving player based on input
	if btn(0) and not(player.is_blocked_left) then
		player.flipx=false
		if player.x>0 then
			player.x-=1
		end
		player.sprite=1+player.movecount
		
		if(player.x-camx<(64-allowance)) then
			if camx<=0 then
				camx=0
			else
				camx-=speed
			end
		end
		
	end
	if btn(1) and not(player.is_blocked_right) then
		player.flipx=true
		if player.x<240 then
			player.x+=1
		end
		player.sprite =1+player.movecount
		--map_x-=map_speed
		if (player.x-camx>(64+allowance)) then
			if camx<=120 then
				camx+=speed
			end
		end
	end
	--if btn(2) and player.jump_allowed == true then
 --	player.y-=3
 -- player.ydiff+=3
 -- player.jump_height +=3
 -- if(player.jump_height > 70) then
 -- 	player.jump_allowed = false
 -- end
 -- if(player.ydiff == 0 and player.jump_allowed == false) then
 --  player.jump_allowed = true
 --  player.jump_height = 0
	--	end
 --end

 -- make dy negative because positive dy moves character downward
 player.y += (-1 * player.dy)

 --if (not player.is_standing) then
 -- player.dy -= player.gravity
 --end
 -- player.dy *= player.gravity
 
 if btnp(3) then
 	local tile_character_on = mget(player.x / 8, player.y / 8)
 	if tile_character_on == 60 then
 		mset(player.x/8, player.y/8, 61)
 		mset(player.x/8, (player.y-8)/8, 45)
 	end
 	if tile_character_on ==61 then
 		gamewin=true
 	end
 end
 
	if btnp(4) and mode == 1 then
		fire()
	end
	
	--we dont use 5 yet i think?
	--so this is for title to game
--	if btnp(5) and mode == 0 then
	--	mode = 1
--	end --redundant code

	-- switching to see animation
	if player.movecount==3 then
		player.movecount=1
	end
	if player.movecount<3 then
		player.movecount+=1
	end
	
end

function _update()
	if mode == 0 then
		titleupdate()
	elseif mode == 1 then
		gameupdate()
	else
		pauseupdate()
	end
	
	-- moving all of the bullets
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy
		if b.x<camx-128 or b.x > camx+128 or b.y < 0 or b.y>128 then
			del(bullets, b)
		end
	end
	
	for b in all(danger) do
		b.x+=b.dx
		b.y+=b.dy
		if b.x<camx-128 or b.x>camx+128 or b.y<0 or b.y>128 then
			del(danger, b)
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
				del(enemies, e)
				del(bullets, b)
			end
		end
	end
	
	for b in all(danger) do
		if abs(b.x - player.x)<=1 and abs(b.y - player.y)<=5 then
			if b.dx>0 then
				player.x+=1
			else
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

	--gravity
	if player.ydiff > 0 then
		player.y+=1
		player.ydiff-=1
	end
	
	if player.ydiff==0 then
	 player.jump_allowed=true
		player.jump_height=0
	end
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

--x only used this way
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
	
title={ --info for the title sprite
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
		pausedraw() --mode only if 1
	end
end

function gamedraw()
	if gameover==false and gameover==false then
 	cls(5)
 	camera(camx, -16)
 	--camera(0, -16)
 	--multiple in editor values by 8 to match map values
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
	
	if level == 1 then
		--level 2 function call
	
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
	
	if gamewin then
		-- draw won level screen
		cls(2)
		print('level completed!', 7)
		print('next levels are', 13)
		print('under construction', 13)
	end
	
end

function _drawmapsprites()
	--multiplied in editor values by eight to fit map values
		--these should all be drawn behind the player
		--so this function will be called before the player is drawm
		--top level of car
		spr(42,09*8,03*8) --table 1
		spr(42,16*8,03*8) --table 2
		spr(42,20*8,03*8) --table 3

		--bottom level of car
		spr(42,09*8,08*8) --table 1
		spr(42,16*8,08*8) --table 2
		spr(42,20*8,08*8) --table 3

	end


settings = false
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
		spr(107,45,45,4,2)
		print("press z for settings",3,13,7)
	--fix this part
	if btn(🅾️) then
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
	--	running = false
		rectmove()
		color(14)
		pal(14,131,1) --replace pink with 131
		rectfill(8, 8, 119, 119)
		print("inventory",10,10,7)
		spr(11,20,20) --queens crown
		spr(57,35,20) --gun
		rect(sel.x,sel.y,sel.x+12,sel.y+12,8)
		if sel.place == 0 then
			print("the queen's crown:", 20,40,7)
			print("you stole this.",25,50,7)
		end
		if sel.place == 1 then
			print("your trusty pistol:",20,40,7)
			print("you should equip this.",15,50,7)
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

function level2draw()

end

function lev2sprites()

end

function lev2flips()
	--lever uses flag 2
end
--settings
function setting()
	cls()
	print("press ⬆️ for colorblind settings",5,20,7)
	--pass some value to gamedraw

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
__gfx__
00000000008888800088880000888800008888000088880000888800008888000088888000888880008888000000a00000777700000ccc000000100000000000
0000000008fff88000f8888000f8888000f8888000f8888000f8888000f8888008fff88008fff88008fff880000aa0007071716000c66f000001110000000000
0aaa0000083f388000f3888000f3888800f3888800f38880003f888800f38888883f3888083f3888083f388000aaaa007777776700c6fff0001a111000000000
0a9aaa0008fff88000ff888000ff888800ff888800ff888000ff888800ff8888f8fff8f8088ff458f8fff8f002272220077717600cccff00007cfc7000000000
0aaaa0000111118000111880001118800011180054111880541118805411180011111110008141f0011111100a8aa8a0077777600ddddd00017fff7100000000
0aaaa000011111000f1110000f1110000f1110000f4110000f4110000f41100000111000001f1000081118800a2a82a0007777600ddddf000f17771f00000000
009040000f101f0000101500001010000015100000101500001010000015100000151500001515000011104500222200000777600ddddd0001a7711000000000
00000000005050000050000000505000000050000050000000505000000050000000000000000000051514000777777000007666dddddd00111711a100000000
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
0000000033333333333333330000000000000000cccccccc00000000000000000000000000000000000000000000000049999994400009943600006300000000
000aa000b3b3b3b3333333330000000007700770cccccccc000d0000000000000000000000000000000000000000000045999994400005943600006300000000
00a00a003b3b3b3b333333330000000077770000cccccccc00ddd000000000000000000001555550000000000000000045999994400005943600006300000000
4544445433333333333333330000000000000000cccccccc0ddddd00000000000000000004111500000000000000000049999994400009943600006300000000
4544445433333333333333330077700000000000ccccccccddddddd00dddd0000066000044500000000000000000000049999994400009943600006300000000
4544445433333333333333330777777000000700ccccccccddddddddddddddd00000000044000000000000000000000049999994400009943600006300000000
45444454bbbbbbbb333333337777777700077770ccccccccdddddddddddddddd0000000044000000000000000000000049999994400009943600006300000000
4544445433333333333333330000000000000000ccccccccdddddddddddddddd0000000000000000000000000000000049999994400000943666666300000000
000ccc0000000000001111100001111000000000000000000c0000000000000000000000000000000ca0000000c0000000000000000000000000000000000000
00c66f0000cccc0001444110001111100660660007000000000000006070000067000000670000000cca7000000a000000000000000088888000000000000000
00c6fff000c6fff001343111000c4cd0666666600000000000d7c00000c60000066000000660000000ca0000000c000000000000000088fff800000000000000
0cccff000cc6ff001144411100d444d0066666000d7c00000dd660000dd00000cd7c0000cd7c0000000aa0000000ca00000c00000000883f3800000000000000
0ddddd000dddddf01555551000111110006660000dd66700000d670000d667000dd667000dd667000000a00000000a000000ca00000088fff800000000000000
0ddddf000ddddd0005555500001111100006000000ddd600000dd000000dd60000ddd60000ddd6000000ca00000000a0000000a0000088555000000000000000
0ddddd000ddddd0004101400004d0d40000000000000d0600000d6600000d0600000dd600000d660000000c00000000a000000a0000087777500000000000000
dddddd000dddddd000505000000d0d00000000000000000000000000000000000000000000000000000000000000000000000000000075555700000000000000
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
9999993044444444001a1110001a1110000000000000000000000000000000000000000000000000000000005a005a5a0005a0000aaa5a005a5a000000000000
3003980044444444007cfc70007cfc70000000000000000000000000000000000000000000000000000000005a005a5aaa05aaa005a05aaa5aaa000000000000
30d3980044444444017fff710f7fff7f000000000000000000000000000000000000000000000000000000005a005a5a0005a00005a05a5a5a00000000000000
99999800444444440f17771f01177711000000000000000000000000000000000000000000000000000000005a005a5a0005a00005a05a5a5a5a005a00000000
9999999a4444445501a7711001a177100000000000000000000000000000000000000000000000000000000005aaaa5a0005a000005a5a5a05a0005a00000000
4444444455444444111711a1111117a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000005a00000000
3bb3b333333b333b000000000000000000000000000000000000000000000000000000000000000000000000005aaaa00000000000d00000000005a000000000
4b333bb44333b344000000000000000000000000000000000000000000000000000000000000000000000000005a005a00000005a00da000000005a000000000
34444444444b4445000000000000000000000000000000000000000000000000000000000000000000000000005a005a00aaa0000000ad05aa005a0000000000
4944444444444944000000000000000000000000000000000000000000000000000000000000000000000000005aaaa000005a05a05a000a00a05a0000000000
4499494454499444000000000000000000000000000000000000000000000000000000000000000000000000005a05a005aa5a05a05a0005a000000000000000
9445444444444444000000000000000000000000000000000000000000000000000000000000000000000000005a05a00a05aa05a5a005a05a005a0000000000
5554455555445444000000000000000000000000000000000000000000000000000000000000000000000000005a05aa05aa5a05a5a0005aa000000000000000
55444455445544440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000aaaaaaaa44444444555565555555555555555555555555555555555555555555000000000000000000000000000000000000000000000000
0000666660000000ad66666a4adddda4555565555544444444444444444444555555599559955555000000000000000000000000000000000000000000000000
0000644460000000ad64446a4dddddd4555555555400000000000000000000455555549559455555000000000000000000000000000000000000000000000000
0000614160000000ad61416a4dd4ddd4555555555400000000000000000000455555445555445555000000000000000000000000000000000000000000000000
0000044400000000ad64446a4ddd4dd4555555555400000000000000000000455554455555544555000000000000000000000000000000000000000000000000
0000044000000000add44dda4dddddd4565555555400000000000000000000455544555555444455000000000000000000000000000000000000000000000000
0041444414000000a111111a4adddda4565555555400000000000000000000455464445554446455000000000000000000000000000000000000000000000000
0041111114000000aaaaaaaa44444444555565555544444444444444444444554446444444464444000000000000000000000000000000000000000000000000
00444441140000004444444456555565666666664464444444444444000000000000000000000000000000000000000000000000000000000000000000000000
000114644400000044dddd4456555565444444444464444444666644000000000000000000000000000000000000000000000000000000000000000000000000
00011111100000004dddddd455655655444664444666666446444464000000000000000000000000000000000000000000000000000000000000000000000000
00011111100000004ddd4dd455655655466666644444444446444464000000000000000000000000000000000000000000000000000000000000000000000000
00011111100000004dd4ddd455655655464664644444444446444464000000000000000000000000000000000000000000000000000000000000000000000000
00011111100000004dddddd456555565466666644666666446444464000000000000000000000000000000000000000000000000000000000000000000000000
000040040000000044dddd4456555565444664444444464444666644000000000000000000000000000000000000000000000000000000000000000000000000
00055005500000004444444456555565444444444444464444444444000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000d777777dd777777d4aaaaaa40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007566665775666657aa44449a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000000000076dddd6776dddd67a494494a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000076dddd6776dddd67a44a944a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000007566665775666957a449944a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007999999770000997a494494a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007955559770000997a944449a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000079555597700009974aaaaaa40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007599999770000597000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007599999770000597000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000997000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007999999770000097000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000010000000000000000000001020200000200000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000040000000000000000000000000000000000000000000000000002020000000000000000000000000000020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2b3232322b32322b3232322b32322b3232322b32322b3232322b2b323232322b000000959384848493858687938484848484858687848484848493848484938484849500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
323232323232323232323232323232323232323232323232323232323232322b000000959384848493848484938484848484848484848484848493848484938484849500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
323232322e32322e3232322e32322e3232322e32322e3232322e2e32322d322b00000095938484849383838393848484848484848484848484849384a284938484849500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
323232323e31313e3131313e31313e3131313e31313e3131313e3e31313d312b00000095938586879384848493858687848484848484848586879384b284938586879500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202020202020202020202020202020202020202020202020202020202020202b000000959384848493848484938484848484848484848484848492929292928484849500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b3232322b32322b3232322b32322b3232322b32322b3232322b2b3232322b2b000000959292928393848484938392929292929292929292929283848484839292929500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
323232323232323232323232323232323232323232323232323232323232322b000000959384848493848484938484848484848484848484848493848484938484849500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212232212232322122322122323221223221223232212232322122323221222b000000959385868793848484938586878484858687848485868793848484938586879500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
313131313131313131313131313131313131313131313131322c2c323131312b00000095938484849384848493848484848484848484848484849384a284938484849500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202020202020202020202020202020202020202020202020313c3c312020202000000094949494949384888493949494949494949494949494949384b284939494949400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000202020202020000000000000000000009694949494949600000000000000000000009694949494949600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__sfx__
000100000d05010050140500f050240501005015050100501705017050100500f0500f05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001818000906015060180601c06018060150600906015060180601c06018060150600906015060180601b06018060150600906015060180601b06018060150600906015060180601c06018060150600906005060
000c20001363013630136301363007630076300763007630136301363013630136300663006630066300663013630136301363013630076300763007630076301363013630136301363007630076300763007630
001320000433004330043300434002430024200243003320033200334002320023200232002340023200232001330013300145001440013400242002440004400133001340013100034000330003200032000330
001800001b050200501d0501b050200501d050200501d050190501705016050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
03 01020344

