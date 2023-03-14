-include sdk.mk

ECJ_VERSION=4.26

BND_VERSION=5.3.0
OSGI_CORE_VERSION=7.0.0
OSGI_CMPN_VERSION=7.0.0
OSGI_ANNOTATION_VERSION=7.0.0
SLF4J_VERSION=1.7.36

JAVA_SOURCE=17
JAVA_TARGET=17

A2_CATEGORY_SDK = org.argeo.tp.sdk
A2_CATEGORY_LOG = org.argeo.tp

BOOTSTRAP_BASE=$(SDK_BUILD_BASE)/bootstrap
ORIGIN_BASE=$(BOOTSTRAP_BASE)/origin

ECJ_BASE=$(BOOTSTRAP_BASE)/ecj
ECJ_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_SDK)/org.eclipse.jdt.core.compiler.batch/src

SLF4J_BASE=$(BOOTSTRAP_BASE)/slf4j
SLF4J_SRC=$(BOOTSTRAP_BASE)/slf4j-src
SYSLOGGER_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_LOG)/org.argeo.tp.syslogger/src

BNDLIB_BASE=$(BOOTSTRAP_BASE)/bndlib
BNDLIB_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_SDK)/biz.aQute.bndlib/src

OSGI_BASE=$(BOOTSTRAP_BASE)/osgi

OSGI_ANNOTATION_BASE=$(BOOTSTRAP_BASE)/osgi-annotation
OSGI_ANNOTATION_SRC=$(SDK_SRC_BASE)/$(A2_CATEGORY_SDK)/osgi.annotation/src

