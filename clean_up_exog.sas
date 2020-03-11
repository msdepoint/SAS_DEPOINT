%MACRO clean_up_exog(in_lib=,in_table=,out_lib=work,out_table=);
PROC FORMAT;
Value $exog
FEDFUND	= 'Effective Federal Funds Rate'
TCM10Y	= '10-Year Treasury Constant Maturity Rate'
TCM1M	= '1-Month Treasury Constant Maturity Rate'
TCM1Y	= '1-Year Treasury Constant Maturity Rate'
TCM20Y	= '20-Year Treasury Constant Maturity Rate'
TCM2Y	= '2-Year Treasury Constant Maturity Rate'
TCM3M	= '3-Month Treasury Constant Maturity Rate'
TCM3Y	= '3-Year Treasury Constant Maturity Rate'
TCM5Y	= '5-Year Treasury Constant Maturity Rate'
TCM6M	= '6-Month Treasury Constant Maturity Rate'
TCM7Y	= '7-Year Treasury Constant Maturity Rate'
;
DATA wait132; SET &in_lib..&in_table;
	product = UPCASE(product);
RUN;

%MACRO loopit(time_period=week);
DATA analyze_it; SET wait132;
	FORMAT series_date_&time_period date9.;
	series_date_&time_period	= INTNX("&time_period",series_date,0,'END');
RUN;
ODS OUTPUT summary=product_mean_&time_period(	KEEP=series_date_&time_period rate_mean product 
										RENAME=(series_date_&time_period=series_date rate_mean=rate_&time_period));
PROC MEANS DATA=analyze_it;
	CLASS PRODUCT series_date_&time_period;
	VAR rate;
RUN;
PROC SORT DATA=product_mean_&time_period; BY product series_date;
%MEND loopit;
ODS LISTING CLOSE;
%loopit(time_period=week);
%loopit(time_period=month);
%loopit(time_period=quarter);
ODS LISTING;
DATA mean_rates;
	MERGE product_mean_week product_mean_month product_mean_quarter;
	FORMAT rate_week rate_month rate_quarter 8.2;
	BY product series_date;
	label	rate_week = 'RATE WEEK simple mean'
			rate_month = 'RATE MONTH simple mean'
			rate_quarter = 'RATE QUARTER simple mean'
			;
RUN;	

PROC SORT DATA=wait132; BY product series_date;RUN;
DATA &out_lib..&out_table;
	MERGE mean_rates wait132;
	BY product series_date;
	FORMAT product_label $42. ;
	product_label = PUT(product,$exog.);
RUN;
PROC DATASETS library=work NOLIST;
	DELETE mean_rates wait132 analyze_it;
QUIT;
%MEND clean_up_exog;