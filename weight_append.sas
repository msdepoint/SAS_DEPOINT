%macro weight_append(in_lib=,in_table=,out_lib=,out_table=,dep_var=,pop_resp_rate=,wgt_name=);
/****************************************************************************************/
/* MACRO TO CALCULATE WEIGHT AND APPEND ONTO SAMPLE TABLE				*/
/* A. CHIN  27JUN2003									*/
/*											*/
/* Macro will wgt_name (weight name) value field to output table.                       */
/* Weight name is used with offset statement in PROC LOGISTIC.                          */
/*                                                                                      */
/* in_lib = library name for SAMPLE table						*/
/* in_table = table name for SAMPLE table						*/
/* out_lib = output library name                                                        */
/* out_table = output table name                                                        */
/* dep_var = the binary DEPENDENT variable						*/
/* pop_resp_rate = PROPORTION of events in POPULATION	(POPULATION RESPONSE RATE)	*/
/* wgt_name = name of NEW weight variable (to be appended)				*/
/****************************************************************************************/

proc means data=&in_lib..&in_table noprint;
  var &dep_var;
  output out=sum mean=rho1;
run;

data _null_;
  set sum;
  call symput('rho1',rho1);
run;

data &out_lib..&out_table;
  set &in_lib..&in_table;
  &wgt_name = ((1-&pop_resp_rate.)/(1-&rho1))*(&dep_var=0)+(&pop_resp_rate./&rho1)*(&dep_var=1);
run;

%mend;

