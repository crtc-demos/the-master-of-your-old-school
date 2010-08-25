#include <stdlib.h>

static unsigned char lut[][4] = {
  { 0x00, 0x00, 0x00, 0x00 },
  { 0x08, 0x04, 0x02, 0x01 },
  { 0x80, 0x40, 0x20, 0x10 },
  { 0x88, 0x44, 0x22, 0x11 }
};

#if 0
void
putpixel (unsigned int x, unsigned int y, int c)
{
  unsigned int row = y >> 3;
  unsigned char *rowstart = (char *) 0x3000 + (row * 640);
  rowstart += ((x << 1) & ~7) + (y & 7);
  *rowstart |= lut[c][x & 3];
}
#endif

#define PLANE_Y (-60)
#define ZOFFSET 1000

int
main (void)
{
  int y;
  char x;

  for (y = 129; y < 256; y++)
    {
      int j = 128 - y;
      int wz = (256 * PLANE_Y / j) - ZOFFSET;
      long wxr = 256l * 160l * ((long) wz + ZOFFSET);
      long wxl = -wxr;
      long wxd = (wxr - wxl) / 320l;
      unsigned char *rowstart = (char *) 0x3000 + (y & ~7) * 80 + (y & 7);
      unsigned char c = 1; // (wz & 0x40) ? 1 : 2;
      unsigned int mask = 255;

#if 0
      if (y & 1)
        {
	  if (wz > 600)
	    mask = 0x11111111;
	  if (wz > 300)
            mask = 0x55555555;
	  else if (wz > 0)
            mask = 0xeeeeeeee;
        }
      else
        {
	  if (wz > 600)
	    mask = 0x44444444;
	  if (wz > 300)
            mask = 0xcccccccc;
	  else if (wz > 0)
            mask = 0xbbbbbbbb;
        }
#endif

      for (x = 0; x < 80; x++)
        {
          unsigned char cbyte = 0;
	  unsigned char pix;

          for (pix = 0; pix < 4; pix++)
            {
	      unsigned char c2 = (wxl & 0x200000) ? (c ^ 3) : c;
	      cbyte |= lut[c2][pix];
	      wxl += wxd;
            }

	  *rowstart = cbyte & mask;
          rowstart += 8;
        }
    }

  return 0;
}
