-include sdk.mk

export NO_SDK_LEGAL := true

## FIXME
## DON'T FORGET TO UPDATE
## org.argeo.tp.build/*/bnd.bnd
## WITH THE UPDATED ECJ AND OSGi VERSIONS!
## 

## A Java 17 JDK MUST be used because BND is not compatible with Java 21 (SortedList issue)
## TODO check automatically

ECLIPSE_RELEASE=4.33
ECLIPSE_DROP=R-$(ECLIPSE_RELEASE)-202409030240

#ECJ_JAVA_HOME=/usr/lib/jvm/java-21-openj9-amd64
# Note: if Java 21 is used the ECJ sources have to be patched with  
# patch -p0 < ecj-java-21-compatibility.patch (see prepare-sources target)
# For the time being we use the default Java which MUST be Java 17 (otherwise bndlib doesn't build anyhow)
ECJ_JAVA_HOME=$(JAVA_HOME)

BND_VERSION=7.0.0
OSGI_CORE_VERSION=7.0.0
OSGI_CMPN_VERSION=7.0.0
OSGI_ANNOTATION_VERSION=8.1.0
SLF4J_VERSION=2.0.16

JAVA_SOURCE=17
JAVA_TARGET=17

A2_CATEGORY_BUILD = org.argeo.tp.build
A2_CATEGORY_LOG = log/syslogger/org.argeo.tp

# required when preparing sources for debuild,
# since no sdk.mk should be present otherwise it would be packed as well
SDK_SRC_BASE ?=$(shell pwd)
SDK_BUILD_BASE ?=$(shell pwd)/output
-include $(SDK_SRC_BASE)/branch.mk
-include $(SDK_SRC_BASE)/sdk/branches/$(BRANCH).bnd

# base for all intermediate actions
BOOTSTRAP_BASE=$(SDK_BUILD_BASE)/bootstrap
# downloaded artifacts
ORIGIN_BASE=$(HOME)/.cache/argeo/build/origin/bootstrap
# base for local sources only used by compilation (but not packaged)
LIB_BASE=$(SDK_SRC_BASE)/lib
LIB_JAVA_COMPILER=$(LIB_BASE)/java.compiler

# Where Argeo Build builds the bundles the usual way (used for clean)
BUILD_BASE = $(SDK_BUILD_BASE)/$(shell basename $(SDK_SRC_BASE))

# ECJ sources, used for both intermediate and final build
ECJ_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_BUILD)/org.eclipse.jdt.core.compiler.batch/src
ECJ_SRC_META_INF=$(abspath $(ECJ_SRC)/../META-INF)
# compiled ECJ, used for intermediate build
ECJ_BIN=$(BOOTSTRAP_BASE)/ecj

# logging APIs sources, used for both intermediate and final build
SYSLOGGER_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_LOG)/org.argeo.tp.syslogger/src
# compiled logging APIs, used for intermediate build
SYSLOGGER_BIN=$(BOOTSTRAP_BASE)/slf4j

# BNDLIB sources, used for both intermediate and final build
BNDLIB_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_BUILD)/biz.aQute.bndlib/src
# compiled BNDLIB, used for intermediate build
BNDLIB_BIN=$(BOOTSTRAP_BASE)/bndlib

# OSGi annotation sources, used for both intermediate and final build
OSGI_ANNOTATION_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_BUILD)/osgi.annotation/src
# compiled OSGi annotation, used for intermediate build
OSGI_ANNOTATION_BIN=$(BOOTSTRAP_BASE)/osgi-annotation

# intermediate directory to unpack SLF4J sources
SLF4J_BASE=$(BOOTSTRAP_BASE)/slf4j-src
# intermediate directory to unpack OSGi sources
OSGI_BASE=$(BOOTSTRAP_BASE)/osgi-src


SOURCE_ARCHIVES=\
$(ORIGIN_BASE)/ecjsrc-$(ECLIPSE_RELEASE).jar \
$(ORIGIN_BASE)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar \
$(ORIGIN_BASE)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar \
$(ORIGIN_BASE)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar \
$(ORIGIN_BASE)/slf4j-api-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/log4j-over-slf4j-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz

# scripts
JVM ?= $(ECJ_JAVA_HOME)/bin/java
JAVAC ?= $(ECJ_JAVA_HOME)/bin/javac

JAVAC_INTERMEDIATE ?= $(JAVAC) -source $(JAVA_SOURCE) -target $(JAVA_TARGET)
ECJ_INTERMEDIATE=org.eclipse.jdt.internal.compiler.batch.Main -source $(JAVA_SOURCE) -target $(JAVA_TARGET) -nowarn 

