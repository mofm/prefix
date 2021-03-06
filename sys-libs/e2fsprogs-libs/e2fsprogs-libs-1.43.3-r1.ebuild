# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

case ${PV} in
*_pre*) UP_PV="${PV%_pre*}-WIP-${PV#*_pre}" ;;
*)      UP_PV=${PV} ;;
esac

inherit toolchain-funcs eutils

DESCRIPTION="e2fsprogs libraries (common error and subsystem)"
HOMEPAGE="http://e2fsprogs.sourceforge.net/"
SRC_URI="mirror://sourceforge/e2fsprogs/${PN}-${UP_PV}.tar.gz
	mirror://kernel/linux/kernel/people/tytso/e2fsprogs/v${UP_PV}/${PN}-${UP_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha ~amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~arm-linux ~x86-linux ~m68k-mint ~x86-solaris ~x64-macos"
IUSE="nls static-libs"

RDEPEND="!sys-libs/com_err
	!sys-libs/ss
	!<sys-fs/e2fsprogs-1.41.8"
DEPEND="nls? ( sys-devel/gettext )
	virtual/pkgconfig
	kernel_Darwin? ( sys-libs/libuuid )
	"

S=${WORKDIR}/${P%_pre*}

PATCHES=(
	"${FILESDIR}"/${PN}-1.42.13-fix-build-cflags.patch #516854
)

src_prepare() {
	printf 'all:\n%%:;@:\n' > doc/Makefile.in # don't bother with docs #305613

	if [[ ${CHOST} == *-darwin* ]] ; then
		PATCHES+=( "${FILESDIR}"/${P}-darwin.patch )
	fi
	epatch "${PATCHES[@]}"
}

src_configure() {
	local SHLIBS
	case ${CHOST} in
		*-darwin*)
			SHLIBS=--enable-bsd-shlibs
			;;
		*)
			SHLIBS=--enable-elf-shlibs
			;;
	esac
	local myconf=()
	# we use blkid/uuid from util-linux now
	if use kernel_linux ; then
		export ac_cv_lib_{uuid_uuid_generate,blkid_blkid_get_cache}=yes
		myconf+=( --disable-lib{blkid,uuid} )
	fi
	# for MacOS
	if [[ ${CHOST} == *-darwin* ]] ; then
		myconf+=( --disable-libuuid --enable-libblkid )
	fi
	ac_cv_path_LDCONFIG=: \
	ECONF_SOURCE="${S}" \
	CC="$(tc-getCC)" \
	BUILD_CC="$(tc-getBUILD_CC)" \
	BUILD_LD="$(tc-getBUILD_LD)" \
	econf \
		$(tc-is-static-only || echo ${SHLIBS}) \
		$(tc-has-tls || echo --disable-tls) \
		$(use_enable nls) \
		"${myconf[@]}"
}

src_compile() {
	emake V=1
}

src_install() {
	emake V=1 STRIP=: DESTDIR="${D}" install || die
	gen_usr_ldscript -a com_err ss
	# configure doesn't have an option to disable static libs :/
	use static-libs || find "${ED}" -name '*.a' -delete
}
