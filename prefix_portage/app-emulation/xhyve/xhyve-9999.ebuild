# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils multilib-build git-r3

DESCRIPTION="The xhyve hypervisor is a port of bhyve to OS X"
HOMEPAGE="https://github.com/mist64/xhyve"
SRC_URI=""
EGIT_REPO_URI="git://github.com/mist64/xhyve.git https://github.com/mist64/xhyve.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~x64-macos"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}/${PN}-cflags.patch"
	eapply_user
}

src_compile() {
	emake
}

src_install() {
	dobin build/xhyve
	doman xhyve.1
}
