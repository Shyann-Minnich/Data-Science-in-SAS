libname download 'C:\Users\Shyann\Downloads'; run;

data school_enrollment;
set download.school_enroll_panel_1990_2004;
run;

proc import datafile = "C:\Users\Shyann\Downloads\Join_Cousub_Target_Schools"
out = cousub dbms = xlsx replace; 
run;

*Taking the last 5 characters in geoid to compare it; 
data cousub;
set cousub;
Geoid_substring = substr(geoid, 6, 10);
run;

data cousub;
set cousub;
nomatch_geo_cousub = compare(COUSUBFP, geoid_substring);
run;

data cousub;
set cousub;
counter = 0;
if nomatch_geo_cousub = 1 then counter = counter + 1;
run;

*All the geoid and cousubfp matched.;

* Create a school district code then count the number of school in each district.;
data school_enrollment;
set school_enrollment;
district_code = substr(School_ID, 1, 8);
run;

data school_enroll;
set school_enrollment;
if New_Total_Enroll = . then delete;
run;

proc sort data = school_enroll; by school_id; run;

data school_enroll;
set school_enroll;
lag_district_code = lag(district_code);
run;

data school_enroll;
set school_enroll;
compare_count = compare(district_code, lag_district_code);
run;

data school;
set school_enroll;
by school_id;
if first.school_id then school_count = 0; 
school_count +1;
run;

*How many districts have the same number of school from 1990 - 2002; 

**************************
*************************
************************


*Record the number of districts.; 

proc sort data = school; by desending compare_count; run;

data school_code; 
set school; 
counter +1;
if compare_count > 0 then district_count = counter; 
run; 

*There are 19411 number of schoool districts that did report. 

*Record the number of districts that didn't report; 

proc sort data = school_e; by school_id; run;

data school_e;
set school_enrollment;
lag_district_code = lag(district_code);
run;

data school_e;
set school_e;
compare_count = compare(district_code, lag_district_code);
run;

data school_e;
set school_e;
by school_id;
if first.school_id then school_count = 0; 
school_count +1;
run;

*Record the number of districts.; 

proc sort data = school_e; by desending compare_count; run;

data school_e; 
set school_e; 
counter +1;
if compare_count > 0 then district_count = counter; 
run; 

*Total number of districts is 19666. The number of districts that did not report is 19666 - 19411 = 255; 

*Merege school enrollment data with the cousub data.; 
*There are 1297293 rows of data in the school enrollment dataset and 118262 rows of data in the cousub dataset.; 

data cousub;
set cousub;
school_id1 = input(school_id, 15.);
FIPS_State1 = input(FIPS_State, 12.);
drop school_id FIPS_State;
run;

data schools;
set school;
school_id1 = school_id;
FIPS_State1 = FIPS_State;
run;


proc sort data = schools; by school_id1; run;
proc sort data = cousub; by school_id1; run; 

data Combined_datasets;
merge cousub (in=a) schools (in=b); by school_id1;
if a and b then count+1;
if a and b then output;
run;

*There are 1033085 rows in the combined dataset.; 
