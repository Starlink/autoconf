# This file is part of Autoconf.                       -*- Autoconf -*-
# Fortran languages support.
# Copyright (C) 2001, 2003-2012 Free Software Foundation, Inc.

# This file is part of Autoconf.  This program is free
# software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Under Section 7 of GPL version 3, you are granted additional
# permissions described in the Autoconf Configure Script Exception,
# version 3.0, as published by the Free Software Foundation.
#
# You should have received a copy of the GNU General Public License
# and a copy of the Autoconf Configure Script Exception along with
# this program; see the files COPYINGv3 and COPYING.EXCEPTION
# respectively.  If not, see <http://www.gnu.org/licenses/>.

# Written by David MacKenzie, with help from
# Franc,ois Pinard, Karl Berry, Richard Pixley, Ian Lance Taylor,
# Roland McGrath, Noah Friedman, david d zuhn, and many others.

#
# Extended by Martin Wilck (2000), Norman Gray and Toby White (2004),
# to add support for preprocessable Fortran (ppfc language).


# XXX Temporary notes on the fpp work, which should turn into a ChangeLog
# entry on submission to the mainline.
#
# Original fpp work done by Martin Wilck: see
# <http://sources.redhat.com/ml/autoconf-patches/2000-07/msg00287.html>
# and the following thread.
#
# The modifications to Martin's work, done by Norman Gray and Toby White,
# are as follows:
#
# - Change define to m4_define, to match newer (post 2.50) versions of autoconf
# - Added second, optional, FPP-SRC-EXT parameter to AC_PROG_FPP, to set the
#   extension expected, in case you want to use something other than .F
# - Slight changes to tests, following comments by Akim Demaille
#   on the mailing list (including Martin's cunning
#   _AC_SHELL_POSITIONAL).
# - renamed $ac_gnu_compiler to $ac_compiler_gnu
# - Added _AC_LANG_ABBREV(Preprocessed Fortran), and a few other
#   functions which match the support apparatus seems to want,
#     - note AC_LANG_ABBREV and AC_LANG_PREFIX incorporated in
#       AC_LANG_DEFINE at 2.64.
# - Added AC_LANG_PREPROC and AC_LANG_COMPILER
# - Added AC_REQUIRE of _AC_PROG_FC_CPP to _AC_PROG_FPP
# - In test of how to run the preprocessor alone, check that our tests
#   don't produce a a.out file -- if they do, that counts as a
#   failure, even with a zero exit status
# - Removed _AC_ECHO calls -- were always internal, now disappeared
# - Changed old >&AC_FD_LOG to >&AS_MESSAGE_LOG_FD
# - Based on "Fortran" language, rather than "Fortran 77"
# - Addition of separate yes/no check for whether FC supports preprocessing.
# - Remove hardcoding of file extensions in preprocessing checks.
# - Improvement of AC_FC_SRCEXT to allow a variable to be passed to it.
# - Add utility macros AC_FC_FIXEDFORM, AC_FC_OPEN_SPECIFIERS,
#   AC_FC_CHECK_INTRINSICS, AC_FC_RECL_UNIT


# Table of Contents:
#
# Preamble
#
# 0. Utility macros
#
# 1. Language selection
#    and routines to produce programs in a given language.
#
# 2. Producing programs in a given language.
#
# 3. Looking for a compiler
#    And possibly the associated preprocessor.
#
# 4. Compilers' characteristics.



## ---------- ##
## Preamble.  ##
## ---------- ##

# Fortran vs. Fortran 77:
#   This file contains macros for both "Fortran 77" and "Fortran", where
# the former is the "classic" autoconf Fortran interface and is intended
# for legacy F77 codes, while the latter is intended to support newer Fortran
# dialects.  Fortran 77 uses environment variables F77, FFLAGS, and FLIBS,
# while Fortran uses FC, FCFLAGS, and FCLIBS.  For each user-callable AC_*
# macro, there is generally both an F77 and an FC version, where both versions
# share the same _AC_*_FC_* backend.  This backend macro requires that
# the appropriate language be AC_LANG_PUSH'ed, and uses _AC_LANG_ABBREV and
# _AC_LANG_PREFIX in order to name cache and environment variables, etc.



## ------------------- ##
## 0. Utility macros.  ##
## ------------------- ##


# _AC_LIST_MEMBER_IF(ELEMENT, LIST, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ---------------------------------------------------------------------------
#
# Processing the elements of a list is tedious in shell programming,
# as lists tend to be implemented as space delimited strings.
#
# This macro searches LIST for ELEMENT, and executes ACTION-IF-FOUND
# if ELEMENT is a member of LIST, otherwise it executes
# ACTION-IF-NOT-FOUND.
AC_DEFUN([_AC_LIST_MEMBER_IF],
dnl Do some sanity checking of the arguments.
[m4_if([$1], , [m4_fatal([$0: missing argument 1])],
      [$2], , [m4_fatal([$0: missing argument 2])])]dnl
[  ac_exists=false
  for ac_i in $2; do
    if test x"$1" = x"$ac_i"; then
      ac_exists=true
      break
    fi
  done

  AS_IF([test x"$ac_exists" = xtrue], [$3], [$4])[]dnl
])# _AC_LIST_MEMBER_IF


# _AC_LINKER_OPTION(LINKER-OPTIONS, SHELL-VARIABLE)
# -------------------------------------------------
#
# Specifying options to the compiler (whether it be the C, C++ or
# Fortran 77 compiler) that are meant for the linker is compiler
# dependent.  This macro lets you give options to the compiler that
# are meant for the linker in a portable, compiler-independent way.
#
# This macro take two arguments, a list of linker options that the
# compiler should pass to the linker (LINKER-OPTIONS) and the name of
# a shell variable (SHELL-VARIABLE).  The list of linker options are
# appended to the shell variable in a compiler-dependent way.
#
# For example, if the selected language is C, then this:
#
#   _AC_LINKER_OPTION([-R /usr/local/lib/foo], foo_LDFLAGS)
#
# will expand into this if the selected C compiler is gcc:
#
#   foo_LDFLAGS="-Xlinker -R -Xlinker /usr/local/lib/foo"
#
# otherwise, it will expand into this:
#
#   foo_LDFLAGS"-R /usr/local/lib/foo"
#
# You are encouraged to add support for compilers that this macro
# doesn't currently support.
# FIXME: Get rid of this macro.
AC_DEFUN([_AC_LINKER_OPTION],
[if test "$ac_compiler_gnu" = yes; then
  for ac_link_opt in $1; do
    $2="[$]$2 -Xlinker $ac_link_opt"
  done
else
  $2="[$]$2 $1"
fi[]dnl
])# _AC_LINKER_OPTION



## ------------------------ ##
## 1a. Language selection.  ##
## ------------------------ ##


# AC_LANG(Fortran 77)
# -------------------
AC_LANG_DEFINE([Fortran 77], [f77], [F], [F77], [],
[ac_ext=f
ac_compile='$F77 -c $FFLAGS conftest.$ac_ext >&AS_MESSAGE_LOG_FD'
ac_link='$F77 -o conftest$ac_exeext $FFLAGS $LDFLAGS conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'
ac_compiler_gnu=$ac_cv_f77_compiler_gnu
])


# AC_LANG_FORTRAN77
# -----------------
AU_DEFUN([AC_LANG_FORTRAN77], [AC_LANG(Fortran 77)])


# _AC_FORTRAN_ASSERT
# ------------------
# Current language must be Fortran, Fortran 77, or preprocessed Fortran.
# FIXME: is there any reason why this can't be AC_LANG_CASE?
m4_defun([_AC_FORTRAN_ASSERT],
[m4_if(_AC_LANG, [Fortran], [],
       [m4_if(_AC_LANG, [Fortran 77], [],
              [m4_if(_AC_LANG, [Preprocessed Fortran], []
                     [m4_fatal([$0: current language is not Fortran: ] _AC_LANG)])])])])


# _AC_FC
# ------
# Return F77, FC or PPFC, depending upon the language.
AC_DEFUN([_AC_FC],
[_AC_FORTRAN_ASSERT()dnl
AC_LANG_CASE([Fortran 77],           [F77],
             [Fortran],              [FC],
             [Preprocessed Fortran], [PPFC])])



## ----------------------- ##
## 2. Producing programs.  ##
## ----------------------- ##


# AC_LANG_PROGRAM(Fortran 77)([PROLOGUE], [BODY])
# -----------------------------------------------
# Yes, we discard the PROLOGUE.
m4_define([AC_LANG_PROGRAM(Fortran 77)],
[m4_ifval([$1],
       [m4_warn([syntax], [$0: ignoring PROLOGUE: $1])])dnl
      program main
$2
      end])


# _AC_LANG_IO_PROGRAM(Fortran 77)
# -------------------------------
# Produce source that performs I/O.
m4_define([_AC_LANG_IO_PROGRAM(Fortran 77)],
[AC_LANG_PROGRAM([],
[dnl
      open(unit=9,file='conftest.out')
      close(unit=9)
])])


# AC_LANG_CALL(Fortran 77)(PROLOGUE, FUNCTION)
# --------------------------------------------
# FIXME: This is a guess, help!
m4_define([AC_LANG_CALL(Fortran 77)],
[AC_LANG_PROGRAM([$1],
[      call $2])])


# AC_LANG_FUNC_LINK_TRY(Fortran)(FUNCTION)
# ----------------------------------------
# Produce a source which links correctly iff the Fortran FUNCTION exists.
# Note that the generic AC_LANG_FUNC_LINK_TRY macro is deemed severely
# broken, and is deprecated.  The macro still currently exists, however,
# and so if macros like AC_CHECK_FUNCS are to work with
# AC_LANG(Fortran) (and friends), then these macros have to be
# defined.
#
# FIXME: This is a severely broken implementation.
# It does not distinguish between functions and subroutines, and it
# ignores any arguments.  We don't attempt to cope with argument $1
# being somethine weird -- either already declared as a Fortran keyword
# or something needing quoting -- if the user wants to ask dumb
# questions, they'll get dumb answers.
m4_define([AC_LANG_FUNC_LINK_TRY(Fortran)],
[AC_LANG_SOURCE(
[      Program Test
      External $1
      Call $1
      End
])])


# AC_LANG_FUNC_LINK_TRY(Fortran 77)(FUNCTION)
# -------------------------------------------
# Ditto, for language `Fortran 77'
m4_define([AC_LANG_FUNC_LINK_TRY(Fortran 77)],
[AC_LANG_SOURCE(
[      Program Test
      External $1
      Call $1
      End
])])


# AC_LANG_FUNC_LINK_TRY(Preprocessed Fortran)(FUNCTION)
# -----------------------------------------------------
# Ditto, for language `Preprocessed Fortran'
m4_define([AC_LANG_FUNC_LINK_TRY(Preprocessed Fortran)],
[AC_LANG_SOURCE(
[      Program Test
      External $1
      Call $1
      End
])])


## ------------------------ ##
## 1b. Language selection.  ##
## ------------------------ ##


# AC_LANG(Fortran)
# ----------------
AC_LANG_DEFINE([Fortran], [fc], [FC], [FC], [Fortran 77],
[ac_ext=${ac_fc_srcext-f}
ac_compile='$FC -c $FCFLAGS $ac_fcflags_srcext conftest.$ac_ext >&AS_MESSAGE_LOG_FD'
ac_link='$FC -o conftest$ac_exeext $FCFLAGS $LDFLAGS $ac_fcflags_srcext conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'
ac_compiler_gnu=$ac_cv_fc_compiler_gnu
])


## ------------------------ ##
## 1c. Language selection.  ##
## ------------------------ ##

# AC_LANG(Preprocessed Fortran)
# --------------------------------
# We need a separate `preprocessed' language, because not all Fortran
# compilers have a preprocessor built in.  Therefore we may need to
# resort to an `indirect' compilation, .F->.f->.o, including the
# generation of a suitable extra build rule.  The language extension
# is set in macro AC_PROG_FPP, to $FPP_SRC_EXT. Note we base on
# Fortran 77 which gets some support macros we previously defined.
AC_LANG_DEFINE([Preprocessed Fortran], [fpp], [FPP], [Fortran 77],
[ac_ext=$FPP_SRC_EXT
# We need to use variables because compilation depends on whether
# $F77 supports direct compilation of source with cpp directives
ac_compile=$ac_fpp_compile
ac_link=$ac_fpp_link
ac_compiler_gnu=$ac_cv_fc_compiler_gnu
])


## -------------------------------------------- ##
## 3. Looking for Compilers and Preprocessors.  ##
## -------------------------------------------- ##


# AC_LANG_PREPROC(Fortran 77)
# ---------------------------
# Find the Fortran 77 preprocessor.  Must be AC_DEFUN'd to be AC_REQUIRE'able.
AC_DEFUN([AC_LANG_PREPROC(Fortran 77)],
[m4_warn([syntax],
	 [$0: No preprocessor defined for ]_AC_LANG)])

# AC_LANG_PREPROC(Fortran)
# ------------------------
# Find the Fortran preprocessor.  Must be AC_DEFUN'd to be AC_REQUIRE'able.
AC_DEFUN([AC_LANG_PREPROC(Fortran)],
[m4_warn([syntax],
	 [$0: No preprocessor defined for ]_AC_LANG)])

# AC_LANG_PREPROC(Preprocessed Fortran)
# -------------------------------------
# Find the Fortran preprocessor.  Must be AC_DEFUN'd to be AC_REQUIRE'able.
AC_DEFUN([AC_LANG_PREPROC(Preprocessed Fortran)],
[AC_REQUIRE([AC_PROG_FPP])])


# AC_LANG_COMPILER(Fortran 77)
# ----------------------------
# Find the Fortran 77 compiler.  Must be AC_DEFUN'd to be
# AC_REQUIRE'able.
AC_DEFUN([AC_LANG_COMPILER(Fortran 77)],
[AC_REQUIRE([AC_PROG_F77])])

# AC_LANG_COMPILER(Fortran)
# -------------------------
# Find the Fortran compiler.  Must be AC_DEFUN'd to be
# AC_REQUIRE'able.
AC_DEFUN([AC_LANG_COMPILER(Fortran)],
[AC_REQUIRE([AC_PROG_FC])])

# AC_LANG_COMPILER(Preprocessed Fortran)
# --------------------------------------
# Find the Fortran compiler.  Must be AC_DEFUN'd to be
# AC_REQUIRE'able.
AC_DEFUN([AC_LANG_COMPILER(Preprocessed Fortran)],
[AC_REQUIRE([AC_PROG_FC])])


# ac_cv_prog_g77
# --------------
# We used to name the cache variable this way.
AU_DEFUN([ac_cv_prog_g77],
[ac_cv_f77_compiler_gnu])


# _AC_FC_DIALECT_YEAR([DIALECT])
# ------------------------------
# Given a Fortran DIALECT, which is Fortran [YY]YY or simply [YY]YY,
# convert to a 4-digit year.  The dialect must be one of Fortran 77,
# 90, 95, or 2000, currently.  If DIALECT is simply Fortran or the
# empty string, returns the empty string.
AC_DEFUN([_AC_FC_DIALECT_YEAR],
[m4_case(m4_bpatsubsts(m4_tolower([$1]), [fortran],[], [ *],[]),
	 [77],[1977], [1977],[1977],
	 [90],[1990], [1990],[1990],
	 [95],[1995], [1995],[1995],
	 [2000],[2000],
	 [],[],
	 [m4_fatal([unknown Fortran dialect])])])


# _AC_FC_MOD_SUFFIX
# -----------------
# Determines the form of the filename of modules produced
# by the Fortran compiler.
# Tests for all forms of file extension I've (TW) found in the
# wild. Note that at least one compiler (PGI??) changes the
# case of the basename as well. Whether this happens is
# encoded in the variable ac_fc_mod_uppercase.
#
AC_DEFUN([_AC_FC_MOD_SUFFIX],
[
ac_mod_ext=
ac_fc_mod_uppercase=no
cat > conftest.$ac_ext << \_ACEOF
      module conftest
       implicit none
       integer :: i
      end module conftest
_ACEOF
_AC_EVAL_STDERR($ac_compile)
AC_MSG_CHECKING([for suffix of module files])
for ac_mod_file in conftest.mod conftest.MOD conftest.M CONFTEST.MOD none
do
  if test -f $ac_mod_file; then
    break;
  fi
done
rm -f conftest.$ac_ext conftest.$ac_exe_ext conftest.mod conftest.MOD conftest.M CONFTEST.MOD
#
case $ac_mod_file in
  conftest.mod)
    ac_mod_ext=mod
    ;;
  conftest.MOD)
    ac_mod_ext=MOD
    ;;
  conftest.M)
    ac_mod_ext=M
    ;;
  CONFTEST.MOD)
    ac_mod_ext=MOD
    ac_fc_mod_uppercase=yes
    ;;
  none)
    AC_MSG_WARN([Could not find Fortran module file extension.])
    ;;
esac

if test $ac_mod_file != none; then
  AC_MSG_RESULT([$ac_mod_ext])
fi
if test $ac_fc_mod_uppercase = yes; then
  AC_MSG_NOTICE([Fortran module filenames are uppercase.])
fi
])

# _AC_PROG_FC([DIALECT], [COMPILERS...])
# --------------------------------------
# DIALECT is a Fortran dialect, given by Fortran [YY]YY or simply [YY]YY,
# and must be one of those supported by _AC_FC_DIALECT_YEAR
#
# If DIALECT is supplied, then we search for compilers of that dialect
# first, and then later dialects.  Otherwise, we search for compilers
# of the newest dialect first, and then earlier dialects in increasing age.
# This search order is necessarily imperfect because the dialect cannot
# always be inferred from the compiler name.
#
# Known compilers:
#  f77/f90/f95: generic compiler names
#  g77: GNU Fortran 77 compiler
#  gfortran: GNU Fortran 95+ compiler (released in gcc 4.0)
#  g95: original gcc-based f95 compiler (gfortran is a fork)
#  ftn: native Fortran 95 compiler on Cray X1
#  cf77: native F77 compiler under older Crays (prefer over fort77)
#  fort77: native F77 compiler under HP-UX (and some older Crays)
#  frt: Fujitsu F77 compiler
#  pgf77/pgf90/pghpf/pgf95/pgfortran: Portland Group F77/F90/F95 compilers
#  xlf/xlf90/xlf95: IBM (AIX) F77/F90/F95 compilers
#    Prefer xlf9x to the generic names because they do not reject files
#    with extension `.f'.
#  lf95: Lahey-Fujitsu F95 compiler
#  fl32: Microsoft Fortran 77 "PowerStation" compiler
#  af77: Apogee F77 compiler for Intergraph hardware running CLIX
#  epcf90: "Edinburgh Portable Compiler" F90
#  fort: Compaq (now HP) Fortran 90/95 compiler for Tru64 and Linux/Alpha
#  ifort, previously ifc: Intel Fortran 95 compiler for Linux/x86
#  efc: Intel Fortran 95 compiler for IA64
#  nagfor: NAGWare Fortran 77/90/95 compiler
#  f77 -old_f77: DIGITAL Fortran 77 (as opposed to f90 in F77 mode)
#
# Must check for lf95 before f95 - some Lahey versions ship an f95 binary
# in the default path that must be avoided.
# (A proper fix would involve being able to go back and try another compiler
#  if the first one fails, but that requires a major reworking of much of
#  autoconf. The same problem arises (with no easy solution) on some Digital
#  compilers: f95 fails on .F files, f90 succeeds.)
#
m4_define([_AC_F95_FC], [gfortran g95 lf95 xlf95 f95 fort ifc ifort efc pgfortran pgf95 ftn nagfor])
m4_define([_AC_F90_FC], [xlf90 f90 pgf90 pghpf epcf90])
m4_define([_AC_F77_FC], [g77 f77 xlf frt pgf77 cf77 fort77 fl32 af77 'f77 -old_f77'])
AC_DEFUN([_AC_PROG_FC],
[_AC_FORTRAN_ASSERT()dnl
AC_CHECK_TOOLS([]_AC_FC[],
      m4_default([$2],
	m4_case(_AC_FC_DIALECT_YEAR([$1]),
		[1995], [_AC_F95_FC],
		[1990], [_AC_F90_FC _AC_F95_FC],
		[1977], [_AC_F77_FC _AC_F90_FC _AC_F95_FC],
		[_AC_F95_FC _AC_F90_FC _AC_F77_FC])))

# Provide some information about the compiler.
_AS_ECHO_LOG([checking for _AC_LANG compiler version])
set X $ac_compile
ac_compiler=$[2]
for ac_option in --version -v -V -qversion; do
  _AC_DO_LIMIT([$ac_compiler $ac_option >&AS_MESSAGE_LOG_FD])
done
rm -f a.out

m4_expand_once([_AC_COMPILER_EXEEXT])[]dnl
m4_expand_once([_AC_COMPILER_OBJEXT])[]dnl
dnl This next will warn but continue if we have an F77-only compiler.
dnl FIXME: do we care about the (potentially) superfluous warning?
_AC_FC_MOD_SUFFIX
# If we don't use `.F' as extension, the preprocessor is not run on the
# input file.  (Note that this only needs to work for GNU compilers.)
ac_save_ext=$ac_ext
ac_ext=F
_AC_LANG_COMPILER_GNU
ac_ext=$ac_save_ext
_AC_PROG_FC_G
])# _AC_PROG_FC


