# COVID-19-Pandemic-Connectedness-Spatial-Temporal-database
A spatial-temporal database for analyzing cross-country pandemic connectedness in COVID-19
[![DOI](https://zenodo.org/badge/325214980.svg)](https://zenodo.org/badge/latestdoi/325214980)

# Backgrounds

Communicable diseases, such as coronavirus disease 2019, pose a major threat to public health across the globe. To effectively curb the spread of communicable diseases, timely prediction of pandemic risk is essential. The conventional method of prediction by looking into confirmed case counts alone provides limited information about pandemic trends. Because air travel is a common route of communicable disease dissemination and network analysis is a powerful way to estimate pandemic risk, a spatial-temporal database allowing us to analyze cross-country pandemic connectedness is important. 

This database can construct useful travel data records for network statistics other than common descriptive statistics. We can display analytical results by time series plots and spatial-temporal maps to illustrate or visualize pandemic connectedness. The flexible design of the database gives users access to network connectedness at different periods, places, and spatial levels by various network statistics calculation methods according to their needs. The database can facilitate early recognition of the pandemic risk of current communicable diseases and newly emerged communicable diseases in the future.

--------------------------------------------------------------

# Data Records

The data records consist of two major parts: aggregated raw input and calculated/ computed records.

The aggregated raw inputs are location metadata which include data at multiple levels – country, city, airport, and geolocation (latitude-longitude) – and travel data which contain daily information regarding flight origin and destination starting from Jan 2019. It covers more than 200 countries and regions in the world.

The data records (details) are structured into three comma-separated value (CSV) files, as follows.

1. [ICAO_airport_meta.csv] Table of the location meta (ICAO-CAPSCA airport meta). The fields of the table are:
	* a.	countryName is the name of the country
	* b.	countryCode is the ISO-3166 alpha-3 code of the country
	* c.	airportName is the name of the airport
	* d.	airportCode is the ICAO code of the airport
	* e.	cityName is the name of the city
	* f.	latitude is the geolocation (latitude) of the airport
	* g.	longitude is the geolocation (longitude) of the airport

2. [flight_2019-01-01_2020-12-03.csv] Table of travel data (daily flight numbers from origin to destination). The fields of the table are:
	* a.	date is the record date
	* b.	num_flight is the number of flights from origin airport to destination airport
	* c.	orig_airportCode is the ICAO airport code of the origin airport
	* d.	orig_airportName is the airport name of the origin airport
	* e.	orig_countryCode is the ISO-3166 alpha-3 country code of the origin airport
	* f.	orig_countryName is the country name of the origin airport
	* g.	orig_cityName is the city name of the origin airport
	* h.	orig_latitude is the geolocation (latitude) of the destination airport
	* i.	orig_longitude is the geolocation (longitude) of the destination airport
	* j.	dest_airportCode is the ICAO airport code of the destination airport
	* k.	dest_airportName is the airport name of the destination airport
	* l.	dest_countryCode is the ISO-3166 alpha-3 country code of the destination airport
	* m.	dest_countryName is the country name of the destination airport
	* n.	dest_cityName is the city name of the destination airport
	* o.	dest_latitude is the geolocation (latitude) of the destination airport
	* p.	dest_longitude is the geolocation (longitude) of the destination airport

3. [network_statistics.csv] Table of the calculated network statistics. The fields of the table are:
	* a.	date is the reference date of the network statistics at time t
	* b.	Vt is the number of vertices (Vt) at time t
	* c.	Et is the number of edges (Et) at time t
	* d.	Dt is the edge density (Dt) at time t
	* e.	Rt is the reciprocity (Rt) at time t

--------------------------------------------------------------

# R Program

All data records were generated using code developed in R version 3.6.3.

Make sure you run the codes in the following order. Otherwise, unexpected error/ issues might occur unless you know what you are doing.

1. [_00_retrieve_data_meta.R]: Retrieve airport meta information by valid ICAO format
  Reminder: Please create a folder named "raw_data" under the project root

2. [_01_retrieve_daily_flight.R]: Retrieve daily flights data (airport-airport)
  Reminder: Please create a folder named "flights" inside the folder "raw_data" for temporary storage

3. [_02_construct_network.R]: Construct dynamic travel network (country-country)
  Please create a folder named "RData" under the project root for temporary storage
 
4. [_03_calculate_stats.R]: Calculate network statistics 
  Please create a folder named "output" under the project root for temporary storage