ARGEO_MAKE := $(JVM) -cp $(ECJ_BIN):$(SYSLOGGER_BIN):$(OSGI_ANNOTATION_BIN):$(BNDLIB_BIN) \
 $(SDK_SRC_BASE)/sdk/argeo-build/src/org/argeo/build/Make.java

ARGEO_MAKE_ECJ := $(ECJ_JAVA_HOME)/bin/java -cp $(ECJ_BIN):$(SYSLOGGER_BIN):$(OSGI_ANNOTATION_BIN):$(BNDLIB_BIN) \
 $(SDK_SRC_BASE)/sdk/argeo-build/src/org/argeo/build/Make.java

# GNU coding standards
prefix ?= /usr/local
datarootdir ?= $(prefix)/share
A2_INSTALL_TARGET ?= $(DESTDIR)$(datarootdir)/a2

# dist
# PACKAGER must be specified
PACKAGER?=
DIST_NAME=argeo-tp-bootstrap
DEB_CHANGELOG=$(SDK_SRC_BASE)/debian/changelog
RPMBUILD_BASE?=$(HOME)/rpmbuild
RPM_DIST=

COPY=cp --reflink=auto

## GENERIC TARGETS
all: osgi

clean:
	-find $(LIB_BASE) -name "*.class" -type f -delete
	-find $(LIB_BASE) -name "*.todo" -type f -delete
	-find $(BOOTSTRAP_BASE) -name "*.todo" -type f -delete
	$(RM) -rf $(BUILD_BASE)
	$(RM) -rf $(ECJ_BIN)
	$(RM) -rf $(SYSLOGGER_BIN)
	$(RM) -rf $(OSGI_ANNOTATION_BIN)
	$(RM) -rf $(BNDLIB_BIN)

distclean:
	$(RM) -f sdk.mk
	$(RM) -rf $(BOOTSTRAP_BASE)
# make sure debuild won't package output
	$(RM) -rf ./output

local-install:
	mkdir -p $(A2_INSTALL_TARGET)
	$(COPY) -Rv $(SDK_BUILD_BASE)/a2/log $(A2_INSTALL_TARGET)
	$(COPY) -Rv $(SDK_BUILD_BASE)/a2/org.argeo.tp.build $(A2_INSTALL_TARGET)
	if [ -d $(SDK_BUILD_BASE)/a2.src ]; then $(COPY) -Rv $(SDK_BUILD_BASE)/a2.src/log $(A2_INSTALL_TARGET); fi;
	if [ -d $(SDK_BUILD_BASE)/a2.src ]; then $(COPY) -Rv $(SDK_BUILD_BASE)/a2.src/org.argeo.tp.build $(A2_INSTALL_TARGET); fi;
	cd $(A2_INSTALL_TARGET)/log && ln -f -s syslogger default 

local-uninstall:
	$(RM) $(A2_INSTALL_TARGET)/log/default
	$(RM) -r $(A2_INSTALL_TARGET)/log/syslogger
	$(RM) -r $(A2_INSTALL_TARGET)/org.argeo.tp.build
	@if [ -d $(A2_INSTALL_TARGET) ]; then find $(A2_INSTALL_TARGET) -empty -type d -delete; fi

## ARGEO STANDARD BUILD
osgi: build-ecj build-syslogger build-osgi-annotation build-bndlib
	cd $(A2_CATEGORY_LOG) && $(ARGEO_MAKE) all --category $(A2_CATEGORY_LOG) \
	--bundles org.argeo.tp.syslogger
	
# We reuse ECJ the classes already compiled by javac
# TODO find a way to rebuild with ECJ with overriding the java.compiler module
	mkdir -p $(SDK_BUILD_BASE)/argeo-tp-bootstrap/org.eclipse.jdt.core.compiler.batch/bin
	cd $(ECJ_BIN) && find . -name '*.class' -exec cp --parents \{\} $(SDK_BUILD_BASE)/argeo-tp-bootstrap/org.eclipse.jdt.core.compiler.batch/bin \;
	cd $(A2_CATEGORY_BUILD) && $(ARGEO_MAKE_ECJ) bundle --category $(A2_CATEGORY_BUILD) \
	--bundles org.eclipse.jdt.core.compiler.batch
	
	cd $(A2_CATEGORY_BUILD) && $(ARGEO_MAKE) all --category $(A2_CATEGORY_BUILD) \
	--bundles osgi.annotation biz.aQute.bndlib
