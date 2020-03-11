%macro MODEL_ESTIMATION_LOGIT(in_table,LHS,variables,selection=%QUOTE(backward fast),results_table=RESULTS1,ESTIMATE_OUT_TABLE=DEV_BETAS);
/************************************************************************************/
/*	estimate logit and produce diagnostics. NO Offset or class features available	*/
/*	DePoint and Gravenish November 1, 2001						*/
/* 	modified by D and G Aug 2003 */
/************************************************************************************/
/********************** BEGIN estimate and capture the parameters **********************/
/*get the correct pvalue for SLSTAY based upon a approximation of the BAYESIAN-INFORMTION CRITERIA */
/* 1 - probchi(k*log(n),DF)*/
/* where k is the number of competing risks [1 for the binomial logit] */
/*and DF is 1 *k */
/*each RHS variable has 1 DF unless a CLASS variable */
/* then equation would be DF = (# of levels) * (k) */
proc sql;
select 1-probchi(2*log(sum(&LHS>0)),2) into :sl
from &IN_TABLE;
quit;
	title;
	ods listing close;
		ods output parameterestimates=PARMS;
		ods output  OddsRatios=odds;
		ods output  responseprofile=responseprofile;
		ods output  rsquare=r2;
		ods output  association=association;
		ods output  corrb=corrb;

		proc logistic data=&in_table descending NAMELEN=50 OUTEST=&ESTIMATE_OUT_TABLE;
		     model &LHS = &variables / selection = &selection SLSTAY=&SL corrb RSQ stb;
		     output out=pred predicted = _p_ ;
		run;
		ods output close;
	ods listing;
/************************ END estimate and capture the parameters **********************/
/***************************************************************************************/
/************************ BEGIN CREATE Parameter Macro	********************************/
	proc sql noprint; 		select variable
			into	:parm_list SEPARATED BY ' '
			from PARMS
			where variable ne 'Intercept'
			;
	quit;
/************************ END CREATE Parameter Macro	*********************************/
/****************************************************************************************/
/*FIX STUPID BETAS FROM PARM_TABLE TO REMOVE THOSE parameters with missing estimate */
/* why are there missing estimates? Because the parm_table from the DEV outest option */
/*resulted from a BACKWARD selection process, not a final model choice. */

data &ESTIMATE_OUT_TABLE;
	set &ESTIMATE_OUT_TABLE (keep=&PARM_LIST INTERCEPT _NAME_ _TYPE_);
;	


/************************ BEGIN MULTICOLLINEARITY		*********************************/
/* TOO MANY Tolerance below .40	or a variance inflation above 10						*/
		data test_multi;
			set pred;
			w = _p_*(1-_p_);
	ods listing close;
		ods output parameterestimates=multi_parms;
		PROC REG data=test_multi;
			weight w;
			MODEL &LHS = &parm_list /TOL VIF;
		RUN;
		ods output close;
	ods listing;	
/************************ END MULTICOLLINEARITY		*********************************/

/************************ BEGIN FINAL ESTIMATION OUTPUT		*********************************/
/* clean up the Output					*/
/* Produce the signs from CORR, and 	*/
/* Compare to signs from Regression		*/
/****************************************/
	/*get the mean of LHS to create the Delta-P below*/
	proc means data=&in_table NOPRINT;
	var &LHS;
	OUTPUT OUT=&LHS._MEAN
				MEAN(&LHS)	= &LHS._MEAN
				;
	data _null_;
		set &LHS._MEAN;
		call symput("&LHS._MEAN",&LHS._MEAN);
	run;

	/* set the R2 and C stats on top of each other, for easier printing	*/ 
	data r2c;
		set r2(keep=label1 nvalue1 rename=(label1=variable nvalue1=estimate)) 
			association(keep=label2 nvalue2 rename=(label2=variable nvalue2=estimate));
		if variable in ( 'R-Square', 'c');
		StandardizedEst = estimate;

	proc print data=responseprofile;
	title "Response Profile for &LHS";
	proc print data=corrb;
	title 'Correlation Matrix';
	run;

	%MAKE_CORR(in_lib=work,in_table=&in_table,LHS=&LHS,RHS_variables=%QUOTE(&PARM_LIST),out_table=out_corr);

	proc sort data=PARMS; by variable;
	proc sort data=multi_parms; by variable;
	proc sort data=r2c; by variable;
	proc sort data=odds; by effect;

	/* Get all of the results into one table for easier printing	*/
	data &results_table;
		merge 	PARMS
				odds(rename=(effect=variable)) 
				out_corr 
				multi_parms(keep=tolerance varianceinflation variable)
				;
		by variable;
		sign = '(-)';
		if estimate > 0 then sign='(+)';
		abs_stdbeta	= ABS(StandardizedEst);
		if variable ne 'Intercept' then delta_p	= estimate*(1-&&&LHS._MEAN)*&&&LHS._MEAN;
		odds	= 1/(OddsRatioEst);
		label 	odds	= "1/(odds_ratio)"
				;
	proc sort data=&results_table; by descending abs_stdbeta;
	data &results_table;
		set &results_table r2c;
	*proc contents data=&RESULTS_TABLE;
	proc print data=&results_table;
		title "Parameters, and diagnostics for &LHS on &IN_TABLE";
		var variable sign corr_sign corr_estimate StandardizedEst ProbChiSq  WaldChiSq varianceinflation;
	run;
%mend MODEL_ESTIMATION_LOGIT;
