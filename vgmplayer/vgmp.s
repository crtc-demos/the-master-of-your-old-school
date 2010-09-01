	.org $e00

start:
	@load_file_to trackname, tune
	

trackname:
	.asc "track",13

	.include "../lib/mos.s"
	.include "../lib/load.s"


tune:
