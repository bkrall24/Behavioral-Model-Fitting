function d2 = getHistoricalRegressors(d, n)
    d2(1,:) = d;
    for i = 2:(n+1)
        d2(i,:) = [0, d2(i-1,1:end-1)];
    end
    d2 = d2';
end