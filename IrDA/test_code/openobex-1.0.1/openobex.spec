#
# spec file for package OpenOBEX (Version 1.0.1)
# 

Summary:     Library for using OBEX
Name:        openobex
Version:     1.0.1
Release:     1
Copyright:   LGPL
Group:       Libraries
Source:      ftp://download.sourceforge.net/pub/sourceforge/openobex/openobex-%{version}.tar.gz
BuildRoot:   %{_tmppath}/%{name}-%{PACKAGE_VERSION}-root
URL:         http://openobex.sourceforge.net/

%description
Open OBEX shared c-library

%changelog

* Thu Oct 17 2002 Christian W. Zuckschwerdt <zany@triq.net>
- Clean ups

* Thu May 18 2000 Pontus Fuchs <pontus.fuchs@tactel.se>
- Initial RPM

%prep
rm -rf $RPM_BUILD_ROOT

%setup -q

%build
CFLAGS="$RPM_OPT_FLAGS" ./configure --prefix=%{_prefix}
make

%install
rm -rf $RPM_BUILD_ROOT
make prefix=$RPM_BUILD_ROOT%{_prefix} install

%clean
rm -rf $RPM_BUILD_ROOT

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%defattr(-, root, root)
%doc AUTHORS COPYING ChangeLog NEWS README
%{_libdir}/libopenobex*
%{_includedir}/openobex/
%{_bindir}/openobex-config
%{_datadir}/aclocal/openobex.m4

