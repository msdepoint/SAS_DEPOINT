/****** MACRO TO PULL CANADA DATA and assign BRANCH REGION with CUST LEVEL info like COMMERCIAL ******/

%macro month_compile_hbca(in_lib =,out_lib=,out_table=,table_type=ACCT,product_codes=,deposit_only=,min_dt=,max_dt=);

LIBNAME dwh "/camidata/SAS_DWH";
LIBNAME tools "/camidata/SAS_DWH/tools"; 
/*table_type	ACCT	DIM	*/
/* min_dt max_dt should be in '15JUN2008'd format	*/

/**********************/
%Let in_lib = dwh;

ODS LISTING CLOSE;
ODS OUTPUT MEMBERS=mem;
PROC DATASETS LIBRARY=&in_lib ; RUN; QUIT;
ODS OUTPUT close;
DATA table_names;
	SET mem (KEEP=name rename=(name=memname));
%IF %UPCASE(&table_type) = ACCT %THEN %DO;
		IF INDEX(UPCASE(memname),'CUST_ACCT_') 
		AND NOT index(UPCASE(memname),'CUST_ACCT_200807B')
		AND NOT index(UPCASE(memname),'CUST_ACCT_200808B')
		AND NOT index(UPCASE(memname),'CUST_ACCT_200808_B')
		AND NOT index(UPCASE(memname),'CUST_ACCT_200809_21OCT2008') 
		AND NOT index(UPCASE(memname),'SUM_CUST_ACCT_200804') 
                AND NOT index(UPCASE(memname),'CUST_ACCT_200812_BKP')
                AND NOT index(UPCASE(memname),'CUST_ACCT_200810_BACKUP_28NOV08')
                AND NOT index(UPCASE(memname),'CUST_ACCT_200809_21OCT2008')        
              AND NOT index(UPCASE(memname),'CUST_ACCT_200903_OLD')  
 	;
%END;

	date_STRING 	= COMPRESS(SUBSTR(memname,11,6));
RUN;


DATA updated_date_table; SET table_names;
FORMAT date_string_n 8.0;
	date_string_n = date_string;
   new_min		= YEAR(&min_dt)*100+	MONTH(&min_dt);
   new_max		= YEAR(&max_dt)*100+	MONTH(&max_dt);
   keepit		= (new_min <= date_string_n <= new_max);
	IF keepit;
RUN;


%get_values(in_lib=work,in_table=updated_date_table,var_list_name=date_names,var_name=date_string);
%PUT &date_names;

/************/
/* I CAN USE the table_names and date_string in conjunction with the min and max dt to limit things*/


%LET new_table_list	= ;


%IF %LENGTH(&product_codes)>0 %THEN %DO;
%STRING_LOOP	(var_list=&date_names,
				ACTION_CODE=%NRSTR
				( DATA acct&&word&i; 	SET &in_lib..CUST_ACCT_&&word&i;
					WHERE 	prime_flag='P'  AND pd_idkey IN (&product_codes);
					FORMAT snap_dt date9.;
					snap_dt	= INTNX('MONTH',MDY(SUBSTR("&&word&i",5,2),15,SUBSTR("&&word&i",1,4)),	0,'END');
              Keep AC_NO AC_STUS_ID PD_ID PD_IDKEY PD_CLS_ID AC_BRN_IDKEY AC_CY_ID EFF_DT DUE_DT A_CU_BAL start_dt
           TERM INT_RT CON_CST_ID EFF_CST_DT prime_flag balance snap_dt SV_CG_GID AUTH_CD;
                    
              if INTNX('MONTH',MDY(SUBSTR("&&word&i",5,2),15,SUBSTR("&&word&i",1,4)),  0,'END') > '30NOV2007'd 
	             then do; 
                                  Keep AC_AR_ID; 
                      end; 			 
          
                        RUN;

 				 DATA cust&&word&i;
				 SET &in_lib..cust_dim_&&word&i 
                                       (KEEP=CLASS_TP AC_STUS_ID CUST_NO CON_CST_ID premier 
                      CUST_BIR EFF_CST_DT END_CST_DT ETHINICITY_CODE GND HIB_ERL_IN 
              ETHINICITY_CODE GND IDV_NAT_ID CTY_ID SPK_LNG WRT_LNG_ID private CLIENT_IN CLASS BR_IDKEY pos_cd);
			          RENAME AC_STUS_ID = CUST_AC_STUS_ID;     	
                               RUN;

/***				 DATA closed&&word&i; 	SET &in_lib..CLOSED_ACCT_&&word&i;***/

   				 PROC SORT DATA=acct&&word&i; BY  con_cst_id;
   				 PROC SORT DATA=cust&&word&i; BY  con_cst_id;

				DATA new_table&&word&i;
					MERGE acct&&word&i(IN=a) cust&&word&i(IN=b);
					BY con_cst_id;
					IF a AND b;
				RUN;
				%LET new_table_list = &new_table_list new_table&&word&i;
 				)

				);
