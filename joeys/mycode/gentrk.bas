    REM vim: noexpandtab ts=2 sw=2 wrap listchars=tab\:\|\ ,trail\:% showbreak=\-\|\-\ 

    REM DONE: Refactor out the 640,512s - only use them during PLOT functions.
    REM DONE: Refactor out the height, it is added then subtracted.  Only apply it once!
    REM DONE: i.e. assume 0 in world coords IS at -height, i.e. camera is at +height not 0,0

		REM We can use level of detail (use more polygon points in the foreground then the background, and for textures use zoomed out mixmaps in the background)
		REM But also we can cheat with the track.  If we put rises after a corner, it will avoid creating too many polygons.
		REM Forget all that, the point is that the furthest part of the track we render can actually be a large length, because it is small, we can't render the detail of a small skip anyway.

		REM If lines are mostly horizontal, and we are happy to give up 010101, we can fill the screen with 001111 and either
		REM have it bg:fg or fg:bg or bg=fg, or we can add the odd change symbol...

    REM TODO: Make the track widen for sharper corners.
    REM TODO: Make corners turn 0 at start 2.0 in middle and 0 at end.  This should average out to the same total turn, but give a gentle lead in/out to corners.

    REM On average the corners are evenly spaced.  Maybe instead, the current corner phase should depend on the lengths of previous corners, making spacing more random.

    REM TODO: Make the ends meet.
    REM Actually do we need to?  Well yes to display a map of the track.  But if we consider the track to be a never-ending repeating tunnel, the ends don't really need to meet.  :P
    REM Disadvantages with tunnel method: we might not see later parts of track that should be on screen (crossovers).
    REM                                   we won't see buildings which we are passing on the other side (landmarks).
    REM       This could be done by tweaking the values of existing corners.
    REM       or by adding a global ++ to rotation and position every tick.
    REM       or we can add two extra corners, one before the start, and the other after the end, which when completed only leave a straight line between them.   (This is aka two corners on the end.)  The changing of their values is called auto-tweaking.  After map generation, we might let the user perform manual tweaking of individual corners.
    REM       Older thoughts: If end rotation does not match start, then calculate and add globalDeltaYaw at every non-straight (when 1 or more corners are active - but what distance is this?  maybe we *should* double it when two corners are active - if we have calculated the total from the sum of all cornerlengths.)

    REM For track height changes, we could rotate upwards/downwards but this could be messy.  The track might lose the UP direction and start going there!  Also, it will be hard to make the two ends meet.
    REM Instead it might be best to make the height temporarily follow a sin curve until it reaches the desired height,
    REM and then make sure the amplitude of all the sin curves sum to 0.

    REM Tip camera forward pitch down a bit, as a real camera would.  (Horizon will move above camera equator.)
    REM Consider how this will change the appearance/display of barriers.
    REM (I think they may not hide to begin with, giving us view of the plane, then begin to hide/obscure later?)

    REM Make camera independent of ship's position on track.

    REM OK on the straight, but change the i%-0.5 to i%-1.0, you will see if we are on a corner, we are looking straight forwards into a wall!
    REM Is that the correct way to render a corner?
    REM Should the camera be back a little, so that it is actually on the near wall, looking at the far wall?  Dur that's not what camera_back achieves!  :P
    REM Or should the camera be rotated according to the rotation/roll/travel of our little ship?  YES!  That would be cool.

    REM One way of making a track that meets up head to tail.
		REM Decide initially wheether to be a clockwise loop or an anti-clockwise loop, and whether to be double or single loop (or triple...).
		REM Create some corner positions.
		REM For each corner in one half: select a corner in the other half, and add/subtract from each respectively.
		REM but overall (average++?) make them totally add an extra 2*PI for clockwise loop.
		REM could be an adaptive/iterative process that descends the map to some optimal.  (relatively gentle corners, well spaced on map, straights and corners, ...)

  10360 REM Track generator
  10370 :
  10380 MODE 2
  10390 :
  10400 REM Track
  10410 corners% = 16
  10420 tracklength% = 128
  10430 speed = 48.0   : REM movement forwards at each step
  10440 width = 8.0    : REM half the distance between the track edges
  10450 barriery = 5.0  : REM height of barriers at track edges
  10480 shipHeight = 0.5
  10460 :
  10470 REM Camera (most values in world coordinates)
  10490 focal_distance = 12.0   : REM Distance of camera lens (aka screen) from camera eye (aka player)
  REM 10480 cameraheight = 4.0           : REM height of camera above track
  REM 10450 camerapitch = 10.0*2*PI/360  : REM pitch of camera downwards
  10480 cameraheight = 1.5           : REM height of camera above track
  10450 camerapitch = 0.0*2*PI/360  : REM pitch of camera downwards
  10500 camera_back = 10.0      : REM If (0,0,0) is ship's position on track, camera will sit at (0,0,-camera_back)
  10510 scale_world_to_screen = 120.0 : REM at focal plane, 4 in world x = 1280 on screen x
  10520 :
  10530 barrierx = width/2 : REM This value cannot be changed - hard-coded copies used later: dx/2 and dy/2
  10540 :
  10550 DIM turn(corners%)
  10560 DIM cornerlength%(corners%)
  10570 DIM cornerstart%(corners%)
  10580 :
  10590 PRINT "Seed=";RND(-3)
  10600 FOR i%=1 TO corners%
  10610 	cornerstart%(i%) = 0.6*(i%+1.0+RND(1)*0.2)*tracklength%/(corners%+2)
  10620 	cornerlength%(i%) = tracklength%/corners% * (0.6+1.0*RND(1)^2)*0.5
  10630 	turn(i%) = (0.3+RND(1))*1.2*PI/2
  10640 	IF RND(1)<0.5 THEN turn(i%) = -turn(i%)
  10650 	REM COLOUR 1 : @%=0 : PRINT TAB(0),i%;TAB(4),cornerstart%(i%);TAB(8),cornerlength%(i%);TAB(12),(turn(i%)*180/PI)DIV1
  10660 NEXT
  10670 :

    REM x = 640 : y = 512
  10700 x = 0 : y = 0
  10710 trackyaw = 0 : REM PI/2
  10720 GCOL 0,7
  10730 PROCplot3dLine(x-width,y,0, x+width,y,0)
  10740 GCOL 0,4
  10750 PROCplot3dLine(x-width-barrierx,y,+barriery, x-width,y,0)
  10760 PROCplot3dLine(x+width+barrierx,y,+barriery, x+width,y,0)
  10770 FOR t=0 TO tracklength% STEP 1
    REM 	Make the track raise evenly:  (Breaks the explosion code)
    REM 	height=height - 0.3
  10800 	countActive% = 0
  10810 	FOR i%=1 TO corners%
    REM TODO: No point in checking i < corners%*t/tracklength%
    REM  10340 	FOR i%=corners%*t/tracklength% TO corners%
  10840 		IF t>=cornerstart%(i%) AND t<cornerstart%(i%)+cornerlength%(i%) THEN trackyaw=trackyaw+turn(i%)/cornerlength%(i%) : countActive% = countActive% + 1
  10850 	NEXT
  10860 	x=x+SIN(trackyaw)*speed : y=y+COS(trackyaw)*speed
  10870 	countActive% = 7 - countActive% : IF countActive%<1 THEN countActive%=1
  10880 	GCOL 0,countActive%
    REM  10390 	DRAW x,y
  10900 	dx = -COS(trackyaw)*width : dy = SIN(trackyaw)*width
  10910 	MOVE 640+x-dx,512+y-dy : DRAW 640+x+dx,512+y+dy
  10920 	IF t<=12 THEN GCOL 0,1
  10930 	PROCplot3dLine(x-dx,y-dy,0, x+dx,y+dy,0)
    REM 	Explosion in centre of screen - testing whether camera_back and FOV can show ship at (0,0,0)!  ATM: NO!
  10950 	GCOL 0,7 : PROCplot3dLine(0,0,shipHeight, 1.0*(RND(1)-0.5),-4,shipHeight+1.0*(RND(1)-0.5))
    REM 	We stop drawing the barriers after the first corner
  10970 	IF t>12 THEN NEXT : REM TODO BUG: This is bad coding - it doesn't jump out of the loop on the last iteration!
  10980 	GCOL 0,3
  10990 	PROCplot3dLine(x-dx,y-dy,0, x-dx-dx/2,y-dy-dy/4,barriery)
  11000 	PROCplot3dLine(x+dx,y+dy,0, x+dx+dx/2,y+dy+dy/4,barriery)
  11010 NEXT
  11020 :
  11030 END
  11040 :

  11060 DEF PROCplot3dLine(ax,ay,az,bx,by,bz)
    REM 	The z we get here is upwards, and the y we get here is inwards.
  11080 	PROCgetxy(ax,az,ay)
  11090 	IF Z% = 0 THEN ENDPROC
  11100 	MOVE X%,Y%
  11110 	PROCgetxy(bx,bz,by)
  11120 	IF Z% = 0 THEN ENDPROC
  11130 	DRAW X%,Y%
  11140 ENDPROC
  11150 :

  11170 DEF PROCgetxy(x,y,z)
    REM 	The y we get here is upwards, and the z we get here is inwards.
  11190 	z = z + camera_back
  11210 	IF z<=0 THEN Z%=0 : ENDPROC
  11200 	y = y - cameraheight
    REM 	Rotate camera pitch
  11200 	newy = y*COS(camerapitch) + z*SIN(camerapitch)
  11200 	newz = z*COS(camerapitch) - y*SIN(camerapitch)
  11200 	y=newy : z=newz
    REM 	z = z + focal_distance
    REM 	REM Convert worldx to screenx, same for y and z
    REM 	x=640+x*64 : y=512+y*64 : z=z*64
  11250 	X% = 640 + scale_world_to_screen * x/z * focal_distance
  11260 	Y% = 512 + scale_world_to_screen * y/z * focal_distance
  11270 	Z% = 1
  11280 ENDPROC
  11290 :

  11310 DEF PROCplotTriangleTele(xa,ya,xb,yb,xc,yc)
  11280 ENDPROC
  11310 :

  11310 :

RUN



