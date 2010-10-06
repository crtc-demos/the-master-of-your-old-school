;;; Wireframe Plan

;; Hold an (editable) scene which is an array of polygons in 3d space and an
;; array of edges (lines) in 3d space, as well as indexes linking them.

;; Make a copy of the relevant objects in the scene, that is the edges which
;; are on one or more polygons which face the camera.  When they are copied
;; they must be translated and rotated into camera's coordinate system.  The
;; normal of the polygon relative to the camera focal point can be checked
;; before or after the transformation.

;; As a final part of this copying, we may perform a reverse of the perspective
;; projection, making the (x,y) "flat" but with depth/distance.

;; Now we just have a bunch of lines with depth.  We should have stored them in
;; an appropriate data structure, because now we will...

;; For each line (call it the plot line), check if there are any lines *in
;; front* of it which might overlap.  (For close lines, we can check the depths
;; again at the point of intersection.)  For each line which does intersect our
;; plot line (and in front of it), we split the plot line where it hits.  Hmmm.
;; Our plot line might be crossed by any number of lines in front of it.
;; Consider the case when 2 foreground lines intersect it.  They could either
;; represent a "spike" crossing the line to take a chunk out of it, or they
;; could represent a "valley" where they provide a gap through which the middle
;; part of the line can be seen.  We must detect these cases to decide which
;; chunk of the plot line to keep.

;; When we cross an occluding line, our coincidence with the normal of the
;; polygon can tell us which sides of the intersection were occluded or not.
;; This could be represented as a 2d vector, angle, or complex number.

#if 0

;; Another trick is:  If we want to know if a point in space is inside or
;; outside the object, we can draw a line from that point to the distance, and
;; check if that line intersects the surface of the object.

;; Is this trick also possible using the flattened data?

;; Well we could attach a (2d or 3d?) normal to each line, which can be
;; calculated from the normals of its 1 or 2 polygons.  OK now with the
;; exception of lines with normals directly into or out of the camera, when our
;; plot line intersects with a frontal line, we can say whether the transition
;; across the frontal line caused us to go into or out of the solid object.
;; Hmm this has problems however.  If a lot of lines intersect, it's hard to
;; tell which order to process them in.  Presumably the frontal ones are most
;; relevant, and cancel out any lines they themselves occlude.  So process the
;; potential overlaps from front to back?  During this process our plot line
;; might split into a number of smaller lines, presumably all of which should
;; be re-processed...

;; The alternative is ... ?

#endif

;; Some approaches

;; a) For each line, lookup the polygons possibly in front of it, check them,
;; chop and plot the lines.  Polygons could be stored in a quadtree, or a
;; coarse x,y,z array of linked-list (iteration would include all frontal
;; bins).

;; b) Collect the lines into a data structure, then for each polygon, chop
;; apart or entirely remove the lines behind it.  Then plot he lines.

;; c) Go from front to back, and on the way build up a silhouette.  This could
;; be a set of polygons, or a mask.  When plotting further lines, only those
;; parts outside the silhouette should be plotted.
;; (It should be pretty quick to check if a particular point is inside or outside
;; the silhouette.  E.g. see if we intersect any of the edges of the silhouette
;; if we go vertically upwards to infinity.)

Maybe the guy at Sundown wanted to restrict it to working on a scaline basis.
So you take a horizontal line, and know all the lines which intersect it, but then what?


