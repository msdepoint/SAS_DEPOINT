%macro rand_sam_rep(in_lib,in_table,out_lib,out_table,sampsize,seed);
/************************************************************************/
/* A.Chin 23SEP2002  modified DePoint April 2004                                                    */
/* This MACRO allows for random sampling with replacement               */
/* must specify sample size less than population size                   */
/************************************************************************/

data &out_lib..&out_table(drop=i);
	sampsize = &sampsize;
	if sampsize not >= totobs then do i = 1 to sampsize;
		pickit = ceil(ranuni(&seed)*totobs);
		set &in_lib..&in_table point=pickit nobs=totobs;
		output;
	end;
	stop;
run;
%mend rand_sam_rep;