%END;
%ELSE %DO;
%STRING_LOOP	(var_list=&date_names,
				ACTION_CODE=%NRSTR
				( DATA acct&&word&i; 	SET &in_lib..CUST_ACCT_&&word&i;
					WHERE 	prime_flag='P';
					FORMAT snap_dt date9.;
					snap_dt	= INTNX('MONTH',MDY(SUBSTR("&&word&i",5,2),15,SUBSTR("&&word&i",1,4)),	0,'END');
                KEEP AC_NO AC_STUS_ID PD_ID PD_IDKEY PD_CLS_ID AC_BRN_IDKEY AC_CY_ID EFF_DT DUE_DT A_CU_BAL start_dt
                                        TERM INT_RT CON_CST_ID EFF_CST_DT prime_flag balance snap_dt SV_CG_GID AUTH_CD; 
    	       if INTNX('MONTH',MDY(SUBSTR("&&word&i",5,2),15,SUBSTR("&&word&i",1,4)),  0,'END') > '30NOV2007'd                              
                      then do;
                             Keep AC_AR_ID;end; 			 
			RUN;

 				 DATA cust&&word&i;
                        SET &in_lib..cust_dim_&&word&i 
                                 (KEEP= CLASS_TP AC_STUS_ID CON_CST_ID CUST_NO 
          CUST_BIR EFF_CST_DT END_CST_DT ETHINICITY_CODE GND HIB_ERL_IN 
          ETHINICITY_CODE GND IDV_NAT_ID CTY_ID SPK_LNG WRT_LNG_ID premier private CLIENT_IN CLASS BR_IDKEY LIN_EX_ID pos_cd);
				  RENAME AC_STUS_ID = CUST_AC_STUS_ID; 
                                 RUN;

/***				 DATA closed&&word&i; 	SET &in_lib..CLOSED_ACCT_&&word&i;***/

   				 PROC SORT DATA=acct&&word&i; BY  con_cst_id;
   				 PROC SORT DATA=cust&&word&i; BY  con_cst_id;

				DATA new_table&&word&i;
					MERGE acct&&word&i(IN=a) cust&&word&i(IN=b);
					BY con_cst_id;
					IF a AND b;
				RUN;
				%LET new_table_list = &new_table_list new_table&&word&i;
 				)

				);
%END;


%PUT &new_table_list;


    proc format;
         value seg
           1 = 'BROKER'
           2 = 'CMB'
           3 = 'PRIVATE'
           4 = 'PREMIER'
           5 = 'STAFF'
           6 = 'MASS'
           ;
           QUIT;      



DATA &out_lib..&out_table;
	SET &new_table_list;