# copy ECJ MANIFEST in order to debug
#mkdir -p $(ECJ_SRC_META_INF)
#cp $(SDK_BUILD_BASE)/argeo-tp-bootstrap/org.eclipse.jdt.core.compiler.batch/META-INF/MANIFEST.MF $(ECJ_SRC_META_INF)

## INTERMEDIATE BUILDS
build-lib:
	# ECJ require the javax.* packages from the java.compiler module of Java 21
	find lib/java.compiler | grep "\.java$$" > lib/java.compiler.todo
	$(JAVAC_INTERMEDIATE) -d lib/java.compiler @lib/java.compiler.todo

build-ecj: build-lib
	mkdir -p $(ECJ_BIN)
# copy resources (message bundles, files required by the compiler, etc.)
# (java files will be copied too, but they are irrelevant here)
	cp -r $(ECJ_SRC)/org $(ECJ_BIN)
	find $(ECJ_SRC) | grep "\.java$$" > $(BOOTSTRAP_BASE)/ecj.todo
	$(JAVAC_INTERMEDIATE) --upgrade-module-path $(LIB_JAVA_COMPILER) -d $(ECJ_BIN) -Xlint:none @$(BOOTSTRAP_BASE)/ecj.todo
	
build-syslogger: build-ecj
	$(JVM) -cp $(ECJ_BIN) $(ECJ_INTERMEDIATE) $(SYSLOGGER_SRC) -d $(SYSLOGGER_BIN)

build-osgi-annotation: build-ecj
	$(JVM) -cp $(ECJ_BIN) $(ECJ_INTERMEDIATE) $(OSGI_ANNOTATION_SRC) -d $(OSGI_ANNOTATION_BIN)

