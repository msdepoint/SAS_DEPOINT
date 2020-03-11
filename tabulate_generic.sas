%MACRO TABULATE_GENERIC(in_table=,CLASS_LIST=,var_label=, N_var_LIST=,PCT_var_LIST=,PCTSUM_var_LIST=,MEAN_VAR_LIST=,
			min_var_list=,max_var_list=,sum_var_list=,std_var_list=,median_var_list=,
			in_lib=work,ALL_TOGGLE=ALL,wgt=,where_extra=,mylabel="&in_table",out_table=ww,out_lib=work);
/********************************************************************************************************/
/*	DEPOINT OCT2002 Ringel 2004 DePoint Dec2004							*/
/*	this macro does  N and % for a give VARIABLE and a given table with specific formats		*/
/*	Does not have ALL compiles for each class							*/
/*	PCT_VAR_LIST is the list of variables you want to have a percent attached (i.e. BAD rate)	*/
/*	MEAN_VAR_LIST is the list of variables you want MEANED BUT NO %					*/
/*	MIN VAR LIST	" "		you want to MIN (by themselves)					*/
/*	MAX VAR LIST			you want to MAX		"					*/
/*	SUM VAR LIST			you want to SUM		"					*/
/*	STD VAR LIST			you want to STD		"					*/
/*		*******IMPORTANT*********								*/
/*	CLASS LIST IS the list of CLASS VARIABLES. The assumption is that the MACRO VARIABLE NAME	*/
/*	of the FORMAT is the same as the name of the CLASS variable					*/
/*	the FORMAT_FROM_RANK macro is very useful with this macro					*/
/*	USE %QUOTE() when putting multiple vars or class names in parameter variables			*/
/*	ALL_TOGGLE allows for an ALL after each class and at the end. VALID values are ALL or blank	*/
/*	If you must WEIGHT the sample, then use WGT to point to a weight variable			*/
/********************************************************************/
/*	THIS SECTION DETERMINES IF THE CLASS VARIABLES ARE CHAR OR NUM	*/
/*	It assumes that the user has created the formats correctly		*/
	%get_var_names(in_lib=&in_lib,in_table=&in_table,out_table=OUTVAR1,
					var_list_name=OUTVAR1,keep1=%QUOTE(name type),drop_list=%QUOTE(pin cin san hh_id));
	run;
	DATA outvar1;
		set outvar1;
		temp = UPCASE(name);
		DROP name;
		RENAME temp=name;
	RUN;	
	%LET CLASS_LIST_QUOTE=;
	%string_loop(	var_list=&CLASS_LIST,
					action_code = %NRSTR(%LET CLASS_LIST_QUOTE = &CLASS_LIST_QUOTE "%UPCASE(&&word&i)";
										)
				)
	;
	data NUM CHAR;
		set OUTVAR1;
		WHERE UPCASE(NAME) IN (&CLASS_LIST_QUOTE);
		IF type=1 and UPCASE(NAME) IN (&CLASS_LIST_QUOTE) then output NUM;	
			ELSE IF type=2 and UPCASE(NAME) IN (&CLASS_LIST_QUOTE) then output CHAR;
		keep NAME;
	run;
	PROC SORT DATA=num; BY name;/*sort these so they always do it in alpha order*/
	PROC SORT DATA=char; BY name; 	/*a pain in the butt any way you look at it */
	%LET add = &sysindex;
	%get_values(in_lib=work,in_table=NUM,var_list_name=CLASS_LIST_NUM&add,var_name=NAME);
	%get_values(in_lib=work,in_table=CHAR,var_list_name=CLASS_LIST_CHAR&add,var_name=NAME);
/********************************************************************/
/********************************************************************/
/****************************************************************************/
/*	Now, create the class code, and the tabulation code for all specified	*/
%PUT ************NUMERIC &&class_list_num&add ********CHAR &&class_list_char&add;
%let CLASS_CODE=;
%MACRO do_class(class,index);
%IF &INDEX=1 %THEN %DO;	%LET CLASS_CODE = (&class=' ' &ALL_TOGGLE); %END;	/*ALL THE FIRST CLASS	*/
%ELSE 		%DO; 	%LET CLASS_CODE = &CLASS_CODE * (&class=' ' &ALL_TOGGLE); %END;
%MEND do_class;

		/************************************************/
		/* Creating a user defined format for percentage*/
		/************************************************/
        proc format; 
        picture pctpic low-high='009.99 %';
        quit;
        title;


%string_loop(	var_list=&&class_list_char&add &&class_list_num&add,									
				action_code = %NRSTR(%DO_class(class=&&word&i,index=&i)
									)
			)
