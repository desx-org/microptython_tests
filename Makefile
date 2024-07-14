d=.

b:=bin
CACHE_DIR?= $d/.cache

all:mpy
USER:=micropython
REPO:=micropython
COMMIT:=v1.23.0
NAME:=$(USER)_$(REPO)_$(COMMIT)
PATCH:=$d/patches/micropython.diff

GIT_DL_TMP=/tmp/git_dl
MPY_DIR:=$b/$(NAME)

PORT_NAME:=unix
PORT_DIR:=$(MPY_DIR)/ports/$(PORT_NAME)

DIRS+=$(GIT_DL_TMP) $(CACHE_DIR) $b 


TAR:=$(CACHE_DIR)/$(NAME).tar.gz
.PHONY:check tar

tar:$(TAR)

#tar --exclude='.git' -C $(GIT_DL_TMP) -czf $(TAR) .
$(TAR): |$(CACHE_DIR) $b
	mkdir -p $(GIT_DL_TMP)
	git clone --depth 1 --branch $(COMMIT) https://github.com/$(USER)/$(REPO).git $(GIT_DL_TMP)
	make -C $(GIT_DL_TMP)/ports/$(PORT_NAME) V=1 submodules | tee $b/submodules_$(PORT_NAME)_loc.txt
	tar -C $(GIT_DL_TMP) -czf $(TAR) .
	rm -rf $(GIT_DL_TMP)

	
VARIANT:=standard
VARIANT_DIR:=$(PORT_DIR)/variants/$(VARIANT)

MAKEFLAGS:=-j 6

MPY_TGT:=$(MPY_DIR)/README.md
.PHONY:mpy
mpy:$(MPY_TGT)

DIRS+=$(MPY_DIR)

$(MPY_TGT):$(TAR)|$(MPY_DIR)
	tar -m -C $(MPY_DIR) -xf $< 
	patch  -d $(MPY_DIR) -p2  < $(PATCH)


CROSS_DIR:=$(MPY_DIR)/mpy-cross
MPY_DIR_R:= $(shell realpath --relative-to=$(CROSS_DIR) $(MPY_DIR))
$(info MPY_DIR_R: $(MPY_DIR_R))
$(info MPY_DIR_R: $(MPY_DIR_R))

#make -C $(CROSS_DIR) PORT_DIR=. TOP=$(MPY_DIR_R) BUILD=$b V=1 2>&1 | tee  $b/mpy_cross_loc.txt
#git -C $(CROSS_DIR) clean -xdf

check:  $(MPY_TGT)
	git -C $(MPY_DIR) clean -xdf
	make -f $(CROSS_DIR)/Makefile PORT_DIR=$(CROSS_DIR) TOP=$(MPY_DIR) BUILD=$b V=1 2>&1 |tee  $b/mpy_cross_rem.txt
	make -f $(PORT_DIR)/Makefile PORT_DIR=$(PORT_DIR) TOP=$(MPY_DIR) BUILD=$b MICROPY_MPYCROSS=$b/mpy-cross MICROPY_MPYCROSS_DEPENDENCY=$b/mpy-cross V=1 submodules 2>&1 | tee  $b/submodules_$(PORT_NAME)_rem.txt
	@echo =======================================
	make -f $(PORT_DIR)/Makefile PORT_DIR=$(PORT_DIR) TOP=$(MPY_DIR) BUILD=$b MICROPY_MPYCROSS=$b/mpy-cross MICROPY_MPYCROSS_DEPENDENCY=$b/mpy-cross  VARIANT=$(VARIANT) VARIANT_DIR=$(VARIANT_DIR) V=1 2>&1 | tee  $b/submodules_$(PORT_NAME)_rem.txt

#make -f $(CROSS_DIR)/Makefile PORT_DIR=$(CROSS_DIR) TOP=$(MPY_DIR) V=1 2>&1 | sed 's/bin\/micropython_micropython_v1.23.0\/mpy-cross/./g' | tee  $b/mpy_cross_rem.txt

#git -C $(MPY_DIR)/mpy-cross clean -xdf

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

INC+=-I$(PORT_DIR)
DIRS+=$(BUILD)

#include $(PORT_DIR)/Makefile

$(foreach V,$(DIRS),$(eval $(call MKDIR_RULE,$V)))
