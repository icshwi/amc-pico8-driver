ifneq ($(KERNELRELEASE),)

  obj-m	:= amc_pico.o
  amc_pico-objs := 		\
	amc_pico_main.o 	\
	amc_pico_bist.o 	\
	amc_pico_char.o 	\
	amc_pico_dma.o

else

  KERNELDIR ?= /lib/modules/$(shell uname -r)/build
  PWD := $(shell pwd)

  PERL := perl

  KMOD_NAME := amc_pico
  QUIET := @

all: modules

modules: .config gen_py test/picodefs.py
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

modules_install:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules_install
	$(QUIET) echo "KERNEL==\"$(KMOD_NAME)*\", MODE=\"0666\"" | tee  /etc/udev/rules.d/99-$(KMOD_NAME).rules
	$(QUIET) /bin/udevadm control --reload-rules
	$(QUIET) /bin/udevadm trigger
	$(QUIET) echo "$(KMOD_NAME)" | tee /etc/modules-load.d/$(KMOD_NAME).conf
	$(QUIET) depmod --quick
	$(QUIET) modprobe -rv $(KMOD_NAME)
	$(QUIET) modprobe -v $(KMOD_NAME)


clean:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) clean
	$(QUIET)rm -f /etc/modules-load.d/$(KMOD_NAME).conf
	$(QUIET)rm -f /etc/udev/rules.d/99-$(KMOD_NAME).rules
	$(QUIET)rm -f $(PWD)/amc_pico_version.h
	$(QUIET)rm -f $(PWD)/gen_py

.config:
	$(QUIET) touch $(PWD)/$@

gen_py: gen_py.c amc_pico.h amc_pico_version.h
	$(CC) -o $@ -g -Wall $<

amc_pico_version.h:
	$(PERL) genVersionHeader.pl -t . -N AMC_PICO_VERSION $(PWD)/amc_pico_version.h

test/picodefs.py: gen_py
	./$< $@


.PHONY: all modules modules_install clean


endif


