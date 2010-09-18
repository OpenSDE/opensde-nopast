/*
 * --- SDE-COPYRIGHT-NOTE-BEGIN ---
 * This copyright note is auto-generated by ./scripts/Create-CopyPatch.
 *
 * Filename: src/tools-source/fl_wrapper/fl_wrapper.c
 * Copyright (C) 2006 - 2010 The OpenSDE Project
 * Copyright (C) 2004 - 2006 The T2 SDE Project
 * Copyright (C) 1998 - 2003 Clifford Wolf
 *
 * More information can be found in the files COPYING and README.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License. A copy of the
 * GNU General Public License can be found in the file COPYING.
 * --- SDE-COPYRIGHT-NOTE-END ---
 *
 * gcc -Wall -O2 -ldl -shared -o fl_wrapper.so fl_wrapper.c
 *
 * ELF Dynamic Loading Documentation:
 *  - http://www.linuxdoc.org/HOWTO/GCC-HOWTO-7.html
 *  - http://www.educ.umu.se/~bjorn/mhonarc-files/linux-gcc/msg00576.html
 *  - /usr/include/dlfcn.h
 */


/* Headers and prototypes */

#ifndef DEBUG
#	define DEBUG 0
#	define LOG(F, ...)
#elif DEBUG == 1
#	define LOG(F, ...)	fprintf(stderr, "fl_wrapper.so debug [%d]: " F "\n", \
					getpid(), __VA_ARGS__)
#else
#	define LOG(F, ...)
#endif
#define ERR(F, ...)		fprintf(stderr, "fl_wrapper.so: " F "\n", __VA_ARGS__)

#define DLOPEN_LIBC 1
#ifndef FLWRAPPER_LIBC
#	define FLWRAPPER_LIBC "libc.so.6"
#endif

#include "fl_wrapper.h"

static void * get_dl_symbol(char *);

struct status_t {
	ino_t   inode;
	off_t   size;
	time_t  mtime;
	time_t  ctime;
};

#ifdef FLWRAPPER_BASEDIR
static void check_write_access(const char * , const char * );
/* only for absolute paths anyway */
#define check_writeat_access(FUNC, FD, FILENAME)	check_write_access(FUNC, FILENAME)
#endif
static void handle_file_access_before(const char *, const char *, struct status_t *);
static void handle_file_access_after(const char *, const char *, struct status_t *);
static void handle_fileat_access_before(const char *, int, const char *, struct status_t *);
static void handle_fileat_access_after(const char *, int, const char *, struct status_t *);

char filterdir[PATH_MAX], wlog[PATH_MAX], rlog[PATH_MAX], *cmdname = "unkown";

/* Wrapper Functions */
#include "fl_wrapper_generated.c"
#include "fl_wrapper_execl.c"

/* Internal Functions */

static void * get_dl_symbol(char * symname)
{
	void * rc;
#if DLOPEN_LIBC
	static void * libc_handle = 0;

	if (!libc_handle) libc_handle=dlopen(FLWRAPPER_LIBC, RTLD_LAZY);
	if (!libc_handle) {
		ERR("Can't dlopen libc: %s", dlerror()); fflush(stderr);
		abort();
	}

	rc = dlsym(libc_handle, symname);
	LOG("Symbol '%s' in libc (%p) has been resolved to %p.", symname, libc_handle, rc);
#else
	rc = dlsym(RTLD_NEXT, symname);
	LOG("Symbol '%s' (RTLD_NEXT) has been resolved to %p.", symname, rc);
#endif
	if (!rc) {
		ERR("Can't resolve %s: %s", symname, dlerror()); fflush(stderr);
		abort();
	}

	return rc;
}

static inline ssize_t readlink_from(char *buf, size_t buf_len, const char *tpl, ...)
{
	ssize_t l;
	va_list ap;

	va_start(ap, tpl);
	vsnprintf(buf, buf_len, tpl, ap);
	va_end(ap);

	if ((l = readlink(buf, buf, buf_len)) < 0)
		return -1;
	buf[l] = '\0';
	return l;
}

