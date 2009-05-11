extern $ret_type $function($p1);
$ret_type (*orig_$function)($p1) = 0;

$ret_type $function($p1)
{
	struct status_t status;
	int old_errno=errno;
	$ret_type rc;

	handle_file_access_before("$function", f, &status);
	if (!orig_$function) orig_$function = get_dl_symbol("$function");
	errno=old_errno;

#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: going to run original $function() at %p (wrapper is at %p).\n",
		getpid(), orig_$function, $function);
#endif
	rc = orig_$function($p2);

	old_errno=errno;
	handle_file_access_after("$function", f, &status);
	errno=old_errno;

	return rc;
}