%IF %UPCASE(&deposit_only)=YES %THEN %DO;      if pd_cls_id in ('@MD','@ML','@RP','@TG','CHK','SAV','SEC','TDT','INV');	  %END;
		/* this is redundant if we have a clause with product codes in it	*/

	FORMAT province $2.;
   if substr(left(upcase(pos_cd)),1,1) in ('T') then province='AB'; else
   if substr(left(upcase(pos_cd)),1,1) in ('V') then province='BC'; else
   if substr(left(upcase(pos_cd)),1,1) in ('R') then province='MB'; else
   if substr(left(upcase(pos_cd)),1,1) in ('E') then province='NB'; else
   if substr(left(upcase(pos_cd)),1,1) in ('A') then province='NL'; else
   if substr(left(upcase(pos_cd)),1,1) in ('B') then province='NS'; else
   if substr(left(upcase(pos_cd)),1,1) in ('X') then province='NT'; else
   if substr(left(upcase(pos_cd)),1,1) in ('X') then province='NU'; else
   if substr(left(upcase(pos_cd)),1,1) in ('C') then province='PE'; else
   if substr(left(upcase(pos_cd)),1,1) in ('S') then province='SK'; else
   if substr(left(upcase(pos_cd)),1,1) in ('Y') then province='YT'; else
   if substr(left(upcase(pos_cd)),1,1) in ('G','H','J') then province='QC'; else
   if substr(left(upcase(pos_cd)),1,1) in ('K','L','M','N','P') then province='ON';
   ELSE IF pos_cd ne '' THEN province='ZC';
   ELSE province='ZM';
   
   series_date=INTNX('MONTH',snap_dt, 0, 'END'); 
   direct_bank=(br_idkey='HCAHKBC850');
   comm_ind  = (Class_TP='N');
   acc_active = (AC_STUS_ID = 1);
   cust_active = (CUST_AC_STUS_ID = 1);
   broker=(br_idkey in ('HCAHKBC049','HCAHKBC069','HCAHKBC089','HCAHKBC841'));
   staff_ind = ((class in ('STS','STF','STJ')) or (client_in = 'S'));
   comm_ind  = (Class_TP='N');
   adcomm_ind = (PD_ID in (162,164,166,174));  
    if broker =1 then hca_seg = 1; /* Broker */
        else if broker = 0 and comm_ind  = 1 then hca_seg = 2; /*'CMB'*/
    else if broker = 0 and comm_ind  = 0 and Private=1 and Premier=1 and staff_ind = 0 then hca_seg = 3; /*'Private'*/
    else if broker = 0 and comm_ind  = 0 and Private=1 and Premier=0 and staff_ind = 0 then hca_seg = 3; /*'Private'*/
    else if broker = 0 and comm_ind  = 0 and Private=0 and Premier=1 and staff_ind = 0 then hca_seg = 4; /* 'Premier' */
    else if broker = 0 and comm_ind  = 0 and Private=0 and Premier=0 and staff_ind = 1 then hca_seg = 5; /* 'Staff' */
    else hca_seg = 6; /*'Mass' */
     
    hca_segdesc =  PUT(hca_seg,seg.); 
    if BR_IDKEY='' then br_id_missing=1; else br_id_missing=0;

     m = month(intnx('month',snap_dt, 0, 'end'));
     y = year(intnx('month',snap_dt, 0, 'end'));
     ym= intnx('month',snap_dt, 0, 'begin');
     begm = intnx ('month',snap_dt,0, 'begin');
     endm = intnx ('month',snap_dt, 0, 'end');
     mth = trim(left(put(m, z2.)));
     yr= trim(left(y));
     score_dt= trim(left(put(ym, yymmn6.)));
     time=trim(left(put(ym, yymmn6.)));
     beg_mth=trim(left(put(begm, date9.)));
     end_mth=trim(left(put(endm, date9.)));
  RUN;

/*  else if broker = 0 and comm_ind  = 0 and adcomm_ind = 1 then hca_seg = 2; */ /*'CMB'*/



/**************************************/
/***** compile branch region name *****/

libname branch '/camidata/SAS_DWH/tools';

%LET in_lib=branch;

ODS OUTPUT MEMBERS=mem;
PROC DATASETS LIBRARY=branch ; RUN; QUIT;
ODS OUTPUT close;
DATA table_names;
	SET mem (KEEP=name rename=(name=memname));
   where INDEX(upcase(memname), 'BRANCH_REGION_') >0
   AND  COMPRESS(SUBSTR(memname, 21, 1))=' ';  
	date_STRING 	= COMPRESS(SUBSTR(memname,15,6));
