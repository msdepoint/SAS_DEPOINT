%MACRO VARIABLE_TRANSFORMATION(in_lib=,in_table=,DEPVAR=,INDVARS=);
/********************************************************************************/
/*	Produce different transformations of variable to see which one is the "best"*/
/*	DePoint JAN 25, 2002					*/
/*	Changed LN to LN(X+1)								*/
/*	Added BIN AT MEDIAN value							*/
/*	updated again oct 2002 
update AUG2005 to add continuous dep var options
/********************************************************************************/

/* determine if dependent variable is binary */
PROC SQL;
	CREATE TABLE how_many AS
	SELECT 
	COUNT (DISTINCT &depvar) as how_many

	FROM &in_lib..&in_table
	;
QUIT;
%get_values(in_lib=work,in_table=how_many,var_list_name=num_dep_values,var_name=how_many);

/*******************************/
ods listing close;
	ods output summarY=sum;
	PROC MEANS data=&in_lib..&in_table MEDIAN QMETHOD=p2; /*there is a default method that does not always work*/
		var &INDVARS;
	run;
ods listing;
	data med1;
		set sum;
		keep 
		%string_loop(	var_list=&INDVARS, action_code = %NRSTR(&&word&i.._median)	)
		;
		rename 
		%string_loop(	var_list=&INDVARS, action_code = %NRSTR(&&word&i.._median = &&word&i)	)
		;
		varname = 'MEDIAN';
run;
	proc transpose data=med1 out=TOUT(drop=_label_ rename=(col1=median)) name=varname;
run;

/*****************************/
/* Now, determine what type of transformation code we should run*/
/*****************************/

%let trans_action =
	%NRSTR(
data _null_;
			set TOUT;
			where varname = "&&word&i";
			median = ROUND(median,.001);
			call symput('median_value',MEDIAN);
		run;
		data trans;
			set &in_lib..&in_table(keep=&DEPVAR &&word&i);
				IF &&word&i >= 0 THEN sqroot&&word&i			= sqrt(&&word&i);
				x_sqrd&&word&i			= &&word&i**2;
				x_cubed&&word&i			= &&word&i**3;
				&&word&i.._BIN			= (&&word&i>&median_value);
				IF &&word&i >= 0 THEN ln&&word&i.._bnd		= log(&&word&i + 1);

		label 	sqroot&&word&i			= "sqrt(&&word&i)"
				x_sqrd&&word&i			= "&&word&i**2"
				x_cubed&&word&i			= "&&word&i**3"
				ln&&word&i.._bnd		= "log(&&word&i + 1)"
				&&word&i.._BIN			= "(&&word&i>%CMPRES(&median_value))"
				;
		run;
		%let trans_list = 	&&word&i 
							sqroot&&word&i  
							x_sqrd&&word&i
							x_cubed&&word&i
							ln&&word&i.._bnd
							&&word&i.._BIN
							;
		%let trans_list_min_max = 	&&word&i,
									sqroot&&word&i,  
									x_sqrd&&word&i,
									x_cubed&&word&i,
									ln&&word&i.._bnd,
									&&word&i.._BIN
									;

		%MAKE_CORR(in_lib=work,in_table=trans,LHS=&DEPVAR,RHS_variables=%QUOTE(&trans_LIST),out_table=out_corr_trans);
		proc print data = out_corr_trans;
		proc transpose data=out_corr_trans out=transpose_out; id variable; var corr_estimate;
		data _null_;
			set transpose_out;
			IF SIGN(&&word&i) = -1 
				THEN the_max	= MIN(&trans_list_min_max);
				ELSE the_max	= MAX(&trans_list_min_max);
			call symput('max_value',the_max);
		run;
		data _null_;
			set out_corr_trans;
			diff = RANGE(corr_estimate,  &MAX_value);
			if (diff > .0000001) or corr_estimate=. then delete;
			call symput('best_trans',variable);
		run;
		
		%edabivar(	in_lib=work,in_table=trans,ind_var=&&WORD&i,dep_var=&DEPVAR,
			groups=20);
		%edabivar(	in_lib=work,in_table=trans,ind_var=&best_trans,dep_var=&DEPVAR,
			groups=20);

		%MAKE_UNI(	in_lib=work,in_table=trans,LHS=&DEPVAR,RHS_variables=&&word&i); 
);

