#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.61])
AC_INIT([mrnative], [1.1], [yhfudev@gmail.com])
AM_INIT_AUTOMAKE(-Wall subdir-objects)

# Checks for programs.
AC_PROG_AWK
AC_PROG_YACC
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S

# Checks for libraries.

dnl Disable doc generation with doxygen option
AC_ARG_ENABLE(doxygen-doc,
              [AC_HELP_STRING([--disable-doxygen-doc],
                              [disable document generation with doxygen])],
              , enable_doxygen_doc="yes")
if test "x$enable_doxygen_doc" = "xyes"; then
  AC_CHECK_PROG(DOXYGEN,doxygen,doxygen,no)
  if test "x$DOXYGEN" = "xno"; then
    enable_doxygen_doc="no"
  fi
fi
dnl where to install the doxygen-generated HTML doc
AC_ARG_WITH(html-docdir,
            [AC_HELP_STRING([--with-html-docdir=DIR],
                            [where to install the doxyten-generated HTML doc [PREFIX/share/doc/libpf/html]])],
            [htmldocdir="$withval"], [htmldocdir=\$\{prefix\}/share/doc/libpf/html])
AC_SUBST(htmldocdir)
AM_CONDITIONAL(ENABLE_DOXYGEN_DOC,test "x$enable_doxygen_doc" = "xyes")

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([Makefile doc/Makefile doc/Doxyfile])
AC_OUTPUT
