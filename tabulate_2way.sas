%macro TABULATE_2way(in_lib,in_table,class1,class2,THEVAR,display_type,wgt=,ALL_TOGGLE=ALL,out_table=blah);
/********************************************************************************/
/* CHAMPION-CHALLENGER TABULATE MACRO WITH/WITHOUT WEIGHTS			*/ 
/* M.DePoint; A.Chin 30APR2003							*/
/* this assumes a format for each class with the macro variable label 		*/
/* of the format equal to the class name 					*/
/* the FORMAT_FROM_RANK macro is very useful with this macro 			*/
/* additional functionality added with WEIGHT statement 			*/
/* Within each cell, you can produce: 						*/
/* MEAN w/ percent 								*/
/* SUM OF PERCENT - USED IN ROLL RATE FOR $ % 					*/
/* COUNT 									*/
/* MEAN w/o percent 								*/
/* PERCENTAGE OF TOTAL 								*/
/* 	- Latest Update Corrects for > 100% tabulation using PCT_TTL option (AC)*/
/********************************************************************************/

%IF %UPCASE(&DISPLAY_TYPE) = MEAN_PCT %THEN %DO;
%let action = %STR(*mean=' '*f=PERCENT8.4);
%let tab_lib = &in_lib;
%let tab_table = &in_table;
%let var_final = &thevar;
%let label = PERCENT RESPONSE WITHIN CELL OF;
%GOTO TABLE;
%END;

%ELSE %IF %UPCASE(&DISPLAY_TYPE) = SUM_PCT %THEN %DO;
%let action = %STR(*SUM=' '*f=PERCENT7.2);
%let tab_lib = &in_lib;
%let tab_table = &in_table;
%let var_final = &thevar;
%let label = SUM PERCENT;
%GOTO TABLE;

%END;

%ELSE %IF %UPCASE(&DISPLAY_TYPE) = COUNT %THEN %DO;
%let action = %STR(*sum=' '*f=COMMA10.);
%let tab_lib = &in_lib;
%let tab_table = &in_table;
%let var_final = &thevar;
%let label = COUNT;
%GOTO TABLE;
%END;

%ELSE %IF %UPCASE(&DISPLAY_TYPE) = MEAN %THEN %DO;
%let action = %STR(*mean=' '*f=COMMA10.);
%let tab_lib = &in_lib;
%let tab_table = &in_table;
%let var_final = &thevar;
%let label = MEAN;
%GOTO TABLE;
%END;

%ELSE %IF %UPCASE(&DISPLAY_TYPE) = PCT_TTL %THEN %DO;
%let action = %STR(*SUM=' '*f=percent7.2);
%let tab_lib = work;
%let tab_table = &in_table._sum;
%let var_final = sum_wgt;
%let label = PERCENT OF TOTAL;
%GOTO SUM;
%END;



%SUM:

%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO; 
	proc means data=&in_lib..&in_table noprint;
		var &thevar / weight = &wgt;
		output out = sum
			sum(&thevar) = sum_thevar
		;
	run;
%END;

%ELSE %DO;
	proc means data=&in_lib..&in_table noprint;
		var &thevar;
		output out = sum
		sum(&thevar) = sum_thevar
		;
	run;
%END;


data _null_;
	set sum;
	call symput('sum_thevar',sum_thevar);
run;

data work.&in_table._sum;
	set &in_lib..&in_table;
	sum_wgt = &thevar/&sum_thevar;
run;
%GOTO TABLE;



%TABLE:
ods output table=&out_table;

%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO; 
	%let title_name = %upcase("weighted &label of &thevar for &class1*&class2 using &display_type display type");
%END;

%ELSE %DO;
	%let title_name = %upcase("&label of &thevar for &class1*&class2 using &display_type display type");
%END;

PROC TABULATE NOSEPS FORMAT=comma14. DATA=&tab_lib..&tab_table MISSING;
	Title &title_name;
	class &class1 &class2; 
	var &var_final;
	%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO; weight &wgt;%END;
	table (&class1 &ALL_TOGGLE),
		(&class2 &ALL_TOGGLE)*(&var_final=" "%UNQUOTE(&action))
		/ rts=15; 
	format &class1 &&&class1... &class2 &&&class2...;
	keylabel mean=' ' sum=' ';
RUN;
ods output close;
%GOTO EXIT;
%EXIT:
%mend TABULATE_2way;
