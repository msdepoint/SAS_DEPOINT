%macro report_lift_chart_wgt_dollar(in_lib=work,in_table=,score=,the_var=,bal_var=,wgt=,
	groups=10,sort_order=,exclusion=,out_table=tab_blah);

/****************************************************************************************************************/
/* WEIGHTED LIFT CHART MACRO (UNIT INCIDENCE AND BALANCE)                                                       */
/* I.Rischall ; A.Chin  29APR2003                                                                               */
/*                                                                                                              */
/*   Macro generates WEIGHTED one-way lift chart of UNIT INCIDENCE and associated BALANCE                       */
/*   If WGT option is left blank, a non-weighted lift table will be generated.                                  */
/*                                                                                                              */
/*      Macro Inputs:                                                                                           */
/*              in_lib          = Input Library                                                                 */
/*              in_table        = Input Table                                                                   */
/*              score           = Ranking Score                                                                 */
/*              the_var         = The Dependent Variable (binary response)                                      */
/*              bal_var         = Balance Variable that is associated with the_var                              */
/*              wgt             = Weight Variable                                                               */
/*              groups          = Number of Bins (e.g., 10 = deciles, 20 = twentiles, etc.)                     */
/*              sort_order      = DESCENDING | <blank>  (blank implies ascending sort [risk score])             */
/*              exclusion       = <blank>; otherwise, macro will omit scores le 10 (assuming exclusions are     */
/*                                      coded with scores < 10                                                  */
/****************************************************************************************************************/

data step_pre;
	set &in_lib..&in_table;
	%IF %EVAL(%LENGTH(&exclusion)>0) %THEN %DO; WHERE &SCORE GE 10; %END;
	%IF %EVAL(%LENGTH(&WGT)=0) %THEN %DO; unit_weight=1; %LET WGT=unit_weight; %END;
run;

proc sort data = step_pre (where = (&score ne . & &the_var ne .)) out = step1;
	by &sort_order &score;
run;

data step2;
	set step1 end=last;
	retain cumulative 0;
	cumulative + &wgt;
	if last then do;
		call symput('totpop',left(cumulative));
	end;
run;

data step3 (keep=&score bin percentile);
	set step2;
	by &sort_order &score;
	percentile=((cumulative/&totpop)*100);

	do i = 1 to &groups;
	if percentile > (i-1)*100/&groups 
		& percentile le i*100/&groups then bin=i; 
	end;

	if percentile > 100 and bin = . then bin = &groups;

	if last.&score;
run;

data step4;
	merge step3 step2;
	by &sort_order &score;
run;


proc report data=step4 nowindows headline headskip missing out = unwgted; 
	column 	bin 
		n 
		pctn 
		&wgt 
		&wgt = wgt_pct 
		&score 
		&score = &score._max 
		&score = &score._mean 
		&the_var 
		&the_var = &the_var._sum 
		&the_var = &the_var._pct
	;

	define bin /group format=2. width=9 'Score Bin' noprint; 
	define n / format=comma9. width=9 'Number of Accounts' noprint;
	define pctn / format=percent6.2 width=9  ' Percent of Accounts' noprint;
	define &wgt / analysis sum format=comma9. 'Sum of Weights' noprint;
	define wgt_pct / analysis pctsum format = percent8.2 'Percent Sum of Weights' noprint;
	define &score / analysis min format=6.0  width = 9 'Minimum Score' noprint;
	define &score._max / analysis max format=6.0 width = 9 'Maximum Score' noprint;
	define &score._mean / analysis mean format=comma5.2 width=9 'Average Score' noprint;
	define &the_var / analysis mean format=8.2 width =9 'Average of Dependent' noprint;
	define &the_var._sum / analysis sum format=comma9. width=9 'Sum of Dependent' noprint;
	define &the_var._pct / analysis pctsum format=percent6.2 width = 9 'Percent of Dependent' noprint; 

	rbreak after / dol dul summarize;
	*title 'Lift Table';
run;

proc sort data=unwgted;
	by bin;
run;

proc report data=step4 nowindows headline headskip missing out = wgted; 
	column 	bin 
		n 
		pctn 
		&wgt 
		&wgt = wgt_pct 
		&score 
		&score = &score._max 
		&score = &score._mean 
		&the_var 
		&the_var = &the_var._sum 
		&the_var = &the_var._pct 
		&bal_var 
		&bal_var = &bal_var._sum
		&bal_var = &bal_var._pct
	; 

	weight &wgt;

	define bin / group format=2. width=9 'Score Bin' noprint; 
	define n / format=comma9. width=9 'Number of Accounts' noprint;
	define pctn / format=percent6.2 width=9  ' Percent of Accounts' noprint;
	define &wgt / analysis sum format=comma9. 'Sum of Weights' noprint;
	define wgt_pct / analysis pctsum format = percent8.2 'Percent Sum of Weights' noprint;
	define &score / analysis min format=6.0  width = 9 'Minimum Score' noprint;
	define &score._max / analysis max format=6.0 width = 9 'Maximum Score' noprint;
	define &score._mean / analysis mean format=comma5.2 width=9 'Average Score' noprint;
	define &the_var / analysis mean format=percent6.2 width =7 'Average of Dependent' noprint;
	define &the_var._sum / analysis sum format=comma9. width=9 'Sum of Dependent' noprint;
	define &the_var._pct / analysis pctsum format=percent6.2 width = 9 'Percent of Dependent' noprint; 
	define &bal_var / analysis mean format=dollar10.0 width=12 "Average of %upcase(&bal_var)" noprint;
	define &bal_var._sum / analysis sum format=dollar15.0 width=19 "Sum of %upcase(&bal_var)" noprint;
	define &bal_var._pct / analysis pctsum format=percent6.2 width=9 "Percent of %upcase(&bal_var)" noprint;

	rbreak after / dol dul summarize;
