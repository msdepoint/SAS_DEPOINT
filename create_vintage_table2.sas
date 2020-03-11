%MACRO create_vintage_table2(in_lib=,in_table=,out_lib=,out_table=,date_open=,date_cycle=,vintage_type=week,cycle_type =,bal_var=,type=MEAN,cutoff=);
/****************************************************************************/
/* Assumes data in long form												*/
/* vintage type could be day, week, or month. DEFAULT is WEEK 				*/
/* 	this is used to standardize the &DATE_OPEN variable into a cohort 		*/

/* An additional input parameter cycle_type has been added. 				*/
/* cycle_type could be month, week or day									*/
/* in_table has to be created from EOM, EOW or EOD Snap files depending on  */
/* whether the cycle_type is a month, week or day respectively				*/

/* TYPE --> N MEAN, or MEDIAN or SUM										*/
/* Cutoff allows us to look at the past X number of vintages Week or Month	*/
/* Cutoff is blank or a number												*/
/****************************************************************************/

/* Standardize the dateopen variable to be unique by interval type*/


DATA prepare;
	SET &in_lib..&in_table;
	format date_vintage date7.;
	date_vintage = INTNX("&vintage_type",&date_open,0,'END');

	/* a new macro variable - date_temp_vintage is used to correct for the issue that occurs*/
	/* when granularity of vintage_type is greater than that of date_cycle					*/

	format date_temp_vintage date7.;

	/* set temp_vintage_type as the minimum of vintage_type and cycle_type*/

        %IF %UPCASE(&vintage_type) = QUARTER %THEN %DO;
                %IF %UPCASE(&cycle_type) = MONTH %THEN %DO;
                %LET temp_vintage_type = MONTH;
                %END;
                %IF %UPCASE(&cycle_type) = WEEK %THEN %DO;
                %LET temp_vintage_type = WEEK;
                %END;
                %IF %UPCASE(&cycle_type) = DAY %THEN %DO;
                %LET temp_vintage_type = DAY;
                %END;
        %END;

	%IF %UPCASE(&vintage_type) = MONTH %THEN %DO;
		%IF %UPCASE(&cycle_type) = MONTH %THEN %DO;
	   	%LET temp_vintage_type = MONTH;
	   	%END;
		%IF %UPCASE(&cycle_type) = WEEK %THEN %DO;
		%LET temp_vintage_type = WEEK;
		%END;
		%IF %UPCASE(&cycle_type) = DAY %THEN %DO;
		%LET temp_vintage_type = DAY;
		%END;
	%END;

	%IF %UPCASE(&vintage_type) = WEEK %THEN %DO;
		%IF %UPCASE(&cycle_type) = MONTH %THEN %DO;
	   	%LET temp_vintage_type = WEEK;
	   	%END;
		%IF %UPCASE(&cycle_type) = WEEK %THEN %DO;
		%LET temp_vintage_type = WEEK;
		%END;
		%IF %UPCASE(&cycle_type) = DAY %THEN %DO;
		%LET temp_vintage_type = DAY;
		%END;
	%END;

	%IF %UPCASE(&vintage_type) = DAY %THEN %DO;
		%IF %UPCASE(&cycle_type) = MONTH %THEN %DO;
	   	%LET temp_vintage_type = DAY;
	   	%END;
		%IF %UPCASE(&cycle_type) = WEEK %THEN %DO;
		%LET temp_vintage_type = DAY;
		%END;
		%IF %UPCASE(&cycle_type) = DAY %THEN %DO;
		%LET temp_vintage_type = DAY;
		%END;
	%END;

	date_temp_vintage = INTNX("&temp_vintage_type", &date_open,0,'END');

	%IF %LENGTH(&cutoff)>0 %THEN %DO;
		IF date_vintage >= INTNX("&vintage_type",TODAY(),-&CUTOFF,'BEGINNING');
	%END;
RUN;

PROC SORT DATA= prepare;
	BY date_temp_vintage &date_cycle;
RUN;

/* cycles are now assigned based on date_temp_vintage rather than the original vintage*/
DATA temp1;
	SET prepare;
	BY date_temp_vintage &date_cycle;
	IF first.date_temp_vintage THEN count = 0;
	IF first.&date_cycle THEN count+1;
	idvar = count;
RUN;

/* Calculate n, mean, and sums by original vintage and cycle date*/
PROC MEANS DATA=temp1  NOPRINT;
	CLASS date_vintage idvar;
	VAR &bal_var;
	OUTPUT OUT=out_tab 
		&TYPE= &bal_var._&TYPE
		;
RUN; 

DATA temp;
	SET out_tab;
	WHERE _type_ = 3;
	KEEP idvar date_vintage &bal_var._&TYPE;
RUN;

PROC TRANSPOSE data=temp out=from_tran(drop=_name_);
	BY date_vintage;
	ID idvar;
	VAR  &bal_var._&TYPE;
RUN;

PROC TRANSPOSE 	DATA=from_tran out=temp2
				prefix=v name=cycle label=cycle;
	ID date_vintage;
RUN;

DATA temp2;
	SET temp2;
	FORMAT cycle1 5.;
	cycle1 = cycle;
RUN;

PROC SORT data = temp2;
	BY cycle1;
RUN;

DATA &out_lib..&out_table;
	SET temp2 (drop = cycle1);
	cycle = compress("&cycle_type" || cycle);
RUN;

%MEND create_vintage_table2;


