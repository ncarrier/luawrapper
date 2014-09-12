# Package-related substitution variables
export package     = luawrapper
export version     = 0.1
export tarname     = $(package)
export distdir     = $(tarname)-$(version)

# Prefix-related substitution variables
export prefix      = /usr/local
export exec_prefix = $(prefix)
export libdir      = $(exec_prefix)/lib

# related substitution variables
export CC          ?= gcc
export CFLAGS      ?= -Os
export CPPFLAGS    ?=
export AR          ?= ar

export Q           ?= @

CPPFLAGS += \
	-I. \
	-Iinclude/ \
	-Isrc/libelf/common/ \
	-Isrc/libelf/ \
	-Isrc/lua/

luawrapper_gen_src := \
	src/libelf/libelf_msize.c \
	src/libelf/libelf_fsize.c \
	src/libelf/libelf_convert.c

.SECONDARY: $(luawrapper_gen_src)

luawrapper_src := \
	$(shell find src -name *.c) \
	$(luawrapper_gen_src)

luawrapper_objects := $(luawrapper_src:.c=.o)

luawrapper_clean_files := \
	$(luawrapper_gen_src) \
	native-elf-format.h \
	luawrapper.a \
	$(luawrapper_objects) \
	$(luawrapper_src:.c=.d)

all: luawrapper.a examples

native-elf-format.h:
	@echo generate platform dependant header $@
	$(Q) LANG=C src/libelf/common/native-elf-format > $@

-include $(luawrapper_src:.c=.d)

%.d: %.c
	$(Q) set -e; rm -f $@; \
	$(CC) -MM -MG $(CPPFLAGS) $< | \
		sed 's,\(^[^:]*\):,$(dir $@)\1 $@ : ,g' > $@; \

# TODO tester $?
luawrapper.a: $(luawrapper_objects)
	@echo creation of $@
	$(Q) $(AR) cr $@ $^

src/libelf/libelf_%.c: src/libelf/libelf_%.m4
	@echo "generate m4 generated $@ for luawrapper"
	$(Q) (cd src/libelf/; m4 -D SRCDIR=. $(notdir $^) > $(notdir $@))

examples: luawrapper.a
	$(MAKE) -C examples

clean:
	$(Q) -rm -f $(luawrapper_clean_files) &>/dev/null
	$(MAKE) -C examples clean

check: all
	$(MAKE) -C examples check

install:
	install -d $(DESTDIR)$(libdir)
	install -m 0755 luawrapper.a $(DESTDIR)$(libdir)

uninstall:
	-rm $(DESTDIR)$(libdir)/luawrapper.a &>/dev/null

dist: $(distdir).tar.gz

$(distdir).tar.gz: FORCE $(distdir)
	tar chof - $(distdir) | gzip -9 -c >$(distdir).tar.gz
	rm -rf $(distdir)

$(distdir):
	mkdir -p $(distdir)/src/libelf/common
	mkdir -p $(distdir)/src/lua
	mkdir -p $(distdir)/include
	cp Makefile $(distdir)
	cp include/lw_dependencies.h $(distdir)/include
	cp src/Makefile $(distdir)/src
	cp src/luawrapper.c $(distdir)/src
	cp src/lua/*.c $(distdir)/src/lua
	cp src/lua/*.h $(distdir)/src/lua
	cp src/libelf/*.c $(distdir)/src/libelf
	cp src/libelf/*.h $(distdir)/src/libelf
	cp src/libelf/*.m4 $(distdir)/src/libelf
	cp src/libelf/common/*.h $(distdir)/src/libelf/common
	cp src/libelf/common/native-elf-format $(distdir)/src/libelf/common

distcheck: $(distdir).tar.gz
	gzip -cd $+ | tar xvf -
	$(MAKE) -C $(distdir) all check
	$(MAKE) -C $(distdir) DESTDIR=$${PWD}/$(distdir)/_inst install uninstall
	$(MAKE) -C $(distdir) clean
	rm -rf $(distdir)
	@echo "*** Package $(distdir).tar.gz is ready for distribution."

FORCE:
	-rm -rf $(distdir) &>/dev/null
	-rm $(distdir).tar.gz &>/dev/null

.PHONY: FORCE all examples clean check dist distcheck install uninstall
