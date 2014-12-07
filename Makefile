
BUILD_DIR=./build

HOST=arm-linux-gnueabihf
TARGET_GCC=arm-linux-gnueabihf-gcc

KOBO_DIR=$(BUILD_DIR)/KoboRoot
KOBO_USR_DIR=$(KOBO_DIR)/usr
KOBO_USR_BIN_DIR=$(KOBO_USR_DIR)/bin
KOBO_USR_LIB_DIR=$(KOBO_USR_DIR)/lib

KOBO_TAR=$(BUILD_DIR)/KoboRoot.tgz

ETC_DIR=./etc

LUA_URL=http://www.lua.org/ftp/lua-5.2.3.tar.gz
LUA_TAR=$(BUILD_DIR)/lua-5.2.3.tar.gz
LUA_DIR=$(BUILD_DIR)/lua-5.2.3
LUA=$(LUA_DIR)/src/lua
LUAC=$(LUA_DIR)/src/luac
LIBLUA=$(LUA_DIR)/src/liblua.a

NCURSES_URL=http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz
NCURSES_TAR=$(BUILD_DIR)/ncurses-5.9.tar.gz
NCURSES_DIR=$(BUILD_DIR)/ncurses-5.9
NCURSES_BUILD_DIR=$(shell readlink -f ./)$(NCURSES_DIR)/build
NCURSES_CONFIGURE_FLAGS= --host=$(HOST) --prefix=$(NCURSES_BUILD_DIR) --enable-widec --with-shared --without-ada --without-progs --without-tests --without-cxx-binding

NANO_URL=http://www.nano-editor.org/dist/v2.3/nano-2.3.6.tar.gz
NANO_TAR=$(BUILD_DIR)/nano-2.3.6.tar.gz
NANO_DIR=$(BUILD_DIR)/nano-2.3.6
NANO_BUILD_DIR=$(shell readlink -f ./)$(NANO_DIR)/build
NANO_CONFIGURE_FLAGS= --host=$(HOST) --prefix=$(NANO_BUILD_DIR) --enable-widec --with-shared --without-ada --without-progs --without-tests --without-cxx-binding


DROPBEAR_URL=https://matt.ucc.asn.au/dropbear/releases/dropbear-2014.66.tar.bz2
DROPBEAR_TAR=$(BUILD_DIR)/dropbear-2014.66.tar.bz2
DROPBEAR_DIR=$(BUILD_DIR)/dropbear-2014.66
DROPBEAR_BUILD_DIR=$(shell readlink -f ./)$(DROPBEAR_DIR)/build
DROPBEAR_CONFIGURE_FLAGS= --host=$(HOST) --prefix=$(DROPBEAR_BUILD_DIR) --enable-widec --with-shared --without-ada --without-progs --without-tests --without-cxx-binding --disable-zlib


all: etc lua ncurses nano dropbear
	tar -C $(KOBO_DIR) -zcvf $(KOBO_TAR) . ;

#building the tar based off what's already there
tar: 
	tar -C $(KOBO_DIR) -zcvf $(KOBO_TAR) . ;

etc: $(KOBO_DIR)
	cp -R $(ETC_DIR) $(KOBO_DIR)	





#note: had to make some changes to that standard lua package to get this to work =P.
#changed the makefile to use arm-linux-gnueabihf
lua: $(LUA_DIR) $(KOBO_USR_BIN_DIR) $(KOBO_USR_LIB_DIR)
	#fix the stupid readline in luaconf.h
	sed -i -e s/"#define LUA_USE_READLINE"/"#undef LUA_USE_READLINE"/g $(LUA_DIR)/src/luaconf.h
	sed -i -e s/"-lreadline"/""/g $(LUA_DIR)/src/Makefile
	cd $(LUA_DIR) && \
	make CC=$(TARGET_GCC) linux
	cp $(LUA) $(KOBO_USR_BIN_DIR)
	cp $(LUAC) $(KOBO_USR_BIN_DIR)
	cp $(LIBLUA) $(KOBO_USR_LIB_DIR)

$(LUA_DIR): $(BUILD_DIR)
	wget $(LUA_URL) -O $(LUA_TAR) 
	tar -xf $(LUA_TAR) -C $(BUILD_DIR)




ncurses: $(NCURSES_BUILD_DIR) $(KOBO_USR_DIR) $(KOBO_DIR)
	cd $(NCURSES_DIR) && \
	./configure $(NCURSES_CONFIGURE_FLAGS) && \
	make && \
	make install
	cp -R $(NCURSES_BUILD_DIR)/* $(KOBO_USR_DIR)/

$(NCURSES_BUILD_DIR): $(NCURSES_DIR)
	mkdir -p $(NCURSES_BUILD_DIR)

$(NCURSES_DIR): $(BUILD_DIR)
	wget $(NCURSES_URL) -O $(NCURSES_TAR) 
	tar -xf $(NCURSES_TAR) -C $(BUILD_DIR)




#note: to get nano working after install, export TERMINFO=/usr/share/terminfo/
nano: ncurses $(NANO_BUILD_DIR)
	cd $(NANO_DIR) && \
	env LDFLAGS=-L$(NCURSES_BUILD_DIR)/lib ./configure $(NANO_CONFIGURE_FLAGS) && \
	make && \
	make install
	cp -R $(NANO_BUILD_DIR)/* $(KOBO_USR_DIR)/

$(NANO_BUILD_DIR): $(NANO_DIR)
	mkdir -p $(NANO_BUILD_DIR)

$(NANO_DIR): $(BUILD_DIR)
	wget $(NANO_URL) -O $(NANO_TAR) 
	tar -xf $(NANO_TAR) -C $(BUILD_DIR)





#once dropbear is installed, you'll need to configure it over telnet:
#telnet in, and generate ssh keys using dropbearkey:
#mkdir -p /etc/dropbear/
#cd /etc/dropbear
#dropbearkey -t rsa -f dropbear_rsa_host_key
#dropbearkey -t dss -f dropbear_dss_host_key
#add the line "ssh  stream tcp nowait root /usr/local/sbin/dropbear dropbear -i" to the end of /etc/inetd.conf
#and use telnet/passwd to set a root passwd, otherwise you won't be able to log in
dropbear: $(DROPBEAR_BUILD_DIR)
	cd $(DROPBEAR_DIR) && \
	./configure $(DROPBEAR_CONFIGURE_FLAGS) && \
	make && \
	make install
	cp -R $(DROPBEAR_BUILD_DIR)/* $(KOBO_USR_DIR)/

$(DROPBEAR_BUILD_DIR): $(DROPBEAR_DIR)
	mkdir -p $(DROPBEAR_BUILD_DIR)

$(DROPBEAR_DIR): $(BUILD_DIR)
	wget $(DROPBEAR_URL) -O $(DROPBEAR_TAR) 
	tar -xf $(DROPBEAR_TAR) -C $(BUILD_DIR)






$(KOBO_USR_LIB_DIR): $(KOBO_USR_DIR)
	mkdir -p $(KOBO_USR_LIB_DIR)

$(KOBO_USR_BIN_DIR): $(KOBO_USR_DIR)
	mkdir -p $(KOBO_USR_BIN_DIR)

$(KOBO_USR_DIR): $(KOBO_DIR)
	mkdir -p $(KOBO_USR_DIR)

$(KOBO_DIR): $(BUILD_DIR)
	mkdir -p $(KOBO_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

