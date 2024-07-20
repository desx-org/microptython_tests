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
MICROPY_MPYCROSS:=$b/mpy-cross
MICROPY_MPYCROSS_DEPENDENCY:=$(MICROPY_MPYCROSS)

TOP:=$b/$(NAME)

PORT_NAME:=unix
PORT_DIR:=$(TOP)/ports/$(PORT_NAME)


TAR:=$(CACHE_DIR)/$(NAME).tar.gz
.PHONY:check tar

tar:$(TAR)

$(TAR): |$(CACHE_DIR) $b
	mkdir -p $(GIT_DL_TMP)
	git clone --depth 1 --branch $(COMMIT) https://github.com/$(USER)/$(REPO).git $(GIT_DL_TMP)
	make -C $(GIT_DL_TMP)/ports/$(PORT_NAME) V=1 submodules | tee $b/submodules_$(PORT_NAME)_loc.txt
	tar -C $(GIT_DL_TMP) -czf $(TAR) .
	rm -rf $(GIT_DL_TMP)
	
VARIANT:=standard
#VARIANT:=minimal

#VARIANT:=coverage
#VARIANT:=nanbox
VARIANT_DIR:=$(PORT_DIR)/variants/$(VARIANT)

MAKEFLAGS:=-j 6

MPY_TGT:=$(TOP)/README.md
.PHONY:mpy
mpy:$(MPY_TGT)


$(MPY_TGT):$(TAR)|$(TOP)
	tar -m -C $(TOP) -xf $< 
	patch  -d $(TOP) -p2  < $(PATCH)

CROSS_DIR:=$(TOP)/mpy-cross
MPY_DIR_R:= $(shell realpath --relative-to=$(CROSS_DIR) $(TOP))
MPY_DIR_R2:= $(shell realpath --relative-to=$(PORT_DIR) $(TOP))
TOP_R:= $(shell realpath --relative-to=$(abspath $(PORT_DIR)) $(abspath $(TOP)))

BUILD:=$b/build-$(VARIANT)



EXPORT_VARS:=PORT_DIR TOP MICROPY_MPYCROSS MICROPY_MPYCROSS_DEPENDENCY VARIANT VARIANT_DIR BUILD CROSS_DIR

EXPORT=$(foreach V, $(EXPORT_VARS),$V=$($V))

#make -f $(PORT_DIR)/Makefile $(EXPORT) BUILD=$b submodules 2>&1 | tee  $b/submodules_$(PORT_NAME)_rem.txt

check2:  $(MPY_TGT) $b/build-standard
	rm -rf $(BUILD)
	make -f $(CROSS_DIR)/Makefile $(EXPORT) PORT_DIR=$(CROSS_DIR) BUILD=$b V=1 2>&1 |tee  $b/mpy_cross_rem.txt
	make -f $(PORT_DIR)/Makefile $(EXPORT) 2>&1 | tee  $b/unix_$(PORT_NAME)_rem.txt

cross:  $(MPY_TGT) $b/build-standard
	make -f $(CROSS_DIR)/Makefile $(EXPORT) PORT_DIR=$(CROSS_DIR) BUILD=$b V=1 2>&1 |tee  $b/mpy_cross_rem.txt

define MKDIR_RULE
$1:
	mkdir -p $$@
endef

REF:=$b/ref_$(NAME)


.PHONY:save

save:$(MPY_TGT)
	rm -rf $(PATCH) $(REF)
	mkdir -p $(REF)
	tar -C $(REF) -xf $(TAR) 
	diff  -U0 -rN --exclude=*\.git* --exclude=__pycache__  $(REF) $(TOP) > $(PATCH) || true
	rm -rf $(REF) 

cln:
	rm -rf $b

cln_all:
	rm -rf $b $(CACHE_DIR)

BUILD:=$b/build
$(PORT_DIR)/Makefile: | cross $(MPY_TGT) $(BUILD)

#include $(PORT_DIR)/Makefile

DIRS+=$(BUILD) $(GIT_DL_TMP) $(CACHE_DIR) $b $(TOP) $(REF)

$(foreach V,$(DIRS),$(eval $(call MKDIR_RULE,$V)))
