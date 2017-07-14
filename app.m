[num_cell, txt_cell] = xlsread('location_data.xlsx', 'Sheet1');
s_no_cell = num_cell(:, 1);
network_type = txt_cell(:, 1);
mcc = num_cell(:, 3);
mnc = num_cell(:, 4);
lac = num_cell(:, 5);
cid = num_cell(:, 6);
strength_cell = num_cell(:, 7);
[sz_cell,~] = size(s_no_cell);

[num_wifi, txt_wifi] = xlsread('location_data.xlsx', 'Sheet2');
s_no_wifi = num_wifi(:, 1);
bssid = txt_wifi(:, 1);
channel = num_wifi(:, 3);
frequency = num_wifi(:, 4);
strength_wifi = num_wifi(:, 5);
[sz_wifi,~] = size(s_no_wifi);

url = 'https://ap1.unwiredlabs.com/v2/process.php';

if (sz_cell == 0 || sz_wifi == 0) 
    return
end

strength_max_cell = max(strength_cell);
strength_max_wifi = max(strength_wifi);

count_size_wifi = 0;
for i=1:sz_wifi
    if( strength_wifi(i) >= -75)
        count_size_wifi = count_size_wifi + 1;
    end    
end

bssid_final = [];
channel_final = ones(1, count_size_wifi);
frequency_final = ones(1, count_size_wifi);
strength_final_wifi = ones(1, count_size_wifi);

b = 1;
for a=1:sz_wifi
    if(strength_wifi(a) >= -75)
        bssid_final = [bssid_final, bssid(a)];
        channel_final(b) = channel(a);
        frequency_final(b) = frequency(a);
        strength_final_wifi(b) = strength_wifi(a);
        b = b+1;
    end    
end

for i=1:count_size_wifi
    if( strength_final_wifi(i) == strength_max_wifi )
        index_wifi = s_no_wifi(i);
    end    
end

latitude_wifi = ones(1, count_size_wifi);
longitude_wifi = ones(1, count_size_wifi);

c = 1;
for a=1:count_size_wifi
    payload = '{"token": "912fa8c8f37257","wifi": [{"bssid": "bssid1","channel": ch1,"frequency": freq1,"signal": sig1}],"address": 1}';
    payload = strrep(payload, 'bssid1', bssid_final(a));
    payload = strrep(payload, 'ch1', num2str(channel_final(a)));
    payload = strrep(payload, 'freq1', num2str(frequency_final(a)));
    payload = strrep(payload, 'sig1', num2str(strength_final_wifi(a)));
    payload = cell2mat(payload);
    response = webwrite(url, payload);
    if strcmp(response.status, 'error')
        continue;
    else    
        latitude_wifi(c) = response.lat;
        longitude_wifi(c) = response.lon;
        c = c + 1;
    end
end

lat_index = mean(latitude_wifi);
long_index = mean(longitude_wifi);

count_size_cell = 0;
for i=1:sz_cell
    if( strength_cell(i) >= -95)
        count_size_cell = count_size_cell + 1;
    end    
end

network_type_final = [];
mcc_final = ones(1, count_size_cell);
mnc_final = ones(1, count_size_cell);
lac_final = ones(1, count_size_cell);
cid_final = ones(1, count_size_cell);
strength_final_cell = ones(1, count_size_cell);

b = 1;
for a=1:sz_cell
    if(strength_cell(a) >= -95)
        network_type_final = [network_type_final, network_type(a)];
        mcc_final(b) = mcc(a);
        mnc_final(b) = mnc(a);
        lac_final(b) = lac(a);
        cid_final(b) = cid(a);
        strength_final_cell(b) = strength_cell(a);
        b = b+1;
    end    
end

for i=1:count_size_cell
    if( strength_final_cell(i) == strength_max_cell )
        index_cell = s_no_cell(i);
    end    
end

latitude_cell = ones(1, count_size_cell);
longitude_cell = ones(1, count_size_cell);

for a=1:count_size_cell
    if strcmp(network_type_final(a), 'gsm')
        payload = '{"token": "912fa8c8f37257","radio": "gsm","mcc": mcc1,"mnc": mnc1,"cells": [{"lac": lac1,"cid": cid1}],"address": 1}';
        payload = strrep(payload, 'mcc1', num2str(mcc_final(a)));
        payload = strrep(payload, 'mnc1', num2str(mnc_final(a)));
        payload = strrep(payload, 'lac1', num2str(lac_final(a)));
        payload = strrep(payload, 'cid1', num2str(cid_final(a)));
        response = webwrite(url, payload);
        latitude_cell(a) = response.lat;
        longitude_cell(a) = response.lon;
        
    elseif strcmp(network_type_final(a), 'umts')
        payload = '{"token": "912fa8c8f37257","radio": "umts","mcc": mcc1,"mnc": mnc1,"cells": [{"lac": lac1,"cid": cid1}],"address": 1}';
        payload = strrep(payload, 'mcc1', num2str(mcc_final(a)));
        payload = strrep(payload, 'mnc1', num2str(mnc_final(a)));
        payload = strrep(payload, 'lac1', num2str(lac_final(a)));
        payload = strrep(payload, 'cid1', num2str(cid_final(a)));
        response = webwrite(url, payload);
        latitude_cell(a) = response.lat;
        longitude_cell(a) = response.lon;

    elseif strcmp(network_type_final(a), 'lte')
        payload = '{"token": "912fa8c8f37257","radio": "gsm","mcc": mcc1,"mnc": mnc1,"cells": [{"lac": lac1,"cid": cid1,"psc": 0}],"address": 1}';
        payload = strrep(payload, 'mcc1', num2str(mcc_final(a)));
        payload = strrep(payload, 'mnc1', num2str(mnc_final(a)));
        payload = strrep(payload, 'lac1', num2str(lac_final(a)));
        payload = strrep(payload, 'cid1', num2str(cid_final(a)));
        response = webwrite(url, payload);
        latitude_cell(a) = response.lat;
        longitude_cell(a) = response.lon;

    end    
