/********************************************************************************/
/* SAS2XSVH.SAS - SAS macro that converts a SAS datasets into Delimited ASCII   */
/*               file.                                                          */
/* This macro is based on original work by Ian Whitlock.                        */ 
/* Based on an original concept and with fine tuning by Jay Jacob Wind          */ 
/* copyright 1994. You may use this macro and pass it to others freely.         */ 
/*                                                                              */ 
/* Modifications / Enhancements                                                 */ 
/* Mon Oct 30 09:30:10 EST 1995 - George Chalissery                             */
/* Fri Jan 10 12:02:26 EST 1997 - George Chalissery (xfer from SASTO123)        */
/* Thu Feb 24 12:11:07 EST 2000 - George Chalissery rewrite to fix order        */
/*                                and output ,, for missing values.             */
/* Tue Aug 22 13:41:10 EDT 2000 - George Chalissery fix duplicate labels.       */
/* Thu Jan 11 12:50:00 EDT 2001 - Marty Porter - fix length of labels, quoting. */
/* Thu Mar 28 12:54:00 EDT 2001 - Marty Porter - fix quoting of labels.         */
/*                                                                              */ 
/* Fri Dec 22 10:10:40 CST 2006 - Zacharia Mathew - Added datetime variable     */
/*                                formatting and avoided other                  */ 
/*                                macro dependancies                            */
/*                                                                              */
/* Syntax:                                                                      */
/*   %sas2xsvh(ds, file, delimiter)                                             */
/*   ds        - name of the input sas dataset to be converted to an ASCII file */
/*   file      - name of the output Delimited ASCII file.                       */
/*   delimiter - character to use as delimiter, comma by default. Delimiter     */ 
/*               should be wrapped in single or double quotes (eg: "," , '|').  */
/*               Hexadecimal delimiters can be used as '09'x or "09"x           */
/*                                                                              */
/* Avoid data set variables beginning with double underscore                    */
/* in particular __nums __chars __name __i __out                                */
/*                                                                              */
/* Numeric variables will be written after string variables.                    */
/* Date variables are written out as numbers in mm/dd/yyyy format               */
/*                                                                              */
/********************************************************************************/

%macro sas2xsvh(data, out, comma);

/*Strip the double quotes and single quotes in the delimiter argument */
%let comma=%left(%trim(%bquote(&comma.)));

/*Define default delimiter comma */
%if &comma. = %then %do;
  %let comma=',';
  %let commasq=',';
%end;
%else %if %length(%bquote(&comma.)) ge 3 %then %do;
  /* Use double quotes instead of single quotes in the macro variable commasq */
  %if (%bquote("%qsubstr(%bquote(&comma.), 1, 1)") eq %bquote("'")
      and %bquote("%qsubstr(%bquote(&comma.), %length(%bquote(&comma.)), 1)")
      eq %bquote("'")) 
  or
  (%bquote('%qsubstr(%bquote(&comma.), 1, 1)') eq %bquote('"')
    and %bquote('%qsubstr(%bquote(&comma.), %length(%bquote(&comma.)), 1)') 
    eq %bquote('"'))
  %then %do;
    %let commasq=%bquote('%qsubstr(%bquote(&comma.), 2, %length(%bquote(&comma.)) - 2)');
  %end;
  /* If hexadecimal delimiters are used */
  %else %if %length(%bquote(&comma.)) ge 4 
              and ((%bquote(%qsubstr(%bquote(&comma.), 1, 1)) eq %bquote('"')
                and %bquote(%qsubstr(%bquote(&comma.), %length(%bquote(&comma.)) - 1, 1))
                 eq %bquote('"')) 
                or (%bquote("%qsubstr(%bquote(&comma.), 1, 1)") eq %bquote("'")
                and %bquote("%qsubstr(%bquote(&comma.), %length(%bquote(&comma.)) - 1, 1)")
                 eq %bquote("'")))
               and (%bquote("%upcase(%qsubstr(%bquote(&comma.), %length(%bquote(&comma.)), 1)")) 
                 eq %bquote("X") %then %do;
    %let commasq=%bquote('%qsubstr(%bquote(&comma.), 2, %length(%bquote(&comma.)) - 3)'X);
  %end;
%end;

%local i __ntvar nosrc2 obs notes missing;
%local _work;

%let nosrc2=%sysfunc(getoption(source2)); * save current setting;
%let obs=%sysfunc(getoption(obs)); * save current setting;
%let notes=%sysfunc(getoption(notes)); * save current setting;
%let missing=%sysfunc(getoption(missing)); * save current setting;

options obs=max;
options nonotes nosource2;