;
%let FORMAT_CODE=;
%string_loop(	var_list=&&class_list_num&add,	
				action_code = %NRSTR(%LET FORMAT_CODE = &FORMAT_CODE &&word&i &&&&&&word&i....;
									)
			)
;
%string_loop(	var_list=&&class_list_char&add,	
				action_code = %NRSTR(%LET FORMAT_CODE = &FORMAT_CODE &&word&i $&&&&&&word&i....;
									)
			)
;
%let PCT_VAR_CODE=;
%string_loop(	var_list=&PCT_var_LIST,
				action_code = %NRSTR(%LET PCT_VAR_CODE = &PCT_VAR_CODE (&&word&i="&&word&i"*mean*f=percent7.2);
									)
			)
;
%let MEAN_VAR_CODE=;
%string_loop(	var_list=&MEAN_var_LIST,
				action_code = %NRSTR(%LET MEAN_VAR_CODE = &MEAN_VAR_CODE (&&word&i="&&word&i"*mean*f=comma20.2);
									)
			)
;
%let MIN_VAR_CODE=;
%string_loop(	var_list=&MIN_var_LIST,
				action_code = %NRSTR(%LET MIN_VAR_CODE = &MIN_VAR_CODE (&&word&i="&&word&i"*min*f=comma20.2);
									)
			)
;
%let MAX_VAR_CODE=;
%string_loop(	var_list=&MAX_var_LIST,
				action_code = %NRSTR(%LET MAX_VAR_CODE = &MAX_VAR_CODE (&&word&i="&&word&i"*max*f=comma20.2);
									)
			)
;
%let SUM_VAR_CODE=;
%string_loop(	var_list=&SUM_var_LIST,
				action_code = %NRSTR(%LET SUM_VAR_CODE = &SUM_VAR_CODE (&&word&i="&&word&i"*SUM*f=comma20.2);
									)
			)
;
%let STD_VAR_CODE=;
%string_loop(	var_list=&STD_var_LIST,
				action_code = %NRSTR(%LET STD_VAR_CODE = &STD_VAR_CODE (&&word&i="&&word&i"*STD*f=comma14.2);
									)
			)
;
%let MEDIAN_VAR_CODE=;
%string_loop(   var_list=&MEDIAN_var_LIST,
                                action_code = %NRSTR(%LET MEDIAN_VAR_CODE =&MEDIAN_VAR_CODE (&&word&i="&&word&i"*MEDIAN*f=comma20.2);
                                                                        )
                        )
;
%let N_VAR_CODE=;
%string_loop(   var_list=&N_var_LIST,
                                action_code = %NRSTR(%LET N_VAR_CODE =&N_VAR_CODE (&&word&i="&&word&i"*N*f=comma14.);
                                                                        )
                        )
;
%let PCTSUM_VAR_CODE=;
%string_loop(   var_list=&PCTSUM_var_LIST,
                                action_code = %NRSTR(%LET PCTSUM_VAR_CODE =&PCTSUM_VAR_CODE (&&word&i="&&word&i"*PCTSUM*f=pctpic9.);
                                                                        )
                        )
;
/****************************************************************************/
/********************************************************************/
/****************************************************************************************/
/*	NOW do the proc tabulate for the variables and types of analysis specified	*/	
/****************************************************************************************/
proc format; /*this helps with the display of any PCT variables	*/
picture pctpic low-high='009.99%';
quit;
title;
PROC TABULATE NOSEPS FORMAT=comma14.2 DATA= &in_lib..&in_table MISSING OUT=&out_lib..&out_table;
class    &class_LIST;
%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO; weight &wgt;%END;
var &N_VAR_LIST &PCT_var_LIST &PCTSUM_var_LIST &MEAN_var_LIST &MIN_VAR_LIST &MAX_VAR_LIST &SUM_VAR_LIST &STD_VAR_LIST &MEDIAN_VAR_LIST;
table   &CLASS_CODE, ALL="&var_label" *
		((n='#'*f=comma14. PCTN='%'*f=pctpic.) &N_VAR_CODE &MIN_VAR_CODE &MAX_VAR_CODE &PCT_VAR_CODE &PCTSUM_VAR_CODE 
                &MEAN_VAR_CODE &SUM_VAR_CODE
		&STD_VAR_CODE &MEDIAN_VAR_CODE) 
		/BOX = &mylabel ROW=FLOAT MISSTEXT='missing';
	format &FORMAT_CODE;
           %IF %LENGTH(%UNQUOTE(&where_extra)) > 0 %THEN %DO;
		       WHERE %UNQUOTE(&where_extra);
		   %END;
RUN;
PROC DATASETS library=work NOLIST;
	DELETE outvar1 NUM CHAR;
QUIT;
%MEND TABULATE_GENERIC;

