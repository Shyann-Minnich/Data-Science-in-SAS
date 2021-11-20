***************************************Final Project Part II************************************************************************;
libname download 'C:\Users\Shyann\Downloads'; run;

data school_enrollment;
set download.school_enroll_panel_1990_2004;
run;

data school_coordinates;
set download.join_school_coordinates_places;
run;

data crime_predictors; 
set download.crime_predictors_90_15;
run;

*Pulling from part a; 

proc import datafile = "C:\Users\Shyann\Downloads\Join_Cousub_Target_Schools"
out = cousub dbms = xlsx replace; 
run;

*Taking the last 6 characters in geoid to compare it; 
data cousub;
set cousub;
Geoid_substring = substr(geoid, 5, 10);
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

data cousub;
set cousub;
school_id1 = input(school_id, 15.);
FIPS_State1 = input(FIPS_State, 12.);
drop school_id FIPS_State;
run;

data school_enrollment;
set school_enrollment;
school_id1 = school_id;
FIPS_State1 = FIPS_State;
run;

proc sort data = schools_enrollement; by school_id1; run;
proc sort data = cousub; by school_id1; run; 

data part_a_merge;
merge cousub (in=a) school_enrollment (in=b); by school_id1;
if a and b then count+1;
if a and b then output;
run;

*Mere enrollment data with crime preducots using flips code or geoid;
		*Make sure both data sets are numeric;

data school_coordinates;
set school_coordinates; 
GEOID = GEOID * 1;
Geoid_substring = GEOID;
Name2 = Name; 
run;

data school_coordinates; 
set school_coordinates; 
drop name; 

proc sort data = part_a_merge; by geoid_substring; run;
proc sort data = school_coordinates; by GEOID_substring; run;


data school;
merge part_a_merge (in=a) school_coordinates (in=b); by Geoid_substring;
if a and b then count+1;
if a and b then output;
run;


*Only schcools that reported enrollment for all years 1990-2002;
data school;
set part_a_merge;
if New_Total_Enroll = . then incomplete = school_id;
if incomplete = . then delete = 0;
if delete = . then delete;
drop delete incomplete;
run;

proc sort data = school; by school_id; run; 

data school;
set school;
by school_id;
if first.school_id then school_count = 0; 
school_count +1;
run;

proc sort data = school; by descending school_count; run; 

data school;
set school;
if year = 2003 then delete;
if year = 2004 then delete;
if school_count > 12 then total_count = 13;
run;

proc sort data = school; by school_id descending school_count; run;

data school;
set school;
if total_count = 13 then complete = school_id;
retain complete;
if complete = . then delete;
if school_id ^= complete then delete;
drop school_count total_count complete nomatch_geo_cousub Total_Enroll FIPS_State1 count school_id1 FIPS_State1;
run;

proc sort data = school; by school_id year; run;


*Create a school district popluation by summing population demographics;

*Create a dataset that includes only cities with 400,000 or larger population.;

data crime_predictors;
set crime_predictors;
if population < 400000 then delete;
if population = . then delete;
StateFlip = STATEFP;
run;

data school; 
set school; 
StateFlip = input(STATEFP, 5.);
run;

proc sort data = school; by Stateflip; run;
proc sort data = crime_predictors; by stateflip; run;

data school; 
set school; 
Stateflip1 = input(Statefp, 2.);
run;

data crime_predictors; 
set crime_predictors; 
Stateflip1 = Statefp; 
run;

data school; 
set school; 
drop statefp; 
run;

data population;
merge school (in=a) crime_predictors (in=b); by STATEFlip1;
if a and b then count+1;
if a and b then output;
run;

*Identify the top 3 metro area for analysis: lost the most population and had a significant crime decline;
      *Change the to only 1990 and 2002 then create apercentage chage in both violent crime rate and population; 

data population; 
set population; 
years = input(year,best.);
run;


data pop_2002;
set population;
if years = 2002 then new_pop = population;
if years = 2002 then new_viol = violent_crime_rate;
retain new_pop new_viol;
if years > 2002 then delete;
run;

proc sort data =  population; by years; run;
proc sort data = population; by stateflip1 school_id; run;

data pop_1990;
set population;
if years = 1990 then base_pop = population;
if years = 1990 then base_viol = violent_crime_rate;
retain base_pop base_viol;
run;

proc sort data = pop_2002; by year; run;
proc sort data = pop_1990; by year; run;


data pop1;
merge pop_2002 (in=a) pop_1990 (in=b); by year;
if a or b then count+1;
if a or b then output;
run;


