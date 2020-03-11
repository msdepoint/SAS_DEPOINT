%MACRO WRITE_TRANS_CODE(the_var,the_min=0,the_max=999999,the_missing=0,
			the_power=1,the_ln=0,the_abs=0,the_zero=0,the_bin=0,OUT_TABLE=%NRSTR(TRAN&THE_VAR));

/* DEPOINT NOV 2002*/
/* this code creates transformation code that can be modified manually later*/
	data t_pre;
		format t $120.;
		DO COUNT=1 to 10;
			t = '';
			OUTPUT;
		END;
	run;	
	
	DATA %UNQUOTE(&OUT_TABLE);
		set T_PRE;
		IF COUNT=1		THEN t = "IF &the_var 	= 0 THEN &the_var = &the_zero;";
		ELSE IF COUNT=2 	THEN t = "IF . < &the_var 	< &the_min 	THEN &the_var = &the_min;";
		ELSE IF COUNT=3		THEN t = "IF &the_var 	> &the_max 	THEN &the_var = &the_max;";
		ELSE IF COUNT=4 	THEN t = "IF &the_var   = . THEN &the_var = &the_missing;"; 
		ELSE IF COUNT=5		THEN 
			DO;
				%IF &the_abs=0 AND &the_LN=0 %THEN %DO;
				t = "&the_var		= &the_var**&the_power;";
				%END;
			END;
		ELSE IF COUNT=6		THEN 
			DO;
				%IF	%EVAL(&the_ABS > 0 OR &the_ABS < 0) %THEN %DO;
				t = "&the_var = ABS(&the_var + (&the_ABS));";
				%END;
			END;
		ELSE IF COUNT=7 THEN 
			DO;
				%IF	(&the_LN=1)  %THEN %DO;
				t = "&the_var = LOG(&the_var + 1);";
				%END;
			END;
		ELSE IF COUNT=8 THEN
			DO; 	%IF %EVAL(&THE_BIN>0 OR &THE_BIN<0) %THEN %DO;
				t = "&the_var = (&the_var>&the_bin);";
				%END;
			END;
		ELSE IF COUNT=9 THEN 
			DO;
				%IF (%EVAL(&THE_BIN>0 OR &THE_BIN<0)) %THEN %DO;
					t = "LABEL &the_var = ""(&the_var>&the_bin)"";";
					%END;
				%ELSE %IF (&the_LN=1) %THEN %DO;
					t = "LABEL &the_var = ""LOG(&the_var + 1)""; ";
				%END;
				%ELSE %IF (&the_ABS > 0 OR &the_ABS < 0) %THEN %DO;
					t = "LABEL &the_var = ""ABS(&the_var + (&the_ABS))"";";
				%END;
				%ELSE %DO;
					t = "LABEL &the_var = ""&the_var**&THE_POWER""; ";
				%END;
			END;

	if missing(t) AND NOT(COUNT=10) then delete;
	DROP COUNT;
	run;
%MEND WRITE_TRANS_CODE; 
