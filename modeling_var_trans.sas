options nobyline nonumber nodate nodetails;
title;
/**********************************************************************************************/
/* need a %include modeling_macros.sas at a higher level*/

%MACRO TRAN_OR_NOT(in_lib,in_table,out_table,out_lib=work,USE_TRANS=N);
DATA &out_lib..&out_table;
	SET &in_LIB..&in_TABLE;
%IF &USE_TRANS=Y %THEN %DO; /******NOTHING*****/%END;
%ELSE %DO; value_missing=.; value_min=.;	%END;
RUN;
%MEND TRAN_OR_NOT;

/**********************************************************************************************/
%TRAN_OR_NOT(in_lib=&var_lib,in_table=&var_table,USE_TRANS=&Transf_test,out_table=TOINSERT);
/**********************************************************************************************/
/* Call the transformation insertion program*/
/* DEPOINT oct 2002*/
/* supply a table with variable names*/
%let var_lib		= work;
%let var_table		= TOINSERT;
%let out_lib		= WORK;
%let out_table		= TEST_TRANSF1;
%let export_type	= SAS; /* assume a SAS export type at this stage. the real insert trans can use ScoreAdvantage*/
%include '/data/41/fmsccanalytics/common/opencode/modeling_insert_trans.sas';

/**********************************************************************************************/
/*	TRANSFORMATIONS										*/
/*GET TRANSFORMATIONS FROM LOCATION */
/*GET LOCATION OF WORK TO PUT txt OUTPUT*/
ods output directory=dir;
proc datasets library=work; run; quit;
ods output close;

data _null_;
	set DIR; if UPCASE(LABEL1) = 'PHYSICAL NAME';
	call symput ('LOCATION',CVALUE1);
run;
options nobyline nonumber nodate nodetails;
title;

data TOPRINT;
	set &out_lib..&out_table(keep=t);
run;
FILENAME routed "&LOCATION/tran_full.txt";

PROC PRINTTO PRINT=routed new;
	proc report data=toprint nowindows noalias nocenter noheader;
RUN;
PROC PRINTTO print=print;
RUN;
%let the_trans=%QUOTE(%INCLUDE  "&location/tran_full.txt" );
/************************************************************************************************/
/************************************************************************************************/
/**********************************************************************************************/
/************************************************************************************************/
/*GET INDEPENDENT VARIABLES */
data IND_TEMP;	&the_trans; run;
%get_var_names(in_lib=work,in_table=IND_TEMP,out_table=INDVARS,var_list_name=INDVARS,
                                out_lib=work,keep1=%QUOTE(name label),
                drop_list=%QUOTE())
                
/************************************************************************************************/
/* PRINT OUT THE REMAINING POTENTIAL INDEPENDENT VARIABLES*/
PROC PRINT DATA=INDVARS;
	TITLE "Independent variables still available for modeling";
	VAR NAME LABEL;
run;
/************************************************************************************************/
DATA TRAN_IT;
	SET &MODEL_LIB..&MODEL_TABLE;
	&THE_TRANS;
	keep &DEPVAR &INDVARS;
RUN;
/*********************************************************/
/*	GET NUMERIC VARIABLES		*/
/****************************************/
%get_var_names(in_lib=work,in_table=TRAN_IT,out_table=LIST1,var_list_name=LIST1,
                                out_lib=work,keep1=%QUOTE(name format label),
                drop_list=%QUOTE(&DEPVAR));
data numeric;
        set list1;
        if MISSING(format) then output numeric;
run;
%get_values(in_lib=work,in_table=numeric,var_list_name=NUMERIC,var_name=name);           

/************************************************************************************************/
/*Transform the variables using various methods*/
/* The user is left to choose the best transformation*/
%VARIABLE_TRANSFORMATION(in_lib=WORK,in_table=tran_it,DEPVAR=&DEPVAR,INDVARS=%QUOTE(&NUMERIC));
