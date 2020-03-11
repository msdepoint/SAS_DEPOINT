%macro MAKE_UNI(in_lib=,in_table=,LHS=,RHS_variables=,out_table=out_uni); 
/****************************************************************/
/*	PROC UNIVARIATE
/****************************************************************/
ODS LISTING EXCLUDE Moments TestsForLocation;
proc univariate data=&in_lib..&in_table;
	var &RHS_variables;
run;
%mend MAKE_UNI;
