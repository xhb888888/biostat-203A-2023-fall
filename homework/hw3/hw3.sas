libname hw3 "~/Biostat203A/Homework/Homework3";
run;

PROC IMPORT OUT= hw3.xxx
DATAFILE= "/home/u63620636/Biostat203A/Homework/Homework3/MDFACW02_d1.csv"
DBMS=CSV REPLACE;
GETNAMES=YES;
DATAROW=2;
RUN;

data hw3.MDFACW2 (label="MDFACW02 data");
infile "/home/u63620636/Biostat203A/Homework/Homework2/MDFACW02_d1.csv" DSD firstobs=2;
informat orauid $10.;
informat bdate MMDDYY10. sex $1. educ 3.;
informat hiredate MMDDYY10. termdate MMDDYY10. ddate MMDDYY10. icda8 $10. autopsy $1. dsex $1. drace $2. ;
informat dcity $50. dstate $10. dcounty $20. race $2. dmvflag $2. dmvdate MMDDYY7. ;
informat cvs $1. ssa861 $1. dla MMDDYY8. ; 
informat seq_no 4. ;
format orauid $10.;
format bdate MMDDYY10. sex $1. educ 3.;
format hiredate MMDDYY10. termdate MMDDYY10. ddate MMDDYY10. icda8 $10. autopsy $1. dsex $1. drace $2. ;
format dcity $50. dcounty $20. race $2. dmvflag $2. dmvdate MMDDYY10. ;
format cvs $1. ssa861 $1. dla MMDDYY10. ; 
format seq_no 4. ;
input orauid $ bdate $ sex $ educ $ hiredate $ termdate $ ddate $ icda8 $ autopsy $ dsex $ drace $ 
     dcity $ dstate $ dcounty $ race $ dmvflag $ dmvdate $ cvs $ ssa861 $ dla $ seq_no ;
label autopsy = "Autopsy"
      seq_no = "Sequence Number of Row"
      bdate = "Date of birth"
      cvs = "Vital status EOS 1983"
      dcity = "The city of death."
      dcounty = "The county of death"
      ddate = "Date of death."
      dla = "Date last alive."
      dmvdate = "Activity date returned by DMV."
      dmvflag = "Submitted to Ohio DMV in 1988."
      drace = "Race on death certificate."
      dsex = "Sex on death certificate."
      dstate = "The state of death."
      educ = "Education"
      hiredate = "hiredate"
      icda8 = "Cause of death - ICDA 8th revision."
      orauid = "Oak Ridge assigned id number."
      race = "Race of worker."
      sex = "Sex"
      ssa861 = "Results of a 1986 SSA submission."
      termdate = "Date of last termination from Mound.";
run;

/*exercise */
Data hw3.MDFACW2age;
 set hw3.MDFACW2;
 age_hire = (hiredate-bdate)/365 ;
 age_dth = (ddate-bdate)/365;
 difference_hire = termdate-hiredate;
run;

/*a) */
Proc sgplot data= hw3.MDFACW2age;
 histogram age_hire;
 histogram age_dth;
run;

Proc sgplot data= hw3.MDFACW2age;
 vbox age_hire;
run;
Proc sgplot data= hw3.MDFACW2age;
 vbox age_dth;
run;

/*comment: */
*I prefer the box plots since box plots are able to show clear signs of outliers so 
we can be careful in dealing with these outliers for further analysis;

/*b) */
Proc means data =hw3.MDFACW2age n mean std noobs maxdec=2;
 where age_dth<15;
 var age_hire  age_dth;
run;

/*c) */
Proc means data =hw3.MDFACW2age n mean std noobs maxdec=2;
 where age_dth<15 and bdate ^= . and ddate ^= .;
 var age_hire  age_dth;
run;

/*d) */
Proc print data =hw3.MDFACW2age noobs;
 where age_hire<15 and bdate ^= . and hiredate ^= .;
 var orauid bdate sex educ hiredate termdate ddate age_hire age_dth difference_hire;
run;


/*e) */
Proc print data =hw3.MDFACW2age noobs;
 where age_hire<15 or age_hire >80 and bdate ^= . and hiredate ^= . ;
 var orauid bdate sex educ hiredate termdate ddate age_hire age_dth difference_hire;
run;

/*exercise 2 */

/*a) */
Proc means data =hw3.MDFACW2age n noobs maxdec=2;
where hiredate - termdate >0 ;
var age_hire age_dth;
run;


Proc print data =hw3.MDFACW2age;
where hiredate - termdate  >0;
var orauid bdate hiredate termdate ddate age_hire age_dth difference_hire;
run;

/*b) */
data hw3.MDFACW2hireflag;
set hw3.MDFACW2age;
/*defining the date below: input is the function for converting character into numeric*/
date09151999='09/15/1999';
date09151999n=input(date09151999,MMDDYY10.);
diff_date= hiredate- date09151999n;
drop date09151999;
rename date09151999n= date0915199;
run;

Proc print data =hw3.MDFACW2hireflag;
where diff_date = 0;
var orauid hiredate age_hire age_dth diff_date;
run;

Proc means data =hw3.MDFACW2hireflag n noobs maxdec=2;
where diff_date = 0;
var age_hire age_dth;
run;

Proc print data =hw3.MDFACW2hireflag;
where diff_date = 0;
var orauid bdate hiredate termdate ddate age_hire diff_date;
run;

/*c)*/
Proc print data =hw3.MDFACW2age;
where age_dth  <0 and age_dth ^= .;
var orauid bdate hiredate termdate ddate age_hire age_dth difference_hire;
run;

Proc print data =hw3.MDFACW2hireflag;
where diff_date = 0;
var orauid hiredate age_hire age_dth diff_date;
run;
*Only one is included;

Proc means data =hw3.MDFACW2hireflag n noobs maxdec=2;
where age_dth  <0 and age_dth ^= .;
var age_hire age_dth;
run;

Proc print data =hw3.MDFACW2hireflag;
where age_dth  <0 and age_dth ^= .;
var orauid bdate hiredate termdate ddate age_hire diff_date;
run;

/*d)*/
Proc print data =hw3.MDFACW2hireflag;
where bdate =input('07/01/1999',mmddyy10.);
var orauid bdate hiredate termdate ddate age_hire diff_date;
run;

Proc means data =hw3.MDFACW2hireflag n noobs maxdec=2;
where diff_date =0 and bdate =input('07/01/1999',mmddyy10.);
var age_hire age_dth;
run;

Proc print data =hw3.MDFACW2hireflag;
where diff_date =0 and bdate =input('07/01/1999',mmddyy10.);
var orauid bdate hiredate termdate ddate age_hire diff_date;
run;

