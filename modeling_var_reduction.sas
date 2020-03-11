/* the variable reduction program*/
/* DEPOINT oct 2002*/
/*	Updated DePoint May 2003 JUN2004*/
/* supply a modeling data set and it will give you a table with a list of variables and their specific statistics*/
/* it ranks variables by their pearson's correlation coefficient and their CHISQ value */

/*	needs the modeling_macros.sas %included somewhere at a higher level*/

options nobyline nonumber nodate nodetails;
title;

/***********************************************************************/
/*GET LOCATION TO PUT ODS HTML OUTPUT*/
ods output directory=dir;
proc datasets library=&out_lib; run; quit;
ods output close;

data _null_;
	set DIR; if UPCASE(LABEL1) = 'PHYSICAL NAME';
	call symput ('HTML_LOCATION',CVALUE1);
run;

/*this creates new calc rollups only if  flag is not missing. keeps same model data otherwise*/

%CREATE_M(in_lib=&model_lib,in_table=&model_table,out_table=TOREDUCE,FLAG=&VAR_TYPE_FLAG)

/*********************************************************/
/*	GET NUMERIC VARIABLES		*/
/****************************************/
%get_var_names(in_lib=work,in_table=TOREDUCE,out_table=LIST1,var_list_name=LIST1,
                                out_lib=work,keep1=%QUOTE(name format label type),
                drop_list=%QUOTE(&DEPVAR APPLID ACCT_I PORTFOLIO_I &IGNORE_LIST));
data numeric;
        set list1;
       /* if MISSING(format) then output numeric;  *this does not work, zhu replaces it with type variable*/
		 if type=1 then output numeric;
run;

%get_values(in_lib=work,in_table=numeric,var_list_name=NUMERIC,var_name=name);
/**************************************************************/
/* VARCLUS reduction */
/************************************************************/
/* zhenhua comments out the original call of VAR_REDUCE_VARCLUS and add in the name2long_varclus: change made on 11/6/06 */
data toreduce; set toreduce; keep &DEPVAR &numeric; run;

%name2long_varclus(in_lib=WORK,in_table=TOREDUCE,out_lib=work,out_table=FROM_VARCLUS, variables=%QUOTE(&NUMERIC),print=Y);

/* %VAR_REDUCE_VARCLUS(in_lib=WORK,in_table=TOREDUCE,out_lib=work,out_table=FROM_VARCLUS, variables=%QUOTE(&NUMERIC),print=Y); */
data REDUCE_VARCLUS;
	set from_varclus;
	RANK_varclus= _n_;
run;

/*******************************************************************************************/
/*	NOW, only take the variables from the VARCLUS and send them through PCORR AND CHISQ*/
/*******************************************************************************************/
%get_values(in_lib=work,in_table=from_varclus,var_list_name=varclus_list,var_name=varname);

/************************************************/
/*	BEGIN VAR REDUCTION	PCORR		*/
/************************************************/
%make_corr(in_lib=WORK,in_table=TOREDUCE,LHS=&DEPVAR,RHS_variables=%QUOTE(&varclus_list &must_keep_list),out_table=out_corr_num);

proc sql;
        create table workable1 as
              select variable as name,corr_sign,
	        	ABS(corr_estimate) as corr_abs
	        from out_corr_num
	        where corr_estimate NOT = .
	
        ;
quit;
proc sort data=workable1;
	by descending corr_abs;

data REDUCE_PCORR;
	set workable1;
	if _n_ <= &keep_amt;
	RANK_PCORR = _n_;
	rename name=varname;
run;
/**************************************************************/
/* Now, do CHISQ reduction */
/*************************************************************/
options nonotes; 
%MAKE_CHISQ(in_table=TOREDUCE,LHS=&DEPVAR,IND_VARIABLES=%QUOTE(&varclus_list &must_keep_list),
		GROUPS=10,out_table=OUT_CHISQ,out_lib=work,in_lib=WORK,PRINT=NO);
options notes;

data REDUCE_CHISQ;
	set out_chisq;
	if _n_ <= &keep_amt;
	RANK_CHISQ = _n_;
run;

/*************************************/
/** GET THE LABELS AND APPEND TO XLS */
/*************************************/
%get_var_names(in_lib=&MODEL_LIB,in_table=&MODEL_TABLE,out_table=LABELS,var_list_name=LABELS,
                                out_lib=work,keep1=%QUOTE(name label),
                drop_list=%QUOTE());

/*******************************************************/
/* Bring them all together */
/*******************************************************/


***zhu modify the varname length to make it consistent ($100) across the four datasets***;
data REDUCE_PCORR; set REDUCE_PCORR; length varname2 $100; varname2=varname; rename varname2=varname; drop varname; run;
data REDUCE_CHISQ; set REDUCE_CHISQ; length varname2 $100; varname2=varname; rename varname2=varname; drop varname; run;
data REDUCE_VARCLUS; set REDUCE_VARCLUS; length varname2 $100; varname2=varname; rename varname2=varname; drop varname; run;
data LABELS; set LABELS; length name2 $100; name2=name; rename name2=name; drop name; run;
***end of zhu modification***;

proc sort data = REDUCE_PCORR; by varname;
proc sort data = REDUCE_CHISQ; by varname;
proc sort data = REDUCE_VARCLUS; by varname;
proc sort data = LABELS; by name;
run;


data &out_lib..&out_table;
merge REDUCE_PCORR(in=P) REDUCE_CHISQ(in=C) REDUCE_VARCLUS LABELS(RENAME=(name=varname));
	by varname;
	if P or C;
	VARNAME = UPCASE(VARNAME);
	VALUE_MISSING	= 0;	label value_missing 	= 'default missing value in a trans --> insert alternate value';
	VALUE_ZERO	= 0;		label value_zero	= 'default zero value in a trans --> insert alternate value';
	VALUE_MIN	= 0;		label value_min		= 'default min value in a trans --> insert alternate value';
	VALUE_MAX	= 999999999;	label value_max		= 'default max value in a trans --> insert alternate value'; 
	VALUE_POWER	= 1;		label value_power	= 'default power trans in a trans --> insert alternate value';
	VALUE_LN	= 0;		label value_ln		= 'take LN (X+1) --> 1';
	VALUE_ABS	= 0;		label value_abs		= 'take ABS(X)	--> value to add to var then ABS';
	VALUE_BIN	= 0;		label value_bin		= 'form a binary variable --> value to set break at';
	VALUE_KEEP	= 1;		label value_keep	= 'keep variable for estimation -->1';
	RENAME _pchi_ = CHISQ_VAL
			nmiss = nmiss_chi;
RUN;
proc sort data=&OUT_LIB..&OUT_TABLE NODUPKEY; by VARNAME;
proc sort data=&OUT_LIB..&OUT_TABLE; by RANK_PCORR;
run;

ods html style=minimal file="&HTML_LOCATION/&OUT_TABLE..xls";
proc print data=&OUT_LIB..&OUT_TABLE NOOBS;
	var varname corr_sign corr_abs CHISQ_VAL nmiss_chi RANK_PCORR RANK_CHISQ 
		value_min value_max value_missing value_zero value_power value_ln value_bin value_abs value_keep label;
        where COMPRESS(varname) NOT = ' '
	;
	/*IGNORE THESE COLUMNS FOR NOW JUN2004  p_pchi  RsquareRatio RANK_VARCLUS */
run;
ods html close;
