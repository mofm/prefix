# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

case ${CHOST} in
	x86_64-apple-darwin9|x86_64-apple-darwin1[0123456])
		MY_ARCH="darwin-amd64"
		;;
	i*86-apple-darwin[89]|i*86-apple-darwin1[0123])
		MY_ARCH="darwin-386"
		;;
	i*86-pc-linux-gnu)
		MY_ARCH="linux-386"
		;;
	x86_64-pc-linux-gnu)
		MY_ARCH="linux-amd64"
		;;
esac
MY_PN="git-lfs"
MY_P="${MY_PN}-${MY_ARCH}-${PV}"

DESCRIPTION="Git extension for versioning large files"
HOMEPAGE="https://git-lfs.github.com/"
SRC_URI="https://github.com/github/git-lfs/releases/download/v${PV}/${MY_P}.tar.gz"

LICENSE="MIT BSD BSD-2 BSD-4 Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"

RDEPEND="
    dev-vcs/git
	"

S="${WORKDIR}/"${MY_PN}-${PV}"/"

src_install() {
	dobin git-lfs
	dodoc CHANGELOG.md  README.md
}
