/* Call a quick var reduce, trans and modeling*/
/* DEPOINT NOVEMBER 2002*/
/* updated may 2003*/
/* supply a modeling data set and it will give you a table with a list of variables and their specific statistics*/
/* it ranks variables by their pearson's correlation coefficient and their CHISQ value */
/* needs an include for the modeling_macros.sas */

%let model_table	= ;				/*table you will model on*/
%let model_lib		= model;				/*model table location*/
%let DEPVAR		= ;				/*name of the dependent variable*/
%let ignore_list	= ;				/*ariables you do wish to ingore as potential independent variables*/
%let must_keep_list	= ;		/*variable that will make it through the varclus*/
%let keep_amt		= 75;				/*specify the number of variables you want to keep, as ranked by PCORR or CHISQ*/
%let RISK_MODEL		= Y;	/*if Risk model, then put Y, leave blank otherwise*/

%let export_type	= SAS; /*either SAS or SA (scoreadvantage)*/
%let var_type_flag	= ;	/*Leave Blank*/


%include '/home/m666528/macros/modeling_quick.sas';

