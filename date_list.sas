/***************all monthends******************/
%LET month_end_dates=
('31-Jan-05'd,
'28-Feb-05'd,
'31-Mar-05'd,
'29-Apr-05'd,
'31-May-05'd,
'30-Jun-05'd,
'29-Jul-05'd,
'31-Aug-05'd,
'30-Sep-05'd,
'31-Oct-05'd,
'30-Nov-05'd,
'30-Dec-05'd,
'31-Jan-06'd,
'28-Feb-06'd,
'31-Mar-06'd,
'28-Apr-06'd,
'31-May-06'd,
'30-Jun-06'd,
'31-Jul-06'd,
'31-Aug-06'd,
'29-Sep-06'd,
'31-Oct-06'd,
'30-Nov-06'd,
'29-Dec-06'd,
'31-Jan-07'd,
'28-Feb-07'd,
'30-Mar-07'd,
'30-Apr-07'd,
'31-May-07'd,
'29-Jun-07'd,
'31-Jul-07'd,
'31-Aug-07'd,
'28-Sep-07'd,
'31-Oct-07'd,
'30-Nov-07'd,
'31-Dec-07'd,
'31-Jan-08'd,
'29-Feb-08'd,
'31-Mar-08'd.
'30-Apr-08'd,
'30-May-08'd,
'30-Jun-08'd,
'31-Jul-08'd,
'29-Aug-08'd,
'30-Sep-08'd,
'31-Oct-08'd,
'28-Nov-08'd,
'31-Dec-08'd,
'30-Jan-09'd,
'27-Feb-09'd,
'31-Mar-09'd,
'30-Apr-09'd,
'29-May-09'd,
'30-Jun-09'd,
'31-Jul-09'd,
'31-Aug-09'd,
'30-Sep-09'd,
'30-Oct-09'd,
'30-Nov-09'd,
'31-Dec-09'd,
'29-Jan-10'd,
'26-Feb-10'd,
'31-Mar-10'd,
'30-Apr-10'd,
'31-May-10'd,
'30-Jun-10'd,
'30-Jul-10'd,
'31-Aug-10'd,
'30-Sep-10'd,
'29-Oct-10'd,
'30-Nov-10'd,
'31-Dec-10'd,
'31-Jan-11'd,
'28-Feb-11'd,
'31-Mar-11'd,
'29-Apr-11'd,
'31-May-11'd,
'30-Jun-11'd,
'29-Jul-11'd,
'31-Aug-11'd,
'30-Sep-11'd,
'31-Oct-11'd,
'30-Nov-11'd,
'30-Dec-11'd
);

 /**************monthends that are not fridays*************/
%LET date_exclude_list=
('31-Jan-05'd,
'28-Feb-05'd,
'31-Mar-05'd,
'31-May-05'd,
'30-Jun-05'd,
'31-Aug-05'd,
'31-Oct-05'd,
'30-Nov-05'd,
'31-Jan-06'd,
'28-Feb-06'd,
'31-May-06'd,
'31-Jul-06'd,
'31-Aug-06'd,
'31-Oct-06'd,
'30-Nov-06'd,
'31-Jan-07'd,
'28-Feb-07'd,
'30-Apr-07'd,
'31-May-07'd,
'31-Jul-07'd,
'31-Oct-07'd,
'31-Dec-07'd,
'31-Jan-08'd,
'31-Mar-08'd,
'30-Apr-08'd,
'30-Jun-08'd,
'31-Jul-08'd,
'30-Sep-08'd,
'31-Dec-08'd,
'31-Mar-09'd,
'30-Apr-09'd,
'30-Jun-09'd,
'31-Aug-09'd,
'30-Sep-09'd,
'30-Nov-09'd,
'31-Dec-09'd,
'31-Mar-10'd,
'31-May-10'd,
'30-Jun-10'd,
'31-Aug-10'd,
'30-Sep-10'd,
'30-Nov-10'd,
'31-Jan-11'd,
'28-Feb-11'd,
'31-Mar-11'd,
'31-May-11'd,
'30-Jun-11'd,
'31-Aug-11'd,
'31-Oct-11'd,
'30-Nov-11'd
);