# AC_PROG_F77([COMPILERS...])
# ---------------------------
# COMPILERS is a space separated list of Fortran 77 compilers to search
# for.  See also _AC_PROG_FC.
AC_DEFUN([AC_PROG_F77],
[AC_BEFORE([$0], [AC_PROG_FPP])dnl
AC_LANG_PUSH(Fortran 77)dnl
AC_ARG_VAR([F77],    [Fortran 77 compiler command])dnl
AC_ARG_VAR([FFLAGS], [Fortran 77 compiler flags])dnl
_AC_ARG_VAR_LDFLAGS()dnl
_AC_ARG_VAR_LIBS()dnl
_AC_PROG_FC([Fortran 77], [$1])
if test $ac_compiler_gnu = yes; then
  G77=yes
else
  G77=
fi
AC_LANG_POP(Fortran 77)dnl
])# AC_PROG_F77


# AC_PROG_FC([COMPILERS...], [DIALECT])
# -------------------------------------
# COMPILERS is a space separated list of Fortran 77 compilers to search
# for, and [DIALECT] is an optional dialect.  See also _AC_PROG_FC.
AC_DEFUN([AC_PROG_FC],
[AC_LANG_PUSH(Fortran)dnl
AC_ARG_VAR([FC],    [Fortran compiler command])dnl
AC_ARG_VAR([FCFLAGS], [Fortran compiler flags])dnl
_AC_ARG_VAR_LDFLAGS()dnl
_AC_ARG_VAR_LIBS()dnl
_AC_PROG_FC([$2], [$1])
if test $ac_compiler_gnu = yes; then
  GFC=yes
else
  GFC=
fi
AC_LANG_POP(Fortran)dnl
])# AC_PROG_FC


# _AC_PROG_FC_G
# -------------
# Check whether -g works, even if F[C]FLAGS is set, in case the package
# plays around with F[C]FLAGS (such as to build both debugging and normal
# versions of a library), tasteless as that idea is.
m4_define([_AC_PROG_FC_G],
[_AC_FORTRAN_ASSERT()dnl
ac_test_[]_AC_LANG_PREFIX[]FLAGS=${[]_AC_LANG_PREFIX[]FLAGS+set}
ac_save_[]_AC_LANG_PREFIX[]FLAGS=$[]_AC_LANG_PREFIX[]FLAGS
_AC_LANG_PREFIX[]FLAGS=
AC_CACHE_CHECK(whether $[]_AC_FC[] accepts -g, ac_cv_prog_[]_AC_LANG_ABBREV[]_g,
[_AC_LANG_PREFIX[]FLAGS=-g
_AC_COMPILE_IFELSE([AC_LANG_PROGRAM()],
[ac_cv_prog_[]_AC_LANG_ABBREV[]_g=yes],
[ac_cv_prog_[]_AC_LANG_ABBREV[]_g=no])
])
if test "$ac_test_[]_AC_LANG_PREFIX[]FLAGS" = set; then
  _AC_LANG_PREFIX[]FLAGS=$ac_save_[]_AC_LANG_PREFIX[]FLAGS
elif test $ac_cv_prog_[]_AC_LANG_ABBREV[]_g = yes; then
  if test "x$ac_cv_[]_AC_LANG_ABBREV[]_compiler_gnu" = xyes; then
    _AC_LANG_PREFIX[]FLAGS="-g -O2"
  else
    _AC_LANG_PREFIX[]FLAGS="-g"
  fi
else
  if test "x$ac_cv_[]_AC_LANG_ABBREV[]_compiler_gnu" = xyes; then
    _AC_LANG_PREFIX[]FLAGS="-O2"
  else
    _AC_LANG_PREFIX[]FLAGS=
  fi
fi[]dnl
])# _AC_PROG_FC_G


# _AC_PROG_FC_C_O
# ---------------
# Test if the Fortran compiler accepts the options `-c' and `-o'
# simultaneously, and define `[F77/FC]_NO_MINUS_C_MINUS_O' if it does not.
#
# The usefulness of this macro is questionable, as I can't really see
# why anyone would use it.  The only reason I include it is for
# completeness, since a similar test exists for the C compiler.
#
# FIXME: it seems like we could merge the C/C++/Fortran versions of this.
AC_DEFUN([_AC_PROG_FC_C_O],
[_AC_FORTRAN_ASSERT()dnl
AC_CACHE_CHECK([whether $[]_AC_FC[] understands -c and -o together],
	       [ac_cv_prog_[]_AC_LANG_ABBREV[]_c_o],
[AC_LANG_CONFTEST([AC_LANG_PROGRAM([])])
# We test twice because some compilers refuse to overwrite an existing
# `.o' file with `-o', although they will create one.
ac_try='$[]_AC_FC[] $[]_AC_LANG_PREFIX[]FLAGS -c conftest.$ac_ext -o conftest2.$ac_objext >&AS_MESSAGE_LOG_FD'
rm -f conftest2.*
if _AC_DO_VAR(ac_try) &&
     test -f conftest2.$ac_objext &&
     _AC_DO_VAR(ac_try); then
  ac_cv_prog_[]_AC_LANG_ABBREV[]_c_o=yes
else
  ac_cv_prog_[]_AC_LANG_ABBREV[]_c_o=no
fi
rm -f conftest*])
if test $ac_cv_prog_[]_AC_LANG_ABBREV[]_c_o = no; then
  AC_DEFINE([]_AC_FC[]_NO_MINUS_C_MINUS_O, 1,
	    [Define to 1 if your Fortran compiler doesn't accept
	     -c and -o together.])
fi
])# _AC_PROG_FC_C_O


# AC_PROG_F77_C_O
# ---------------
AC_DEFUN([AC_PROG_F77_C_O],
[AC_REQUIRE([AC_PROG_F77])dnl
AC_LANG_PUSH(Fortran 77)dnl
_AC_PROG_FC_C_O
AC_LANG_POP(Fortran 77)dnl
])# AC_PROG_F77_C_O


# AC_PROG_FC_C_O
# --------------
AC_DEFUN([AC_PROG_FC_C_O],
[AC_REQUIRE([AC_PROG_FC])dnl
AC_LANG_PUSH(Fortran)dnl
_AC_PROG_FC_C_O
AC_LANG_POP(Fortran)dnl
])# AC_PROG_FC_C_O



## ------------------------------- ##
## 4. Compilers' characteristics.  ##
## ------------------------------- ##


# _AC_PROG_FC_V_OUTPUT([FLAG = $ac_cv_prog_{f77/fc}_v])
# -----------------------------------------------------
# Link a trivial Fortran program, compiling with a verbose output FLAG
# (whose default value, $ac_cv_prog_{f77/fc}_v, is computed by
# _AC_PROG_FC_V), and return the output in $ac_{f77/fc}_v_output.  This
# output is processed in the way expected by _AC_FC_LIBRARY_LDFLAGS,
# so that any link flags that are echoed by the compiler appear as
# space-separated items.
AC_DEFUN([_AC_PROG_FC_V_OUTPUT],
[_AC_FORTRAN_ASSERT()dnl
AC_LANG_CONFTEST([AC_LANG_PROGRAM([])])

# Compile and link our simple test program by passing a flag (argument
# 1 to this macro) to the Fortran compiler in order to get
# "verbose" output that we can then parse for the Fortran linker
# flags.
ac_save_[]_AC_LANG_PREFIX[]FLAGS=$[]_AC_LANG_PREFIX[]FLAGS
_AC_LANG_PREFIX[]FLAGS="$[]_AC_LANG_PREFIX[]FLAGS m4_default([$1], [$ac_cv_prog_[]_AC_LANG_ABBREV[]_v])"
eval "set x $ac_link"
shift
_AS_ECHO_LOG([$[*]])
# gfortran 4.3 outputs lines setting COLLECT_GCC_OPTIONS, COMPILER_PATH,
# LIBRARY_PATH; skip all such settings.
ac_[]_AC_LANG_ABBREV[]_v_output=`eval $ac_link AS_MESSAGE_LOG_FD>&1 2>&1 |
  sed '/^Driving:/d; /^Configured with:/d;
      '"/^[[_$as_cr_Letters]][[_$as_cr_alnum]]*=/d"`
AS_ECHO(["$ac_[]_AC_LANG_ABBREV[]_v_output"]) >&AS_MESSAGE_LOG_FD
_AC_LANG_PREFIX[]FLAGS=$ac_save_[]_AC_LANG_PREFIX[]FLAGS

rm -rf conftest*

# On HP/UX there is a line like: "LPATH is: /foo:/bar:/baz" where
# /foo, /bar, and /baz are search directories for the Fortran linker.
# Here, we change these into -L/foo -L/bar -L/baz (and put it first):
ac_[]_AC_LANG_ABBREV[]_v_output="`echo $ac_[]_AC_LANG_ABBREV[]_v_output |
	grep 'LPATH is:' |
	sed 's|.*LPATH is\(: *[[^ ]]*\).*|\1|;s|: */| -L/|g'` $ac_[]_AC_LANG_ABBREV[]_v_output"

# FIXME: we keep getting bitten by quoted arguments; a more general fix
#        that detects unbalanced quotes in FLIBS should be implemented
#        and (ugh) tested at some point.
case $ac_[]_AC_LANG_ABBREV[]_v_output in
  # With xlf replace commas with spaces,
  # and remove "-link" and closing parenthesis.
  *xlfentry*)
    ac_[]_AC_LANG_ABBREV[]_v_output=`echo $ac_[]_AC_LANG_ABBREV[]_v_output |
      sed '
        s/,/ /g
        s/ -link / /g
        s/) *$//
      '
    ` ;;

  # With Intel ifc, ignore the quoted -mGLOB_options_string stuff (quoted
  # $LIBS confuse us, and the libraries appear later in the output anyway).
  *mGLOB_options_string*)
    ac_[]_AC_LANG_ABBREV[]_v_output=`echo $ac_[]_AC_LANG_ABBREV[]_v_output | sed 's/"-mGLOB[[^"]]*"/ /g'` ;;

  # Portland Group compiler has singly- or doubly-quoted -cmdline argument
  # Singly-quoted arguments were reported for versions 5.2-4 and 6.0-4.
  # Doubly-quoted arguments were reported for "PGF90/x86 Linux/x86 5.0-2".
  *-cmdline\ * | *-ignore\ * | *-def\ *)
    ac_[]_AC_LANG_ABBREV[]_v_output=`echo $ac_[]_AC_LANG_ABBREV[]_v_output | sed "\
	s/-cmdline  *'[[^']]*'/ /g; s/-cmdline  *\"[[^\"]]*\"/ /g
	s/-ignore  *'[[^']]*'/ /g; s/-ignore  *\"[[^\"]]*\"/ /g
	s/-def  *'[[^']]*'/ /g; s/-def  *\"[[^\"]]*\"/ /g"` ;;

  # If we are using fort77 (the f2c wrapper) then filter output and delete quotes.
  *fort77*f2c*gcc*)
    ac_[]_AC_LANG_ABBREV[]_v_output=`echo "$ac_[]_AC_LANG_ABBREV[]_v_output" | sed -n '
        /:[[	 ]]\+Running[[	 ]]\{1,\}"gcc"/{
          /"-c"/d
          /[[.]]c"*/d
          s/^.*"gcc"/"gcc"/
          s/"//gp
        }'` ;;

  # If we are using Cray Fortran then delete quotes.
  *cft90*)
    ac_[]_AC_LANG_ABBREV[]_v_output=`echo $ac_[]_AC_LANG_ABBREV[]_v_output | sed 's/"//g'` ;;
esac

])# _AC_PROG_FC_V_OUTPUT


# _AC_PROG_FC_V
# -------------
#
# Determine the flag that causes the Fortran compiler to print
# information of library and object files (normally -v)
# Needed for _AC_FC_LIBRARY_FLAGS
# Some compilers don't accept -v (Lahey: (-)-verbose, xlf: -V, Fujitsu: -###)
AC_DEFUN([_AC_PROG_FC_V],
[_AC_FORTRAN_ASSERT()dnl
AC_CACHE_CHECK([how to get verbose linking output from $[]_AC_FC[]],
		[ac_cv_prog_[]_AC_LANG_ABBREV[]_v],
[AC_COMPILE_IFELSE([AC_LANG_PROGRAM()],
[ac_cv_prog_[]_AC_LANG_ABBREV[]_v=
# Try some options frequently used verbose output
for ac_verb in -v -verbose --verbose -V -\#\#\#; do
  _AC_PROG_FC_V_OUTPUT($ac_verb)
  # look for -l* and *.a constructs in the output
  for ac_arg in $ac_[]_AC_LANG_ABBREV[]_v_output; do
     case $ac_arg in
	[[\\/]]*.a | ?:[[\\/]]*.a | -[[lLRu]]*)
	  ac_cv_prog_[]_AC_LANG_ABBREV[]_v=$ac_verb
	  break 2 ;;
     esac
  done
done
if test -z "$ac_cv_prog_[]_AC_LANG_ABBREV[]_v"; then
   AC_MSG_WARN([cannot determine how to obtain linking information from $[]_AC_FC[]])
fi],
		  [AC_MSG_WARN([compilation failed])])
])])# _AC_PROG_FC_V


# _AC_FC_LIBRARY_LDFLAGS
# ----------------------
#
# Determine the linker flags (e.g. "-L" and "-l") for the Fortran
# intrinsic and runtime libraries that are required to successfully
# link a Fortran program or shared library.  The output variable
# FLIBS/FCLIBS is set to these flags.
#
# This macro is intended to be used in those situations when it is
# necessary to mix, e.g. C++ and Fortran, source code into a single
# program or shared library.
#
# For example, if object files from a C++ and Fortran compiler must
# be linked together, then the C++ compiler/linker must be used for
# linking (since special C++-ish things need to happen at link time
# like calling global constructors, instantiating templates, enabling
# exception support, etc.).
#
# However, the Fortran intrinsic and runtime libraries must be
# linked in as well, but the C++ compiler/linker doesn't know how to
# add these Fortran libraries.  Hence, the macro
# "AC_F77_LIBRARY_LDFLAGS" was created to determine these Fortran
# libraries.
#
# This macro was packaged in its current form by Matthew D. Langston.
# However, nearly all of this macro came from the "OCTAVE_FLIBS" macro
# in "octave-2.0.13/aclocal.m4", and full credit should go to John
# W. Eaton for writing this extremely useful macro.  Thank you John.
AC_DEFUN([_AC_FC_LIBRARY_LDFLAGS],
[AC_REQUIRE([AC_CANONICAL_HOST])dnl
_AC_FORTRAN_ASSERT()dnl
_AC_PROG_FC_V
AC_CACHE_CHECK([for _AC_LANG libraries of $[]_AC_FC[]], ac_cv_[]_AC_LANG_ABBREV[]_libs,
[if test "x$[]_AC_LANG_PREFIX[]LIBS" != "x"; then
  ac_cv_[]_AC_LANG_ABBREV[]_libs="$[]_AC_LANG_PREFIX[]LIBS" # Let the user override the test.
else

_AC_PROG_FC_V_OUTPUT

ac_cv_[]_AC_LANG_ABBREV[]_libs=

# Save positional arguments (if any)
ac_save_positional="$[@]"

set X $ac_[]_AC_LANG_ABBREV[]_v_output
while test $[@%:@] != 1; do
  shift
  ac_arg=$[1]
  case $ac_arg in
	[[\\/]]*.a | ?:[[\\/]]*.a)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_[]_AC_LANG_ABBREV[]_libs, ,
	      ac_cv_[]_AC_LANG_ABBREV[]_libs="$ac_cv_[]_AC_LANG_ABBREV[]_libs $ac_arg")
	  ;;
	-bI:*)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_[]_AC_LANG_ABBREV[]_libs, ,
	     [_AC_LINKER_OPTION([$ac_arg], ac_cv_[]_AC_LANG_ABBREV[]_libs)])
	  ;;
	  # Ignore these flags.
	-lang* | -lcrt*.o | -lc | -lgcc* | -lSystem | -libmil | -little \
	  |-LANG:=* | -LIST:* | -LNO:* | -link)
	  ;;
	-lkernel32)
	  case $host_os in
	  *cygwin*) ;;
	  *) ac_cv_[]_AC_LANG_ABBREV[]_libs="$ac_cv_[]_AC_LANG_ABBREV[]_libs $ac_arg"
	    ;;
	  esac
	  ;;
	-[[LRuYz]])
	  # These flags, when seen by themselves, take an argument.
	  # We remove the space between option and argument and re-iterate
	  # unless we find an empty arg or a new option (starting with -)
	  case $[2] in
	     "" | -*);;
	     *)
		ac_arg="$ac_arg$[2]"
		shift; shift
		set X $ac_arg "$[@]"
		;;
	  esac
	  ;;
	-YP,*)
	  for ac_j in `AS_ECHO(["$ac_arg"]) | sed -e 's/-YP,/-L/;s/:/ -L/g'`; do
	    _AC_LIST_MEMBER_IF($ac_j, $ac_cv_[]_AC_LANG_ABBREV[]_libs, ,
			       [ac_arg="$ac_arg $ac_j"
			       ac_cv_[]_AC_LANG_ABBREV[]_libs="$ac_cv_[]_AC_LANG_ABBREV[]_libs $ac_j"])
	  done
	  ;;
	-[[lLR]]*)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_[]_AC_LANG_ABBREV[]_libs, ,
			     ac_cv_[]_AC_LANG_ABBREV[]_libs="$ac_cv_[]_AC_LANG_ABBREV[]_libs $ac_arg")
	  ;;
	-zallextract*| -zdefaultextract)
	  ac_cv_[]_AC_LANG_ABBREV[]_libs="$ac_cv_[]_AC_LANG_ABBREV[]_libs $ac_arg"
	  ;;
	  # Ignore everything else.
  esac
done
# restore positional arguments
set X $ac_save_positional; shift

# We only consider "LD_RUN_PATH" on Solaris systems.  If this is seen,
# then we insist that the "run path" must be an absolute path (i.e. it
# must begin with a "/").
case `(uname -sr) 2>/dev/null` in
   "SunOS 5"*)
      ac_ld_run_path=`AS_ECHO(["$ac_[]_AC_LANG_ABBREV[]_v_output"]) |
			sed -n 's,^.*LD_RUN_PATH *= *\(/[[^ ]]*\).*$,-R\1,p'`
      test "x$ac_ld_run_path" != x &&
	_AC_LINKER_OPTION([$ac_ld_run_path], ac_cv_[]_AC_LANG_ABBREV[]_libs)
      ;;
