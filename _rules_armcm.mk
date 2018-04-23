#
# Copyright (c) 2014 Zubax, zubax.com
# Distributed under the MIT License, available in the file LICENSE.
# Author: Pavel Kirienko <pavel.kirienko@zubax.com>
#

ZUBAX_CHIBIOS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

CPPSRC += $(ZUBAX_CHIBIOS_DIR)/zubax_chibios/sys/libstdcpp.cpp                  \
          $(ZUBAX_CHIBIOS_DIR)/zubax_chibios/sys/sys_console.cpp                \
          $(ZUBAX_CHIBIOS_DIR)/zubax_chibios/sys/sys.cpp

UINCDIR += $(ZUBAX_CHIBIOS_DIR)

UDEFS +=

#
# Optional components
#

BUILD_CONFIG ?= 0
ifneq ($(BUILD_CONFIG),0)
    CPPSRC += $(ZUBAX_CHIBIOS_DIR)/zubax_chibios/config/config.cpp
endif

#
# OS configuration
#

ifndef SERIAL_CLI_PORT_NUMBER
    $(error SERIAL_CLI_PORT_NUMBER must be assigned an integer value greater than zero)
endif

ifndef USE_PROCESS_STACKSIZE
    $(error USE_PROCESS_STACKSIZE is not defined)
endif

ifndef USE_EXCEPTIONS_STACKSIZE
    $(error USE_EXCEPTIONS_STACKSIZE is not defined)
endif

UDEFS += -DSTDOUT_SD=SD$(SERIAL_CLI_PORT_NUMBER) -DSTDIN_SD=STDOUT_SD -DSERIAL_CLI_PORT_NUMBER=$(SERIAL_CLI_PORT_NUMBER)

UDEFS += -DCORTEX_ENABLE_WFI_IDLE=1

USE_LINK_GC = yes
USE_THUMB ?= yes
USE_VERBOSE_COMPILE ?= no
USE_SMART_BUILD ?= no

CHIBIOS := $(ZUBAX_CHIBIOS_DIR)/chibios
include $(CHIBIOS)/os/hal/hal.mk
include $(CHIBIOS)/os/rt/rt.mk
include $(CHIBIOS)/os/hal/osal/rt/osal.mk
include $(CHIBIOS)/os/various/cpp_wrappers/chcpp.mk
include $(CHIBIOS)/os/hal/lib/streams/streams.mk

VARIOUSSRC = $(STREAMSSRC) \
             $(CHIBIOS)/os/various/syscalls.c

VARIOUSINC = $(STREAMSINC)

CSRC += $(STARTUPSRC) $(KERNSRC) $(PORTSRC) $(OSALSRC) $(HALSRC) $(PLATFORMSRC) $(VARIOUSSRC)

CPPSRC += $(CHCPPSRC)

ASMXSRC += $(STARTUPASM) $(PORTASM) $(OSALASM)

INCDIR += $(PORTINC) $(KERNINC) $(HALINC) $(PLATFORMINC) $(CHCPPINC) $(STARTUPINC) $(OSALINC) $(VARIOUSINC) \
          $(CHIBIOS)/os/various \
          $(CHIBIOS)/os/license

#
# OS optional components
#

BUILD_CHIBIOS_SHELL ?= 0
ifneq ($(BUILD_CHIBIOS_SHELL),0)
	include $(CHIBIOS)/os/various/shell/shell.mk
    VARIOUSSRC += $(SHELLSRC)
    VARIOUSINC += $(SHELLINC)
endif

#
# Build configuration
#

NO_BUILTIN += -fno-builtin-printf -fno-builtin-fprintf  -fno-builtin-vprintf -fno-builtin-vfprintf -fno-builtin-puts

USE_OPT += -falign-functions=16 -U__STRICT_ANSI__ -fno-exceptions -fno-unwind-tables -fno-stack-protector \
           $(NO_BUILTIN)

# Explicit usage flags are needed for LTO:
USE_OPT += -u_port_lock -u_port_unlock -u_exit -u_kill -u_getpid -uchThdExit -u__errno

# Fixing float constants - otherwise the C++ standard library may fail to compile:
UDEFS += -fno-single-precision-constant

# Unfortunately, we have to allow the use of the deprecated "register" keyword, because it is used in the
# sources of the operating system.
# TODO: Compile the operating system as a static library!
USE_COPT += -std=c99
USE_CPPOPT += -std=c++17 -fno-rtti -fno-exceptions -fno-threadsafe-statics -Wno-error=register -Wno-register

USE_OPT += -nodefaultlibs -lc -lgcc -lm

RELEASE ?= 0
RELEASE_OPT ?= -O1 -fomit-frame-pointer
DEBUG_OPT ?= -O1 -g3
ifneq ($(RELEASE),0)
    DDEFS += -DRELEASE_BUILD=1 -DNDEBUG=1
    DADEFS += -DRELEASE_BUILD=1 -DNDEBUG=1
    USE_OPT += $(RELEASE_OPT)
else
    DDEFS += -DDEBUG_BUILD=1
    DADEFS += -DDEBUG_BUILD=1
    USE_OPT += $(DEBUG_OPT)
endif

#
# Compiler options
#

TOOLCHAIN_PREFIX ?= arm-none-eabi
CC   = $(TOOLCHAIN_PREFIX)-gcc
CPPC = $(TOOLCHAIN_PREFIX)-g++
LD   = $(TOOLCHAIN_PREFIX)-g++
CP   = $(TOOLCHAIN_PREFIX)-objcopy
AS   = $(TOOLCHAIN_PREFIX)-gcc -x assembler-with-cpp
OD   = $(TOOLCHAIN_PREFIX)-objdump
SZ   = $(TOOLCHAIN_PREFIX)-size
HEX  = $(CP) -O ihex
BIN  = $(CP) -O binary

# ARM-specific options here
AOPT +=

# THUMB-specific options here
TOPT ?= -mthumb -DTHUMB=1

CWARN += -Wall -Wextra -Wstrict-prototypes
CPPWARN += -Wundef -Wall -Wextra -Werror

# asm statement fix
DDEFS += -Dasm=__asm

include $(CHIBIOS)/os/common/startup/ARMCMx/compilers/GCC/rules.mk
