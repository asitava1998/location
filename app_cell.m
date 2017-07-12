% The data of network type, MCC, MNC, LAC, CID, strength is stored in an Excel sheet.
% All the data mentioned are taken at one particular location. Found using
% the Netmonitor app.

[num, txt] = xlsread('location_data.xlsx', 'Sheet1');
s_no = num(:, 1);
network_type = txt(:, 1);
mcc = num(:, 3);
mnc = num(:, 4);
lac = num(:, 5);
cid = num(:, 6);
strength = num(:, 7);
[sz,~] = size(s_no);
url = 'https://ap1.unwiredlabs.com/v2/process.php';

%The URL is needed for using the OpenCellID API which is being used to
%retrieve the data of coordinates of the cell towers.

if (sz == 0) % check to see if the file is empty. A given location may not have cell towers at all.
    return
end

% The maximum signal strength received is found
strength_max = max(strength);

% The towers having signal strengths less than -95dB are neglected since
% they lead to erroneous results.
count_size = 0;
for i=1:sz
    if( strength(i) >= -95)
        count_size = count_size + 1;
    end    
end

% The following arrays are to store the data after filtering out the weak
% signals.
network_type_final = [];
mcc_final = ones(1, count_size);
mnc_final = ones(1, count_size);
lac_final = ones(1, count_size);
cid_final = ones(1, count_size);
strength_final = ones(1, count_size);

% The above arrays are updated with the relevant values.
b = 1;
for a=1:sz
    if(strength(a) >= -95)
        network_type_final = [network_type_final, network_type(a)];
        mcc_final(b) = mcc(a);
        mnc_final(b) = mnc(a);
        lac_final(b) = lac(a);
        cid_final(b) = cid(a);
        strength_final(b) = strength(a);
        b = b+1;
    end    
end

% index stores the s_no of the tower with maximum signal strength. The
% tower with maximum signal strength usually gives the most accurate
% results while calculating the distance and thus is given a greater
% preference.
for i=1:count_size
    if( strength_final(i) == strength_max )
        index = s_no(i);
    end    
end

%latitude and longitude arrays are defined to store the data returned by
%the API.
latitude = ones(1, count_size);
longitude = ones(1, count_size);

% The openCellID API needs an API token and it takes data like mcc, mnc,
% lac & cid.
% First a string payload is defined and the values of mcc, mnc, lac & cid
% are set to mcc1, mnc1, lac1 & cid1 respectively. Then in each iteration
% of the loop according to network type which are 'gsm', 'lte' and 'umts',
% the values are replaced by the actual values.
% The matlab function `webwrite` is used to generate a POST request and the
% response is returned in JSON format. The fields `lat` and `long` in the
% response are stored in the latitude or longitude array.
for a=1:count_size
    if strcmp(network_type_final(a), 'gsm')
        payload = '{"token": "912fa8c8f37257","radio": "gsm","mcc": mcc1,"mnc": mnc1,"cells": [{"lac": lac1,"cid": cid1}],"address": 1}';
        payload = strrep(payload, 'mcc1', num2str(mcc_final(a)));
        payload = strrep(payload, 'mnc1', num2str(mnc_final(a)));
        payload = strrep(payload, 'lac1', num2str(lac_final(a)));
        payload = strrep(payload, 'cid1', num2str(cid_final(a)));
        response = webwrite(url, payload);
        latitude(a) = response.lat;
        longitude(a) = response.lon;
        
    elseif strcmp(network_type_final(a), 'umts')
        payload = '{"token": "912fa8c8f37257","radio": "umts","mcc": mcc1,"mnc": mnc1,"cells": [{"lac": lac1,"cid": cid1}],"address": 1}';
        payload = strrep(payload, 'mcc1', num2str(mcc_final(a)));
        payload = strrep(payload, 'mnc1', num2str(mnc_final(a)));
        payload = strrep(payload, 'lac1', num2str(lac_final(a)));
        payload = strrep(payload, 'cid1', num2str(cid_final(a)));
        response = webwrite(url, payload);
        latitude(a) = response.lat;
        longitude(a) = response.lon;

    elseif strcmp(network_type_final(a), 'lte')
        payload = '{"token": "912fa8c8f37257","radio": "gsm","mcc": mcc1,"mnc": mnc1,"cells": [{"lac": lac1,"cid": cid1,"psc": 0}],"address": 1}';
        payload = strrep(payload, 'mcc1', num2str(mcc_final(a)));
        payload = strrep(payload, 'mnc1', num2str(mnc_final(a)));
        payload = strrep(payload, 'lac1', num2str(lac_final(a)));
        payload = strrep(payload, 'cid1', num2str(cid_final(a)));
        response = webwrite(url, payload);
        latitude(a) = response.lat;
        longitude(a) = response.lon;

    end    
end    

