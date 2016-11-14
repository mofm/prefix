# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}

MY_PV=${PV/_/}

inherit toolchain-funcs

BOOTSTRAP_ROOT="https://storage.googleapis.com/golang"

case ${CHOST} in
	x86_64-apple-darwin9|x86_64-apple-darwin1[0123456])
		BOOTSTRAP_PACKAGE="go${PV}.darwin-amd64.tar.gz"
		;;
	i*86-pc-linux-gnu)
		BOOTSTRAP_PACKAGE="go${PV}.linux-386.tar.gz"
		;;
	x86_64-pc-linux-gnu)
		BOOTSTRAP_PACKAGE="go${PV}.linux-amd64.tar.gz"
		;;
	i386-pc-freebsd*)
		BOOTSTRAP_PACKAGE="go${PV}.freebsd-386.tar.gz"
		;;
	x86_64-pc-freebsd*)
		BOOTSTRAP_PACKAGE="go${PV}.freebsd-amd64.tar.gz"
		;;
	*)
		echo "Download failed: unknown arch"
		exit 1
		;;
esac

SRC_URI="https://storage.googleapis.com/golang/go${MY_PV}.src.tar.gz \
		 "${BOOTSTRAP_ROOT}/${BOOTSTRAP_PACKAGE}" \
		 "

DESCRIPTION="A concurrent garbage collected and typesafe programming language"
HOMEPAGE="http://www.golang.org"

LICENSE="BSD"
SLOT="0/${PV}"
IUSE="gccgo"

DEPEND="gccgo? ( >=sys-devel/gcc-5[go] )"
RDEPEND="!<dev-go/go-tools-0_pre20150902"

# These test data objects have writable/executable stacks.
QA_EXECSTACK="usr/lib/go/src/debug/elf/testdata/*.obj"

# Do not complain about CFLAGS, etc, since Go doesn't use them.
QA_FLAGS_IGNORED='.*'

REQUIRES_EXCLUDE="/usr/lib/go/src/debug/elf/testdata/*"

# The tools in /usr/lib/go should not cause the multilib-strict check to fail.
QA_MULTILIB_PATHS="usr/lib/go/pkg/tool/.*/.*"

# The go language uses *.a files which are _NOT_ libraries and should not be
# stripped. The test data objects should also be left alone and unstripped.
STRIP_MASK="/usr/lib/go/pkg/*.a
	/usr/lib/go/src/debug/elf/testdata/*
	/usr/lib/go/src/debug/dwarf/testdata/*
	/usr/lib/go/src/runtime/race/*.syso"

S="${WORKDIR}"/go

go_arch()
{
	# By chance most portage arch names match Go
	local portage_arch=$(tc-arch $@)
	case "${portage_arch}" in
		x86)	echo 386;;
		x64-*)	echo amd64;;
		ppc64) [[ $(tc-endian $@) = big ]] && echo ppc64 || echo ppc64le ;;
		s390) echo s390x ;;
		*)		echo "${portage_arch}";;
	esac
}

go_arm()
{
	case "${1:-${CHOST}}" in
		armv5*)	echo 5;;
		armv6*)	echo 6;;
		armv7*)	echo 7;;
		*)
			die "unknown GOARM for ${1:-${CHOST}}"
			;;
	esac
}

go_os()
{
	case "${1:-${CHOST}}" in
		*-linux*)	echo linux;;
		*-darwin*)	echo darwin;;
		*-freebsd*)	echo freebsd;;
		*-netbsd*)	echo netbsd;;
		*-openbsd*)	echo openbsd;;
		*-solaris*)	echo solaris;;
		*-cygwin*|*-interix*|*-winnt*)
			echo windows
			;;
		*)
			die "unknown GOOS for ${1:-${CHOST}}"
			;;
	esac
}

go_tuple()
{
	echo "$(go_os $@)_$(go_arch $@)"
}

go_cross_compile()
{
	[[ $(go_tuple ${CBUILD}) != $(go_tuple) ]]
}

pkg_pretend()
{
	# make.bash does not understand cross-compiling a cross-compiler
	if [[ $(go_tuple) != $(go_tuple ${CTARGET}) ]]; then
		die "CHOST CTARGET pair unsupported: CHOST=${CHOST} CTARGET=${CTARGET}"
	fi
}

src_unpack()
{
	unpack ${BOOTSTRAP_PACKAGE}
	mv ${WORKDIR}/go ${WORKDIR}/go${PV}-$(go_os)-$(go_arch)
	unpack go${MY_PV}.src.tar.gz

}

src_compile()
{
	export GOROOT_BOOTSTRAP="${WORKDIR}"/go${PV}-$(go_os)-$(go_arch)
	if use gccgo; then
		mkdir -p "${GOROOT_BOOTSTRAP}/bin" || die
		local go_binary=$(gcc-config --get-bin-path)/go-5
		[[ -x ${go_binary} ]] || go_binary=$(
			find "${EPREFIX}"/usr/${CHOST}/gcc-bin/*/go-5 | sort -V | tail -n1)
		[[ -x ${go_binary} ]] || die "go-5: command not found"
		ln -s "${go_binary}" "${GOROOT_BOOTSTRAP}/bin/go" || die
	fi
	export GOROOT_FINAL="${EPREFIX}"/usr/lib/go
	export GOROOT="$(pwd)"
	export GOBIN="${GOROOT}/bin"

	# Go's build script does not use BUILD/HOST/TARGET consistently. :(
	export GOHOSTARCH=$(go_arch ${CBUILD})
	export GOHOSTOS=$(go_os ${CBUILD})
	export CC=$(tc-getBUILD_CC)

	export GOARCH=$(go_arch)
	export GOOS=$(go_os)
	export CC_FOR_TARGET=$(tc-getCC)
	export CXX_FOR_TARGET=$(tc-getCXX)
	if [[ ${ARCH} == arm ]]; then
		export GOARM=$(go_arm)
	fi
	elog "GOROOT_BOOTSTRAP is ${GOROOT_BOOTSTRAP}"

	cd src
	./make.bash || die "build failed"
}

src_test()
{
	go_cross_compile && return 0

	cd src
	PATH="${GOBIN}:${PATH}" \
		./run.bash -no-rebuild || die "tests failed"
}

src_install()
{
	local bin_path f x

	dodir /usr/lib/go
	insinto /usr/lib/go

	# There is a known issue which requires the source tree to be installed [1].
	# Once this is fixed, we can consider using the doc use flag to control
	# installing the doc and src directories.
	# [1] https://golang.org/issue/2775
	doins -r bin doc lib pkg src
	fperms -R +x /usr/lib/go/bin /usr/lib/go/pkg/tool

	cp -a misc "${D}"/usr/lib/go/misc

	if go_cross_compile; then
		bin_path="bin/$(go_tuple)"
	else
		bin_path=bin
	fi
	for x in ${bin_path}/*; do
		f=${x##*/}
		dosym ../lib/go/${bin_path}/${f} /usr/bin/${f}
	done
	dodoc AUTHORS CONTRIBUTORS PATENTS README.md
}
