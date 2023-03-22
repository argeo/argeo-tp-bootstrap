-include sdk.mk

export NO_SDK_LEGAL := true

ECJ_VERSION=4.27

BND_VERSION=5.3.0
OSGI_CORE_VERSION=7.0.0
OSGI_CMPN_VERSION=7.0.0
OSGI_ANNOTATION_VERSION=7.0.0
SLF4J_VERSION=1.7.36

JAVA_SOURCE=17
JAVA_TARGET=17

A2_CATEGORY_SDK = org.argeo.tp.sdk
A2_CATEGORY_LOG = org.argeo.tp

# required when preparing sources for debuild,
# since no sdk.mk should be present otherwise it would be packed as well
SDK_SRC_BASE ?=$(shell pwd)
SDK_BUILD_BASE ?=$(shell pwd)/output

# base for all intermediate actions
BOOTSTRAP_BASE=$(SDK_BUILD_BASE)/bootstrap
# downloaded artifacts
ORIGIN_BASE=$(BOOTSTRAP_BASE)/origin

# ECJ sources, used for both intermediate and final build
ECJ_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_SDK)/org.eclipse.jdt.core.compiler.batch/src
# compiled ECJ, used for intermediate build
ECJ_BIN=$(BOOTSTRAP_BASE)/ecj

# logging APIs sources, used for both intermediate and final build
SYSLOGGER_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_LOG)/org.argeo.tp.syslogger/src
# compiled logging APIs, used for intermediate build
SYSLOGGER_BIN=$(BOOTSTRAP_BASE)/slf4j

# BNDLIB sources, used for both intermediate and final build
BNDLIB_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_SDK)/biz.aQute.bndlib/src
# compiled BNDLIB, used for intermediate build
BNDLIB_BIN=$(BOOTSTRAP_BASE)/bndlib

# OSGi annotation sources, used for both intermediate and final build
OSGI_ANNOTATION_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_SDK)/osgi.annotation/src
# compiled OSGi annotation, used for intermediate build
OSGI_ANNOTATION_BIN=$(BOOTSTRAP_BASE)/osgi-annotation

# intermediate directory to unpack SLF4J sources
SLF4J_BASE=$(BOOTSTRAP_BASE)/slf4j-src
# intermediate directory to unpack OSGi sources
OSGI_BASE=$(BOOTSTRAP_BASE)/osgi-src


