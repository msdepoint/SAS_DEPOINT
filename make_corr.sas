%macro MAKE_CORR(in_lib,in_table,LHS,RHS_variables,out_table=out_corr); 
/****************************************************************/
/*	Multi-correlation matrix:									*/
/*	BEST=n prints n correlation coefficients for each variable. */
/*	RANK ranks by highest corr 									*/
/****************************************************************/
ods listing close;
	ods output pearsoncorr=pcorr;
	proc corr data=&in_lib..&in_table nosimple rank best=1;
	var &LHS; with &RHS_variables;
	run;
	ods output close;
ods listing;
	data &out_table;
		set pcorr;/*(keep=variable label r1);*/
		corr_sign = '(-)';
		if r1 > 0 then corr_sign='(+)';
		rename r1 = CORR_estimate;

	proc sort data=&out_table; by variable;
	run;
%mend MAKE_CORR;