static unsigned char lut[][4] = {
  { 0x00, 0x00, 0x00, 0x00 },
  { 0x08, 0x04, 0x02, 0x01 },
  { 0x80, 0x40, 0x20, 0x10 },
  { 0x88, 0x44, 0x22, 0x11 }
};

void putpixel (unsigned int x, unsigned int y, int c)
{
  unsigned int row = y >> 3;
  unsigned int column = x >> 2;
  unsigned char *rowstart = (char *) 0x3000 + (row * 640);
  rowstart[(column << 3) + (y & 7)] |= lut[c][x & 3];
}

#define PLANE_Y (-100)
#define ZSCALE 100

int main (void)
{
  int x, y;

  for (y = 128; y < 256; y++)
    for (x = 0; x < 320; x++)
      {
        int cx = x - 160, cy = 128 - y;
        int z = (PLANE_Y * ZSCALE) / cy;
        int wx = (ZSCALE * cx) / z;

        putpixel (x, y, (((wx >> 4) ^ (z >> 4)) & 1) + 1);
      }

  return 0;
}
