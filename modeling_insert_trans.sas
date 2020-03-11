
/*needs the modeling_macro.sas the be %included at a higher level*/

%GLOBAL LOOK_LIB;
%GLOBAL LOOK_TABLE;
%GLOBAL LOOK_KEY;
%LET LOOK_LIB = &VAR_LIB;
%LET LOOK_TABLE = &VAR_TABLE;
%LET LOOK_KEY = &KEY_VAR;

/********************************/
/* START TRAN INSERT		*/
/********************************/

%get_values(in_lib=&look_lib,in_table=&look_table,var_list_name=list1,var_name=&look_key);

%MACRO write_action(the_var,out_table,export_type=SAS);
data _null_;
	set &look_lib..&look_table;
	IF UPCASE(&LOOK_KEY)=UPCASE("&the_var") AND NOT (MISSING(&LOOK_KEY));
	call symput ("VALUE_MIN",VALUE_MIN);
	call symput ("VALUE_MAX",VALUE_MAX);
	call symput ("VALUE_MISSING",VALUE_MISSING);
	call symput ("VALUE_POWER",VALUE_POWER);
	call symput ("VALUE_LN",VALUE_LN);
	call symput ("VALUE_ABS",VALUE_ABS);
	call symput ("VALUE_ZERO",VALUE_ZERO);
	call symput ("VALUE_BIN",VALUE_BIN);	 
	call symput ("VALUE_KEEP",VALUE_KEEP);
RUN;

%IF &EXPORT_TYPE=SA %THEN %DO;
	%WRITE_TRANS_CODE(the_var=&&word&i,the_min=&VALUE_MIN,the_max=&VALUE_MAX,the_missing=&VALUE_MISSING,
		the_power=&VALUE_POWER,the_ln=&VALUE_LN,the_abs=%QUOTE(&VALUE_ABS),the_zero=&VALUE_ZERO,
		THE_BIN=%QUOTE(&VALUE_BIN),OUT_TABLE=%NRSTR(FROM_TRANS));
	%WRITE_TRANS_CODE_SA(wknum_count=&I,the_var=&&word&i,the_min=&VALUE_MIN,the_max=&VALUE_MAX,the_missing=&VALUE_MISSING,
		the_power=&VALUE_POWER,the_ln=&VALUE_LN,the_abs=%QUOTE(&VALUE_ABS),the_zero=&VALUE_ZERO,
		THE_BIN=%QUOTE(&VALUE_BIN),OUT_TABLE=%NRSTR(FROM_TRANS_SA));
data new_tran;
	merge FROM_TRANS FROM_TRANS_SA(rename=(t=t_sa));
	ATTRIB VARNAME FORMAT=$80. LABEL = 'INDEPENDENT VARIABLE';
	ATTRIB SA_NAME format=$80. label = 'Scoreadvantage wknum reference';
	VARNAME = "&THE_VAR";
	sa_name = "wknum&I";
RUN;
%END;

%ELSE %DO;
	%WRITE_TRANS_CODE(the_var=&&word&i,the_min=&VALUE_MIN,the_max=&VALUE_MAX,the_missing=&VALUE_MISSING,
		the_power=&VALUE_POWER,the_ln=&VALUE_LN,the_abs=%QUOTE(&VALUE_ABS),the_zero=&VALUE_ZERO,
		THE_BIN=%QUOTE(&VALUE_BIN),OUT_TABLE=%NRSTR(FROM_TRANS));
	data new_tran;
	set FROM_TRANS;
	ATTRIB VARNAME FORMAT=$80. LABEL = 'INDEPENDENT VARIABLE';
	VARNAME = "&THE_VAR";
RUN;
%END;

%IF &VALUE_KEEP=1 %THEN %DO;
	data &out_table;
	  set &out_table NEW_TRAN;
	 run;
%END;

%MEND write_action;

%TRAN_INIT(FLAG=&VAR_TYPE_FLAG,out_table=OUTWRITE)

%string_loop(	var_list=&LIST1,
		action_code = %NRSTR(%WRITE_ACTION(THE_VAR=&&WORD&I,out_Table=OUTWRITE,export_type=&export_type)
					)
			)
;
			
/*GET LOCATION TO PUT ODS HTML OUTPUT*/
ods output directory=dir;
proc datasets library=&out_lib ; run; quit;
ods output close;

data _null_;
	set DIR; if UPCASE(LABEL1) = 'PHYSICAL NAME';
	call symput ('LOCATION',CVALUE1);
run;

options nobyline nonumber nodate nodetails;
title;
data toprint;
	set OUTWRITE(keep=t);
run;
FILENAME routed "&LOCATION/&OUT_TABLE..txt";

PROC PRINTTO PRINT=routed new;
	proc report data=toprint nowindows noalias nocenter noheader;
RUN;
PROC PRINTTO print=print;
RUN;


data &out_lib..&out_Table;
	set OUTWRITE;
RUN;
