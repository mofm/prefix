# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="4"

inherit multilib-minimal

MY_P="libtool-${PV}"

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="https://www.gnu.org/software/libtool/"
SRC_URI="mirror://gnu/libtool/${MY_P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="static-libs"
# libltdl doesn't have a testsuite.
RESTRICT="test"

RDEPEND="!<sys-devel/libtool-2.4.3-r2:2
	abi_x86_32? (
		!<=app-emulation/emul-linux-x86-baselibs-20140406-r2
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
	)"
DEPEND="app-arch/xz-utils"

S="${WORKDIR}/${MY_P}/libltdl"

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		--enable-ltdl-install \
		--enable-shared=no
		$(use_enable static-libs static)
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	# While the libltdl.la file is not used directly, the m4 ltdl logic
	# keys off of its existence when searching for ltdl support. #293921
	#use static-libs || find "${D}" -name libltdl.la -delete
}
