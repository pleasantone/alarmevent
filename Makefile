#
# Initial Makefile for installation
#
# Honestly, this really shouldn't be used, it's just documentation at this
# point for where things belong, and permisison settings.
#
# Move/merge/diff by hand
#

DISTDIR=/tmp

BINDIR=${DISTDIR}/usr/local/sbin
BINDIRMODE=-o root -g staff -m 4755

ETCDIR=${DISTDIR}/etc/alarmevent
ETCDIRMODE=-o root -g asterisk -m 750

ASTDIR=${DISTDIR}/etc/asterisk
ASTDIRMODE=-o asterisk -g asterisk -m 755

SPOOLDIR=${DISTDIR}/var/spool/asterisk/alarm
SPOOLDIRMODE=-o asterisk -g asterisk -m 750

ETCFILES=accounts.yaml.dist config.ini.dist
ETCMODE=-o root -g asterisk -m 640

ASTFILES=alarmreceiver.conf.dist
ASTMODE=-o asterisk -g asterisk -m 640

BINFILES=alarmevent
BINMODE=-o root -g asterisk -m 755

install:
	test -d ${ETCDIR} || install -d ${ETCDIR} ${ETCDIRMODE}
	for file in ${ETCFILES}; do \
		install -c ${ETCMODE} $$file ${ETCDIR}/ ; \
		destname=${ETCDIR}/`basename $$file .dist` ; \
		test -f $$destname || install -c ${ETCMODE} $$file $$destname ;\
	done
	test -d ${ASTDIR} || install -d ${ASTDIR} ${ASTDIRMODE}
	for file in ${ASTFILES}; do \
		install -c ${ASTMODE} $$file ${ASTDIR}/ ; \
		destname=${ASTDIR}/`basename $$file .dist` ; \
		test -f $$destname || install -c ${ASTMODE} $$file $$destname ;\
	done
	test -d ${BINDIR} || install -d ${BINDIR} ${BINDIRMODE}
	for file in ${BINFILES}; do \
		install -c ${BINMODE} $$file ${BINDIR}/ ; \
	done
	test -d ${SPOOLDIR} || install -d ${SPOOLDIR} ${SPOOLDIRMODE}
