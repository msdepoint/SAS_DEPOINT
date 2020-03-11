%MACRO superkey_bd_rollup(in_lib=work,in_table=,unique_rollup=superkey,out_lib=,out_table=rolled,tsl=);
/**************************************************************/
/**************************************************************/
/*This macro rolls up BD (wide form) to a super key level)		*/
/* DePoint Jun 2005													*/
/**************************************************************/
/**************************************************************/

	/*****************************************/
	/*****************************************/
	/* Helper macros								*/
	/*****************************************/
	/*****************************************/
	%MACRO do_da_roll(varname=,newname=,var_type_value=);
		/*var_type=1 --> MAX */
		/*var_type=2 --> MIN */
		/*var_type=3 --> SUM */
		%IF &var_type_value = 1 %THEN %DO;		MAX(&varname)		AS &newname,		%END;
		%ELSE
		%IF &var_type_value = 2 %THEN %DO;		MIN(&varname)		AS &newname,		%END;
		%ELSE
		%IF &var_type_value = 3 %THEN %DO;		SUM(&varname)		AS &newname,		%END;
	%MEND do_da_roll;
	
	%MACRO rollup(out_lib=work,out_table=rollup,varlist=,var_type=,in_lib=work,in_table=);
	/*must use %QUOTE for varlist*/
	%PUT *****&varlist *****VAR_TYPE=&VAR_TYPE**;
	PROC SQL;
		CREATE TABLE &out_lib..&out_table AS
		SELECT 
		%STRING_LOOP(var_list=%QUOTE(&varlist),
		ACTION_CODE=%NRSTR( %do_da_roll(varname=&&word&i,newname=sk&var_type._&&word&i,var_type_value=&var_type) )
		)
		&unique_rollup

	FROM &in_lib..&in_table
	GROUP BY &unique_rollup
	;
	%MEND rollup;
	/*****************************************/
	/*****************************************/

/*****************************************/
/*****************************************/
%get_var_names(in_lib=&in_lib,in_table=&in_table,out_table=thevars,var_list_name=LIST1,
        out_lib=work,keep1=%QUOTE(name type),drop_list=%QUOTE(&unique_rollup PIN SERIES_DATE_H1 SERIES_DATE_H2
	SERIES_DATE_H3 SERIES_DATE_H4 SERIES_DATE_H5 SERIES_DATE_H6  SERIES_DATE_P1 SERIES_DATE_P2
	SERIES_DATE_P3 SERIES_DATE_P4 SERIES_DATE_P5 SERIES_DATE_P6 HH_ID HH_ID_H1 HH_ID_H2 HH_ID_H3 HH_ID_H4
	HH_ID_H5 HH_ID_H6 HH_ID_P1 HH_ID_P2 HH_ID_P3 HH_ID_P4 HH_ID_P5 HH_ID_P6 OBSDATE RAWSEQ ACCT_BRANCH_PREFIX
	ASSIGNED_BRANCH PRIME_BRANCH_NUM_HH STANDARDIZEDOPENDATE STANDARDIZEDOPENDATE));
/*Get deduped list of variable names*/

DATA chopit;
	SET thevars;
	WHERE type = 1; /*=1 is numeric */
	IF (index(UPCASE(name),'_IND'))		OR (index(UPCASE(name),'AGE')) 
	OR (index(UPCASE(name),'MONTHS_AS'))	OR (index(UPCASE(name),'_MOS'))
	OR (index(UPCASE(name),'FLAG'))		OR (index(UPCASE(name),'INDICATOR'))
	OR (index(UPCASE(name),'IND_'))		OR (index(UPCASE(name),'MOSAS'))
	OR (index(UPCASE(name),'MOSSINCE'))	OR (index(UPCASE(name),'MOS_SINCE'))
	OR (index(UPCASE(name),'INDH'))		OR (index(UPCASE(name),'INDC'))
	OR (index(UPCASE(name),'CODE'))		OR (index(UPCASE(name),'_CODE'))
	OR (index(UPCASE(name),'_FLAG'))
									THEN var_type = 1;				/*1=MAX*/
	ELSE IF (index(UPCASE(name),'SCORE')) 
	OR (index(UPCASE(name),'MODEL'))
									THEN var_type = 2;	/*2=MIN*/
	ELSE var_type = 3;												/*3=SUM*/
	KEEP name var_type;
RUN;
PROC SORT DATA=chopit NODUPKEY; BY name;

DATA maxvars minvars sumvars;
	SET chopit;
	IF var_type=1 THEN OUTPUT maxvars;
	ELSE IF var_type=2 THEN OUTPUT minvars;
	ELSE IF var_type=3 THEN OUTPUT sumvars;
RUN;

/* do the rollups */
%LET merge_list	= ;

/***********Max Variables	**********/
%get_values(in_lib=work,in_table=maxvars,	var_list_name=maxvars,var_name=name,delimiter=%QUOTE());
%IF %LENGTH(&maxvars) > 0 %THEN %DO;
	%rollup(out_lib=work,out_table=rollup_max,varlist=%QUOTE(&maxvars),var_type=1,in_lib=&in_lib,in_table=&in_table);
	PROC SORT DATA=rollup_max; BY &unique_rollup;
	%LET merge_list = &merge_list rollup_max;
%END;

/***********MIN Variables	**********/
%get_values(in_lib=work,in_table=minvars,	var_list_name=minvars,var_name=name,delimiter=%QUOTE());
%IF %LENGTH(&minvars) > 0 %THEN %DO;
	%rollup(out_lib=work,out_table=rollup_min,varlist=%QUOTE(&minvars),var_type=2,in_lib=&in_lib,in_table=&in_table);
	PROC SORT DATA=rollup_min; BY &unique_rollup;
	%LET merge_list = &merge_list rollup_min;
%END;

/***********SUM Variables	**********/
%get_values(in_lib=work,in_table=sumvars,	var_list_name=sumvars,var_name=name,delimiter=%QUOTE());
%IF %LENGTH(&sumvars) > 0 %THEN %DO;
	%rollup(out_lib=work,out_table=rollup_sum,varlist=%QUOTE(&sumvars),var_type=3,in_lib=&in_lib,in_table=&in_table);
	PROC SORT DATA=rollup_sum; BY &unique_rollup;
	%LET merge_list = &merge_list rollup_sum;
%END;

/***********Merge Together	**********/
DATA &out_lib..&out_table;
	MERGE &merge_list;
	BY &unique_rollup;
RUN;

%MEND superkey_bd_rollup;


