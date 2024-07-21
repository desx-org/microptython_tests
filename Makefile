d=.
b:=bin
CACHE_DIR?= $d/.cache
MPY_USER:=micropython
MPY_REPO:=micropython
MPY_COMMIT:=v1.23.0
#MPY_NAME:=$(MPY_USER)_$(MPY_REPO)_$(MPY_COMMIT)
MPY_NAME:=m
MPY_PATCH:=$d/patches/micropython.diff
GIT_DL_TMP=/tmp/git_dl
MICROPY_MPYCROSS:=$b/mpy-cross
MICROPY_MPYCROSS_DEPENDENCY:=$(MICROPY_MPYCROSS)
TOP:=$b/$(MPY_NAME)
PORT_NAME:=unix
PORT_DIR:=$(TOP)/ports/$(PORT_NAME)
MPY_TAR:=$(CACHE_DIR)/$(MPY_NAME).tar.gz

INC_FILE:=$(abspath $(PORT_DIR)/Makefile)

VARIANT:=standard
#VARIANT:=minimal

#VARIANT:=coverage
#VARIANT:=nanbox
VARIANT_DIR:=$(PORT_DIR)/variants/$(VARIANT)

MAKEFLAGS:=-j 6

#MPY_TGT:=$(TOP)/README.md
MPY_TGT:=$(INC_FILE)

CROSS_DIR:=$(TOP)/mpy-cross

BUILD:=$b/build-$(VARIANT)

EXPORT_VARS:=PORT_DIR TOP MICROPY_MPYCROSS MICROPY_MPYCROSS_DEPENDENCY VARIANT VARIANT_DIR BUILD CROSS_DIR b

EXPORT=$(foreach V, $(EXPORT_VARS),$V=$($V))

PROG:=micropython

all:$(BUILD)/$(PROG)

check2: $(MPY_TGT) $b/build-standard
	rm -rf $(BUILD)
	make -f $(PORT_DIR)/Makefile $(EXPORT) V=1 2>&1 | tee  $b/unix_$(PORT_NAME)_rem.txt




.PHONY:mpy
mpy:$(MPY_TGT)

$(MPY_TGT):$(MPY_TAR)|$(TOP)
	tar -m -C $(TOP) -xf $< 
	patch  -d $(TOP) -p2  < $(MPY_PATCH)

tar:$(MPY_TAR)

$(MPY_TAR): |$(CACHE_DIR) $b
	mkdir -p $(GIT_DL_TMP)
	git clone --depth 1 --branch $(MPY_COMMIT) https://github.com/$(MPY_USER)/$(MPY_REPO).git $(GIT_DL_TMP)
	make -C $(GIT_DL_TMP)/ports/$(PORT_NAME) V=1 submodules | tee $b/submodules_$(PORT_NAME)_loc.txt
	tar -C $(GIT_DL_TMP) -czf $(MPY_TAR) .
	rm -rf $(GIT_DL_TMP)

define MKDIR_RULE
$1:
	mkdir -p $$@
endef

.PHONY:save

REF:=$b/ref_$(MPY_NAME)

save:$(MPY_TGT)
	rm -rf $(PATCH) $(REF)
	mkdir -p $(REF)
	tar -C $(REF) -xmf $(MPY_TAR) 
	diff  -U0 -rN --exclude=*\.git* --exclude=__pycache__  $(REF) $(TOP) > $(MPY_PATCH) || true
	rm -rf $(REF) 

cln:
	rm -rf $b

cln_all:
	rm -rf $b $(CACHE_DIR)


DIRS+=$(BUILD) $(GIT_DL_TMP) $(CACHE_DIR) $b $(TOP) $(REF) $(dir $(MICROPY_MPYCROSS))

$(foreach V,$(DIRS),$(eval $(call MKDIR_RULE,$V)))

include $(INC_FILE)
