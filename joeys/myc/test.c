// #define _MAIN_C_

/* #include <time.h>
#include <ctype.h> */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

short colMasks[4][4] = {
	{ 0x00, 0x00, 0x00, 0x00 },
	{ 0x08, 0x04, 0x02, 0x01 },
	{ 0x80, 0x40, 0x20, 0x10 },
	{ 0x88, 0x44, 0x22, 0x11 }
};

void putpixel(int x, int y, unsigned char col) {
	// MODE 1
	#define BYTES_PER_LINE (40*8*2)
	unsigned char *loc = (void*) ( 0x3000 + BYTES_PER_LINE*(y/8) + 8*(x/4) + (y%8) );
	*(loc) |= colMasks[col][x&3];
}

// FOCAL_DIST is a world distance but it matches the screen units.
#define FOCAL_DIST 109
#define PLANE_DEPTH 32
#define GRID_SIZE 8

// int main (int argc, char **argv)
void main ()
{
	int x,y;
	for (y=128;y<256;++y) {
		for (x=0;x<320;++x) {
			#define scry (y-127)
			#define scrx (x-160)
			int wz = PLANE_DEPTH * FOCAL_DIST / scry;
			// int wx = scrx * wz / FOCAL_DIST;
			int wx = PLANE_DEPTH * scrx / scry;
			// putpixel(x,y,1 + ((abs(wx/GRID_SIZE)+wz/GRID_SIZE)%2));
			putpixel(x, y, ( ((wx/GRID_SIZE)&3) == 2 ? 1 : 0 ) + ( ((wz/GRID_SIZE)&3) == 0 ? 2 : 0 ) );
			// putpixel(x,y,1 + (((wx+wz) >> 5) & 1)); // not working right
		}
	}
}