%IF &num_dep_values = 2 %THEN %DO;
%LET trans_action = 
%NRSTR(
data _null_;
			set TOUT;
			where varname = "&&word&i";
			median = ROUND(median,.001);
			call symput('median_value',MEDIAN);
		run;
		data trans;
			set &in_lib..&in_table(keep=&DEPVAR &&word&i);
				sqroot&&word&i			= sqrt(&&word&i);
				x_sqrd&&word&i			= &&word&i**2;
				x_cubed&&word&i			= &&word&i**3;
				&&word&i.._BIN			= (&&word&i>&median_value);
				ln&&word&i.._bnd	= log(&&word&i + 1);

		label 	sqroot&&word&i				= "sqrt(&&word&i)"
				x_sqrd&&word&i				= "&&word&i**2"
				x_cubed&&word&i				= "&&word&i**3"
				ln&&word&i.._bnd		= "log(&&word&i + 1)"
				&&word&i.._BIN				= "(&&word&i>%CMPRES(&median_value))"
				;
		run;
		%let trans_list = 	&&word&i 
							sqroot&&word&i  
							x_sqrd&&word&i
							x_cubed&&word&i
							ln&&word&i.._bnd
							&&word&i.._BIN
							;
		%let trans_list_min_max = 	&&word&i,
									sqroot&&word&i,  
									x_sqrd&&word&i,
									x_cubed&&word&i,
									ln&&word&i.._bnd,
									&&word&i.._BIN
									;

		%MAKE_CORR(in_lib=work,in_table=trans,LHS=&DEPVAR,RHS_variables=%QUOTE(&trans_LIST),out_table=out_corr_trans);
		proc print data = out_corr_trans;
		proc transpose data=out_corr_trans out=transpose_out; id variable; var corr_estimate;
		data _null_;
			set transpose_out;
			IF SIGN(&&word&i) = -1 
				THEN the_max	= MIN(&trans_list_min_max);
				ELSE the_max	= MAX(&trans_list_min_max);
			call symput('max_value',the_max);
		run;
		data _null_;
			set out_corr_trans;
			diff = RANGE(corr_estimate,  &MAX_value);
			if (diff > .0000001) or corr_estimate=. then delete;
			call symput('best_trans',variable);
		run;
		
		%edabivar(	in_lib=work,in_table=trans,ind_var=&&WORD&i,dep_var=&DEPVAR,
			groups=20);
		%MAKE_ELOGIT_PLOT(	in_lib=work,in_table=trans,LHS=&DEPVAR,ind_var=&&word&i);
		%ks_wgt(in_lib=work,in_table=trans,score=&&WORD&I,the_var=&DEPVAR,wgt=);

		%edabivar(	in_lib=work,in_table=trans,ind_var=&best_trans,dep_var=&DEPVAR,
			groups=20);
		%MAKE_ELOGIT_PLOT(	in_lib=work,in_table=trans,LHS=&DEPVAR,ind_var=&best_trans);
		%ks_wgt(in_lib=work,in_table=trans,score=&best_trans,the_var=&DEPVAR,wgt=);

		%MAKE_UNI(	in_lib=work,in_table=trans,LHS=&DEPVAR,RHS_variables=&&word&i); 
);
%END;
/**********************************************************/
/*	grab the RHS variables and shove them, one by one, into the transformation code	*/
%string_loop(	var_list=&INDVARS, action_code = &trans_action	);
%MEND VARIABLE_TRANSFORMATION;

