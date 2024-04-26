OBJECTS+=														\
	load/load.o													\
	load/fat_io_lib/fat_access.o load/fat_io_lib/fat_cache.o	\
	load/fat_io_lib/fat_filelib.o load/fat_io_lib/fat_format.o	\
	load/fat_io_lib/fat_misc.o load/fat_io_lib/fat_string.o		\
	load/fat_io_lib/fat_table.o load/fat_io_lib/fat_write.o
DEFINES+=-DFATFS_USE_CUSTOM_OPTS_FILE
INCLUDES+=-Iload/include -I../stage1/blockdev/include