run;

proc sort data=wgted;
	by bin;
run;

data wgted;
	set wgted (keep = bin &score &score._max &score._mean &the_var &the_var._sum &the_var._pct &bal_var &bal_var._sum &bal_var._pct);

	format bin2 $5.;

	if bin = . then bin2 = "Total";
	else bin2 = put(bin, $5.);

	if bin = . then bin = &groups + 1;
run;

proc sort data=wgted;
	by bin;
run;

data wgted;
	set wgted;

	retain cum_pct 0;
	retain &bal_var._cum_pct 0;
	cum_pct + &the_var._pct;
	&bal_var._cum_pct + &bal_var._pct;

	if bin2 = "Total" then do;
		cum_pct = 1;
		&bal_var._cum_pct = 1;
	end;

run;

proc sort data=wgted;
	by bin;
run;

data unwgted; 
	set unwgted (keep = bin n pctn &wgt wgt_pct);

	rename n = num;
	rename pctn = pctnum;

	format bin2 $5.;

	if bin = . then bin2 = "Total";
	else bin2 = put(bin, $5.);

	if bin = . then bin = &groups + 1;
run;

proc sort data=unwgted;
	by bin;
run;

data unwgted;
	set unwgted;

	retain cum_wgt 0;
	cum_wgt + wgt_pct;
	if bin2 = "Total" then cum_wgt = 1;
run;

proc sort data = unwgted;
	by bin;
run;

data wgt_lift;
	merge unwgted wgted;
	by bin2;

	cum_lift = (cum_pct - cum_wgt) / cum_wgt;
	non_cum_lift = &the_var._pct / wgt_pct;
	if bin2 = "Total" then non_cum_lift = .;
run;

proc report data=wgt_lift nowindows headline headskip missing out=&out_table; 
	column 	bin 
		bin2 
		num 
		pctnum 
		
		&wgt
		wgt_pct
		
		&wgt 	= est_pop 
		wgt_pct = est_pop_pct
		cum_wgt 
		&score 
		&score._max
		&score._mean
		&the_var 
		&the_var._sum
		&the_var._pct
		cum_pct 
		cum_lift 
		non_cum_lift 
		&bal_var 
		&bal_var._sum
		&bal_var._pct
		&bal_var._cum_pct
	; 

	define bin / order order=data format=2. width=9 'Score Bin' noprint; 
	define bin2 / group format=$5. width=9 'Score Bin'; 
	define num / analysis sum format=comma9. width=9 'Number in Sample';
	define pctnum /analysis sum format=percent6.2 width=9  ' Percent of Sample';
	
	define &wgt / analysis sum format=comma9. width=10 'Estimated Population' NOPRINT;
	define wgt_pct / analysis sum format = percent8.2 width=12 'Estimated Percent of Population' NOPRINT;

	define est_pop / analysis sum format=comma9. width=10 'Estimated Population';
	define est_pop_pct / analysis sum format = percent8.2 width=12 'Estimated Percent of Population';
	define cum_wgt / analysis max format = percent8.2 width=12 'Estimated Cumulative Percent of Population';
	define &score / analysis min format=6.0  width = 9 "Minimum &Score";
	define &score._max / analysis max format=6.0 width = 9 "Maximum &Score";
	define &score._mean / analysis mean format=comma5.2 width=8 "Average &Score";
	define &the_var / analysis mean format=percent6.2 width =8 "Average of &the_var";
	define &the_var._sum / analysis sum format=comma15. width=17 "Sum of &the_var";
	define &the_var._pct / analysis sum format=percent6.2 width = 7 "Percent of &the_var";
	define cum_pct / analysis max format=percent6.2 width = 7 "Cumulative Percent of &the_var";
	define cum_lift / analysis min format=8.2 width = 10 'Cumulative Lift';
	define non_cum_lift / analysis mean format=8.2 width = 10 'Non-Cumulative Lift';
        define &bal_var / analysis mean format=dollar10.0 width=12 "Average of %upcase(&bal_var)";
	define &bal_var._sum / analysis sum format=dollar16.0 width=19 "Sum of %upcase(&bal_var)";
	define &bal_var._pct / analysis mean format=percent6.2 width=9 "Percent of %upcase(&bal_var)";
	define &bal_var._cum_pct / analysis max format=percent6.2 width = 7 "Cumulative Percent of %upcase(&bal_var)";

	title "Weighted Lift Table Using %upcase(&score) Score in Predicting %upcase(&the_var) Response and %upcase(&bal_var) Using Weight=%upcase(&wgt)";

	*rbreak after / dol dul summarize;

run;
%mend report_lift_chart_wgt_dollar;
