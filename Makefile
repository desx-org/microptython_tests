d=.

b:=bin
DIRS+=$b

CACHE_DIR?= $d/.cache
DIRS+=$(CACHE_DIR)
all:mpy
USER:=micropython
REPO:=micropython
COMMIT:=v1.23.0
NAME:=$(USER)_$(REPO)_$(COMMIT)
PATCH:=$d/patches/micropython.diff

GIT_DL_TMP=/tmp/git_dl

DIRS+=$(GIT_DL_TMP)
TAR:=$(CACHE_DIR)/$(NAME).tar.gz
$(TAR): |$(CACHE_DIR)
	mkdir -p $(GIT_DL_TMP)
	git clone --depth 1 --branch $(COMMIT) https://github.com/$(USER)/$(REPO).git $(GIT_DL_TMP)
	make -C $(GIT_DL_TMP)/ports/minimal submodules
	tar --exclude='.git' -C $(GIT_DL_TMP) -czf $(TAR) .
	rm -rf $(GIT_DL_TMP)
	
MPY_DIR:=$b/$(NAME)
PORT_DIR:=$(MPY_DIR)/ports/minimal

MAKEFLAGS:=-j 6

MPY_TGT:=$(MPY_DIR)/README.md
.PHONY:mpy
mpy:$(MPY_TGT)

DIRS+=$(MPY_DIR)

$(MPY_TGT):$(TAR)|$(MPY_DIR)
	tar -m -C $(MPY_DIR) -xf $< 
	patch  -d $(MPY_DIR) -p2  < $(PATCH)

define MKDIR_RULE
$1:
	mkdir -p $$@
endef

REF:=$b/ref_$(NAME)

DIRS+=$(REF)

.PHONY:save

save:$(MPY_TGT)
	rm -rf $(PATCH) $(REF)
	mkdir -p $(REF)
	tar -C $(REF) -xf $(TAR) 
	diff -ruN  $(REF) $(MPY_DIR) > $(PATCH) || true
	rm -rf $(REF) 

cln:
	rm -rf $b

cln_all:
	rm -rf $b $(CACHE_DIR)

TOP:=$(MPY_DIR)

BUILD:=$b/build
$(PORT_DIR)/Makefile:$(MPY_TGT)|$(BUILD)
$(info  $(PORT_DIR)/Makefile)

INC+=-I$(PORT_DIR)
DIRS+=$(BUILD)
include bin/micropython_micropython_v1.23.0/ports/minimal/Makefile
#include $(PORT_DIR)/Makefile

$(foreach V,$(DIRS),$(eval $(call MKDIR_RULE,$V)))

#$1_$2_$3:
#	tar -xf $(CACHE_DIR)/$1_$2_$3.tar.gz


#$(eval $(call GIT_DL,micropython,micropython,v1.23.0))

#GIT_URL:=https://github.com/USER/REPOSITORY/archive/COMMIT.tar.gz
#MPY_TAR
#MPY_VER:=v1.23.0
#MPY_DIR:=$(HOME)/repos/micropython
#MPY_DIR_:=$(HOME)/repos/patch/micropython
#
#MPY_README:=$(MPY_DIR)/README.md
#MPY_MK:=$(MPY_DIR)/ports/minimal/Makefile
#
#MPY_PTCH:$d/patch/micropython.diff
#
#DIRS+=$b $(CACHE_DIR)
#
#$(MPY_TAR):
#	wget $(call GIT_URL,micropython,micropython,v1.23.0) -O $()
#
#$(MPY_README):
#	wget $(call GIT_URL,micropython,micropython,v1.23.0) -O $()
#	patch $(MPY_DIR) $(MPY_DIR)
#
#$(MPY_DIR_):
#	wget $(call GIT_URL,micropython,micropython,v1.23.0)
#
#save:
#	diff  -r $(MPY_DIR) $(MPY_DIR_) -x .git -x *.swp >> $(MPY_PATCH) 
#
#$(MPY_MK):$(MPY_README)
#TOP:=$(MPY_DIR)
#include $(MPY_MK)
#
#