proc sort data = pop2; by GEOID Schoolid year; run;

data pop2;
set pop1;
viol_rate_pct = 100*(new_viol - base_viol)/base_viol;
popul_pct = 100*(new_pop - base_pop)/base_pop;
if years > 2002 then delete;
run;


       *Use sas proc rank to order the ctities that lost the most population.;

proc rank data= pop2 out = ranks;
var viol_rate_pct popul_pct;
ranks viol_rank popul_rank;
run;

proc sort data=ranks; by viol_rate_pct;run;
proc sort data=ranks; by popul_pct;run;

data index;
set ranks;
if viol_rank<20 and popul_rank<8 then output;
run;

*Use a geodist function to find all cities and towns within a 50 mile geo distance.
*Include all cities found around the tope 3 cities in the analysis.;

/* Identify a center point (latitude, longitude)  */
data Place;
set Index;
if agency='Phoenix' and state_abbr='AZ' then do;
	long1=PRIMARY_LONGITUDE;
    lat1 = PRIMARY_LATITUDE;
end;
if agency='Mesa' and state_abbr='AZ' then do;
	long2=longitude;
    lat2=latitude;
end;
if agency='Riverside' and state_abbr='CA' then do;
	long3=longitude;
    lat3=latitude;
end;
run;

data Place1; 
set pop2;
long_Phoenix = -112.0890683;
lat_Phoenix = 33.5722837;
Long_Mesa = -111.7186759;
Lat_Mesa = 33.4022255;
Long_Riverside = -115.9938587;
Lat_Riverside = 33.743676;
run;

proc sort data=place1; by descending long1 lat1;run;

/* Get distance from target using geodist for all locations */
data distance1;
retain target_lat1 target_long1 distance1;
set place1;
if _n_=1 then do;
target_long1=long_Phoenix;
target_lat1=lat_Phoenix;
end;
distance=geodist(target_lat1, target_long1, primary_latitude, primary_longitude, 'M');
if distance=. then distance=99999;
distance_phoenix = distance;
run;

proc sort data=distance1; by descending long2 lat2;run;

/* Get distance from target using geodist for all locations */
data distance2;
retain target_lat2 target_long2 distance2;
set distance1;
if _n_=1 then do;
target_long2=long_Mesa;
target_lat2=lat_Mesa;
end;
distance=geodist(target_lat2, target_long2, primary_latitude, primary_longitude, 'M');
if distance=. then distance=99999;
distance_mesa = distance;
run;

proc sort data=distance2; by descending long3 lat3;run;

/* Get distance from target using geodist for all locations */
data distance3;
retain target_lat3 target_long3 distance3;
set distance2;
if _n_=1 then do;
target_long3=long_Riverside;
target_lat3=lat_Riverside;
end;
distance=geodist(target_lat3, target_long3, primary_latitude, primary_longitude, 'M');
if distance=. then distance=99999;
diatance_riverside = distance;
run;

/* Establish a set range, or identify specific agencies that will be included  */
data Locations;
set distance3;
if distance_Phoenix<50 then keep = 1;
if distance_Mesa<50 then keep = 1;
if diatance_riverside<50 then keep = 1;
if keep = 1 then output;
run;

data download.FinalPartII;
  set Locations;
run;

data Locations_adj;
set distance3;
if distance_Phoenix<150 then keep = 1;
if distance_Mesa<150 then keep = 1;
if diatance_riverside<150 then keep = 1;
if keep = 1 then output;
if LSAD = 25 then output;
run;

data download.FinalPartII_adj;
  set Locations_adj;
run;

*Analyze the change in population size, school enrollment, school race for each year; 
*What specific cities does it appear that people migrated to?;

       *People from Riverside moved to LA and Long Beach. 

*Check pop100 or population of cities. Does the population variable give the same result as the schoool enrollment percent change?;
*If not, should the school enrollment be more accurate?;
	*Some of the information between city population and school enrollment data conflicted. The school enrollment data should be more accurate. 

*Did school enrollment race in cities within 50 mines change significantly?'
	*It was relatively the same for most years, however there was a significant change around 2002. 

*Did the surrounding cities experience an inflow. If so what happened to the crime rate?
	*As LA experienced an inflow in population their crime rate went up. 

*Is there a coorelation betwn population and crime rate?;
       *It was hard to see the correlation between population and crime rate until I compared the population pct change and crime rate pct change. 

*Upload a visulation from Tableau into a word document.;