% If there is just a single tower for which latitude & longitude data is
% available, then that location is reflected as the location of the user
% and the signal strength is not taken into consideration since it will
% result in a wide area of values.
% If there are two or more sets of latitude and longitude available, then the 
% algorithm for location finding is applied.
% The default function used for optimization in 'fmincon' which is used for
% constrained optimization.
% The function defined for the optimization for each tower is 
%     log(((latitude(i) - x(1))^2) + ((longitude(i) - x(2))^2) * (cosd(latitude(i))^2)) - ((strength_final(i) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
% The above is a culmination of two formulae used here:
% The first formula is for finding the relation between signal strength and distance
%     Strength(in dB) = -113.0 +  10 * (Gamma) * log(r/R);
%     where `Gamma` is a parameter which is measure of how quickly will the
%     signal die. Typically Gamma can be safely assumed to be 4.
%     `r` is the distance of the point from the cell tower and `R` denotes
%     the mean cell radius. `R` is a fixed value but R depends on a lot of
%     other factors like network type, type of equipment used, whether the
%     signal propagation is affected by a large number of obstacles. here
%     we take `R` to be 4.
% So, `r` turns out to be r = R * 10 ^ ((Strength + 113)/40)
% The second formula used is to find the distance between two points given
% their latitudes and longitudes are given
%     r = sqrt((latitude(1) - latitude(2))^2 + ((longitude(1) - longitude(2))^2) * (cosd((latitude(1) + latitude(2))/2)^2))
% The cosine term comes into existence because the earth is not flat so
% the distance between longitudes is not uniform.
% Finally for our calculation we take the logarithm of the above expression
% as it reduces the error.
% The final function for optimization for each cell tower is therefore
%     log(((latitude(1) - x(1))^2) + ((longitude(1) - x(2))^2) * (cosd(latitude(1))^2)) - ((strength_final(1) + x(3) + 113.0)/40 + 4) * 2 - log(111300)
% Similar expressions are written for all the cell towers.
% The upper and lower bound are determined using the latitude and
% longtitude of the tower of the maximum signal strength. (This is where 
% index defined earlier is used.
% the variables for optimization are final latitude, final longitude and a
% dummy variable to account for the fluctuations in signal strength and
% its value ranges from -5 to 5.
% The algorithm returns the optimum value of the latitude and longitude
% that we need to find.
% For the case of three or more sets, the sets are considered in groups of
% three to get the optimum latitude and longitude for each iteration and
% then their mean is calculated. This process reduces the margin of error.
if ( count_size == 1)
    result = [ latitude(1), latitude(1) ]; 
elseif ( count_size == 2)
    func1 = @(x)log(((latitude(1) - x(1))^2) + ((longitude(1) - x(2))^2) * (cosd(latitude(1))^2)) - ((strength_final(1) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
    func2 = @(x)log(((latitude(2) - x(1))^2) + ((longitude(2) - x(2))^2) * (cosd(latitude(2))^2)) - ((strength_final(2) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
    func = @(x)(func1(x) + func2(x));
    
    lb = [latitude(index) - 0.5, longitude(index) - 0.5, -5];
    ub = [latitude(index) + 0.5, longitude(index) + 0.5, 5];
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    x0 = [latitude(index) - 5, longitude(index) -5, 0];
    result = fmincon(func, x0, A, b, Aeq, beq, lb, ub);
else
    latitude_arr = ones(1, count_size-2);
    longitude_arr = ones(1, count_size-2);
    for i=1:count_size-2
        func1 = @(x)log(((latitude(i) - x(1))^2)   + ((longitude(i) - x(2))^2)   * (cosd(latitude(i))^2))   - ((strength_final(i) + x(3)   + 113.0)/40 + 4) * 2 - log(111300);
        func2 = @(x)log(((latitude(i+1) - x(1))^2) + ((longitude(i+1) - x(2))^2) * (cosd(latitude(i+1))^2)) - ((strength_final(i+1) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
        func3 = @(x)log(((latitude(i+2) - x(1))^2) + ((longitude(i+2) - x(2))^2) * (cosd(latitude(i+2))^2)) - ((strength_final(i+2) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
        func = @(x)(func1(x) + func2(x) + func3(x));
        
        lb = [latitude(index) - 0.5, longitude(index) - 0.5, -5];
        ub = [latitude(index) + 0.5, longitude(index) + 0.5, 5];
        A = [];
        b = [];
        Aeq = [];
        beq = [];
        x0 = [latitude(index) - 5, longitude(index) - 5, 0];
        result_intermediate = fmincon(func, x0, A, b, Aeq, beq, lb, ub);
        latitude_arr(i) = result_intermediate(1);
        longitude_arr(i) = result_intermediate(2);
    end
    result = [mean(latitude_arr), mean(longitude_arr)];
end

% Finally, the probable value of latitude and longitude is displayed.
display(result);