SOURCE_ARCHIVES=\
$(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar \
$(ORIGIN_BASE)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar \
$(ORIGIN_BASE)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar \
$(ORIGIN_BASE)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar \
$(ORIGIN_BASE)/slf4j-api-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz

# scripts
JVM ?= $(JAVA_HOME)/bin/java
ECJ_INTERMEDIATE=$(JVM) -cp $(ECJ_BIN):$(SYSLOGGER_BIN):$(OSGI_ANNOTATION_BIN) \
 org.eclipse.jdt.internal.compiler.batch.Main \
 -source $(JAVA_SOURCE) -target $(JAVA_TARGET) -nowarn 

ARGEO_MAKE := $(JVM) -cp $(ECJ_BIN):$(SYSLOGGER_BIN):$(OSGI_ANNOTATION_BIN):$(BNDLIB_BIN) \
 $(SDK_SRC_BASE)/sdk/argeo-build/src/org/argeo/build/Make.java

## GENERIC TARGETS
all: osgi

clean:
	$(RM) -rf $(ECJ_BIN)
	$(RM) -rf $(SYSLOGGER_BIN)
	$(RM) -rf $(OSGI_ANNOTATION_BIN)
	$(RM) -rf $(BNDLIB_BIN)

distclean:
	$(RM) -f sdk.mk
	$(RM) -rf $(BOOTSTRAP_BASE)
# make sure debuild won't package output
	$(RM) -rf ./output

## ARGEO STANDARD BUILD
osgi: build-ecj build-syslogger build-osgi-annotation build-bndlib
	cd $(A2_CATEGORY_LOG) && $(ARGEO_MAKE) all --category $(A2_CATEGORY_LOG) \
	--bundles org.argeo.tp.syslogger
	cd $(A2_CATEGORY_SDK) && $(ARGEO_MAKE) all --category $(A2_CATEGORY_SDK) \
	--bundles org.eclipse.jdt.core.compiler.batch osgi.annotation biz.aQute.bndlib

## INTERMEDIATE BUILDS
build-ecj:
	mkdir -p $(ECJ_BIN)
# copy resources (message bundles, files required by the compiler, etc.)
# (java files will be copied too, but they are irrelevant here)
	cp -r $(ECJ_SRC)/org $(ECJ_BIN)
	find $(ECJ_SRC) | grep "\.java" > $(BOOTSTRAP_BASE)/ecj.todo
	$(JAVA_HOME)/bin/javac -d $(ECJ_BIN) -source $(JAVA_SOURCE) -target $(JAVA_TARGET) -Xlint:none @$(BOOTSTRAP_BASE)/ecj.todo
	
build-syslogger: build-ecj
	$(ECJ_INTERMEDIATE)	$(SYSLOGGER_SRC) -d $(SYSLOGGER_BIN)

build-osgi-annotation: build-ecj
	$(ECJ_INTERMEDIATE)	$(OSGI_ANNOTATION_SRC) -d $(OSGI_ANNOTATION_BIN)

build-bndlib: build-ecj build-syslogger build-osgi-annotation
	$(ECJ_INTERMEDIATE) $(BNDLIB_SRC) -d $(BNDLIB_BIN)

## SOURCES PREPARATION	
prepare-sources: clean-sources download-sources
	## ECJ
	mkdir -p $(ECJ_SRC)
	cd $(ECJ_SRC) && jar -xf $(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar
# remove ant-dependent class
	$(RM) $(ECJ_SRC)/org/eclipse/jdt/core/JDTCompilerAdapter.java
# clean up
	$(RM) $(ECJ_SRC)/*.jar
	$(RM) $(ECJ_SRC)/build.xml
	$(RM) $(ECJ_SRC)/ecj.1
	$(RM) -rf $(ECJ_SRC)/scripts
# TODO: keep the service files
	$(RM) -rf  $(ECJ_SRC)/META-INF
	
	## BNDLIB
# copy sources
	mkdir -p $(BOOTSTRAP_BASE)
	cd $(BOOTSTRAP_BASE) && tar -xzf $(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz
	mkdir -p $(BNDLIB_SRC)
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION).REL/aQute.libg/src/* $(BNDLIB_SRC)
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION).REL/biz.aQute.bndlib/src/* $(BNDLIB_SRC)
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION).REL/biz.aQute.bnd.annotation/src/* $(BNDLIB_SRC)	
	$(RM) -rf $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION).REL

# clean up BNDLIB
	$(RM) -rf $(BNDLIB_SRC)/aQute/bnd/annotation/spi
	$(RM) -rf $(BNDLIB_SRC)/aQute/bnd/junit

# copy some OSGi packages to BNDLIB
	mkdir -p $(OSGI_BASE)
	cd $(OSGI_BASE) && jar -xf $(ORIGIN_BASE)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar
	cd $(OSGI_BASE) && jar -xf $(ORIGIN_BASE)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar
	
	mkdir -p $(BNDLIB_SRC)/org/osgi/service
	cp -r $(OSGI_BASE)/org/osgi/resource $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/framework $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/namespace $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/util $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/dto $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/service/repository $(BNDLIB_SRC)/org/osgi/service
	cp -r $(OSGI_BASE)/org/osgi/service/log $(BNDLIB_SRC)/org/osgi/service

	## OSGI ANNOTATION
	cd $(OSGI_ANNOTATION_SRC) && jar -xf $(ORIGIN_BASE)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar
	$(RM) -rf $(OSGI_ANNOTATION_SRC)/META-INF

	## SLF4J
	mkdir -p $(SLF4J_BASE)
	cd $(SLF4J_BASE) && jar -xf $(ORIGIN_BASE)/slf4j-api-$(SLF4J_VERSION)-sources.jar
	cd $(SLF4J_BASE) && jar -xf $(ORIGIN_BASE)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar
	$(RM) -rf $(SLF4J_BASE)/META-INF
	$(RM) -rf $(SLF4J_BASE)/org/slf4j/impl
	cp -r $(SLF4J_BASE)/org $(SYSLOGGER_SRC)

clean-sources:
	$(RM) -rf $(ECJ_SRC)/*
	$(RM) -rf $(BNDLIB_SRC)/*
	$(RM) -rf $(OSGI_ANNOTATION_SRC)/*
	$(RM) -rf $(OSGI_BASE)
	$(RM) -rf $(SLF4J_BASE)
	$(RM) -f $(SYSLOGGER_SRC)/org/slf4j/*.java
	$(RM) -f $(SYSLOGGER_SRC)/org/slf4j/*.html
	$(RM) -rf $(SYSLOGGER_SRC)/org/slf4j/event
	$(RM) -rf $(SYSLOGGER_SRC)/org/slf4j/helpers
	$(RM) -rf $(SYSLOGGER_SRC)/org/slf4j/spi
	$(RM) -rf $(SYSLOGGER_SRC)/org/apache

## DEBIAN
deb-source: distclean clean-sources bootstrap-prepare-sources
	debuild --no-sign -S
	$(RM) -f debian/files

## SOURCES ORIGIN
download-sources: $(SOURCE_ARCHIVES)

$(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar https://ftp-stud.hs-esslingen.de/Mirrors/eclipse/eclipse/downloads/drops4/R-4.26-202211231800/ecjsrc-$(ECJ_VERSION).jar
	
$(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz https://github.com/bndtools/bnd/archive/refs/tags/$(BND_VERSION).REL.tar.gz

$(ORIGIN_BASE)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar https://repo1.maven.org/maven2/org/osgi/osgi.core/$(OSGI_CORE_VERSION)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar

$(ORIGIN_BASE)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar https://repo1.maven.org/maven2/org/osgi/osgi.cmpn/$(OSGI_CMPN_VERSION)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar

$(ORIGIN_BASE)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar https://repo1.maven.org/maven2/org/osgi/osgi.annotation/$(OSGI_ANNOTATION_VERSION)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar

$(ORIGIN_BASE)/slf4j-api-$(SLF4J_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/slf4j-api-$(SLF4J_VERSION)-sources.jar https://repo1.maven.org/maven2/org/slf4j/slf4j-api/$(SLF4J_VERSION)/slf4j-api-$(SLF4J_VERSION)-sources.jar

$(ORIGIN_BASE)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar https://repo1.maven.org/maven2/org/slf4j/jcl-over-slf4j/$(SLF4J_VERSION)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar

.PHONY=all clean distclean osgi download-sources deb-source clean-sources prepare-sources build-ecj build-syslogger build-osgi-annotation build-bndlib