RUN;


proc print data=table_names; run;

DATA updated_date_table; SET table_names;
FORMAT date_string_n 8.0;
        date_string_n = date_string;
   new_min              = YEAR(&min_dt)*100+    MONTH(&min_dt);
   new_max              = YEAR(&max_dt)*100+    MONTH(&max_dt);
   keepit               = (new_min <= date_string_n <= new_max);
        IF keepit;
RUN;

%get_values(in_lib=work,in_table=table_names,var_list_name=date_names,var_name=date_string);
%PUT &date_names;

%LET new_table_list	= ;

%STRING_LOOP	(var_list=&date_names,
				ACTION_CODE=%NRSTR
				( DATA branch_region&&word&i; 	SET &in_lib..branch_region_&&word&i
				(KEEP=br_idkey region organization_unit_name branch_number );

					
					FORMAT snap_dt date9.;
					snap_dt	= INTNX('MONTH',MDY(SUBSTR("&&word&i",5,2),15,SUBSTR("&&word&i",1,4)),	0,'END');
                                        run;

   				 PROC contents DATA=branch_region&&word&i; run;;

				DATA new_table&&word&i;
                   SET branch_region&&word&i;
				RUN;
				%LET new_table_list = &new_table_list new_table&&word&i;
 				)

				);


%PUT &new_table_list;

/*********************************/
/*** Region Change since Oct08 ***/
/*********************************/
DATA all_regions;
	SET &new_table_list;
run;

data old_region; set all_regions; if snap_dt <'31OCT2008'd; run;

data new_region; set all_regions; if snap_dt>='31OCT2008'd;
z_region=region;
if upcase(region)='WESTERN' then z_region='Z_WESTERN';
else if upcase(region)='EASTERN' then z_region='Z_EASTERN';
else if upcase(region)='NON BRANCH' then z_region='Z_NON BRANCH';
else if upcase(region)='DIRECT BANK' then z_region='Z_DIRECT BANK';
if br_idkey='' then delete;
snap_dt_br=put(snap_dt, date9.)||br_idkey;
run;

proc sort data=new_region; by snap_dt_br z_region; run;

data new_region_sorted; set new_region;
by snap_dt_br z_region;
if first.snap_dt_br then region_keep=0;
else region_keep=1;
run;

data new_region_keep; set new_region_sorted;
if region_keep=1 or index(upcase(z_region), 'Z_')>0;
keep snap_dt br_idkey region organization_unit_name;
run;

%LET outb_lib=work;
%LET outb_table=branch_region;

DATA &outb_lib..&outb_table;
SET old_region new_region_keep;
run;

/* combine account level data with branch region info */

proc sort data=&outb_lib..&outb_table nodupkey; by DESCENDING snap_dt BR_IDKEY; run;

proc sort data=&outb_lib..&outb_table; by snap_dt BR_IDKEY; run;
proc sort data=&out_lib..&out_table; by snap_dt BR_IDKEY; run;

data &out_lib..&out_table;
merge &out_lib..&out_table(in=a) &outb_lib..&outb_table(in=b);
by snap_dt BR_IDKEY;
if a;
if region='' then region_missing=1; else region_missing=0;
if organization_unit_name='' then branch_missing=1; else branch_missing=0;

if region='' then region='Z MISSING REGION NAME';
if organization_unit_name='' then organization_unit_name ='Z MISSING BRANCH NAME';
run;


/* combine PD_NM from product dataset */

proc sort data=&out_lib..&out_table;by PD_ID;run;
proc sort data = tools.products out=products(keep = PD_ID PD_NM PRODUCT_NAME_2ND_LANGUAGE PD_CODE);by PD_ID;run;

data &out_lib..&out_table;
merge &out_lib..&out_table(in = A) products(in = B);
by PD_ID;
if A;
run;     

ODS LISTING ;
%MEND month_compile_hbca;





