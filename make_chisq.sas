%MACRO MAKE_CHISQ(in_table=,LHS=,IND_VARIABLES=,GROUPS=10,out_table=OUT_CHISQ,out_lib=work,in_lib=work,PRINT=NO);
/*****************************************************************/
/*****************************************************************/
/***                                                          	**/
/***  MACRO FOR EXPLORATORY DATA ANALYSIS:                    	**/
/***  by Katy Sunde, Decision Analysis                        	**/
/***  7/19/99, revised 8/27/99                                	**/
/***	MODIFIED BY DEPOINT 9OCT2002                          	**/
/***  SUMMARY: This macro will perform the Pearson Chi-Square 	**/
/***  test of association between a list of independent       	**/
/***  variables and the dependent variable.  The null         	**/
/***  hypothesis is that there is NO association. The null    	**/
/***  is rejected for large chi-square values.  In this test, 	**/
/***  the independent variable is first ranked in a user      	**/
/***  specified number of groups and then the ranks are       	**/
/***  tested for association with the dependent variable.    	**/
/***                                                        	**/
/***		data test1;					**/
/***			do y=1 to 200;				**/
/***			c + 23;					**/
/***			flag = ranuni(17) < .25;		**/
/***			output;					**/
/***		end;						**/
/***		RUN;						**/
/***  %MAKE_CHISQ(in_table=test,LHS=flag,		 	**/
/***		IND_VARIABLES=%QUOTE(c d),		 	**/
/***		GROUPS=10,out_table=OUT_CHISQ,		 	**/
/***		out_lib=work,in_lib=work);		 	**/
/***								**/	
/***  OUTPUT:  This macro will output a dataset in the        	**/
/***           library where the original data is stored      	**/
/***           including: the independent variable names and  	**/
/***           their Chi-Square statistics, corresponding     	**/
/***           p-values and degrees of freedom		  	**/
/***           The macro will also print the above data, in   	**/
/***           order of largest to smallest chi square value. 	**/
/***                                                          	**/
/*****************************************************************/
/*****************************************************************/

		*************************************************************;
		/*PROVIDE THE RANK for EVERY INDEPENDENT VARIABLE*/
		*************************************************************;
		proc rank DATA=&in_lib..&in_table GROUPS=&GROUPS TIES=MEAN 	out=R;
			var &IND_VARIABLES;
		run;
		*************************************************************;
		/*ASSIGN MISSINGS TO BUCKET*/
		*************************************************************;
		DATA FIX_MISS;
			SET R;
			%string_loop(	var_list=%UNQUOTE(&IND_VARIABLES),
				action_code = %NRSTR(IF MISSING(&&word&i) then &&word&i=&GROUPS+1;
										ELSE &&word&i=&&word&i;					
									)
			)
		RUN;

	%MACRO doitcode(THE_VAR,out_table,in_table=R,DEPVAR=&LHS);
		ods listing close;
				PROC FREQ DATA=R; /*do freq to determine if missing values in STRATA*/
					TABLES &THE_VAR*(&DEPVAR)/CHISQ;
					OUTPUT OUT=FROM_FREQ1 NMISS;
				PROC FREQ DATA=FIX_MISS;	/*put missing in their own bucket*/
					TABLES &THE_VAR*(&DEPVAR)/CHISQ;
					OUTPUT OUT=FROM_FREQ2 PCHI;
				RUN;
			ods listing;
		%IF &SYSERR >3 %THEN %DO; /*if ALL missing or all same value*/
		data &OUT_TABLE;
			ATTRIB VARNAME FORMAT=$40. LABEL='Independent Variable Name';
			VARNAME="&THE_VAR";
			_pchi_	=.;
			p_pchi	=.;
			df_pchi	=.;
			nmiss	=9999;
		run;
		%END;
		%ELSE %DO;
			DATA &out_table;
			MERGE FROM_FREQ2 FROM_FREQ1;
			ATTRIB VARNAME FORMAT=$40. LABEL='Independent Variable Name';
			VARNAME="&THE_VAR";
			label _pchi_ = "CHI VALUE";
			label p_pchi = "CHI PROB";
			label DF_PCHI = "DF";
			RUN;
			proc datasets lib=work memtype=data NOLIST;
				DELETE FROM_FREQ1 FROM_FREQ2 ;
			run;
		%END;
	%MEND doitcode;
data CHI;
	ATTRIB VARNAME FORMAT=$40. LABEL='Independent Variable Name';
	ATTRIB _pchi_ 	FORMAT=best8.;
	ATTRIB p_pchi 	FORMAT=best8.;
	ATTRIB df_pchi 	FORMAT=best8.;
	ATTRIB nmiss 	FORMAT=best8.;
run;

%string_loop(	var_list=%UNQUOTE(&IND_VARIABLES),
				action_code = %NRSTR(%doitcode(THE_VAR=&&word&i,out_table=from_chi,in_table=R,DEPVAR=&LHS);
									 PROC APPEND BASE=CHI DATA=FROM_CHI FORCE;
									 
									)
			)
;
PROC SORT DATA=CHI OUT=&out_lib..&out_table;
 BY DESCENDING _PCHI_;
RUN;
%IF &PRINT=YES %THEN %DO;
	PROC PRINT DATA=&out_lib..&out_table label;
	 VAR VARNAME  _PCHI_ DF_PCHI P_PCHI NMISS;
	  FORMAT _PCHI_ 9.7;
	  FORMAT P_PCHI 11.9;
	RUN;
%END;
%MEND MAKE_CHISQ;
