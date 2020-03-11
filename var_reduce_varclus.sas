%macro VAR_REDUCE_VARCLUS(in_lib,in_table,out_lib,out_table, variables=, print=NO);
/* limit redundancy by employing PROC VARCLUS and choosing those variables within each unique cluster*/
/* that have the lowest 1-RSQratio*/
/********************************************************/
/* MAKE SMALL ANALYSIS TABLE*/
/********************************************************/
data SMALL_ANALYSIS;
	set &in_lib..&in_table(keep=&variables);
	insert_flag=1;
run;
/********************************************************/
/* Populate all missing values with MEDIAN values*/
/********************************************************/
	ods listing close;
	proc contents data=&in_lib..&in_table;
		ods output Attributes=attl;
	run;
	data _null_;
		set attl(keep=label2 nvalue2);
		where UPCASE(LABEL2) = 'OBSERVATIONS';
		call symput ('numobs',nvalue2);
	run;

	proc datasets lib=WORK memtype=data;
	DELETE mvars&in_table;
	run;
	
	proc means data=&in_lib..&in_table nmiss;
		var &variables;
		ods output summary=mvars_prelim;
	run;
	ods listing;
	proc transpose data=mvars_prelim out=mvars_flip(drop=_label_);
	run;
	data mvars&in_table;
		set mvars_flip(rename=(col1=nmiss));
		where nmiss > 0;
		varname = SUBSTR(_name_,1,LENGTH(_name_)-6);
		format pct_missing percent8.2;
		pct_missing = nmiss/&numobs;
		drop _name_;
	run;
	%let nummiss =0;
	data _null_;
		set mvars&in_table end=x;
		num = _n_;
		if x then call symput ('nummiss',num);
	run;
	%IF &nummiss = 0 %THEN %DO;
		%PUT ****************************;
		%PUT ****************************;
		%PUT NO MISSING VARIABLES IN &IN_TABLE;
		%PUT ****************************;
		%PUT ****************************;
		data ANALYSIS_TABLE;
			set SMALL_ANALYSIS(drop=insert_flag);
		run;
	%END;
	%ELSE %DO;
		data get_allmissing&in_table;
			insert_flag=.; /*this is here to make sure we always have something to delete*/
			set mvars&in_table;
			if pct_missing > .95; /*just too many to fill in the blanks*/
		run;
		%get_values(in_lib=work,in_table=get_allmissing&in_table,var_list_name=DROP_ALLMISS_LIST,var_name=VarName);
		
		%get_values(in_lib=work,in_table=mvars&in_table,var_list_name=FIX_VAR_LIST,var_name=VarName);
		ods listing close;
			ods output summary=MED0;
			PROC MEANS data=&in_lib..&in_table MEDIAN qmethod=p2;
				var &FIX_VAR_LIST;
			run;
		ods listing;

		
			data med1;
				set MED0;
				insert_flag=1;
				keep insert_flag
				%string_loop(	var_list=&FIX_VAR_LIST, action_code = %NRSTR(&&word&i.._median)	)
				;

				%string_loop(	var_list=&FIX_VAR_LIST, 
								action_code = %NRSTR(label &&word&i.._median = "&&word&i.._median";)	)

				%string_loop(	var_list=&FIX_VAR_LIST, 
								action_code = %NRSTR(rename &&word&i.._median = &&word&i.._med;)	)

				
		run;
		data blank;
			%string_loop(	var_list=&variables, action_code = %NRSTR(&&word&i.._med=.;)	)
			insert_flag=1;
		run;
		/*populate missing with median value*/
		DATA ANALYSIS_TABLE(drop=&DROP_ALLMISS_LIST);
			merge SMALL_ANALYSIS blank med1;
			by insert_flag;
			%string_loop(	var_list=&variables, 
			action_code = %NRSTR(IF MISSING(&&word&i) THEN &&word&i = &&word&i.._med;)	)
		
			drop
			%string_loop(	var_list=&variables, 
			action_code = %NRSTR(&&word&i.._med)	)
			;
		run;
	%END;
ods listing close;
/********************************************************************/
/*	NOW do the PROC VARLCUS on nonmissing values					*/
/********************************************************************/
%get_var_names(in_lib=work,in_table=ANALYSIS_TABLE,out_table=CLUSLIST1,var_list_name=CLUSLIST1,
               out_lib=work,keep1=%QUOTE(name),
               drop_list=%QUOTE(insert_flag applid acct_i portfolio_i date_campaign));

ods output clusterquality=summary
			rsquare(match_all) = RSQ;
proc varclus  data=ANALYSIS_TABLE maxeigen=.7 SHORT HI;
		var &CLUSLIST1;
	run;
	ods listing;

	data _null_;
	  set summary;
	  call symput('ncl',TRIM(left(numberofclusters-2)));
	run;
%IF %EVAL(&SYSERR > 0) %THEN %GOTO CRACK; /*Clustering not possible because of too few variables or no relationship found*/
/* fill in the CLUSTER variable values */
data rsq_NEW; 
	set rsq&NCL;
	drop old_cluster;
	retain old_cluster;
	if MISSING(cluster) then cluster = old_cluster;
	old_cluster=cluster;
	run;

/* pick out the variable corresponding to smallest 1-rsq ratio */ /*a ratio of 0 may not be correct*/
proc sort data=rsq_NEW out=rsq_SORT;
	by cluster RSquareRatio;
	run;
data GOTIT(rename=(variable=varname) keep=variable RSquareRatio);
	set rsq_SORT;
	by cluster;
	if first.cluster;
	run;
proc sort data=GOTIT out=&out_lib..&out_table; by RsquareRatio;  
run;
%IF &PRINT=Y %THEN %DO;
	PROC PRINT DATA=rsq_NEW;
		var cluster variable owncluster nextclosest RsquareRatio;
	PROC PRINT data=&out_lib..&out_table;
	run;
%END;
%GOTO EXIT;

	%CRACK:
		%PUT ****************************;
		%PUT ****************************;
		%PUT NO CLUSTER CONVERGENCE;
		%PUT ****************************;
		%PUT ****************************;

		data &out_lib..&out_table;
			set Cluslist1(rename=(name=varname));
			RsquareRatio=9999;
			label RsquareRatio='fake RsquareRatio no cluster convergence';
			run;
		PROC PRINT 	data= &out_lib..&out_table;
			title "fake RsquareRatio no cluster convergence";
			run;
	%GOTO EXIT;
	%EXIT:
%mend VAR_REDUCE_VARCLUS;