static inline ssize_t readonce_from(char *buf, size_t buf_len, const char *tpl, ...)
{
	int fd;
	ssize_t rc;
	va_list ap;

	va_start(ap, tpl);
	vsnprintf(buf, buf_len, tpl, ap);
	va_end(ap);

	/* EINTR? */
	if ((fd = open(buf, O_RDONLY)) < 0)
		return -1;
	else if ((rc = read(fd, buf, buf_len-1)) > 0)
		buf[rc] = '\0';
	close(fd);

	return rc;
}

static inline pid_t pid2ppid(pid_t pid)
{
	pid_t ppid = 0;

	/* in some broken systems the last (pid,ppid) is (1,1)
	   instead of (1,0), good excuse to speed this up a bit */
	if (pid > 1) {
		char buffer[100];

		if (readonce_from(buffer, sizeof(buffer), "/proc/%d/stat", pid) < 0)
			return 0;

		/* format: 27910 (bash) S 27315 ... */
		sscanf(buffer, "%*[^ ] %*[^ ] %*[^ ] %d", &ppid);
	}

	return ppid;
}

/* this is only called from fl_wrapper_init(). so it doesn't need to be
 * reentrant. */
static char *getpname(int pid)
{
	static char p[512];
	char buffer[100];
	char *arg=0, *b;
	int i, rc;

	if ((rc = readonce_from(buffer, sizeof(buffer), "/proc/%d/cmdline", pid)) < 0)
		return "unknown";

	buffer[rc--] = '\0';
	for (i=0; i<rc; i++)
		if (!buffer[i]) { arg = buffer+i+1; break; }

	b = basename(buffer);
	snprintf(p, sizeof(p), "%s", b);

	if ( !strcmp(b, "bash") || !strcmp(b, "sh") || !strcmp(b, "perl") )
		if (arg && *arg && *arg != '-')
			snprintf(p, sizeof(p), "%s(%s)", b, basename(arg));

	return p;
}

/* invert the order by recursion. there will be only one recursion tree
 * so we can use a static var for managing the last ent */
static void addptree(int *txtpos, char *cmdtxt, int pid, int basepid)
{
	static char l[512] = "";
	char *p;

	if (!pid || pid == basepid) return;

	addptree(txtpos, cmdtxt, pid2ppid(pid), basepid);

	p = getpname(pid);

	if ( strcmp(l, p) )
		*txtpos += snprintf(cmdtxt+*txtpos, 4096-*txtpos, "%s%s",
				*txtpos ? "." : "", getpname(pid));
	else
		*txtpos += snprintf(cmdtxt+*txtpos, 4096-*txtpos, "*");

	strcpy(l, p);
}

void copy_getenv (char* var, const char* name)
{
	char *c = getenv(name);
	if (c) strcpy (var, c);
	else var[0]=0;
}

void __attribute__ ((constructor)) fl_wrapper_init()
{
	char cmdtxt[4096] = "";
	char *basepid_txt = getenv("FLWRAPPER_BASEPID");
	int basepid = 0, txtpos=0;

	if (basepid_txt)
		basepid = atoi(basepid_txt);

	LOG("FLWRAPPER_BASEPID=%d", basepid);

	addptree(&txtpos, cmdtxt, getpid(), basepid);
	cmdname = strdup(cmdtxt);

	LOG("cmdname=\"%s\"", cmdname);

	/* we copy the vars, so evil code can not unset them ... e.g.
	   the perl/spamassassin build ... -ReneR */
	copy_getenv(filterdir, "FLWRAPPER_FILTERDIR");
	copy_getenv(wlog, "FLWRAPPER_WLOG");
	copy_getenv(rlog, "FLWRAPPER_RLOG");

	LOG("FLWRAPPER_FILTERDIR=\"%s\"", filterdir);
	LOG("FLWRAPPER_RLOG=\"%s\"", rlog);
	LOG("FLWRAPPER_WLOG=\"%s\"", wlog);
}

