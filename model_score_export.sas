%MACRO MODEL_SCORE_EXPORT(model_lib=work,model_table=model,PARM_LIST=,RISKMODEL=,trans_lib=,trans_table=,BETAS=,TYPE=SAS,out_name=JUNK,XBETA_MEAN=9999.9999,extra_lib=work,extra_table=extra);
/*this macro exports the SCORE CODE produced from a FINAL MODEL VALIDATION*/
/*	depoint oct2002 UPDATE jun 2004*/
/* The extra table allows you to pass in more lines to the score code */
/* It must have the same format as valcode */

	%let addition	 = %eval(%SUBSTR(%EVAL(&sysjobid*&sysindex),2,3))_&sysdate; /*this is for exporting*/
	%IF %UPCASE(&TYPE) = SA %THEN 
		%DO; %MAKE_EQ_SA(parm_list=%QUOTE(&PARM_LIST),BETAS_IN=&BETAS,risk=&RISKMODEL,xbeta_mean=&XBETA_MEAN);
		%END;
	%ELSE %DO;%MAKE_EQ_SAS(parm_list=%QUOTE(&PARM_LIST),BETAS_IN=&BETAS,risk=&RISKMODEL,xbeta_mean=&XBETA_MEAN);%END;
	/****************************************************************/
	/*spit out the valcode to the VALCODE AREA			*/
	/****************************************************************/
	options nobyline nonumber nodate nodetails ls=256;
	title;
	/************************************************************************************************/
	/*	TRANSFORMATIONS										*/
	/************************************************************************************************/
		data TRANSFORMATIONS;
		set &trans_lib..&trans_table;
		WHERE UPCASE(VARNAME) IN ("EXCLUDE_DECEASED" "EXCLUDE_NO_BUREAU" "EXCLUDE_NO_HIT" "EXCLUDE_BNK"
		%string_loop(var_list=&parm_list, action_code = %NRSTR("%UPCASE(&&word&i)" ))
		);
		%IF %UPCASE(&TYPE) = SA %THEN %DO;
			%string_loop(var_list=&parm_list, 
			action_code = %NRSTR(
				IF UPCASE(VARNAME) = "%UPCASE(&&word&i)" THEN DO;
					T_SA = TRANWRD(T_SA,COMPRESS(SA_NAME),"WKNUM&I");
					SA_NAME = "WKNUM&I";
					END;
				 )
				)	
		 	keep t_sa; rename t_sa=t; 
		 	%END;
		%ELSE %DO;  keep t; %END;
	run;

	data VALCODE;
		format t $120.;
		do k = 1 to 2;
			if k=1 then t = "/* HSBC BANK (USA) Customer Analytics-Marketing */";
			if k=2 then t = "/* &ADDITION */";
			output;
		end;
		drop k;
	run;
		
	/*make Reason Code*/
	%IF %UPCASE(&TYPE) = SAS %THEN %DO;
	%make_rc_code (in_lib=&model_lib,in_table=&model_table,parm_list=&PARM_LIST,
					wgt=,out_lib=work,out_table=AAReason_CODE,method=MEAN,betas=&betas);
	%END;
	%ELSE %DO; data aareason_code; code='/*NO REASON CODE*/'; %END;

	data VALCODE;
		set 
		valcode &extra_lib..&extra_table TRANSFORMATIONS EQUATION(rename=(v=t)) 				AAREASON_CODE(rename=(code=t));
	run;
	/*GET TRANSFORMATIONS FROM LOCATION */
	/*trans_lib trans_table*/
	/*GET LOCATION OF WORK TO PUT txt OUTPUT*/
		FILENAME routed "./%UPCASE(&out_name&ADDITION).sas";
		data _null_;
			set valcode;
			file routed notitles;
			put @1 t $120.;
			return;
		run;

		FILENAME routed "./backup/%UPCASE(&out_name&ADDITION).sas";
		data _null_;
			set valcode;
			file routed notitles;
			put @1 t $120.;
			return;
		run;

	options ls=96;
%MEND MODEL_SCORE_EXPORT;