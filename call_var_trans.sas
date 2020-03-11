/* Call the variable transformation program*/
/* DEPOINT oct 2002*/
/* updated May 2003 April 2004*/
/* supply a modeling data set and a table with a variable list */
/* and it will give you an output list with multiple transformations, e-logit plots, and PROC UNIVARIATE results.*/
/* needs an include for the modeling_macros.sas */

%let model_table	= ;				/*table you will model on*/
%let model_lib		= ;			/*model table location*/
%let DEPVAR		= ;				/*name of the dependent variable*/

%let var_table		= ;		/*name of the var list table*/
%let var_lib		= ;		/*library of the varlist table*/
%let Transf_test	= N; 	/*if you are testing transformation you all ready choose, put Y. First time call*/
							/* leave at N	*/
%let key_var		= varname;
%let var_type_flag	= ;	/*LEAVE BLANK FOR NOW*/

%include '/home/m666528/macros/modeling_var_trans.sas';

