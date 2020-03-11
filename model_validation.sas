%macro MODEL_VALIDATION(in_dev,in_val,LHS,PARM_table=,dev_lib=work,val_lib=work,out_ROC_table=VAL_ROC_OUT,
			out_lift_table=VAL_LIFT_OUT,out_diag_table=VAL_DIAG_OUT,XBETA_MEAN_NAME=XBETA_MEAN);
/************************************************************************/
/*	take estimates from development set and push through validation set	*/
/*	DePoint SPRING 2002								*/
/*	Let the EXPORT toggle identify what type of export output we want	*/
/*	SAS or ScoreAdvantage(SA)											*/
/************************************************************************/
/************************ BEGIN CREATE Parameter Macro	********************************/
%get_var_names(in_lib=work,in_table=&PARM_TABLE,out_table=PARM_LIST,var_list_name=PARM_LIST,
                                out_lib=work,keep1=%QUOTE(name),
                drop_list=%QUOTE(_NAME_ _LINK_ _TYPE_ _STATUS_ _LNLIKE_ Intercept));
/************************ END CREATE Parameter Macro	*********************************/
ods listing close;
	ods output  association=association;
	proc logistic data = &val_lib..&in_val des inest = &PARM_TABLE;
		title "Validation Regression";
		model &LHS = &parm_list /maxiter=0 outroc=roc;
   		output out = xbeta_2B_meaned(keep=xbeta1) xbeta=xbeta1;
	run;
	ods output close;
ods listing;
/************************************************************************/
/*	capture  % of LHS var from development 								*/
/* (assuming no offset and random split) so original % = development %	*/
/************************************************************************/
proc means data = &dev_lib..&in_dev noprint;
	var &LHS;
	output out=sum mean=rho1;
data _null_;
	set sum;
	call symput('rho1',rho1);
run;
%let pi1 = &rho1; /*we assume their is no OFFSET	*/

/*****************************************/
/*OUTPUT FROM THIS MACRO #1		*/
/* ROC CURVE/TABLE			*/
/*****************************************/
data &OUT_ROC_TABLE; /*WE DO NOT use all of these measures, but just in case */
	set roc NOBS=TOTOBS;
	cutoff	= _prob_*&pi1*(1-&rho1)/(_prob_*&pi1*(1-&rho1)+(1-_prob_)*(1-&pi1)*&rho1);
	specif	= 1 - _1mspec_;
	tp		= &pi1*_sensit_;
	fn		= &pi1*(1-_sensit_);
	tn		= (1-&pi1)*specif;
	fp		= (1-&pi1)*_1mspec_;
	depth	= tp+fp;
	pospv	= tp/depth;
	negpv	= tn/(1-depth);
	acc		= tp+tn;
	lift	= pospv/&pi1;
	BASE	= _n_/TOTOBS;
	keep cutoff tn fp fn tp _sensit_ _1mspec_ specif depth pospv negpv acc lift BASE;
run;

/*score the validation data set with the training betas  and produced KS(D) */
proc score data = &val_lib..&in_val out=scova1 score=&PARM_TABLE type=parms;
	var &parm_list;

data scova1;
	set scova1;
	&LHS._pred = 1/(1+exp(-&LHS.2));
run;

ods listing close;
	ods output KolSmir2Stats=KS;
	proc npar1way edf wilcoxon data=scova1;
		class &LHS;
		var &LHS._pred;
	run;
	ods output close;
ods listing;

data ks;
	informat label1 label2 $32.;
	set ks;
	if UPCASE(label1) = "KS" then LABEL1  = "KS: one-sample KS";
	if UPCASE(label1) = "KSA" then LABEL1 = "KSa: asymptotic KS [ KS*sqrt(n)]";
	if UPCASE(label2) = "D" then LABEL2 = "D: two-sample KS";
	LABEL 	LABEL1 	= "Validation Results"
		LABEL2 	= "Validation Results"
		NValue1	= "Value"
		NValue2	= "Value"
	;
	
run;
/*****************************************/
/*OUTPUT FROM THIS MACRO #2		*/
/* VALIDATION KS and C			*/
/*****************************************/
data &OUT_DIAG_TABLE;
	informat label1 label2 $32.;
	set association ks;
run;

/*****************************************/
/*OUTPUT FROM THIS MACRO #3		*/
/* LIFT TABLE				*/
/*****************************************/
%tabulate_lift_chart_wgt(in_lib=work,in_table=scova1,score=&LHS._PRED,
	the_var=&LHS,wgt=,groups=10,sort_order=DESCENDING,exclusion=,out_table=&OUT_LIFT_TABLE);
run;
/*****************************************/
/*OUTPUT FROM THIS MACRO #4		*/
/* XBETA MEAN for SCORE_SCALED		*/
/*****************************************/
	/*get mean of XBETA for the scorecode to scale the score*/
	proc means data = xbeta_2B_meaned noprint;
	var xbeta1;
	output out =mean_xbeta mean = ;
	
	%GLOBAL &XBETA_MEAN_NAME;
	data _null_;
		set mean_xbeta end=last;
		if last then call symput("&xbeta_MEAN_NAME",left(xbeta1));
	run;
%MEND MODEL_VALIDATION;