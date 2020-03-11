%macro MAKE_MEANS_PLOT(in_lib,in_table,LHS,ind_var); 
/****************************************************************/
/*	Produce mean of dependent by all of the independent
	looking for a rank ordering, which means a linear relationship
	DePoint and Gravenish May 29, 2001
/****************************************************************/
proc rank DATA=&in_lib..&in_table GROUPS=100 TIES=MEAN out=rank_out(keep=&ind_var the_rank &LHS);
   var &ind_var;
   ranks the_rank;
proc sort data=rank_out; by the_rank;
run;
proc means data=rank_out noprint;
	var &ind_var;
	by the_rank;
	output out=means0
		mean(&ind_var)	= mean_&ind_var
		;
run;

proc means data=rank_out noprint;
	class the_rank;
	var &LHS;
	output out=MEANS1
	;
data TESTIT;
	merge MEANS0(keep=the_rank mean_&ind_var) MEANS1;
	by the_rank;
	if _stat_ ne 'MEAN' then delete;
	if _type_ = 0 then delete;
run;
proc print data=testit;
	TITLE "Mean of &LHS by bucketed &ind_var"; 
	var mean_&ind_var _freq_ &LHS;
run;
proc plot data=testit hpct=50 vpct=50;/*this could be gplot*/
	title "Plot of &LHS*mean_&ind_var";
	plot 	&LHS*mean_&ind_var='*';
run;
quit;/* */
%mend MAKE_MEANS_PLOT;