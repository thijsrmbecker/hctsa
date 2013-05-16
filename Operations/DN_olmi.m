function out = DN_olmi(y,howth)
% DN_olmi
% Outlier mean interval
% Computes a curve as a function of the threshold (in std of the signal)
% Ben Fulcher June 2009
% Would also be a good idea to compare the output between, say p, n, and
% abs -- could give an idea as to asymmetries/nonstationarities

%% Check Inputs
y = zscore(y);% check z-scored
N = length(y);
inc = 0.01;

if strcmp(howth,'abs')% look at absolute value deviations
    thr = (0:inc:max(abs(y)));
    tot = N;
elseif strcmp(howth,'p')% look at only positive deviations
    thr = (0:inc:max(y));
    tot = length(find(y>=0));
elseif strcmp(howth,'n')% look at only negative deviations
    thr = (0:inc:max(-y));
    tot = length(find(y<=0));
% elseif strcmp(howth,'c') % compare positive, negative, abs
else
    disp('DN_olmi>> Error with input. Exiting.'); return
end

% If time series is all the same value -- ridiculous! ++BF 21/3/2010
if isempty(thr)
    disp('I suspect the time series is all the same value!')
    out = NaN; return
end


msDt = zeros(length(thr),6); % mean, std, proportion_of_time_series_included, 
                            % median of index relative to middle, mean,
                            % error
for i = 1:length(thr)
    th = thr(i); % the threshold
    
    % Construct a time series consisting of inter-event intervals for parts
    % of the time serie exceeding the threshold, th
    
    if strcmp(howth,'abs')% look at absolute value deviations
        r = find(abs(y)>=th);
    elseif strcmp(howth,'n')% look at only positive deviations
        r = find(y<=-th);
    elseif strcmp(howth,'p')% look at only negative deviations
        r = find(y>=th);
    end
    
    Dt_exc = diff(r); % Delta t (interval) time series; exceeding threshold
    
       
    msDt(i,1) = mean(Dt_exc); % the mean value of this sequence
    msDt(i,2) = std(Dt_exc)/sqrt(length(r)); % error on the mean
    msDt(i,3) = length(Dt_exc)/tot*100; % this is just really measuring the distribution
                                      % : the proportion of possible values
                                      % that are actually used in
                                      % calculation
    msDt(i,4) = median(r)/(N/2)-1;
    msDt(i,5) = mean(r)/(N/2)-1; % between -1 and 1
    msDt(i,6) = std(r)/sqrt(length(r));
    
end

%% Trim
% Trim off where the number of events is only one; hence the differenced
% series returns NaN
fbi = find(isnan(msDt(:,1)),1,'first'); % first bad index
if ~isempty(fbi)
    msDt = msDt(1:fbi-1,:);
    thr = thr(1:fbi-1);
end

% Trim off where the statistic power is lacking: less than 2% of data
% included
trimthr = 2; % percent
mj = find(msDt(:,3)>trimthr,1,'last');
if ~isempty(mj)
    msDt = msDt(1:mj,:);
    thr = thr(1:mj);
end

%% Plot output
% plot(thr,msDt(:,1),'.-k');hold on
% plot(thr,msDt(:,2),'.-b');hold on
% plot(thr,msDt(:,3),'.-g');hold on
% plot(thr,msDt(:,4)*100,'.-m');hold on
% plot(thr,msDt(:,5)*100,'.-r');hold on
% plot(thr,msDt(:,6),'.-c');hold off

% out=msDt;

%%% OUTPUTS!!!
%% Fit an exponential to the mean as a function of the threshold
s = fitoptions('Method','NonlinearLeastSquares','StartPoint',[0.1 2.5 1]);
f = fittype('a*exp(b*x)+c','options',s);
emsg = [];
try
    [c,gof] = fit(thr',msDt(:,1),f);
catch emsg
end

if isempty(emsg)
    out.mfexpa=c.a;
    out.mfexpb=c.b;
    out.mfexpc=c.c;
    out.mfexpr2=gof.rsquare;
    out.mfexpadjr2=gof.adjrsquare;
    out.mfexprmse=gof.rmse;
else
    out.mfexpa=NaN;
    out.mfexpb=NaN;
    out.mfexpc=NaN;
    out.mfexpr2=NaN;
    out.mfexpadjr2=NaN;
    out.mfexprmse=NaN;
end

%% Fit an exponential to N: the valid proportion left in calculation
s = fitoptions('Method','NonlinearLeastSquares','StartPoint',[120 -1 -16]);
f = fittype('a*exp(b*x)+c','options',s);
[c,gof] = fit(thr',msDt(:,3),f);

out.nfexpa=c.a;
out.nfexpb=c.b;
out.nfexpc=c.c;
out.nfexpr2=gof.rsquare;
out.nfexpadjr2=gof.adjrsquare;
out.nfexprmse=gof.rmse;

%% Fit an linaer to N: the valid proportion left in calculation
s = fitoptions('Method','NonlinearLeastSquares','StartPoint',[-40,100]);
f = fittype('a*x+b','options',s);
[c,gof] = fit(thr',msDt(:,3),f);

out.nfla=c.a;
out.nflb=c.b;
out.nflr2=gof.rsquare;
out.nfladjr2=gof.adjrsquare;
out.nflrmse=gof.rmse;

%% Stationarity assumption
% mean, median and std of the mean and median of range indicies
out.mdrm=mean(msDt(:,4));
out.mdrmd=median(msDt(:,4));
out.mdrstd=std(msDt(:,4));

out.mrm=mean(msDt(:,5));
out.mrmd=median(msDt(:,5));
out.mrstd=std(msDt(:,5));

%% Cross correlation between mean and error
xc=xcorr(msDt(:,1),msDt(:,2),1,'coeff');
out.xcmerr1=xc(end); % this is the cross-correlation at lag 1
out.xcmerrn1=xc(1); % this is the cross-correlation at lag -1

%% Fit exponential to std in range
s = fitoptions('Method','NonlinearLeastSquares','StartPoint',[5 1 15]);
f = fittype('a*exp(b*x)+c','options',s);
emsg = [];
try
    [c,gof] = fit(thr',msDt(:,6),f);
catch emsg
end
if isempty(emsg)
    out.stdrfexpa=c.a;
    out.stdrfexpb=c.b;
    out.stdrfexpc=c.c;
    out.stdrfexpr2=gof.rsquare;
    out.stdrfexpadjr2=gof.adjrsquare;
    out.stdrfexprmse=gof.rmse;
else
    out.stdrfexpa = NaN;
    out.stdrfexpb = NaN;
    out.stdrfexpc = NaN;
    out.stdrfexpr2 = NaN;
    out.stdrfexpadjr2 = NaN;
    out.stdrfexprmse = NaN;
end

%% Fit linear to errors in range
s = fitoptions('Method','NonlinearLeastSquares','StartPoint',[40,4]);
f = fittype('a*x +b','options',s);
[c,gof] = fit(thr',msDt(:,6),f);

out.stdrfla=c.a;
out.stdrflb=c.b;
out.stdrflr2=gof.rsquare;
out.stdrfladjr2=gof.adjrsquare;
out.stdrflrmse=gof.rmse;

% out=c;
% errorbar(thr,msDt(:,1),msDt(:,2),'k');

end