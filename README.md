# Operator SDK Makefiles
Makifiles for Operator SDK operators:
- put them in ``hack/mk/`
- rename operator sdk `Makefile` to `Makefile-dist.mk`
- define a new `Makefile`. Ex:
```makefile
OPERATOR_SHORTNAME ?= kio
VERSION ?= 0.0.2
OPERATOR_TYPE ?= go

include hack/mk/main.mk
```