build-bndlib: build-ecj build-syslogger build-osgi-annotation
	# We copy everything (including .java files) because we need the many resource files
	mkdir $(BNDLIB_BIN)
	cp -r $(BNDLIB_SRC)/* $(BNDLIB_BIN)
	$(JVM) -cp $(ECJ_BIN):$(SYSLOGGER_BIN):$(OSGI_ANNOTATION_BIN) $(ECJ_INTERMEDIATE) $(BNDLIB_BIN) -d $(BNDLIB_BIN)

## SOURCES PREPARATION	
prepare-sources: clean-sources download-sources
	##
	## ECJ
	##
	mkdir -p $(ECJ_SRC)
	cd $(ECJ_SRC) && jar -xf $(ORIGIN_BASE)/ecjsrc-$(ECLIPSE_RELEASE).jar
# remove ant-dependent class
	$(RM) $(ECJ_SRC)/org/eclipse/jdt/core/JDTCompilerAdapter.java
# apply patches
	#patch -p0 < ecj-java-21-compatibility.patch
# clean up
	$(RM) $(ECJ_SRC)/*.jar
	$(RM) $(ECJ_SRC)/build.xml
	$(RM) $(ECJ_SRC)/ecj.1
	$(RM) -rf $(ECJ_SRC)/scripts
# TODO: keep the service files
	$(RM) -rf  $(ECJ_SRC)/META-INF
	
	##
	## BNDLIB
	##
# copy sources
	mkdir -p $(BOOTSTRAP_BASE)
	cd $(BOOTSTRAP_BASE) && tar -xzf $(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz
	mkdir -p $(BNDLIB_SRC)
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION)/aQute.libg/src/* $(BNDLIB_SRC)
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION)/biz.aQute.bndlib/src/* $(BNDLIB_SRC)
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION)/biz.aQute.bnd.annotation/src/* $(BNDLIB_SRC)	
	cp -r $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION)/biz.aQute.bnd.util/src/* $(BNDLIB_SRC)	
	$(RM) -rf $(BOOTSTRAP_BASE)/bnd-$(BND_VERSION)

# clean up BNDLIB
#	$(RM) -rf $(BNDLIB_SRC)/aQute/bnd/annotation/spi
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
	cp -r $(OSGI_BASE)/org/osgi/service/serviceloader $(BNDLIB_SRC)/org/osgi/service
	cp -r $(OSGI_BASE)/org/osgi/service/log $(BNDLIB_SRC)/org/osgi/service

	## OSGI ANNOTATION
	mkdir -p $(OSGI_ANNOTATION_SRC)
	cd $(OSGI_ANNOTATION_SRC) && jar -xf $(ORIGIN_BASE)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar
	$(RM) -rf $(OSGI_ANNOTATION_SRC)/META-INF

	##
	## SLF4J
	##
	mkdir -p $(SLF4J_BASE)
	cd $(SLF4J_BASE) && jar -xf $(ORIGIN_BASE)/slf4j-api-$(SLF4J_VERSION)-sources.jar
	cd $(SLF4J_BASE) && jar -xf $(ORIGIN_BASE)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar
	cd $(SLF4J_BASE) && jar -xf $(ORIGIN_BASE)/log4j-over-slf4j-$(SLF4J_VERSION)-sources.jar
	$(RM) -rf $(SLF4J_BASE)/META-INF
	$(RM) -rf $(SLF4J_BASE)/org/slf4j/impl
	cp -r $(SLF4J_BASE)/org $(SYSLOGGER_SRC)
	
	# Debian changelog
	echo "$(DIST_NAME) ($(major).$(minor).$(micro)+$(ECLIPSE_RELEASE)) $(BRANCH); urgency=medium" > $(DEB_CHANGELOG)
	echo >> $(DEB_CHANGELOG)
	echo "  * Based on Eclipse ECJ release $(ECLIPSE_RELEASE)" >> $(DEB_CHANGELOG)
	echo >> $(DEB_CHANGELOG)
	echo " -- $(PACKAGER)  $(shell date -u -R)">> $(DEB_CHANGELOG)	

clean-sources:
	$(RM) -rf $(ECJ_SRC)/*
	$(RM) -rf $(ECJ_SRC_META_INF)
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
	$(RM) -rf $(DEB_CHANGELOG)

## DIST
rpm-sources: prepare-sources
	mkdir -p $(RPMBUILD_BASE)/SOURCES
	mkdir -p $(RPMBUILD_BASE)/SPECS
#	 --transform 's,^,$(DIST_NAME)-$(major).$(minor).$(micro)/,' 
	cd $(SDK_SRC_BASE) && tar --exclude='output' --exclude-vcs \
	  -cJf $(RPMBUILD_BASE)/SOURCES/$(DIST_NAME)_$(major).$(minor).$(micro).tar.xz .
	echo "Version: $(major).$(minor).$(micro)" > $(RPMBUILD_BASE)/SPECS/$(DIST_NAME).spec
	cat $(SDK_SRC_BASE)/$(DIST_NAME).spec >> $(RPMBUILD_BASE)/SPECS/$(DIST_NAME).spec
	rpmbuild -bs $(RPMBUILD_BASE)/SPECS/$(DIST_NAME).spec

rpm-build:
	mkdir -p $(RPMBUILD_BASE)/SOURCES
	mkdir -p $(RPMBUILD_BASE)/SPECS
	echo "Version: $(major).$(minor).$(micro)+$(ECLIPSE_RELEASE)" > $(RPMBUILD_BASE)/SPECS/$(DIST_NAME).spec
	cat $(SDK_SRC_BASE)/$(DIST_NAME).spec >> $(RPMBUILD_BASE)/SPECS/$(DIST_NAME).spec
	rpmbuild --clean --rmsource --nodeps \
	 --define "_topdir $(RPMBUILD_BASE)" --define "dist $(RPM_DIST)" \
	 -ba $(RPMBUILD_BASE)/SPECS/$(DIST_NAME).spec

deb-source: distclean clean-sources prepare-sources
	debuild --no-sign -S
	$(RM) -f debian/files

## SOURCES ORIGIN
download-sources: $(SOURCE_ARCHIVES)

$(ORIGIN_BASE)/ecjsrc-$(ECLIPSE_RELEASE).jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/ecjsrc-$(ECLIPSE_RELEASE).jar https://ftp-stud.hs-esslingen.de/Mirrors/eclipse/eclipse/downloads/drops4/$(ECLIPSE_DROP)/ecjsrc-$(ECLIPSE_RELEASE).jar
	
$(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz https://github.com/bndtools/bnd/archive/refs/tags/$(BND_VERSION).tar.gz

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

$(ORIGIN_BASE)/log4j-over-slf4j-$(SLF4J_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/log4j-over-slf4j-$(SLF4J_VERSION)-sources.jar https://repo1.maven.org/maven2/org/slf4j/log4j-over-slf4j/$(SLF4J_VERSION)/log4j-over-slf4j-$(SLF4J_VERSION)-sources.jar

.PHONY=all clean distclean osgi download-sources deb-source clean-sources prepare-sources build-ecj build-syslogger build-osgi-annotation build-bndlib
