%MACRO create_vintage_table(in_lib=WORK,in_table=,out_lib=WORK,out_table=VINT_TBL,date_open=ACCT_OPEN_DT,date_cycle=SNAP_DT,vintage_type=WEEK,
			    cycle_type=WEEK,bal_var=BAL_LDGR_AMT,extra_class=,xls=VINT_TBL,type=MEAN,cutoff=);
/********************************************************************************/
/* Assumes data in long form						        */
/* VINTAGE_TYPE could be day, week, or month. DEFAULT: WEEK. 		        */
/* this is used to standardize the &DATE_OPEN variable into a cohort 	        */

/* An additional input parameter cycle_type has been added.	   	        */
/* CYCLE_TYPE could be month, week or day. 				        */
/* IN_TABLE has to be created from EOM, EOW or EOD Snap files depending on      */
/* whether the cycle_type is a month, week or day respectively. DEFAULT is WEEK.*/

/* EXTRA_CLASS allows the user to track funding curves by an additional class   */
/* variable, for example, their starting balance tier. DEFAULT: BLANK.          */

/* XLS is the file name, which MUST be entered, to output the final table	*/
/* generated by proc tabulate through ODS. The table is created by using	*/
/* the RTF_SMALL template. The location of the XLS output is the current path   */
/* from which the code is run (if running in PC SAS, this is the home directory */
/* of the user). DEFAULT: VINT_TBL.       					*/

/* TYPE --> N, MEAN, MEDIAN, or SUM					     	*/
/* CUTOFF allows the user to look at the past X number of vintages Week or Month*/
/* Cutoff is blank or a number. DEFAULT: BLANK. 			        */
/********************************************************************************/

/* Standardize the dateopen variable to be unique by interval type*/
DATA prepare;
	SET &in_lib..&in_table;
	format date_vintage date7.;
	date_vintage = INTNX("&vintage_type",&date_open,0,'END');

	/* a new macro variable - date_temp_vintage is used to correct for the issue that occurs*/
	/* when granularity of vintage_type is greater than that of date_cycle	*/

	format date_temp_vintage date7.;

	/* set temp_vintage_type as the minimum of vintage_type and cycle_type*/

	%IF %UPCASE(&vintage_type) = MONTH %THEN 
		%DO;
			%IF %UPCASE(&cycle_type) = MONTH %THEN 
				%DO;
		   			%LET temp_vintage_type = MONTH;
		   		%END;
			%IF %UPCASE(&cycle_type) = WEEK %THEN
				%DO;
					%LET temp_vintage_type = WEEK;
				%END;
			%IF %UPCASE(&cycle_type) = DAY %THEN 
				%DO;
					%LET temp_vintage_type = DAY;
				%END;
		%END;

	%IF %UPCASE(&vintage_type) = WEEK %THEN 
		%DO;
			%IF %UPCASE(&cycle_type) = MONTH %THEN 
				%DO;
		   			%LET temp_vintage_type = WEEK;
		   		%END;
			%IF %UPCASE(&cycle_type) = WEEK %THEN 
				%DO;
					%LET temp_vintage_type = WEEK;
				%END;
			%IF %UPCASE(&cycle_type) = DAY %THEN 
				%DO;
					%LET temp_vintage_type = DAY;
				%END;
		%END;

	%IF %UPCASE(&vintage_type) = DAY %THEN 
		%DO;
			%IF %UPCASE(&cycle_type) = MONTH %THEN
				%DO;
		   			%LET temp_vintage_type = DAY;
		   		%END;
			%IF %UPCASE(&cycle_type) = WEEK %THEN 
				%DO;
					%LET temp_vintage_type = DAY;
				%END;
			%IF %UPCASE(&cycle_type) = DAY %THEN 
				%DO;
					%LET temp_vintage_type = DAY;
				%END;
		%END;

	date_temp_vintage = INTNX("&temp_vintage_type",&date_open,0,'END');

	/*	Make sure that accts that opened in periods, whose end falls into the next cycle's vintage, are assigned the vintage of the period*/
	if date_temp_vintage >= INTNX("&vintage_type",&date_open,1,'BEGINNING') then date_temp_vintage = INTNX("&temp_vintage_type",&date_open,-1,'END');

	%IF %LENGTH(&cutoff)>0 %THEN 
		%DO;
			IF date_vintage >= INTNX("&vintage_type",TODAY(),-&CUTOFF,'BEGINNING');
		%END;