esac
fi # test "x$[]_AC_LANG_PREFIX[]LIBS" = "x"
])
[]_AC_LANG_PREFIX[]LIBS="$ac_cv_[]_AC_LANG_ABBREV[]_libs"
AC_SUBST([]_AC_LANG_PREFIX[]LIBS)
])# _AC_FC_LIBRARY_LDFLAGS


# AC_F77_LIBRARY_LDFLAGS
# ----------------------
AC_DEFUN([AC_F77_LIBRARY_LDFLAGS],
[AC_REQUIRE([AC_PROG_F77])dnl
AC_LANG_PUSH(Fortran 77)dnl
_AC_FC_LIBRARY_LDFLAGS
AC_LANG_POP(Fortran 77)dnl
])# AC_F77_LIBRARY_LDFLAGS


# AC_FC_LIBRARY_LDFLAGS
# ---------------------
AC_DEFUN([AC_FC_LIBRARY_LDFLAGS],
[AC_REQUIRE([AC_PROG_FC])dnl
AC_LANG_PUSH(Fortran)dnl
_AC_FC_LIBRARY_LDFLAGS
AC_LANG_POP(Fortran)dnl
])# AC_FC_LIBRARY_LDFLAGS


# _AC_FC_DUMMY_MAIN([ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# -----------------------------------------------------------
#
# Detect name of dummy main routine required by the Fortran libraries,
# (if any) and define {F77,FC}_DUMMY_MAIN to this name (which should be
# used for a dummy declaration, if it is defined).  On some systems,
# linking a C program to the Fortran library does not work unless you
# supply a dummy function called something like MAIN__.
#
# Execute ACTION-IF-NOT-FOUND if no way of successfully linking a C
# program with the {F77,FC} libs is found; default to exiting with an error
# message.  Execute ACTION-IF-FOUND if a dummy routine name is needed
# and found or if it is not needed (default to defining {F77,FC}_DUMMY_MAIN
# when needed).
#
# What is technically happening is that the Fortran libraries provide
# their own main() function, which usually initializes Fortran I/O and
# similar stuff, and then calls MAIN__, which is the entry point of
# your program.  Usually, a C program will override this with its own
# main() routine, but the linker sometimes complain if you don't
# provide a dummy (never-called) MAIN__ routine anyway.
#
# Of course, programs that want to allow Fortran subroutines to do
# I/O, etcetera, should call their main routine MAIN__() (or whatever)
# instead of main().  A separate autoconf test (_AC_FC_MAIN) checks
# for the routine to use in this case (since the semantics of the test
# are slightly different).  To link to e.g. purely numerical
# libraries, this is normally not necessary, however, and most C/C++
# programs are reluctant to turn over so much control to Fortran.  =)
#
# The name variants we check for are (in order):
#   MAIN__ (g77, MAIN__ required on some systems; IRIX, MAIN__ optional)
#   MAIN_, __main (SunOS)
#   MAIN _MAIN __MAIN main_ main__ _main (we follow DDD and try these too)
AC_DEFUN([_AC_FC_DUMMY_MAIN],
[_AC_FORTRAN_ASSERT()dnl
m4_define(_AC_LANG_PROGRAM_C_[]_AC_FC[]_HOOKS,
[#ifdef ]_AC_FC[_DUMMY_MAIN
]AC_LANG_CASE([Fortran], [#ifndef FC_DUMMY_MAIN_EQ_F77])
[#  ifdef __cplusplus
     extern "C"
#  endif
   int ]_AC_FC[_DUMMY_MAIN() { return 1; }
]AC_LANG_CASE([Fortran], [#endif])
[#endif
])
AC_CACHE_CHECK([for dummy main to link with _AC_LANG libraries],
	       ac_cv_[]_AC_LANG_ABBREV[]_dummy_main,
[ac_[]_AC_LANG_ABBREV[]_dm_save_LIBS=$LIBS
 LIBS="$LIBS $[]_AC_LANG_PREFIX[]LIBS"
 ac_fortran_dm_var=[]_AC_FC[]_DUMMY_MAIN
 AC_LANG_PUSH(C)dnl

 # First, try linking without a dummy main:
 AC_LINK_IFELSE([AC_LANG_PROGRAM([], [])],
		[ac_cv_fortran_dummy_main=none],
		[ac_cv_fortran_dummy_main=unknown])

 if test $ac_cv_fortran_dummy_main = unknown; then
   for ac_func in MAIN__ MAIN_ __main MAIN _MAIN __MAIN main_ main__ _main; do
     AC_LINK_IFELSE([AC_LANG_PROGRAM([[@%:@define $ac_fortran_dm_var $ac_func]])],
		    [ac_cv_fortran_dummy_main=$ac_func; break])
   done
 fi
 AC_LANG_POP(C)dnl
 ac_cv_[]_AC_LANG_ABBREV[]_dummy_main=$ac_cv_fortran_dummy_main
 rm -rf conftest*
 LIBS=$ac_[]_AC_LANG_ABBREV[]_dm_save_LIBS
])
[]_AC_FC[]_DUMMY_MAIN=$ac_cv_[]_AC_LANG_ABBREV[]_dummy_main
AS_IF([test "$[]_AC_FC[]_DUMMY_MAIN" != unknown],
      [m4_default([$1],
[if test $[]_AC_FC[]_DUMMY_MAIN != none; then
  AC_DEFINE_UNQUOTED([]_AC_FC[]_DUMMY_MAIN, $[]_AC_FC[]_DUMMY_MAIN,
		     [Define to dummy `main' function (if any) required to
		      link to the Fortran libraries.])
  if test "x$ac_cv_fc_dummy_main" = "x$ac_cv_f77_dummy_main"; then
	AC_DEFINE([FC_DUMMY_MAIN_EQ_F77], 1,
		  [Define if F77 and FC dummy `main' functions are identical.])
  fi
fi])],
      [m4_default([$2],
	    [AC_MSG_FAILURE([linking to Fortran libraries from C fails])])])
])# _AC_FC_DUMMY_MAIN


# AC_F77_DUMMY_MAIN
# -----------------
AC_DEFUN([AC_F77_DUMMY_MAIN],
[AC_REQUIRE([AC_F77_LIBRARY_LDFLAGS])dnl
AC_LANG_PUSH(Fortran 77)dnl
_AC_FC_DUMMY_MAIN($@)
AC_LANG_POP(Fortran 77)dnl
])# AC_F77_DUMMY_MAIN


# AC_FC_DUMMY_MAIN
# ----------------
AC_DEFUN([AC_FC_DUMMY_MAIN],
[AC_REQUIRE([AC_FC_LIBRARY_LDFLAGS])dnl
AC_LANG_PUSH(Fortran)dnl
_AC_FC_DUMMY_MAIN($@)
AC_LANG_POP(Fortran)dnl
])# AC_FC_DUMMY_MAIN


# _AC_FC_MAIN
# -----------
# Define {F77,FC}_MAIN to name of alternate main() function for use with
# the Fortran libraries.  (Typically, the libraries may define their
# own main() to initialize I/O, etcetera, that then call your own
# routine called MAIN__ or whatever.)  See _AC_FC_DUMMY_MAIN, above.
# If no such alternate name is found, just define {F77,FC}_MAIN to main.
#
AC_DEFUN([_AC_FC_MAIN],
[_AC_FORTRAN_ASSERT()dnl
AC_CACHE_CHECK([for alternate main to link with _AC_LANG libraries],
	       ac_cv_[]_AC_LANG_ABBREV[]_main,
[ac_[]_AC_LANG_ABBREV[]_m_save_LIBS=$LIBS
 LIBS="$LIBS $[]_AC_LANG_PREFIX[]LIBS"
 ac_fortran_dm_var=[]_AC_FC[]_DUMMY_MAIN
 AC_LANG_PUSH(C)dnl
 ac_cv_fortran_main="main" # default entry point name
 for ac_func in MAIN__ MAIN_ __main MAIN _MAIN __MAIN main_ main__ _main; do
   AC_LINK_IFELSE([AC_LANG_PROGRAM([@%:@ifdef FC_DUMMY_MAIN_EQ_F77
@%:@  undef F77_DUMMY_MAIN
@%:@  undef FC_DUMMY_MAIN
@%:@else
@%:@  undef $ac_fortran_dm_var
@%:@endif
@%:@define main $ac_func])],
		  [ac_cv_fortran_main=$ac_func; break])
 done
 AC_LANG_POP(C)dnl
 ac_cv_[]_AC_LANG_ABBREV[]_main=$ac_cv_fortran_main
 rm -rf conftest*
 LIBS=$ac_[]_AC_LANG_ABBREV[]_m_save_LIBS
])
if test "$ac_cv_[]_AC_LANG_ABBREV[]_main" != "main"; then
   AC_DEFINE(HAVE_[]_AC_FC[]_MAIN, 1, [True when Fortran main isn't C main])
fi
AC_DEFINE_UNQUOTED([]_AC_FC[]_MAIN, $ac_cv_[]_AC_LANG_ABBREV[]_main,
		   [Define to alternate name for `main' routine that is
		    called from a `main' in the Fortran libraries.])
])# _AC_FC_MAIN


# AC_F77_MAIN
# -----------
AC_DEFUN([AC_F77_MAIN],
[AC_REQUIRE([AC_F77_LIBRARY_LDFLAGS])dnl
AC_LANG_PUSH(Fortran 77)dnl
_AC_FC_MAIN
AC_LANG_POP(Fortran 77)dnl
])# AC_F77_MAIN


# AC_FC_MAIN
# ----------
AC_DEFUN([AC_FC_MAIN],
[AC_REQUIRE([AC_FC_LIBRARY_LDFLAGS])dnl
AC_LANG_PUSH(Fortran)dnl
_AC_FC_MAIN
AC_LANG_POP(Fortran)dnl
])# AC_FC_MAIN


# __AC_FC_NAME_MANGLING
# ---------------------
# Test for the name mangling scheme used by the Fortran compiler.
#
# Sets ac_cv_{f77,fc}_mangling. The value contains three fields, separated
# by commas:
#
# lower case / upper case:
#    case translation of the Fortran symbols
# underscore / no underscore:
#    whether the compiler appends "_" to symbol names
# extra underscore / no extra underscore:
#    whether the compiler appends an extra "_" to symbol names already
#    containing at least one underscore
#
AC_DEFUN([__AC_FC_NAME_MANGLING],
[_AC_FORTRAN_ASSERT()dnl
AC_CACHE_CHECK([for _AC_LANG name-mangling scheme],
	       ac_cv_[]_AC_LANG_ABBREV[]_mangling,
[AC_COMPILE_IFELSE(
[[      subroutine foobar()
      return
      end
      subroutine foo_bar()
      return
      end]],
[mv conftest.$ac_objext cfortran_test.$ac_objext

  ac_save_LIBS=$LIBS
  LIBS="cfortran_test.$ac_objext $LIBS $[]_AC_LANG_PREFIX[]LIBS"

  AC_LANG_PUSH(C)dnl
  ac_success=no
  for ac_foobar in foobar FOOBAR; do
    for ac_underscore in "" "_"; do
      ac_func="$ac_foobar$ac_underscore"
      AC_LINK_IFELSE([AC_LANG_CALL([], [$ac_func])],
		     [ac_success=yes; break 2])
    done
  done
  AC_LANG_POP(C)dnl

  if test "$ac_success" = "yes"; then
     case $ac_foobar in
	foobar)
	   ac_case=lower
	   ac_foo_bar=foo_bar
	   ;;
	FOOBAR)
	   ac_case=upper
	   ac_foo_bar=FOO_BAR
	   ;;
     esac

     AC_LANG_PUSH(C)dnl
     ac_success_extra=no
     for ac_extra in "" "_"; do
	ac_func="$ac_foo_bar$ac_underscore$ac_extra"
	AC_LINK_IFELSE([AC_LANG_CALL([], [$ac_func])],
		       [ac_success_extra=yes; break])
     done
     AC_LANG_POP(C)dnl

     if test "$ac_success_extra" = "yes"; then
	ac_cv_[]_AC_LANG_ABBREV[]_mangling="$ac_case case"
	if test -z "$ac_underscore"; then
	   ac_cv_[]_AC_LANG_ABBREV[]_mangling="$ac_cv_[]_AC_LANG_ABBREV[]_mangling, no underscore"
	else
	   ac_cv_[]_AC_LANG_ABBREV[]_mangling="$ac_cv_[]_AC_LANG_ABBREV[]_mangling, underscore"
	fi
	if test -z "$ac_extra"; then
	   ac_cv_[]_AC_LANG_ABBREV[]_mangling="$ac_cv_[]_AC_LANG_ABBREV[]_mangling, no extra underscore"
	else
	   ac_cv_[]_AC_LANG_ABBREV[]_mangling="$ac_cv_[]_AC_LANG_ABBREV[]_mangling, extra underscore"
	fi
      else
	ac_cv_[]_AC_LANG_ABBREV[]_mangling="unknown"
      fi
  else
     ac_cv_[]_AC_LANG_ABBREV[]_mangling="unknown"
  fi

  LIBS=$ac_save_LIBS
  rm -rf conftest*
  rm -f cfortran_test*],
  [AC_MSG_FAILURE([cannot compile a simple Fortran program])])
])
])# __AC_FC_NAME_MANGLING

# The replacement is empty.
AU_DEFUN([AC_F77_NAME_MANGLING], [])


# _AC_F77_NAME_MANGLING
# ---------------------
AC_DEFUN([_AC_F77_NAME_MANGLING],
[AC_REQUIRE([AC_F77_LIBRARY_LDFLAGS])dnl
AC_REQUIRE([AC_F77_DUMMY_MAIN])dnl
AC_LANG_PUSH(Fortran 77)dnl
__AC_FC_NAME_MANGLING
AC_LANG_POP(Fortran 77)dnl
])# _AC_F77_NAME_MANGLING


# _AC_FC_NAME_MANGLING
# --------------------
AC_DEFUN([_AC_FC_NAME_MANGLING],
[AC_REQUIRE([AC_FC_LIBRARY_LDFLAGS])dnl
AC_REQUIRE([AC_FC_DUMMY_MAIN])dnl
AC_LANG_PUSH(Fortran)dnl
__AC_FC_NAME_MANGLING
AC_LANG_POP(Fortran)dnl
])# _AC_FC_NAME_MANGLING


# _AC_FC_WRAPPERS
# ---------------
# Defines C macros {F77,FC}_FUNC(name,NAME) and {F77,FC}_FUNC_(name,NAME) to
# properly mangle the names of C identifiers, and C identifiers with
# underscores, respectively, so that they match the name mangling
# scheme used by the Fortran compiler.
AC_DEFUN([_AC_FC_WRAPPERS],
[_AC_FORTRAN_ASSERT()dnl
AH_TEMPLATE(_AC_FC[_FUNC],
    [Define to a macro mangling the given C identifier (in lower and upper
     case), which must not contain underscores, for linking with Fortran.])dnl
AH_TEMPLATE(_AC_FC[_FUNC_],
    [As ]_AC_FC[_FUNC, but for C identifiers containing underscores.])dnl
case $ac_cv_[]_AC_LANG_ABBREV[]_mangling in
  "lower case, no underscore, no extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [name])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [name]) ;;
  "lower case, no underscore, extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [name])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [name [##] _]) ;;
  "lower case, underscore, no extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [name [##] _])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [name [##] _]) ;;
  "lower case, underscore, extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [name [##] _])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [name [##] __]) ;;
  "upper case, no underscore, no extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [NAME])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [NAME]) ;;
  "upper case, no underscore, extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [NAME])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [NAME [##] _]) ;;
  "upper case, underscore, no extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [NAME [##] _])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [NAME [##] _]) ;;
  "upper case, underscore, extra underscore")
	  AC_DEFINE(_AC_FC[_FUNC(name,NAME)],  [NAME [##] _])
	  AC_DEFINE(_AC_FC[_FUNC_(name,NAME)], [NAME [##] __]) ;;
  *)
	  AC_MSG_WARN([unknown Fortran name-mangling scheme])
	  ;;
esac
])# _AC_FC_WRAPPERS


# AC_F77_WRAPPERS
# ---------------
AC_DEFUN([AC_F77_WRAPPERS],
[AC_REQUIRE([_AC_F77_NAME_MANGLING])dnl
AC_LANG_PUSH(Fortran 77)dnl
_AC_FC_WRAPPERS
AC_LANG_POP(Fortran 77)dnl
])# AC_F77_WRAPPERS


# AC_FC_WRAPPERS
# --------------
AC_DEFUN([AC_FC_WRAPPERS],
[AC_REQUIRE([_AC_FC_NAME_MANGLING])dnl
AC_LANG_PUSH(Fortran)dnl
_AC_FC_WRAPPERS
AC_LANG_POP(Fortran)dnl
])# AC_FC_WRAPPERS


# _AC_FC_FUNC(NAME, [SHELLVAR = NAME])
# ------------------------------------
# For a Fortran subroutine of given NAME, define a shell variable
# $SHELLVAR to the Fortran-mangled name.  If the SHELLVAR
# argument is not supplied, it defaults to NAME.
AC_DEFUN([_AC_FC_FUNC],
[_AC_FORTRAN_ASSERT()dnl
case $ac_cv_[]_AC_LANG_ABBREV[]_mangling in
  upper*) ac_val="m4_toupper([$1])" ;;
  lower*) ac_val="m4_tolower([$1])" ;;
  *)      ac_val="unknown" ;;
esac
case $ac_cv_[]_AC_LANG_ABBREV[]_mangling in *," underscore"*) ac_val="$ac_val"_ ;; esac
m4_if(m4_index([$1],[_]),-1,[],
[case $ac_cv_[]_AC_LANG_ABBREV[]_mangling in *," extra underscore"*) ac_val="$ac_val"_ ;; esac
])
m4_default([$2],[$1])="$ac_val"
])# _AC_FC_FUNC


# AC_F77_FUNC(NAME, [SHELLVAR = NAME])
# ------------------------------------
AC_DEFUN([AC_F77_FUNC],
[AC_REQUIRE([_AC_F77_NAME_MANGLING])dnl
AC_LANG_PUSH(Fortran 77)dnl
_AC_FC_FUNC([$1],[$2])
AC_LANG_POP(Fortran 77)dnl
])# AC_F77_FUNC


# AC_FC_FUNC(NAME, [SHELLVAR = NAME])
# -----------------------------------
AC_DEFUN([AC_FC_FUNC],
[AC_REQUIRE([_AC_FC_NAME_MANGLING])dnl
AC_LANG_PUSH(Fortran)dnl
_AC_FC_FUNC([$1],[$2])
AC_LANG_POP(Fortran)dnl
])# AC_FC_FUNC


# AC_FC_SRCEXT(EXT, [ACTION-IF-SUCCESS], [ACTION-IF-FAILURE])
# -----------------------------------------------------------
# Set the source-code extension used in Fortran (FC) tests to EXT (which
# defaults to f).  Also, look for any necessary additional FCFLAGS needed
# to allow this extension, and store them in the output variable
# FCFLAGS_<EXT> (e.g. FCFLAGS_f90 for EXT=f90).  If successful,
# call ACTION-IF-SUCCESS.  If unable to compile source code with EXT,
# call ACTION-IF-FAILURE, which defaults to failing with an error
# message.
#
# (The flags for the current source-code extension, if any, are stored in
# $ac_fcflags_srcext and used automatically in subsequent autoconf tests.)
#
# For ordinary extensions like f90, etcetera, the modified FCFLAGS
# are currently needed for IBM's xlf* and Intel's ifc (grrr).  Unfortunately,
# xlf* will only take flags to recognize one extension at a time, so if the
# user wants to compile multiple extensions (.f90 and .f95, say), she
# will need to use the FCFLAGS_F90 and FCFLAGS_F95 individually rather
# than just adding them all to FCFLAGS, for example.
#
# Also, for Intel's ifc compiler (which does not accept .f95 by default in
# some versions), the $FCFLAGS_<EXT> variable *must* go immediately before
# the source file on the command line, unlike other $FCFLAGS.  Ugh.
#
# gfortran requires '-x f77' in order to recognize .f77 files.
AC_DEFUN([AC_FC_SRCEXT],
[AC_LANG_PUSH(Fortran)dnl
AC_CACHE_CHECK([for Fortran flag to compile .$1 files],
		ac_cv_fc_srcext_$1,
[ac_ext=$1
ac_fcflags_srcext_save=$ac_fcflags_srcext
ac_fcflags_srcext=
ac_cv_fc_srcext_$1=unknown
case $ac_ext in #(
  [[fF]]77) ac_try=f77;; #(
  *) ac_try=f95;;
esac
for ac_flag in none -qsuffix=f=$1 -Tf "-x $ac_try"; do
  test "x$ac_flag" != xnone && ac_fcflags_srcext="$ac_flag"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM()], [ac_cv_fc_srcext_$1=$ac_flag; break])
done
rm -f conftest.$ac_objext conftest.$1
ac_fcflags_srcext=$ac_fcflags_srcext_save
])
if test "x$ac_cv_fc_srcext_$1" = xunknown; then
  m4_default([$3],[AC_MSG_ERROR([Fortran could not compile .$1 files])])
else
  ac_fc_srcext=$1
  if test "x$ac_cv_fc_srcext_$1" = xnone; then
    ac_fcflags_srcext=""
    FCFLAGS_[]$1[]="$FCFLAGS_[]$1[]"
  else
    ac_fcflags_srcext=$ac_cv_fc_srcext_$1
    FCFLAGS_[]$1[]="$FCFLAGS_[]$1[] $ac_cv_fc_srcext_$1"
  fi
  AC_SUBST(FCFLAGS_[]$1)
  $2
fi
AC_LANG_POP(Fortran)dnl
])# AC_FC_SRCEXT

# AC_FPP_SRCEXT(EXT, [ACTION-IF-SUCCESS], [ACTION-IF-FAILURE])
# -----------------------------------------------------------
# Set the source-code extension used in Fortran (FPP) tests to EXT (which
# defaults to f).  Also, look for any necessary additional FPPFLAGS needed
# to allow this extension, and store them in the output variable
# FPPFLAGS_<EXT> (e.g. FPPFLAGS_f90 for EXT=f90).  If successful,
# call ACTION-IF-SUCCESS.  If unable to compile source code with EXT,
# call ACTION-IF-FAILURE, which defaults to failing with an error
# message.
#
# (The flags for the current source-code extension, if any, are stored
# in the FPPFLAGS_SRCEXT variable and are automatically used in subsequent
# autoconf tests.)
#
# For ordinary extensions like f90, etcetera, the modified FPPFLAGS
# are currently needed for IBM's xlf* and Intel's ifc (grrr).  Unfortunately,
# xlf* will only take flags to recognize one extension at a time, so if the
# user wants to compile multiple extensions (.f90 and .f95, say), she
# will need to use the FPPFLAGS_F90 and FPPFLAGS_F95 individually rather
# than just adding them all to FPPFLAGS, for example.
#
# Also, for Intel's ifc compiler (which does not accept .f95 by default in
# some versions), the $FPPFLAGS_<EXT> variable *must* go immediately before
# the source file on the command line, unlike other $FPPFLAGS.  Ugh.
#
#
# The problem with this is ... we are doing this in order to find what
# flag must be passed to the compiler to compile a preprocessed file;
# but we haven't (or need not have) constructed the ac_fpp_compile
# variable yet. Thus we must check to see first if we know how to compile
# preprocessed source, and otherwise pretend that we're compiling normal
# Fortran.
#
# The (other) problem is that flags may be different for preprocessed
# free form, and preprocessed fixed form, source. This is true for
# the xlf compiler, but this can be faked by treating the free/fixed
# form question and the fpp/nofpp question separately, and adding both
# to F(C|PP)FLAGS_SRCEXT. This requires good behaviour on the part of
# automake or the package maintainer though. It really ought to be
# fixed at some point.
#
# For the moment, the flags we test for are:
#       <none> : rely on current source extension
# -qsuffix=cpp : xlf
#         -cpp : Tru64, (some versions of) Intel Fortran
#         -fpp : NAG, (some versions of) Intel Fortran
#  -lfe "-Cpp" : Lahey (undocumented)
AC_DEFUN([AC_FPP_SRCEXT],
[dnl
AC_CACHE_CHECK([for Fortran flag to compile preprocessable .$1 files],
                ac_cv_fpp_srcext_$1,
[ac_ext=$1
ac_fpp_srcext_FPPFLAGS_SRCEXT_save=$FPPFLAGS_SRCEXT
FPPFLAGS_SRCEXT=""
ac_cv_fpp_srcext_$1=unknown
for ac_flag in none -qsuffix=cpp=$1 -cpp -fpp '-lfe "-Cpp"'; do
 test "x$ac_flag" != xnone && FPPFLAGS_SRCEXT="$ac_flag"
  if test "x$ac_cv_fpp_build_rule" = x; then
     # We're probably being called from AC_FPP_PROG. We don't know
     # how to compile fpp programs yet.
     AC_LANG_PUSH([Fortran])
     ## Force ac_ext to be the extension we're testing, carefully
     ## ignoring the one defaulted in the statement above.
     ac_ext=$1
     AC_COMPILE_IFELSE([AC_LANG_PROGRAM()], [ac_cv_fpp_srcext_$1=$ac_flag; break])
     AC_LANG_POP([Fortran])
  else
     # We already know what ac_fpp_compile etc. are:
     AC_LANG_PUSH([Preprocessed Fortran])
     ac_ext=$1
     AC_COMPILE_IFELSE([
      program main
#if 1
      end
#endif
],   [ac_cv_fpp_srcext_$1=$ac_flag; break])
     AC_LANG_POP([Preprocessed Fortran])
  fi
done
rm -f conftest.$ac_objext conftest.$1
FPPFLAGS_SRCEXT=$ac_fpp_srcext_FPPFLAGS_SRCEXT_save
])
if test "x$ac_cv_fpp_srcext_$1" = xunknown; then
  m4_default([$3],[AC_MSG_ERROR([Fortran could not compile .$1 files])])
else
  FPP_SRCEXT=$1
  if test "x$ac_cv_fpp_srcext_$1" = xnone; then
    FPPFLAGS_SRCEXT=""
    FPPFLAGS_[]$1[]="$FPPFLAGS_[]$1[]"
  else
    FPPFLAGS_SRCEXT=$ac_cv_fpp_srcext_[]$1
    FPPFLAGS_[]$1[]="$FPPFLAGS_[]$1[] $ac_cv_fpp_srcext_[]$1"
  fi
AC_SUBST(FPPFLAGS_[]$1)
  $2
fi
])# AC_FPP_SRCEXT

# AC_FC_PP_SRCEXT(EXT, [ACTION-IF-SUCCESS], [ACTION-IF-FAILURE])
# --------------------------------------------------------------
# Like AC_FC_SRCEXT, set the source-code extension used in Fortran (FC) tests
# to EXT (which defaults to f).  Also, look for any necessary additional
# FCFLAGS needed to allow this extension for preprocessed Fortran, and store
# them in the output variable FCFLAGS_<EXT> (e.g. FCFLAGS_f90 for EXT=f90).
# If successful, call ACTION-IF-SUCCESS.  If unable to compile preprocessed
# source code with EXT, call ACTION-IF-FAILURE, which defaults to failing with
# an error message.
#
# Some compilers allow preprocessing with either a Fortran preprocessor or
# with the C preprocessor (cpp).  Prefer the Fortran preprocessor, to deal
# correctly with continuation lines, `//' (not a comment), and preserve white
# space (for fixed form).
#
# (The flags for the current source-code extension, if any, are stored in
# $ac_fcflags_srcext and used automatically in subsequent autoconf tests.)
#
# For ordinary extensions like f90, etcetera, the modified FCFLAGS
# are needed for IBM's xlf*.  Also, for Intel's ifort compiler, the
# $FCFLAGS_<EXT> variable *must* go immediately before the source file on the
# command line, unlike other $FCFLAGS.  Ugh.
#
# Known extensions that enable preprocessing by default, and flags to force it:
# GNU: .F .F90 .F95 .F03 .F08, -cpp for most others,
#      -x f77-cpp-input for .f77 .F77; -x f95-cpp-input for gfortran < 4.4
# SGI: .F .F90, -ftpp or -cpp for .f .f90, -E write preproc to stdout
#      -macro_expand enable macro expansion everywhere (with -ftpp)
#      -P preproc only, save in .i, no #line's
# SUN: .F .F95, -fpp for others; -xpp={fpp,cpp} for preprocessor selection
#      -F preprocess only (save in lowercase extension)
# IBM: .F .F77 .F90 .F95 .F03, -qsuffix=cpp=EXT for extension .EXT to invoke cpp
#      -WF,-qnofpp -WF,-qfpp=comment:linecont:nocomment:nolinecont
#      -WF,-qlanglvl=classic or not -qnoescape (trigraph problems)
#      -d no #line in output, -qnoobject for preprocessing only (output in .f)
#      -q{no,}ppsuborigarg substitute original macro args before expansion
# HP:  .F, +cpp={yes|no|default} use cpp, -cpp, +cpp_keep save in .i/.i90
# PGI: -Mpreprocess
# Absoft: .F .FOR .F90 .F95, -cpp for others
# Cray: .F .F90 .FTN, -e Z for others; -F enable macro expansion everywhere
# Intel: .F .F90, -fpp for others, but except for .f and .f90, -Tf may also be
#        needed right before the source file name
# PathScale: .F .F90 .F95, -ftpp or -cpp for .f .f90 .f95
#         -macro_expand for expansion everywhere, -P for no #line in output
# Lahey: .F .FOR .F90 .F95, -Cpp
# NAGWare: .F .F90 .F95, .ff .ff90 .ff95 (new), -fpp for others
# Compaq/Tru64: .F .F90, -cpp, -P keep .i file, -P keep .i file
# f2c: .F, -cpp
# g95: .F .FOR .F90 .F95 .F03, -cpp -no-cpp, -E for stdout
AC_DEFUN([AC_FC_PP_SRCEXT],
[AC_LANG_PUSH(Fortran)dnl
AC_CACHE_CHECK([for Fortran flag to compile preprocessed .$1 files],
		ac_cv_fc_pp_srcext_$1,
[ac_ext=$1
ac_fcflags_pp_srcext_save=$ac_fcflags_srcext
ac_fcflags_srcext=
ac_cv_fc_pp_srcext_$1=unknown
case $ac_ext in #(
  [[fF]]77) ac_try=f77-cpp-input;; #(
  *) ac_try=f95-cpp-input;;
esac
for ac_flag in none -ftpp -fpp -Tf "-fpp -Tf" -xpp=fpp -Mpreprocess "-e Z" \
               -cpp -xpp=cpp -qsuffix=cpp=$1 "-x $ac_try" +cpp -Cpp; do
  test "x$ac_flag" != xnone && ac_fcflags_srcext="$ac_flag"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[
#if 0
#include <ac_nonexistent.h>
      choke me
#endif]])],
    [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[
#if 1
#include <ac_nonexistent.h>
      choke me
#endif]])],
       [],
       [ac_cv_fc_pp_srcext_$1=$ac_flag; break])])
done
rm -f conftest.$ac_objext conftest.$1
ac_fcflags_srcext=$ac_fcflags_pp_srcext_save
])
if test "x$ac_cv_fc_pp_srcext_$1" = xunknown; then
  m4_default([$3],
             [AC_MSG_ERROR([Fortran could not compile preprocessed .$1 files])])
else
  ac_fc_srcext=$1
  if test "x$ac_cv_fc_pp_srcext_$1" = xnone; then
    ac_fcflags_srcext=""
    FCFLAGS_[]$1[]=""
  else
    ac_fcflags_srcext=$ac_cv_fc_pp_srcext_$1
    FCFLAGS_[]$1[]=$ac_cv_fc_pp_srcext_$1
  fi
  AC_SUBST(FCFLAGS_[]$1)
  $2
fi
AC_LANG_POP(Fortran)dnl
])# AC_FC_PP_SRCEXT


# AC_FC_PP_DEFINE([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# -------------------------------------------------------------------
# Find a flag to specify defines for preprocessed Fortran.  Not all
# Fortran compilers use -D.  Substitute FC_DEFINE with the result and
# call ACTION-IF-SUCCESS (defaults to nothing) if successful, and
# ACTION-IF-FAILURE (defaults to failing with an error message) if not.
#
# Known flags:
# IBM: -WF,-D
# Lahey/Fujitsu: -Wp,-D     older versions???
# f2c: -D or -Wc,-D
# others: -D
AC_DEFUN([AC_FC_PP_DEFINE],
[AC_LANG_PUSH([Fortran])dnl
ac_fc_pp_define_srcext_save=$ac_fc_srcext
AC_FC_PP_SRCEXT([F])
AC_CACHE_CHECK([how to define symbols for preprocessed Fortran],
  [ac_cv_fc_pp_define],
[ac_fc_pp_define_srcext_save=$ac_fc_srcext
ac_cv_fc_pp_define=unknown
ac_fc_pp_define_FCFLAGS_save=$FCFLAGS
for ac_flag in -D -WF,-D -Wp,-D -Wc,-D
do
  FCFLAGS="$ac_fc_pp_define_FCFLAGS_save ${ac_flag}FOOBAR ${ac_flag}ZORK=42"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[
#ifndef FOOBAR
      choke me
#endif
#if ZORK != 42
      choke me
#endif]])],
    [ac_cv_fc_pp_define=$ac_flag])
  test x"$ac_cv_fc_pp_define" != xunknown && break
done
FCFLAGS=$ac_fc_pp_define_FCFLAGS_save
])
ac_fc_srcext=$ac_fc_pp_define_srcext_save
if test "x$ac_cv_fc_pp_define" = xunknown; then
  FC_DEFINE=
  m4_default([$2],
	     [AC_MSG_ERROR([Fortran does not allow to define preprocessor symbols], 77)])
else
  FC_DEFINE=$ac_cv_fc_pp_define
  $1
fi
AC_SUBST([FC_DEFINE])dnl
AC_LANG_POP([Fortran])dnl
])


# AC_FC_FREEFORM([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ------------------------------------------------------------------
# Look for a compiler flag to make the Fortran (FC) compiler accept
# free-format source code, and adds it to FCFLAGS.  Call
# ACTION-IF-SUCCESS (defaults to nothing) if successful (i.e. can
# compile code using new extension) and ACTION-IF-FAILURE (defaults to
# failing with an error message) if not.  (Defined via DEFUN_ONCE to
# prevent flag from being added to FCFLAGS multiple times.)
#
# The known flags are:
#        -ffree-form: GNU g77, gfortran, g95
#         -FR, -free: Intel compiler (icc, ecc, ifort)
#              -free: Compaq compiler (fort), Sun compiler (f95)
#             -qfree: IBM compiler (xlf) (generates a warning with
#                                         recent versions)
#         -qfree=f90: Newer xlf versions
#             --nfix: Lahey compiler
# -Mfree, -Mfreeform: Portland Group compiler
#          -freeform: SGI compiler
#        -8, -f free: Absoft Fortran
#       +source=free: HP Fortran
#    (-)-nfix, -Free: Lahey/Fujitsu Fortran
#              -free: NAGWare
#         -f, -Wf,-f: f2c (but only a weak form of "free-form" and long lines)
# We try to test the "more popular" flags first, by some prejudiced
# notion of popularity.
AC_DEFUN_ONCE([AC_FC_FREEFORM],
[AC_LANG_PUSH(Fortran)dnl
AC_CACHE_CHECK([for Fortran flag needed to accept free-form source],
	       [ac_cv_fc_freeform],
[ac_cv_fc_freeform=unknown
ac_fc_freeform_FCFLAGS_save=$FCFLAGS
for ac_flag in none -ffree-form -FR -free -qfree "-qfree=f90" -Mfree -Mfreeform \
	       -freeform "-f free" -8 +source=free -nfix --nfix -Free
do
  test "x$ac_flag" != xnone && FCFLAGS="$ac_fc_freeform_FCFLAGS_save $ac_flag"
dnl Use @&t@ below to ensure that editors don't turn 8+ spaces into tab.
  AC_COMPILE_IFELSE([
program freeform
! FIXME: how to best confuse non-freeform compilers?
print *, 'Hello ', &
'world.'
end program],
                    [ac_cv_fc_freeform=$ac_flag; break])
done
rm -f conftest.err conftest.$ac_objext conftest.$ac_ext
FCFLAGS=$ac_fc_freeform_FCFLAGS_save
])
if test "x$ac_cv_fc_freeform" = xunknown; then
  m4_default([$2],
             [AC_MSG_ERROR([Fortran does not accept free-form source], 77)])
else
  if test "x$ac_cv_fc_freeform" != xnone; then
    FCFLAGS_free="$FCFLAGS_free $ac_cv_fc_freeform"
  fi
  $1
fi
AC_LANG_POP([Fortran])dnl
])# AC_FC_FREEFORM

# AC_FC_FIXEDFORM([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ------------------------------------------------------------------
# Look for a compiler flag to make the Fortran (FC) compiler accept
# fixed-format source code, and adds it to FCFLAGS.  Call
# ACTION-IF-SUCCESS (defaults to nothing) if successful (i.e. can
# compile code using new extension) and ACTION-IF-FAILURE (defaults to
# failing with an error message) if not.  (Defined via DEFUN_ONCE to
# prevent flag from being added to FCFLAGS multiple times.)
#
# The known flags are:
#       -ffixed-form: GNU g77, gfortran, g95
#             -fixed: Intel compiler (ifort), Sun compiler (f95)
#            -qfixed: IBM compiler (xlf*)
#            -Mfixed: Portland Group compiler
#         -fixedform: SGI compiler
#           -f fixed: Absoft Fortran
#      +source=fixed: HP Fortran
#    (-)-fix, -Fixed: Lahey/Fujitsu Fortran
#             -fixed: NAGWare
# Since compilers may accept fixed form based on file name extension,
# but users may want to use it with others as well, call AC_FC_SRCEXT
# with the respective source extension before calling this macro.
AC_DEFUN_ONCE([AC_FC_FIXEDFORM],
[AC_LANG_PUSH([Fortran])dnl
AC_CACHE_CHECK([for Fortran flag needed to accept fixed-form source],
	       [ac_cv_fc_fixedform],
[ac_cv_fc_fixedform=unknown
ac_fc_fixedform_FCFLAGS_save=$FCFLAGS
for ac_flag in none -ffixed-form -fixed -qfixed -Mfixed -fixedform "-f fixed" \
	       +source=fixed -fix --fix -Fixed
do
  test "x$ac_flag" != xnone && FCFLAGS="$ac_fc_fixedform_FCFLAGS_save $ac_flag"
  AC_COMPILE_IFELSE([[
C     This comment should confuse free-form compilers.
      program main
      end]],
		    [ac_cv_fc_fixedform=$ac_flag; break])
done
rm -f conftest.err conftest.$ac_objext conftest.$ac_ext
FCFLAGS=$ac_fc_fixedform_FCFLAGS_save
])
if test "x$ac_cv_fc_fixedform" = xunknown; then
  m4_default([$2],
	     [AC_MSG_ERROR([Fortran does not accept fixed-form source], 77)])
else
  if test "x$ac_cv_fc_fixedform" != xnone; then
    FCFLAGS="$FCFLAGS $ac_cv_fc_fixedform"
  fi
  $1
fi
AC_LANG_POP([Fortran])dnl
])# AC_FC_FIXEDFORM

# AC_FC_LINE_LENGTH([LENGTH], [ACTION-IF-SUCCESS],
#		    [ACTION-IF-FAILURE = FAILURE])
# ------------------------------------------------
# Look for a compiler flag to make the Fortran (FC) compiler accept long lines
# in the current (free- or fixed-format) source code, and adds it to FCFLAGS.
# The optional LENGTH may be 80, 132 (default), or `unlimited' for longer
# lines.  Note that line lengths above 254 columns are not portable, and some
# compilers (hello ifort) do not accept more than 132 columns at least for
# fixed format.  Call ACTION-IF-SUCCESS (defaults to nothing) if successful
# (i.e. can compile code using new extension) and ACTION-IF-FAILURE (defaults
# to failing with an error message) if not.  (Defined via DEFUN_ONCE to
# prevent flag from being added to FCFLAGS multiple times.)
# You should call AC_FC_FREEFORM or AC_FC_FIXEDFORM to set the desired format
# prior to using this macro.
#
# The known flags are:
# -f{free,fixed}-line-length-N with N 72, 80, 132, or 0 or none for none.
# -ffree-line-length-none: GNU gfortran
# -ffree-line-length-huge: g95 (also -ffixed-line-length-N as above)
#       -qfixed=132 80 72: IBM compiler (xlf)
#                -Mextend: Cray
#            -132 -80 -72: Intel compiler (ifort)
#                          Needs to come before -extend_source because ifort
#                          accepts that as well with an optional parameter and
#                          doesn't fail but only warns about unknown arguments.
#          -extend_source: SGI compiler
#  -W, -WNN (132, 80, 72): Absoft Fortran
#     +es, +extend_source: HP Fortran (254 in either form, default is 72 fixed,
#			   132 free)
#            -w, (-)-wide: Lahey/Fujitsu Fortran (255 cols in fixed form)
#                      -e: Sun Fortran compiler (132 characters)
#                    -132: NAGWare
#         -72, -f, -Wf,-f: f2c (a weak form of "free-form" and long lines).
#                  /XLine: Open Watcom
AC_DEFUN_ONCE([AC_FC_LINE_LENGTH],
[AC_LANG_PUSH([Fortran])dnl
m4_case(m4_default([$1], [132]),
  [unlimited], [ac_fc_line_len_string=unlimited
	               ac_fc_line_len=0
                       ac_fc_line_length_test='
      subroutine longer_than_132(arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,'\
'arg9,arg10,arg11,arg12,arg13,arg14,arg15,arg16,arg17,arg18,arg19)'],
  [132],            [ac_fc_line_len=132
		       ac_fc_line_length_test='
      subroutine longer_than_80(arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,'\
'arg10)'],
  [80],             [ac_fc_line_len=80
		       ac_fc_line_length_test='
      subroutine longer_than_72(arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)'],
  [m4_warning([Invalid length argument `$1'])])
: ${ac_fc_line_len_string=$ac_fc_line_len}
AC_CACHE_CHECK(
[for Fortran flag needed to accept $ac_fc_line_len_string column source lines],
	       [ac_cv_fc_line_length],
[ac_cv_fc_line_length=unknown
ac_fc_line_length_FCFLAGS_save=$FCFLAGS
for ac_flag in none \
	       -ffree-line-length-none -ffixed-line-length-none \
	       -ffree-line-length-huge \
	       -ffree-line-length-$ac_fc_line_len \
	       -ffixed-line-length-$ac_fc_line_len \
	       -qfixed=$ac_fc_line_len -Mextend \
	       -$ac_fc_line_len -extend_source \
	       -W$ac_fc_line_len -W +extend_source +es -wide --wide -w -e \
               -f -Wf,-f -xline
do
  test "x$ac_flag" != xnone && FCFLAGS="$ac_fc_line_length_FCFLAGS_save $ac_flag"
  AC_COMPILE_IFELSE([[$ac_fc_line_length_test
      end subroutine]],
		    [ac_cv_fc_line_length=$ac_flag; break])
done
rm -f conftest.err conftest.$ac_objext conftest.$ac_ext
FCFLAGS=$ac_fc_line_length_FCFLAGS_save
])
if test "x$ac_cv_fc_line_length" = xunknown; then
  m4_default([$3],
	     [AC_MSG_ERROR([Fortran does not accept long source lines], 77)])
else
  if test "x$ac_cv_fc_line_length" != xnone; then
    FCFLAGS="$FCFLAGS $ac_cv_fc_line_length"
  fi
  $2
fi
AC_LANG_POP([Fortran])dnl
])# AC_FC_LINE_LENGTH

# AC_FC_CHECK_BOUNDS([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ----------------------------------------------------------------------
# Look for a compiler flag to turn on array bounds checking for the
# Fortran (FC) compiler, and adds it to FCFLAGS.  Call
# ACTION-IF-SUCCESS (defaults to nothing) if successful (i.e. can
# compile code using new extension) and ACTION-IF-FAILURE (defaults to
# failing with an error message) if not.  (Defined via DEFUN_ONCE to
# prevent flag from being added to FCFLAGS multiple times.)
#
# The known flags are:
# -fcheck=all, -fbounds-check: gfortran
#     -fbounds-check: g77, g95
# -CB, -check bounds: Intel compiler (icc, ecc, ifort)
#                 -C: Sun/Oracle compiler (f95)
#        -C, -qcheck: IBM compiler (xlf)
#           -Mbounds: Portland Group compiler
#       -C ,-Mbounds: Cray
#  -C, -check_bounds: SGI compiler
# -check_bounds, +check=all: HP Fortran
#        -C, -Rb -Rc: Absoft (-Rb: array boundaries, -Rc: array conformance)
# --chk e,s -chk (e,s): Lahey
#          -C -C=all: NAGWare
# -C, -ffortran-bounds-check: PathScale pathf90
#                 -C: f2c
#            -BOunds: Open Watcom
AC_DEFUN_ONCE([AC_FC_CHECK_BOUNDS],
[AC_LANG_PUSH([Fortran])dnl
AC_CACHE_CHECK([for Fortran flag to enable array-bounds checking],
               [ac_cv_fc_check_bounds],
[ac_cv_fc_check_bounds=unknown
ac_fc_check_bounds_FCFLAGS_save=$FCFLAGS
for ac_flag in -fcheck=bounds -fbounds-check -check_bounds -Mbounds -qcheck \
               '-check bounds' +check=all --check '-Rb -Rc' -CB -C=all -C \
               -ffortran-bounds-check "--chk e,s" "-chk e -chk s" -bounds
do
  FCFLAGS="$ac_fc_check_bounds_FCFLAGS_save $ac_flag"
  # We should be able to link a correct program.
  AC_LINK_IFELSE([AC_LANG_PROGRAM([], [])],
    [AC_LINK_IFELSE([[
      subroutine sub(a)
      integer a(:)
      a(8) = 0
      end subroutine

      program main
      integer a(1:7)
      interface
         subroutine sub(a)
         integer a(:)
         end subroutine
      end interface

      call sub(a)
      end program]],
       [# If we can run the program, require failure at run time.
	# In cross-compiling mode, we rely on the compiler not accepting
	# unknown options.
	AS_IF([test "$cross_compiling" = yes],
	  [ac_cv_fc_check_bounds=$ac_flag; break],
	  [AS_IF([_AC_DO_TOKENS(./conftest$ac_exeext)],
	     [],
	     [ac_cv_fc_check_bounds=$ac_flag; break])])])])
done
rm -f conftest$ac_exeext conftest.err conftest.$ac_objext conftest.$ac_ext \
  core *.core core.conftest.*
FCFLAGS=$ac_fc_check_bounds_FCFLAGS_save
])
if test "x$ac_cv_fc_check_bounds" = xunknown; then
  m4_default([$2],
             [AC_MSG_ERROR([no Fortran flag for bounds checking found], 77)])
else
  if test "x$ac_cv_fc_check_bounds" != xnone; then
    FCFLAGS="$FCFLAGS $ac_cv_fc_check_bounds"
  fi
  $1
fi
AC_LANG_POP([Fortran])dnl
])# AC_FC_CHECK_BOUNDS

# AC_FC_OPEN_SPECIFIERS(specifier ...)
# ------------------------------------
#
# The Fortran OPEN statement is a rich source of portability problems,
# since there are numerous common extensions which consiste of extra
# specifiers, several of which are useful when they are available.
# For each of the specifiers in the (whitespace-separated) argument
# list, define HAVE_FC_OPEN_mungedspecifier if the specifier may be
# given as  argument to the OPEN statement.  The `mungedspecifier' is the
# `specifier' converted to uppercase and with all characters outside
# [a-zA-Z0-9_] deleted.  Note that this may include `specifiers' such
# as "access='append'" and "[access='sequential',recl=1]" (note quoting of
# comma) to check combinations of specifiers.  You may not include a
# space in the `specifier', even quoted.  Each argument must be a
# maximum of 65 characters in length (to abide by Fortran 77
# line-length limits).
#
dnl Multiple m4_quote instances are necessary in case specifier includes comma.
dnl In the Fortran OPEN line, include status='scratch' unless status=???
dnl is in the specifier being tested.
dnl Put specifier on continuation line, in case it's long.
AC_DEFUN([AC_FC_OPEN_SPECIFIERS],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_LANG_PUSH([Fortran])
          AC_FOREACH([Specifier],
                     m4_quote(m4_toupper([$1])),
                     [m4_define([mungedspec],
                                m4_bpatsubst(m4_quote(Specifier), [[^a-zA-Z0-9_]], []))
                      AC_CACHE_CHECK([whether ${FC} supports OPEN specifier ]m4_quote(Specifier),
                          [ac_cv_fc_spec_]mungedspec,
                          [AC_COMPILE_IFELSE(AC_LANG_PROGRAM([],
                                                             [      OPEN(UNIT=99,]m4_if(m4_bregexp(m4_quote(Specifier), [\<STATUS *=]), -1, [STATUS='SCRATCH'[,]], [])
     :m4_quote(Specifier)[)]),
                                             [ac_cv_fc_spec_]mungedspec=yes,
                                             [ac_cv_fc_spec_]mungedspec=no)])
                      if test $ac_cv_fc_spec_[]mungedspec = yes; then
                          AC_DEFINE([HAVE_FC_OPEN_]mungedspec, 1,
                                    [Define to 1 if the Fortran compiler supports OPEN specifier ]m4_quote(Specifier))
                      fi])
           AC_LANG_POP([Fortran])
])# AC_FC_OPEN_SPECIFIERS


# _AC_FC_IMPLICIT_NONE([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ------------------------------------------------------------------------
# Look for a flag to disallow implicit declarations, and add it to FCFLAGS.
# Call ACTION-IF-SUCCESS (defaults to nothing) if successful and
# ACTION-IF-FAILURE (defaults to failing with an error message) if not.
#
# Known flags:
# GNU gfortran, g95: -fimplicit-none, g77: -Wimplicit
# Intel: -u, -implicitnone; might also need '-warn errors' to turn into error.
# Sun/Oracle: -u
# HP: +implicit_none
# IBM: -u, -qundef
# SGI: -u
# Compaq: -u, -warn declarations
# NAGWare: -u
# Lahey: -in, --in, -AT
# Cray: -Mdclchk -e I
# PGI: -Mcdlchk
# f2c: -u
AC_DEFUN([_AC_FC_IMPLICIT_NONE],
[_AC_FORTRAN_ASSERT()dnl
AC_CACHE_CHECK([for flag to disallow _AC_LANG implicit declarations],
               [ac_cv_[]_AC_LANG_ABBREV[]_implicit_none],
[ac_cv_[]_AC_LANG_ABBREV[]_implicit_none=unknown
ac_fc_implicit_none_[]_AC_LANG_PREFIX[]FLAGS_save=$[]_AC_LANG_PREFIX[]FLAGS
for ac_flag in none -fimplicit-none -u -Wimplicit -implicitnone +implicit_none \
               -qundef "-warn declarations" -in --in -AT "-e I" -Mdclchk \
               "-u -warn errors"
do
  if test "x$ac_flag" != xnone; then
    _AC_LANG_PREFIX[]FLAGS="$ac_fc_implicit_none_[]_AC_LANG_PREFIX[]FLAGS_save $ac_flag"
  fi
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [])],
    [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[
      i = 0
      print *, i]])],
       [],
       [ac_cv_[]_AC_LANG_ABBREV[]_implicit_none=$ac_flag; break])])
done
rm -f conftest.err conftest.$ac_objext conftest.$ac_ext
_AC_LANG_PREFIX[]FLAGS=$ac_fc_implicit_none_[]_AC_LANG_PREFIX[]FLAGS_save
])
if test "x$ac_cv_[]_AC_LANG_ABBREV[]_implicit_none" = xunknown; then
  m4_default([$3],
    [AC_MSG_ERROR([no Fortran flag to disallow implicit declarations found], 77)])
else
  if test "x$ac_cv_[]_AC_LANG_ABBREV[]_implicit_none" != xnone; then
    _AC_LANG_PREFIX[]FLAGS="$_AC_LANG_PREFIX[]FLAGS $ac_cv_[]_AC_LANG_ABBREV[]_implicit_none"
  fi
  $2
fi
])# _AC_FC_IMPLICIT_NONE


# AC_F77_IMPLICIT_NONE([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ------------------------------------------------------------------------
AC_DEFUN([AC_F77_IMPLICIT_NONE],
[AC_LANG_PUSH([Fortran 77])dnl
_AC_FC_IMPLICIT_NONE($@)
AC_LANG_POP([Fortran 77])dnl
])# AC_F77_IMPLICIT_NONE


# AC_FC_IMPLICIT_NONE([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# -----------------------------------------------------------------------
AC_DEFUN([AC_FC_IMPLICIT_NONE],
[AC_LANG_PUSH([Fortran])dnl
_AC_FC_IMPLICIT_NONE($@)
AC_LANG_POP([Fortran])dnl
])# AC_FC_IMPLICIT_NONE


# AC_FC_MODULE_EXTENSION
# ----------------------
# Find the Fortran 90 module file extension.  The module extension is stored
# in the variable FC_MODEXT and empty if it cannot be determined.  The result
# or "unknown" is cached in the cache variable ac_cv_fc_module_ext.
AC_DEFUN([AC_FC_MODULE_EXTENSION],
[AC_CACHE_CHECK([Fortran 90 module extension], [ac_cv_fc_module_ext],
[AC_LANG_PUSH(Fortran)
mkdir conftest.dir
cd conftest.dir
ac_cv_fc_module_ext=unknown
AC_COMPILE_IFELSE([[
      module conftest_module
      contains
      subroutine conftest_routine
      write(*,'(a)') 'gotcha!'
      end subroutine
      end module]],
  [ac_cv_fc_module_ext=`ls | sed -n 's,conftest_module\.,,p'`
   if test x$ac_cv_fc_module_ext = x; then
dnl Some F90 compilers use upper case characters for the module file name.
     ac_cv_fc_module_ext=`ls | sed -n 's,CONFTEST_MODULE\.,,p'`
   fi])
cd ..
rm -rf conftest.dir
AC_LANG_POP(Fortran)
])
FC_MODEXT=$ac_cv_fc_module_ext
if test "$FC_MODEXT" = unknown; then
  FC_MODEXT=
fi
AC_SUBST([FC_MODEXT])dnl
])


# AC_FC_MODULE_FLAG([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ---------------------------------------------------------------------
# Find a flag to include Fortran 90 modules from another directory.
# If successful, run ACTION-IF-SUCCESS (defaults to nothing), otherwise
# run ACTION-IF-FAILURE (defaults to failing with an error message).
# The module flag is cached in the ac_cv_fc_module_flag variable.
# It may contain significant trailing whitespace.
#
# Known flags:
# gfortran: -Idir, -I dir (-M dir, -Mdir (deprecated), -Jdir for writing)
# g95: -I dir (-fmod=dir for writing)
# SUN: -Mdir, -M dir (-moddir=dir for writing;
#                     -Idir for includes is also searched)
# HP: -Idir, -I dir (+moddir=dir for writing)
# IBM: -Idir (-qmoddir=dir for writing)
# Intel: -Idir -I dir (-mod dir for writing)
# Absoft: -pdir
# Lahey: -mod dir
# Cray: -module dir, -p dir (-J dir for writing)
#       -e m is needed to enable writing .mod files at all
# Compaq: -Idir
# NAGWare: -I dir
# PathScale: -I dir  (but -module dir is looked at first)
# Portland: -module dir (first -module also names dir for writing)
# Fujitsu: -Am -Idir (-Mdir for writing is searched first, then '.', then -I)
#                    (-Am indicates how module information is saved)
AC_DEFUN([AC_FC_MODULE_FLAG],[
AC_CACHE_CHECK([Fortran 90 module inclusion flag], [ac_cv_fc_module_flag],
[AC_LANG_PUSH([Fortran])
ac_cv_fc_module_flag=unknown
mkdir conftest.dir
cd conftest.dir
AC_COMPILE_IFELSE([[
      module conftest_module
      contains
      subroutine conftest_routine
      write(*,'(a)') 'gotcha!'
      end subroutine
      end module]],
  [cd ..
   ac_fc_module_flag_FCFLAGS_save=$FCFLAGS
   # Flag ordering is significant for gfortran and Sun.
   for ac_flag in -M -I '-I ' '-M ' -p '-mod ' '-module ' '-Am -I'; do
     # Add the flag twice to prevent matching an output flag.
     FCFLAGS="$ac_fc_module_flag_FCFLAGS_save ${ac_flag}conftest.dir ${ac_flag}conftest.dir"
     AC_COMPILE_IFELSE([[
      program main
      use conftest_module
      call conftest_routine
      end program]],
       [ac_cv_fc_module_flag="$ac_flag"])
     if test "$ac_cv_fc_module_flag" != unknown; then
       break
     fi
   done
   FCFLAGS=$ac_fc_module_flag_FCFLAGS_save
])
rm -rf conftest.dir
AC_LANG_POP([Fortran])
])
if test "$ac_cv_fc_module_flag" != unknown; then
  FC_MODINC=$ac_cv_fc_module_flag
  $1
else
  FC_MODINC=
  m4_default([$2],
    [AC_MSG_ERROR([unable to find compiler flag for module search path])])
fi
AC_SUBST([FC_MODINC])
# Ensure trailing whitespace is preserved in a Makefile.
AC_SUBST([ac_empty], [""])
AC_CONFIG_COMMANDS_PRE([case $FC_MODINC in #(
  *\ ) FC_MODINC=$FC_MODINC'${ac_empty}' ;;
esac])dnl
])


# AC_FC_MODULE_OUTPUT_FLAG([ACTION-IF-SUCCESS], [ACTION-IF-FAILURE = FAILURE])
# ----------------------------------------------------------------------------
# Find a flag to write Fortran 90 module information to another directory.
# If successful, run ACTION-IF-SUCCESS (defaults to nothing), otherwise
# run ACTION-IF-FAILURE (defaults to failing with an error message).
# The module flag is cached in the ac_cv_fc_module_output_flag variable.
# It may contain significant trailing whitespace.
#
# For known flags, see the documentation of AC_FC_MODULE_FLAG above.
AC_DEFUN([AC_FC_MODULE_OUTPUT_FLAG],[
AC_CACHE_CHECK([Fortran 90 module output flag], [ac_cv_fc_module_output_flag],
[AC_LANG_PUSH([Fortran])
mkdir conftest.dir conftest.dir/sub
cd conftest.dir
ac_cv_fc_module_output_flag=unknown
ac_fc_module_output_flag_FCFLAGS_save=$FCFLAGS
# Flag ordering is significant: put flags late which some compilers use
# for the search path.
for ac_flag in -J '-J ' -fmod= -moddir= +moddir= -qmoddir= '-mod ' \
	      '-module ' -M '-Am -M' '-e m -J '; do
  FCFLAGS="$ac_fc_module_output_flag_FCFLAGS_save ${ac_flag}sub"
  AC_COMPILE_IFELSE([[
      module conftest_module
      contains
      subroutine conftest_routine
      write(*,'(a)') 'gotcha!'
      end subroutine
      end module]],
    [cd sub
     AC_COMPILE_IFELSE([[
      program main
      use conftest_module
      call conftest_routine
      end program]],
       [ac_cv_fc_module_output_flag="$ac_flag"])
     cd ..
     if test "$ac_cv_fc_module_output_flag" != unknown; then
       break
     fi])
done
FCFLAGS=$ac_fc_module_output_flag_FCFLAGS_save
cd ..
rm -rf conftest.dir
AC_LANG_POP([Fortran])
])
if test "$ac_cv_fc_module_output_flag" != unknown; then
  FC_MODOUT=$ac_cv_fc_module_output_flag
  $1
else
  FC_MODOUT=
  m4_default([$2],
    [AC_MSG_ERROR([unable to find compiler flag to write module information to])])
fi
AC_SUBST([FC_MODOUT])
# Ensure trailing whitespace is preserved in a Makefile.
AC_SUBST([ac_empty], [""])
AC_CONFIG_COMMANDS_PRE([case $FC_MODOUT in #(
  *\ ) FC_MODOUT=$FC_MODOUT'${ac_empty}' ;;
esac])dnl
])


