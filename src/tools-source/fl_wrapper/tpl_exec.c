extern $ret_type $function($p1);
$ret_type (*orig_$function)($p1) = 0;

$ret_type $function($p1)
{
	int old_errno=errno;

	handle_file_access_after("$function", f, 0);
	if (!orig_$function) orig_$function = get_dl_symbol("$function");
	errno=old_errno;

	return orig_$function($p2);
}
