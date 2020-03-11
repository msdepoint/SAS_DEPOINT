/*the original var_reduce_varclus macro often sees problems of "var name too long"			*/
/*this code rename all the input variables to be vxaxbx1-vxaxbx1000 (or vxaxbx100000) 	*/
/*and then apply the var_reduce_clus macro. the resulting dataset is then renamed back	*/

/*step1: create a match table: read in all numeric var names into a dataset and assign 	*/
/*       new names																					*/
/*step2: output the match table into sas rename code and rename the input dataset			*/
/*step3: run var_reduce_varclus macro																*/
/*step4: get the resulting var names from varclus output dataset and use the match			*/
/*       table to rename var names back															*/
/*created by zhenhua hu, 05nov2006																	*/

/*USAGE: %name2long_varclus(in_lib=blah1,in_table=blah2,										*/
/*		out_lib=work,out_table=FROM_VARCLUS, variables=%QUOTE(&NUMERIC_1),print=Y);			*/
/*THE "VARIABLE" INPUT MUST BE QUOTED IF IT IS NOT EMPTY										*/

/*note: this macro calls get_values macro which assigns var names to a macro variable		*/
/*thus if there are too many variables then there will be a problem							*/
/*the maximum length of a macro variable''s value is host dependent, but for most 			*/
/*platforms it is 32,767 bytes with Version 6. Version 7 has a maximum length of 			*/
/*approximately 65,534 bytes																		*/
/*therefore, this code generally works fine for dataset with less then 2000 variables		*/

/*to comment out "ods listing" with "  %* " in the original var_reduce_varclus.sas */
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
%*	ods listing close;
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
%*	ods listing;
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
%*		ods listing close;
			ods output summary=MED0;
			PROC MEANS data=&in_lib..&in_table MEDIAN qmethod=p2;
				var &FIX_VAR_LIST;
			run;
%*		ods listing;

		
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
%* ods listing close;
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
%*	ods listing;

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

%*-------------------------------------------------	*;
%*						MAIN PROGRAM;						*;
%*-------------------------------------------------	*;

%macro name2long_varclus(in_lib=work, in_table=, out_lib=work, out_table=, variables=, print=Y);
	filename _all_ clear;
%*step1: create match table;  
	%*if the user does not provide the input variable list, use all the numeric variable in the data;
	%*otherwise, use the list the user provides;

	%if &variables=%str( ) %then 
		%do;                     
			ods listing close;
				proc contents data=&in_lib..&in_table. out=tmp1; run; 
			ods listing;
			proc sort data=tmp1(where=(type=1)); by name; run;
			data match_tab; set tmp1(keep=name);
				xzy312_zh+1;
				newname=compress('vxaxb_'||left(put(xzy312_zh,8.)));
				renm='rename';
				equalsign='=';
				semicolon=';';
				drop xzy312_zh;
			run;

			%get_values(in_lib=work,in_table=match_tab,var_list_name=numeric_zh312,var_name=newname);
		%end;
	%else
		%do;
			data tmp1;
				length name0 $100; %*assumes no var name will exceed 100 letters, which is generally true;
				%string_loop(var_list=%unquote(&variables), action_code=%nrstr(name0=compress("&&word&i.."); output;))

			run;
			data match_tab; set tmp1(keep=name0);
				name=trim(left(name0));
				xzy312_zh+1;
				newname=compress('vxaxb_'||left(put(xzy312_zh,8.)));
				renm='rename';
				equalsign='=';
				semicolon=';';
				drop xzy312_zh name0;
			run;

			%get_values(in_lib=work,in_table=match_tab,var_list_name=numeric_zh312,var_name=newname);
		%end;
	%put *************************************************;
	%put &numeric_zh312;
	%put *************************************************;
%*step2: output match table and rename the input dataset;
	filename routed0 './oldnames_xaxb312.txt';
	data _null_; set match_tab;
		file routed0 notitles;
		put @1 name ;
		return;
	run;
	filename routed1 './renm_cmd_xaxb312.txt';
	data _null_; set match_tab;
		file routed1 notitles;
		put @1 renm name equalsign newname semicolon;
		return;
	run;
	data renamed; set &in_lib..&in_table.;
		keep %include routed0 ; 
		;
		%include routed1;
	run;
	x 'rm ./oldnames_xaxb312.txt';
	x 'rm ./renm_cmd_xaxb312.txt';
%*step3: run the var_reduce_varclus macro;
	ods listing close;
		%VAR_REDUCE_VARCLUS(in_lib=work,in_table=renamed,out_lib=work,out_table=varclus_zh312,
						variables=%quote(&numeric_zh312),print=&print.); 
	ods listing;
	%*the output data from var_reduce_varclus only contains varname and RSquareRatio;
	%*where the varname has values of vxaxbx_1 vxaxbx_2...;
	%*the var_reduce_varclus produce a temporary dataset rsq_NEW which provides detailed cluster information; 
%*step4: get the original name back;
	proc sort data=match_tab; by newname; run;

	%*rename the rsq_NEW var name back;
	proc sort data=rsq_NEW out=rsq_NEW_sort; by variable; run;
	data rsq_NEW_oldname; merge match_tab(rename=(newname=variable)) rsq_NEW_sort(in=inb); by variable;
		if inb;
		clusterno=input(scan(cluster,2),8.);
		keep clusterno cluster name owncluster nextclosest RsquareRatio;
	run;
	proc sort data=rsq_NEW_oldname(rename=(name=variable)); by clusterno variable; run;

	%*rename the final output dataset var name back;
	proc sort data=varclus_zh312(keep=varname RSquareRatio); by varname; run;
	data tmp2; merge match_tab(rename=(newname=varname)) varclus_zh312(in=inb); by varname;
		if inb;
		keep name RSquareRatio;
	run;
	data &out_lib..&out_table.; set tmp2;
		rename name=varname;
	run;

	%IF &PRINT=Y %THEN %DO;
		PROC PRINT DATA=rsq_NEW_oldname;
			var cluster variable owncluster nextclosest RsquareRatio;
		run;
		proc print data=&out_lib..&out_table.; var varname RSquareRatio; run;
	%END;

	filename _all_ clear;
%mend name2long_varclus;
			


	