#ifdef FLWRAPPER_BASEDIR
static void check_write_access(const char * func, const char * file)
{
	(void) func;

	if (*file == '/') { /* do only check rooted paths */
		while (file[1] == '/') file++;

		if (!strcmp(file, "/dev/null") || !strncmp(file, "/tmp", 4)) {
		}
		else if (strncmp(file, FLWRAPPER_BASEDIR, sizeof(FLWRAPPER_BASEDIR)-1)) {
			ERR("write outside basedir (%s): %s", FLWRAPPER_BASEDIR, file);
			fflush(stderr);
			exit(-1);
		}
	}
}
#endif

static void handle_file_access_before(const char * func, const char * file,
				      struct status_t * status)
{
	struct stat st;
#if DEBUG != 1
	(void) func;
#endif

	if (lstat(file,&st) < 0) {
		status->inode=0;  status->size=0;
		status->mtime=0;  status->ctime=0;
		LOG("%s(\"%s\"): No such file or directory", func, file);
	} else {
		status->inode=st.st_ino;    status->size=st.st_size;
		status->mtime=st.st_mtime;  status->ctime=st.st_ctime;
		LOG("%s(\"%s\"): inode info backed up", func, file);
	}
}

static void handle_fileat_access_before(const char * func, int dirfd, const char * file,
					struct status_t * status)
{
	struct stat st;
#if DEBUG != 1
	(void) func;
#endif

	if ( fstatat(dirfd, file, &st, AT_SYMLINK_NOFOLLOW) ) {
		status->inode=0;  status->size=0;
		status->mtime=0;  status->ctime=0;
		LOG("%s(%d, \"%s\"): No such file or directory", func, dirfd, file);
	} else {
		status->inode=st.st_ino;    status->size=st.st_size;
		status->mtime=st.st_mtime;  status->ctime=st.st_ctime;
		LOG("%s(%d, \"%s\"): inode info backed up", func, dirfd, file);
	}
}

static const char *make_file_absolute(char *absfile, const char *file)
{
	if (file[0] == '/')
		return file;
	else {
		char cwd[PATH_MAX];
		if (getcwd(cwd, PATH_MAX) == NULL)
			return NULL;
		snprintf(absfile, PATH_MAX, "%s/%s", cwd, file);
		return absfile;
	}
}

static const char *make_fileat_absolute(char *absfile, int dirfd, const char *file)
{
	if (file[0] == '/')
		return file;
	else if (dirfd == AT_FDCWD)
		return make_file_absolute(absfile, file);
	else {
		char cwd[PATH_MAX];
		if (readlink_from(cwd, PATH_MAX, "/proc/self/fd/%d", dirfd) < 0)
			return NULL;
		snprintf(absfile, PATH_MAX, "%s/%s", cwd, file);
		return absfile;
	}
}

/* sort of, private realpath, mostly not readlink() */
static void sanitize_absfile(char *absfile, const char *file)
{
	const char* src = file; char* dst = absfile;
	/* till the end, remove //, ./ and ../ parts */
	while (dst < absfile + PATH_MAX && *src) {
		if (*src == '/' && src[1] == '/')
			while (src[1] == '/') src++;
		else if (*src == '.') {
			if (src[1] == '.' && (src[2] == '/' || src[2] == 0)) {
				if (dst > absfile+1) --dst; /* jump to last '/' */
				while (dst >absfile+1 && dst[-1] != '/')
					--dst;
				src += 2; if (*src) src++;
				while (*src == '/') src++;
				continue;
			}
			else if (src[1] == '/' || src[1] == 0) {
				src += 1; if (*src) src++;
				while (*src == '/') src++;
				continue;
			}
		}
		*dst++ = *src++;
	}
	*dst = 0;
	/* remove trailing slashes */
	while (--dst, dst > absfile+1 && *dst == '/')
		*dst = 0;
}

