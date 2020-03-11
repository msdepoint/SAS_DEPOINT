%MACRO var_reduce_missing(in_table,out_table,out_lib=work,in_lib=work,THRESH=.05); 
	%get_var_names(in_lib=&in_lib,in_table=&in_table,out_table=T1,var_list_name=VAR_10,
					keep1=name,drop_list=%QUOTE(APPLID acct_i portfolio_i DATE_CAMPAIGN));
	/****************************************************************/
	/*	PROC UNIVARIATE TO FIND MISSING								*/
	/****************************************************************/
	ods listing close;
	ods output Attributes=attl;
	proc contents data=&in_lib..&in_table;
	run;
	ods output close;
	data _null_;
		set attl(keep=label2 nvalue2);
		where UPCASE(LABEL2) = 'OBSERVATIONS';
		call symput ('numobs',nvalue2);
	run;

	proc datasets lib=WORK memtype=data;
	DELETE drop_vars&in_table;
	run;
	proc means data=&in_lib..&in_table nmiss;
		var &var_10;
		ods output summary=mvars_prelim;
	run;
	ods listing;
	proc transpose data=mvars_prelim out=mvars_flip(drop=_label_);
	run;
	data drop_vars&in_table;
		set mvars_flip(rename=(col1=nmiss));
		where nmiss > 0;
		varname = SUBSTR(_name_,1,LENGTH(_name_)-6);
		format pct_missing percent8.2;
		pct_missing = nmiss/&numobs;
		if pct_missing > &THRESH;
		drop _name_;
	run;
	%let nummiss =0;
	data _null_;
		set drop_vars&in_table end=x;
		num = _n_;
		if x then call symput ('nummiss',num);
	run;
	%IF &nummiss = 0 %THEN %DO;
		%PUT ****************************;
		%PUT ****************************;
		%PUT NO MISSING VARIABLES IN &IN_TABLE;
		%PUT ****************************;
		%PUT ****************************;
		data &out_lib..&out_table;
			set &in_lib..&in_table;
		run;
	%END;
	%ELSE %DO;
		%get_values(in_lib=work,in_table=drop_vars&in_table,var_list_name=DROP_VAR_LIST,var_name=VarName);
	%put &drop_var_list;
		data &out_lib..&out_table;
			set &in_lib..&in_table;
			drop &drop_var_list;
		run;
	%END;
%mend var_reduce_missing;