/* datastep to make the SASTEMP work data directory pathname available */
data _null_;
  length datadir $512;
  datadir = left(trim(pathname('work')));
  call symput("_work", trim(datadir));
run;

proc contents data=&data noprint out=__conte;
run;

data _null_;
  set __conte nobs=ntvar;
  call symput ("__ntvar", left(put(ntvar,5.)));
  call symput ("__lname", left(trim(libname)));
  call symput ("__mname", left(trim(memname)));
  stop;
run;

data __conte;
  set __conte end=eof;
  output;
  if eof then do; * To ensure that the format gets created;
    name = "9999999"; * Invalid name;
    label = repeat("0123456789", 20); * Invalid name :-);
    output;
    name = "8888888"; * Invalid name;
    label = repeat("0123456789", 20); * Invalid name :-);
    output;
  end;
run;

proc sort data=__conte;
  where label ne "";
  by label name;
run;

data __conte;
  length label $256;
  set __conte(keep=label name) end=eof;
  by label;
  
  retain suffix 0 fmtname '$__s2c' type 'c';

  if not (first.label and last.label);
  
  if first.label then
    suffix = 0;
  suffix = suffix + 1;
  label = left(trim(left(trim(label)) || "_" || put(suffix,z3.)));
  
  output;
  keep label name fmtname type;
  rename name=start;
run;

proc format library=work cntlin=__conte;
run;

proc datasets nolist lib=work;
  delete __conte;
run;

/* Write delimited data into file */
data _null_;
  file "&_work./sas2xsv&sysjobid..tmp" notitles noprint lrecl=256 recfm=v;
  length varname varfmt $50.;
  __dsid = open ("&data");
  call set (__dsid);
  do i = 1 to &__ntvar;
    varname = varname(__dsid, i);
    varfmt = left(varfmt(__dsid, i));
    if substr(varfmt, 1, 6) in ('YYMMDD', 'YYDDMM', 'MMDDYY', 'MMYYDD',
                                'DDYYMM', 'DDMMYY', 'JULIAN', 'DATE9.',
                                'DATE7.'
                                ) then do;
      put "if " varname " ne . then put " varname " date9. @;";
      if i ne &__ntvar then
        put "put &commasq. @;";
      else
        put "put '0D'x;";
    end;
    else if substr(varfmt, 1, 8) in ('DATETIME') then do;
      put "if " varname " ne . then put " varname " datetime20. @;";
      if i ne &__ntvar then
        put "put &commasq. @;";
      else
        put "put '0D'x;";
    end;    
    else if vartype(__dsid, i) = "C" then do;
      put varname " = translate(" varname ', "' "'" '", ' "'" '"' "');";
      put 'put "" @;';
      put 'if ' varname ' ne "" then put ' varname ' @;';
      put 'put +(-1) "" @;';
      put "if " varname " = '' then put +(-1) @;";
      if i ne &__ntvar then
        put "put &commasq. @;";
      else
        put "put '0D'x;";
    end;
    else if vartype(__dsid, i) = "N" then do;
      put "if " varname " ne . then put " varname " @;";
      put "if " varname " = . then put ' ' @;";
      if i ne &__ntvar then
        put "put +(-1) &commasq. @;";
      else
        put "put +(-1) '0D'x;";
    end;
    if length(varfmt) < 6  and _error_ = 1 then
      _error_ = 0;
  end;
  __dsid = close (__dsid);
run;

options notes;
run;

/* Write Variable Names as File Header */
data _null_;
  set &data.;
  length __varnam __varlab $200.;
  file "&out" notitles noprint lrecl=65536 recfm=V;
  format _numeric_;
  if _n_ = 1 then do;
    __dsid = open ("&data");
    do __i = 1 to &__ntvar;
      __varnam = varname(__dsid, __i);
      if put(__varnam, $__s2c.) ne __varnam then
        __varlab = put(__varnam, $__s2c.);
      else 
        __varlab = varlabel(__dsid, __i);
      __varlab = translate ( __varlab, "'", '"');
      if __varlab = '' then 
        __varlab = quote(trim(left(__varnam)));  
      else
        __varlab = quote(trim(left(__varlab)));
      put __varlab @;
      if __i ne &__ntvar then
        put +(-1) &comma. @;
      else
        put +(-1) '0D'x;
    end;
    __dsid = close (__dsid);
  end;

  %include "&_work./sas2xsv&sysjobid..tmp";
run;

data _null_;
  if fileexist("&_work./sas2xsv&sysjobid..tmp") then
    call system ("rm -rf &_work./sas2xsv&sysjobid..tmp");
run;

options &notes; * restore original settings;
options missing="&missing"; * restore original settings;
options obs=&obs; * restore original settings;
options &nosrc2; * restore original settings;

%mend sas2xsvh;
