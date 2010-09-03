	.org $1200

start:
	@load_file_to vgmplayer, $e00

	ldx #<logo
	ldy #>logo
	jsr oscli
	
vgmplayer
	.asc "vgmp",13
logo
	.asc "logo",13

	.include "../lib/mos.s"
	.include "../lib/load.s"
