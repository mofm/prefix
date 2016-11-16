# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit eutils git-r3

DESCRIPTION="corectl commandline tools for MacOS"
HOMEPAGE="https://github.com/TheNewNormal/corectl"
EGIT_REPO_URI="git://github.com/TheNewNormal/corectl.git https://github.com/TheNewNormal/corectl.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~x64-macos"
IUSE=""

DEPEND="=dev-lang/go-1.7.3-r1"
RDEPEND="${DEPEND}"

src_prepare() {
	mkdir -p "${WORKDIR}/src/github.com/TheNewNormal/"
	mv "${WORKDIR}/${P}" "${WORKDIR}/src/github.com/TheNewNormal/${PN}"
	S="${WORKDIR}/src/github.com/TheNewNormal/${PN}"
	cd "${S}"
	epatch "${FILESDIR}/${PN}-prefix.patch"
	eapply_user
}

src_compile() {
	export GOPATH="${WORKDIR}/"
	emake
}

src_install() {
	dobin bin/corectl*

	doman documentation/man/*
}

pkg_postinst() {
	ewarn "This package is unstable! It can't run"
	elog " "
	elog "Please visit for examples: "
	elog " https://github.com/TheNewNormal/corectl "
}
