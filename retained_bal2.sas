%MACRO retained_bal2(in_lib=work, in_table=,asof_date=,balance_var=curbal,series_date=filedate,unique_vars=,tenure_option=0,
						out_lib=work,out_table=,time_increment=MONTH,open_date=dateopen,tiered=YES,tier_var=);
/* DEPOINT MAY 2006 */
/*assumes that LEVEL and balance var have a format associated with their macro var reference */
/* FORMAT asof_date '31DEC2005'd */
/* If tenure_option > 0 then it excludes rows with less than a certain tenure. Plug in that value */
/* choose the time_increment to be either WEEK or MONTH depending on your data feed*/
%IF %UPCASE(&time_increment) = WEEK OR %UPCASE(&time_increment) = MONTH OR %UPCASE(&time_increment) = QUARTER
	OR %UPCASE(&time_increment) = YEAR
	%THEN %LET time_period	= %UPCASE(&time_increment);
	%ELSE %DO;
		%PUT #########$$$$$$$$###############$$$$$$$$###############$$$$$$$$######;
		%PUT #########$$$$$$$$###### ERROR IN Time Increment #########$$$$$$$$######;
		%PUT #########$$$$$$$$###############$$$$$$$$###############$$$$$$$$######;
		%GOTO EXIT;
	%END;
PROC SORT DATA=&in_lib..&in_table; BY %UNQUOTE(&unique_vars &series_date);
DATA asof;
	SET &in_lib..&in_table;
	WHERE 	INTNX("&time_period",&series_date,0,'END') >= INTNX("&time_period",&asof_date,0,'END') 
	%IF %SYSEVALF(&tenure_option > 0)
 	%THEN %DO;		AND INTCHK("&time_period",&open_date,&asof_date) >=&tenure_option									%END;
	%ELSE %DO;		AND INTNX("&time_period",&open_date,0,'END') <=INTNX("&time_period",&asof_date,0,'END') 	%END;
			;


	%IF %UPCASE(&TIERED) = YES %THEN %DO;

	IF 	INTNX("&time_period",&series_date,0,'END') = INTNX("&time_period",&asof_date,0,'END') 
		THEN DO;
			LEVEL 	= INPUT(&tier_var,&&&tier_var...);
			denom	= &balance_var;
			END;
	RETAIN LEVEL DENOM;

	%END; /* tiered*/
	%ELSE %DO;
		IF 	INTNX("&time_period",&series_date,0,'END') = INTNX("&time_period",&asof_date,0,'END') 
		THEN denom = &balance_var;
		RETAIN denom;
	%END; /*not tiered*/

RUN;
OPTIONS MISSING='';

%IF %UPCASE(&TIERED) = YES %THEN %DO;
proc tabulate data=asof missing order=INTERNAL OUT=from_34tab;
	VAR &balance_var;
	CLASS &series_date level;
	FORMAT level &level.. &series_date date9.;
	TABLE 	(&series_date=''),
			(level="" all)
			* &balance_var=''*(n sum*f=dollar20. )
        /rts=30 row=float  BOX = "($ retained) As of &asof_date" MISSTEXT='';
        TITLE ' ';
RUN;
PROC SORT DATA=from_34tab(KEEP= _type_ level &balance_var._n &balance_var._sum &series_date) OUT=a23b; 
	BY level &series_date;RUN;

DATA &out_lib..&out_table; SET a23b; BY level;
	IF 	FIRST.level THEN	denom = &balance_var._sum;
	RETAIN denom;
	FORMAT Retain_Ratio 8.4;
	Retain_Ratio = &balance_var._sum / denom;
RUN;

data for_trans; set &out_lib..&out_table;
if level=. then level=99;
run;


proc sort data=for_trans; by &series_date; run;
proc transpose data=for_trans out=trans_out;
ID level;
by &series_date;
var retain_ratio;
run;

proc contents data=trans_out; run;

PROC PRINT DATA=&out_lib..&out_table NOOBS;
	VAR LEVEL &balance_var._n &balance_var._sum retain_ratio;
RUN;
PROC PRINT DATA=trans_out NOOBS;
        VAR &series_date 
axLOW__1000                                    
bx1000__25M                                  
cx25M__100M
dx100M__200M                                
ex200M__300M                                  
fx300M__400M                                 
gx400M__500M
hx500M_ 
ixAll;
RUN;
%END; /*tiered*/
%ELSE %DO;
proc tabulate data=asof missing order=INTERNAL OUT=from_34tab;
	VAR &balance_var;
	CLASS &series_date;
	FORMAT &series_date date9.;
	TABLE 	(&series_date=''),
			&balance_var=''*(n sum*f=dollar20. )
        /rts=30 row=float  BOX = "($ retained) As of &asof_date" MISSTEXT='';
        TITLE ' ';
RUN;
PROC SORT DATA=from_34tab(KEEP= _type_ &balance_var._n &balance_var._sum &series_date) OUT=a23b; 
	BY &series_date;RUN;

DATA &out_lib..&out_table; SET a23b; BY &series_date;
	IF 	_n_	denom = &balance_var._sum;
	RETAIN denom;
	FORMAT Retain_Ratio 8.4;
	Retain_Ratio = &balance_var._sum / denom;
RUN;

data for_trans; set &out_lib..&out_table;
if level=. then level=99;
run;

proc sort data=for_trans; by &series_date; run;
proc transpose data=for_trans out=trans_out;
ID level;
by &series_date;
var retain_ratio;
run;

PROC PRINT DATA=&out_lib..&out_table NOOBS;
	VAR &balance_var._n &balance_var._sum retain_ratio;
RUN;
PROC PRINT DATA=trans_out NOOBS;
        VAR &series_date 
axLOW__1000                                    
bx1000__25M                                  
cx25M__100M
dx100M__200M                                
ex200M__300M                                  
fx300M__400M                                 
gx400M__500M
hx500M_ 
ixAll;
RUN;

%END; /*not tiered*/
PROC DATASETS LIB=work;
	DELETE from_34tab a23b;
QUIT;
%EXIT:
%MEND retained_bal2;



