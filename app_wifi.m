% The data of bssid, frequency, channel, strength is stored in an Excel sheet.
% All the data mentioned are taken at one particular location. Found using
% the WiFi Analyzer app.

[num, txt] = xlsread('location_data.xlsx', 'Sheet2');
s_no = num(:, 1);
bssid = txt(:, 1);
channel = num(:, 3);
frequency = num(:, 4);
strength = num(:, 5);
[sz,~] = size(s_no);
url = 'https://ap1.unwiredlabs.com/v2/process.php';
%The URL is needed for using the OpenCellID API which is being used to
%retrieve the data of coordinates of the wifi routers.

if (sz == 0) % check to see if the file is empty. A given wifi router may not have been listed in the OpenCellID database.
    return
end

% The maximum signal strength received is found
strength_max = max(strength);

% The towers having signal strengths less than -75dB are neglected since
% they lead to erroneous results.
count_size = 0;
for i=1:sz
    if( strength(i) >= -75)
        count_size = count_size + 1;
    end    
end

% The following arrays are to store the data after filtering out the weak
% signals.s
bssid_final = [];
channel_final = ones(1, count_size);
frequency_final = ones(1, count_size);
strength_final = ones(1, count_size);

% The above arrays are updated with the relevant values.
b = 1;
for a=1:sz
    if(strength(a) >= -75)
        bssid_final = [bssid_final, bssid(a)];
        channel_final(b) = channel(a);
        frequency_final(b) = frequency(a);
        strength_final(b) = strength(a);
        b = b+1;
    end    
end

% index stores the s_no of the router with maximum signal strength. The
% router with maximum signal strength usually gives the most accurate
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

% The openCellID API needs an API token and it takes data like bssid, channel,
% frequency & strength.
% First a string payload is defined and the values of bssid, channel,
% frequency & strength are set to bssid1, ch1, freq1 & sig1 respectively. Then in each iteration
% of the loop the values are replaced by the actual values.
% The matlab function `webwrite` is used to generate a POST request and the
% response is returned in JSON format. The fields `lat` and `long` in the
% response are stored in the latitude or longitude array. If an error
% message is encountered, the control moves to the next iteration. 
c = 1;
for a=1:count_size
    payload = '{"token": "912fa8c8f37257","wifi": [{"bssid": "bssid1","channel": ch1,"frequency": freq1,"signal": sig1}],"address": 1}';
    payload = strrep(payload, 'bssid1', bssid_final(a));
    payload = strrep(payload, 'ch1', num2str(channel_final(a)));
    payload = strrep(payload, 'freq1', num2str(frequency_final(a)));
    payload = strrep(payload, 'sig1', num2str(strength_final(a)));
    payload = cell2mat(payload);
    response = webwrite(url, payload);
    if strcmp(response.status, 'error')
        continue;
    else    
        latitude(c) = response.lat;
        longitude(c) = response.lon;
        c = c + 1;
    end
end

% As the API already takes into account the distance, the results are
% correct and moreover the range of WiFi is too small to cause any significant error.
% However, an interesting thing could be done is too use the value of WiFi
% strengths for WiFi localization. WiFi localization can be used to get
% highly accurate location is small areas where there are a number of
% routers.
% Finally the calculated latitude and lonitude are displayed.
disp(latitude);
disp(longitude);