static inline void log_append(const char *logfile, const char *fmt, ...)
{
	va_list ap;
	char buf[PATH_MAX];
	int fd, l;

	va_start(ap, fmt);
	l = vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);

#ifdef __USE_LARGEFILE
	fd=open64(logfile,O_APPEND|O_WRONLY|O_LARGEFILE,0);
#else
#	warning "The wrapper library will not work properly for large logs!"
	fd=open(logfile,O_APPEND|O_WRONLY,0);
#endif
	if (fd == -1) return;

	flock(fd, LOCK_EX);
	lseek(fd, 0, SEEK_END);

	/* EINTR? */
	write(fd,buf,l);

	close(fd);
}

static inline void _handle_file_access_after(const char *func, const char *absfile,
					     struct status_t *status, struct stat *st)
{
	char *logfile, filterdir2 [PATH_MAX], *tfilterdir;

	if ((status != NULL) && (status->inode != st->st_ino ||
	     status->size  != st->st_size || status->mtime != st->st_mtime ||
	     status->ctime != st->st_ctime)) {
		logfile = wlog;
		LOG("%s(\"%s\"): inode was modified", func, absfile);
	} else {
		logfile = rlog;
		LOG("%s(\"%s\"): inode was not modified", func, absfile);
	}
	if (logfile == NULL) return;

	/* We ignore access inside the collon seperated directory list
	   $FLWRAPPER_BASE, to keep the log smaller and reduce post
	   processing time. -ReneR */
	strcpy (filterdir2, filterdir); /* due to strtok - sigh */
	tfilterdir = strtok(filterdir2, ":");
	for ( ; tfilterdir ; tfilterdir = strtok(NULL, ":") )
	{
		if ( !strncmp(absfile, tfilterdir, strlen(tfilterdir)) ) {
			LOG("%s(\"%s\"): skipped due to filterdir \"%s\"", func, absfile, tfilterdir);
			return;
		}
	}
	LOG("%s(\"%s\"): logging to \"%s\"", func, absfile, logfile);
	log_append(logfile, "%s.%s:\t%s\n", cmdname, func, absfile);
}

static void handle_file_access_after(const char * func, const char * file,
				     struct status_t * status)
{
	struct stat st;
	const char *file2;
	char absfile[PATH_MAX];

	LOG("%s(\"%s\"): post processing", func, file);

	if (strcmp(file, wlog) == 0) return;
	else if (strcmp(file, rlog) == 0) return;
	else if (lstat(file, &st) < 0) return;

	file2 = make_file_absolute(absfile, file);
	if (file2 == NULL) {
		ERR("%s(\"%s\"): failed to make absolute!", func, file);
		return;
	} else {
		LOG("%s(\"%s\"): is now absolute", func, file2);
	}

	sanitize_absfile(absfile, file2);
	LOG("%s(\"%s\"): is now sanitized", func, absfile);

	_handle_file_access_after(func, absfile, status, &st);
}

static void handle_fileat_access_after(const char * func, int dirfd, const char * file,
				       struct status_t * status)
{
	struct stat st;
	const char *file2;
	char absfile [PATH_MAX];

	LOG("%s(%d, \"%s\"): post processing", func, dirfd, file);

	if (strcmp(file, wlog) == 0) return;
	else if (strcmp(file, rlog) == 0) return;
	else if (fstatat(dirfd, file, &st, AT_SYMLINK_NOFOLLOW) < 0) return;

	file2 = make_fileat_absolute(absfile, dirfd, file);
	if (file2 == NULL) {
		ERR("%s(%d, \"%s\"): failed to make absolute!", func, dirfd, file);
		return;
	} else {
		LOG("%s(\"%s\"): is now absolute", func, file2);
	}

	sanitize_absfile(absfile, file2);
	LOG("%s(\"%s\"): is now sanitized", func, absfile);

	_handle_file_access_after(func, absfile, status, &st);
}
