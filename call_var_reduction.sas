/* Call the variable reduction program*/
/* DEPOINT oct 2002*/
/* updated may 2003 April 2004*/
/* supply a modeling data set and it will give you a table with a list of variables and their specific statistics*/
/* it ranks variables by their pearson's correlation coefficient and their CHISQ value */
/* needs an include for the modeling_macros.sas */

%let model_table	= ;				/*table you will model on*/
%let model_lib		= ;				/*model table location*/
%let DEPVAR		= ;				/*name of the dependent variable*/
%let ignore_list	= ;				/*variables you do wish to ingore as potential independent variables*/
%let must_keep_list	= ;		/*variables you want to save through the varclus procedure */
%let out_table		= var_reduction&model_table;	/*name to call the output table*/
%let out_lib		= ;				/*output table library name*/
%let keep_amt		= 75;				/*specify the number of variables you want to keep, as ranked by PCORR or CHISQ*/
%let var_type_flag	= ;				/*LEAVE blank for now*/

%include '/home/m666528/macros/modeling_var_reduction.sas';
