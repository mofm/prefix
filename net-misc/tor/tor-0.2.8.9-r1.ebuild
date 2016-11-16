# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

inherit eutils flag-o-matic readme.gentoo-r1 systemd versionator user

MY_PV="$(replace_version_separator 4 -)"
MY_PF="${PN}-${MY_PV}"
DESCRIPTION="Anonymizing overlay network for TCP"
HOMEPAGE="http://www.torproject.org/"
SRC_URI="https://www.torproject.org/dist/${MY_PF}.tar.gz
	https://archive.torproject.org/tor-package-archive/${MY_PF}.tar.gz"
S="${WORKDIR}/${MY_PF}"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ~ppc ppc64 ~sparc x86 ~ppc-macos ~x64-macos"
IUSE="-bufferevents libressl scrypt seccomp selinux stats systemd tor-hardening transparent-proxy test web"

DEPEND="
	app-text/asciidoc
	dev-libs/libevent
	sys-libs/zlib
	bufferevents? ( dev-libs/libevent[ssl] )
	!libressl? ( dev-libs/openssl:0=[-bindist] )
	libressl? ( dev-libs/libressl:0= )
	scrypt? ( app-crypt/libscrypt )
	seccomp? ( sys-libs/libseccomp )
	systemd? ( sys-apps/systemd )"
RDEPEND="${DEPEND}
	selinux? ( sec-policy/selinux-tor )"

src_prepare() {
	if [[ ${CHOST} == *-darwin* ]] ; then
		cp "${FILESDIR}"/tor.plist "${S}"/
		sed -i -e "s:EPREFIX:$EPREFIX:" tor.plist || die "Sed failed!"
    fi
}

src_configure() {
	# Upstream isn't sure of all the user provided CFLAGS that
	# will break tor, but does recommend against -fstrict-aliasing.
	# We'll filter-flags them here as we encounter them.
	filter-flags -fstrict-aliasing

	econf \
		--enable-system-torrc \
		--enable-asciidoc \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable stats instrument-downloads) \
		$(use_enable bufferevents) \
		$(use_enable scrypt libscrypt) \
		$(use_enable seccomp) \
		$(use_enable systemd) \
		$(use_enable tor-hardening gcc-hardening) \
		$(use_enable tor-hardening linker-hardening) \
		$(use_enable transparent-proxy transparent) \
		$(use_enable web tor2web-mode) \
		$(use_enable test unittests) \
		$(use_enable test coverage)
}

src_install() {
	readme.gentoo_create_doc

	newconfd "${FILESDIR}"/tor.confd tor
	newinitd "${FILESDIR}"/tor.initd-r8 tor
	systemd_dounit "${FILESDIR}/${PN}.service"
	systemd_dotmpfilesd "${FILESDIR}/${PN}.conf"

	emake DESTDIR="${D}" install

	keepdir /var/lib/tor

	dodoc -r README ChangeLog ReleaseNotes doc/HACKING
	
	insinto /usr/share/tor
	doins tor.plist 
}

pkg_postinst() {
    if [[ ${CHOST} == *-darwin* ]] ; then
		elog "For MacOS users, You can start tor automatically on login with:"
		elog "mkdir -p ~/Library/LaunchAgents"
		elog "cp ${EPREFIX}/usr/share/${PN}/tor.plist ~/Library/LaunchAgents/"
		elog "launchctl load -w ~/Library/LaunchAgents/tor.plist"
		elog " "
	fi
}
