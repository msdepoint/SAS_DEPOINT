%macro MAKE_ELOGIT_PLOT(in_lib,in_table,LHS,ind_var); 
/****************************************************************/
/*	Produce empirical logit plots
	DePoint Oct 29, 2001
/****************************************************************/
proc rank DATA=&in_lib..&in_table GROUPS=100 TIES=MEAN out=rank_out;
   var &ind_var;
   ranks bin;
proc means data=rank_out noprint nway;
	class bin;
	var &LHS &ind_var;
	output out=bins
		sum(&LHS)		= &LHS 
		mean(&ind_var)	= &ind_var
		;
data bins;
	set bins;
	elogit_&LHS	= log((&LHS+(sqrt(_FREQ_)/2))/(_FREQ_-&LHS+(sqrt(_FREQ_)/2)));
run;
proc plot data=bins hpct=75 vpct=75;/*this could be gplot*/
	title "Empirical Logit Plot of &ind_var for &LHS";
	plot 	elogit_&LHS*&ind_var='*';
run;
quit;
%mend MAKE_ELOGIT_PLOT;