# AC_FC_CHECK_INTRINSICS(intrinsic-function ...)
# ----------------------------------------------
#
# Like AC_CHECK_FUNCS, but instead determine the intrinsics available
# to the Fortran compiler.  For each intrinsic in the
# (whitespace-separated and case-insensitive) argument list, define
# HAVE_INTRINSIC_intrinsic-function (uppercased) if it is available.
# For example, AC_FC_CHECK_INTRINSICS(sin) would define
# HAVE_INTRINSIC_SIN if the `sin' intrinsic function were available
# (there are probably rather few Fortrans which don't have this
# function).  The macro works for both intrinsic functions and
# intrinsic subroutines.
AC_DEFUN([AC_FC_CHECK_INTRINSICS],
  [AC_REQUIRE([AC_PROG_FC])dnl
   AC_LANG_PUSH([Fortran])
   AC_FOREACH([IntrinsicName],
              dnl In case the user is mad, escape impossible names
              m4_bpatsubst(m4_toupper([$1]), [[^a-zA-Z0-9_ ]], [_]),
              [AC_CACHE_CHECK([whether ${FC} supports intrinsic ]IntrinsicName,
                              [ac_cv_fc_has_]IntrinsicName,
                              [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
dnl All we need do is attempt to declare the thing as an intrinsic,
dnl since it is an error to thus declare a symbol which is not
dnl in fact an intrinsic function.
      intrinsic IntrinsicName
])],
                               ac_cv_fc_has_[]IntrinsicName=yes,
                               ac_cv_fc_has_[]IntrinsicName=no)])
               if test $ac_cv_fc_has_[]IntrinsicName = yes; then
                   AC_DEFINE([HAVE_INTRINSIC_]IntrinsicName, 1,
                             [Define to 1 if the Fortran compiler supports intrinsic ]IntrinsicName)
               fi
              ])
   AC_LANG_POP([Fortran])
])# AC_FC_CHECK_INTRINSICS

