# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

EGO_PN="github.com/docker/docker"
MY_PV="${PV/_/-}"
DOCKER_GITCOMMIT="6b644ec"
EGIT_COMMIT="v${MY_PV}"

inherit bash-completion-r1 golang-base golang-vcs-snapshot

DESCRIPTION="Pack, ship and run any application as a lightweight container"
HOMEPAGE="https://www.docker.com/"
SRC_URI="https://github.com/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

[ "$DOCKER_GITCOMMIT" ] || die "DOCKER_GITCOMMIT must be added manually for each bump!"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~x64-macos"
IUSE="experimental"

DEPEND="
	dev-lang/go
	dev-go/go-md2man
"
RDEPEND="${DEPEND}"

RESTRICT="installsources strip"
S="${WORKDIR}/${P}/src/${EGO_PN}"

src_compile() {
	export GOPATH="${WORKDIR}/${P}:${PWD}/vendor"
	# setup CFLAGS and LDFLAGS for separate build target
	# see https://github.com/tianon/docker-overlay/pull/10
	export CGO_CFLAGS="-I${ROOT}/usr/include"
	export CGO_LDFLAGS="-L${ROOT}/usr/$(get_libdir)"

	[ "$DOCKER_GITCOMMIT" ] && export DOCKER_GITCOMMIT

	if use experimental; then
		export DOCKER_EXPERIMENTAL=1
	else
		unset DOCKER_EXPERIMENTAL
	fi

	# time to build!
	./hack/make.sh dynbinary-client || die 'dynbinary failed'
	# build the man pages too
	./man/md2man-all.sh || die "unable to generate man pages"
}

src_install() {
	VERSION="$(cat VERSION)"
	newbin "bundles/$VERSION/dynbinary-client/docker-$VERSION" docker

	dodoc AUTHORS CONTRIBUTING.md CHANGELOG.md NOTICE README.md
	dodoc -r docs/*
	doman man/man*/*

	dobashcomp contrib/completion/bash/*

	insinto /usr/share/zsh/site-functions
	doins contrib/completion/zsh/_*

	insinto /usr/share/vim/vimfiles
	doins -r contrib/syntax/vim/ftdetect
	doins -r contrib/syntax/vim/syntax
}
