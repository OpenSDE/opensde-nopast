
extern RET_TYPE FUNCTION(P1);
RET_TYPE (*orig_FUNCTION)(P1) = 0;

RET_TYPE FUNCTION(P1)
{
	int old_errno=errno;

	handle_file_access_after("FUNCTION", f, 0);
	if (!orig_FUNCTION) orig_FUNCTION = get_dl_symbol("FUNCTION");
	errno=old_errno;

	return orig_FUNCTION(P2);
}