# AC_FC_RECL_UNIT
# ----------------
#
# When opening a file for direct access, you must specify
# the record length with the @samp{OPEN} specifier @samp{RECL};
# however in the case of unformatted direct access files, the
# @emph{units} of this specifier are processor dependent, and may be
# words or bytes.  This macro determines the units and defines
# @samp{FC_RECL_UNIT} to contain the number of bytes (1, 2, 4, 8, ...) in
# the processor's unit of measurement.
#
# Note that unformatted files are not themselves portable, and should
# only be used as either temporary files, or as data files which will
# be read by a program or library compiled with the same Fortran
# processor.  With this macro, however, you can read and write such
# files in a portable way.
AC_DEFUN([AC_FC_RECL_UNIT],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([units for Fortran OPEN RECL],
                         [ac_cv_fc_recl_unit],
                         [AC_LANG_PUSH([Fortran])
                          AC_RUN_IFELSE([AC_LANG_SOURCE([dnl
      PROGRAM TESTRECL
      IMPLICIT NONE
      INTEGER NBYTES
*   Make sure these values agree
      PARAMETER ( NBYTES = 8 )
      REAL * 8 TOFILE, FROMFILE

      INTEGER RECLEN,UNITLEN,OUTUNIT

      TOFILE = 123456789D56
      OUTUNIT = 10

*   Record length to try
      RECLEN = 1
*   Unitlen is the result -- zero indicates that no value was successful
      UNITLEN = 0

*     Keep on increasing the record length until we hit a
*     size that allows us to write a number and read it back correctly.
      DO WHILE (RECLEN .LE. 8)

         OPEN(UNIT = OUTUNIT,
     :        FILE = 'conftest.rcl1',
     :        STATUS = 'NEW',
     :        FORM = 'UNFORMATTED',
     :        ACCESS = 'DIRECT',
     :        RECL = RECLEN,
     :        ERR = 101)

*      Write two records to the output file, so that the second will stomp
*      on the end of the first if the record length is too short.
         WRITE(UNIT=OUTUNIT,REC=1,ERR=101) TOFILE
         WRITE(UNIT=OUTUNIT,REC=2,ERR=101) TOFILE
         READ(UNIT=OUTUNIT,REC=1,ERR=101) FROMFILE
         IF (TOFILE .EQ. FROMFILE) THEN
            UNITLEN = NBYTES/RECLEN
            GOTO 102
         END IF

*      Error opening unit; close and delete the file
 101     CONTINUE

         CLOSE(UNIT=OUTUNIT, STATUS='DELETE')

         RECLEN = RECLEN * 2
      END DO

*   Got a match
 102  CONTINUE

      OPEN(UNIT = OUTUNIT,
     :     FILE = 'conftest.rcl2',
     :     STATUS = 'NEW',
     :     ERR = 103)
      WRITE(OUTUNIT,'(I3)') UNITLEN
      CLOSE(UNIT = OUTUNIT)
 103  CONTINUE

      END
])],
                                        [],
                                        AC_MSG_FAILURE([Can't test for RECL length]),
                                        AC_MSG_FAILURE([Can't cross-compile: can't test for RECL length]))
                          AC_LANG_POP([Fortran])
                          if test -r conftest.rcl2; then
                              ac_cv_fc_recl_unit=`cat conftest.rcl2`
                          else
                              ac_cv_fc_recl_unit=0
                          fi
                          rm -f conftest*])
          if test -n "$ac_cv_fc_recl_unit" -a $ac_cv_fc_recl_unit -gt 0; then
              AC_DEFINE_UNQUOTED([FC_RECL_UNIT], $ac_cv_fc_recl_unit,
                        [Define to the length in bytes of the unit that OPEN RECL expects])
          fi
])# AC_FC_RECL_UNIT


# AC_FC_CHECK_HEADERS(include-file...)
# ------------------------------------
# Fortran analogue of AC_CHECK_HEADERS, though it only takes the
# first argument, giving the list of include files to check.  For
# each include file, defines HAVE_include-file (in all capitals) if the
# include file is found.  Respects the current value of FCFLAGS.
AC_DEFUN([AC_FC_CHECK_HEADERS],
   [AC_REQUIRE([AC_PROG_FC])dnl
    m4_ifval([$1], , [AC_FATAL([$0: missing argument])])dnl
    AC_LANG_PUSH([Fortran])
    AC_FOREACH([IncludeName],
              dnl In case the user is mad, escape impossible names
              m4_bpatsubst(m4_toupper([$1]), [[^a-zA-Z0-9_ ]], [_]),
              [AC_CACHE_CHECK([whether ${FC} supports include ]IncludeName,
                              [ac_cv_fc_has_]IncludeName,
                              [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
      include 'IncludeName'
      i=0
])],
                               [ac_cv_fc_has_]IncludeName=yes,
                               [ac_cv_fc_has_]IncludeName=no)])
               if test $ac_cv_fc_has_[]IncludeName = yes; then
                   AC_DEFINE([HAVE_]IncludeName, 1,
                             [Define to 1 if the we have Fortran include ]IncludeName)
               fi
              ])
    AC_LANG_POP([Fortran])
])# AC_FC_CHECK_HEADERS

