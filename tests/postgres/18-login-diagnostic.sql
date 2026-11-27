\set ON_ERROR_STOP on
DO $$ BEGIN
 IF session_user <> 'nl_accept_diagnostic' THEN RAISE EXCEPTION 'Not a diagnostic login'; END IF;
 BEGIN PERFORM * FROM infra_login.records; RAISE EXCEPTION 'Diagnostic read business rows'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
