%MACRO make_eq_SAS(parm_list,BETAS_IN,out_table=EQUATION,risk=Y,xbeta_mean=9999.9999);
	%local numvars;
	data _null_; 
		set &BETAS_IN;
		call symput ('INTERCEPT',INTERCEPT);
		%string_loop(	var_list=&parm_list, 
					action_code = %NRSTR( call symput ("parm_value&i",&&word&i);
										%LET NUMVARS=&i;)		
					);
	run;
	data &OUT_TABLE;
		ATTRIB V FORMAT=$120. LABEL = 'SAS SCORECODE';
		V= "xbeta = &INTERCEPT"; output;
		%string_loop(	var_list=&parm_list, 
			action_code = %NRSTR(V = "+ (&&WORD&I * &&PARM_VALUE&I)"; output;)	);
		V = ";";				output;
		V = "PRED = 1/(1+exp(-xbeta));";	output;
		V = "PRED_scaled = exp(xbeta - (&xbeta_mean))/(1+exp(xbeta - (&xbeta_mean)));";	output;

		%IF &RISK=Y %THEN %DO;
			V = "IF PRED>= 0.990 THEN PRED=0.990;"; 				output;
			V = "SCORE = ROUND((1-PRED)*1000); IF SCORE=1000 THEN SCORE=999;"; 	output;
			V = "IF PRED_scaled>= 0.990 THEN PRED_scaled=0.990;";			output;
			V = "SCORE_scaled = ROUND((1-PRED_scaled)*1000); IF SCORE_scaled=1000 THEN SCORE_scaled=999;"; 	output;
		%END;
		%ELSE %DO;
			V = "SCORE = ROUND(PRED*1000);";		output;
			V = "IF SCORE <= 10 THEN SCORE=10;";		output;
			V = "SCORE_scaled = ROUND(PRED_scaled*1000); IF SCORE_scaled=1000 THEN SCORE_scaled=999;"; 	output;
			V = "IF SCORE_scaled <= 10 THEN SCORE_scaled=10;";		output;

		%END;
			V = "IF EXCLUDE_DECEASED THEN SCORE=1;";	output;
			V = "ELSE IF EXCLUDE_NO_BUREAU THEN SCORE=2;";	output;
			V = "ELSE IF EXCLUDE_NO_HIT THEN SCORE=3;";	output;
			V = "ELSE IF EXCLUDE_BNK THEN SCORE=4;";	output;			
			V = "/*CREATION DATE = &SYSDATE*/";		output;
	run;
%MEND make_eq_SAS;
