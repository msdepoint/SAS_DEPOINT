/************************************************************************************************/
/* this needs a %include of the modeling macros at the call template level*/
/* modified by DePoint Gravenish-Reilly Aug2003 */
/* Modified by DePoint Jun 2004 */
/************************************************************************************************/

/************************************************************************************************/
/*LIST OF actions in this program		*/
/* 1) get transformation information		*/
/* 2) grab RHS variables that the user defined a potentional modeling variables */
/* 3) split into  DEVELOPMENT and VALIDATION data sets randomly (possible to input same random seed) */
/* 4) Perform PROC LOGISTIC (either BACKWARD FAST selection or FINAL MODEL OUTPUT) */
/* 5) create model diagnostics on the VALIDATION data set */
/* 6) create SCORECODE output if final model */
/* 7) create ODS RTF output file, if final model */
/************************************************************************************************/


/************************************************************************************************/
/*	TRANSFORMATIONS						*/
/*GET TRANSFORMATIONS FROM LOCATION 	trans_lib trans_table	*/
/************************************************************************************************/

/*GET LOCATION OF WORK TO PUT txt OUTPUT*/
ods output directory=dir;
proc datasets library=work; run; quit;
ods output close;

data _null_;
	set DIR; if UPCASE(LABEL1) = 'PHYSICAL NAME';
	call symput ('LOCATION',CVALUE1);
run;
options nobyline nonumber nodate nodetails;
title;
data toprint;
	set &trans_lib..&trans_table(keep=t);
run;
FILENAME routed "&LOCATION/tran_full.txt";
data _null_;
	set toprint;
	file routed notitles;
	put @1 t $120.;
	return;
run;
%let the_trans=%QUOTE(%INCLUDE  "&location/tran_full.txt" );

/************************************************************************************************/
/*GET INDEPENDENT VARIABLES */
/************************************************************************************************/
data IND_TEMP;
	&the_trans;
run;
%get_var_names(in_lib=work,in_table=IND_TEMP,out_table=INDVARS_prelim,var_list_name=INDVARS_prelim,
                                out_lib=work,keep1=%QUOTE(name label),
                drop_list=%QUOTE(&ignore_vars applid acct_i portfolio_i date_campaign));
                
DATA MODEL_IT;
	SET &MODEL_LIB..&MODEL_TABLE;
	&THE_TRANS;
	keep &DEPVAR &INDVARS_prelim;
RUN;
/************************************************************************************************/
/*	GET NUMERIC VARIABLES		*/
/* make sure ONLY numeric 		*/
/************************************************************************************************/
%get_var_names(in_lib=work,in_table=MODEL_IT,out_table=LIST1,var_list_name=LIST1,
                                out_lib=work,keep1=%QUOTE(name label type),
                drop_list=%QUOTE(&DEPVAR));
data INDVARS;
        set list1;
        IF TYPE = 1; /*type=1 means it is numeric */
run;
%get_values(in_lib=work,in_table=INDVARS,var_list_name=INDVARS,var_name=name);   

data model_it;
	set model_it;
	keep &depvar &INDVARS;
/************************************************************************************************/
/* PRINT OUT THE REMAINING POTENTIAL INDEPENDENT VARIABLES*/
/************************************************************************************************/
PROC PRINT DATA=INDVARS;
	TITLE "Independent variables still available for modeling";
	VAR NAME LABEL;
run;

/************************************************************************************************/
/*	split up into validation and development						*/
/************************************************************************************************/
%split_up(in_lib=WORK,in_table=MODEL_IT,devset=development,valset=validation,percent=&DEV_VAL_SPLIT,seed=&RANDOM_SEED)


/************************************************************************************************/
/* Perform PROC LOGISTIC*/
/* from this MACRO, we use RESULTS_TABLE to display the results of the PROC LOGISTICS */
/* and we use the PARAMETER_TABLE to feed into the validation macro*/
/************************************************************************************************/
%MACRO PERFORM_LOGIT();
%IF &FINAL=Y %THEN %DO;		
	%MODEL_ESTIMATION_LOGIT(in_table=DEVELOPMENT,LHS=&DEPVAR,variables=%QUOTE(&final_ind_var),selection=NONE,results_table=results1,ESTIMATE_OUT_TABLE=DEV_BETAS)
%END;
%ELSE %DO;
	%MODEL_ESTIMATION_LOGIT(in_table=DEVELOPMENT,LHS=&DEPVAR,variables=%QUOTE(&INDVARS),selection=%QUOTE(BACKWARD FAST),results_table=results1,ESTIMATE_OUT_TABLE=DEV_BETAS)
%END;

%MEND PERFORM_LOGIT;

%PERFORM_LOGIT;


