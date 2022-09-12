# frp
FRP_SUBDOMAIN ?= $(shell echo kio-web-app$${HOSTNAME:+-$${HOSTNAME%.*}})
FRPC_INI_SUBDOMAIN_INFO ?= $(FRP_SUBDOMAIN)
FRPC_INI_VAULT_KEY ?= .frpc-fe.ini
