/*MACRO : init_user_orpw.sas*/
/*Determine active user and initialize Oracle login data */
%macro init_user_orpw;
filename usnm pipe 'echo $USER';
options symbolgen=no;
options mprint=no;

%global uscode;
%global pwcode;
%global server;



data username;
infile usnm;
input usnm $ ;
run;

proc sql;
select usnm into :user
from username;

proc delete data = username;
 run;


%let user = %trim(&user);

%include "/s01/home/&user/orpw.sas";
%put Oracle User info initialized for user &user.;


%mend init_user_orpw;

