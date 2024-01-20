libname CEDR "~/Biostat203A/Homework/Homework2";
run;

PROC IMPORT OUT= CEDR.xxx
DATAFILE= "/home/u63620636/Biostat203A/Homework/Homework2/MDFACW02_d1.csv"
DBMS=CSV REPLACE;
GETNAMES=YES;
DATAROW=2;
RUN;

data CEDR.MDFACW (label="Working personnel file for Mound Plant");
infile "/home/u63620636/Biostat203A/Homework/Homework2/MDFACW02_d1.csv" DSD firstobs=2;
informat orauid $8. ;
informat bdate MMDDYY10. sex $1. educ $1. ;
informat hiredate MMDDYY10. termdate MMDDYY10. ddate MMDDYY10. icda8 $10. autopsy $1. dsex $1. drace $2. ;
informat dcity $50. dstate $10. dcounty $20. race $2. dmvflag $2. dmvdate MMDDYY7. ;
informat cvs $1. ssa861 $1. dla MMDDYY8. ; 
informat seq_no 4. ;
format orauid $8. ;
format bdate MMDDYY10. sex $1. educ $1. ;
format hiredate MMDDYY10. termdate MMDDYY10. ddate MMDDYY10. icda8 $10. autopsy $1. dsex $1. drace $2. ;
format dcity $50. dstate $10. dcounty $20. race $2. dmvflag $2. dmvdate MMDDYY10. ;
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

proc means data=CEDR.MDFACW ;
run;
proc print data=CEDR.MDFACW (obs=5) label;
run;

proc means data=CEDR.MDFACW n mean std median min max;
  vars ddate dla seq_no;
run;

proc format;
  value $enrfmt "1"    = "Grade school"
               "2"  = "Some high school"
               "3" = "High school graduate"
               "4" = "Associates Degree"
               "9","U" = "Unknown";
run;

proc freq data=CEDR.MDFACW;
  format educ $enrfmt.;
  tables educ / nocum;
run;

proc format;
  value $cvsfmt "A"     = "Alive"
                "D"   = "Dead"
                "U" = "Unknown";
run;

/* Next we will create our two-way frequency table using 'proc freq.' */

proc freq data = CEDR.MDFACW;
  format cvs $cvsfmt. 
         educ $enrfmt.;
  tables educ*cvs /norow nocol;
run;

data MDFACW; 
set CEDR.MDFACW;
age = intck('YEAR', bdate, hiredate);
run;

proc means data = WORK.MDFACW n mean std median min max nonobs maxdec = 3;
  var age;
  format educ $enrfmt.;
  class educ;
run;

proc format;
	value $autopsyformat ''="Not applicable" 0="No autopsy" 1="Autopsy performed" 'U' = "Unknown";
	value $cvsformat 'A'="Alive" 'D'="Dead" "U"="Unknown";
	value $dmvflagformat ""="Not submitted" "N"="Not found" "Y"="Found";
	value $cdraceformat ""="Not applicable" 1='Oriental' 2='Native American' 3='Black' 'U'='Unknown';
	value $cdsexformat ''='Not applicable' 0='Male' 1='Female';
	value $educformat 1='Grade school' 2='Some high school' 3='High school graduate' 4='Associates Degree'
	 5='College Graduate' 6='Advanced Degree' 9='Unknown' 'U'='Unknown';
	value $craceformat ''='Unknown' 0='white' 2='Other' 3='Black';
	value $csexformat 0='Male' 1='Female' 9='Unknown';
	value $cssaformat ''='Not submitted' 'A'='Alive' 'D'='Dead' 
	'I'='Impossible SSN' 'N'='Non-match' 'U'='Unknown' 'X'='Duplicate';
	 
run;
 
data CEDR.MDFACW2 (label="Question 6");
infile "/home/u63620636/Biostat203A/Homework/Homework2/MDFACW02_d1.csv" DSD firstobs=2;
informat orauid $10.;
informat bdate MMDDYY10. sex $1. educ 3.;
informat hiredate MMDDYY10. termdate MMDDYY10. ddate MMDDYY10. icda8 $10. autopsy $1. dsex $1. drace $2. ;
informat dcity $50. dstate $10. dcounty $20. race $2. dmvflag $2. dmvdate MMDDYY7. ;
informat cvs $1. ssa861 $1. dla MMDDYY8. ; 
informat seq_no 4. ;

format orauid $10.;
format bdate MMDDYY10. sex $csexformat. educ $educformat.;
format hiredate MMDDYY10. termdate MMDDYY10. ddate MMDDYY10. icda8 $10. autopsy $autopsyformat.; 
format dsex $cdsexformat. drace $cdraceformat. ;
format dcity $50. dcounty $20. race $craceformat. dmvflag $dmvflagformat. dmvdate MMDDYY10. ;
format cvs $cvsformat. ssa861 $cssaformat. dla MMDDYY10. ; 
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

proc contents data=CEDR.MDFACW2 order=varnum ;
run;








