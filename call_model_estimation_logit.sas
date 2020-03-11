/* Call the model estimation logit program*/
/* DEPOINT oct 2002*/
/* updated may 2003 April 2004 */
/* supply a modeling data set */
/* needs an include for the modeling_macros.sas */

%let model_table	= ;				/*table you will model on*/
%let model_lib		= model;				/*model table location*/
%let DEPVAR		= ;				/*name of the dependent variable*/
%LET DEV_VAL_SPLIT	= .50;	/*how many do you want in developement and validation*/
%let RANDOM_SEED	= 0;/*do you want a fixed or random seed? if random, then value=0 */
%let var_table		= ;	/*a table that contains the potential independent variables*/
%let var_lib		= ;	/*the location of said table*/
%LET key_var		= varname;	/*the variable in the list that has the VARNAMES as values*/

%let trans_table	= ;	/*the test list of transformations*/
%let trans_lib		= &var_lib;	/*the location of said table in UNIX format. IF NO TRANS, then leave blank.*/
%let RISK_MODEL		= ;	/*if Risk model, then put Y, leave blank otherwise*/

%let ignore_vars	= 

;	/*variables you want to remove as potential independent variables*/

/************************************************************************/
/* FINAL ANALYSIS							*/
/************************************************************************/
%let final_ind_var =
;

%let FINAL	=	N;	/*If Final Estimation then label (Y)es. Final Estimation will output parameter tables with diagnostics*/
				/* to a RTF file*/
%let export_type	= SAS; /*SAS*/
%let final_LOC		= ;  /* in UNIX format*/
%let final_name		= FINAL1&model_table;

%include '/home/m666528/macros/modeling_estimation_logit.sas';