SOURCE_ARCHIVES=\
$(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar \
$(ORIGIN_BASE)/org.osgi/osgi.core-$(OSGI_CORE_VERSION)-sources.jar \
$(ORIGIN_BASE)/org.osgi/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar \
$(ORIGIN_BASE)/org.osgi/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar \
$(ORIGIN_BASE)/org.slf4j/slf4j-api-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/org.slf4j/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar \
$(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz

# Actions
JVM ?= $(JAVA_HOME)/bin/java
ECJ_INTERMEDIATE=$(JVM) -cp $(ECJ_BASE):$(SLF4J_BASE):$(OSGI_ANNOTATION_BASE) \
 org.eclipse.jdt.internal.compiler.batch.Main \
 -source $(JAVA_SOURCE) -target $(JAVA_TARGET) -nowarn 

ARGEO_MAKE := $(JVM) -cp $(ECJ_BASE):$(SLF4J_BASE):$(OSGI_ANNOTATION_BASE):$(BNDLIB_BASE) $(SDK_SRC_BASE)/sdk/argeo-build/src/org/argeo/build/Make.java

all: osgi

build-ecj:
	mkdir -p $(BOOTSTRAP_BASE)
	find $(ECJ_SRC) | grep "\.java" > $(BOOTSTRAP_BASE)/ecj.todo
	$(JAVA_HOME)/bin/javac -d $(ECJ_BASE) -source $(JAVA_SOURCE) -target $(JAVA_TARGET) -Xlint:none @$(BOOTSTRAP_BASE)/ecj.todo
	
build-slf4j: build-ecj
	$(ECJ_INTERMEDIATE)	$(SYSLOGGER_SRC) -d $(SLF4J_BASE)

build-osgi-annotation: build-ecj
	$(ECJ_INTERMEDIATE)	$(OSGI_ANNOTATION_BASE) -d $(OSGI_ANNOTATION_BASE)

build-bndlib: build-ecj build-slf4j build-osgi-annotation
	$(ECJ_INTERMEDIATE) $(BNDLIB_SRC) -d $(BNDLIB_BASE)

osgi: build-ecj build-slf4j build-osgi-annotation build-bndlib
	cd $(A2_CATEGORY_LOG) && $(ARGEO_MAKE) all --category $(A2_CATEGORY_LOG) \
	--bundles org.argeo.tp.syslogger
	cd $(A2_CATEGORY_SDK) && $(ARGEO_MAKE) all --category $(A2_CATEGORY_SDK) \
	--bundles org.eclipse.jdt.core.compiler.batch osgi.annotation biz.aQute.bndlib

clean:
	$(RM) -rf $(BOOTSTRAP_BASE)
	find $(ECJ_BASE) -name "*.class" -type f -exec rm -f {} \;
	find $(BNDLIB_BASE) -name "*.class" -type f -exec rm -f {} \;

distclean:
	$(RM) -f sdk.mk
	$(RM) -rf ./output

clean-sources:
	$(RM) -rf $(ECJ_BASE)
	$(RM) -rf $(ECJ_SRC)/*
	$(RM) -rf $(BNDLIB_BASE)
	$(RM) -rf $(BNDLIB_SRC)/*
	$(RM) -rf $(OSGI_BASE)
	$(RM) -rf $(OSGI_ANNOTATION_BASE)
	$(RM) -rf $(OSGI_ANNOTATION_SRC)/*
	$(RM) -rf $(SLF4J_BASE)
	$(RM) -rf $(SLF4J_SRC)
	$(RM) -f $(SYSLOGGER_SRC)/org/slf4j/*.java
	$(RM) -f $(SYSLOGGER_SRC)/org/slf4j/*.html
	$(RM) -rf $(SYSLOGGER_SRC)/org/slf4j/event
	$(RM) -rf $(SYSLOGGER_SRC)/org/slf4j/helpers
	$(RM) -rf $(SYSLOGGER_SRC)/org/slf4j/spi
	$(RM) -rf $(SYSLOGGER_SRC)/org/apache
	
deb-source: distclean clean-sources bootstrap-prepare-sources
	debuild --no-sign -S
	$(RM) -f debian/files

bootstrap-prepare-sources: clean-sources bootstrap-download-sources
	## ECJ
	mkdir -p $(ECJ_BASE)
	cd $(ECJ_BASE) && jar -xf $(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar
	# remove ant-dependent class
	$(RM) $(ECJ_BASE)/org/eclipse/jdt/core/JDTCompilerAdapter.java
	# clean up
	$(RM) $(ECJ_BASE)/*.jar
	$(RM) $(ECJ_BASE)/build.xml
	$(RM) $(ECJ_BASE)/ecj.1
	$(RM) -rf $(ECJ_BASE)/scripts
	# TODO: keep the service files
	$(RM) -rf  $(ECJ_BASE)/META-INF

	# copy sources and resources
	mkdir -p $(ECJ_SRC)
	cp -r $(ECJ_BASE)/org $(ECJ_SRC)
	
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

	# OSGi
	mkdir -p $(OSGI_BASE)
	cd $(OSGI_BASE) && jar -xf $(ORIGIN_BASE)/org.osgi/osgi.core-$(OSGI_CORE_VERSION)-sources.jar
	cd $(OSGI_BASE) && jar -xf $(ORIGIN_BASE)/org.osgi/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar
	
	mkdir -p $(BNDLIB_SRC)/org/osgi/service
	cp -r $(OSGI_BASE)/org/osgi/resource $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/framework $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/namespace $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/util $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/dto $(BNDLIB_SRC)/org/osgi
	cp -r $(OSGI_BASE)/org/osgi/service/repository $(BNDLIB_SRC)/org/osgi/service
	cp -r $(OSGI_BASE)/org/osgi/service/log $(BNDLIB_SRC)/org/osgi/service

	mkdir -p $(OSGI_ANNOTATION_BASE)
	cd $(OSGI_ANNOTATION_BASE) && jar -xf $(ORIGIN_BASE)/org.osgi/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar
	cp -r $(OSGI_ANNOTATION_BASE)/org $(OSGI_ANNOTATION_SRC)

	# SLF4J
	mkdir -p $(SLF4J_BASE)
	mkdir -p $(SLF4J_SRC)
	cd $(SLF4J_SRC) && jar -xf $(ORIGIN_BASE)/org.slf4j/slf4j-api-$(SLF4J_VERSION)-sources.jar
	cd $(SLF4J_SRC) && jar -xf $(ORIGIN_BASE)/org.slf4j/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar
	$(RM) -rf $(SLF4J_SRC)/META-INF
	$(RM) -rf $(SLF4J_SRC)/org/slf4j/impl
	cp -r $(SLF4J_SRC)/org $(SYSLOGGER_SRC)

bootstrap-download-sources: $(SOURCE_ARCHIVES)

$(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/ecjsrc-$(ECJ_VERSION).jar https://ftp-stud.hs-esslingen.de/Mirrors/eclipse/eclipse/downloads/drops4/R-4.26-202211231800/ecjsrc-$(ECJ_VERSION).jar
	
$(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz:
	mkdir -p $(ORIGIN_BASE)
	wget -c -O $(ORIGIN_BASE)/bnd-$(BND_VERSION).tar.gz https://github.com/bndtools/bnd/archive/refs/tags/$(BND_VERSION).REL.tar.gz

$(ORIGIN_BASE)/org.osgi/osgi.core-$(OSGI_CORE_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)/org.osgi
	wget -c -O $(ORIGIN_BASE)/org.osgi/osgi.core-$(OSGI_CORE_VERSION)-sources.jar https://repo1.maven.org/maven2/org/osgi/osgi.core/$(OSGI_CORE_VERSION)/osgi.core-$(OSGI_CORE_VERSION)-sources.jar

$(ORIGIN_BASE)/org.osgi/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)/org.osgi
	wget -c -O $(ORIGIN_BASE)/org.osgi/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar https://repo1.maven.org/maven2/org/osgi/osgi.cmpn/$(OSGI_CMPN_VERSION)/osgi.cmpn-$(OSGI_CMPN_VERSION)-sources.jar

$(ORIGIN_BASE)/org.osgi/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)/org.osgi
	wget -c -O $(ORIGIN_BASE)/org.osgi/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar https://repo1.maven.org/maven2/org/osgi/osgi.annotation/$(OSGI_ANNOTATION_VERSION)/osgi.annotation-$(OSGI_ANNOTATION_VERSION)-sources.jar

$(ORIGIN_BASE)/org.slf4j/slf4j-api-$(SLF4J_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)/org.slf4j
	wget -c -O $(ORIGIN_BASE)/org.slf4j/slf4j-api-$(SLF4J_VERSION)-sources.jar https://repo1.maven.org/maven2/org/slf4j/slf4j-api/$(SLF4J_VERSION)/slf4j-api-$(SLF4J_VERSION)-sources.jar

$(ORIGIN_BASE)/org.slf4j/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar:
	mkdir -p $(ORIGIN_BASE)/org.slf4j
	wget -c -O $(ORIGIN_BASE)/org.slf4j/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar https://repo1.maven.org/maven2/org/slf4j/jcl-over-slf4j/$(SLF4J_VERSION)/jcl-over-slf4j-$(SLF4J_VERSION)-sources.jar


	