/************************************************************************************************/
/* create model diagnostics on the VALIDATION data set*/
/************************************************************************************************/
%MODEL_VALIDATION(in_dev=DEVELOPMENT,in_val=VALIDATION,LHS=&DEPVAR,parm_table=DEV_BETAS,dev_lib=work,val_lib=work,
		out_ROC_table=VAL_ROC_OUT,out_lift_table=VAL_LIFT_OUT,out_diag_table=VAL_DIAG_OUT,
		XBETA_MEAN_NAME=XBETA_MEAN);
/************************************************************************************************/
/* create LST OUTPUT for intermediate model or ODS RTF output if FINAL MODEL */
/************************************************************************************************/

	/*CREATE FANCY RESULTS TABLE */
	%get_var_names(in_lib=&MODEL_LIB,in_table=&MODEL_TABLE,out_table=LABELS,var_list_name=LABELS,
                                out_lib=work,keep1=%QUOTE(name label),
                drop_list=%QUOTE());

	proc sql;
	create table RESULTS_WITH_LABEL1 as
	SELECT *
	FROM
	(
		select  a.label as TRANSFORMATION,
			b.label,
			Variable, WaldChiSq, Estimate, StdErr, VarianceInflation, StandardizedEst,
			ABS(StandardizedEst) as abs_st
		from results1 a,  LABELS b
		where a.variable=b.name
	)
	order by abs_st desc
	;
	create table results_RSQ_C as
	SELECT variable, standardizedest 
	from results1
	where UPCASE(variable) IN ('R-SQUARE','C')
	;

	CREATE TABLE results_with_label2 AS
	SELECT *
	FROM 	
		(	SELECT varname,
			VALUE_ABS,
			VALUE_BIN,
			VALUE_LN,
			VALUE_MAX,
			VALUE_MIN,
			VALUE_MISSING,
			VALUE_POWER,
			VALUE_ZERO
		FROM 	&var_lib..&Var_table) v,
			results_with_label1 r
		WHERE UPCASE(r.variable) =  UPCASE(v.varname)
	;
	QUIT;

	data results_with_label;
		set results_with_label2 results_rsq_c;
		if UPCASE(variable) = 'C' then LABEL='C from development';
		if UPCASE(variable) = 'R-SQUARE' then LABEL='R-SQUARED from development';
		format var_trans $125.;
		var_trans = Variable||transformation;
	run;



%MACRO CREATE_OUTPUT();
%IF &FINAL=Y %THEN %DO;
	*options orientation=landscape;
	ods listing close;
	ods rtf BODYTITLE STARTPAGE=NO KEEPN FILE="&FINAL_LOC/&FINAL_NAME..DOC" style=RTF_small;