RUN;

******* Extra Class *******;
%if %length(&extra_class) > 0 %then 
%do;
	PROC SORT DATA= prepare;
		BY date_temp_vintage &extra_class &date_cycle;
	RUN;

	/* cycles are now assigned based on date_temp_vintage rather than the original vintage*/
	DATA temp1;
		SET prepare;
		BY date_temp_vintage &extra_class &date_cycle;
		IF first.&extra_class THEN count = 0;
		IF first.&date_cycle THEN count + 1;
		cycle = compress("&cycle_type"||put(count,z3.));
	RUN;

	/* If the XLS file name is missing, force the DEFAULT: xls=VINT_TBL*/
	%if %length(&xls) = 0 %then %let xls =VINT_TBL;

	/* Choose the correct format, depending on the value of TYPE*/
	%if %upcase(&type) = MEAN or %upcase(&type) = MEDIAN or %upcase(&type) = SUM	
						      or %upcase(&type) = MIN	 or %upcase(&type) = MAX
		%then %let fmt = dollar20.;
	%else %if %upcase(&type) = N %then %let fmt = comma20.;

	/* Use this for the title of the table*/
	%let cycle_type_ttl = %upcase(&cycle_type);

	/* Prepare the final data set and XLS output through ODS from proc tabulate*/
	ODS HTML3 FILE = "./&xls..xls" RS=none STYLE=rtf_small;
		proc tabulate data = temp1 out = &out_lib..&out_table order=internal missing;
			class date_vintage &extra_class cycle;
			var &bal_var;
			tables cycle='', date_vintage='Vintage'* (&extra_class='' all)*(&bal_var="&type"*f=&fmt)*&type=''
				/box='Cycle' rts=30 row=float misstext='';
			title "Vintage Funding of &bal_var by &extra_class Class and &&cycle_type_ttl.LY Cycles";
		run;
	ODS HTML3 close;
%end;

******* No Extra Class *******;
%if %length(&extra_class) = 0 %then
%do;
	PROC SORT DATA= prepare;
		BY date_temp_vintage &date_cycle;
	RUN;

	/* cycles are now assigned based on date_temp_vintage rather than the original vintage*/
	DATA temp1;
		SET prepare;
		BY date_temp_vintage &date_cycle;
		IF first.date_temp_vintage THEN count = 0;
		IF first.&date_cycle THEN count + 1;
		cycle = compress("&cycle_type"||put(count,z3.));
	RUN;

	/* If the XLS file name is missing, force the DEFAULT: xls=VINT_TBL*/
	%if %length(&xls) = 0 %then %let xls =VINT_TBL;

	/* Choose the correct format, depending on the value of TYPE*/
	%if %upcase(&type) = MEAN or %upcase(&type) = MEDIAN or %upcase(&type) = SUM	
						      or %upcase(&type) = MIN	 or %upcase(&type) = MAX
		%then %let fmt = dollar20.;
	%else %if %upcase(&type) = N %then %let fmt = comma20.;

	/* Use this for the title of the table*/
	%let cycle_type_ttl = %upcase(&cycle_type);

	/* Prepare the final data set and XLS output through ODS from proc tabulate*/
		ODS HTML3 FILE = "./&xls..xls" RS=none STYLE=rtf_small;
			proc tabulate data = temp1 out = &out_lib..&out_table order=internal missing;
				class date_vintage cycle;
				var &bal_var;
				tables cycle='', date_vintage='Vintage'*(&bal_var="&type"*f=&fmt)*&type=''
					/box='Cycle' rts=30 row=float misstext='';
				title "Vintage Funding of &bal_var by &&cycle_type_ttl.LY Cycles";
			run;
		ODS HTML3 close;
%end;

%MEND create_vintage_table;