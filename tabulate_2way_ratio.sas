%macro tabulate_2way_ratio(in_lib=work, in_table=,class1=,class2=,numer=,denom=,class1_label=,out_lib=work, 
	out_table=test_out);
ods listing close;
/*
PROC FORMAT;
PICTURE T2EST (round) 
low-<0 ='00099' (Prefix='negative   ')
0-<100 ='00099%'
100-high ='00999%' (Prefix ='over100%  ');
run;*/
PROC FORMAT;
PICTURE pctfmt low-high='009.00 %';
run;
ods listing;	
proc tabulate data = &in_lib..&in_table missing order=INTERNAL OUT=&out_lib..&out_table;
	VAR &numer &denom;
	CLASS &class1 &class2;
	FORMAT &class1 &&&class1... &class2 &&&class2...;
	TABLE (&class1 =' ' all), (&class2= '' all)
	* &numer=' '*pctsum<&denom>=' '*f=pctfmt. /rts=30 row=float BOX="&class1_label" 
	MISSTEXT='';
	TITLE ''; 
QUIT;
%mend tabulate_2way_ratio;
