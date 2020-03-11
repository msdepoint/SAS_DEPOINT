%macro split_up (in_lib,in_table,devset,valset,percent,out_lib=work,seed=0);
*This macro splits a dataset into a validation and development data set;
    DATA &out_lib..&devset &out_lib..&valset; 
       set &in_lib..&in_table;
	   flag = (ranuni(&seed) <=&percent);
	if (flag) then output &out_lib..&devset;
	else output &out_lib..&valset;
	run;
%mend split_up;
