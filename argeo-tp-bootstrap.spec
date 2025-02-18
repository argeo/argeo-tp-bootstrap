Name:           argeo-tp-bootstrap
Release:        1%{dist}
Summary:        Enrollment into a FREEd compatible domain

License:        LGPL
URL:            http://www.argeo.org
Source0:        %{name}_%{version}.tar.xz

BuildArch:      noarch

BuildRequires: make
BuildRequires: java-17-openjdk-devel

%description

%package -n argeo-tp-log
Summary:        Argeo third party logging APIs

%description -n argeo-tp-log
SLF4J and Commons Logging APIs redirecting to Java System.Logger

%package -n argeo-tp-log-source
Summary:        Argeo third party logging APIs (sources)

%description -n argeo-tp-log-source
Source code packaged as jar files usable in an Eclipse target platform.

%package -n argeo-tp-build
Summary:        Argeo Build third party libraries
Requires:       argeo-tp-log

%description -n argeo-tp-build
Eclipse ECJ compiler and BND library.

%package -n argeo-tp-build-source
Summary:        Argeo Build third party libraries (sources)

%description -n argeo-tp-build-source
Source code packaged as jar files usable in an Eclipse target platform.

%prep
%setup -n %{name} -q

%build
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
%configure
export SOURCE_BUNDLES=true
export LC_ALL=C.UTF-8
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make datarootdir=%{buildroot}%{_datarootdir} local-install

%files -n argeo-tp-log
%{_datarootdir}/a2/log/default
%{_datarootdir}/a2/log/syslogger/org.argeo.tp/*.jar
%exclude %{_datarootdir}/a2/log/syslogger/org.argeo.tp/*.src.jar

%files -n argeo-tp-log-source
%{_datarootdir}/a2/log/syslogger/org.argeo.tp/*.src.jar

%files -n argeo-tp-build
%{_datarootdir}/a2/org.argeo.tp.build/*.jar
%exclude %{_datarootdir}/a2/org.argeo.tp.build/*.src.jar

%files -n argeo-tp-build-source
%{_datarootdir}/a2/org.argeo.tp.build/*.src.jar