end    

if (lat_index == 1 || long_index == 1)
    if ( count_size_cell == 1)
        result = [ latitude_cell(1), longitude_cell(1) ]; 
    elseif ( count_size_cell == 2)
        func1 = @(x)log(((latitude_cell(1) - x(1))^2) + ((longitude_cell(1) - x(2))^2) * (cosd(latitude_cell(1))^2)) - ((strength_final_cell(1) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
        func2 = @(x)log(((latitude_cell(2) - x(1))^2) + ((longitude_cell(2) - x(2))^2) * (cosd(latitude_cell(2))^2)) - ((strength_final_cell(2) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
        func = @(x)(func1(x) + func2(x));
        
        lb = [latitude_cell(index_cell) - 0.5, longitude_cell(index_cell) - 0.5, -5];
        ub = [latitude_cell(index_cell) + 0.5, longitude_cell(index_cell) + 0.5, 5];
        A = [];
        b = [];
        Aeq = [];
        beq = [];
        x0 = [latitude_cell(index_cell) - 5, longitude_cell(index_cell) -5, 0];
        result = fmincon(func, x0, A, b, Aeq, beq, lb, ub);
    else
        latitude_arr = ones(1, count_size_cell-2);
        longitude_arr = ones(1, count_size_cell-2);
        for i=1:count_size_cell-2
            func1 = @(x)log(((latitude_cell(i) - x(1))^2)   + ((longitude_cell(i) - x(2))^2)   * (cosd(latitude_cell(i))^2))   - ((strength_final_cell(i) + x(3)   + 113.0)/40 + 4) * 2 - log(111300);
            func2 = @(x)log(((latitude_cell(i+1) - x(1))^2) + ((longitude_cell(i+1) - x(2))^2) * (cosd(latitude_cell(i+1))^2)) - ((strength_final_cell(i+1) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
            func3 = @(x)log(((latitude_cell(i+2) - x(1))^2) + ((longitude_cell(i+2) - x(2))^2) * (cosd(latitude_cell(i+2))^2)) - ((strength_final_cell(i+2) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
            func = @(x)(func1(x) + func2(x) + func3(x));
            
            lb = [latitude_cell(index_cell) - 0.5, longitude_cell(index_cell) - 0.5, -5];
            ub = [latitude_cell(index_cell) + 0.5, longitude_cell(index_cell) + 0.5, 5];
            A = [];
            b = [];
            Aeq = [];
            beq = [];
            x0 = [latitude_cell(index_cell) - 5, longitude_cell(index_cell) - 5, 0];
            result_intermediate = fmincon(func, x0, A, b, Aeq, beq, lb, ub);
            latitude_arr(i) = result_intermediate(1);
            longitude_arr(i) = result_intermediate(2);
        end
        result = [mean(latitude_arr), mean(longitude_arr)];
    end

    display(result);
else
    if ( count_size_cell == 1)
        result = [ lat_index, long_index ]; 
    elseif ( count_size_cell == 2)
        func1 = @(x)log(((latitude_cell(1) - x(1))^2) + ((longitude_cell(1) - x(2))^2) * (cosd(latitude_cell(1))^2)) - ((strength_final_cell(1) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
        func2 = @(x)log(((latitude_cell(2) - x(1))^2) + ((longitude_cell(2) - x(2))^2) * (cosd(latitude_cell(2))^2)) - ((strength_final_cell(2) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
        func = @(x)(func1(x) + func2(x));
        
        lb = [lat_index - 0.05, long_index - 0.05, -5];
        ub = [lat_index + 0.05, long_index + 0.05, 5];
        A = [];
        b = [];
        Aeq = [];
        beq = [];
        x0 = [lat_index - 0.1, lat_index - 0.1, 0];
        result = fmincon(func, x0, A, b, Aeq, beq, lb, ub);
    else
        latitude_arr = ones(1, count_size_cell-2);
        longitude_arr = ones(1, count_size_cell-2);
        for i=1:count_size_cell-2
            func1 = @(x)log(((latitude_cell(i) - x(1))^2)   + ((longitude_cell(i) - x(2))^2)   * (cosd(latitude_cell(i))^2))   - ((strength_final_cell(i) + x(3)   + 113.0)/40 + 4) * 2 - log(111300);
            func2 = @(x)log(((latitude_cell(i+1) - x(1))^2) + ((longitude_cell(i+1) - x(2))^2) * (cosd(latitude_cell(i+1))^2)) - ((strength_final_cell(i+1) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
            func3 = @(x)log(((latitude_cell(i+2) - x(1))^2) + ((longitude_cell(i+2) - x(2))^2) * (cosd(latitude_cell(i+2))^2)) - ((strength_final_cell(i+2) + x(3) + 113.0)/40 + 4) * 2 - log(111300);
            func = @(x)(func1(x) + func2(x) + func3(x));
            
            lb = [lat_index - 0.05, long_index - 0.05, -5];
            ub = [lat_index + 0.05, long_index + 0.05, 5];
            A = [];
            b = [];
            Aeq = [];
            beq = [];
            x0 = [lat_index - 0.1, long_index - 0.1, 0];
            result_intermediate = fmincon(func, x0, A, b, Aeq, beq, lb, ub);
            latitude_arr(i) = result_intermediate(1);
            longitude_arr(i) = result_intermediate(2);
        end
        result = [mean(latitude_arr), mean(longitude_arr)];
    end

    display(result);
end    