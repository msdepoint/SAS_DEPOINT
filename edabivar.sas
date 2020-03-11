%macro edabivar(in_lib=,in_table=,ind_var=,dep_var=,groups=20,height=67,width=100);

/* determine if dependent variable is binary */
PROC SQL;
	CREATE TABLE how_many AS
	SELECT 
	COUNT (DISTINCT &dep_var) as how_many

	FROM &in_lib..&in_table	;
QUIT;
%get_values(in_lib=work,in_table=how_many,var_list_name=num_dep_values,var_name=how_many);


proc rank data=&in_lib..&in_table out=rankout groups=&groups;
 var &ind_var;
 ranks grp_indvar;
run;

proc means data=rankout noprint;
  var &dep_var &ind_var;
  class grp_indvar;
  output out=meanout
         mean=mean_dep mean_ind min=crap1 min_ind max= crap2 max_ind;

proc sql noprint;
  select mean_ind,
         mean_dep   
into :avg_ind,
     :avg_dep
from meanout
where _type_ = 0;

proc plot data=meanout vpercent=&height hpercent=&width;
  title "Bivariate of &dep_var Rate by &ind_var";
  plot mean_dep*mean_ind / href=&avg_ind vref=&avg_dep hrefchar='.' vrefchar='.';
where _type_=1;
run;

options formdlim="-";
%IF &num_dep_values = 2 %THEN %LET dep_format = percent8.2;
%ELSE %LET dep_format = 8.2;

proc report data=rankout nowindows headline headskip missing;
  column grp_indvar &ind_var &ind_var=cut_max &ind_var = cut_av n &dep_var;
  define grp_indvar /group format=2. width=9 'Bin';
  define &ind_var / analysis min width = 9 format = 8.2 "Min &ind_var";
  define cut_max / analysis max  format = 8.2 "Max &ind_var";
  define cut_av /  analysis mean format = 8.2 "MEAN &ind_var";
  define n / format=comma9. width=9 'N';
  define &dep_var / analysis mean format = &dep_format width = 8  "MEAN &dep_var";

 rbreak after /  summarize ul ol ;
 run;

%mend edabivar;
