%MACRO duration_calc(in_tables_set_list=,out_table=,out_lib=work);
/* DePoint August 2006*/
/* USES PRESENT VALUE CALCULATIONS to estimated the change in PV given different*/
/* shock scenarios	*/
/* ASSUME there will be 7 tables to set on top of each other*/
/* base line and 6 shocks*/

DATA pva_ALL;
	SET %UNQUOTE(&in_tables_set_list)
	;
RUN;
/****************************/
/* SET UP the DATA to calc Duration	*/
/****************************/
PROC SORT DATA=pva_all; BY shock;RUN;
DATA pva_prelim1; SET pva_all;	pv_lag	=  LAG(PV);	RUN;
PROC SORT DATA=pva_all; BY DESCENDING shock;RUN;
DATA pva_prelim2; SET pva_all;	pv_lead	=  LAG(PV); RUN;
PROC SORT DATA=pva_prelim1; BY shock; PROC SORT DATA=pva_prelim2; BY shock;

DATA &out_lib..&out_table ; MERGE pva_prelim1 pva_prelim2; BY shock;
	FORMAT duration 8.2;
	IF shock < 0 		THEN duration = 100*(pv - pv_lead)/pv_lead;
	ELSE IF shock > 0 	THEN duration = 100*(pv - pv_lag)/pv_lag;
	ELSE IF shock = 0 	THEN duration = 100*(((pv_lag -pv)/pv) + ABS((pv_lead - pv)/pv) )/2;
									/** +100 				-100		**/
	DROP pv_lead pv_lag;
RUN;

PROC SORT DATA=&out_lib..&out_table ; BY DESCENDING shock;RUN;

PROC DATASETS;
	DELETE pva_all pva_prelim1 pva_prelim2;
QUIT;
%MEND duration_calc;