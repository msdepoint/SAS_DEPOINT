%macro glm_analysis_loop(in_lib,in_table,lhs_list,class,wgt=);
/************************************************************************************************/
/* GLM_ANALYSIS_LOOP                                                                            */
/* 13JAN04 / MD:ac                                                                              */
/* THIS MACRO LOOPS THROUGH A LIST (LHS_LIST) OF VARIABLES AND GENERATES F-TESTS                */
/*   ON THIS VARIABLE LIST BY CLASS                                                             */
/************************************************************************************************/

%let set_list=;

%if %eval(%length(&wgt)=0) %then %do;
	%let wgt =;
	%put &wgt;
%end;
%else %do;
	%let wgt = &wgt;
	%put &wgt;
%end;

%local i;
%let i = 0;
	%do %until (&word_length=0);
		%let i = %eval(&i+1);
		%let word&i = %scan(&lhs_list,&i,%str( ));
		%let word_length = %length(&&word&i);
		%if &word_length ne 0 %then %do;
			%GLM_test_1effect(in_lib=&in_lib,in_table=&in_table,class=&class,
				wgt=&wgt,lhs=&&word&i);
		%end;
	%end;

data final_&in_table;
	set &set_list;
	format mean 8.4;
run;

proc print data=final_&in_table;
run;

%mend glm_analysis_loop;

