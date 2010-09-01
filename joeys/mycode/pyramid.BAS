; Equilateral pyramid in MODE 2.
; 3 faces only, red, green, blue, solid triangles.
; Camera starts above, looking down at a triangle, before swinging around a bit.
; Using ORing of 1,2,4 we can perform "transparency"!
; When camera stops for a while, draw some grid lines on the plane.
; Problem: we will never get 7 with such a pyramid! :P

; Alternative:
; Use MODE 1, only have RGB
; But setup some dithering scheme so that each channel will only affect its own pixels
; With dirty dithering, we can worry less about the exact edges of our object?  Hmm no if we work on character-basis then viewer will see that we are doing so, even with dithering.

