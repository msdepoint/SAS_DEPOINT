/********************************************************************************/
/* Program - oralog.sas                                                         */
/* Description - Verify the Oracle login for the user                           */
/* Author - Zacharia Mathew                                                     */
/* Created on - Tue May 16 14:30:33 CDT 2006                                    */
/*                                                                              */
/* Assumptions - The macro variables uscode, pwcode and server should be        */
/*               defined in ~/orpw.sas (suggested) and included                 */
/*               (in autoexec.sas) or defined elsewhere separately.             */
/*                                                                              */
/* Description - If the user name is blank then the macro puts a warning in the */
/*               SAS log. This program works if macro variables in ~/orpw.sas,  */
/*               are wrapped with single quotes, double quotes or or none. This */
/*               program uses local macro variables for testing connection to   */
/*               avoid any modification of global macro variables. This program */
/*               uses the macro qResil for separate text wrapping and checks    */
/*               for blank password and blank server name.                      */
/*                                                                              */
/* Acknowledgements -                                                           */
/* Matthew Carney - Suggestion to check user Oracle password expiration date    */
/* Barry Crane @ Acxiom - Provided the field and table in the Oracle database   */
/*                        to check for the user's Oracle password expiration    */
/*                        date                                                  */
/*                                                                              */
/* Modifications -                                                              */
/* Zacharia Mathew - Mon Jul  3 15:30:27 CDT 2006                               */
/* Added check of oracle login password expiry date.                            */ 
/* Zacharia Mathew - Wed Aug 16 15:06:33 CDT 2006                               */
/* Check if account status is expired(grace) before checking the expiry date of */
/* oracle password.                                                             */
/* Zacharia Mathew - Tue Aug 29 16:39:39 CDT 2006                               */
/* Avoid stopping the sas session if the oracle database is not reachable.      */
/* This will allow users to function with an error message during backups. When */
/* the database is down your account will not be locked but multiple calls.     */
/* Added Brutus along with Oracle on the error / warning messages.              */
/*                                                                              */
/********************************************************************************/


%macro oralog;

  /* If the user name is blank then issue warning in the log */
  %if &uscode. eq or &uscode. eq '' or &uscode. eq "" %then %do;
     %put "WARNING: You have a blank Oracle (Brutus) login name";
  %end;
  %else %if &pwcode. eq or &pwcode. eq '' or &pwcode. eq "" %then %do;
     %put "ERROR: You have a blank Oracle (Brutus) password";
  %end;
  %else %if &server. eq or &server. eq '' or &server. eq "" %then %do;
     %put "ERROR: You have a blank Oracle (Brutus) server name";
  %end;  
  %else %do;

    /*Connection macro variables*/
    %let luscode =&uscode.;
    %let lpwcode =&pwcode.;
    %let lserver =&server.;
    
    /*DB messages*/
    %let dbdown1=ORACLE: ORA-12541: TNS:NO LISTENER;
    %let dbdown2=ORACLE: ORA-03113: END-OF-FILE ON COMMUNICATION CHANNEL;
    %let dbdown3=ORACLE: ORA-01034: ORACLE NOT AVAILABLE;
    %let srvwrong=ORACLE: ORA-12154: TNS:COULD NOT RESOLVE SERVICE NAME;
    %let pswdgrc=EXPIRED(GRACE);

    /* If user name is not quoted with single or double quotes then wrap with double quotes */
    %qResil(luscode);

    /* If password is not quoted with single or double quotes then wrap with double quotes */
    %qResil(lpwcode);

    /* If server is not quoted with single or double quotes then wrap with double quotes */
    %qResil(lserver);

    libname oralib oracle user=&luscode. password=&lpwcode. path=&lserver. schema=HSBC;

    /* If Oracle Database is not reachable just issue a note to the user */ 
    /* This will avoid sas from ending when the database is down         */
    %if "%trim(%upcase(&sysdbmsg.))" eq "&dbdown1." 
     or "%trim(%upcase(&sysdbmsg.))" eq "&dbdown2." 
     or "%trim(%upcase(&sysdbmsg.))" eq "&dbdown3."
     or "%trim(%upcase(&sysdbmsg.))" eq "&srvwrong." %then %do;
      %put "NOTE: Oracle (Brutus) Database is not reachable";
      %put "sysdbmsg - &sysdbmsg. sysdbrc - &sysdbrc. syslibrc - &syslibrc.";
    %end;
    %else %if &syslibrc. eq 0 %then %do;
    
      libname orlib oracle user=&luscode. password=&lpwcode. path=&lserver.;
      
      %if &syslibrc. eq 0 %then %do;
      
        proc sql noprint;        
          select account_status 
          into :acctst
          from orlib.user_users
          ;

          select datepart(expiry_date) format=date9.
          into :expdt
          from orlib.user_users
          ;
        quit; 

        %if "%trim(&acctst.)" = "%trim(&pswdgrc.)" %then %do;

          data _null_;
            call symput('remdays', put(intck("DAY", "&sysdate9."d, "&expdt."d), 8.));
          run;

          /* If the Oracle password expires in 2 days then dont run SAS */
          %if %eval(&remdays. <= 2) %then %do;
            %put "ERROR: Your Oracle (Brutus) password will expire on &expdt.. Please change it and update orpw.sas before you run SAS.";
            endsas;
          %end; 
          /* If the Oracle password expires in 10 days then issue warning */
          %else %if %eval(&remdays. <= 10) %then %do;
            %put "ERROR: Your Oracle (Brutus) password will expire on &expdt.. Please change it and update orpw.sas.";
          %end; 
        %end;
      %end;            
    %end;                  
    /* If Oracle login name password combination is wrong then dont run SAS */
    %else %do;
      %put "ERROR: Oracle (Brutus) login is invalid";
      %put "sysdbmsg - &sysdbmsg. sysdbrc - &sysdbrc. syslibrc - &syslibrc.";
      endsas;
    %end;
  %end;

%mend oralog;