# AC_FC_HAVE_PERCENTVAL
# ---------------------
# Test whether the FC compiler has the %VAL extension.  If so, define
# the preprocessor variable HAVE_PERCENTVAL to be 1.
AC_DEFUN([AC_FC_HAVE_PERCENTVAL],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([whether ${FC} has the %VAL extension],
                         [ac_cv_fc_have_percentval],
                         [AC_LANG_PUSH([Fortran])
                          AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
      i=1
      call t1(%val(i))
])],
                          ac_cv_fc_have_percentval=yes,
                          ac_cv_fc_have_percentval=no)
                          AC_LANG_POP([Fortran])])
          if test $ac_cv_fc_have_percentval = yes; then
              AC_DEFINE([HAVE_PERCENTVAL], 1,
                        [Define to 1 if the Fortran compiler supports the VAX %VAL extension])
          fi
])# AC_FC_HAVE_PERCENTVAL

# AC_FC_HAVE_PERCENTLOC
# ---------------------
# Test whether the FC compiler has the %LOC extension.  If so, define
# the preprocessor variable HAVE_PERCENTLOC to be 1.
AC_DEFUN([AC_FC_HAVE_PERCENTLOC],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([whether ${FC} has the %LOC extension],
                         [ac_cv_fc_have_percentloc],
                         [AC_LANG_PUSH([Fortran])
                          AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
      INTEGER I, ADDR
      I = 1
      ADDR = %LOC( I )
])],
                          ac_cv_fc_have_percentloc=yes,
                          ac_cv_fc_have_percentloc=no)
                          AC_LANG_POP([Fortran])])
          if test $ac_cv_fc_have_percentloc = yes; then
              AC_DEFINE([HAVE_PERCENTLOC], 1,
                        [Define to 1 if the Fortran compiler supports the VAX %LOC extension])
          fi
])# AC_FC_HAVE_PERCENTLOC


# AC_FC_HAVE_BOZ
# --------------
# Test whether the FC compiler supports BOZ constants in the Fortran
# 95 style. These are integer constants written in the format
# B'xxx', O'xxx' and Z'xxx'. If so set the preprocessor variable
# HAVE_BOZ to be 1.
AC_DEFUN([AC_FC_HAVE_BOZ],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([whether ${FC} supports F95 BOZ constants],
                         [ac_cv_fc_have_boz],
                         [AC_LANG_PUSH([Fortran])
                          AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
      INTEGER I, J, K, L
      PARAMETER ( J = B'1111111111111111' )
      PARAMETER ( K = O'7777' )
      PARAMETER ( L = Z'FF' )
])],
                          ac_cv_fc_have_boz=yes,
                          ac_cv_fc_have_boz=no)
                          AC_LANG_POP([Fortran])])
          if test $ac_cv_fc_have_boz = yes; then
              AC_DEFINE([HAVE_BOZ], 1,
                        [Define to 1 if the Fortran compiler supports F95 boz constants])
          fi
])# AC_FC_HAVE_BOZ

# AC_FC_HAVE_TYPELESS_BOZ
# ---------------------------
# Test whether the FC compiler supports typeless BOZ constants in the Fortran
# 95 style. These are (usually integer) constants written in the format
# X'xxx', but may also be typeless, which allows the initialisation of any type
# to a specific bit pattern. If so set the preprocessor variable
# HAVE_TYPELESS_BOZ to be 1.
#
# A problem with this test is that it may compile but the assignments are not
# actually typeless and have been done as integer casts.  To stop this we need
# to run the program and check if an integer equals a floating point value, by
# value, they shouldn't for a bit pattern assignment. Uses a "EXIT(1)" to
# signal a problem. This is non-standard, so the test may fail for that reason.
AC_DEFUN([AC_FC_HAVE_TYPELESS_BOZ],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([whether ${FC} supports F95 typeless BOZ constants],
                         [ac_cv_fc_have_typeless_boz],
                         [AC_LANG_PUSH([Fortran])
                          AC_RUN_IFELSE([AC_LANG_SOURCE([
      PROGRAM TMP
      INTEGER I
      PARAMETER ( I = X'FF7FFFFF' )
      REAL D
      PARAMETER ( D = X'FF7FFFFF' )
      LOGICAL L
      PARAMETER ( L = X'A55A5AA5' )
      IF ( D .EQ. I ) THEN
         CALL EXIT( 1 )
      END IF
      END
])],
                          ac_cv_fc_have_typeless_boz=yes,
                          ac_cv_fc_have_typeless_boz=no)
                          AC_LANG_POP([Fortran])])
          if test $ac_cv_fc_have_typeless_boz = yes; then
              AC_DEFINE([HAVE_TYPELESS_BOZ], 1,
                        [Define to 1 if the Fortran compiler supports F95 typeless boz constants])
          fi
])# AC_FC_HAVE_TYPELESS_BOZ

# AC_FC_HAVE_OLD_TYPELESS_BOZ
# ---------------------------
# Test whether the FC compiler supports typeless BOZ constants in the OLD (VMS
# and g77) Fortran style. These are constants written in the format 'xxx'X,
# which allows the initialisation of any type to a specific bit pattern. If so
# set the preprocessor variable HAVE_OLD_TYPELESS_BOZ to be 1.
#
# A problem with this test is that it may compile but the assignments are not
# actually typeless and have been done as integer casts.  To stop this we need
# to run the program and check if an integer equals a floating point value, by
# value, they shouldn't for a bit pattern assignment. Uses a "EXIT(1)" to
# signal a problem. This is non-standard, so the test may fail for that reason.
AC_DEFUN([AC_FC_HAVE_OLD_TYPELESS_BOZ],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([whether ${FC} supports OLD style typeless BOZ constants],
                         [ac_cv_fc_have_old_typeless_boz],
                         [AC_LANG_PUSH([Fortran])
                          AC_RUN_IFELSE([AC_LANG_SOURCE([
      PROGRAM TMP
      INTEGER I
      PARAMETER ( I = 'FF7FFFFF'X )
      REAL D
      PARAMETER ( D = 'FF7FFFFF'X )
      LOGICAL L
      PARAMETER ( L = 'A55A5AA5'X )
      IF ( D .EQ. I ) THEN
         CALL EXIT( 1 )
      END IF
      END
])],
                          ac_cv_fc_have_old_typeless_boz=yes,
                          ac_cv_fc_have_old_typeless_boz=no)
                          AC_LANG_POP([Fortran])])
          if test $ac_cv_fc_have_old_typeless_boz = yes; then
              AC_DEFINE([HAVE_OLD_TYPELESS_BOZ], 1,
                        [Define to 1 if the Fortran compiler supports OLD style typeless boz constants])
          fi
])# AC_FC_HAVE_OLD_TYPELESS_BOZ

# AC_FC_HAVE_VOLATILE
# -------------------
# Test whether the FC compiler supports the VOLATILE statement. VOLATILE
# is used to stop the optimisation of a variable, so that it can be modified
# outside of the program itself. If supported set HAVE_VOLATILE to be 1.
AC_DEFUN([AC_FC_HAVE_VOLATILE],
         [AC_REQUIRE([AC_PROG_FC])dnl
          AC_CACHE_CHECK([whether ${FC} supports VOLATILE],
                         [ac_cv_fc_have_volatile],
                         [AC_LANG_PUSH([Fortran])
                          AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
      INTEGER I
      VOLATILE I
])],
                          ac_cv_fc_have_volatile=yes,
                          ac_cv_fc_have_volatile=no)
                          AC_LANG_POP([Fortran])])
          if test $ac_cv_fc_have_volatile = yes; then
              AC_DEFINE([HAVE_VOLATILE], 1,
                        [Define to 1 if the Fortran compiler supports VOLATILE])
          fi
])# AC_FC_HAVE_VOLATILE

# AC_FC_LITERAL_BACKSLASH
# -----------------------
#
# Check whether the compiler regards the backslash character as an escape
# character.  The Standard doesn't say anything about this, but many Unix
# Fortran compilers interpret '\n', for example, as a newline, and '\\' as
# a single backslash.
#
# Test the behaviour of the currently selected compiler, and define
# FC_LITERAL_BACKSLASH to 1 if backslashes are treated literally -- that is
# if '\\' is interpreted as a _pair_ of backslashes and thus that '\n' is
# interpreted as a pair of characters.
AC_DEFUN([AC_FC_LITERAL_BACKSLASH],
   [AC_REQUIRE([AC_PROG_FC])dnl
    AC_CACHE_CHECK([whether ${FC} interprets backslashes literally],
        ac_cv_fc_literal_backslash,
       [AC_LANG_PUSH([Fortran])
## Four backslashes here -- this is expanded by the shell in writing
## the text to the file.  We want to end up with TEST\\TEST in the source.
        AC_COMPILE_IFELSE([AC_LANG_PROGRAM([],[
      write(*,'("TEST\\\\TEST")')
])],
## 'strings' is portable, yes?
           [if strings conftest.$ac_objext | grep 'TEST\\\\TEST' >/dev/null; then
                ac_cv_fc_literal_backslash=yes
            else
                ac_cv_fc_literal_backslash=no
            fi],
           [AC_MSG_WARN([cannot compile a program with backslashes!])
            ac_cv_fc_literal_backslash=unknown])
        AC_LANG_POP([Fortran])])
    if test $ac_cv_fc_literal_backslash = yes; then
        AC_DEFINE([FC_LITERAL_BACKSLASH], 1,
                  [Define to 1 if the Fortran compiler interprets '\\' as a pair of characters, not one])
    fi
])# AC_FC_LITERAL_BACKSLASH

# AC_FC_MOD_PATH_FLAG
# -------------------------
# Check which flag is necessary to alter the compiler's search path
# for module files.
# This obviously requires that the compiler has some notion of
# module files as separate from object files and some sensible
# method of altering its search path. This will therefore not work
# on early Cray F90 compilers, or on v5 (and 6?) of ifc.
#
# Nearly every compiler I have found uses -Ipath for this purpose;
# Sun F95 v7.1 (at least), uses -Mpath
#
AC_DEFUN([AC_FC_CHECK_MOD_PATH_FLAG],[
          AC_REQUIRE([AC_PROG_FC])
          ac_cv_fc_mod_path_flag=no
          AC_MSG_CHECKING([for flag to alter module search path])
	  mkdir conftestdir
          cd conftestdir
          cat > conftest.$ac_ext << \_ACEOF
      module conftest
       implicit none
       integer :: i
      end module conftest
_ACEOF
          _AC_EVAL_STDERR($ac_compile)
          cd ..
          for i in -I -M; do
            if test $ac_cv_fc_mod_path_flag == "no"; then
               FCFLAGS_save=$FCFLAGS
               FCFLAGS="$FCFLAGS ${i}conftestdir"
               AC_COMPILE_IFELSE([
      subroutine test
       use conftest
       implicit none
       i = 0
      end subroutine test
],
              [FC_MOD_FLAG=$i; ac_cv_fc_mod_path_flag=$i],
              [:])
            fi
            FCFLAGS=$FCFLAGS_save
          done
          AC_MSG_RESULT([$ac_cv_fc_mod_path_flag])
          rm -rf conftestdir
          AS_IF([test $ac_cv_fc_mod_path_flag != "no"],
                [$1],
                [m4_default([$2],[AC_MSG_ERROR([Cannot find flag to alter module search path])])])
])# AC_FC_MOD_PATH_FLAG


# -------------------------------------- #
# Feature tests for Preprocessed Fortran #
# -------------------------------------- #


# ------------------------------------------#
# Some test programs for different features #
# ------------------------------------------#

# _AC_LANG_PROGRAM_FPP_SIMPLE
# ---------------------------
# The minimum test program - any compiler supporting
# preprocessing should handle this
AC_DEFUN([_AC_LANG_PROGRAM_FPP_SIMPLE],
         [AC_LANG_PROGRAM([@%:@define OK], [dnl
#ifndef OK
      syntax error
#endif
])])#_AC_LANG_PROGRAM_FPP_SIMPLE


# _AC_LANG_PROGRAM_FPP_ONLY
# ---------------------------
# Test program for pure preprocessing
# Note that other macros test for literal strings within this, so check
# for those if you have to change anything here.
AC_DEFUN([_AC_LANG_PROGRAM_FPP_ONLY],
         [AC_LANG_PROGRAM([@%:@define OK], [dnl
#ifdef OK
      REAL A
#else
      syntax error
#endif
])])#_AC_LANG_PROGRAM_FPP_ONLY


