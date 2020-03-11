%MACRO make_rc_code (in_lib=,in_table=,wgt=,out_lib=,out_table=,method=MEAN,BETAS=,parm_list=);
/*dePoint April 2003*/
/*this code creates the descending orded reason codes for a score*/
/*based on the parameter estimates and the mean/min/max values*/
/*for the supplied input data set*/
/*METHOD can be MEAN or BEST*/

	%MACRO RC_MEAN_makecode(count=,the_var=,the_parameter=,code_label=);
	&code_label	= "RC_value&count = &THE_PARAMETER * (&THE_VAR - &&&THE_VAR.MEAN); RC&count = ""&COUNT-&THE_VAR""; "; 
	%MEND RC_MEAN_makecode;

	%MACRO RC_BEST_makecode(count=,the_var=,the_parameter=,code_label=);
	%IF %SYSEVALF(&THE_PARAMETER>0) %THEN %DO; 	
		&code_label	= "RC_value&COUNT = &THE_PARAMETER * (&THE_VAR - &&&THE_VAR.MIN); RC&count = ""&COUNT-&THE_VAR"";";
		%END;
	%ELSE %DO; 
		&code_label	= "RC_value&COUNT = &THE_PARAMETER * (&THE_VAR - &&&THE_VAR.MAX); RC&count = ""&COUNT-&THE_VAR"";";
		%END; 
	%MEND RC_BEST_makecode;

/************************************************************/
/* Calcuate the MIN, MAX, and MEANS for each variable	*/
/****************************************************************/
/*ods listing close;*/
proc means data=&in_lib..&in_table mean max min;
	var &parm_list;
	%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO; weight &wgt;%END;
ods output summary=mout(keep = 
	%STRING_LOOP(var_list=&parm_list,
				ACTION_CODE=%NRSTR(&&WORD&i.._mean &&WORD&i.._max &&WORD&i.._min
									)
				)
	);
run;
/*ods listing;*/
/****************************************************************/
/*	Output those MIN/MAX/MEAN values to local macro variables	*/
/****************************************************************/
%local num_vars_for_rc;
data _null_;
	set mout;
	%STRING_LOOP(var_list=&parm_list,
				ACTION_CODE=%NRSTR( call symput("&&WORD&I..MEAN",&&WORD&I.._MEAN);
									call symput("&&WORD&I..MIN",&&WORD&I.._MIN);
									call symput("&&WORD&I..MAX",&&WORD&I.._MAX);
									%LET num_vars_for_rc = &I;
 									)
				)
	;	
run;
/*%PUT _USER_;*/
/****************************************************************/
/*	Calcuate REASON codes  SAS code					*/
/****************************************************************/
	data _null_; 
		set &BETAS;
		%string_loop(	var_list=&parm_list, 
					action_code = %NRSTR( call symput ("&&WORD&I.._parm",&&word&i);
										)		
					);
data &out_lib..&out_table;
	format code $120.;
	CODE = "/*Reason code values 1 through 10 will be left for exclusions*/";output;
	CODE = "/*Values 11-99 will be for component variables*/";output;
	CODE = "/*We use  &method Method*/";output;
	CODE = "/*The larger the augmented RC value, the more detrimental to the score*/";output;
	CODE = "/*Thus, the 'more important' the reason*/";output;
	CODE = "array rc_value{%EVAL(10+&num_vars_for_rc)};";output;
	CODE = "array rc{%EVAL(10+&num_vars_for_rc)} $20.;";output;
	CODE = "IF SCORE=1 	THEN DO; RC_value1 = 9999; RC1 = ""1-EXCLUDE_DECEASED""; END;";	output;
	CODE = "ELSE IF SCORE=2	THEN DO; RC_value2 = 9998; RC2 = ""2-EXCLUDE_NO_BUREAU"";END;";	output;
	CODE = "ELSE IF SCORE=3	THEN DO; RC_value3 = 9997; RC3 = ""3-EXCLUDE_NO_HIT"";END;";	output;
	CODE = "ELSE IF SCORE=4	THEN DO; RC_value4 = 9996; RC4 = ""4-EXCLUDE_BNK"";END;";	output;
	CODE = "/*Leave room for more exclusion scores*/";output;
	%STRING_LOOP(var_list=&parm_list,
	ACTION_CODE=%NRSTR(%RC_MEAN_makecode(COUNT=%EVAL(10+&I),the_var=&&WORD&I,the_parameter=&&&&&&WORD&I.._parm,code_label=code)
						output;)
				)
	;
/****************** I CHANGED &METHOD to MEAN because the SAS engine was screwing up **********/

	CODE = "/*Now BUBBLE SORT the array in DESCENDING ORDER*/";output;
	CODE = "/*(+) is more derogatory*/";output;
	CODE = "do k = 1 to %EVAL(10+&num_vars_for_rc);";output;
	CODE = "	do j = 1 to %EVAL(10+&num_vars_for_rc-1);";output;
	CODE = "		if rc_value{j} < rc_value{j+1} then do;";output;
	CODE = "			temp_n 			= rc_value{j};";output;
	CODE = "			temp_c			= rc{j};";output;
	CODE = "			rc_value{j} 	= rc_value{j+1};";output;
	CODE = "			rc{j} 			= rc{j+1};";output;
	CODE = "			rc_value{j+1} 	= temp_n;";output;
	CODE = "			rc{j+1} 		= temp_c;";output;
	CODE = "		end;";output;
	CODE = "	end;";output;
	CODE = "end;";output;
	CODE = " drop temp_n temp_c k j;";output;
run;
%MEND make_rc_code;