extern $ret_type $function($p1);
$ret_type (*orig_$function)($p1) = 0;

$ret_type $function($p1)
{
	struct status_t status;
	int old_errno=errno;
	$ret_type rc;
	mode_t b = 0;

#ifdef FLWRAPPER_BASEDIR
	if (a & (O_WRONLY|O_CREAT|O_APPEND))
		check_write_access("$function", f);
#endif

	handle_file_access_before("$function", f, &status);
	if (!orig_$function) orig_$function = get_dl_symbol("$function");
	errno=old_errno;

#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: going to run original $function() at %p (wrapper is at %p).\n",
		getpid(), orig_$function, $function);
#endif

	if (a & O_CREAT) {
	  va_list ap;

	  va_start(ap, a);
	  b = va_arg(ap, mode_t);
	  va_end(ap);

	  rc = orig_$function($p2, b);
	}
	else
	  rc = orig_$function($p2);

	old_errno=errno;
	handle_file_access_after("$function", f, &status);
	errno=old_errno;

	return rc;
}
