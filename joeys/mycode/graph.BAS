;;; GRAPH.BAS
; Make a graph plotter which as smoothly as possible animates the graph e.g.
; rotates it, or plots it with one of the parameters changing, and displays the
; surface via a grid based on x,y or u,v or contour lines.





;; Super-efficient line moving
; If we take two frames of the lines with the intention of interpolating them
; to plot a number of screen planes
; and the lines we have are 2d
; then we should be able to calculate the max-speed of each line, and (by
; sorting?) prioritise those lines which move quickly over those which move
; rarely.
; The aim would be to update a line only when (exactly when) one of its pixels
; would change (in a sub-pixel anti-aliased plot ofc).
; One 







;; Evaluation of equations using lookups

; The logarith shortcut for multiplication.  We may want to switch between the two sometimes but not always between operations to calculate an equation.  In other words we don't want to waste time by always staying in (converting back to) one of the states.




;; Fading
; If we have too many grid lines or many curves which are too long, we could attempt to fade by some sort of dithering.
; Meaning we would consider the curve to be stretched thinner than 1 pixel width in some places, so that a pixel would only sometimes be plotted at any part along that line.
; If they are chosen correctly interesting moire effects should be visible.