# _AC_LANG_PROGRAM_FPP_D
# ---------------------------
# Like _AC_LANG_PROGRAM_FPP_SIMPLE, but OK is passed via -D switch
AC_DEFUN([_AC_LANG_PROGRAM_FPP_D],
[AC_LANG_PROGRAM([],[
#ifndef OK
      syntax error
#endif
])])#_AC_LANG_PROGRAM_FPP_D


# _AC_LANG_PROGRAM_FPP_I
# ---------------------------
# Test for #include statement
# If unsupported, this should give a type error
AC_DEFUN([_AC_LANG_PROGRAM_FPP_I],
[AC_LANG_PROGRAM([],[
      IMPLICIT CHARACTER (c)
!     Comments in test programs should be freeform compliant just in case.
!     conftest.inc contains the Fortran statement "REAL cc"
#include "conftest.inc"
      cc=1.
])])#_AC_LANG_PROGRAM_FPP_I


# _AC_LANG_PROGRAM_FPP_SUBS
# ---------------------------
# Test whether cpp symbols are expanded in Fortran code lines
# If not, this should give a type error
AC_DEFUN([_AC_LANG_PROGRAM_FPP_SUBS],
[AC_LANG_PROGRAM([
#define NM xxxx
], [      IMPLICIT CHARACTER (n)
      REAL xxxx
      NM=1.
])])#_AC_LANG_PROGRAM_FPP_SUBS


# _AC_LANG_PROGRAM_FPP_WRAP
# ---------------------------
# Test whether preprocessor breaks lines that become too long due
# to macro substitution.
# If not, this gives an "unterminated character constant" error
AC_DEFUN([_AC_LANG_PROGRAM_FPP_WRAP],
[AC_LANG_PROGRAM([
#define LONG '901234567890123456789012345678901234567890123456789012345678901234567890'
],[      CHARACTER*80 A
      A=LONG
])])#_AC_LANG_PROGRAM_FPP_WRAP


# _AC_LANG_PROGRAM_FPP_CSTYLE
# ---------------------------
# Test program for C style comments
AC_DEFUN([_AC_LANG_PROGRAM_FPP_CSTYLE],
[AC_LANG_PROGRAM([],[
      A=1. /* C-style comment */
])])#_AC_LANG_PROGRAM_FPP_CSTYLE


# ----------------#
# Internal macros #
# ----------------#


# _AC_PROG_FPP_FEATURES ([feature list])
# --------------------------------------
# Parse the feature list from configure.in
AC_DEFUN([_AC_PROG_FPP_FEATURES],
[# defaults for needed features
ac_fpp_need_d=yes
ac_fpp_need_i=yes
ac_fpp_need_subs=yes
ac_fpp_need_wrap=no
ac_fpp_need_cstyle=no
ac_fpp_need_CSTYLE=no
for _t in $1 nil
do
    case $_t in
        d*)    ac_fpp_need_d=yes    ;;
        nod*)  ac_fpp_need_d=no     ;;
        i*)    ac_fpp_need_i=yes    ;;
        noi*)  ac_fpp_need_i=no     ;;
        s*)    ac_fpp_need_subs=yes    ;;
        nos*)  ac_fpp_need_subs=no     ;;
        w*)    ac_fpp_need_wrap=yes   ;;
        now*)  ac_fpp_need_wrap=no    ;;
        c*)    ac_fpp_need_cstyle=yes ;;
        noc*)  ac_fpp_need_cstyle=no  ;;
        C*)    ac_fpp_need_CSTYLE=yes ;;
        noC*)  ac_fpp_need_CSTYLE=no  ;;
        nil)   ;;
    esac
done
# Wrapping requires substitution
test $ac_fpp_need_wrap = yes && ac_fpp_need_subs=yes
# Both CSTYLE and cstyle cannot be requested
# CSTYLE has precedence, since if it is not fulfilled,
# compile errors may arise
test $ac_fpp_need_CSTYLE = yes && ac_fpp_need_cstyle=no
])# _AC_PROG_FPP_FEATURES


# _AC_TEST_FPP ([command])
# ------------------------
# A helper macro to test correct fpp behaviour
# It sets ac_cv_prog_fpp and ac_fpp_out
AC_DEFUN([_AC_TEST_FPP],
[rm -f conftest*
cat >conftest.$ac_ext << \_ACEOF
_AC_LANG_PROGRAM_FPP_ONLY
_ACEOF
ac_fpp_command=$1
if eval '$ac_fpp_command conftest.$ac_ext > conftest.log 2>/dev/null'; then
  if test -f conftest.f; then
    if cmp conftest.$ac_ext conftest.f >/dev/null; then
      # ooops -- these two are the same file.  Ie, this is a
      # case-insensitive filesystem, so ignore this file
      ac_tmp=
    else
      ac_tmp=conftest.f
      ac_fpp_out=
    fi
  fi
  if test -z "$ac_tmp"; then
    ac_tmp=conftest.log
    ac_fpp_out=' > conftest.f'
  fi
  if grep '^      REAL A' $ac_tmp >/dev/null 2>&1; then
    # we have Fortran!  That worked...
    ac_cv_prog_fpp=$ac_fpp_command
  fi
  if grep 'syntax error' $ac_tmp >/dev/null 2>&1; then
    # ...oh no it didn't: this line should have been skipped
    ac_cv_prog_fpp=
  fi
fi
rm -f conftest*
])# _AC_TEST_FPP


# _AC_PROG_FPP
# ------------
# Try to figure out how to preprocess .F files for use with the selected
# Fortran compiler
#
# Must be run after _AC_PROG_FC_CPP
AC_DEFUN([_AC_PROG_FPP],
[AC_REQUIRE([_AC_PROG_FC_CPP])dnl
AC_CACHE_CHECK([how to preprocess Fortran files], ac_cv_prog_fpp,
[ac_cv_prog_fpp=
dnl AC_LANG_PUSH(Preprocessed Fortran)
AC_LANG_ASSERT(Preprocessed Fortran)

# Let the user specify FPP
if test -n "$FPP"; then
  _AC_TEST_FPP([$FPP])
  if test -z "$ac_cv_prog_fpp"; then
    AC_MSG_WARN([user-specified \$FPP ($FPP) does not work])
    FPP=
  fi
fi # test -n "$FPP"

if test -z "$ac_cv_prog_fpp" && test $ac_fpp_ok = yes; then
# We know that the Fortran compiler can directly preprocess and compile.
# All that remains is to find out how to run only the preprocessor.
# We check that the compiler does not compile as well as
# preprocessing, by looking for the file a.out (is this portable?  The
# single-unix spec says that cc produces an a.out if no -o is given).
# If we don't do this, and the compiler doesn't recognise, and
# ignores, one of the options (for example g77 ignores -F
# and returns without error), then the test appears to succeed.
#
# We only know the following methods of invocation: -E and -F
  for ac_j in "$FC -E" "$FC -F"; do
    rm -f a.out
    _AC_TEST_FPP([$ac_j])
    if test -e a.out; then
        rm -f a.out
        ac_cv_prog_fpp=  # discard any value there
    else
        test -n "$ac_cv_prog_fpp" && break;
    fi
  done
fi

if test -z "$ac_cv_prog_fpp"; then
# Either the Fortran compiler can't handle cpp, or doesn't have all the
# features, or can't be used for pure preprocessing.
# We must find another way for preprocessing.
# We try the "best" preprocessors first. At this point, F77 has already
# proven that it is insufficient, so use it as a last resort only.
# XXX: is there a more up-to-date list?
  for ac_j in 'fpp' "$CPP" 'g77 -E' '$CC -E' 'cpp' '/lib/cpp' \
              '/usr/ccs/lib/cpp' "$F77 -F" "$F77 -E"; do
    _AC_TEST_FPP([$ac_j])
    test -n "$ac_cv_prog_fpp" && break;
  done
fi # test -z "$ac_cv_prog_fpp"

if test -z "$ac_cv_prog_fpp"; then
# This is only fatal if direct compilation doesn't work either
  if test $ac_cv_prog_fc_cpp = no; then
    AC_MSG_ERROR([cannot find a working Fortran preprocessor])
  else
    AC_MSG_WARN([cannot find a working Fortran preprocessor])
  fi
fi
dnl AC_LANG_POP()dnl
])
AC_CACHE_CHECK([how to redirect $ac_cv_prog_fpp output],
  ac_cv_fpp_out,
  [ac_cv_fpp_out=$ac_fpp_out])
FPP=$ac_cv_prog_fpp
ac_fpp_out=$ac_cv_fpp_out
])# _AC_PROG_FPP


# _AC_PROG_FPP_P
# --------------
# Check whether we need to give FPP the -P option, to get it to
# produce code which FC can read.
AC_DEFUN([_AC_PROG_FPP_P],
[AC_CACHE_CHECK([whether $FPP needs the -P option],
ac_cv_prog_fpp_p,
[ac_cv_prog_fpp_p=unknown
dnl AC_LANG_PUSH(Preprocessed Fortran)
AC_LANG_ASSERT(Preprocessed Fortran)
# Note we force extension .$FPP_SRC_EXT here and in the ac_cmd lines below, to
# make sure that we don't use the default extension for the language.
# We mustn't blindly set ac_ext=$FPP_SRC_EXT, however, or else this
# would break the $(ac_link) command below.  Yes, this test file has
# the literal extension .FPP_SRC_EXT (see below).
cat > conftest.FPP_SRC_EXT << \_ACEOF
_AC_LANG_PROGRAM_FPP_ONLY
_ACEOF
dnl AC_LANG_POP(Preprocessed Fortran)dnl

AC_LANG_PUSH(Fortran)

# We must not fail, here, in the case where the filesystem is
# case-insensitive, so that conftest.F and conftest.f are the same
# file.
if test -n "$ac_fpp_out"; then
   # If $ac_fpp_out is non-null, then preprocessor output goes to
   # stdout, which we send to conftest.f _without_ immediately clobbering
   # the input file as it is being read.  We do clobber it in the
   # end, however, which is why we copy .FPP_SRC_EXT to .$FPP_SRC_EXT
   # each time.
   ac_tmp='>conftest.tmp && mv conftest.tmp conftest.f'
else
   # conftest.F is preprocessed directly to conftest.f.  We can
   # assume that the filesystem is case-sensitive, since otherwise
   # this compiler/preprocessor would be simply non-functional on
   # this platform.
   ac_tmp=
fi
cp conftest.FPP_SRC_EXT conftest.$FPP_SRC_EXT
ac_cmd='$FPP $FPPFLAGS conftest.$FPP_SRC_EXT '"$ac_tmp"
## use ac_link from the Fortran language
if AC_TRY_EVAL(ac_cmd) &&
     AC_TRY_EVAL(ac_link) && test -s conftest${ac_exeext}; then
   ac_cv_prog_fpp_p=
else
   cp conftest.FPP_SRC_EXT conftest.$FPP_SRC_EXT
   ac_save_FPPFLAGS=$FPPFLAGS
   FPPFLAGS="$FPPFLAGS -P"
   if AC_TRY_EVAL(ac_cmd) &&
       AC_TRY_EVAL(ac_link) && test -s conftest${ac_exeext}; then
     ac_cv_prog_fpp_p=-P
   fi
   FPPFLAGS=$ac_save_FPPFLAGS
fi
rm -f conftest*
AC_LANG_POP(Fortran)dnl
])
if test "x$ac_cv_prog_fpp_p" = "xunknown"; then
   AC_MSG_ERROR([$FPP cannot produce code that $FC compiles])
else
   FPPFLAGS="$FPPFLAGS $ac_cv_prog_fpp_p"
fi
])# _AC_PROG_FPP_P

# _AC_PROG_FPP_CSTYLE
# -------------------
# Check whether FPP lets C-style options through to FC
AC_DEFUN([_AC_PROG_FPP_CSTYLE],
[AC_CACHE_CHECK([how to pass C-style comments to $FC],
   ac_cv_prog_fpp_cstyle,
[ac_cv_prog_fpp_cstyle=unknown
dnl AC_LANG_PUSH(Preprocessed Fortran)
AC_LANG_ASSERT(Preprocessed Fortran)
cat > conftest.$ac_ext << \_ACEOF
_AC_LANG_PROGRAM_FPP_CSTYLE
_ACEOF
dnl AC_LANG_POP()dnl

AC_LANG_PUSH(Fortran)
ac_cmd='$FPP $FPPFLAGS conftest.$ac_ext '"$ac_fpp_out"
if AC_TRY_EVAL(ac_cmd) &&
   cat conftest.f | grep '[[*]]/.*[[*]]/' >/dev/null 2>&1; then
   ac_cv_prog_fpp_cstyle=
else
   ac_save_FPPFLAGS=$FPPFLAGS
   ac_name=`expr "x$FPP" : 'x\(fpp\)'`
   if test "x$ac_name" = xfpp; then
     ac_flag="-c_com=no"
   else
     ac_flag="-C"
   fi
   FPPFLAGS="$FPPFLAGS $ac_flag"
   ac_cmd='$FPP $FPPFLAGS conftest.$ac_ext '"$ac_fpp_out"
   if AC_TRY_EVAL(ac_cmd) &&
     cat conftest.f | grep '/[[*]].*[[*]]/' >/dev/null 2>&1; then
     ac_cv_prog_fpp_cstyle=$ac_flag
   fi
   FPPFLAGS=$ac_save_FPPFLAGS
fi
rm -f conftest*
AC_LANG_POP(Fortran)dnl
])
if test "x$ac_cv_prog_fpp_cstyle" = "xunknown"; then
  AC_MSG_WARN([cannot find a way to make $FPP pass C-style comments])
else
  FPPFLAGS="$FPPFLAGS $ac_cv_prog_fpp_cstyle"
fi
])# _AC_PROG_FPP_CSTYLE

# _AC_PROG_FC_CPP
# ----------------
#FIXME: this is only for fixed form code. Need a separate check for free-form.
# Test whether compilation of Fortan code with preprocessor directives
# succeeds, and check for supported features
#
# Sets ac_fpp_ok to "no" if a requested feature is unavailable
#
AC_DEFUN([_AC_PROG_FC_CPP],
[ac_fpp_ok=yes
ac_prog_fc_cpp=no
ac_prog_fc_cpp_d=no
ac_prog_fc_cpp_i=no
ac_prog_fc_cpp_subs=no
ac_prog_fc_cpp_wrap=no
ac_prog_fc_cpp_CSTYLE=no

dnl AC_LANG_PUSH(Preprocessed Fortran)
AC_LANG_ASSERT(Preprocessed Fortran)
AC_MSG_CHECKING([for fixed form Fortran preprocessor features])
# We must use AC_LINK_IFELSE because Lahey Fortran (and maybe others) have
# broken exit status when compiling
AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_SIMPLE],
   [ac_prog_fc_cpp=yes],
   [ac_fpp_ok=no])

if test $ac_prog_fc_cpp = yes; then

    if test $ac_fpp_need_d = yes; then
       ac_prog_fc_cpp_d=no
       ac_save_FPPFLAGS=$FPPFLAGS
       FPPFLAGS="$FPPFLAGS -DOK"
       AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_D],
         [ac_prog_fc_cpp_d=yes; FPPFLAGS_DEF="-D"],
         [:])
       FPPFLAGS=$ac_save_FPPFLAGS
       if test $ac_prog_fc_cpp_d = no; then
	  # stupid ibm compiler
          ac_save_FPPFLAGS=$FPPFLAGS
          FPPFLAGS="$FPPFLAGS -WF,-DOK"
          AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_D],
            [ac_prog_fc_cpp_d=yes; FPPFLAGS_DEF="-WF,-D"],
            [ac_fpp_ok=no])
          FPPFLAGS=$ac_save_FPPFLAGS
       fi
    fi
    AC_SUBST(FPPFLAGS_DEF)

    if test $ac_fpp_need_i = yes; then
       mkdir conftst
       cat > conftst/conftest.inc << \_ACEOF
!     This statement overrides the IMPLICIT statement in the program
      REAL cc
_ACEOF
       ac_save_FPPFLAGS=$FPPFLAGS
       FPPFLAGS="$FPPFLAGS -Iconftst"
       AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_I],
         [ac_prog_fc_cpp_i=yes],
         [ac_fpp_ok=no])
       rm -rf conftst
       FPPFLAGS=$ac_save_FPPFLAGS
    fi

    if test $ac_fpp_need_subs = yes; then
        AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_SUBS],
           [ac_prog_fc_cpp_subs=yes],
           [ac_fpp_ok=no])
    fi

    if test $ac_fpp_need_wrap = yes; then
        AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_WRAP],
           [ac_prog_fc_cpp_wrap=yes],
           [ac_fpp_ok=no])
    fi

    if test $ac_fpp_need_CSTYLE = yes; then
        AC_LINK_IFELSE([_AC_LANG_PROGRAM_FPP_CSTYLE],
           [ac_prog_fc_cpp_CSTYLE=yes],
           [ac_fpp_ok=no])
    fi
fi
AC_MSG_RESULT([done.])
dnl AC_LANG_POP()dnl
])#_AC_PROG_FC_CPP


