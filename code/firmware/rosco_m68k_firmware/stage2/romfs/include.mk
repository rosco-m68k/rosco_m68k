OBJECTS+=romfs/load.o romfs/romfs.o romfs/lfs.o romfs/lfs_util.o
DEFINES+=-DROMFS_LOADER -DLFS_NO_MALLOC -DLFS_NO_ASSERT -DLFS_READONLY -DLFS_NO_DEBUG -DLFS_NO_WARN -DLFS_NO_ERROR
INCLUDES+=-Iromfs/include
