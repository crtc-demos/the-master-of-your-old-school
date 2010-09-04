
## game

## player options

## track (aka level or map or world template)

## objects in the 3d world which we will render
### level-of-detail: CanSkipRender() - actually return a score of whether to drop or not
###                  full and reduced and itermediary polygon version
##                   texture/lighting effect settings

## things to render on HUD



# State of Player
## position in 3d space (also same for other racers, bots)
## position along track
## orientation (on horizontal plane (x,y : yaw) , and also some pitch and roll)
## velocity, state of equipment, and controls (brakes, jets, air-brakes, direction stick)

## scene to render
## list of objects

## output screen
.. intermediary data
## target bitmap




## Render algorithm:
## Given camera pos, world object/scene.
## Filter/collect all objects in the current frustrum
## For all faces of all objects whose planes fact the camera (or double-sided), transform the object/world coords to 2d coords with some depth info also.  Order objects in tree so that nearest are prefered to farthest (?).  Each polygon gets a bounding circle (or rectangle?) and also a front and rear depth length, so in fact a rectangle but in the new coord system.
## For each line in the target image, collect/filter all polygons who hit the line, and order left-to-right.
## Do clever clipping according to depth, some colours won't be applied until the thing in front / partially occluding, changes it.  Some polygons will be skipped entirely on this line!
## "Fill in" columns with coloured pixels.  Or do wireframe.




## The 2d intermediary will basically be a set of 2D polygons, but we might want to associate ends (centres, and hence partway along lines too - correctly proportional?!) with depths into the screne(sic).
## Each polygon has a colour, probably a centre (maybe a bounding circle?), and can provide a set of edges.  These have perpendicular normal ofc in 2d.
## Where there are complex (sub-character) interactions, only render that char fully pixellated if the char is in the centre of the screen.  Nearer the edges we can just fudge it :)
## Or we can fudge all chars, doing no pixels, but letting them flicker probabilistically.
## What we are doing here is, instead of being blocky, adding noise to disguise the blockiness, and the noise is usually better than bad.



### ! ============================= ! ###
# Language and environment:
## Plugability of parts of program.  Enable/disable.  #defines!



## Nice logging system
## Don't define logSettingVar, then do fiddly logs to that channel, then print the channel logs
## Just call once.  Use hashtables.  Tho we must still check the bool before creating the string.






