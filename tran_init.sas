%MACRO TRAN_INIT (out_table=,varname=varname,FLAG=);
/*this is used in the INSERT TRANS code.*/
/* It initializes a code set with either new var creations, or nothing */
/*depoint updated may2003*/

	ods output directory=dir;
	proc datasets library=work; run; quit;
	ods output close;

	data _null_;
		set DIR; if UPCASE(LABEL1) = 'PHYSICAL NAME';
		call symput ('LOCATION',CVALUE1);
	run;

%IF &FLAG = XXXSDE %THEN %DO;
	%let calc_loc 	= ;
	%let calc_name 	= ;
%END;
%ELSE %DO;
	data nothing;
		ATTRIB &VARNAME FORMAT=$80. LABEL = 'INDEPENDENT VARIABLE';
		ATTRIB t FORMAT=$120. LABEL = 'transformation';		
		t=' ';
	%let calc_loc 	= &LOCATION;
	%let calc_name 	= nothing;	
%END;


%IF (%LENGTH(&FLAG) >0)
	%THEN %DO;
	libname place "&calc_loc";
		data &OUT_TABLE;
			ATTRIB &VARNAME FORMAT=$40. LABEL = 'INDEPENDENT VARIABLE';
			set place.&calc_name;
		WHERE UPCASE(VARNAME) IN ("EXCLUDE_DECEASED" "EXCLUDE_NO_BUREAU" "EXCLUDE_NO_HIT" "EXCLUDE_BNK"
		%string_loop(var_list=&list1, action_code = %NRSTR("%UPCASE(&&word&i)" ))
		);

	%END;
%ELSE %DO;
		data &OUT_TABLE;
		ATTRIB &VARNAME FORMAT=$40. LABEL = 'INDEPENDENT VARIABLE';
%END;
run;
%MEND TRAN_INIT;