
extern RET_TYPE FUNCTION(P1);
RET_TYPE (*orig_FUNCTION)(P1) = 0;

RET_TYPE FUNCTION(P1)
{
	struct status_t status;
	int old_errno=errno;
	RET_TYPE rc;
	mode_t b = 0;

#ifdef FLWRAPPER_BASEDIR
	if (a & (O_WRONLY|O_CREAT|O_APPEND))
		check_write_access("FUNCTION", f);
#endif

	handle_file_access_before("FUNCTION", f, &status);
	if (!orig_FUNCTION) orig_FUNCTION = get_dl_symbol("FUNCTION");
	errno=old_errno;

#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: going to run original FUNCTION() at %p (wrapper is at %p).\n",
		getpid(), orig_FUNCTION, FUNCTION);
#endif

	if (a & O_CREAT) {
	  va_list ap;

	  va_start(ap, a);
	  b = va_arg(ap, mode_t);
	  va_end(ap);

	  rc = orig_FUNCTION(P2, b);
	}
	else
	  rc = orig_FUNCTION(P2);

	old_errno=errno;
	handle_file_access_after("FUNCTION", f, &status);
	errno=old_errno;

	return rc;
}
