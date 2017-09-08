MAKEFILE_PATH     := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR          := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))

NAMESPACE         ?= openshift

_OC_CMD           := oc -n $(NAMESPACE)

define client_check
    @type oc > /dev/null 2>&1 || {
        echo 1>&2 "OpenShift Client (oc) not found in \$PATH"; exit 1
    }
endef

define delete_config
    @$(_OC_CMD) delete imagestream $(1) || :
    @$(_OC_CMD) delete buildconfig $(1) || :
endef

define install_or_replace_config
    @$(_OC_CMD) create -f $(ROOT_DIR)/.openshift/$(1)/image-stream.yaml \
        || $(_OC_CMD) replace -f $(ROOT_DIR)/.openshift/$(1)/image-stream.yaml
    @$(_OC_CMD) create -f $(ROOT_DIR)/.openshift/$(1)/build-config.yaml \
        || $(_OC_CMD) replace -f $(ROOT_DIR)/.openshift/$(1)/build-config.yaml
endef

.PHONY: all clean clean/base clean/s2i install install/base install/s2i \
    clean/6.x install/6.x clean/6.x/s2i install/6.x/s2i \
    clean/7.x install/7.x clean/7.x/s2i install/7.x/s2i \
    clean/8.x install/8.x clean/7.x/s2i install/8.x/s2i test

all: | clean install

oc:
    $(call cient_check)

clean/6.x:
    $(call delete_config,nodejs-6)

clean/6.x/s2i:
    $(call delete_config,nodejs-6-s2i)

install/6.x:
    $(call install_or_replace_config,v6.x)

install/6.x/s2i:
    $(call install_or_replace_config,v6.x/s2i)

clean/7.x:
    $(call delete_config,nodejs-7)

clean/7.x/s2i:
    $(call delete_config,nodejs-7-s2i)

install/7.x:
    $(call install_or_replace_config,v7.x)

install/7.x/s2i:
    $(call install_or_replace_config,v7.x/s2i)

clean/8.x:
    $(call delete_config,nodejs-8)

clean/8.x/s2i:
    $(call delete_config,nodejs-8-s2i)

install/8.x:
    $(call install_or_replace_config,v8.x)

install/8.x/s2i:
    $(call install_or_replace_config,v8.x/s2i)

clean/s2i: | clean/6.x/s2i clean/7.x/s2i clean/8.x/s2i

clean/base: | clean/6.x clean/7.x clean/8.x

clean: | oc clean/s2i clean/base

install/s2i: | install/6.x/s2i install/7.x/s2i install/8.x/s2i

install/base: | install/6.x install/7.x install/8.x

install: | oc install/base install/s2i

test:
    @echo $(_OC_CMD)
