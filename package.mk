
# overridable parameters

PREFIX?=/usr/local

EXE?=${NAME}

LIB?=lib${NAME}.a

PROG?=$(wildcard main.c)
TEST?=$(wildcard test.c)
HDRS?=$(wildcard ${NAME}*.h)
SRCS?=$(wildcard ${NAME}*.c)

LANGUAGE?=-std=c11 -pedantic -Wall -Wextra
DEBUG?=-g
OPTIMIZE?=-O2
DEFINES?=
INCLUDES?=-I.

################################################################################

CFLAGS?=${LANGUAGE} ${DEBUG} ${OPTIMIZE} ${DEFINES} ${INCLUDES}
CPPFLAGS?=${LANGUAGE} ${DEFINES} ${INCLUDES}

OBJS=$(SRCS:.c=.o)

ALLTGTS=$(if ${PROG},${EXE}) $(if ${SRCS},${LIB}) $(if ${TEST},test)
ALLSRCS=$(if ${PROG},${PROG}) $(if ${SRCS},${SRCS}) $(if ${TEST},${TEST})
ALLOBJS=$(ALLSRCS:.c=.o)
ALLDEPS=$(ALLSRCS:.c=.d)

# define default target first
default: all

# include/update dependencies
-include ${ALLDEPS}

# main target
all: ${ALLTGTS}

# rule for the program
ifneq (${EXE},)
${EXE}: ${PROG} ${LIB}
	${CC} ${CFLAGS} -o $@ $^
endif

# rule for the library
ifneq (${LIB},)
${LIB}: ${OBJS}
	rm -f $@ && ${AR} -crs $@ $^
	size $@
endif

# rules for the test
ifneq (${TEST},)
check: test
	./test
.PHONY: check

test: ${TEST} ${LIB}
	${CC} ${CFLAGS} -DTEST -o $@ $^
endif

# generate dependencies
%.d: %.c
	@echo updating $@
	@set -e; rm -f $@; \
	${CC} -M ${CPPFLAGS} $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

# package install
install: all
ifneq (${PROG},)
	mkdir -p ${PREFIX}/bin
	install ${BIN} ${PREFIX}/bin
endif
ifneq (${SRCS},)
	mkdir -p ${PREFIX}/lib
	install ${LIB} ${PREFIX}/lib
endif
ifneq (${HDRS},)
	mkdir -p ${PREFIX}/include
	install -t ${PREFIX}/include ${HDRS}
endif
.PHONY: install

# package uninstall
uninstall:
ifneq (${PROG},)
	rm -f ${PREFIX}/bin/${EXE}
endif
ifneq (${SRCS},)
	rm -f ${PREFIX}/lib/${LIB}
endif
ifneq (${HDRS},)
	for f in ${HDRS}; do rm -f ${PREFIX}/include/$$f; done
endif
.PHONY: uninstall

# source cleanup
clean:
	rm -f ${ALLOBJS} ${ALLDEPS} ${LIB} ${EXE} test
.PHONY: clean