/*	
ods rtf FILE="&FINAL_LOC/&FINAL_NAME..DOC" style=RTF_small;
*/
	/**********************************/
	/* INSERT GENERIC DEFINITION TEXT */
	/**********************************/
	FILENAME def '/data/41/fmsccanalytics/common/opencode/model_results_definitions_list.txt';
	data _null_;
		infile DEF truncover;
		input DEFINITIONS $ 1-256;
		LABEL DEFINITIONS = "Interpreting the Results:";
		file print ODS;
		put _ODS_;
	run;
	/**********************/
	/*FANCY RESULTS TABLE */
	/**********************/
	ODS RTF TEXT = 'RESULTS from Validation using Development Estimates';
	proc print data=Results_WITH_LABEL LABEL NOOBS;
		title "RESULTS from Validation using Development Estimates ";
		LABEL 	VALUE_MIN 	= "MIN"
			VALUE_MAX 	= "MAX"
			VALUE_MISSING	= "Miss Replace"
			VALUE_ZERO	= "Zero Replace"
			;
		var 	Variable Label TRANSFORMATION
			VALUE_MIN
			VALUE_MAX
			VALUE_MISSING
			VALUE_ZERO
			;
	RUN;
	proc print data=Results_WITH_LABEL LABEL NOOBS;
		title "RESULTS from Validation using Development Estimates ";
		var Variable StandardizedEst WaldChiSq Estimate StdErr VarianceInflation;
	RUN;	
	/**********************/
	/*VALIDATION KS AND C DIAGNOSTICS */
	/**********************/
	ODS RTF TEXT = 'Validation Diagnostics';
	proc print data= VAL_DIAG_OUT LABEL NOOBS;
		title "Validation Diagnostics";
		var label1 nvalue1 label2 nvalue2;
	run;
	/**********************/
	/*ROC CURVE */
	/**********************/
	/*ROC */
	ODS RTF TEXT = 'Validation ROC Curve';
	proc plot data=VAL_ROC_OUT hpct=75 vpct=75;
		title "Validation ROC Curve";
	plot 	_sensit_*_1mspec_='R'/ haxis=0 to 1 by .1 vaxis=0 to 1 by .1; 	
	run;
	/**********************/
	/*LIFT TABLE */
	/**********************/
	ODS RTF TEXT = 'Lift Chart from Validation using Development Estimates';
	proc print data=VAL_LIFT_OUT label NOOBS;
		Title "Lift Chart from Validation using Development Estimates";
		format est_pop_pct &DEPVAR._pct cum_pct percent8.2;
		var bin est_pop_pct est_pop &DEPVAR._PRED &DEPVAR._PRED_max &DEPVAR._PRED_mean &DEPVAR &DEPVAR._sum &DEPVAR._pct cum_pct ;
	run;
	options nolabel;
	/**********************/
	/*SUMMARY STATISTICS OF RHS VARIABLES */
	/**********************/
	ODS RTF TEXT = "Summary Statistics from Original (&MODEL_TABLE)";
	PROC MEANS DATA=&MODEL_LIB..&MODEL_TABLE N MIN MAX MEAN MEDIAN;
		Title "Summary Statistics from Original (&MODEL_TABLE)";
		VAR &final_ind_var;
	RUN;
	ODS RTF TEXT = "Summary Statistics from Transformed (Validation)";
	PROC MEANS DATA=validation N MIN MAX MEAN MEDIAN;
		Title "Summary Statistics from Transformed (Validation)";
		VAR &final_ind_var;
	RUN;
	/**********************/
	/*Correlation Matrix */
	/**********************/
	ODS RTF TEXT = "Correlation Matrix from Original(&model_Table)";
	PROC CORR DATA=&MODEL_LIB..&MODEL_TABLE nosimple ;
        	VAR &final_ind_var; WITH &final_ind_var;
	Title "Correlation Matrix from Original(&model_Table)";
	RUN;
	ODS RTF TEXT = "Correlation Matrix from Transformed (Validation)";
	PROC CORR DATA=validation nosimple ;
        	VAR &final_ind_var; WITH &final_ind_var;
	Title "Correlation Matrix from Transformed (Validation)";
	RUN;

	options label;
	/*************************/
	/* MEANS PLOTS		*/
	/************************/
	Title "Means Plots from Validation";
	%string_loop(	var_list=&final_ind_var,
				action_code = %NRSTR(
ODS RTF TEXT = "Means Plots for &&WORD&i from Transformed (Validation)";
%edabivar(in_lib=work,in_table=VALIDATION,ind_var=&&WORD&i,dep_var=&DEPVAR,groups=20);
%ks_wgt(in_lib=work,in_table=VALIDATION,score=&&WORD&I,the_var=&DEPVAR,wgt=);
						)
			)
			;

ODS RTF CLOSE;


/********************************************************************************************/
/* create SCORECODE if FINAL MODEL */
/********************************************************************************************/ DATA EXTRA;
/*	SET &calc_lib..&calc_table		*/
/* This is where we would input the SQL query so that */
/* the scorecode would contain the raw calc definitions */
	format t $120.;
	t = "/*INSERT CALC VAR DEFINITIONS HERE*/";
RUN;

%MODEL_SCORE_EXPORT(model_lib=WORK,model_table=VALIDATION,
			PARM_LIST=%QUOTE(&PARM_LIST),RISKMODEL=&RISK_MODEL,
			trans_lib=&TRANS_LIB,trans_table=&TRANS_TABLE,
			BETAS=DEV_BETAS,TYPE=&EXPORT_TYPE,out_name=%QUOTE(&FINAL_NAME),XBETA_MEAN=&XBETA_MEAN,
extra_table=extra,extra_lib=work);

%END; /*END FINAL MODEL SECTION */

%ELSE %DO;
	/**********************/
	/*VALIDATION KS AND C DIAGNOSTICS */
	/**********************/
	proc print data= VAL_DIAG_OUT;
		title "Validation Diagnostics";
		var label1 nvalue1 label2 nvalue2;
	run;
	/**********************/
	/*LIFT TABLE */
	/**********************/

/***************
	proc print data=VAL_LIFT_OUT label NOOBS;
		Title "Lift Chart from Validation using Development Estimates";
		format est_pop_pct &DEPVAR._pct cum_pct percent8.2;
		var bin est_pop_pct est_pop &DEPVAR._PRED &DEPVAR._PRED_max &DEPVAR._PRED_mean &DEPVAR &DEPVAR._sum &DEPVAR._pct cum_pct ;
	run;
***************/

%END;
%MEND CREATE_OUTPUT;

%CREATE_OUTPUT;
