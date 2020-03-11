%PUT BEGIN QUICK MODELING var reduction;

/***********************************/
/* QUICK modeling */
/***********************************/
%let out_table		= reduce_quick;	/*name to call the output table*/
%let out_lib		= work;				/*output table library name*/

%include '/data/41/fmsccanalytics/common/opencode/modeling_var_reduction.sas';

%PUT BEGIN VAR TRANS;
/* Call the variable transformation program*/
/* DEPOINT oct 2002*/
/* supply a modeling data set and a table with a variable list */
/* and it will give you an output list with multiple transformations, e-logit plots, and PROC UNIVARIATE results.*/

%let var_table		= reduce_quick;		/*name of the var list table*/
%let var_lib		= work;		/*library of the varlist table*/
%let key_var		= varname;
%let TRANSF_TEST	= Y;
%include '/data/41/fmsccanalytics/common/opencode/modeling_var_trans.sas';

%PUT BEGIN VAR TRANS INSERT;
/* Call the transformation insertion program*/
/* DEPOINT oct 2002*/
/* supply a table with variable names*/
%let key_var		= varname;	/*name of variable with variable names*/
%let out_lib		= work;
%let out_table		= quick_tran;
%include '/data/41/fmsccanalytics/common/opencode/modeling_insert_trans.sas';

%PUT BEGIN ESTIMATE LOGIT;
/* Call the model estimation logit program*/
/* DEPOINT oct 2002*/
/* supply a modeling data set */

%LET DEV_VAL_SPLIT	= .50;	/*how many do you want in developement and validation*/

%let trans_table	= quick_tran;	/*the test list of transformations*/
%let trans_lib		= work;	/*the location of said table in UNIX format. IF NO TRANS, then leave blank.*/

%let ignore_vars	= 

;	/*variables you want to remove as potential independent variables*/

/************************************************************************/
/* FINAL ANALYSIS							*/
/************************************************************************/
%let final_ind_var =
;

%let FINAL=		N;	/*If Final Estimation then label (Y)es. Final Estimation will output parameter tables with diagnostics*/
				/* to a RTF file*/
%let final_LOC		= ./;
%let final_name		= JUNK&model_table;
%include '/data/41/fmsccanalytics/common/opencode/modeling_estimation_logit.sas';

%LET FINAL = Y;
%CREATE_OUTPUT();