# _AC_FPP_BUILD_RULE
# ------------------
# Figure out how to build from cpp/Fortran sources
#
# If we need to use a separate preprocessor, we must override make's
# `direct' .F.o rule in order to do `indirect' compilation
# (.F -> .f then .f -> .o).
#
# Configure variables set here:
#
#   FPP_SRC_EXT
#     This is the file extension (without a dot) of preprocessable
#     Fortran files; by default this is `F', but others are occasionally
#     used, though they are surely less portable. [set in AC_PROG_FPP,
#     but documented here for consistency]
#
#   FPP_COMPILE_EXT
#     This contains the file extension which the Fortran compiler will
#     accept.  It is $FPP_SRC_EXT if the compiler itself can do
#     preprocessing (`direct' compilation), or a dummy value (not .f,
#     since that would conflict with the pre-existing rule for
#     compiling Fortran) if it cannot, and the file must be
#     preprocessed separately (`indirect').
#
#   FPP_PREPROCESS_EXT
#     The partner of FPP_COMPILE_EXT.  This is $FPP_SRC_EXT for
#     indirect compilation, or a dummy value for direct compilation,
#     when the corresponding separate-processing generated rule should
#     be ignored.
#
#   FPP_MAKE_FLAGS
#     This is used to include CPP/FPP related flags into the compiler
#     call if we compile directly, and leave them out otherwise.
#
#   FPP_OUTPUT
#     This is used to redirect FPP output to the .f file in those
#     cases where FPP writes to stdout rather than to a file.
#
# These are used in Automake's lang_ppfc_finish subroutine.
#
# NOTE 1: There would seem to be a problem here with the use of .F as
# the extension for preprocessed files.  On case-insensitive
# filesystems such as HFS+, as used on MacOS X, foo.F and foo.f are
# the same file.  This means that indirect compilation would lose badly, since
# converting foo.F to foo.f would clobber the original.  This is
# probably not a problem in practice, since the compilers (g77, gfortran,
# nag, and xlf) actually likely to be used on OS X -- which is a
# recent platform, and thus with only recent Fortrans on it -- can all
# do direct compilation of preprocessable Fortran.  Just in case, we
# check below whether we are in this fatal situation, and collapse
# noisily if necessary.
#
# NOTE 2: Martin Wilck's original version of these macros noted that it
# was necessary to generate explicit rules for .F -> .o compilations
# in order to override make's builtin rules in a portable manner
# (i.e. without using make extensions).  Not all makes do chains of
# implicit rules, so we cannot depend on .F.f, .f.o rules generating
# a .f file.  We need unified .F.o and .F.lo rules, but that's
# complicated, an alternative is to name the intermediary .f files in
# the Makefiles.  Again, this may not be much of a problem in fact,
# since the main culprit seems to be Solaris make, but Solaris f77
# can do direct compilation, so that the issue of chaining rules
# doesn't arise.
#
# POSIX/Single-Unix states that inference rules can be
# redefined, and there's no warning against this in Autoconf's section
# on `Limitations of Make'.
#
AC_DEFUN([_AC_FPP_BUILD_RULE],
[AC_CACHE_CHECK([how to build from preprocessed Fortran sources],
  ac_cv_fpp_build_rule,
[ac_cv_fpp_build_rule=
if test $ac_cv_prog_fc_cpp_ok = yes; then
   ac_cv_fpp_build_rule=direct
   ac_fpp_status=ok
elif test $ac_cv_prog_fpp_ok = yes; then
   ac_cv_fpp_build_rule=indirect
   ac_fpp_status=ok
elif test $ac_cv_prog_fc_cpp = no -a $ac_cv_prog_fpp = no; then
   ac_cv_fpp_build_rule=
   ac_fpp_status=fatal
elif test $ac_cv_prog_fc_cpp = no; then
   ac_cv_fpp_build_rule=indirect
   ac_fpp_status=fail
elif test -z "$ac_cv_prog_fpp"; then
   ac_cv_fpp_build_rule=direct
   ac_fpp_status=fail
elif test $ac_fpp_equals_fc = yes; then
   ac_cv_fpp_build_rule=direct
   ac_fpp_status=fail
else
   ac_fpp_status=fail
# Both methods - direct and indirect - fail to meet some requirements
# We use a simple approach to choose the best alternative
   ac_fc_score=0
   ac_fpp_score=0
   for ac_i in d i subs wrap cstyle CSTYLE; do
      ac_tmp="\$ac_fpp_need_$ac_i"
      ac_need=`eval echo $ac_tmp`
      if test $ac_need = yes; then
        ac_tmp="\$ac_cv_prog_fc_cpp_$ac_i"
        ac_v_fc=`eval echo $ac_tmp`
        ac_tmp="\$ac_cv_prog_fpp_$ac_i"
        ac_v_fpp=`eval echo $ac_tmp`
        test "x$ac_v_fc" = xyes && ac_fc_score=`expr $ac_fc_score + 1`
        test "x$ac_v_fpp" = xyes && ac_fpp_score=`expr $ac_fpp_score + 1`
      fi
   done
   if test $ac_fpp_score -gt $ac_fc_score; then
     ac_cv_fpp_build_rule=indirect
   else
     ac_cv_fpp_build_rule=direct
   fi
fi
])

if test -z "$ac_fpp_status"; then
    # must be non-empty below
    ac_fpp_status=cached
fi

if test $ac_fpp_status = fatal; then

  AC_MSG_ERROR([cannot find a valid build rule for Fortran/cpp source: consider installing the free Fortran preprocessor fpp from ftp.netlib.org/fortran])

elif test $ac_fpp_status = fail; then

  AC_MSG_WARN([cannot find a build rule for Fortran/cpp source that fulfills all requirements.  The compilation may fail or run time errors may arise.  Consider installing the free Fortran preprocessor fpp from ftp.netlib.org/fortran])

fi

# Before we go any further, check that we're not courting disaster,
# here, by using indirect compilation (.F -> .f -> .o) on a
# case-insensitive filesystem.  If we are, there's nothing we can do
# other than fail noisily.
if test $ac_cv_fpp_build_rule = indirect; then
    _AC_FC_CHECK_CIFS
    if test $ac_cv_fc_cifs = yes; then
        AC_MSG_ERROR([disaster: this Fortran needs indirect compilation, but we
 have a case-insensitive filesystem, so .F -> .f would fail; further compilation isn't going to work -- consider filing a bug])
    fi
fi

# The flags here are those included in the 'compile' field of the
# 'ppfc' language in automake.in, minus the {AM_,}FCFLAGS variables.
# It's not _absolutely_ guaranteed that these are the correct ones,
# and I (NG) would be open to argument about both {AM_,}CPPFLAGS and
# {AM_,}FCFLAGS, but this set appears to work.  The .f_in extension
# doesn't mean anything particular, but it's a useful and harmless
# default, which can potentially be used in a user rule for an
# explicit preprocessing step.
if test $ac_cv_fpp_build_rule = direct; then
    FPP_COMPILE_EXT=$FPP_SRC_EXT
    FPP_PREPROCESS_EXT=f_in
    FPP_MAKE_FLAGS='$(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(AM_CPPFLAGS) $(CPPFLAGS)'
else
    FPP_COMPILE_EXT=DUMMYf
    FPP_PREPROCESS_EXT=$FPP_SRC_EXT

#  PWD: seem to need mainly for getting DEFAULT_INCLUDES and INCLUDES
#  to the FC compiler (i.e $FC -I$(INCLUDES) to get local include files).
    FPP_MAKE_FLAGS='$(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(AM_CPPFLAGS)'
fi
if test -z "$ac_fpp_out"; then
   FPP_OUTPUT=" "
else
   FPP_OUTPUT=">\[$]@"
fi
])# _AC_FPP_BUILD_RULE


# _AC_FC_CHECK_CIFS
# -----------------
# Check whether the filesystem is case-insensitive (eg, HFS+ on
# MacOS X).  Set ac_cv_fc_cifs=yes if so.
AC_DEFUN([_AC_FC_CHECK_CIFS],
   [AC_CACHE_CHECK([whether the filesystem is case-insensitive],
        ac_cv_fc_cifs,
       [rm -f conftest.*
        echo wibble >conftest.F
        ac_cv_fc_cifs=no
        if test -f conftest.f -a `cat conftest.f` = wibble; then
            ac_cv_fc_cifs=yes
        fi
])])# _AC_FC_CHECK_CIFS



# -----------------------
# User macros
# -----------------------

# AC_CHECK_FC_FPP([required features], [FPP-SRC-EXT=.F], [ACTION-IF-YES], [ACTION-IF-NO])
# --------------------------------------------------
#
# [required features] is a space-separated list of features that the Fortran
# preprocessor must have for the code to compile.
# See below.

# [FPP-SRC-EXT] is an optional specification of the file extension
# See below

AC_DEFUN([AC_CHECK_FC_FPP],
[AC_REQUIRE([AC_PROG_FC])dnl

AC_LANG_PUSH([Fortran])
# Prefer AC_PROG_FC to AC_PROG_F77
if test "X$F77" != X; then
    AC_MSG_WARN([Use A@&t@C_PROG_FC with A@&t@C_PROG_FPP, instead of A@&t@C_PROG_F77])
fi

_AC_PROG_FPP_FEATURES([$1])

# Default optional second argument to F
FPP_SRC_EXT=m4_default([$2], [F])

# Test FPP_SRC_EXT
ac_fpp_srcext_failed=no
AC_FPP_SRCEXT(m4_default([$2], [F]),[],[ac_fpp_srcext_failed=yes])
if test $ac_fpp_srcext_failed = yes -a "$2" != F; then
    AC_MSG_NOTICE([Could not use .$FPP_SRC_EXT as extension; trying .F])
    FPP_SRC_EXT=F
    AC_FPP_SRCEXT([F])
fi

AC_LANG_POP([Fortran])

# We first try to use FC for compiling the source directly
# into object files
ac_fpp_compile='${FC-fc} -c $FPPFLAGS $FFLAGS $FPPFLAGS_SRCEXT conftest.$ac_ext >&AS_MESSAGE_LOG_FD'
ac_fpp_link='${FC-fc} -o conftest${ac_exeext} $FPPFLAGS $FFLAGS $LDFLAGS $FPPFLAGS_SRCEXT conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'

AC_LANG_PUSH(Preprocessed Fortran)

# _AC_PROG_FC_CPP stores results of the feature checks in non-cv variables,
# which we copy to cv variables afterwards.
# The reason for that is reusability of the macro for other cv variables (see below)
_AC_PROG_FC_CPP

AC_CACHE_CHECK([whether $FC compiles programs with cpp directives],
   ac_cv_prog_fc_cpp,
  [ac_cv_prog_fc_cpp=$ac_prog_fc_cpp])

if test $ac_fpp_need_d = yes; then
  AC_CACHE_CHECK([whether $FC accepts -D],
     ac_cv_prog_fc_cpp_d,
    [ac_cv_prog_fc_cpp_d=$ac_prog_fc_cpp_d])
fi

if test $ac_fpp_need_i = yes; then
  AC_CACHE_CHECK([whether $FC accepts -I],
     ac_cv_prog_fc_cpp_i,
    [ac_cv_prog_fc_cpp_i=$ac_prog_fc_cpp_i])
fi

if test $ac_fpp_need_subs = yes; then
  AC_CACHE_CHECK([whether $FC substitutes macros in Fortran code],
     ac_cv_prog_fc_cpp_subs,
    [ac_cv_prog_fc_cpp_subs=$ac_prog_fc_cpp_subs])
fi

if test $ac_fpp_need_wrap = yes; then
  AC_CACHE_CHECK([whether $FC wraps long lines automatically],
     ac_cv_prog_fc_cpp_wrap,
    [ac_cv_prog_fc_cpp_wrap=$ac_prog_fc_cpp_wrap])
fi

if test $ac_fpp_need_CSTYLE = yes; then
  AC_CACHE_CHECK([whether $FC handles C-style comments],
     ac_cv_prog_fc_cpp_CSTYLE,
    [ac_cv_prog_fc_cpp_CSTYLE=$ac_prog_fc_cpp_CSTYLE])
fi

AC_CACHE_CHECK([whether $FC fulfills requested features],
  ac_cv_prog_fc_cpp_ok,
  [ac_cv_prog_fc_cpp_ok=$ac_fpp_ok])

if test $ac_fpp_ok = yes; then
    :
else
    AC_MSG_NOTICE([$FC cannot deal with preprocessed Fortran; press on...])
fi
##if test $ac_fpp_ok = yes; then
##    m4_default([$3],[:])
##else
##    m4_default([$4],[AC_MSG_ERROR([$FC cannot deal with preprocessed Fortran])])
##fi

])# AC_CHECK_FC_FPP

# AC_CHECK_FC_FREEFORM_FPP([required features], [FPP-SRC-EXT=.F], [ACTION-IF-YES], [ACTION-IF-NO])
# --------------------------------------------------
#
# [required features] is a space-separated list of features that the Fortran
# preprocessor must have for the code to compile.
# See below.

# [FPP-SRC-EXT] is an optional specification of the file extension
# See below

#FIXME. This is not even remotely implemented yet.

AC_DEFUN([AC_CHECK_FC_FREEFORM_FPP],
[AC_REQUIRE([AC_PROG_FC])dnl

AC_LANG_PUSH([Fortran])
# Prefer AC_PROG_FC to AC_PROG_F77
if test "X$F77" != X; then
    AC_MSG_WARN([Use A@&t@C_PROG_FC with A@&t@C_PRO_FPP, instead of A@&t@C_PROG_F77])
fi

_AC_PROG_FPP_FEATURES([$1])

# Default optional second argument to F90
FPP_SRC_EXT=m4_if([$2], [$2], [F90])

# Test FPP_SRC_EXT
AC_MSG_NOTICE([1: $ac_fpp_compile])
ac_fc_srcext_failed=no
AC_FC_SRCEXT([$FPP_SRC_EXT],[],[ac_fc_srcext_failed=yes])
AC_MSG_NOTICE([2: $ac_fpp_compile])
if test $ac_fc_srcext_failed = yes -a "$2" != F; then
    AC_MSG_NOTICE([Could not use F90 as extension; trying .F])
    FPP_SRC_EXT=F
    AC_FC_SRCEXT([F])
fi
AC_MSG_NOTICE([3: $ac_fpp_compile])

AC_LANG_POP([Fortran])

# We first try to use FC for compiling the source directly
# into object files
ac_fpp_compile='${FC-fc} -c $FPPFLAGS $FFLAGS $FPPFLAGS_SRCEXT conftest.$ac_ext >&AS_MESSAGE_LOG_FD'
ac_fpp_link='${FC-fc} -o conftest${ac_exeext} $FPPFLAGS $FFLAGS $LDFLAGS $FPPFLAGS_SRCEXT conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'

AC_LANG_PUSH(Preprocessed Fortran)

# _AC_PROG_FC_CPP stores results of the feature checks in non-cv variables,
# which we copy to cv variables afterwards.
# The reason for that is reusability of the macro for other cv variables (see below)
_AC_PROG_FC_CPP

AC_CACHE_CHECK([whether $FC compiles programs with cpp directives],
   ac_cv_prog_fc_cpp,
  [ac_cv_prog_fc_cpp=$ac_prog_fc_cpp])

if test $ac_fpp_need_d = yes; then
  AC_CACHE_CHECK([whether $FC accepts -D],
     ac_cv_prog_fc_cpp_d,
    [ac_cv_prog_fc_cpp_d=$ac_prog_fc_cpp_d])
fi

if test $ac_fpp_need_i = yes; then
  AC_CACHE_CHECK([whether $FC accepts -I],
     ac_cv_prog_fc_cpp_i,
    [ac_cv_prog_fc_cpp_i=$ac_prog_fc_cpp_i])
fi

if test $ac_fpp_need_subs = yes; then
  AC_CACHE_CHECK([whether $FC substitutes macros in Fortran code],
     ac_cv_prog_fc_cpp_subs,
    [ac_cv_prog_fc_cpp_subs=$ac_prog_fc_cpp_subs])
fi

if test $ac_fpp_need_wrap = yes; then
  AC_CACHE_CHECK([whether $FC wraps long lines automatically],
     ac_cv_prog_fc_cpp_wrap,
    [ac_cv_prog_fc_cpp_wrap=$ac_prog_fc_cpp_wrap])
fi

if test $ac_fpp_need_CSTYLE = yes; then
  AC_CACHE_CHECK([whether $FC handles C-style comments],
     ac_cv_prog_fc_cpp_CSTYLE,
    [ac_cv_prog_fc_cpp_CSTYLE=$ac_prog_fc_cpp_CSTYLE])
fi

AC_CACHE_CHECK([whether $FC fulfills requested features],
  ac_cv_prog_fc_cpp_ok,
  [ac_cv_prog_fc_cpp_ok=$ac_fpp_ok])

if test $ac_fpp_ok = yes; then
    m4_default([$3],[:])
else
    m4_default([$4],[AC_MSG_ERROR([$FC cannot deal with preprocessed Fortran])])
fi

])# AC_CHECK_FC_FREEFORM_FPP


# AC_PROG_FPP([required features], [FPP-SRC-EXT=.F])
# --------------------------------------------------
#
# [required features] is a space-separated list of features that the Fortran
# preprocessor must have for the code to compile.
# It is up to the package maintainer to properly set these requirements.
#
# [FPP-SRC-EXT] is an optional specification of the file extension for
# preprocessable Fortran source files (without a leading dot).  It
# defaults to `F'.
#
# Supported features are:
#
# include   : correctly process #include directives and -I
# define    : correctly process -D
# substitute: substitute macros in Fortran code
#             (some preprocessors touch only lines starting with #)
# wrap      : wrap lines that become too long through macro substitution
#             fpp is probably the only preprocessor that does this.
# cstyle    : Do not suppress C style comments (-C option in cpp)
# CSTYLE    : *Do* suppress C style comments
#             (e.g. code contains C-style comments, and compiler may not
#             know how to handle them)
#
# Features can be abbreviated: i, in, inc etc. are equivalent to include.
# Features can be deselected (feature not needed) by prepending "no",
#   e.g. nodef (=nodefine), now (=nowrap).
#
# Default for the feature list is
#       [include define substitute nowrap nocstyle noCSTYLE]
# Feature requirements corresponding to the defaults may be omitted
#
# Note that "wrap" implies "substitute", and CSTYLE and cstyle cannot
# be requested at the same time. The macro adjusts this automatically.
#
# This macro sets and substitutes the variables FPP and FPPFLAGS, and
# causes to be set FPP_OUTPUT, FPP_MAKE_FLAGS, and FPP_COMPILE_EXT
# (actually set in macro _AC_FPP_BUILD_RULE)
#
# The macro depends on both FC and CPP, because we must possibly fall
# back on CPP for preprocessing.
#
AC_DEFUN([AC_PROG_FPP],
[AC_REQUIRE([AC_PROG_FC])dnl
AC_REQUIRE([AC_PROG_CPP])dnl

AC_CHECK_FC_FPP([$1],[$2])

# Now we check how to invoke a preprocessor that outputs Fortran code
# that FC can understand
# The next macro sets FPP (unless already set by the user)
ac_ext=F
_AC_PROG_FPP
_AC_PROG_FPP_P

# Now, we check the features of the preprocessor/compiler combination
# It only makes sense to carry out further tests if FPP is a different
# program from FC
ac_fpp_name=`expr "x$FPP" : "x\([[^ ]]*\)"`
ac_fc_name=`expr "x$FC" : "x\([[^ ]]*\)"`
if test "x$ac_fc_name" != "x$ac_fpp_name"; then
  ac_fpp_equals_fc=no

# Redefine the compile and link commands for indirect compilation
  ac_fpp_compile='${FPP-fpp} $FPPFLAGS conftest.$ac_ext '"$ac_fpp_out"' && ${FC-fc} -c $FFLAGS conftest.f >&AS_MESSAGE_LOG_FD'
  ac_fpp_link='${FPP-fpp} $FPPFLAGS conftest.$ac_ext '"$ac_fpp_out"' && ${FC-fc} -o conftest${ac_exeext} $FFLAGS $LDFLAGS conftest.f $LIBS >&AS_MESSAGE_LOG_FD'

# PWD: we are not picking up indirection compilation for the following
# tests, maybe we need to reset more than the above variables.
  AC_LANG_POP(Preprocessed Fortran)
  AC_LANG_PUSH(Preprocessed Fortran)

# Redo all the feature checks for indirect compilation: perhaps we have an
# external preprocessor that does a better job than FC
  _AC_PROG_FC_CPP

else
  ac_fpp_equals_fc=yes
fi

if test $ac_fpp_need_d = yes; then
  AC_CACHE_CHECK([whether $FPP accepts -D],
     ac_cv_prog_fpp_d,
    [ac_cv_prog_fpp_d=$ac_prog_fc_cpp_d])
fi

if test $ac_fpp_need_i = yes; then
  AC_CACHE_CHECK([whether $FPP accepts -I],
     ac_cv_prog_fpp_i,
    [ac_cv_prog_fpp_i=$ac_prog_fc_cpp_i])
fi

if test $ac_fpp_need_subs = yes; then
  AC_CACHE_CHECK([whether $FPP substitutes macros in Fortran code],
     ac_cv_prog_fpp_subs,
    [ac_cv_prog_fpp_subs=$ac_prog_fc_cpp_subs])
fi

if test $ac_fpp_need_wrap = yes; then
  AC_CACHE_CHECK([whether $FPP wraps long lines automatically],
     ac_cv_prog_fpp_wrap,
    [ac_cv_prog_fpp_wrap=$ac_prog_fc_cpp_wrap])
fi

if test $ac_fpp_need_CSTYLE = yes; then
  AC_CACHE_CHECK([whether $FPP suppresses C-style comments],
     ac_cv_prog_fpp_CSTYLE,
    [ac_cv_prog_fpp_CSTYLE=$ac_prog_fc_cpp_CSTYLE])

elif test $ac_fpp_need_cstyle = yes; then
# It only makes sense to test this for indirect compilation,
# i.e., if .f files are generated
    _AC_PROG_FPP_CSTYLE
fi

AC_CACHE_CHECK([whether $FPP fulfills requested features],
  ac_cv_prog_fpp_ok,
  [ac_cv_prog_fpp_ok=$ac_fpp_ok])

# We have all necessary information.
# It remains to construct optimal build rules
# (direct: .F.o or indirect: .F.f)
# and carry out the substitutions.
_AC_FPP_BUILD_RULE

AC_SUBST(FPP)
AC_SUBST(FPPFLAGS)
AC_SUBST(FPP_OUTPUT)
AC_SUBST(FPP_MAKE_FLAGS)
AC_SUBST(FPP_COMPILE_EXT)
AC_SUBST(FPP_PREPROCESS_EXT)
AC_SUBST(FPP_SRC_EXT)

AC_LANG_POP(Preprocessed Fortran)

])# AC_PROG_FPP

