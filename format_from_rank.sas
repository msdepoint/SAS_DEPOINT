%MACRO format_from_rank(in_table,ranked_var,format_label,in_lib=work, groups=10,wgt=);
/********************************************************************************/	
/*	THIS MACRO takes the IN_TABLE, ranks it by the RANKED_VAR into GROUPS	*/
/*	THEN, it creates a FORMAT from those rankings				*/
/*	DEPOINT CHIN, RISCHALL APR2003, DePoint oct2003				*/
/********************************************************************************/	
%IF (%LENGTH(&WGT)=0) %THEN %GOTO NON_WGT_METHOD; 
%ELSE %GOTO WGT_METHOD;

%NON_WGT_METHOD:
PROC RANK DATA=&in_lib..&in_table GROUPS=&groups out=RANK_OUT;
	VAR &ranked_var;
    RANKS RANK1; 
proc means data=RANK_OUT maxdec=0 NOPRINT;
	class RANK1;
	var &ranked_var;
	output out=to_ctrl(drop=_freq_ rank1)
			MIN(&ranked_VAR) 	= START
			MAX(&ranked_VAR) 	= END
			;
run;
data to_ctrl;
	set to_ctrl;
	where _type_=1;
	drop	 _type_;
run;
%GOTO FINAL_FORMAT_OUTPUT;
/****************************************************************************/

%WGT_METHOD:
/****************************************************************************************************************/
/* This format creation macro is based upon the lift chart macro created by */
/* WEIGHTED LIFT CHART MACRO (UNIT INCIDENCE)									*/
/* I.Rischall ; A.Chin  29APR2003										*/
/*														*/
/* 	Macro Inputs:												*/
/*		in_lib 		= Input Library									*/
/*		in_table 	= Input Table									*/
/*		ranked_var 		= Ranking Score									*/
/*		wgt		= Weight Variable								*/
/* format_label = macro variable label for the format created*/
/* 		groups		= Number of Bins (e.g., 10 = deciles, 20 = twentiles, etc.)			*/
/****************************************************************************************************************/
data step_pre; set &in_lib..&in_table;
run;
proc sort data = step_pre (where = (&ranked_var ne .)) out = step1;
  by &ranked_var;
run;
data step2;
   set step1 end = last;
   retain cumulative 0;
   cumulative + &wgt;
   if last then do;
      call symput('totpop',left(cumulative));
   end;
run;
data step3 (keep = &ranked_var bin percentile);
	set step2;
	by  &ranked_var;
	percentile=((cumulative/&totpop)*100);

	do i = 1 to &groups;
	if percentile > (i-1)*100/&groups
	& percentile le i*100/&groups then bin=i;
	end;
	if percentile > 100 and bin = . then bin = &groups;
	if last.&ranked_var;
run;
data step4;
	merge step3 step2;
	by &ranked_var;
run;
proc report data = step4 nowindows headline headskip missing out = to_ctrl;
	column 	
  		bin
		&ranked_var = START
		&ranked_var = END
		;
	weight &wgt;
	define bin / group format=2. width=9 'Score Bin' noprint;
	define START / analysis min format=6.0  width = 9 'Minimum ' noprint;
	define END / analysis max format=6.0 width = 9 'Maximum ' noprint;
run;
proc sort data=to_ctrl; by bin;
%GOTO FINAL_FORMAT_OUTPUT;
/****************************************************************************/

%FINAL_FORMAT_OUTPUT:
  %global &format_label;
  %let &FORMAT_LABEL=;
  %let &FORMAT_label = %SUBSTR(&ranked_var,1,7);

  data ctrl;
     set to_ctrl(keep = start end) end=last;
     retain fmtname "&&&FORMAT_label" type 'n';
     if last then hlo='h';
     else hlo =' ';
     format label $80.;
     /*if start >=10 then*/ label = compress('*'||START||' - '||END);
   run;

proc format library=work cntlin=ctrl;
/*proc format library=work fmtlib;*/
proc print data=ctrl noobs;
title "format for &in_table based upon &ranked_var with &groups breaks &WGT";
run;
%MEND format_from_rank;

